import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bip_mascot.dart';
import '../widgets/control_button_effects.dart';
import '../widgets/freeze_options_modal.dart';
import '../widgets/freeze_overlay.dart';
import '../widgets/motifs.dart';
import '../widgets/page_entry_sfx.dart';
import 'task_list_screen.dart';

/// Timer / Home screen.
///
/// Reads all state from [TimerProvider] — no local timer or demo ticker.
///
/// `visible` mirrors the HistoryScreen pattern — plumbed in from MainShell
/// so screen-entry SFX fires only on tab navigation, not on persistent
/// rebuilds inside the IndexedStack.
class TimerScreen extends StatelessWidget {
  final bool visible;
  const TimerScreen({super.key, this.visible = false});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final activeTask = context.watch<TaskProvider>().activeTask;
    // While a focus phase runs we show the active task's name in the
    // "Now Tree-mah-doing" label — falls back to the phase label
    // ("Focus" / "Short Break" / "Long Break") whenever there's no
    // active task or we're on a break.
    final moduleLabel = (timer.isFocusPhase && activeTask != null)
        ? activeTask.name
        : timer.phaseLabel;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DotGridBackground(),
        // Invisible listener — plays a chime whenever a focus phase
        // completes (regular vs final-of-cycle variant) and when a break
        // phase ends. All three on PlayerMode.mediaPlayer so long clips
        // play to completion (SoundPool would truncate past ~5–6 s).
        const _PhaseCompletionSfx(),
        // Page-entry chime — plays once each time the user navigates TO
        // the timer tab from another tab. Re-tapping the timer tab while
        // already on it leaves `visible` true → no replay.
        PageEntrySfx(visible: visible, asset: 'audio/timerpage.mp3'),

        const Align(
          alignment: Alignment(0.92, -0.85),
          child: Spark(size: 18, color: TM.lemon),
        ),
        const Align(
          alignment: Alignment(-0.92, -0.55),
          child: Spark(size: 12, color: TM.cobalt),
        ),
        SafeArea(
          bottom: false,
          // Fast upward flick anywhere on the timer surface pulls up the task list
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              // -700 px/s is roughly the same flick threshold Flutter's
              // bottom sheet uses to dismiss. Symmetric on the way in.
              if (v < -700) TaskListScreen.show(context);
            },
            child: Column(
              children: [
                const _TopBar(),
                const SizedBox(height: 12),
                _ActiveModuleLabel(task: moduleLabel),
                const Spacer(),
                _MascotWithOrbit(
                  bipState: timer.isCelebrating
                      ? BipState.done
                      : (timer.isFocusPhase && timer.isRunning)
                          ? BipState.focus
                          : BipState.idle,
                ),
                const Spacer(),
                _TimerDisplay(
                  time: timer.formattedTime,
                  isRunning: timer.isRunning,
                  shouldPulseHint: !timer.hasSeenFreezeHintPulse,
                ),
                const SizedBox(height: 20),
                _FocusCyclePills(
                  filled: timer.completedPomodoros,
                  total: timer.pomodorosPerCycle,
                ),
                const SizedBox(height: 14),
                const _ControlButton(),
                const SizedBox(height: 16),
              ],
            ),
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
          boxShadow: [
            BoxShadow(color: TM.ink, offset: Offset(2, 2), blurRadius: 0),
          ],
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
              color: TM.cream.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            task,
            style: TMText.marker(fontSize: 28, color: TM.cream, height: 1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
//
// Long-pressing the digits triggers a 2-second cobalt-frost freeze build-up.
// On completion, the SKIP / RESET options modal pops; releasing early
// reverses the animation and the timer carries on. The underlying countdown
// keeps ticking throughout — the freeze visuals are layered on top only.

class _TimerDisplay extends StatefulWidget {
  final String time;
  final bool isRunning;
  // True only while the user has never seen the freeze-hint pulse before.
  final bool shouldPulseHint;
  const _TimerDisplay({
    required this.time,
    required this.isRunning,
    required this.shouldPulseHint,
  });

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _freezeCtrl;

  // Independent looping ticker that drives the sweep-gradient highlight
  // around the frost border. Runs only while the freeze is engaged.
  late final AnimationController _shimmerCtrl;
  // One-time upward nudge on the freeze hint, fired on the user's first
  // press-start. 800 ms, sin half-wave: 0 → -4 px → 0.
  late final AnimationController _hintPulseCtrl;
  bool _modalOpen = false;

  @override
  void initState() {
    super.initState();
    _freezeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      reverseDuration: const Duration(milliseconds: 400),
    )..addStatusListener(_onFreezeStatus);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _hintPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant _TimerDisplay old) {
    super.didUpdateWidget(old);
    final justStarted = widget.isRunning && !old.isRunning;
    if (justStarted &&
        widget.shouldPulseHint &&
        !_hintPulseCtrl.isAnimating &&
        _hintPulseCtrl.status != AnimationStatus.completed) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (!reduceMotion) {
        _hintPulseCtrl.forward(from: 0);
      }
      //the user has now crossed press-start once, so the hint has served its purpose.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TimerProvider>().markFreezeHintPulseSeen();
      });
    }
  }

  @override
  void dispose() {
    _freezeCtrl
      ..removeStatusListener(_onFreezeStatus)
      ..dispose();
    _shimmerCtrl.dispose();
    _hintPulseCtrl.dispose();
    super.dispose();
  }

  void _onFreezeStatus(AnimationStatus s) {
    if (s == AnimationStatus.dismissed) {
      _shimmerCtrl.stop();
      return;
    }
    if (s != AnimationStatus.completed || _modalOpen || !mounted) return;
    _handleFreezeComplete();
  }

  /// Pauses the timer, awaits the user's choice, then either advances /
  /// restarts / resumes depending on the outcome, and reverses the freeze
  /// animation.
  Future<void> _handleFreezeComplete() async {
    _modalOpen = true;
    final timer = context.read<TimerProvider>();
    final wasRunning = timer.isRunning;
    if (wasRunning) timer.pauseTimer();

    final choice = await showFreezeOptions(context);

    if (!mounted) return;
    _modalOpen = false;

    final t = context.read<TimerProvider>();
    switch (choice) {
      case FreezeChoice.skip:
        t.skipPhase();
        break;
      case FreezeChoice.reset:
        t.resetTimer();
        break;
      case null:
        // Dismissed without choosing — restore the prior run state so the
        // session continues as if nothing happened.
        if (wasRunning) t.startTimer();
        break;
    }

    _freezeCtrl.reverse();
  }

  void _engageFreeze() {
    // Only available while the timer is actually counting down. Idle and
    // paused states have their own affordances (the START / RESUME button)
    // and the freeze gesture would be confusing without an active session
    // to skip or restart.
    if (!widget.isRunning) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _freezeCtrl.duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 2000);
    _freezeCtrl.forward();
    if (!reduceMotion && !_shimmerCtrl.isAnimating) {
      _shimmerCtrl.repeat();
    }
  }

  void _releaseFreeze() {
    if (_modalOpen) return;
    _freezeCtrl.reverse();
  }

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

    final digitsRow = SizedBox(
      height: 82,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.time.length; i++)
            _FlipChar(
              char: widget.time[i],
              mainStyle: mainStyle,
              ghostStyle: ghostStyle,
            ),
        ],
      ),
    );

    return Column(
      children: [
        // Caption rebuilds only when freeze progress changes — not every
        // shimmer frame. Hidden entirely when the timer isn't running, since
        // the gesture is gated on isRunning.
        AnimatedBuilder(
          animation: Listenable.merge([_freezeCtrl, _hintPulseCtrl]),
          builder: (_, __) {
            final pulseY = _hintPulseCtrl.value > 0 && _hintPulseCtrl.value < 1
                ? math.sin(_hintPulseCtrl.value * math.pi) * -4
                : 0.0;
            return Opacity(
              opacity: widget.isRunning
                  ? (1.0 - _freezeCtrl.value).clamp(0.0, 1.0)
                  : 0.0,
              child: Transform.translate(
                offset: Offset(0, pulseY),
                child: Transform.rotate(
                  angle: -1.0 * math.pi / 180,
                  child: Text(
                    'hold timer for more options',
                    style: TMText.marker(
                      fontSize: 14,
                      color: TM.cream.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressDown: (_) => _engageFreeze(),
          onLongPressCancel: _releaseFreeze,
          onLongPressEnd: (_) => _releaseFreeze(),
          child: AnimatedBuilder(
            animation: Listenable.merge([_freezeCtrl, _shimmerCtrl]),
            builder: (_, child) => FreezeOverlay(
              progress: _freezeCtrl.value,
              shimmerPhase: _shimmerCtrl.value,
              child: child!,
            ),
            child: digitsRow,
          ),
        ),
        const SizedBox(height: 8),
        const _RotatingSubtitle(),
      ],
    );
  }
}

class _RotatingSubtitle extends StatefulWidget {
  const _RotatingSubtitle();

  @override
  State<_RotatingSubtitle> createState() => _RotatingSubtitleState();
}

class _RotatingSubtitleState extends State<_RotatingSubtitle> {
  static const _focusLines = <String>[
    'it gets easier, trust me bro',
    'breathe in. breathe out. type.',
    "you've survived worse. like monday.",
    'tabs can wait. they always do.',
    'one tomato at a time, hero.',
  ];
  static const _breakLines = <String>[
    'go look out a window.',
    'stretch the legs. stretch the soul.',
    'a tomato a day keeps the chaos at bay.',
    'drink some water, future you.',
    'look away from the screen. yes really.',
  ];

  final math.Random _rng = math.Random();
  int _index = 0;
  bool? _prevIsFocusPhase;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 27), (_) {
      if (!mounted) return;
      // No state churn under reduced motion — line stays stable.
      if (MediaQuery.of(context).disableAnimations) return;
      setState(() => _index = _pickNextIndex());
    });
  }

  /// Pick any index in the active bank except the current one, so the
  /// same line never shows twice in a row.
  int _pickNextIndex() {
    final bankSize = _activeBank().length;
    if (bankSize <= 1) return 0;
    final offset = _rng.nextInt(bankSize - 1) + 1;
    return (_index + offset) % bankSize;
  }

  List<String> _activeBank() {
    final isFocus = _prevIsFocusPhase ?? true;
    return isFocus ? _focusLines : _breakLines;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isFocusPhase = context.select<TimerProvider, bool>(
      (t) => t.isFocusPhase,
    );

    // Phase flip → snap to a fresh random line from the new bank so the
    // break user doesn't get a focus-voice line lingering on screen.
    if (_prevIsFocusPhase != null && _prevIsFocusPhase != isFocusPhase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final newBank = isFocusPhase ? _focusLines : _breakLines;
        setState(() => _index = _rng.nextInt(newBank.length));
      });
    }
    _prevIsFocusPhase = isFocusPhase;

    final bank = isFocusPhase ? _focusLines : _breakLines;
    final safeIndex = _index % bank.length;

    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
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
        bank[safeIndex],
        // Key includes the bank identity so the cross-fade fires when the
        // phase flips, not just when the index changes.
        key: ValueKey('${isFocusPhase ? 'f' : 'b'}-$safeIndex'),
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
// Skip / reset now live behind the freeze gesture on the timer digits.
//
// Overdrive build:
//   - Press (onTapDown): vertical squash + horizontal stretch, lemon
//     shadow snaps closer to the body, tomato2 misregistration ghost
//     materialises behind the button. HapticFeedback.selectionClick.
//   - Release into START / RESUME: tomato (or cobalt) shockwave ring
//     expands and fades, 6 cream/lemon confetti streamers radiate from
//     the centre, 5 sparks fly diagonal-up-right from the bolt anchor,
//     the bolt scale-punches with rotation jitter, the label slams in
//     with a tomato2 misreg ghost, button rebounds 1.0 → 1.06 → 1.0.
//     HapticFeedback.heavyImpact.
//   - Release into PAUSE: a soft cream2 ripple instead, no streamers /
//     sparks, the bolt slumps to 35° and 0.8 scale (and stays there
//     until the next RESUME / START). HapticFeedback.mediumImpact.
//   - Idle: when status is idle, the bolt wiggles once every 5s as a
//     tap invitation. Cancelled on the first interaction.
//   - All motion respects MediaQuery.disableAnimations; haptics still
//     fire under reduced motion (they're an accessibility-positive
//     signal, not motion).

class _ControlButton extends StatefulWidget {
  const _ControlButton();

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final AnimationController _burstCtrl;
  late final AnimationController _idleHintCtrl;
  // Drives the "no, you can't pause" horizontal shake when the user taps
  // the button while Strict Mode + running has locked it.
  late final AnimationController _shakeCtrl;
  late final AnimationController _lockMsgCtrl;
  Timer? _idleNudgeTimer;
  TimerStatus? _prevStatus;
  bool? _prevStrictLocked;
  BurstVariant _variant = BurstVariant.burst;

  // Pool of pre-loaded SFX players for the strict-mode lock tap. Round-robin
  // ensures rapid taps always hit a player that's either idle or finished,
  // dodging audioplayers' quirk where seek/resume on a "completed" player
  // in low-latency mode (Android SoundPool) silently no-ops.
  static const int _lockedSfxPoolSize = 3;
  final List<AudioPlayer> _lockedSfxPool = [];
  int _lockedSfxIdx = 0;
  bool _lockedSfxReady = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _idleHintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _lockMsgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initLockedSfx();
  }

  Future<void> _initLockedSfx() async {
    try {
      for (int i = 0; i < _lockedSfxPoolSize; i++) {
        final p = AudioPlayer();
        // ReleaseMode.stop keeps the source decoded between plays so
        // there's no per-tap setup cost.
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource('audio/locked.mp3'));
        _lockedSfxPool.add(p);
      }
      if (!mounted) {
        for (final p in _lockedSfxPool) {
          await p.dispose();
        }
        _lockedSfxPool.clear();
        return;
      }
      _lockedSfxReady = true;
    } catch (_) {
      // If loading fails (missing asset, decoder error), silently degrade —
      // the haptic + visual shake still convey the locked state.
    }
  }

  void _playLockedSfx() {
    if (!_lockedSfxReady || _lockedSfxPool.isEmpty) return;
    final p = _lockedSfxPool[_lockedSfxIdx];
    _lockedSfxIdx = (_lockedSfxIdx + 1) % _lockedSfxPool.length;
    // stop() resets the player out of the "completed" state that swallows
    // resume() calls in low-latency mode; chained resume() then triggers
    // a fresh playback from the head.
    p.stop().then((_) {
      if (!mounted) return;
      p.resume();
    });
  }

  @override
  void dispose() {
    _idleNudgeTimer?.cancel();
    _pressCtrl.dispose();
    _burstCtrl.dispose();
    _idleHintCtrl.dispose();
    _shakeCtrl.dispose();
    _lockMsgCtrl.dispose();
    for (final p in _lockedSfxPool) {
      p.dispose();
    }
    super.dispose();
  }

  void _syncIdleNudge(TimerProvider timer) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final shouldNudge = timer.isIdle && !reduced;
    if (shouldNudge) {
      _idleNudgeTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          if (!mounted) return;
          if (!context.read<TimerProvider>().isIdle) return;
          if (_idleHintCtrl.isAnimating) return;
          _idleHintCtrl.forward(from: 0);
        },
      );
    } else {
      _idleNudgeTimer?.cancel();
      _idleNudgeTimer = null;
      if (_idleHintCtrl.isAnimating) _idleHintCtrl.stop();
      _idleHintCtrl.value = 0;
    }
  }

  void _onTapDown(TapDownDetails _) {
    final reduced = MediaQuery.of(context).disableAnimations;
    // Cancel idle hint immediately — user is interacting.
    _idleNudgeTimer?.cancel();
    _idleNudgeTimer = null;
    if (_idleHintCtrl.isAnimating) _idleHintCtrl.stop();
    _idleHintCtrl.value = 0;

    if (!reduced) _pressCtrl.forward();
    HapticFeedback.selectionClick();

    // Locked SFX fires here (not _onTapUp) so every interaction attempt —
    // including a tap that gets cancelled by sliding off the button —
    // plays the sound. Round-robin pool ensures rapid presses always
    // land on a player that can replay.
    final timer = context.read<TimerProvider>();
    if (timer.isRunning && timer.strictModeOn) {
      _playLockedSfx();
    }
  }

  void _onTapUp(TapUpDetails _) {
    final timer = context.read<TimerProvider>();
    final reduced = MediaQuery.of(context).disableAnimations;
    final wasRunning = timer.isRunning;

    // Strict Mode lock
    if (wasRunning && timer.strictModeOn) {
      HapticFeedback.selectionClick();
      // SFX already played on tap-down — don't replay here.
      if (reduced) {
        _pressCtrl.value = 0;
      } else {
        _pressCtrl.reverse();
        _shakeCtrl.forward(from: 0);
      }
      _lockMsgCtrl.forward(from: 0);
      return;
    }

    if (wasRunning) {
      _variant = BurstVariant.deflate;
      timer.pauseTimer();
      HapticFeedback.mediumImpact();
    } else {
      _variant = BurstVariant.burst;
      timer.startTimer();
      HapticFeedback.heavyImpact();
    }

    if (reduced) {
      _pressCtrl.value = 0;
    } else {
      _pressCtrl.reverse();
      _burstCtrl.forward(from: 0);
    }
  }

  void _onTapCancel() {
    final reduced = MediaQuery.of(context).disableAnimations;
    if (!reduced) _pressCtrl.reverse();
  }

  String _labelFor(TimerStatus status, {bool strictLocked = false}) {
    if (strictLocked && status == TimerStatus.running) return 'LOCKED';
    switch (status) {
      case TimerStatus.idle:
        return 'START';
      case TimerStatus.running:
        return 'PAUSE';
      case TimerStatus.paused:
        return 'RESUME';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final reduced = MediaQuery.of(context).disableAnimations;
    final strictLocked = timer.isRunning && timer.strictModeOn;
    final label = _labelFor(timer.status, strictLocked: strictLocked);
    final bgColor = timer.isFocusPhase ? TM.tomato : TM.cobalt;
    final ringColor = timer.isFocusPhase ? TM.tomato : TM.cobalt;

    // Re-sync the idle nudge timer on any status transition.
    if (_prevStatus != timer.status) {
      _prevStatus = timer.status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncIdleNudge(timer);
      });
    }

    // When the user toggles Strict Mode from the drawer mid-session, the
    // label needs to swap (PAUSE ↔ LOCKED). Reuse the existing _BurstLabel
    // cross-fade by kicking _burstCtrl with the deflate variant — that
    // gives us the scale + ghost label swap for free without spawning any
    // confetti / sparks (those are gated on BurstVariant.burst).
    if (_prevStrictLocked != null && _prevStrictLocked != strictLocked) {
      if (!reduced) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _variant = BurstVariant.deflate;
          _burstCtrl.forward(from: 0);
        });
      }
    }
    _prevStrictLocked = strictLocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge(
            <Listenable>[
              _pressCtrl,
              _burstCtrl,
              _idleHintCtrl,
              _shakeCtrl,
              _lockMsgCtrl,
            ],
          ),
          builder: (context, _) {
            final pressEase = Curves.easeOutQuart.transform(_pressCtrl.value);
            final burst = _burstCtrl.value;

            // Squash on press: horizontal 1.0 → 1.04, vertical 1.0 → 0.92.
            final scaleX = 1.0 + 0.04 * pressEase;
            final scaleY = 1.0 - 0.08 * pressEase;

            // Rebound 1.0 → 1.06 → 1.0 in the first 260 ms of the burst
            // (burst.value 0 → 0.46). Sin half-wave gives a clean overshoot
            // without spring / elastic feel.
            double rebound = 1.0;
            if (!reduced &&
                _variant == BurstVariant.burst &&
                burst > 0 &&
                burst < 0.46) {
              final phase = burst / 0.46;
              rebound = 1.0 + 0.06 * math.sin(phase * math.pi);
            }
            final effectiveScaleX = scaleX * rebound;
            final effectiveScaleY = scaleY * rebound;

            // Shadow offset interp during press: (4,4) → (1,1). When locked
            // the shadow stays snapped at (1,1) regardless of press — the
            // button reads as "already pushed in, going nowhere".
            final shadowDx = strictLocked ? 1.0 : 4.0 - 3.0 * pressEase;
            final shadowDy = strictLocked ? 1.0 : 4.0 - 3.0 * pressEase;

            // Tomato2 misregistration ghost behind the button.
            final ghostOpacity = 0.30 * pressEase;

            final showBurst = !reduced && burst > 0 && burst < 1;
            final showBurstVariant =
                showBurst && _variant == BurstVariant.burst;
            final showDeflateVariant =
                showBurst && _variant == BurstVariant.deflate;

            // Locked head-shake: damped sine, ±6 px, dies out over 180 ms.
            final shakeT = _shakeCtrl.value;
            final shakeDx = shakeT > 0 && shakeT < 1
                ? math.sin(shakeT * math.pi * 3) * 6 * (1 - shakeT)
                : 0.0;

            // Strict-mode lock caption
            final lockMsgT = _lockMsgCtrl.value;
            double lockMsgOpacity = 0.0;
            if (lockMsgT > 0 && lockMsgT < 1) {
              if (lockMsgT < 0.10) {
                lockMsgOpacity = lockMsgT / 0.10;
              } else if (lockMsgT < 0.85) {
                lockMsgOpacity = 1.0;
              } else {
                lockMsgOpacity = 1.0 - (lockMsgT - 0.85) / 0.15;
              }
            }

            final lockCaption = SizedBox(
              height: 18,
              child: Opacity(
                opacity: lockMsgOpacity,
                child: Transform.rotate(
                  angle: -1.0 * math.pi / 180,
                  child: Text(
                    'strict mode is on, focus first',
                    style: TMText.marker(
                      fontSize: 14,
                      color: TM.cream.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            );

            final shakenButton = Transform.translate(
              offset: Offset(shakeDx, 0),
              child: Transform.scale(
                scaleX: effectiveScaleX,
                scaleY: effectiveScaleY,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tomato2 misregistration ghost (press feedback) — behind.
                    if (!reduced && ghostOpacity > 0.005)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Transform.translate(
                            offset: const Offset(-5, 3),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    TM.tomato2.withValues(alpha: ghostOpacity),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Deflate ripple — BEHIND the button.
                    if (showDeflateVariant)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: DeflateRipplePainter(
                              progress: burst,
                              color: TM.cream2,
                            ),
                          ),
                        ),
                      ),

                    // Main button body.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: TM.ink, width: 3),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: TM.lemon,
                            offset: Offset(shadowDx, shadowDy),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _BurstLabel(
                        label: label,
                        burst: burst,
                        variant: _variant,
                        reducedMotion: reduced,
                      ),
                    ),

                    // Shockwave ring — OVER the button.
                    if (showBurstVariant)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ShockwaveRingPainter(
                              progress: burst,
                              color: ringColor,
                            ),
                          ),
                        ),
                      ),

                    // Confetti streamers (radiating from centre).
                    if (showBurstVariant)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ConfettiStreamerPainter(progress: burst),
                          ),
                        ),
                      ),

                    // Sparks near the bolt anchor (top-right).
                    if (showBurstVariant)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SparkBurstPainter(progress: burst),
                          ),
                        ),
                      ),

                    // Bolt — animated punch / slump / idle wiggle.
                    Positioned(
                      top: -8,
                      right: 16,
                      child: _AnimatedBolt(
                        burst: burst,
                        variant: _variant,
                        idleHint: _idleHintCtrl.value,
                        timerStatus: timer.status,
                        reducedMotion: reduced,
                        locked: strictLocked,
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Caption sits OUTSIDE the shake transform so it stays still
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                lockCaption,
                shakenButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Label rendered inside the control button.
///
/// On a state change, the old label scales+fades down while the new label
/// scales 1.3 → 1.0. On the START / RESUME variant, a tomato2 misregistration
/// ghost copy of the new label converges from offset (-3, +2) → (0, 0) and
/// fades out, echoing the timer digits' misreg ghost.
class _BurstLabel extends StatefulWidget {
  final String label;
  final double burst;
  final BurstVariant variant;
  final bool reducedMotion;

  const _BurstLabel({
    required this.label,
    required this.burst,
    required this.variant,
    required this.reducedMotion,
  });

  @override
  State<_BurstLabel> createState() => _BurstLabelState();
}

class _BurstLabelState extends State<_BurstLabel> {
  String? _outgoingLabel;

  @override
  void didUpdateWidget(covariant _BurstLabel old) {
    super.didUpdateWidget(old);
    if (old.label != widget.label) {
      // Capture the previous label so it can fade out alongside the
      // incoming one.  Set on label change wins over the reset-cleanup
      // branch below — rapid taps arrive as (burst goes 1.0 → 0.0 AND
      // label changes) in the same frame.
      _outgoingLabel = old.label;
    } else if (widget.burst == 0 && old.burst > 0) {
      // Burst fully reset without a label change — clean up so the next
      // press doesn't paint a stale outgoing label.
      _outgoingLabel = null;
    }
  }

  TextStyle _style({Color color = TM.cream}) => TMText.display(
        fontSize: 20,
        letterSpacing: 3,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    if (widget.reducedMotion || widget.burst == 0 || widget.burst >= 1) {
      return Text(widget.label, style: _style());
    }

    final isBurstVariant = widget.variant == BurstVariant.burst;
    final outEnd = isBurstVariant ? 0.21 : 0.30;
    final inEnd = isBurstVariant ? 0.39 : 0.54;

    // Incoming label.
    final newT = (widget.burst / inEnd).clamp(0.0, 1.0);
    final newEase = Curves.easeOutExpo.transform(newT);
    final newScale = 1.3 - 0.3 * newEase;
    final ghostT = (1 - newEase).clamp(0.0, 1.0);

    Widget incoming = Transform.scale(
      scale: newScale,
      child: Text(widget.label, style: _style()),
    );

    // Outgoing (previous) label.
    Widget? outgoing;
    if (_outgoingLabel != null && widget.burst < outEnd) {
      final outT = (widget.burst / outEnd).clamp(0.0, 1.0);
      final outEase = Curves.easeOutQuart.transform(outT);
      final outScale = (1.0 - outEase).clamp(0.0, 1.0);
      final outOpacity = (1.0 - outEase).clamp(0.0, 1.0);
      outgoing = IgnorePointer(
        child: Opacity(
          opacity: outOpacity,
          child: Transform.scale(
            scale: outScale,
            child: Text(_outgoingLabel!, style: _style()),
          ),
        ),
      );
    }

    // Misregistration ghost (only on the burst variant).
    Widget? ghost;
    if (isBurstVariant && ghostT > 0.01) {
      final dx = -3.0 * ghostT;
      final dy = 2.0 * ghostT;
      ghost = IgnorePointer(
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: newScale,
            child: Text(
              widget.label,
              style: _style(color: TM.tomato2.withValues(alpha: ghostT)),
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (ghost != null) ghost,
        incoming,
        if (outgoing != null) outgoing,
      ],
    );
  }
}

/// Bolt that scale-punches and rotation-jitters on START / RESUME, smoothly
/// slumps on PAUSE (and holds the slumped pose until the next start/resume),
/// and does a single tap-invitation wiggle every 5 s while the timer is idle.
class _AnimatedBolt extends StatelessWidget {
  final double burst;
  final BurstVariant variant;
  final double idleHint;
  final TimerStatus timerStatus;
  final bool reducedMotion;
  final bool locked;

  const _AnimatedBolt({
    required this.burst,
    required this.variant,
    required this.idleHint,
    required this.timerStatus,
    required this.reducedMotion,
    this.locked = false,
  });

  static const double _restRotDeg = 12;
  static const double _slumpRotDeg = 35;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion) {
      // Locked under reduced motion: hold the slump pose so the visual
      // still reads as "powered down"; otherwise a static rest pose.
      return Transform.scale(
        scale: locked ? 0.8 : 1.0,
        child: Transform.rotate(
          angle: (locked ? _slumpRotDeg : _restRotDeg) * math.pi / 180,
          child: const Bolt(size: 20, color: TM.lemon),
        ),
      );
    }

    // Locked + idle (no in-flight burst): hold the slump pose. The
    // (burst == 0 || burst >= 1) guard lets a start-of-session burst
    // still punch the bolt before it settles into the lock.
    if (locked && (burst == 0 || burst >= 1)) {
      return Transform.scale(
        scale: 0.8,
        child: Transform.rotate(
          angle: _slumpRotDeg * math.pi / 180,
          child: const Bolt(size: 20, color: TM.lemon),
        ),
      );
    }

    double rotDeg = _restRotDeg;
    double scale = 1.0;

    if (timerStatus == TimerStatus.paused) {
      // Slumped pose. Lerp from rest → slump if we just paused (variant=deflate).
      if (variant == BurstVariant.deflate && burst > 0 && burst < 1) {
        final t = Curves.easeOutQuart.transform(burst);
        rotDeg = _restRotDeg + (_slumpRotDeg - _restRotDeg) * t;
        scale = 1.0 - 0.2 * t;
      } else {
        rotDeg = _slumpRotDeg;
        scale = 0.8;
      }
    } else {
      // Running or idle: rest pose, with optional burst punch or idle wiggle.
      if (variant == BurstVariant.burst && burst > 0 && burst < 1) {
        // Three-stage scale punch:
        //   burst 0.00 → 0.18: 0.6 → 1.35 (fast pop)
        //   burst 0.18 → 0.50: 1.35 → 1.0 (settle)
        //   burst 0.50 → 1.00: 1.0 (rest)
        if (burst < 0.18) {
          final t = burst / 0.18;
          scale = 0.6 + 0.75 * Curves.easeOutExpo.transform(t);
        } else if (burst < 0.50) {
          final t = (burst - 0.18) / 0.32;
          scale = 1.35 - 0.35 * Curves.easeOutQuart.transform(t);
        } else {
          scale = 1.0;
        }
        // Rotation jitter falls off as burst progresses.
        final jitterAmp = 18 * (1 - burst);
        rotDeg = _restRotDeg + math.sin(burst * math.pi * 8) * jitterAmp;
      } else if (idleHint > 0 && timerStatus == TimerStatus.idle) {
        // Idle wiggle: 12° → 0° → 22° → 12° across the 600 ms controller.
        final t = idleHint;
        if (t < 0.33) {
          final p = t / 0.33;
          rotDeg = _restRotDeg +
              (0 - _restRotDeg) * Curves.easeOutQuart.transform(p);
        } else if (t < 0.66) {
          final p = (t - 0.33) / 0.33;
          rotDeg = 0 + (22 - 0) * Curves.easeOutQuart.transform(p);
        } else {
          final p = (t - 0.66) / 0.34;
          rotDeg = 22 + (_restRotDeg - 22) * Curves.easeOutQuart.transform(p);
        }
      }
    }

    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotDeg * math.pi / 180,
        child: const Bolt(size: 20, color: TM.lemon),
      ),
    );
  }
}

// Phase-completion SFX
//
// Invisible widget that subscribes to TimerProvider via addListener and
// fires the right chime on every phase boundary:
//
//   - focus → regular pomo  ⇒ pomo_complete.mp3
//   - focus → last of cycle ⇒ onFinalPomoComplete.mp3
//   - break → next phase    ⇒ onBreakOver.mp3
//
// All three players run on PlayerMode.mediaPlayer because the clips are
// long (the final-pomo cue is ~25 s). lowLatency mode is backed by
// Android SoundPool, which truncates anything past ~5–6 s; mediaPlayer
// streams the full file with negligible startup latency for a one-shot.
// Pool size 1 each — phase boundaries are minutes apart, so there's no
// rapid-fire risk.
//
// Variant choice for focus completions: at the moment isCelebrating
// flips true, `_phaseIndex` has already advanced to the *next* phase.
// If that next phase is the long break, the focus we just completed was
// the cycle's last pomo → onFinalPomoComplete.mp3.
//
// Break completions use a mirrored flag on the provider (isOnBreakOver)
// since there's no other reliable way to distinguish a natural break
// boundary from a resetCycle / shape-rebuild from the UI side.
//
// Caveat: if the user changes pomodorosPerCycle / shortBreaksOn while a
// session is running, the sequence rebuilds on the next phase boundary
// (see TimerProvider._advancePhase). If that boundary coincides with a
// focus completion, the rebuilt sequence starts at index 0 (focus), so
// `phase` reads as focus rather than longBreak — we'd play the regular
// chime even if the just-completed focus was the old cycle's last. Rare
// edge; flag if you want different behaviour.
class _PhaseCompletionSfx extends StatefulWidget {
  const _PhaseCompletionSfx();

  @override
  State<_PhaseCompletionSfx> createState() => _PhaseCompletionSfxState();
}

class _PhaseCompletionSfxState extends State<_PhaseCompletionSfx> {
  AudioPlayer? _regularPlayer;
  AudioPlayer? _finalPlayer;
  AudioPlayer? _breakOverPlayer;
  bool _ready = false;

  TimerProvider? _timer;
  bool _prevCelebrating = false;
  bool _prevBreakOver = false;

  @override
  void initState() {
    super.initState();
    final timer = context.read<TimerProvider>();
    _timer = timer;
    _prevCelebrating = timer.isCelebrating;
    _prevBreakOver = timer.isOnBreakOver;
    timer.addListener(_onTimerChange);
    _initSfx();
  }

  Future<AudioPlayer?> _prime(String asset) async {
    final p = AudioPlayer();
    try {
      // mediaPlayer mode (default for AudioPlayer): no size cap, plays
      // the full clip even past ~6 s.
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.mediaPlayer);
      await p.setSource(AssetSource(asset));
      return p;
    } catch (_) {
      await p.dispose();
      return null;
    }
  }

  Future<void> _initSfx() async {
    final regular = await _prime('audio/pomo_complete.mp3');
    final fin = await _prime('audio/onFinalPomoComplete.mp3');
    final brk = await _prime('audio/onBreakOver.mp3');
    if (!mounted) {
      await regular?.dispose();
      await fin?.dispose();
      await brk?.dispose();
      return;
    }
    _regularPlayer = regular;
    _finalPlayer = fin;
    _breakOverPlayer = brk;
    _ready = true;
  }

  void _onTimerChange() {
    final t = _timer;
    if (t == null) return;
    final celebrating = t.isCelebrating;
    final breakOver = t.isOnBreakOver;
    // Edge-trigger on each flag separately. Both stay true until the
    // next startTimer / reset, so without the edge guard we'd retrigger
    // on every tick that follows.
    if (celebrating && !_prevCelebrating) {
      if (t.phase == TimerPhase.longBreak) {
        _play(_finalPlayer);
      } else {
        _play(_regularPlayer);
      }
    }
    if (breakOver && !_prevBreakOver) {
      _play(_breakOverPlayer);
    }
    _prevCelebrating = celebrating;
    _prevBreakOver = breakOver;
  }

  void _play(AudioPlayer? p) {
    if (!_ready || p == null) return;
    // stop().then(resume) restarts cleanly even if a previous play is
    // somehow still in-flight. Phase boundaries are minutes apart so
    // collisions effectively never happen, but the pattern is cheap.
    p.stop().then((_) {
      if (!mounted) return;
      p.resume();
    });
  }

  @override
  void dispose() {
    _timer?.removeListener(_onTimerChange);
    _regularPlayer?.dispose();
    _finalPlayer?.dispose();
    _breakOverPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
