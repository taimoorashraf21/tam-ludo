import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import 'ludo_colors.dart';

/// The 15x15 Ludo board: a static painted board plus tappable tokens.
///
/// The board itself is drawn once by [_BoardPainter] (bases, track cells,
/// start cells, star safe cells, home columns, centre triangles). Tokens
/// are widgets layered on top so they stay big enough to tap on a phone.
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
          final cell = size / 15;
          return Stack(
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _BoardPainter(),
              ),
              ..._tokenWidgets(cell),
            ],
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
        final cx = (cellPos.$2 + 0.5) * cell + offset.$1;
        final cy = (cellPos.$1 + 0.5) * cell + offset.$2;
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
              darkColor: ludoDarkColors[player.color]!,
              diameter: cell * 0.82,
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

/// One token: a coloured disc with a white ring. Movable tokens pulse.
class _TokenWidget extends StatefulWidget {
  const _TokenWidget({
    required this.color,
    required this.darkColor,
    required this.diameter,
    required this.movable,
    required this.finished,
    this.onTap,
  });

  final Color color;
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
          color: widget.color,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: widget.diameter * 0.34,
            height: widget.diameter * 0.34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.darkColor.withValues(alpha: 0.55),
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
                color: widget.darkColor.withValues(alpha: 0.35 + 0.6 * t),
                width: 2.5 + 2.5 * t,
              ),
            ),
            child: child,
          );
        },
        child: disc,
      ),
    );
  }
}

/// Paints the static board: bases, track, safe stars, home columns, centre.
class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final line = Paint()
      ..color = TamLudoTheme.boardLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final white = Paint()..color = Colors.white;

    // Board background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(10),
      ),
      white,
    );

    // --- Bases (6x6 corners) ---
    for (final color in LudoColor.values) {
      final (top, left) = LudoEngine.baseOrigins[color]!;
      final baseRect = Rect.fromLTWH(
        left * cell,
        top * cell,
        6 * cell,
        6 * cell,
      );
      canvas.drawRect(baseRect, Paint()..color = ludoColors[color]!);
      // Inner white area.
      final inner = Rect.fromLTWH(
        (left + 0.9) * cell,
        (top + 0.9) * cell,
        4.2 * cell,
        4.2 * cell,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.35)),
        white,
      );
      // Token parking spots.
      for (final (r, c) in LudoEngine.baseSpots[color]!) {
        canvas.drawCircle(
          Offset((c + 0.5) * cell, (r + 0.5) * cell),
          cell * 0.42,
          Paint()..color = ludoColors[color]!,
        );
        canvas.drawCircle(
          Offset((c + 0.5) * cell, (r + 0.5) * cell),
          cell * 0.42,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // --- Main track cells ---
    final startCells = <int, LudoColor>{
      for (final c in LudoColor.values) LudoEngine.startIndices[c.index]: c,
    };
    for (var i = 0; i < LudoEngine.trackLength; i++) {
      final (r, c) = LudoEngine.track[i];
      final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
      final startColor = startCells[i];
      if (startColor != null) {
        canvas.drawRect(rect, Paint()..color = ludoColors[startColor]!);
      } else if (LudoEngine.safeIndices.contains(i)) {
        canvas.drawRect(rect, Paint()..color = const Color(0xFFFFF3C4));
        _drawStar(canvas, rect.center, cell * 0.32);
      } else {
        canvas.drawRect(rect, white);
      }
      canvas.drawRect(rect, line);
    }

    // --- Home columns ---
    for (final color in LudoColor.values) {
      for (final (r, c) in LudoEngine.homeColumns[color]!) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        canvas.drawRect(rect, Paint()..color = ludoColors[color]!);
        canvas.drawRect(rect, line);
      }
    }

    // --- Centre home triangle (3x3, rows/cols 6-8) ---
    final centre = Offset(7.5 * cell, 7.5 * cell);
    final corners = {
      LudoColor.green: [Offset(6 * cell, 6 * cell), Offset(9 * cell, 6 * cell)],
      LudoColor.yellow: [
        Offset(9 * cell, 6 * cell),
        Offset(9 * cell, 9 * cell),
      ],
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

    // Board outline.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(10),
      ),
      Paint()
        ..color = TamLudoTheme.boardLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
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
    canvas.drawPath(path, Paint()..color = const Color(0xFFE65100));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
