import 'package:material_ui/material_ui.dart';

/// A tappable dice. [face] is 1-6 (null before the first roll shows a "?").
/// While [rolling] the face flashes rapidly (driven by the controller).
class DiceWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !rolling ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade400, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: face == null
              ? const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _DicePipsPainter(face!),
                ),
        ),
      ),
    );
  }
}

class _DicePipsPainter extends CustomPainter {
  _DicePipsPainter(this.face);

  final int face;

  @override
  void paint(Canvas canvas, Size size) {
    final pip = Paint()..color = const Color(0xFF263238);
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
      canvas.drawCircle(Offset(x, y), r, pip);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePipsPainter old) => old.face != face;
}
