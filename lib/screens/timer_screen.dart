import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bip_mascot.dart';
import '../widgets/motifs.dart';
import 'task_list_screen.dart';

/// Timer / Home screen.
///
/// Reads all state from [TimerProvider] — no local timer or demo ticker.
class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();

    return Stack(
      fit: StackFit.expand,
      children: [
        const DotGridBackground(),
        const Positioned(
          top: 72,
          right: 28,
          child: Spark(size: 18, color: TM.lemon),
        ),
        const Positioned(
          top: 140,
          left: 22,
          child: Spark(size: 12, color: TM.cobalt),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _TopBar(),
              const SizedBox(height: 12),
              _ActiveModuleLabel(task: timer.phaseLabel),
              const Spacer(),
              _MascotWithOrbit(
                bipState: timer.isCelebrating
                    ? BipState.done
                    : (timer.isFocusPhase && timer.isRunning)
                        ? BipState.focus
                        : BipState.idle,
              ),
              const Spacer(),
              _TimerDisplay(time: timer.formattedTime),
              const SizedBox(height: 20),
              _FocusCyclePills(
                filled: timer.completedPomodoros,
                total: 3,
              ),
              const SizedBox(height: 32),
              const _ControlButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// Top bar

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const _HamburgerIcon(),
            ),
          ),
          Text(
            'Treemato',
            style: TMText.brand(
              fontSize: 20,
              color: TM.cream.withValues(alpha: 0.7),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => TaskListScreen.show(context),
            child: const _StickyNoteIcon(),
          ),
        ],
      ),
    );
  }
}

class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _HamburgerPainter()),
    );
  }
}

class _HamburgerPainter extends CustomPainter {
  const _HamburgerPainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final y in [8.0, 14.0, 20.0]) {
      final path = Path()
        ..moveTo(4, y)
        ..quadraticBezierTo(14, y - 2, 24, y);
      c.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HamburgerPainter old) => false;
}

class _StickyNoteIcon extends StatelessWidget {
  const _StickyNoteIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -4 * math.pi / 180,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: TM.lemon,
          boxShadow: [BoxShadow(color: TM.ink, offset: Offset(2, 2))],
        ),
        child: const CustomPaint(painter: _StickyLinesPainter()),
      ),
    );
  }
}

class _StickyLinesPainter extends CustomPainter {
  const _StickyLinesPainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final k = s.width / 24.0;
    const lines = [
      [6.0, 9.0, 18.0],
      [6.0, 13.0, 18.0],
      [6.0, 17.0, 14.0],
    ];
    for (final line in lines) {
      final x1 = line[0] * k;
      final y = line[1] * k;
      final x2 = line[2] * k;
      final path = Path()
        ..moveTo(x1, y)
        ..quadraticBezierTo((x1 + x2) / 2, y - 2 * k, x2, y);
      c.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StickyLinesPainter old) => false;
}

// Active module label

class _ActiveModuleLabel extends StatelessWidget {
  final String task;
  const _ActiveModuleLabel({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now Tree-mah-doing:',
            style: TMText.ui(
              fontSize: 10,
              letterSpacing: 3,
              weight: FontWeight.w600,
              color: TM.cream.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            task,
            style: TMText.marker(fontSize: 28, color: TM.cream, height: 1.0),
          ),
          const MarkerUnderline(width: 170),
        ],
      ),
    );
  }
}

// Mascot and orbit

class _MascotWithOrbit extends StatelessWidget {
  final BipState bipState;
  const _MascotWithOrbit({this.bipState = BipState.idle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: _DashedEllipsePainter(
                  insetX: 20,
                  insetY: 30,
                ),
              ),
            ),
            Center(
              child: BipMascot(
                state: bipState,
                size: 240,
              ),
            ),
            const Positioned(
              top: 24,
              left: 54,
              child: _OrbitDot(size: 10, color: TM.cobalt),
            ),
            const Positioned(
              top: 190,
              right: 48,
              child: _OrbitDot(size: 8, color: TM.lemon),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  final double size;
  final Color color;
  const _OrbitDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DashedEllipsePainter extends CustomPainter {
  final double insetX;
  final double insetY;
  const _DashedEllipsePainter({required this.insetX, required this.insetY});

  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(
      insetX,
      insetY,
      s.width - insetX * 2,
      s.height - insetY * 2,
    );
    final path = Path()..addOval(rect);
    final paint = Paint()
      ..color = TM.lemon.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dash = 2.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        c.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedEllipsePainter old) =>
      old.insetX != insetX || old.insetY != insetY;
}

// Timer display

class _TimerDisplay extends StatelessWidget {
  final String time;
  const _TimerDisplay({required this.time});

  @override
  Widget build(BuildContext context) {
    final mainStyle = TMText.display(
      fontSize: 82,
      letterSpacing: -2,
      color: TM.cream,
      height: 0.9,
    );
    final ghostStyle = TMText.display(
      fontSize: 82,
      letterSpacing: -2,
      color: TM.tomato.withValues(alpha: 0.55),
      height: 0.9,
    );
    return Column(
      children: [
        SizedBox(
          height: 82,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < time.length; i++)
                _FlipChar(
                  char: time[i],
                  mainStyle: mainStyle,
                  ghostStyle: ghostStyle,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const _RotatingSubtitle(),
      ],
    );
  }
}

/// Rotates a set of marker-voice motivational lines under the timer.
/// Swaps every 13 seconds with a soft cross-fade. Respects reduced-motion.
class _RotatingSubtitle extends StatefulWidget {
  const _RotatingSubtitle();

  @override
  State<_RotatingSubtitle> createState() => _RotatingSubtitleState();
}

class _RotatingSubtitleState extends State<_RotatingSubtitle> {
  static const _lines = <String>[
    'it gets easier, trust me bro',
    'breathe in. breathe out. type.',
    "you've survived worse. like monday.",
    'tabs can wait. they always do.',
    'one tomato at a time, hero.',
  ];

  int _index = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 13), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _lines.length);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        if (reduceMotion) return child;
        return AnimatedBuilder(
          animation: anim,
          builder: (_, c) {
            final sigma = (1 - anim.value) * 6.0;
            final filtered = sigma > 0.05
                ? ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: sigma,
                      sigmaY: sigma,
                    ),
                    child: c,
                  )
                : c;
            return Opacity(opacity: anim.value, child: filtered);
          },
          child: child,
        );
      },
      child: Text(
        _lines[_index],
        key: ValueKey(_index),
        style: TMText.ui(
          fontSize: 11,
          letterSpacing: 2,
          color: TM.cream.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Single timer character that animates a Y-axis flip whenever [char] changes.
/// Renders both the misregistration ghost and the main glyph together so they
/// flip in lockstep.
class _FlipChar extends StatelessWidget {
  final String char;
  final TextStyle mainStyle;
  final TextStyle ghostStyle;
  const _FlipChar({
    required this.char,
    required this.mainStyle,
    required this.ghostStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => AnimatedBuilder(
        animation: anim,
        builder: (_, c) {
          final angle = (1 - anim.value) * (math.pi / 2);
          return Opacity(
            opacity: anim.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(angle),
              child: c,
            ),
          );
        },
        child: child,
      ),
      child: Stack(
        key: ValueKey(char),
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-3, 2),
            child: Text(char, style: ghostStyle),
          ),
          Text(char, style: mainStyle),
        ],
      ),
    );
  }
}

// Focus cycle pills

class _FocusCyclePills extends StatelessWidget {
  final int filled;
  final int total;
  const _FocusCyclePills({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          return Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            child: _Pill(active: i < filled),
          );
        }),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final bool active;
  const _Pill({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 10,
      decoration: BoxDecoration(
        color: active ? TM.tomato : TM.dim,
        border: Border.all(
          color: active ? TM.tomato2 : TM.dim2,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: active ? const CustomPaint(painter: _PillStripePainter()) : null,
    );
  }
}

class _PillStripePainter extends CustomPainter {
  const _PillStripePainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    for (double x = 0; x < s.width; x += 6) {
      c.drawRect(Rect.fromLTWH(x, 0, 2, s.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PillStripePainter old) => false;
}

// Control button — toggles between START / PAUSE / RESUME.
// Long-press resets the current phase.

class _ControlButton extends StatelessWidget {
  const _ControlButton();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();

    // Button label depends on state.
    final String label;
    switch (timer.status) {
      case TimerStatus.idle:
        label = 'START';
      case TimerStatus.running:
        label = 'PAUSE';
      case TimerStatus.paused:
        label = 'RESUME';
    }

    // Color shifts for break phases.
    final bgColor = timer.isFocusPhase ? TM.tomato : TM.cobalt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: () {
          if (timer.isRunning) {
            timer.pauseTimer();
          } else {
            timer.startTimer();
          }
        },
        onLongPress: () => timer.resetTimer(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: TM.ink, width: 3),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: TM.lemon, offset: Offset(4, 4)),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: TMText.display(
                    fontSize: 20,
                    letterSpacing: 3,
                    color: TM.cream,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              right: 16,
              child: Transform.rotate(
                angle: 12 * math.pi / 180,
                child: const Bolt(size: 20, color: TM.lemon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
