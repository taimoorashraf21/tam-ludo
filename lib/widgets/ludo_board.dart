import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import 'ludo_colors.dart';

/// The 15x15 Ludo board: a static painted board plus tappable tokens.
///
/// The board itself is drawn once by [_BoardPainter] (wood-gold rim,
/// gradient bases, track cells, star safe cells, home columns, centre
/// triangles). Tokens are widgets layered on top so they stay big enough
/// to tap on a phone. All art is original and code-drawn.
///
/// The rim width must match [_BoardPainter]'s inset so tokens sit exactly
/// on their cells.
const double _boardRim = 7.0;

class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          // Tokens must use the same cell grid as the painter: the board
          // face is inset by [_boardRim] on every side.
          final cell = (size - 2 * _boardRim) / 15;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _BoardPainter(),
                ),
                ..._tokenWidgets(cell),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _tokenWidgets(double cell) {
    final widgets = <Widget>[];
    final engine = controller.engine;
    for (var pi = 0; pi < engine.players.length; pi++) {
      final player = engine.players[pi];
      for (var ti = 0; ti < LudoEngine.tokensPerPlayer; ti++) {
        final cellPos = controller.tokenCell(pi, ti);
        final coLocated =
            controller.tokensOnCell(cellPos.$1, cellPos.$2);
        final slot = coLocated.indexWhere((e) => e.$1 == pi && e.$2 == ti);
        final offset = _stackOffset(coLocated.length, slot, cell);
        final cx = _boardRim + (cellPos.$2 + 0.5) * cell + offset.$1;
        final cy = _boardRim + (cellPos.$1 + 0.5) * cell + offset.$2;
        final movable = controller.movableTokens.contains(ti) &&
            engine.currentPlayer == pi;
        // A generous invisible hit area around the visible token.
        final hit = cell * 1.5;
        widgets.add(
          Positioned(
            left: cx - hit / 2,
            top: cy - hit / 2,
            width: hit,
            height: hit,
            child: _TokenWidget(
              color: ludoColors[player.color]!,
              lightColor: ludoLightColors[player.color]!,
              darkColor: ludoDarkColors[player.color]!,
              diameter: cell * 0.86,
              movable: movable,
              finished: player.tokens[ti] == LudoEngine.finishSteps,
              onTap: movable ? () => controller.tapToken(ti) : null,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Small offsets so tokens sharing one cell sit side by side.
  (double, double) _stackOffset(int count, int slot, double cell) {
    if (count <= 1) return (0, 0);
    const spots = [
      (-0.22, -0.22),
      (0.22, -0.22),
      (-0.22, 0.22),
      (0.22, 0.22),
    ];
    if (count == 2) {
      return slot == 0 ? (-0.24 * cell, 0) : (0.24 * cell, 0);
    }
    final s = spots[slot.clamp(0, 3)];
    return (s.$1 * cell, s.$2 * cell);
  }
}

/// One token: a 3D-looking disc with a radial highlight and white ring.
/// Movable tokens pulse with a glowing ring.
class _TokenWidget extends StatefulWidget {
  const _TokenWidget({
    required this.color,
    required this.lightColor,
    required this.darkColor,
    required this.diameter,
    required this.movable,
    required this.finished,
    this.onTap,
  });

  final Color color;
  final Color lightColor;
  final Color darkColor;
  final double diameter;
  final bool movable;
  final bool finished;
  final VoidCallback? onTap;

  @override
  State<_TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<_TokenWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.movable) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TokenWidget old) {
    super.didUpdateWidget(old);
    if (widget.movable && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.movable && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disc = Center(
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.95,
            colors: [widget.lightColor, widget.color, widget.darkColor],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: widget.diameter * 0.3,
            height: widget.diameter * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.darkColor.withValues(alpha: 0.55),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
    if (!widget.movable) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: disc,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TamLudoTheme.gold.withValues(alpha: 0.5 + 0.5 * t),
                width: 2.5 + 2.5 * t,
              ),
              boxShadow: [
                BoxShadow(
                  color: TamLudoTheme.gold.withValues(alpha: 0.35 + 0.4 * t),
                  blurRadius: 8 + 6 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: disc,
      ),
    );
  }
}

/// Paints the static board: wood-gold rim, gradient bases, track, safe
/// stars, home columns, centre triangles.
class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = TamLudoTheme.boardLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final white = Paint()..color = Colors.white;

    // --- Outer wood-gold rim ---
    final rimRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rimRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TamLudoTheme.boardFrameLight,
            TamLudoTheme.boardFrame,
            TamLudoTheme.boardFrameDark,
          ],
        ).createShader(Offset.zero & size),
    );

    // --- Board face (inset inside the rim) ---
    const rim = _boardRim;
    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(rim, rim, size.width - 2 * rim, size.height - 2 * rim),
      const Radius.circular(10),
    );
    canvas.drawRRect(face, white);
    canvas.save();
    canvas.clipRRect(face);

    // Work in face coordinates: recompute the cell from the face size.
    final faceSize = size.width - 2 * rim;
    final f = faceSize / 15;
    final ox = rim;
    final oy = rim;
    Rect cellRect(double r, double c) =>
        Rect.fromLTWH(ox + c * f, oy + r * f, f, f);
    Offset cellCenter(double r, double c) =>
        Offset(ox + (c + 0.5) * f, oy + (r + 0.5) * f);

    Paint vGrad(Rect rect, Color top, Color bottom) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(rect);

    // --- Bases (6x6 corners) ---
    for (final color in LudoColor.values) {
      final (top, left) = LudoEngine.baseOrigins[color]!;
      final baseRect = Rect.fromLTWH(
        ox + left * f,
        oy + top * f,
        6 * f,
        6 * f,
      );
      canvas.drawRect(
        baseRect,
        vGrad(baseRect, ludoLightColors[color]!, ludoColors[color]!),
      );
      // Inner white panel.
      final inner = Rect.fromLTWH(
        ox + (left + 0.9) * f,
        oy + (top + 0.9) * f,
        4.2 * f,
        4.2 * f,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(f * 0.35)),
        Paint()..color = const Color(0xFFFFFBF2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(f * 0.35)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      // 3D parking spots.
      for (final (r, c) in LudoEngine.baseSpots[color]!) {
        final center = cellCenter(r, c);
        canvas.drawCircle(
          center,
          f * 0.44,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawCircle(
          center,
          f * 0.42,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 0.9,
              colors: [
                ludoLightColors[color]!,
                ludoColors[color]!,
                ludoDarkColors[color]!,
              ],
            ).createShader(Rect.fromCircle(center: center, radius: f * 0.42)),
        );
        canvas.drawCircle(
          Offset(center.dx - f * 0.12, center.dy - f * 0.12),
          f * 0.09,
          Paint()..color = Colors.white.withValues(alpha: 0.75),
        );
      }
    }

    // --- Main track cells ---
    final startCells = <int, LudoColor>{
      for (final c in LudoColor.values) LudoEngine.startIndices[c.index]: c,
    };
    for (var i = 0; i < LudoEngine.trackLength; i++) {
      final (r, c) = LudoEngine.track[i];
      final rect = cellRect(r.toDouble(), c.toDouble());
      final startColor = startCells[i];
      if (startColor != null) {
        canvas.drawRect(
          rect,
          vGrad(rect, ludoLightColors[startColor]!, ludoColors[startColor]!),
        );
        // Small white ring marks the start square.
        canvas.drawCircle(
          rect.center,
          f * 0.2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else if (LudoEngine.safeIndices.contains(i)) {
        canvas.drawRect(rect, Paint()..color = const Color(0xFFFFF3C4));
        _drawStar(canvas, rect.center, f * 0.32);
      } else {
        canvas.drawRect(rect, vGrad(rect, Colors.white, const Color(0xFFF1F5F9)));
      }
      canvas.drawRect(rect, line);
    }

    // --- Home columns ---
    for (final color in LudoColor.values) {
      for (final (r, c) in LudoEngine.homeColumns[color]!) {
        final rect = cellRect(r.toDouble(), c.toDouble());
        canvas.drawRect(
          rect,
          vGrad(rect, ludoLightColors[color]!, ludoColors[color]!),
        );
        canvas.drawRect(rect, line);
      }
    }

    // --- Centre home triangles (3x3, rows/cols 6-8) ---
    final centre = Offset(ox + 7.5 * f, oy + 7.5 * f);
    final corners = {
      LudoColor.green: [
        Offset(ox + 6 * f, oy + 6 * f),
        Offset(ox + 9 * f, oy + 6 * f),
      ],
      LudoColor.yellow: [
        Offset(ox + 9 * f, oy + 6 * f),
        Offset(ox + 9 * f, oy + 9 * f),
      ],
      LudoColor.blue: [
        Offset(ox + 9 * f, oy + 9 * f),
        Offset(ox + 6 * f, oy + 9 * f),
      ],
      LudoColor.red: [
        Offset(ox + 6 * f, oy + 9 * f),
        Offset(ox + 6 * f, oy + 6 * f),
      ],
    };
    for (final entry in corners.entries) {
      final path = Path()
        ..moveTo(entry.value[0].dx, entry.value[0].dy)
        ..lineTo(entry.value[1].dx, entry.value[1].dy)
        ..lineTo(centre.dx, centre.dy)
        ..close();
      canvas.drawPath(
        path,
        vGrad(
          Rect.fromPoints(entry.value[0], entry.value[1]),
          ludoLightColors[entry.key]!,
          ludoColors[entry.key]!,
        ),
      );
      canvas.drawPath(path, line);
    }
    // Tiny gold star at the very centre.
    _drawStar(canvas, centre, f * 0.34, color: TamLudoTheme.gold);
    canvas.drawCircle(
      centre,
      f * 0.34,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.restore();

    // Board outline.
    canvas.drawRRect(
      face,
      Paint()
        ..color = TamLudoTheme.boardLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius,
      {Color color = const Color(0xFFF59E0B)}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final r = i.isEven ? radius : radius * 0.45;
      final point = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
