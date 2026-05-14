import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session_record.dart';
import '../providers/session_provider.dart';
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
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final ScrollController _scroll = ScrollController();

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
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>().pomodorosNewestFirst;

    return Stack(
      fit: StackFit.expand,
      children: [
        ParallaxDotGrid(controller: _scroll),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: sessions.isEmpty
                    ? const _EmptyState()
                    : _HistoryList(
                        sessions: sessions,
                        scroll: _scroll,
                        ctrl: _ctrl,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── List & grouping ──────────────────────────────────────────────────

/// Renders the day-grouped, staggered-in list of pomodoro entries.
class _HistoryList extends StatelessWidget {
  final List<SessionRecord> sessions;
  final ScrollController scroll;
  final AnimationController ctrl;

  const _HistoryList({
    required this.sessions,
    required this.scroll,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = today.subtract(const Duration(days: 1));

    // Group sessions by calendar day, preserving newest-first order
    // since the input is already sorted that way.
    final grouped = <DateTime, List<SessionRecord>>{};
    for (final s in sessions) {
      grouped.putIfAbsent(_dayKey(s.startTime), () => []).add(s);
    }
    final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Flatten into a single child list (divider per day, then rows).
    final items = <Widget>[];
    for (final day in dayKeys) {
      final entries = grouped[day]!;
      final label = day == today
          ? 'today'
          : day == yesterday
              ? 'yesterday'
              : _formatDayLabel(day);
      items.add(_DayDivider(label: label, count: entries.length));
      for (final e in entries) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: _HistoryRow(entry: e, sessionDay: day, today: today, yesterday: yesterday),
          ),
        );
      }
      items.add(const SizedBox(height: 10));
    }

    return SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++)
            _StaggeredEntry(
              controller: ctrl,
              index: i,
              total: items.length,
              child: items[i],
            ),
        ],
      ),
    );
  }
}

DateTime _dayKey(DateTime t) => DateTime(t.year, t.month, t.day);

const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _months = [
  'jan', 'feb', 'mar', 'apr', 'may', 'jun',
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
];

/// Formats a non-today/non-yesterday day key as e.g. `mon, may 13`.
String _formatDayLabel(DateTime day) {
  // DateTime.weekday returns 1 (Mon) .. 7 (Sun).
  final dow = _weekdays[day.weekday - 1];
  final mon = _months[day.month - 1];
  return '$dow, $mon ${day.day}';
}

/// Formats a wall-clock time as `H:MM AM/PM` (12-hour, no leading zero
/// on the hour to match the design's `10:30 AM` style).
String _formatTime(DateTime t) {
  final hour12 = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
  final mins = t.minute.toString().padLeft(2, '0');
  final ampm = t.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$mins $ampm';
}

/// Formats a duration in minutes as the duration pill text. Pomodoros
/// today are typically 25m; long sessions clamp to `Hh Mm` so the pill
/// stays compact even for a 90-minute focus block.
String _formatDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

// ── Empty state ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -3 * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: TM.ink2,
                  border: Border.all(color: TM.dim2, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: TM.tomato2, offset: Offset(3, 3)),
                  ],
                ),
                child: Text(
                  'no tomatoes yet',
                  style: TMText.marker(fontSize: 28, color: TM.cream),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'finish a pomodoro and it lands here.',
              textAlign: TextAlign.center,
              style: TMText.ui(
                fontSize: 12,
                letterSpacing: 0.4,
                color: TM.cream.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stagger ──────────────────────────────────────────────────────────

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

// ── Header ───────────────────────────────────────────────────────────

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

// ── Day divider ──────────────────────────────────────────────────────

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
            count == 1 ? '1 SESSION' : '$count SESSIONS',
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

// ── History row ──────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final SessionRecord entry;
  final DateTime sessionDay;
  final DateTime today;
  final DateTime yesterday;
  const _HistoryRow({
    required this.entry,
    required this.sessionDay,
    required this.today,
    required this.yesterday,
  });

  @override
  Widget build(BuildContext context) {
    // Always tomato-coloured — breaks aren't persisted, so every row is
    // a pomodoro. (Keeping the design's left-border accent intact.)
    const borderColor = TM.tomato;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TM.ink2,
        border: const Border(
          top: BorderSide(color: TM.dim2, width: 2),
          right: BorderSide(color: TM.dim2, width: 2),
          bottom: BorderSide(color: TM.dim2, width: 2),
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          const _EntryIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: _EntryContent(
              entry: entry,
              sessionDay: sessionDay,
              today: today,
              yesterday: yesterday,
            ),
          ),
          // Skipped rows omit the duration pill — they carry no real
          // time data, so a pill would be misleading.
          if (!entry.skipped) ...[
            const SizedBox(width: 8),
            _DurationPill(duration: _formatDuration(entry.durationMinutes)),
          ],
        ],
      ),
    );
  }
}

class _EntryIcon extends StatelessWidget {
  const _EntryIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: TM.tomato,
        border: Border.all(color: TM.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _TomatoIconPainter()),
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

class _EntryContent extends StatelessWidget {
  final SessionRecord entry;
  final DateTime sessionDay;
  final DateTime today;
  final DateTime yesterday;
  const _EntryContent({
    required this.entry,
    required this.sessionDay,
    required this.today,
    required this.yesterday,
  });

  @override
  Widget build(BuildContext context) {
    final hasTask = entry.taskName != null && entry.taskName!.isNotEmpty;

    // Skipped rows carry no real time data — drop the timestamp line
    // and label the row "(skipped)" instead. The task name (or "no
    // task selected" fallback) stays so the user can still see what
    // was bailed on.
    final String subtitle;
    if (entry.skipped) {
      subtitle = '(skipped)';
    } else {
      // Day prefix matches the dividers above — capitalised because it
      // sits inside a full sentence-style label.
      final dayPrefix = sessionDay == today
          ? 'Today'
          : sessionDay == yesterday
              ? 'Yesterday'
              : _formatDayLabel(sessionDay);
      subtitle =
          '$dayPrefix, ${_formatTime(entry.startTime)} – ${_formatTime(entry.endTime)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hasTask ? entry.taskName! : '(no task selected)',
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
          subtitle,
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
  const _DurationPill({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -2 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TM.tomato,
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
