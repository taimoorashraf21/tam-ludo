import 'package:material_ui/material_ui.dart';

import '../game/ludo_engine.dart';
import 'ludo_colors.dart';

/// Deep-green "felt table" background with a soft glow and faint
/// decorative token dots. Wraps whole screens.
class FeltBackground extends StatelessWidget {
  const FeltBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TamLudoTheme.feltTop,
            TamLudoTheme.feltMid,
            TamLudoTheme.feltBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Soft glow at the top.
          Positioned(
            top: -90,
            left: 0,
            right: 0,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TamLudoTheme.feltGlow.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Faint decorative token dots.
          const Positioned(
            top: 64,
            left: -24,
            child: _GhostDot(color: Color(0xFFE53935)),
          ),
          const Positioned(
            top: 150,
            right: -18,
            child: _GhostDot(color: Color(0xFFF9C80E)),
          ),
          const Positioned(
            bottom: 120,
            left: -30,
            child: _GhostDot(color: Color(0xFF1E88E5)),
          ),
          const Positioned(
            bottom: 40,
            right: -22,
            child: _GhostDot(color: Color(0xFF43A047)),
          ),
          child,
        ],
      ),
    );
  }
}

class _GhostDot extends StatelessWidget {
  const _GhostDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 2,
        ),
      ),
    );
  }
}

/// A 3D-looking token disc: radial highlight, white ring, soft shadow.
/// Used for avatars, the title row, and the mini board.
class TokenDisc extends StatelessWidget {
  const TokenDisc({
    super.key,
    required this.color,
    this.size = 40,
    this.child,
  });

  final LudoColor color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final base = ludoColors[color]!;
    final light = ludoLightColors[color]!;
    final dark = ludoDarkColors[color]!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Colors.white, width: size * 0.07),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A player's avatar: token disc with their initial, plus an optional
/// gold glow ring when it is their turn.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.color,
    required this.name,
    this.size = 44,
    this.glowing = false,
  });

  final LudoColor color;
  final String name;
  final double size;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final disc = TokenDisc(
      color: color,
      size: size,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
    if (!glowing) return disc;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TamLudoTheme.gold, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: TamLudoTheme.gold.withValues(alpha: 0.7),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: disc,
    );
  }
}

/// Big polished gold gradient button (PLAY, Start Game, Rematch…).
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final on = enabled && onTap != null;
    return Opacity(
      opacity: on ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: on ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TamLudoTheme.goldLight,
                  TamLudoTheme.gold,
                  TamLudoTheme.goldDark,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 28, color: const Color(0xFF4E2F0E)),
                    const SizedBox(width: 10),
                  ],
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Color(0xFF4E2F0E),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D4C1F),
                          ),
                        ),
                    ],
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

/// A polished mode card: coloured icon disc, title, subtitle, chevron.
class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
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
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final on = enabled && onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: on ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 26, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TamLudoTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: color, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small decorative preview of the board (original, code-drawn).
class MiniBoardPreview extends StatelessWidget {
  const MiniBoardPreview({super.key, this.size = 190});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TamLudoTheme.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: CustomPaint(
          size: Size.square(size),
          painter: _MiniBoardPainter(),
        ),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final line = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    // Corner bases.
    for (final color in LudoColor.values) {
      final (top, left) = LudoEngine.baseOrigins[color]!;
      final baseRect = Rect.fromLTWH(left * cell, top * cell, 6 * cell, 6 * cell);
      canvas.drawRect(baseRect, Paint()..color = ludoColors[color]!);
      final inner = Rect.fromLTWH(
        (left + 0.9) * cell,
        (top + 0.9) * cell,
        4.2 * cell,
        4.2 * cell,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.35)),
        Paint()..color = Colors.white,
      );
      for (final (r, c) in LudoEngine.baseSpots[color]!) {
        canvas.drawCircle(
          Offset((c + 0.5) * cell, (r + 0.5) * cell),
          cell * 0.4,
          Paint()..color = ludoColors[color]!,
        );
      }
    }

    // Track cells.
    for (var i = 0; i < LudoEngine.trackLength; i++) {
      final (r, c) = LudoEngine.track[i];
      final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
      if (LudoEngine.safeIndices.contains(i) &&
          !LudoEngine.startIndices.contains(i)) {
        canvas.drawRect(rect, Paint()..color = const Color(0xFFFFF3C4));
      } else if (LudoEngine.startIndices.contains(i)) {
        final color = LudoColor.values[LudoEngine.startIndices.indexOf(i)];
        canvas.drawRect(rect, Paint()..color = ludoColors[color]!);
      } else {
        canvas.drawRect(rect, Paint()..color = Colors.white);
      }
      canvas.drawRect(rect, line);
    }

    // Home columns.
    for (final color in LudoColor.values) {
      for (final (r, c) in LudoEngine.homeColumns[color]!) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        canvas.drawRect(rect, Paint()..color = ludoColors[color]!);
        canvas.drawRect(rect, line);
      }
    }

    // Centre triangles.
    final centre = Offset(7.5 * cell, 7.5 * cell);
    final corners = {
      LudoColor.green: [Offset(6 * cell, 6 * cell), Offset(9 * cell, 6 * cell)],
      LudoColor.yellow: [Offset(9 * cell, 6 * cell), Offset(9 * cell, 9 * cell)],
      LudoColor.blue: [Offset(9 * cell, 9 * cell), Offset(6 * cell, 9 * cell)],
      LudoColor.red: [Offset(6 * cell, 9 * cell), Offset(6 * cell, 6 * cell)],
    };
    for (final entry in corners.entries) {
      final path = Path()
        ..moveTo(entry.value[0].dx, entry.value[0].dy)
        ..lineTo(entry.value[1].dx, entry.value[1].dy)
        ..lineTo(centre.dx, centre.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = ludoColors[entry.key]!);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
