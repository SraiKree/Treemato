import 'dart:math' as math;
import 'package:flutter/material.dart';
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
              children: const [
                HistoryScreen(),
                TimerScreen(),
                StatsScreen(),
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

class _PersistentBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _PersistentBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

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
            // Tomato highlight behind the active icon.
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: _alignFor(currentIndex),
              child: _Highlight(big: currentIndex == 1),
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
                _Slot(onTap: () => onTap(0), child: const _ClockIcon()),
                _Slot(onTap: () => onTap(1), child: const _PlayIcon()),
                _Slot(onTap: () => onTap(2), child: const _BarChartIcon()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Alignment _alignFor(int i) {
    switch (i) {
      case 0:
        return const Alignment(-2.23 / 3, 0);
      case 2:
        return const Alignment(2.23 / 3, 0);
      case 1:
      default:
        return Alignment.center;
    }
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

class _Slot extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Slot({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(child: child),
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

class _PlayIcon extends StatelessWidget {
  const _PlayIcon();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _PlayPainter()),
      );
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter();

  @override
  void paint(Canvas c, Size s) {
    final path = Path()
      ..moveTo(s.width * 5 / 22, s.height * 3 / 22)
      ..lineTo(s.width * 19 / 22, s.height * 11 / 22)
      ..lineTo(s.width * 5 / 22, s.height * 19 / 22)
      ..close();
    c.drawPath(path, Paint()..color = TM.cream);
  }

  @override
  bool shouldRepaint(covariant _PlayPainter old) => false;
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
