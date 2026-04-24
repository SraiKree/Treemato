import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/motifs.dart';

/// Timer Settings drawer.
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF050505),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      width: MediaQuery.of(context).size.width * 0.82,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 120,
            child: Text(
              '25',
              style: TMText.display(
                fontSize: 200,
                color: TM.dim.withValues(alpha: 0.35),
                height: 0.8,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _Header(),
                  SizedBox(height: 14),
                  _DurationRow(
                    kind: _DurIcon.tomato,
                    color: TM.tomato,
                    title: 'Pomodoro Focus',
                    subtitle: 'default focus duration',
                    value: '25',
                    unit: 'm',
                  ),
                  SizedBox(height: 14),
                  _DurationRow(
                    kind: _DurIcon.coffee,
                    color: TM.mint,
                    title: 'Short Break',
                    subtitle: 'tiny breather',
                    value: '5',
                    unit: 'm',
                  ),
                  SizedBox(height: 14),
                  _DurationRow(
                    kind: _DurIcon.couch,
                    color: TM.cobalt,
                    title: 'Long Break',
                    subtitle: 'proper nap (every 3 pomos)',
                    value: '15',
                    unit: 'm',
                  ),
                  SizedBox(height: 14),
                  _CycleMap(),
                  SizedBox(height: 14),
                  _SquiggleDivider(),
                  SizedBox(height: 14),
                  _WorkflowMode(),
                  SizedBox(height: 14),
                  _SoundToggle(),
                  SizedBox(height: 28),
                  _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Header

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIMER',
                style: TMText.display(
                  fontSize: 24,
                  letterSpacing: 1,
                  height: 1.0,
                ),
              ),
              Text(
                'SETTINGS',
                style: TMText.display(
                  fontSize: 24,
                  letterSpacing: 1,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const MarkerUnderline(width: 140),
            ],
          ),
        ),
        _CloseChip(onTap: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _CloseChip extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.rotate(
        angle: -3 * math.pi / 180,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: TM.cream,
            border: Border.all(color: TM.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: TM.tomato, offset: Offset(2, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '✕',
            style: TMText.display(fontSize: 18, color: TM.ink, height: 1.0),
          ),
        ),
      ),
    );
  }
}

// Duration row

enum _DurIcon { tomato, coffee, couch }

class _DurationRow extends StatelessWidget {
  final _DurIcon kind;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  const _DurationRow({
    required this.kind,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: TM.ink2,
        border: Border.all(color: TM.dim2, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CustomPaint(
                  painter: _DurationIconPainter(kind: kind, color: color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TMText.display(fontSize: 15, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TMText.ui(
                        fontSize: 11,
                        color: TM.cream.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TMText.display(
                      fontSize: 44,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                    children: [
                      TextSpan(text: value),
                      TextSpan(
                        text: unit,
                        style: TMText.display(
                          fontSize: 22,
                          color: TM.cream.withValues(alpha: 0.7),
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _StepButton(label: '−', shadowColor: TM.ink),
              const SizedBox(width: 8),
              const _StepButton(label: '+', shadowColor: TM.lemon),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final Color shadowColor;
  const _StepButton({required this.label, required this.shadowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: TM.tomato,
        border: Border.all(color: TM.ink, width: 2),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(2, 2))],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TMText.display(fontSize: 20, color: TM.cream, height: 1.0),
      ),
    );
  }
}

class _DurationIconPainter extends CustomPainter {
  final _DurIcon kind;
  final Color color;
  const _DurationIconPainter({required this.kind, required this.color});

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 28.0;
    switch (kind) {
      case _DurIcon.tomato:
        _tomato(c, k);
        break;
      case _DurIcon.coffee:
        _coffee(c, k);
        break;
      case _DurIcon.couch:
        _couch(c, k);
        break;
    }
  }

  void _tomato(Canvas c, double k) {
    final stem = Paint()
      ..color = TM.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round;
    final stemPath = Path()
      ..moveTo(10 * k, 5 * k)
      ..quadraticBezierTo(14 * k, 2 * k, 18 * k, 5 * k);
    c.drawPath(stemPath, stem);
    final body = Rect.fromCenter(
      center: Offset(14 * k, 16 * k),
      width: 18 * k,
      height: 16 * k,
    );
    c.drawOval(body, Paint()..color = color);
    c.drawOval(
      body,
      Paint()
        ..color = TM.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k,
    );
  }

  void _coffee(Canvas c, double k) {
    final fill = Paint()..color = color;
    final ink = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cup = Path()
      ..moveTo(6 * k, 10 * k)
      ..lineTo(20 * k, 10 * k)
      ..lineTo(18.5 * k, 22 * k)
      ..lineTo(7.5 * k, 22 * k)
      ..close();
    c.drawPath(cup, fill);
    c.drawPath(cup, ink);
    final handle = Path()
      ..moveTo(20 * k, 13 * k)
      ..quadraticBezierTo(25 * k, 13 * k, 25 * k, 17 * k)
      ..quadraticBezierTo(25 * k, 20 * k, 20 * k, 20 * k);
    c.drawPath(handle, ink);
    final steam = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * k
      ..strokeCap = StrokeCap.round;
    final s1 = Path()
      ..moveTo(10 * k, 3 * k)
      ..quadraticBezierTo(10 * k, 6 * k, 11 * k, 6 * k);
    final s2 = Path()
      ..moveTo(14 * k, 2 * k)
      ..quadraticBezierTo(14 * k, 5 * k, 15 * k, 5 * k);
    c.drawPath(s1, steam);
    c.drawPath(s2, steam);
  }

  void _couch(Canvas c, double k) {
    final fill = Paint()..color = color;
    final ink = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final body = Path()
      ..moveTo(3 * k, 14 * k)
      ..quadraticBezierTo(3 * k, 11 * k, 6 * k, 11 * k)
      ..lineTo(22 * k, 11 * k)
      ..quadraticBezierTo(25 * k, 11 * k, 25 * k, 14 * k)
      ..lineTo(25 * k, 20 * k)
      ..lineTo(3 * k, 20 * k)
      ..close();
    c.drawPath(body, fill);
    c.drawPath(body, ink);
    final cushion = Paint()..color = TM.cream.withValues(alpha: 0.35);
    c.drawRect(Rect.fromLTWH(5 * k, 13 * k, 7 * k, 5 * k), cushion);
    c.drawRect(Rect.fromLTWH(16 * k, 13 * k, 7 * k, 5 * k), cushion);
    c.drawLine(Offset(5 * k, 20 * k), Offset(5 * k, 23 * k), ink);
    c.drawLine(Offset(23 * k, 20 * k), Offset(23 * k, 23 * k), ink);
  }

  @override
  bool shouldRepaint(covariant _DurationIconPainter old) =>
      old.kind != kind || old.color != color;
}

// Cycle map

class _CycleMap extends StatelessWidget {
  const _CycleMap();

  @override
  Widget build(BuildContext context) {
    const segments = <_CycleSeg>[
      _CycleSeg('P1', TM.tomato, done: true),
      _CycleSeg('b', TM.mint, done: true, thin: true),
      _CycleSeg('P2', TM.tomato, active: true),
      _CycleSeg('b', TM.mint, thin: true),
      _CycleSeg('P3', TM.tomato),
      _CycleSeg('B', TM.cobalt, big: true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT_CYCLE_MAP',
          style: TMText.display(
            fontSize: 10,
            letterSpacing: 2,
            color: TM.tomato,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TM.ink2,
            border: Border.all(color: TM.dim2, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < segments.length; i++) ...[
                Expanded(
                  flex: segments[i].big
                      ? 14
                      : segments[i].thin
                          ? 7
                          : 10,
                  child: _CyclePill(segment: segments[i]),
                ),
                if (i < segments.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '›',
                      style: TMText.ui(
                        fontSize: 10,
                        color: TM.dim2,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CycleSeg {
  final String label;
  final Color color;
  final bool done;
  final bool active;
  final bool thin;
  final bool big;
  const _CycleSeg(
    this.label,
    this.color, {
    this.done = false,
    this.active = false,
    this.thin = false,
    this.big = false,
  });
}

class _CyclePill extends StatelessWidget {
  final _CycleSeg segment;
  const _CyclePill({required this.segment});

  @override
  Widget build(BuildContext context) {
    final filled = segment.done || segment.active;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: segment.big ? 28 : 22,
          decoration: BoxDecoration(
            color: filled ? segment.color : TM.dim,
            border: Border.all(color: TM.ink, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            segment.label,
            style: TMText.display(
              fontSize: 11,
              color: TM.cream,
              height: 1.0,
            ),
          ),
        ),
        if (segment.active)
          const Positioned(
            top: -6,
            right: -4,
            child: Spark(size: 10, color: TM.lemon),
          ),
      ],
    );
  }
}

// Squiggle divider

class _SquiggleDivider extends StatelessWidget {
  const _SquiggleDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: TM.dim2),
            child: SizedBox(height: 1),
          ),
        ),
        const SizedBox(width: 8),
        const Squiggle(width: 60, height: 10, strokeWidth: 2),
        const SizedBox(width: 8),
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: TM.dim2),
            child: SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}

// Workflow mode

class _WorkflowMode extends StatelessWidget {
  const _WorkflowMode();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKFLOW MODE',
          style: TMText.display(fontSize: 16, letterSpacing: 1),
        ),
        const MarkerUnderline(width: 100, color: TM.cobalt),
        const SizedBox(height: 10),
        const _ToggleCard(
          title: 'Strict Mode',
          subtitle: 'disable pausing · pure pomodoro rules',
          on: true,
          shadowColor: TM.lemon,
        ),
      ],
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle();

  @override
  Widget build(BuildContext context) {
    return const _ToggleCard(
      title: 'Chime sounds',
      subtitle: 'a little "bip!" on completion',
      on: false,
      shadowColor: null,
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool on;
  final Color? shadowColor;
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.on,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TM.ink2,
        border: Border.all(color: TM.dim2, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TMText.marker(fontSize: 22, height: 1.0),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TMText.ui(
                    fontSize: 11,
                    color: TM.cream.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PillToggle(on: on, shadowColor: shadowColor),
        ],
      ),
    );
  }
}

class _PillToggle extends StatelessWidget {
  final bool on;
  final Color? shadowColor;
  const _PillToggle({required this.on, required this.shadowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 28,
      decoration: BoxDecoration(
        color: on ? TM.tomato : TM.dim,
        border: Border.all(color: TM.ink, width: 2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: (shadowColor != null && on)
            ? [BoxShadow(color: shadowColor!, offset: const Offset(2, 2))]
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 1,
            left: on ? null : 1,
            right: on ? 1 : null,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? TM.cream : TM.cream2,
                border: Border.all(color: TM.ink, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Footer

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TREEMATO',
          style: TMText.display(
            fontSize: 12,
            letterSpacing: 2,
            color: TM.tomato,
          ),
        ),
        Text(
          'v0.4.0 · made with ♥ and caffeine',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            letterSpacing: 2,
            color: TM.cream.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
