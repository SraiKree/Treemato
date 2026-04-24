import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The three reactive moods of BIP, our tomato sidekick.
enum BipState { idle, focus, done }

/// Chunky flat-illustration tomato mascot with three animated states.
class BipMascot extends StatefulWidget {
  final BipState state;
  final double size;
  const BipMascot({
    super.key,
    this.state = BipState.idle,
    this.size = 180,
  });

  @override
  State<BipMascot> createState() => _BipMascotState();
}

class _BipMascotState extends State<BipMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  Duration _durFor(BipState s) {
    switch (s) {
      case BipState.idle:
        return const Duration(milliseconds: 4000);
      case BipState.focus:
        return const Duration(milliseconds: 3200);
      case BipState.done:
        return const Duration(milliseconds: 900);
    }
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _durFor(widget.state))
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant BipMascot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _c
        ..stop()
        ..duration = _durFor(widget.state)
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _BipPainter(state: widget.state, progress: _c.value),
        ),
      ),
    );
  }
}

class _BipPainter extends CustomPainter {
  final BipState state;
  final double progress; // 0.0 → 1.0 looping

  _BipPainter({required this.state, required this.progress});

  @override
  void paint(Canvas canvas, Size s) {
    // Map viewBox units to pixels.
    final k = s.width / 200.0;

    _paintHalo(canvas, s);
    if (state == BipState.focus) _paintTensionLines(canvas, s, k);

    canvas.save();
    _applyBodyTransform(canvas, s);
    _paintStem(canvas, k);
    _paintBody(canvas, k);
    _paintFace(canvas, k);
    canvas.restore();

    if (state == BipState.focus) _paintSweat(canvas, k);
    if (state == BipState.done) _paintStreamers(canvas, s, k);
  }

  // Radial effort lines for focus state.
  void _paintTensionLines(Canvas c, Size s, double k) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    const count = 12;
    final tomato = Paint()
      ..color = TM.tomato.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * k
      ..strokeCap = StrokeCap.round;
    final cobalt = Paint()
      ..color = TM.cobalt.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      // Per-tick phase + 2x speed → twitchy tension beat.
      final phase = (i % 3) / 3.0;
      final wave = math.sin(progress * 2 * math.pi * 2 + phase * 2 * math.pi);
      final norm = (wave + 1) / 2; // 0..1
      final innerR = (82 + 2 * norm) * k;
      final outerR = (90 + 12 * norm) * k;
      final p1 = Offset(
        cx + innerR * math.cos(angle),
        cy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        cx + outerR * math.cos(angle),
        cy + outerR * math.sin(angle),
      );
      // Alternate colors every 3rd tick for a two-tone strained aura.
      c.drawLine(p1, p2, i % 3 == 0 ? cobalt : tomato);
    }
  }

  // Riso misregistration halo.
  void _paintHalo(Canvas c, Size s) {
    final haloR = s.width * 0.92 / 2;
    final cx = s.width / 2;
    final cy = s.height / 2;
    final blur = const MaskFilter.blur(BlurStyle.normal, 1);
    c.drawCircle(
      Offset(cx - 5, cy - 3),
      haloR,
      Paint()
        ..color = TM.tomato.withValues(alpha: 0.22)
        ..maskFilter = blur,
    );
    c.drawCircle(
      Offset(cx + 5, cy + 3),
      haloR,
      Paint()
        ..color = TM.cobalt.withValues(alpha: 0.18)
        ..maskFilter = blur,
    );
  }

  // Apply transforms based on current state.
  void _applyBodyTransform(Canvas c, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    double dy = 0, rotDeg = 0, scale = 1;
    final u = (1 - math.cos(2 * math.pi * progress)) / 2; // 0→1→0

    switch (state) {
      case BipState.idle:
        dy = -3.0 * u;
        rotDeg = -1 + 2 * u;
        break;
      case BipState.focus:
        scale = 1 + 0.04 * u;
        break;
      case BipState.done:
        dy = -6.0 * u;
        rotDeg = -4 + 8 * u;
        break;
    }

    c.translate(cx, cy + dy);
    c.rotate(rotDeg * math.pi / 180);
    c.scale(scale);
    c.translate(-cx, -cy);
  }

  // Stem and leaf.
  void _paintStem(Canvas c, double k) {
    final cx = 100 * k;
    final cy = 36 * k;
    final fill = Paint()..color = TM.mint;
    final stroke = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx - 14 * k, cy - 14 * k, cx - 28 * k, cy - 12 * k, cx - 32 * k,
          cy - 2 * k)
      ..cubicTo(cx - 22 * k, cy - 2 * k, cx - 14 * k, cy + 4 * k, cx - 10 * k,
          cy + 12 * k)
      ..close();
    final right = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + 14 * k, cy - 14 * k, cx + 28 * k, cy - 12 * k, cx + 32 * k,
          cy - 2 * k)
      ..cubicTo(cx + 22 * k, cy - 2 * k, cx + 14 * k, cy + 4 * k, cx + 10 * k,
          cy + 12 * k)
      ..close();
    final stalk = Rect.fromLTWH(cx - 3 * k, cy - 2 * k, 6 * k, 10 * k);

    c.drawPath(left, fill);
    c.drawPath(left, stroke);
    c.drawPath(right, fill);
    c.drawPath(right, stroke);
    c.drawRect(stalk, fill);
    c.drawRect(stalk, stroke);
  }

  // Main body.
  void _paintBody(Canvas c, double k) {
    final body = Rect.fromCenter(
      center: Offset(100 * k, 120 * k),
      width: 144 * k,
      height: 128 * k,
    );
    c.drawOval(body, Paint()..color = TM.tomato);
    c.drawOval(
      body,
      Paint()
        ..color = TM.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * k,
    );

    final shine = Rect.fromCenter(
      center: Offset(72 * k, 92 * k),
      width: 36 * k,
      height: 20 * k,
    );
    c.drawOval(shine, Paint()..color = TM.cream.withValues(alpha: 0.28));

    final seedPaint = Paint()
      ..color = TM.ink.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * k
      ..strokeCap = StrokeCap.round;
    final seed1 = Path()
      ..moveTo(58 * k, 150 * k)
      ..quadraticBezierTo(62 * k, 142 * k, 66 * k, 150 * k);
    final seed2 = Path()
      ..moveTo(138 * k, 146 * k)
      ..quadraticBezierTo(142 * k, 138 * k, 146 * k, 146 * k);
    c.drawPath(seed1, seedPaint);
    c.drawPath(seed2, seedPaint);
  }

  // Face features.
  void _paintFace(Canvas c, double k) {
    final inkStroke = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (state) {
      case BipState.idle:
        c.drawCircle(Offset(78 * k, 115 * k), 5 * k, Paint()..color = TM.ink);
        c.drawCircle(Offset(122 * k, 115 * k), 5 * k, Paint()..color = TM.ink);
        final mouth = Path()
          ..moveTo(86 * k, 142 * k)
          ..quadraticBezierTo(100 * k, 150 * k, 114 * k, 142 * k);
        c.drawPath(mouth, inkStroke);
        final cheek = Paint()..color = TM.tomato2.withValues(alpha: 0.6);
        c.drawCircle(Offset(66 * k, 132 * k), 6 * k, cheek);
        c.drawCircle(Offset(134 * k, 132 * k), 6 * k, cheek);
        break;

      case BipState.focus:
        final left = Path()
          ..moveTo(70 * k, 118 * k)
          ..quadraticBezierTo(78 * k, 112 * k, 86 * k, 118 * k);
        final right = Path()
          ..moveTo(114 * k, 118 * k)
          ..quadraticBezierTo(122 * k, 112 * k, 130 * k, 118 * k);
        c.drawPath(left, inkStroke);
        c.drawPath(right, inkStroke);
        final mouth = Path()
          ..moveTo(92 * k, 144 * k)
          ..lineTo(108 * k, 144 * k);
        c.drawPath(mouth, inkStroke);
        break;

      case BipState.done:
        // Open excited eyes: cream whites, ink pupils, pulsing glimmer twinkles.
        final eyeCenters = [
          Offset(78 * k, 115 * k),
          Offset(122 * k, 115 * k),
        ];
        final whiteFill = Paint()..color = TM.cream;
        final whiteStroke = Paint()
          ..color = TM.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * k;
        final pupilFill = Paint()..color = TM.ink;
        final glimmerFill = Paint()..color = TM.cream;
        // Glimmer pulses twice per party wobble — reads as a twinkle.
        final pulse = (math.sin(progress * 2 * math.pi * 2) + 1) / 2;
        final mainR = (1.9 + 0.5 * pulse) * k;

        for (final eye in eyeCenters) {
          c.drawCircle(eye, 8 * k, whiteFill);
          c.drawCircle(eye, 8 * k, whiteStroke);
          c.drawCircle(eye, 5 * k, pupilFill);
          // Main glimmer upper-right of pupil.
          c.drawCircle(
            Offset(eye.dx + 2.0 * k, eye.dy - 2.4 * k),
            mainR,
            glimmerFill,
          );
          // Secondary tiny highlight lower-left, fixed size.
          c.drawCircle(
            Offset(eye.dx - 2.2 * k, eye.dy + 1.8 * k),
            0.9 * k,
            glimmerFill,
          );
        }

        // Toothy grin: shallower cavity, clipped cream teeth, then tongue.
        // Outer outline is stroked last so teeth edges don't fight the lip.
        final smile = Path()
          ..moveTo(82 * k, 138 * k)
          ..quadraticBezierTo(100 * k, 156 * k, 118 * k, 138 * k)
          ..close();
        c.drawPath(smile, Paint()..color = TM.ink2);

        c.save();
        c.clipPath(smile);
        final toothFill = Paint()..color = TM.cream;
        final toothStroke = Paint()
          ..color = TM.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * k;
        for (int i = 0; i < 4; i++) {
          final rect = Rect.fromLTWH(
            (83.75 + i * 8.5) * k,
            138 * k,
            7 * k,
            6 * k,
          );
          c.drawRect(rect, toothFill);
          c.drawRect(rect, toothStroke);
        }
        final tongue = Path()
          ..moveTo(90 * k, 149 * k)
          ..quadraticBezierTo(100 * k, 155 * k, 110 * k, 149 * k)
          ..close();
        c.drawPath(tongue, Paint()..color = TM.tomato);
        c.restore();

        c.drawPath(
          smile,
          Paint()
            ..color = TM.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * k
            ..strokeJoin = StrokeJoin.round,
        );

        final cheek = Paint()..color = TM.tomato2.withValues(alpha: 0.8);
        c.drawCircle(Offset(66 * k, 136 * k), 7 * k, cheek);
        c.drawCircle(Offset(134 * k, 136 * k), 7 * k, cheek);
        break;
    }
  }

  // Focus sweat drip.
  void _paintSweat(Canvas c, double k) {
    // 3.2s body loop ↔ 2.4s sweat loop → scale progress by 3200/2400.
    final phase = (progress * (3200 / 2400)) % 1.0;
    final ty = -4 + 18 * phase; // linear interpolation of y
    final opacity =
        (phase < 0.4 ? phase / 0.4 : 1.0 - (phase - 0.4) / 0.6).clamp(0.0, 1.0);

    final rect = Rect.fromCenter(
      center: Offset(148 * k, (96 + ty) * k),
      width: 8 * k,
      height: 12 * k,
    );
    c.drawOval(rect, Paint()..color = TM.cobalt.withValues(alpha: opacity));
    c.drawOval(
      rect,
      Paint()
        ..color = TM.ink.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k,
    );
  }

  // Celebration streamers for done state.
  void _paintStreamers(Canvas c, Size s, double k) {
    const colors = [
      TM.lemon,
      TM.cobalt,
      TM.mint,
      TM.tomato,
      TM.lemon,
      TM.cobalt,
    ];
    final cx = s.width / 2;
    final cy = s.height / 2;
    final radius = s.width * 0.5;

    for (int i = 0; i < 6; i++) {
      final phase = (progress + i / 6.0) % 1.0;
      final baseAngle = i * 60.0;
      final ty = -22 * phase;
      final rotAdd = 40 * phase;
      final opacity = (0.9 * (1 - phase)).clamp(0.0, 0.9);

      c.save();
      c.translate(cx, cy);
      c.rotate(baseAngle * math.pi / 180);
      c.translate(0, -radius + ty);
      c.rotate(rotAdd * math.pi / 180);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 4 * k,
        height: 16 * k,
      );
      c.drawRect(rect, Paint()..color = colors[i].withValues(alpha: opacity));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BipPainter old) =>
      old.progress != progress || old.state != state;
}
