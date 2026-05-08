import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Local frost palette — deliberately not in TM, since this is a one-off
// material used for the freeze gesture. Pale, cool, never saturated.
const Color _iceWhite = Color(0xFFF0F8FF);
const Color _iceLight = Color(0xFFC8E2FF);
const Color _iceMid = Color(0xFF94BEFF);

/// Wraps [child] with a cold-border + frost-glass overlay whose intensity is
/// driven by [progress] (`0.0 = invisible, 1.0 = fully frozen`). The border
/// stroke is painted with a sweep gradient whose angular offset is driven by
/// [shimmerPhase] (0..1, expected to loop), giving a shimmering "light-on-ice"
/// feel that stays alive even while the user holds the modal open.
///
/// Pure presentation — owns no animation. The hosting widget is responsible
/// for ticking both progress and shimmer phase (typically via two
/// [AnimationController]s merged into a single [AnimatedBuilder]).
class FreezeOverlay extends StatelessWidget {
  final double progress;
  final double shimmerPhase;
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const FreezeOverlay({
    super.key,
    required this.progress,
    this.shimmerPhase = 0,
    required this.child,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    // The Padding sits *inside* the Stack so its size sets the Stack's
    // bounds — the border and texture then paint at the padded edges, not
    // at the digits' edges. (Wrapping the Stack with Padding instead would
    // only add external margin and leave the border hugging the glyphs.)
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: padding, child: child),
        if (p > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FrostTexturePainter(
                  progress: p,
                  radius: borderRadius,
                ),
              ),
            ),
          ),
        if (p > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FrostBorderPainter(
                  progress: p,
                  radius: borderRadius,
                  shimmerPhase: shimmerPhase,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cobalt tint + speckle dots + diagonal streaks. Layered behind the border.
class _FrostTexturePainter extends CustomPainter {
  final double progress;
  final double radius;

  _FrostTexturePainter({required this.progress, required this.radius});

  // Deterministic so the speckle pattern is stable across rebuilds.
  static final _rng = math.Random(12);
  static final List<_Speckle> _speckles = List.generate(
    36,
    (_) => _Speckle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      maxR: 0.5 + _rng.nextDouble() * 1.6,
      phase: _rng.nextDouble(),
    ),
  );
  static final List<_Streak> _streaks = List.generate(
    4,
    (_) => _Streak(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      angle: -math.pi / 4 + (_rng.nextDouble() - 0.5) * 0.4,
      maxLen: 14 + _rng.nextDouble() * 22,
      phase: _rng.nextDouble() * 0.3,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    // Cool tint wash — pale frost, much softer than cobalt.
    final tintAlpha = (0.08 * progress).clamp(0.0, 1.0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _iceMid.withValues(alpha: tintAlpha),
    );

    // Frost-white speckles — appear with slight per-speckle phase so they
    // "frost in" unevenly rather than all at once.
    final specklePaint = Paint();
    for (final s in _speckles) {
      final t = ((progress - s.phase * 0.4) / (1 - s.phase * 0.4))
          .clamp(0.0, 1.0);
      if (t <= 0) continue;
      final r = s.maxR * t;
      final alpha = (0.55 * t).clamp(0.0, 1.0);
      specklePaint.color = _iceWhite.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        r,
        specklePaint,
      );
    }

    // Diagonal frost streaks — short pale-ice lines that grow with progress.
    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final s in _streaks) {
      final t = ((progress - s.phase) / (1 - s.phase)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final len = s.maxLen * t;
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      final dx = math.cos(s.angle) * len / 2;
      final dy = math.sin(s.angle) * len / 2;
      streakPaint.color = _iceLight.withValues(alpha: 0.6 * t);
      canvas.drawLine(Offset(cx - dx, cy - dy), Offset(cx + dx, cy + dy),
          streakPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FrostTexturePainter old) =>
      old.progress != progress || old.radius != radius;
}

class _Speckle {
  final double x;
  final double y;
  final double maxR;
  final double phase;
  _Speckle({
    required this.x,
    required this.y,
    required this.maxR,
    required this.phase,
  });
}

class _Streak {
  final double x;
  final double y;
  final double angle;
  final double maxLen;
  final double phase;
  _Streak({
    required this.x,
    required this.y,
    required this.angle,
    required this.maxLen,
    required this.phase,
  });
}

/// Pale-frost rounded-rect stroke that draws itself clockwise as progress
/// goes 0 → 1. Painted with a sweep gradient whose start angle is shifted by
/// [shimmerPhase] (looping 0 → 1) so a bright "highlight" rotates around the
/// box like light catching the edge of an ice cube.
class _FrostBorderPainter extends CustomPainter {
  final double progress;
  final double radius;
  final double shimmerPhase;

  _FrostBorderPainter({
    required this.progress,
    required this.radius,
    required this.shimmerPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 1.5;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final shimmerAngle = shimmerPhase * 2 * math.pi;
    final center = Offset(size.width / 2, size.height / 2);

    // Sweep gradient: cycles light → highlight → mid → highlight → light, so
    // there are two bright spots ~180° apart. Shifting startAngle by
    // shimmerAngle rotates the whole sweep around the center over time.
    final shader = ui.Gradient.sweep(
      center,
      const [_iceLight, _iceWhite, _iceMid, _iceWhite, _iceLight],
      const [0.0, 0.25, 0.5, 0.75, 1.0],
      TileMode.clamp,
      shimmerAngle,
      shimmerAngle + 2 * math.pi,
    );

    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + 2.0 * progress
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    // Soft frost-white ghost behind the stroke — keeps the riso
    // misregistration vibe without competing with the gradient.
    final ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = _iceWhite.withValues(alpha: 0.3 * progress);

    for (final metric in path.computeMetrics()) {
      final drawn = metric.extractPath(0, metric.length * progress);
      canvas.save();
      canvas.translate(2, -1);
      canvas.drawPath(drawn, ghostPaint);
      canvas.restore();
      canvas.drawPath(drawn, mainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrostBorderPainter old) =>
      old.progress != progress ||
      old.radius != radius ||
      old.shimmerPhase != shimmerPhase;
}
