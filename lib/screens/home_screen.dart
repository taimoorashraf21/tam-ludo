import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/online_service.dart';
import 'lobby_screen.dart';
import 'setup_screen.dart';

/// Home: title, three mode buttons, and a short how-to-play section.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onlineReady = OnlineService.isConfigured;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const _LogoTitle(),
              const SizedBox(height: 8),
              const Text(
                'Classic Ludo — vs computer, with friends\non one phone, or online with a room code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              _ModeButton(
                label: 'Vs Computer',
                subtitle: 'You against 1–3 computer opponents',
                icon: Icons.computer,
                color: const Color(0xFFE53935),
                onTap: () => _openSetup(context, GameMode.vsComputer),
              ),
              const SizedBox(height: 12),
              _ModeButton(
                label: 'Pass & Play',
                subtitle: '2–4 friends on this phone',
                icon: Icons.people,
                color: const Color(0xFF43A047),
                onTap: () => _openSetup(context, GameMode.passAndPlay),
              ),
              const SizedBox(height: 12),
              _ModeButton(
                label: 'Online',
                subtitle: onlineReady
                    ? 'Create or join a room with a code'
                    : 'Online setup pending — see ONLINE_SETUP.md',
                icon: Icons.public,
                color: const Color(0xFF1E88E5),
                enabled: onlineReady,
                onTap: () => _openLobby(context),
              ),
              const SizedBox(height: 28),
              const Text(
                'How to play',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const _RuleLine('Roll a 6 to bring a token out of your base.'),
              const _RuleLine('Rolling a 6 gives you another turn — but '
                  'three 6s in a row forfeits your turn.'),
              const _RuleLine('Land on an opponent to send them back to '
                  'base. Star squares and start squares are safe.'),
              const _RuleLine('You need an exact roll to enter the centre. '
                  'First to bring all 4 tokens home wins.'),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'TAM Ludo • original game, no ads, no sign-up',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            ],
          ),
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

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(color: const Color(0xFFE53935)),
            _Dot(color: const Color(0xFF43A047)),
            _Dot(color: const Color(0xFFF9C80E)),
            _Dot(color: const Color(0xFF1E88E5)),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'TAM LUDO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Color(0xFF0F766E),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 15)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
