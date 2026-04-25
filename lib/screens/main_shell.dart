import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/app_theme.dart';
import '../widgets/motifs.dart';
import 'history_screen.dart';
import 'settings_drawer.dart';
import 'stats_screen.dart';
import 'timer_screen.dart';

/// Root shell that manages the Scaffold, settings drawer, and bottom navigation.
///
/// The tomato highlight inside the bottom bar animates between the three
/// slot centers when the user taps an icon.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1; // 0 = History, 1 = Timer, 2 = Stats

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TM.ink,
      drawer: const SettingsDrawer(),
      drawerScrimColor: TM.ink.withValues(alpha: 0.6),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                HistoryScreen(visible: _index == 0),
                const TimerScreen(),
                const StatsScreen(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: _PersistentBottomBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom navigation bar

class _PersistentBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _PersistentBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_PersistentBottomBar> createState() => _PersistentBottomBarState();
}

class _PersistentBottomBarState extends State<_PersistentBottomBar>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 18,
  );

  late final AnimationController _ctrl;
  double _startX = 0;
  double _endX = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this);
    final initial = _alignXFor(widget.currentIndex);
    _startX = initial;
    _endX = initial;
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _PersistentBottomBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      // Capture current visual position so re-tapping mid-flight stays smooth.
      final current = lerpDouble(_startX, _endX, _ctrl.value) ?? _endX;
      _startX = current;
      _endX = _alignXFor(widget.currentIndex);
      _ctrl.stop();
      _ctrl.value = 0.0;
      _ctrl.animateWith(SpringSimulation(_spring, 0, 1, 0));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Alignment corresponding to the center of each third of the row.
  /// Alignment x = -1 → parent left edge, 0 → center, 1 → right edge;
  /// so ±2.23/3 land the child center on the left/right slot centers.
  static double _alignXFor(int i) {
    switch (i) {
      case 0:
        return -2.23 / 3;
      case 2:
        return 2.23 / 3;
      case 1:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TM.ink2,
        border: Border(top: BorderSide(color: TM.dim2, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: SizedBox(
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Tomato highlight — spring-driven slide between slot centers.
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) {
                final x = lerpDouble(_startX, _endX, _ctrl.value) ?? _endX;
                return Align(
                  alignment: Alignment(x, 0),
                  child: child,
                );
              },
              child: _Highlight(big: widget.currentIndex == 1),
            ),
            // Lemon checker strip anchored above the center slot (static).
            Positioned(
              top: -20,
              child: Transform.rotate(
                angle: -8 * math.pi / 180,
                child: const Checker(width: 28, cellsX: 6, color: TM.lemon),
              ),
            ),
            // Icon slots — equal width, each centered in its cell.
            Row(
              children: [
                _Slot(onTap: () => widget.onTap(0), child: const _ClockIcon()),
                _Slot(onTap: () => widget.onTap(1), child: const _TreeIcon()),
                _Slot(
                  onTap: () => widget.onTap(2),
                  child: const _BarChartIcon(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  final bool big;
  const _Highlight({required this.big});

  @override
  Widget build(BuildContext context) {
    final size = big ? 56.0 : 40.0;
    final borderWidth = big ? 3.0 : 2.0;
    final shadow = big ? const Offset(3, 3) : const Offset(2, 2);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TM.tomato,
        border: Border.all(color: TM.ink, width: borderWidth),
        boxShadow: [BoxShadow(color: TM.lemon, offset: shadow)],
      ),
    );
  }
}

class _Slot extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Slot({required this.onTap, required this.child});

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Center(
          child: ScaleTransition(scale: _scale, child: widget.child),
        ),
      ),
    );
  }
}

// Tab icons

class _ClockIcon extends StatelessWidget {
  const _ClockIcon();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _ClockPainter()),
      );
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cx = s.width / 2;
    final cy = s.height / 2;
    c.drawCircle(Offset(cx, cy), 8, paint);
    final hand = Path()
      ..moveTo(cx, cy - 5)
      ..lineTo(cx, cy)
      ..lineTo(cx + 4, cy + 2);
    c.drawPath(hand, paint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) => false;
}

class _TreeIcon extends StatelessWidget {
  const _TreeIcon();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _TreePainter()),
      );
}

class _TreePainter extends CustomPainter {
  const _TreePainter();

  @override
  void paint(Canvas c, Size s) {
    final fill = Paint()..color = TM.cream;
    final k = s.width / 22.0;

    // Three stacked foliage triangles (chunky pine silhouette).
    final top = Path()
      ..moveTo(11 * k, 2 * k)
      ..lineTo(6 * k, 8.5 * k)
      ..lineTo(16 * k, 8.5 * k)
      ..close();
    final mid = Path()
      ..moveTo(11 * k, 6 * k)
      ..lineTo(4.5 * k, 13.5 * k)
      ..lineTo(17.5 * k, 13.5 * k)
      ..close();
    final bot = Path()
      ..moveTo(11 * k, 10 * k)
      ..lineTo(3 * k, 18 * k)
      ..lineTo(19 * k, 18 * k)
      ..close();
    c.drawPath(top, fill);
    c.drawPath(mid, fill);
    c.drawPath(bot, fill);

    // Trunk.
    c.drawRect(
      Rect.fromLTWH(9.5 * k, 18 * k, 3 * k, 3 * k),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) => false;
}

class _BarChartIcon extends StatelessWidget {
  const _BarChartIcon();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _BarChartPainter()),
      );
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()..color = TM.cream;
    final k = s.width / 26.0;
    c.drawRect(Rect.fromLTWH(4 * k, 14 * k, 4 * k, 8 * k), paint);
    c.drawRect(Rect.fromLTWH(11 * k, 10 * k, 4 * k, 12 * k), paint);
    c.drawRect(Rect.fromLTWH(18 * k, 6 * k, 4 * k, 16 * k), paint);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => false;
}
