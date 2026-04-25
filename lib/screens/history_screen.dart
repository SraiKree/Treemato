import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/motifs.dart';

/// Session History screen.
///
/// `visible` is plumbed in from `MainShell` so the staggered slide-in plays
/// every time the user navigates to this tab — not just once on app launch,
/// which is when initState fires inside the persistent IndexedStack.
class HistoryScreen extends StatefulWidget {
  final bool visible;
  const HistoryScreen({super.key, this.visible = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();

  static const _today = <_HistoryEntry>[
    _HistoryEntry(
      task: 'Refactor UI Engine',
      time: 'Today, 10:30 AM – 10:55 AM',
      duration: '25m',
      isPomo: true,
    ),
    _HistoryEntry(
      task: null,
      time: 'Today, 10:00 AM – 10:05 AM',
      duration: '5m',
      isPomo: false,
    ),
    _HistoryEntry(
      task: 'Refactor UI Engine',
      time: 'Today, 9:30 AM – 9:55 AM',
      duration: '25m',
      isPomo: true,
    ),
  ];

  static const _yesterday = <_HistoryEntry>[
    _HistoryEntry(
      task: 'Fix Bug #104',
      time: 'Yesterday, 4:15 PM – 4:40 PM',
      duration: '25m',
      isPomo: true,
    ),
    _HistoryEntry(
      task: null,
      time: 'Yesterday, 3:55 PM – 4:10 PM',
      duration: '15m',
      isPomo: false,
    ),
    _HistoryEntry(
      task: 'water the plant',
      time: 'Yesterday, 2:30 PM – 2:55 PM',
      duration: '25m',
      isPomo: true,
    ),
  ];

}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen old) {
    super.didUpdateWidget(old);
    // Replay each time the tab becomes visible.
    if (!old.visible && widget.visible) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = HistoryScreen._today;
    final yesterday = HistoryScreen._yesterday;
    final items = <Widget>[
      _DayDivider(label: 'today', count: today.length),
      ...today.map(
        (e) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: _HistoryRow(entry: e),
        ),
      ),
      const SizedBox(height: 10),
      _DayDivider(label: 'yesterday', count: yesterday.length),
      ...yesterday.map(
        (e) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: _HistoryRow(entry: e),
        ),
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        const DotGridBackground(),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < items.length; i++)
                        _StaggeredEntry(
                          controller: _ctrl,
                          index: i,
                          total: items.length,
                          child: items[i],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wraps a child in a fade + slide-up driven by a slice of [controller]'s
/// progress. Slice = `[index/total .. index/total + window]`, clamped to 1.
class _StaggeredEntry extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final int total;
  final Widget child;
  const _StaggeredEntry({
    required this.controller,
    required this.index,
    required this.total,
    required this.child,
  });

  static const _window = 0.4; // each item takes 40% of total to play
  static const _slidePx = 16.0;

  @override
  Widget build(BuildContext context) {
    // Last item starts at (1 - window) so everything finishes by 1.0.
    final start = (index / total) * (1 - _window);
    final end = start + _window;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final raw = ((controller.value - start) / (end - start)).clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _slidePx),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _HistoryEntry {
  final String? task;
  final String time;
  final String duration;
  final bool isPomo;
  const _HistoryEntry({
    required this.task,
    required this.time,
    required this.duration,
    required this.isPomo,
  });
}

// Header

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION HISTORY',
            style: TMText.display(fontSize: 20, letterSpacing: 1),
          ),
          const MarkerUnderline(width: 160, color: TM.lemon),
        ],
      ),
    );
  }
}

// Day divider

class _DayDivider extends StatelessWidget {
  final String label;
  final int count;
  const _DayDivider({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TMText.marker(fontSize: 22, color: TM.lemon),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(color: TM.dim2),
              child: SizedBox(height: 1),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count SESSIONS',
            style: TMText.ui(
              fontSize: 10,
              letterSpacing: 2,
              color: TM.cream.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// History row

class _HistoryRow extends StatelessWidget {
  final _HistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final borderColor = entry.isPomo ? TM.tomato : TM.cream2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TM.ink2,
        border: Border(
          top: const BorderSide(color: TM.dim2, width: 2),
          right: const BorderSide(color: TM.dim2, width: 2),
          bottom: const BorderSide(color: TM.dim2, width: 2),
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          _EntryIcon(isPomo: entry.isPomo),
          const SizedBox(width: 12),
          Expanded(child: _EntryContent(entry: entry)),
          const SizedBox(width: 8),
          _DurationPill(duration: entry.duration, isPomo: entry.isPomo),
        ],
      ),
    );
  }
}

class _EntryIcon extends StatelessWidget {
  final bool isPomo;
  const _EntryIcon({required this.isPomo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isPomo ? TM.tomato : TM.dim,
        border: Border.all(color: TM.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(
          painter: isPomo
              ? const _TomatoIconPainter()
              : const _CoffeeIconPainter(),
        ),
      ),
    );
  }
}

class _TomatoIconPainter extends CustomPainter {
  const _TomatoIconPainter();

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 22.0;
    final fill = Paint()..color = TM.cream;
    final stroke = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round;
    final body = Rect.fromCenter(
      center: Offset(11 * k, 13 * k),
      width: 16 * k,
      height: 14 * k,
    );
    c.drawOval(body, fill);
    final stemL = Path()
      ..moveTo(11 * k, 6 * k)
      ..cubicTo(9 * k, 4 * k, 7 * k, 4 * k, 7 * k, 6 * k);
    final stemR = Path()
      ..moveTo(11 * k, 6 * k)
      ..cubicTo(13 * k, 4 * k, 15 * k, 4 * k, 15 * k, 6 * k);
    c.drawPath(stemL, stroke);
    c.drawPath(stemR, stroke);
  }

  @override
  bool shouldRepaint(covariant _TomatoIconPainter old) => false;
}

class _CoffeeIconPainter extends CustomPainter {
  const _CoffeeIconPainter();

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 20.0;
    final stroke = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cup = Path()
      ..moveTo(4 * k, 8 * k)
      ..lineTo(14 * k, 8 * k)
      ..lineTo(13 * k, 16 * k)
      ..lineTo(5 * k, 16 * k)
      ..close();
    c.drawPath(cup, stroke);
    final handle = Path()
      ..moveTo(14 * k, 10 * k)
      ..quadraticBezierTo(18 * k, 10 * k, 18 * k, 13 * k)
      ..quadraticBezierTo(18 * k, 15 * k, 14 * k, 14 * k);
    c.drawPath(handle, stroke);
    final steamPaint = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * k
      ..strokeCap = StrokeCap.round;
    final steam1 = Path()
      ..moveTo(7 * k, 4 * k)
      ..quadraticBezierTo(7 * k, 6 * k, 8 * k, 6 * k);
    final steam2 = Path()
      ..moveTo(10 * k, 3 * k)
      ..quadraticBezierTo(10 * k, 5 * k, 11 * k, 5 * k);
    c.drawPath(steam1, steamPaint);
    c.drawPath(steam2, steamPaint);
  }

  @override
  bool shouldRepaint(covariant _CoffeeIconPainter old) => false;
}

class _EntryContent extends StatelessWidget {
  final _HistoryEntry entry;
  const _EntryContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasTask = entry.task != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hasTask ? entry.task! : '(no task selected)',
          style: TMText.marker(
            fontSize: 22,
            color: hasTask ? TM.cream : const Color(0xFF6A665F),
            height: 1.0,
          ).copyWith(
            fontStyle: hasTask ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.time,
          style: TMText.ui(
            fontSize: 11,
            letterSpacing: 0.3,
            color: TM.cream.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  final String duration;
  final bool isPomo;
  const _DurationPill({required this.duration, required this.isPomo});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -2 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPomo ? TM.tomato : TM.dim,
          border: Border.all(color: TM.ink, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          duration,
          style: TMText.display(
            fontSize: 12,
            letterSpacing: 1,
            color: TM.cream,
          ),
        ),
      ),
    );
  }
}
