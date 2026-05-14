import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Wraps a child so it tumbles into place from a chaotic starting pose —
/// like a piece of clothing pulled out of an overstuffed suitcase.
///
/// Driven by an external [animation] (typically `ModalRoute.of(context)!
/// .animation!`) so multiple items can share one timeline and be staggered
/// with [delayFraction] / [spanFraction]. The wrapper contributes only the
/// *delta* on top of the wrapped child — the child keeps its own design
/// rotation (e.g. the sticker buttons' -2° / +2° resting pose), and that
/// pose is what the item settles onto once the animation reaches 1.0.
///
/// Respects `MediaQuery.disableAnimations`: the wrapper returns the child
/// verbatim — no transforms, no opacity layer — so a reduced-motion user
/// sees the final pose with zero motion.
class SuitcaseItem extends StatelessWidget {
  final Animation<double> animation;
  final double delayFraction;
  final double spanFraction;
  final Offset fromOffset;
  final double fromRotationDeg;
  final double fromScale;
  final Widget child;

  const SuitcaseItem({
    super.key,
    required this.animation,
    required this.child,
    this.delayFraction = 0.0,
    this.spanFraction = 1.0,
    this.fromOffset = Offset.zero,
    this.fromRotationDeg = 0.0,
    this.fromScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        final raw = animation.value;
        final span = spanFraction <= 0 ? 1.0 : spanFraction;
        final t = ((raw - delayFraction) / span).clamp(0.0, 1.0);

        // Translation + scale: easeOutBack gives the suitcase-tumble overshoot.
        final eased = Curves.easeOutBack.transform(t);
        final dx = fromOffset.dx * (1 - eased);
        final dy = fromOffset.dy * (1 - eased);
        final scale = fromScale + (1.0 - fromScale) * eased;

        // Rotation: lerp toward 0 with an overshoot of +8° at t≈0.55, then a
        // single damped wobble back to 0 across t=0.55..1.0. The +8° sign
        // matches the chaotic starting direction so the overshoot reads as
        // "the cloth flopped a bit past where it was going to land."
        double rotDeg;
        if (t < 0.55) {
          final p = t / 0.55;
          final ease = Curves.easeOutQuart.transform(p);
          rotDeg = fromRotationDeg * (1 - ease) +
              (fromRotationDeg.sign * 8) * ease;
        } else {
          final p = (t - 0.55) / 0.45;
          final decay = (1 - p);
          rotDeg = (fromRotationDeg.sign * 8) *
              math.sin(p * math.pi) *
              decay;
        }

        // Opacity: each item fades in sharply within its own stagger window
        // so it doesn't ghost the layout before its turn.
        final opacity = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: rotDeg * math.pi / 180,
              child: Transform.scale(
                scale: scale,
                child: c,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
