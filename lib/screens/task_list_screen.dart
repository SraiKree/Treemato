import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/motifs.dart';

/// Daily Task List screen.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  /// Present as a bottom sheet. Tap-outside, drag-down, back chip, and the
  /// system back button all dismiss.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: TM.ink.withValues(alpha: 0.55),
      clipBehavior: Clip.none,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: TaskListScreen(),
      ),
    );
  }

  static const List<_TaskItem> _tasks = [
    _TaskItem('Fix Bug #104', 4),
    _TaskItem('Refactor UI Engine', 3, active: true),
    _TaskItem('Prepare PR', 0, done: true),
    _TaskItem('water the plant', 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Stack(
              clipBehavior: Clip.none,
              children: const [
                _TornPaper(tasks: _tasks),
                Positioned(
                  top: -8,
                  left: 0,
                  right: 0,
                  child: Center(child: _TapeStrip()),
                ),
                Positioned(
                  right: 10,
                  bottom: 20,
                  child: _PostItMemo(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskItem {
  final String name;
  final int remaining;
  final bool done;
  final bool active;
  const _TaskItem(
    this.name,
    this.remaining, {
    this.done = false,
    this.active = false,
  });
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
          _BackChip(onTap: () => Navigator.of(context).pop()),
          Text(
            'TODAY · TUE',
            style: TMText.display(
              fontSize: 11,
              letterSpacing: 2,
              color: TM.cream.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.rotate(
        angle: -4 * math.pi / 180,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: TM.lemon,
            border: Border.all(color: TM.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: TM.tomato, offset: Offset(2, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CustomPaint(painter: _BackChevronPainter()),
          ),
        ),
      ),
    );
  }
}

class _BackChevronPainter extends CustomPainter {
  const _BackChevronPainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(s.width * 14 / 22, s.height * 5 / 22)
      ..lineTo(s.width * 7 / 22, s.height * 11 / 22)
      ..lineTo(s.width * 14 / 22, s.height * 17 / 22);
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackChevronPainter old) => false;
}

// Torn paper task list

class _TornPaper extends StatelessWidget {
  final List<_TaskItem> tasks;
  const _TornPaper({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _TornEdgeClipper(),
      child: CustomPaint(
        painter: const _PaperLinesPainter(),
        child: Stack(
          children: [
            // Red margin rule
            Positioned(
              top: 20,
              bottom: 20,
              left: 46,
              width: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TM.tomato.withValues(alpha: 0.7),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DAILY TASK LIST',
                    style: TMText.display(
                      fontSize: 26,
                      letterSpacing: 1,
                      color: TM.ink,
                    ),
                  ),
                  const MarkerUnderline(width: 200),
                  const SizedBox(height: 14),
                  ...tasks.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TaskRow(task: t),
                      )),
                  const SizedBox(height: 8),
                  const _AddTaskRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TornEdgeClipper extends CustomClipper<Path> {
  const _TornEdgeClipper();

  @override
  Path getClip(Size s) {
    final w = s.width;
    final h = s.height;
    // % coordinates from design_ref polygon clipPath CSS.
    const pts = <List<double>>[
      [0.00, 0.06], [0.06, 0.02], [0.14, 0.05], [0.22, 0.01],
      [0.32, 0.04], [0.44, 0.00], [0.56, 0.04], [0.68, 0.01],
      [0.80, 0.05], [0.92, 0.02], [1.00, 0.06], [0.98, 0.94],
      [0.90, 0.99], [0.78, 0.95], [0.66, 1.00], [0.54, 0.96],
      [0.42, 1.00], [0.30, 0.95], [0.18, 0.99], [0.08, 0.96],
      [0.00, 0.94],
    ];
    final path = Path()..moveTo(pts[0][0] * w, pts[0][1] * h);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0] * w, pts[i][1] * h);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TornEdgeClipper old) => false;
}

class _PaperLinesPainter extends CustomPainter {
  const _PaperLinesPainter();

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = TM.lemon);
    final linePaint = Paint()
      ..color = TM.ink.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 38; y < s.height; y += 39) {
      c.drawLine(Offset(0, y), Offset(s.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperLinesPainter old) => false;
}

// Tape strip decoration

class _TapeStrip extends StatelessWidget {
  const _TapeStrip();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * math.pi / 180,
      child: Container(
        width: 80,
        height: 22,
        decoration: BoxDecoration(
          color: TM.tomato.withValues(alpha: 0.65),
          border: Border.all(
            color: TM.ink.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
    );
  }
}

// Task row

class _TaskRow extends StatelessWidget {
  final _TaskItem task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final nameColor =
        task.done ? TM.ink.withValues(alpha: 0.55) : TM.ink;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SelectionCircle(active: task.active),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RichText(
                text: TextSpan(
                  style: TMText.marker(
                    fontSize: 24,
                    color: nameColor,
                    weight: FontWeight.w700,
                  ).copyWith(
                    decoration:
                        task.done ? TextDecoration.lineThrough : null,
                    decorationColor: task.done ? TM.tomato : null,
                    decorationThickness: task.done ? 3 : null,
                  ),
                  children: [
                    TextSpan(text: task.name),
                    TextSpan(
                      text: ' : ${task.remaining}',
                      style: TextStyle(
                        color: TM.ink.withValues(alpha: 0.6),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (task.active)
                const Positioned(
                  right: -2,
                  top: -6,
                  child: Spark(size: 14, color: TM.tomato),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  final bool active;
  const _SelectionCircle({required this.active});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: active ? 3 * math.pi / 180 : 0,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? TM.tomato : Colors.transparent,
                border: Border.all(color: TM.ink, width: 2.5),
              ),
            ),
            if (active)
              const Positioned.fill(
                child: CustomPaint(painter: _CheckmarkPainter()),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter();

  @override
  void paint(Canvas c, Size s) {
    final sx = s.width / 22;
    final sy = s.height / 22;
    final paint = Paint()
      ..color = TM.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(5 * sx, 12 * sy)
      ..lineTo(10 * sx, 16 * sy)
      ..lineTo(17 * sx, 7 * sy);
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter old) => false;
}

// Add task row

class _AddTaskRow extends StatelessWidget {
  const _AddTaskRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '+',
          style: TMText.marker(
            fontSize: 26,
            color: TM.tomato,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'add task',
          style: TMText.marker(
            fontSize: 22,
            color: TM.tomato,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        const Squiggle(
          width: 40,
          height: 8,
          color: TM.tomato,
          strokeWidth: 2.5,
        ),
      ],
    );
  }
}

// Post-it memo decoration

class _PostItMemo extends StatelessWidget {
  const _PostItMemo();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 6 * math.pi / 180,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: TM.mint,
          border: Border.all(color: TM.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: TM.ink, offset: Offset(2, 2)),
          ],
        ),
        child: Text(
          'p.s. you got this!',
          textAlign: TextAlign.center,
          style: TMText.marker(fontSize: 16, color: TM.ink, height: 1.1),
        ),
      ),
    );
  }
}

