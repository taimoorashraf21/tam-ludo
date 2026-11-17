import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import '../game/online_service.dart';
import '../widgets/game_widgets.dart';
import 'lobby_screen.dart';
import 'setup_screen.dart';
import 'board_screen.dart';
import '../widgets/ludo_colors.dart';

/// Home: player profile bar, title, big PLAY button, mini board preview,
/// the three mode cards, stats, and a styled how-to-play card.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onlineReady = OnlineService.isConfigured;
    return Scaffold(
      backgroundColor: TamLudoTheme.feltBottom,
      body: FeltBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProfileBar(),
                const SizedBox(height: 18),
                const _LogoTitle(),
                const SizedBox(height: 18),
                GoldButton(
                  label: 'PLAY',
                  subtitle: 'Quick game vs Computer',
                  icon: Icons.play_arrow,
                  onTap: () => _quickPlay(context),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => _quickPlay(context),
                    child: const MiniBoardPreview(size: 188),
                  ),
                ),
                const SizedBox(height: 20),
                ModeCard(
                  label: 'Vs Computer',
                  subtitle: 'You against 1–3 computer opponents',
                  icon: Icons.computer,
                  color: const Color(0xFFE53935),
                  onTap: () => _openSetup(context, GameMode.vsComputer),
                ),
                const SizedBox(height: 12),
                ModeCard(
                  label: 'Pass & Play',
                  subtitle: '2–4 friends on this phone',
                  icon: Icons.people,
                  color: const Color(0xFF43A047),
                  onTap: () => _openSetup(context, GameMode.passAndPlay),
                ),
                const SizedBox(height: 12),
                ModeCard(
                  label: 'Online',
                  subtitle: onlineReady
                      ? 'Create or join a room with a code'
                      : 'Online setup pending — see ONLINE_SETUP.md',
                  icon: Icons.public,
                  color: const Color(0xFF1E88E5),
                  enabled: onlineReady,
                  onTap: () => _openLobby(context),
                ),
                const SizedBox(height: 18),
                const _StatsRow(),
                const SizedBox(height: 18),
                const _HowToPlayCard(),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'TAM Ludo • original game, no ads, no sign-up',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One tap straight into a 2-player game vs the computer.
  void _quickPlay(BuildContext context) {
    final players = [
      LudoPlayer(color: LudoColor.red, name: 'You'),
      LudoPlayer(color: LudoColor.yellow, name: 'Computer 1', isAI: true),
    ];
    final setup = GameSetup(mode: GameMode.vsComputer, players: players);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(
          controller: setup.buildController(),
          setup: setup,
        ),
      ),
    );
  }

  void _openSetup(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SetupScreen(mode: mode)),
    );
  }

  void _openLobby(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LobbyScreen()),
    );
  }
}

/// Top bar: avatar + name + level progress, coins and gems counters.
class _ProfileBar extends StatelessWidget {
  const _ProfileBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PlayerAvatar(color: LudoColor.red, name: 'You', size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TamLudoTheme.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Lv 1',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4E2F0E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.25,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TamLudoTheme.gold,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '125 / 500 XP to Level 2',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _CurrencyChip(icon: Icons.monetization_on, label: '1,000'),
        const SizedBox(width: 8),
        _CurrencyChip(icon: Icons.diamond, label: '25'),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TamLudoTheme.gold.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TamLudoTheme.gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TokenDisc(color: LudoColor.red, size: 26),
            SizedBox(width: 8),
            TokenDisc(color: LudoColor.green, size: 26),
            SizedBox(width: 8),
            TokenDisc(color: LudoColor.yellow, size: 26),
            SizedBox(width: 8),
            TokenDisc(color: LudoColor.blue, size: 26),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'TAM LUDO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white,
            shadows: [
              Shadow(
                color: TamLudoTheme.gold.withValues(alpha: 0.8),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
              const Shadow(
                color: Colors.black54,
                offset: Offset(0, 5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const Text(
          'Classic Ludo — vs computer, with friends\non one phone, or online with a room code.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatChip(icon: Icons.emoji_events, label: 'Wins', value: '0')),
        SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.casino, label: 'Games', value: '0')),
        SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.bolt, label: 'Captures', value: '0')),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: TamLudoTheme.gold),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayCard extends StatelessWidget {
  const _HowToPlayCard();

  static const _rules = [
    'Roll a 6 to bring a token out of your base.',
    'Rolling a 6 gives you another turn — but three 6s in a row forfeits your turn.',
    'Land on an opponent to send them back to base. Star squares and start squares are safe.',
    'You need an exact roll to enter the centre. First to bring all 4 tokens home wins.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: TamLudoTheme.primary),
              SizedBox(width: 8),
              Text(
                'How to play',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TamLudoTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _rules.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ludoColors[LudoColor.values[i]]!,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _rules[i],
                      style: const TextStyle(
                        fontSize: 14,
                        color: TamLudoTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
