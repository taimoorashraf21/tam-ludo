import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_board.dart';
import '../widgets/ludo_colors.dart';
import 'game_over_screen.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

/// The game screen: turn banner, board, dice, event line and move log.
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
      appBar: AppBar(
        title: const Text('TAM Ludo'),
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
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final engine = controller.engine;
          final current = engine.current;
          final currentColor = ludoColors[current.color]!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Turn banner.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // The board.
                LudoBoard(controller: controller),
                const SizedBox(height: 12),
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
                          if (controller.lastEvent != null)
                            Text(
                              controller.lastEvent!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (controller.engine.awaitingMove)
                            const Text(
                              'Tap a glowing token to move it.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
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
                const SizedBox(height: 12),
                // Move log.
                Container(
                  width: double.infinity,
                  height: 104,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: controller.log.isEmpty
                      ? const Text(
                          'Moves will appear here.',
                          style: TextStyle(color: Colors.black45),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: controller.log.length,
                          itemBuilder: (context, i) {
                            final line = controller
                                .log[controller.log.length - 1 - i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                line,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                // Finished tokens per player.
                Wrap(
                  spacing: 12,
                  children: [
                    for (final p in engine.players)
                      _PlayerChip(player: p),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.player});

  final LudoPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ludoColors[player.color]!.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ludoColors[player.color]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ludoColors[player.color],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${player.name}: ${player.finishedCount}/4 home'
            '${player.isAI ? ' (CPU)' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
