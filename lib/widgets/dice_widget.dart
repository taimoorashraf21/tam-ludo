import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A tappable 3D-looking dice. [face] is 1-6 (null before the first roll
/// shows a "?"). While [rolling] the dice wobbles and the face flashes
/// (the flash itself is driven by the controller).
class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.face,
    required this.enabled,
    required this.rolling,
    required this.onTap,
  });

  final int? face;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didUpdateWidget(covariant DiceWidget old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !_wobble.isAnimating) {
      _wobble.repeat(reverse: true);
    } else if (!widget.rolling && _wobble.isAnimating) {
      _wobble.stop();
      _wobble.value = 0;
    }
  }

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dice = GestureDetector(
      onTap: widget.enabled && !widget.rolling ? widget.onTap : null,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFE8EDF2), Color(0xFFCBD5E1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF94A3B8), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: widget.face == null
              ? const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _DicePipsPainter(widget.face!),
                ),
        ),
      ),
    );
    if (!widget.rolling) return dice;
    return AnimatedBuilder(
      animation: _wobble,
      builder: (context, child) {
        final t = _wobble.value;
        return Transform.rotate(
          angle: (t - 0.5) * 0.35,
          child: Transform.scale(
            scale: 1.0 + 0.06 * math.sin(t * math.pi),
            child: child,
          ),
        );
      },
      child: dice,
    );
  }
}

class _DicePipsPainter extends CustomPainter {
  _DicePipsPainter(this.face);

  final int face;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.11;
    final q = size.width / 4; // quarter positions
    final Set<(double, double)> show = switch (face) {
      1 => {(2 * q, 2 * q)},
      2 => {(q, q), (3 * q, 3 * q)},
      3 => {(q, q), (2 * q, 2 * q), (3 * q, 3 * q)},
      4 => {(q, q), (3 * q, q), (q, 3 * q), (3 * q, 3 * q)},
      5 => {(q, q), (3 * q, q), (2 * q, 2 * q), (q, 3 * q), (3 * q, 3 * q)},
      _ => {
          (q, q),
          (3 * q, q),
          (q, 2 * q),
          (3 * q, 2 * q),
          (q, 3 * q),
          (3 * q, 3 * q),
        },
    };
    for (final (x, y) in show) {
      // Dark pip with a tiny top-left highlight so it reads as a dimple.
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = const Color(0xFF1E293B),
      );
      canvas.drawCircle(
        Offset(x - r * 0.3, y - r * 0.3),
        r * 0.35,
        Paint()..color = const Color(0xFF64748B),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DicePipsPainter old) => old.face != face;
}
