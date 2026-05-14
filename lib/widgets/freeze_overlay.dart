import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

/// 2.5D candy-bar border: alternating cobalt and ice-white stripes scroll
/// around the rounded-rect path like a barber pole (driven by [shimmerPhase]).
/// A wider dark stroke underneath fakes a drop shadow, a thin bright stroke
/// on top fakes a specular highlight running down the centre of the bar, and
/// a soft blurred hotspot travels along the path for the glossy "shine"
/// catching light. Progress 0 → 1 reveals the bar clockwise from the start.
class _FrostBorderPainter extends CustomPainter {
  final double progress;
  final double radius;
  final double shimmerPhase;

  _FrostBorderPainter({
    required this.progress,
    required this.radius,
    required this.shimmerPhase,
  });

  // Width of one stripe in pixels along the path. Total cycle = 2 * stripe.
  static const double _stripeLen = 12.0;
  // Length of the travelling shine hotspot.
  static const double _shineLen = 26.0;

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

    // Bar thickens as the freeze locks in.
    final barWidth = 3.0 + 3.0 * progress;

    // Layer 1 — riso ghost (offset frost-white) behind everything.
    final ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = _iceWhite.withValues(alpha: 0.3 * progress);

    // Layer 2 — dark "underside" shadow: a slightly wider, near-black stroke
    // sitting beneath the candy. Sells depth — the bar feels lifted off the
    // frost. Inky cobalt so it ties into the freeze palette.
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth + 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0A1A3A).withValues(alpha: 0.55 * progress);

    // Layer 3 — alternating candy stripes (cobalt / ice-white), drawn as
    // discrete path segments. Butt caps so adjacent stripes meet cleanly.
    final cobaltPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.butt
      ..color = TM.cobalt;
    final whitePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.butt
      ..color = _iceWhite;

    // Layer 4 — thin specular highlight down the middle of the bar. Same
    // path, ~30 % of bar width, soft white. Reads as a glossy ridge running
    // the length of a cylindrical candy.
    final specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, barWidth * 0.30)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.55 * progress);

    // Layer 5 — travelling shine hotspot: a short, blurred bright segment
    // that scoots around the path with shimmerPhase. This is the "shine"
    // the sweep gradient used to provide.
    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth * 0.9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    for (final metric in path.computeMetrics()) {
      final pathLen = metric.length;
      final drawnLen = pathLen * progress;
      if (drawnLen <= 0) continue;

      // Ghost (offset).
      final drawn = metric.extractPath(0, drawnLen);
      canvas.save();
      canvas.translate(2, -1);
      canvas.drawPath(drawn, ghostPaint);
      canvas.restore();

      // Shadow under the bar.
      canvas.drawPath(drawn, shadowPaint);

      // Candy stripes — phase-shifted by shimmerPhase so the bands appear
      // to scroll around the bar like a barber pole.
      const cycle = _stripeLen * 2;
      final shift = (shimmerPhase * cycle) % cycle;
      double pos = -shift;
      bool isCobalt = false;
      while (pos < drawnLen) {
        final segStart = math.max(pos, 0.0);
        final segEnd = math.min(pos + _stripeLen, drawnLen);
        if (segEnd > segStart) {
          canvas.drawPath(
            metric.extractPath(segStart, segEnd),
            isCobalt ? cobaltPaint : whitePaint,
          );
        }
        pos += _stripeLen;
        isCobalt = !isCobalt;
      }

      // Specular ridge along the drawn bar.
      canvas.drawPath(drawn, specularPaint);

      // Travelling shine hotspot. While progress < 1 the path is open, so
      // we just clip to the drawn region. At full progress we wrap the
      // segment around the closed path so the shine never "pops" off.
      final shineCenter = (shimmerPhase * pathLen) % pathLen;
      double shineStart = shineCenter - _shineLen / 2;
      double shineEnd = shineCenter + _shineLen / 2;
      if (progress >= 1.0) {
        if (shineStart < 0) {
          canvas.drawPath(
              metric.extractPath(pathLen + shineStart, pathLen), shinePaint);
          shineStart = 0;
        }
        if (shineEnd > pathLen) {
          canvas.drawPath(
              metric.extractPath(0, shineEnd - pathLen), shinePaint);
          shineEnd = pathLen;
        }
        canvas.drawPath(metric.extractPath(shineStart, shineEnd), shinePaint);
      } else {
        final s = math.max(shineStart, 0.0);
        final e = math.min(shineEnd, drawnLen);
        if (e > s) canvas.drawPath(metric.extractPath(s, e), shinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FrostBorderPainter old) =>
      old.progress != progress ||
      old.radius != radius ||
      old.shimmerPhase != shimmerPhase;
}
