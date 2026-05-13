import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Which flavour of burst the control button should render on a state change.
///
/// `burst` fires on `START` / `RESUME` — bright, generous: shockwave ring,
/// confetti streamers, sparks, full bolt punch.
///
/// `deflate` fires on `PAUSE` — softer: cream2 ripple only, bolt slumps.
enum BurstVariant { burst, deflate }

/// Expanding rounded-rect stroke around the button perimeter.
///
/// `progress` 0 → 1. Strokes outward up to [maxInflate], stroke-width 3 → 0,
/// opacity 1 → 0. Painter canvas should be the button's exact rect — the
/// stroke extends outside it, so the host Stack must use `Clip.none`.
class ShockwaveRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxInflate;

  const ShockwaveRingPainter({
    required this.progress,
    required this.color,
    this.maxInflate = 40,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeOutQuart.transform(progress);
    final inflate = maxInflate * eased;
    final strokeW = 3 * (1 - progress);
    if (strokeW <= 0.01) return;
    final rect = (Offset.zero & size).inflate(inflate);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ShockwaveRingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Soft filled ripple used by the PAUSE / deflate variant.
///
/// Inflates 0 → 20 px, opacity 0.25 → 0. Canvas = button rect.
class DeflateRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  const DeflateRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeOutQuart.transform(progress);
    final inflate = 20 * eased;
    final alpha = 0.25 * (1 - progress);
    if (alpha <= 0.005) return;
    final rect = (Offset.zero & size).inflate(inflate);
    final paint = Paint()..color = color.withValues(alpha: alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DeflateRipplePainter old) =>
      old.progress != progress || old.color != color;
}

/// Six cream/lemon streamers radiating from the button centre.
///
/// Mirrors the BIP `done` celebration but slightly faster and with deliberately
/// uneven angles. Each streamer has a tiny phase offset so they fire in a
/// staggered burst rather than a perfect ring.
class ConfettiStreamerPainter extends CustomPainter {
  final double progress;

  const ConfettiStreamerPainter({required this.progress});

  static const _angles = <double>[-78, -42, -12, 18, 52, 96];
  static const _lengths = <double>[36, 42, 32, 38, 40, 34];
  static const _phases = <double>[0.0, 0.06, 0.10, 0.04, 0.08, 0.02];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < _angles.length; i++) {
      final phase = _phases[i];
      final localT = ((progress - phase) / (1 - phase)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      // ease-out-cubic on travel so the streamer flies fast then slows.
      final ease = 1 - math.pow(1 - localT, 3).toDouble();
      final angleRad = _angles[i] * math.pi / 180;
      final travel = 36 + ease * 64;
      final length = _lengths[i] * (1 - localT * 0.4);

      final tip = center +
          Offset(math.cos(angleRad) * travel, math.sin(angleRad) * travel);
      final tail = tip -
          Offset(math.cos(angleRad) * length, math.sin(angleRad) * length);

      final base = i.isEven ? TM.cream : TM.lemon;
      final paint = Paint()
        ..color = base.withValues(alpha: (1 - localT).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(tail, tip, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiStreamerPainter old) =>
      old.progress != progress;
}

/// Five small lemon/cream dots flying diagonal-upward-right from the bolt
/// anchor (top-right of the button).
///
/// Deterministic across frames via a fixed seed — every paint() call replays
/// the same trajectories.
class SparkBurstPainter extends CustomPainter {
  final double progress;

  const SparkBurstPainter({required this.progress});

  static const _count = 5;
  // anchor is computed per-paint relative to size so the burst always tracks
  // the bolt's nominal position (top-right of the button).

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rng = math.Random(11);
    final anchor = Offset(size.width - 26, 4);

    for (int i = 0; i < _count; i++) {
      // Pull all rng values for this spark FIRST so iteration order stays
      // deterministic across paint() calls.
      final phase = rng.nextDouble() * 0.15;
      // angles in [-70°, -10°] — diagonal-upward-right cone
      final angleDeg = -70 + rng.nextDouble() * 60;
      final dist = 22 + rng.nextDouble() * 22;
      final radius = 3 + rng.nextDouble() * 2;
      final colorPick = rng.nextBool();

      final localT = ((progress - phase) / (1 - phase)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final ease = 1 - math.pow(1 - localT, 3).toDouble();
      final angleRad = angleDeg * math.pi / 180;
      final pos = anchor +
          Offset(math.cos(angleRad) * dist * ease,
              math.sin(angleRad) * dist * ease);

      final base = colorPick ? TM.lemon : TM.cream;
      final paint = Paint()
        ..color = base.withValues(alpha: (1 - localT).clamp(0.0, 1.0));
      canvas.drawCircle(pos, radius * (1 - localT * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparkBurstPainter old) =>
      old.progress != progress;
}
