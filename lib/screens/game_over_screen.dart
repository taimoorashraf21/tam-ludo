import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import '../widgets/game_widgets.dart';
import '../widgets/ludo_colors.dart';
import 'board_screen.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

/// Winner announcement with Rematch / Home.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.winner,
    required this.mode,
    this.setup,
  });

  final LudoPlayer winner;
  final GameMode mode;
  final GameSetup? setup;

  @override
  Widget build(BuildContext context) {
    final canReplay = setup != null && mode != GameMode.online;
    return Scaffold(
      backgroundColor: TamLudoTheme.feltBottom,
      body: FeltBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy in a gold ring.
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TamLudoTheme.goldLight,
                          TamLudoTheme.gold,
                          TamLudoTheme.goldDark,
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: TamLudoTheme.gold.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                        const BoxShadow(
                          color: Colors.black45,
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 62,
                      color: Color(0xFF4E2F0E),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PlayerAvatar(
                        color: winner.color,
                        name: winner.name,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '${winner.name} wins!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${winner.color.label} brought all 4 tokens home.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  if (canReplay)
                    SizedBox(
                      width: double.infinity,
                      child: GoldButton(
                        label: 'REMATCH',
                        icon: Icons.replay,
                        onTap: () {
                          final controller = setup!.buildController();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => BoardScreen(
                                controller: controller,
                                setup: setup,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomeScreen(),
                        ),
                        (route) => false,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
