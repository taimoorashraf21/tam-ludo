import 'dart:math';

/// TAM Ludo — classic Ludo rules, implemented as a pure-Dart engine
/// (no Flutter dependency) so it can be unit-tested directly.
///
/// Board model (15 x 15 grid, rows 0-14 top to bottom, cols 0-14 left to
/// right):
///   * Red base top-left, Green base top-right, Yellow base bottom-right,
///     Blue base bottom-left.
///   * The main track is 52 cells, walked clockwise starting at Red's start
///     cell (row 6, col 1).
///   * Each colour has a 5-cell home column + the centre (home). A token's
///     journey is 57 steps: step 0 = its start cell, steps 0-50 on the main
///     track, steps 51-55 in its home column, step 56 = finished (home).
///   * Token `steps == -1` means the token is still in its base.
enum LudoColor { red, green, yellow, blue }

extension LudoColorLabel on LudoColor {
  String get label {
    switch (this) {
      case LudoColor.red:
        return 'Red';
      case LudoColor.green:
        return 'Green';
      case LudoColor.yellow:
        return 'Yellow';
      case LudoColor.blue:
        return 'Blue';
    }
  }
}

/// One player: a colour, a display name, human or AI, and 4 tokens.
class LudoPlayer {
  LudoPlayer({
    required this.color,
    required this.name,
    this.isAI = false,
    List<int>? tokens,
  }) : tokens = tokens ?? List.filled(LudoEngine.tokensPerPlayer, -1);

  final LudoColor color;
  final String name;
  final bool isAI;

  /// Token positions in steps: -1 = in base, 0..55 moving, 56 = finished.
  final List<int> tokens;

  bool get hasWon => tokens.every((t) => t == LudoEngine.finishSteps);

  int get finishedCount =>
      tokens.where((t) => t == LudoEngine.finishSteps).length;

  LudoPlayer copy() => LudoPlayer(
        color: color,
        name: name,
        isAI: isAI,
        tokens: List.of(tokens),
      );

  Map<String, dynamic> toJson() => {
        'color': color.index,
        'name': name,
        'isAI': isAI,
        'tokens': List.of(tokens),
      };

  factory LudoPlayer.fromJson(Map<String, dynamic> json) => LudoPlayer(
        color: LudoColor.values[json['color'] as int],
        name: json['name'] as String,
        isAI: json['isAI'] as bool? ?? false,
        tokens: (json['tokens'] as List)
            .map((t) => (t as num).toInt())
            .toList(),
      );
}

/// What happened when a move was applied (for UI feedback + logs).
class MoveResult {
  const MoveResult({
    required this.tokenIndex,
    required this.fromSteps,
    required this.toSteps,
    this.captured = const [],
    this.extraTurn = false,
    this.gameOver = false,
  });

  final int tokenIndex;
  final int fromSteps;
  final int toSteps;

  /// (player index, token index) of every opponent token sent back to base.
  final List<(int, int)> captured;
  final bool extraTurn;
  final bool gameOver;
}

class LudoEngine {
  LudoEngine({required List<LudoPlayer> players})
      : players = players.map((p) => p.copy()).toList(),
        random = Random();

  LudoEngine._clone(this.players, this.currentPlayer, this.diceValue,
      this.awaitingMove, this.consecutiveSixes, this.winner, this.random);

  static const int trackLength = 52;

  /// Steps 51..55 are the home column; step 56 is home (finished).
  static const int homeColumnLength = 5;
  static const int finishSteps = 56;
  static const int tokensPerPlayer = 4;

  /// Track index where each colour's tokens enter the board.
  static const List<int> startIndices = [0, 13, 26, 39];

  /// Safe cells on the main track: the 4 start cells + the 4 star cells.
  /// Tokens standing on a safe cell cannot be captured.
  static const Set<int> safeIndices = {0, 8, 13, 21, 26, 34, 39, 47};

  /// The 52-cell main track as (row, col) grid coordinates, in walk order.
  static const List<(int, int)> track = [
    (6, 1), (6, 2), (6, 3), (6, 4), (6, 5),
    (5, 6), (4, 6), (3, 6), (2, 6), (1, 6), (0, 6),
    (0, 7),
    (0, 8), (1, 8), (2, 8), (3, 8), (4, 8), (5, 8),
    (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14),
    (7, 14),
    (8, 14), (8, 13), (8, 12), (8, 11), (8, 10), (8, 9),
    (9, 8), (10, 8), (11, 8), (12, 8), (13, 8), (14, 8),
    (14, 7),
    (14, 6), (13, 6), (12, 6), (11, 6), (10, 6), (9, 6),
    (8, 5), (8, 4), (8, 3), (8, 2), (8, 1), (8, 0),
    (7, 0),
    (6, 0),
  ];

  /// Home columns (steps 51..55) as (row, col) grid coordinates.
  static const Map<LudoColor, List<(int, int)>> homeColumns = {
    LudoColor.red: [(7, 1), (7, 2), (7, 3), (7, 4), (7, 5)],
    LudoColor.green: [(1, 7), (2, 7), (3, 7), (4, 7), (5, 7)],
    LudoColor.yellow: [(7, 13), (7, 12), (7, 11), (7, 10), (7, 9)],
    LudoColor.blue: [(13, 7), (12, 7), (11, 7), (10, 7), (9, 7)],
  };

  /// Token parking spots inside each 6x6 base, as (row, col) in cell units.
  static const Map<LudoColor, List<(double, double)>> baseSpots = {
    LudoColor.red: [(1.5, 1.5), (1.5, 3.5), (3.5, 1.5), (3.5, 3.5)],
    LudoColor.green: [(1.5, 10.5), (1.5, 12.5), (3.5, 10.5), (3.5, 12.5)],
    LudoColor.yellow: [(10.5, 10.5), (10.5, 12.5), (12.5, 10.5), (12.5, 12.5)],
    LudoColor.blue: [(10.5, 1.5), (10.5, 3.5), (12.5, 1.5), (12.5, 3.5)],
  };

  /// Base rectangles as (topRow, leftCol) in grid cells; each is 6x6.
  static const Map<LudoColor, (int, int)> baseOrigins = {
    LudoColor.red: (0, 0),
    LudoColor.green: (0, 9),
    LudoColor.yellow: (9, 9),
    LudoColor.blue: (9, 0),
  };

  final List<LudoPlayer> players;
  final Random random;

  int currentPlayer = 0;
  int? diceValue;
  bool awaitingMove = false;
  int consecutiveSixes = 0;
  LudoColor? winner;

  LudoPlayer get current => players[currentPlayer];

  bool get isGameOver => winner != null;

  /// Main-track index (0..51) for a token at [steps], or null when the token
  /// is in base, in its home column, or finished.
  static int? trackIndexFor(LudoColor color, int steps) {
    if (steps < 0 || steps > 50) return null;
    return (startIndices[color.index] + steps) % trackLength;
  }

  /// Grid position (row, col) in cell units for a token at [steps].
  /// [tokenIndex] only matters for base spots and the finished centre.
  static (double, double) cellFor(
      LudoColor color, int steps, int tokenIndex) {
    if (steps == -1) return baseSpots[color]![tokenIndex];
    if (steps <= 50) {
      final cell = track[trackIndexFor(color, steps)!];
      return (cell.$1.toDouble(), cell.$2.toDouble());
    }
    if (steps <= 55) {
      final cell = homeColumns[color]![steps - 51];
      return (cell.$1.toDouble(), cell.$2.toDouble());
    }
    // Finished: park in the centre, one small offset per token.
    const offsets = [(7.0, 7.0), (7.0, 7.9), (7.9, 7.0), (7.9, 7.9)];
    return offsets[tokenIndex];
  }

  /// Token indexes the current player may legally move with [dice].
  List<int> legalMoves(int playerIndex, int dice) {
    final p = players[playerIndex];
    final moves = <int>[];
    for (var i = 0; i < tokensPerPlayer; i++) {
      final s = p.tokens[i];
      if (s == -1) {
        if (dice == 6) moves.add(i);
      } else if (s < finishSteps && s + dice <= finishSteps) {
        moves.add(i);
      }
    }
    return moves;
  }

  /// Roll a random dice. Handles the three-6s-forfeit rule and the
  /// no-legal-move pass. Returns a short human-readable event line, or null
  /// when the roll produced no event (normal roll with moves available).
  /// Call [applyMove] afterwards while [awaitingMove] is true.
  String? roll() => rollWithValue(random.nextInt(6) + 1);

  /// Same as [roll] but with a fixed dice value (used by tests and online
  /// play, where the dice value comes from the shared room state).
  String? rollWithValue(int value) {
    if (isGameOver || awaitingMove) return null;
    diceValue = value;
    if (value == 6) {
      consecutiveSixes++;
      if (consecutiveSixes >= 3) {
        consecutiveSixes = 0;
        diceValue = null;
        final name = current.name;
        _advanceTurn();
        return '$name rolled a third 6 in a row — turn forfeited.';
      }
    } else {
      consecutiveSixes = 0;
    }
    final moves = legalMoves(currentPlayer, value);
    if (moves.isEmpty) {
      diceValue = null;
      final name = current.name;
      _advanceTurn();
      return '$name rolled $value but has no legal move — turn passed.';
    }
    awaitingMove = true;
    return null;
  }

  /// Move [tokenIndex] of the current player by the rolled dice value.
  /// Returns details of what happened (capture, extra turn, win).
  MoveResult applyMove(int tokenIndex) {
    final dice = diceValue;
    if (dice == null || !awaitingMove) {
      throw StateError('No dice roll awaiting a move.');
    }
    final player = current;
    final fromSteps = player.tokens[tokenIndex];
    final toSteps = fromSteps == -1 ? 0 : fromSteps + dice;
    player.tokens[tokenIndex] = toSteps;

    // Capture: landing on a non-safe track cell sends every opponent token
    // standing there back to its base.
    final captured = <(int, int)>[];
    final landing = trackIndexFor(player.color, toSteps);
    if (landing != null && !safeIndices.contains(landing)) {
      for (var pi = 0; pi < players.length; pi++) {
        if (pi == currentPlayer) continue;
        final other = players[pi];
        for (var ti = 0; ti < tokensPerPlayer; ti++) {
          final s = other.tokens[ti];
          if (s >= 0 &&
              s <= 50 &&
              trackIndexFor(other.color, s) == landing) {
            other.tokens[ti] = -1;
            captured.add((pi, ti));
          }
        }
      }
    }

    final gameOver = player.hasWon;
    if (gameOver) winner = player.color;

    final extraTurn = dice == 6 && !gameOver;
    awaitingMove = false;
    diceValue = null;
    if (!extraTurn) {
      consecutiveSixes = 0;
      _advanceTurn();
    }
    return MoveResult(
      tokenIndex: tokenIndex,
      fromSteps: fromSteps,
      toSteps: toSteps,
      captured: captured,
      extraTurn: extraTurn,
      gameOver: gameOver,
    );
  }

  /// Pass the turn without moving (used online when the current player
  /// has dropped out — the game continues for everyone else).
  void passTurn() {
    if (isGameOver) return;
    diceValue = null;
    awaitingMove = false;
    consecutiveSixes = 0;
    _advanceTurn();
  }

  void _advanceTurn() {
    if (isGameOver) return;
    var next = currentPlayer;
    for (var i = 0; i < players.length; i++) {
      next = (next + 1) % players.length;
      if (!players[next].hasWon) break;
    }
    currentPlayer = next;
  }

  LudoEngine clone() => LudoEngine._clone(
        players.map((p) => p.copy()).toList(),
        currentPlayer,
        diceValue,
        awaitingMove,
        consecutiveSixes,
        winner,
        random,
      );

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'currentPlayer': currentPlayer,
        'diceValue': diceValue,
        'awaitingMove': awaitingMove,
        'consecutiveSixes': consecutiveSixes,
        'winner': winner?.index,
      };

  void restore(Map<String, dynamic> json) {
    final restored = (json['players'] as List)
        .map((p) => LudoPlayer.fromJson(
            Map<String, dynamic>.from(p as Map)))
        .toList();
    players
      ..clear()
      ..addAll(restored);
    currentPlayer = (json['currentPlayer'] as num).toInt();
    diceValue = json['diceValue'] as int?;
    awaitingMove = json['awaitingMove'] as bool? ?? false;
    consecutiveSixes = (json['consecutiveSixes'] as num?)?.toInt() ?? 0;
    final w = json['winner'] as int?;
    winner = w == null ? null : LudoColor.values[w];
  }
}
