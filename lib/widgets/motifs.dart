import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Background layers

/// Faint cream dot grid — drop at the bottom of a Stack as the canvas.
class DotGridBackground extends StatelessWidget {
  final double spacing;
  final double opacity;
  final Color color;
  final double radius;
  const DotGridBackground({
    super.key,
    this.spacing = 16,
    this.opacity = 0.18,
    this.color = TM.cream,
    this.radius = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DotGridPainter(
            spacing: spacing,
            radius: radius,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final double spacing;
  final double radius;
  final Color color;
  _DotGridPainter({
    required this.spacing,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.spacing != spacing || old.color != color || old.radius != radius;
}

/// Same dot grid but its vertical position tracks a [ScrollController]'s
/// offset, multiplied by [factor] (default 0.15 — subtle). The grid canvas is
/// extended below the viewport by [bufferPx] so scrolling never reveals a
/// gap. Painted inside its own [RepaintBoundary] and listens to the controller
/// directly via [AnimatedBuilder] (no setState), so foreground content does
/// not rebuild on scroll.
class ParallaxDotGrid extends StatelessWidget {
  final ScrollController controller;
  final double factor;
  final double bufferPx;
  final double spacing;
  final double opacity;
  final Color color;
  final double radius;

  const ParallaxDotGrid({
    super.key,
    required this.controller,
    this.factor = 0.15,
    this.bufferPx = 200,
    this.spacing = 16,
    this.opacity = 0.18,
    this.color = TM.cream,
    this.radius = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final dotCanvas = OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight + bufferPx,
                  child: CustomPaint(
                    painter: _DotGridPainter(
                      spacing: spacing,
                      radius: radius,
                      color: color.withValues(alpha: opacity),
                    ),
                  ),
                ),
              );
              return RepaintBoundary(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (_, child) {
                    final off =
                        controller.hasClients ? controller.offset : 0.0;
                    return Transform.translate(
                      offset: Offset(0, -off * factor),
                      child: child,
                    );
                  },
                  child: dotCanvas,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Subtle halftone/noise overlay — drop at the TOP of a Stack.
class GrainOverlay extends StatelessWidget {
  final double opacity;
  final int seed;
  const GrainOverlay({super.key, this.opacity = 0.22, this.seed = 7});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GrainPainter(opacity: opacity, seed: seed),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  final double opacity;
  final int seed;
  _GrainPainter({required this.opacity, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const density = 0.0018; // specks per pixel^2
    final n = (size.width * size.height * density).round();
    final paint = Paint()
      ..color = TM.cream.withValues(alpha: opacity)
      ..blendMode = BlendMode.plus;
    for (int i = 0; i < n; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.9 + 0.2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      old.opacity != opacity || old.seed != seed;
}

// Small decorative shapes

/// Wobbly tomato marker underline — good under section headings.
class MarkerUnderline extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;
  const MarkerUnderline({
    super.key,
    this.width = 120,
    this.height = 8,
    this.color = TM.tomato,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MarkerUnderlinePainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _MarkerUnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _MarkerUnderlinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final path = Path()
      ..moveTo(2, 5)
      ..quadraticBezierTo(w * 0.3, 1, w * 0.5, 4)
      ..quadraticBezierTo(w * 0.7, 7, w * 0.9, 4);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkerUnderlinePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Sine-bump squiggle — Memphis staple.
class Squiggle extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;
  const Squiggle({
    super.key,
    this.width = 80,
    this.height = 14,
    this.color = TM.lemon,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SquigglePainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _SquigglePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path();
    final midY = s.height / 2;
    final amp = (s.height / 2) - 1;
    const cycles = 4;
    final step = s.width / (cycles * 2);
    path.moveTo(0, midY);
    for (int i = 0; i < cycles * 2; i++) {
      final cx = step * i + step / 2;
      final cy = midY + (i.isEven ? -amp : amp);
      final ex = step * (i + 1);
      path.quadraticBezierTo(cx, cy, ex, midY);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SquigglePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Lightning bolt icon with ink outline.
class Bolt extends StatelessWidget {
  final double size;
  final Color color;
  const Bolt({super.key, this.size = 16, this.color = TM.lemon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BoltPainter(color: color)),
    );
  }
}

class _BoltPainter extends CustomPainter {
  final Color color;
  _BoltPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final sx = s.width / 16;
    final sy = s.height / 16;
    final path = Path()
      ..moveTo(9 * sx, 1 * sy)
      ..lineTo(2 * sx, 9 * sy)
      ..lineTo(7 * sx, 9 * sy)
      ..lineTo(6 * sx, 15 * sy)
      ..lineTo(14 * sx, 6 * sy)
      ..lineTo(9 * sx, 6 * sy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = TM.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BoltPainter old) => old.color != color;
}

/// 4-point star / spark.
class Spark extends StatelessWidget {
  final double size;
  final Color color;
  const Spark({super.key, this.size = 14, this.color = TM.lemon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparkPainter(color: color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  _SparkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final sx = s.width / 14;
    final sy = s.height / 14;
    final path = Path()
      ..moveTo(7 * sx, 0)
      ..lineTo(8.3 * sx, 5.7 * sy)
      ..lineTo(14 * sx, 7 * sy)
      ..lineTo(8.3 * sx, 8.3 * sy)
      ..lineTo(7 * sx, 14 * sy)
      ..lineTo(5.7 * sx, 8.3 * sy)
      ..lineTo(0, 7 * sy)
      ..lineTo(5.7 * sx, 5.7 * sy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.color != color;
}

/// 2-row checker strip.
class Checker extends StatelessWidget {
  final double width;
  final int cellsX;
  final Color color;
  const Checker({
    super.key,
    this.width = 40,
    this.cellsX = 8,
    this.color = TM.lemon,
  });

  @override
  Widget build(BuildContext context) {
    final cellW = width / cellsX;
    return SizedBox(
      width: width,
      height: cellW * 2,
      child: CustomPaint(
        painter: _CheckerPainter(cellsX: cellsX, color: color),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  final int cellsX;
  final Color color;
  _CheckerPainter({required this.cellsX, required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final cellW = s.width / cellsX;
    final paint = Paint()..color = color;
    for (int y = 0; y < 2; y++) {
      for (int x = 0; x < cellsX; x++) {
        if ((x + y) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellW, cellW, cellW),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter old) =>
      old.cellsX != cellsX || old.color != color;
}

/// Two offset circles in tomato + cobalt
class RisoHalo extends StatelessWidget {
  final double size;
  final double offset;
  const RisoHalo({super.key, this.size = 180, this.offset = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -offset,
            top: -offset,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TM.tomato.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            left: offset,
            top: offset,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TM.cobalt.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
