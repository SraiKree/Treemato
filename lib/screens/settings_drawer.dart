import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
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
                    title: 'Pomodoro Slot',
                    subtitle: 'default focus duration',
                  ),
                  SizedBox(height: 14),
                  _DurationRow(
                    kind: _DurIcon.coffee,
                    color: TM.mint,
                    title: 'Short Break',
                    subtitle: 'tiny breather',
                  ),
                  SizedBox(height: 14),
                  _DurationRow(
                    kind: _DurIcon.couch,
                    color: TM.cobalt,
                    title: 'Long Break',
                    subtitle: 'do not doomscroll (every 3 pomos)',
                  ),
                  SizedBox(height: 14),
                  _CycleMap(),
                  SizedBox(height: 14),
                  _SquiggleDivider(),
                  SizedBox(height: 14),
                  _DailyGoal(),
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
  const _DurationRow({
    required this.kind,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  /// Read the current value for this row from the provider.
  int _read(TimerProvider t) {
    switch (kind) {
      case _DurIcon.tomato:
        return t.pomodoroMinutes;
      case _DurIcon.coffee:
        return t.shortBreakMinutes;
      case _DurIcon.couch:
        return t.longBreakMinutes;
    }
  }

  /// Apply a delta (+1 / -1) to the right setter on the provider.
  void _write(TimerProvider t, int delta) {
    switch (kind) {
      case _DurIcon.tomato:
        t.setPomodoroMinutes(t.pomodoroMinutes + delta);
      case _DurIcon.coffee:
        t.setShortBreakMinutes(t.shortBreakMinutes + delta);
      case _DurIcon.couch:
        t.setLongBreakMinutes(t.longBreakMinutes + delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final value = _read(timer).toString();

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
                        text: 'm',
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
              _StepButton(
                label: '−',
                shadowColor: TM.ink,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _write(timer, -1);
                },
              ),
              const SizedBox(width: 8),
              _StepButton(
                label: '+',
                shadowColor: TM.lemon,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _write(timer, 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chunky `−` / `+` stepper that fires [onTap] once on press and then
/// auto-repeats while held. Tuned to feel like a physical knob: a short
/// initial pause (so a quick tap reads as a single step), then ticks
/// every 100 ms, accelerating to 55 ms after ~1 s of continuous hold.
class _StepButton extends StatefulWidget {
  final String label;
  final Color shadowColor;
  final VoidCallback onTap;
  const _StepButton({
    required this.label,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  /// Delay between the initial tap and the start of auto-repeat. Long
  /// enough that a quick tap is unambiguously a single step.
  static const _holdDelay = Duration(milliseconds: 400);

  /// Tick interval while held. Drops to [_fastInterval] after a second
  /// of holding so the user can sweep across the range quickly.
  static const _slowInterval = Duration(milliseconds: 100);
  static const _fastInterval = Duration(milliseconds: 55);
  static const _accelerateAfter = Duration(milliseconds: 1000);

  Timer? _holdDelayTimer;
  Timer? _repeatTimer;
  Timer? _accelerateTimer;
  bool _pressed = false;
  bool _accelerated = false;

  void _start() {
    setState(() => _pressed = true);
    widget.onTap();
    _holdDelayTimer = Timer(_holdDelay, _beginRepeat);
  }

  void _beginRepeat() {
    _accelerated = false;
    _repeatTimer = Timer.periodic(_slowInterval, (_) => widget.onTap());
    // After ~1 s of holding, swap to the fast tick. Single one-shot
    // reschedule so we don't churn the timer every tick.
    _accelerateTimer = Timer(_accelerateAfter, () {
      if (!_pressed || _accelerated) return;
      _accelerated = true;
      _repeatTimer?.cancel();
      _repeatTimer = Timer.periodic(_fastInterval, (_) => widget.onTap());
    });
  }

  void _stop() {
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
    _accelerateTimer?.cancel();
    _accelerateTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _accelerated = false;
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _holdDelayTimer?.cancel();
    _accelerateTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TM.tomato,
          border: Border.all(color: TM.ink, width: 2),
          // Shadow snaps in toward the body while pressed — same idiom
          // the main control button uses, so the stepper feels part of
          // the same family.
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: _pressed ? const Offset(1, 1) : const Offset(2, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TMText.display(fontSize: 20, color: TM.cream, height: 1.0),
        ),
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

class _CycleMap extends StatefulWidget {
  const _CycleMap();

  @override
  State<_CycleMap> createState() => _CycleMapState();
}

class _CycleMapState extends State<_CycleMap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final reduced = MediaQuery.of(context).disableAnimations;
    final currentIdx = timer.phaseIndex;
    // When the timer is idle (fresh start OR waiting between phases) we
    // don't highlight an active segment — the user hasn't engaged yet.
    final showActive = timer.status != TimerStatus.idle;

    // Build the pill row directly from the provider's dynamic sequence
    // so any reshape (pomodorosPerCycle / shortBreaksOn) shows up here
    // immediately.
    final segments = <_CycleSeg>[];
    var pomoNum = 0;
    for (var i = 0; i < timer.sequenceLength; i++) {
      final phase = timer.phaseAt(i);
      final done = i < currentIdx;
      final active = showActive && i == currentIdx;
      switch (phase) {
        case TimerPhase.focus:
          pomoNum++;
          segments.add(_CycleSeg('P$pomoNum', TM.tomato,
              done: done, active: active));
          break;
        case TimerPhase.shortBreak:
          segments.add(_CycleSeg('b', TM.mint,
              done: done, active: active, thin: true));
          break;
        case TimerPhase.longBreak:
          segments.add(_CycleSeg('B', TM.cobalt,
              done: done, active: active, big: true));
          break;
      }
    }

    final motion = reduced
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'CYCLE MAP',
                    style: TMText.display(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: TM.tomato,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expanded ? 'tap to close' : 'tap to edit',
                    style: TMText.marker(
                      fontSize: 12,
                      color: TM.cream.withValues(alpha: 0.55),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: motion,
                    curve: Curves.easeOutCubic,
                    child: Text(
                      '›',
                      style: TMText.display(
                        fontSize: 16,
                        color: TM.cream.withValues(alpha: 0.55),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
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
          ),
        ),
        AnimatedSize(
          duration: motion,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? const _CycleMapEditor()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Two-knob editor that appears under the cycle map when expanded:
/// a stepper for "Pomodoros per cycle" (2..6) and a toggle for
/// "Short breaks" (on/off). Reuses the same _StepButton / _ToggleCard
/// idiom as the duration rows above, so it reads as part of the same
/// family of controls.
class _CycleMapEditor extends StatelessWidget {
  const _CycleMapEditor();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    // Strict mode promises "no escape" — reshaping the cycle while a
    // strict session is mid-flight would let the user dodge the long
    // break. Mirror the PAUSE-locks-as-LOCKED idiom: dim + ignore taps.
    final locked = timer.strictModeOn && timer.isRunning;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: IgnorePointer(
        ignoring: locked,
        child: Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                        'Pomodoros per cycle',
                        style: TMText.display(
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2..6 focus blocks before long break',
                        style: TMText.ui(
                          fontSize: 11,
                          color: TM.cream.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${timer.pomodorosPerCycle}',
                  style: TMText.display(fontSize: 32, height: 1.0),
                ),
                const SizedBox(width: 10),
                _StepButton(
                  label: '−',
                  shadowColor: TM.ink,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    timer
                        .setPomodorosPerCycle(timer.pomodorosPerCycle - 1);
                  },
                ),
                const SizedBox(width: 8),
                _StepButton(
                  label: '+',
                  shadowColor: TM.lemon,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    timer
                        .setPomodorosPerCycle(timer.pomodorosPerCycle + 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ToggleCard(
            title: 'Short breaks',
            subtitle: 'tiny breathers between focus blocks',
            on: timer.shortBreaksOn,
            shadowColor: TM.mint,
            onTap: () {
              HapticFeedback.selectionClick();
              timer.setShortBreaksOn(!timer.shortBreaksOn);
            },
          ),
            ],
          ),
        ),
      ),
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

// Daily goal

class _DailyGoal extends StatelessWidget {
  const _DailyGoal();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY GOAL',
          style: TMText.display(fontSize: 16, letterSpacing: 1),
        ),
        const MarkerUnderline(width: 90, color: TM.lemon),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                      'Pomodoros per day',
                      style: TMText.display(
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'target shown on the stats screen',
                      style: TMText.ui(
                        fontSize: 11,
                        color: TM.cream.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${timer.dailyTargetPomodoros}',
                style: TMText.display(fontSize: 32, height: 1.0),
              ),
              const SizedBox(width: 10),
              _StepButton(
                label: '−',
                shadowColor: TM.ink,
                onTap: () {
                  HapticFeedback.selectionClick();
                  timer.setDailyTargetPomodoros(
                      timer.dailyTargetPomodoros - 1);
                },
              ),
              const SizedBox(width: 8),
              _StepButton(
                label: '+',
                shadowColor: TM.lemon,
                onTap: () {
                  HapticFeedback.selectionClick();
                  timer.setDailyTargetPomodoros(
                      timer.dailyTargetPomodoros + 1);
                },
              ),
            ],
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
    final timer = context.watch<TimerProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKFLOW MODE',
          style: TMText.display(fontSize: 16, letterSpacing: 1),
        ),
        const MarkerUnderline(width: 100, color: TM.cobalt),
        const SizedBox(height: 10),
        _ToggleCard(
          title: 'Strict Mode',
          subtitle: 'disable pausing',
          on: timer.strictModeOn,
          shadowColor: TM.lemon,
          onTap: () {
            HapticFeedback.selectionClick();
            timer.toggleStrictMode();
          },
        ),
      ],
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    return _ToggleCard(
      title: 'Squelches & Epic music',
      subtitle: 'all the sounds or total silence',
      on: timer.chimeSoundsOn,
      shadowColor: null,
      onTap: () {
        HapticFeedback.selectionClick();
        timer.toggleChimeSounds();
      },
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool on;
  final Color? shadowColor;
  final VoidCallback onTap;
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.on,
    required this.shadowColor,
    required this.onTap,
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: _PillToggle(on: on, shadowColor: shadowColor),
          ),
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
          'Treemato',
          style: TMText.brand(
            fontSize: 18,
            color: TM.tomato,
          ),
        ),
        Text(
          'v0.4.0 · made with ♥ by TreeGPT',
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
