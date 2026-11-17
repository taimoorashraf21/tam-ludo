import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_widgets.dart';
import '../widgets/ludo_board.dart';
import '../widgets/ludo_colors.dart';
import 'game_over_screen.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

/// The game screen: player panels, turn banner, board, 3D dice,
/// event line and move log — all on the green felt table.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.controller, this.setup});

  final GameController controller;

  /// Offline only: used by Play Again to rebuild the same game.
  final GameSetup? setup;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _navigatedToGameOver = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final engine = widget.controller.engine;
    if (engine.isGameOver && !_navigatedToGameOver) {
      _navigatedToGameOver = true;
      final winner =
          engine.players.firstWhere((p) => p.color == engine.winner);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GameOverScreen(
              winner: winner,
              setup: widget.setup,
              mode: widget.controller.mode,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: TamLudoTheme.feltBottom,
      appBar: AppBar(
        backgroundColor: TamLudoTheme.feltBottom,
        foregroundColor: Colors.white,
        title: const Text(
          'TAM Ludo',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Leave game',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: FeltBackground(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final engine = controller.engine;
            final current = engine.current;
            final currentColor = ludoColors[current.color]!;
            final currentLight = ludoLightColors[current.color]!;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  // Player panels — turn glow on the current player.
                  Row(
                    children: [
                      for (var i = 0; i < engine.players.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 4,
                              right: i == engine.players.length - 1 ? 0 : 4,
                            ),
                            child: _PlayerPanel(
                              player: engine.players[i],
                              isCurrent: engine.currentPlayer == i,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Turn banner.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [currentLight, currentColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TokenDisc(color: current.color, size: 22),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            controller.statusText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // The board.
                  LudoBoard(controller: controller),
                  const SizedBox(height: 14),
                  // Dice + event line.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DiceWidget(
                        face: controller.shownDice,
                        enabled: controller.canRoll,
                        rolling: controller.isRolling,
                        onTap: () => controller.rollDice(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (controller.shownDice != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: TamLudoTheme.gold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Last roll: ${controller.shownDice}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4E2F0E),
                                  ),
                                ),
                              ),
                            if (controller.lastEvent != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                controller.lastEvent!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            if (controller.engine.awaitingMove)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Tap a glowing token to move it.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            if (!controller.engine.awaitingMove &&
                                controller.lastEvent == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Tap the dice to roll.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            if (controller.currentPlayerAway &&
                                controller.mode == GameMode.online)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ElevatedButton(
                                  onPressed: controller.passAwayTurn,
                                  child: const Text('Pass away player’s turn'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Move log.
                  Container(
                    width: double.infinity,
                    height: 104,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TamLudoTheme.gold.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Game Log',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: controller.log.isEmpty
                              ? const Text(
                                  'Moves will appear here.',
                                  style: TextStyle(color: Colors.black45),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  itemCount: controller.log.length,
                                  itemBuilder: (context, i) {
                                    final line = controller.log[
                                        controller.log.length - 1 - i];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        line,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One player's panel: avatar, name, tokens-home count, CPU badge.
/// The current player's panel glows gold.
class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({required this.player, required this.isCurrent});

  final LudoPlayer player;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = ludoColors[player.color]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? TamLudoTheme.gold : color.withValues(alpha: 0.6),
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: TamLudoTheme.gold.withValues(alpha: 0.55),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          PlayerAvatar(
            color: player.color,
            name: player.name,
            size: 38,
            glowing: isCurrent,
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCurrent ? TamLudoTheme.ink : Colors.white,
            ),
          ),
          Text(
            '${player.finishedCount}/4 home'
            '${player.isAI ? ' • CPU' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCurrent ? Colors.black54 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
