import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import '../widgets/game_widgets.dart';
import '../widgets/ludo_colors.dart';
import 'board_screen.dart';

/// Setup for Vs Computer and Pass & Play: player count (2-4), names,
/// and (for Vs Computer) which seats are computer-controlled.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _playerCount = 2;
  final List<TextEditingController> _nameControllers = [];
  final List<bool> _isAi = [];

  /// Seat colours by player count. 2 players sit opposite each other.
  static const Map<int, List<LudoColor>> _seatColors = {
    2: [LudoColor.red, LudoColor.yellow],
    3: [LudoColor.red, LudoColor.green, LudoColor.yellow],
    4: [LudoColor.red, LudoColor.green, LudoColor.yellow, LudoColor.blue],
  };

  List<LudoColor> get _colors => _seatColors[_playerCount]!;

  @override
  void initState() {
    super.initState();
    _resetSeats();
  }

  void _resetSeats() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    _nameControllers.clear();
    _isAi.clear();
    for (var i = 0; i < _playerCount; i++) {
      final color = _colors[i];
      final isComputer =
          widget.mode == GameMode.vsComputer && i > 0;
      _nameControllers.add(
        TextEditingController(
          text: isComputer ? 'Computer $i' : color.label,
        ),
      );
      _isAi.add(isComputer);
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setCount(int count) {
    setState(() {
      _playerCount = count;
      _resetSeats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVsComputer = widget.mode == GameMode.vsComputer;
    return Scaffold(
      backgroundColor: TamLudoTheme.feltBottom,
      appBar: AppBar(
        backgroundColor: TamLudoTheme.feltBottom,
        foregroundColor: Colors.white,
        title: Text(
          isVsComputer ? 'Vs Computer' : 'Pass & Play',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: FeltBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Players',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TamLudoTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('2')),
                        ButtonSegment(value: 3, label: Text('3')),
                        ButtonSegment(value: 4, label: Text('4')),
                      ],
                      selected: {_playerCount},
                      onSelectionChanged: (s) => _setCount(s.first),
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < _playerCount; i++) _playerRow(i),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GoldButton(
                label: 'START GAME',
                icon: Icons.play_arrow,
                onTap: _startGame,
              ),
              if (isVsComputer) ...[
                const SizedBox(height: 14),
                const Text(
                  'Computer opponents use one fixed difficulty: they '
                  'capture when they can, prefer safe squares, and avoid '
                  'leaving tokens exposed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerRow(int i) {
    final color = _colors[i];
    final isComputer = _isAi[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          PlayerAvatar(
            color: color,
            name: _nameControllers[i].text,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameControllers[i],
              decoration: InputDecoration(
                labelText:
                    'Player ${i + 1} — ${color.label}${isComputer ? ' (Computer)' : ''}',
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: TamLudoTheme.creamCard,
              ),
            ),
          ),
          if (widget.mode == GameMode.passAndPlay) ...[
            const SizedBox(width: 8),
            const Icon(Icons.person, color: Colors.black54),
          ],
        ],
      ),
    );
  }

  void _startGame() {
    final players = <LudoPlayer>[];
    for (var i = 0; i < _playerCount; i++) {
      final name = _nameControllers[i].text.trim().isEmpty
          ? _colors[i].label
          : _nameControllers[i].text.trim();
      players.add(
        LudoPlayer(color: _colors[i], name: name, isAI: _isAi[i]),
      );
    }
    final controller = GameController(mode: widget.mode, players: players);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(
          controller: controller,
          setup: GameSetup(mode: widget.mode, players: players),
        ),
      ),
    );
  }
}

/// Everything needed to rebuild the same game (used by Play Again).
class GameSetup {
  const GameSetup({required this.mode, required this.players});

  final GameMode mode;
  final List<LudoPlayer> players;

  GameController buildController() =>
      GameController(mode: mode, players: players);
}
