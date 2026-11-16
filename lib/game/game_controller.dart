import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'ai_player.dart';
import 'ludo_engine.dart';
import 'online_service.dart';

enum GameMode { vsComputer, passAndPlay, online }

/// UI-facing controller for one game.
///
/// Owns the [LudoEngine], the dice-roll animation state, the move log,
/// AI turns (automatic, with small delays so the game is watchable) and,
/// in online mode, syncing the engine state with the Firebase room.
class GameController extends ChangeNotifier {
  GameController({
    required this.mode,
    required List<LudoPlayer> players,
    this.roomCode,
    this.myUid,
    this.myColor,
    this.isHost = false,
  }) : engine = LudoEngine(players: players);

  final GameMode mode;
  final LudoEngine engine;

  /// Online only: the room code, my uid, and the colour of my seat.
  final String? roomCode;
  final String? myUid;
  final LudoColor? myColor;
  final bool isHost;

  /// Face currently shown on the dice (1-6). Null before the first roll.
  int? shownDice;
  bool isRolling = false;

  /// Whether the human sitting at this phone may roll right now.
  bool get canRoll =>
      !engine.isGameOver &&
      !isRolling &&
      !engine.awaitingMove &&
      engine.diceValue == null &&
      _isLocalTurn;

  /// Token indexes the current player may tap right now.
  List<int> get movableTokens {
    final dice = engine.diceValue;
    if (dice == null || !engine.awaitingMove) return const [];
    return engine.legalMoves(engine.currentPlayer, dice);
  }

  String statusText = '';
  final List<String> log = [];
  String? lastEvent;

  /// Online only: true when the player whose turn it is has dropped out.
  bool currentPlayerAway = false;

  StreamSubscription<RoomSnapshot?>? _roomSub;
  int _lastAppliedRevision = 0;
  int _aiGeneration = 0;
  bool _disposed = false;

  bool get _isOnline => mode == GameMode.online;

  /// Online: only the local player's own seat may act.
  /// Offline: the human seat(s) may act; AI seats are automatic.
  bool get _isLocalTurn {
    if (_isOnline) {
      return myColor != null &&
          engine.players[engine.currentPlayer].color == myColor;
    }
    return !engine.current.isAI;
  }

  // ------------------------------------------------------------ lifecycle

  void start() {
    _pushLog('${engine.current.name} starts. Roll the dice!');
    statusText = "${engine.current.name}'s turn — tap the dice.";
    if (_isOnline) _subscribeRoom();
    _maybeRunAi();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _aiGeneration++;
    _roomSub?.cancel();
    if (_isOnline && roomCode != null && myUid != null) {
      unawaited(OnlineService.leaveRoom(roomCode!, myUid!));
    }
    super.dispose();
  }

  // ------------------------------------------------------------ dice

  /// Human taps the dice (or the AI takes its turn with [byAi]).
  /// Animates the face, then rolls the engine with the shown value.
  Future<void> rollDice({bool byAi = false}) async {
    if (engine.isGameOver || isRolling) return;
    if (!byAi && !canRoll) return;
    if (byAi && (engine.diceValue != null || engine.awaitingMove)) return;
    isRolling = true;
    lastEvent = null;
    // Pick the value first so the animation lands on the real face.
    final value = engine.random.nextInt(6) + 1;
    notifyListeners();
    // Simple roll animation: flash random faces for ~550 ms.
    final random = engine.random;
    for (var i = 0; i < 7; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (_disposed) return;
      shownDice = random.nextInt(6) + 1;
      notifyListeners();
    }
    await Future<void>.delayed(const Duration(milliseconds: 70));
    if (_disposed) return;
    shownDice = value;
    isRolling = false;
    notifyListeners();
    final event = engine.rollWithValue(value);
    if (event != null) {
      lastEvent = event;
      _pushLog(event);
    } else {
      _pushLog('${engine.current.name} rolled $value.');
    }
    statusText = _statusAfterRoll();
    await _pushOnline();
    notifyListeners();
    _maybeRunAi();
  }

  String _statusAfterRoll() {
    if (engine.isGameOver) return '';
    if (engine.awaitingMove) {
      return "${engine.current.name} rolled ${engine.diceValue} — pick a token.";
    }
    return "${engine.current.name}'s turn — tap the dice.";
  }

  // ------------------------------------------------------------ moves

  /// Human taps one of their tokens (or the AI moves with [byAi]).
  Future<void> tapToken(int tokenIndex, {bool byAi = false}) async {
    if (!movableTokens.contains(tokenIndex)) return;
    if (!byAi && !_isLocalTurn) return;
    final player = engine.current;
    final result = engine.applyMove(tokenIndex);
    _describeMove(player, result);
    await _pushOnline();
    notifyListeners();
    _maybeRunAi();
  }

  void _describeMove(LudoPlayer player, MoveResult result) {
    final from = result.fromSteps == -1 ? 'base' : 'step ${result.fromSteps}';
    final to = result.toSteps == LudoEngine.finishSteps
        ? 'home!'
        : 'step ${result.toSteps}';
    var line = '${player.name} moved a token from $from to $to.';
    if (result.captured.isNotEmpty) {
      final names = result.captured
          .map((c) => engine.players[c.$1].name)
          .toSet()
          .join(', ');
      line += ' Captured $names!';
      lastEvent = '${player.name} captured $names!';
    } else if (result.toSteps == LudoEngine.finishSteps) {
      lastEvent = '${player.name} brought a token home!';
    } else if (result.extraTurn) {
      lastEvent = '${player.name} rolled a 6 — roll again!';
    } else {
      lastEvent = null;
    }
    _pushLog(line);
    if (result.gameOver) {
      lastEvent = '${player.name} wins the game!';
      _pushLog('${player.name} wins the game!');
      statusText = '${player.name} wins!';
      if (_isOnline && roomCode != null) {
        unawaited(OnlineService.finishGame(roomCode!));
      }
    } else if (result.extraTurn) {
      statusText = "${player.name} rolled a 6 — roll again!";
    } else {
      statusText = "${engine.current.name}'s turn — tap the dice.";
    }
  }

  // ------------------------------------------------------------ AI

  void _maybeRunAi() {
    if (_disposed || engine.isGameOver) return;
    if (_isOnline) return; // No AI online.
    if (!engine.current.isAI) return;
    final generation = ++_aiGeneration;
    // AI rolls after a short pause so the human can follow the game.
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (_disposed || generation != _aiGeneration) return;
      if (engine.isGameOver || !engine.current.isAI) return;
      if (engine.diceValue == null && !engine.awaitingMove) {
        await rollDice(byAi: true);
      }
      if (_disposed || generation != _aiGeneration) return;
      if (engine.awaitingMove && engine.current.isAI) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
        if (_disposed || generation != _aiGeneration) return;
        if (!engine.awaitingMove || engine.isGameOver) return;
        final choice = AiPlayer.chooseMove(engine, engine.currentPlayer);
        await tapToken(choice, byAi: true);
      }
    });
  }

  /// Online: pass the turn when the current player is away, so the game
  /// is not stuck waiting for a dropped player.
  Future<void> passAwayTurn() async {
    if (!_isOnline || !currentPlayerAway) return;
    final name = engine.current.name;
    engine.passTurn();
    _pushLog('$name is away — turn passed.');
    statusText = "${engine.current.name}'s turn — tap the dice.";
    await _pushOnline();
    notifyListeners();
  }

  // ------------------------------------------------------------ online sync

  void _subscribeRoom() {
    final code = roomCode;
    if (code == null) return;
    _roomSub = OnlineService.watchRoom(code).listen((snap) {
      if (snap == null || _disposed) return;
      if (snap.revision <= _lastAppliedRevision) return;
      _lastAppliedRevision = snap.revision;
      if (snap.engineJson != null) {
        final wasAwaiting = engine.awaitingMove;
        engine.restore(snap.engineJson!);
        final currentColor = engine.players[engine.currentPlayer].color;
        currentPlayerAway = snap.players
                .where((p) => p.color == currentColor)
                .firstOrNull
                ?.connected ==
            false;
        if (engine.awaitingMove && !wasAwaiting) {
          shownDice = engine.diceValue;
        }
        // Keep the local log in sync with the room log.
        log
          ..clear()
          ..addAll(snap.log);
        if (engine.isGameOver) {
          final w =
              engine.players.firstWhere((p) => p.color == engine.winner);
          statusText = '${w.name} wins!';
          lastEvent = '${w.name} wins the game!';
        } else if (engine.awaitingMove) {
          statusText = _statusAfterRoll();
        } else {
          statusText = "${engine.current.name}'s turn — tap the dice.";
        }
        notifyListeners();
      }
    });
  }

  Future<void> _pushOnline() async {
    if (!_isOnline || roomCode == null) return;
    try {
      _lastAppliedRevision = DateTime.now().millisecondsSinceEpoch;
      await OnlineService.pushState(roomCode!, engine, log);
    } catch (_) {
      // A failed push must not break local play; the next action retries.
    }
  }

  void _pushLog(String line) {
    log.add(line);
    if (log.length > 40) log.removeRange(0, log.length - 40);
  }

  // ------------------------------------------------------------ helpers

  /// Cell position (row, col in board-cell units) for a token, for the UI.
  (double, double) tokenCell(int playerIndex, int tokenIndex) {
    final p = engine.players[playerIndex];
    return LudoEngine.cellFor(
      p.color,
      p.tokens[tokenIndex],
      tokenIndex,
    );
  }

  /// All tokens currently standing on the same board cell (for offsets).
  List<(int, int)> tokensOnCell(double row, double col) {
    final found = <(int, int)>[];
    for (var pi = 0; pi < engine.players.length; pi++) {
      final p = engine.players[pi];
      for (var ti = 0; ti < LudoEngine.tokensPerPlayer; ti++) {
        final cell = LudoEngine.cellFor(p.color, p.tokens[ti], ti);
        if ((cell.$1 - row).abs() < 0.01 &&
            (cell.$2 - col).abs() < 0.01) {
          found.add((pi, ti));
        }
      }
    }
    return found;
  }
}
