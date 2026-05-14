import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/motifs.dart';
import '../widgets/suitcase_entrance.dart';

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

  @override
  Widget build(BuildContext context) {
    // Keyboard offset: when the inline "add task" input is focused the
    // soft keyboard pushes up by this amount, so we mirror it as bottom
    // padding to keep the input on-screen inside the bottom sheet.
    final kbInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: kbInset),
      child: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Stack(
                clipBehavior: Clip.none,
                children: const [
                  _TornPaper(),
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
      ),
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
  const _TornPaper();

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
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
              child: SingleChildScrollView(
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
                    if (tasks.isEmpty) const _EmptyHint(),
                    for (final t in tasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TaskRow(task: t),
                      ),
                    const SizedBox(height: 8),
                    const _AddTaskRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly placeholder when the list is empty — keeps the page from
/// reading as broken on first launch.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Transform.rotate(
        angle: -1.5 * math.pi / 180,
        child: Text(
          'nothing on the list yet — \nsplash one below.',
          style: TMText.marker(
            fontSize: 18,
            color: TM.ink.withValues(alpha: 0.55),
            height: 1.15,
          ),
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
  final Task task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final nameColor =
        task.done ? TM.ink.withValues(alpha: 0.55) : TM.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () async {
        HapticFeedback.mediumImpact();
        final confirmed = await _showDeleteConfirm(context, task);
        if (confirmed == true && context.mounted) {
          context.read<TaskProvider>().removeTask(task.id);
        }
      },
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SelectionCircle(
          active: task.active,
          onTap: task.done
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  context.read<TaskProvider>().setActive(task.id);
                },
        ),
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
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  final bool active;

  /// When `null`, the circle is read-only (used for done rows). Otherwise
  /// the whole 34×34 hit area dispatches taps to the callback.
  final VoidCallback? onTap;
  const _SelectionCircle({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = Transform.rotate(
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

    // 6px padding around the 22×22 visual gives a 34×34 hit target —
    // matches the row's previous left-margin footprint (22 + 12 spacer)
    // so the layout doesn't shift, and clears Material's 48px tap-zone
    // *enough* for a touch on the densest paper rows.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: visual,
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
//
// Two visual states behind one widget:
//   1. Collapsed — the original "+ add task" Caveat affordance with the
//      tomato squiggle. Tapping it switches to editing.
//   2. Editing — Caveat text field for the task name + a tiny ± stepper
//      for the pomodoro count (1..99) + a tomato ✓ commit button.
// Empty name on commit / submit cancels back to the collapsed state.

class _AddTaskRow extends StatefulWidget {
  const _AddTaskRow();

  @override
  State<_AddTaskRow> createState() => _AddTaskRowState();
}

class _AddTaskRowState extends State<_AddTaskRow> {
  bool _editing = false;
  final _controller = TextEditingController();
  final _focus = FocusNode();
  int _remaining = 1;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _remaining = 1;
      _controller.clear();
    });
    // Defer focus until after the frame so the TextField is in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _commit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      _cancel();
      return;
    }
    context.read<TaskProvider>().addTask(name, remaining: _remaining);
    HapticFeedback.lightImpact();
    _cancel();
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _controller.clear();
      _remaining = 1;
    });
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startEditing,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
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
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              cursorColor: TM.tomato,
              style: TMText.marker(
                fontSize: 22,
                color: TM.ink,
                weight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                hintText: 'task name',
                hintStyle: TMText.marker(
                  fontSize: 22,
                  color: TM.ink.withValues(alpha: 0.35),
                  weight: FontWeight.w700,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              maxLines: 1,
              maxLength: 40,
              buildCounter: (_,
                  {required currentLength,
                  required isFocused,
                  required maxLength}) => null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commit(),
            ),
          ),
          const SizedBox(width: 6),
          _MiniStep(
            label: '−',
            onTap: () => setState(() {
              _remaining = (_remaining - 1).clamp(1, 99);
            }),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 22,
            child: Text(
              '$_remaining',
              textAlign: TextAlign.center,
              style: TMText.display(
                fontSize: 18,
                color: TM.ink,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _MiniStep(
            label: '+',
            onTap: () => setState(() {
              _remaining = (_remaining + 1).clamp(1, 99);
            }),
          ),
          const SizedBox(width: 8),
          _CommitCheck(onTap: _commit),
        ],
      ),
    );
  }
}

class _MiniStep extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MiniStep({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: TM.cream2,
          border: Border.all(color: TM.ink, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TMText.display(
            fontSize: 14,
            color: TM.ink,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _CommitCheck extends StatelessWidget {
  final VoidCallback onTap;
  const _CommitCheck({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.rotate(
        angle: 3 * math.pi / 180,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: TM.tomato,
            border: Border.all(color: TM.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: TM.lemon, offset: Offset(1.5, 1.5)),
            ],
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CustomPaint(painter: _CommitCheckPainter()),
          ),
        ),
      ),
    );
  }
}

class _CommitCheckPainter extends CustomPainter {
  const _CommitCheckPainter();

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = TM.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = s.width;
    final h = s.height;
    final path = Path()
      ..moveTo(w * 0.18, h * 0.55)
      ..lineTo(w * 0.42, h * 0.78)
      ..lineTo(w * 0.82, h * 0.28);
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CommitCheckPainter old) => false;
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

// Delete confirmation modal

/// Pops a small "throw this out?" modal styled like a paper sticker.
/// Resolves to `true` if the user confirmed deletion, `false` if they
/// cancelled, or `null` if they tapped outside to dismiss.
Future<bool?> _showDeleteConfirm(BuildContext context, Task task) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss delete confirmation',
    barrierColor: TM.ink.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (_, __, ___) => _DeleteConfirmBody(taskName: task.name),
    transitionBuilder: (_, anim, __, child) {
      final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      );
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _DeleteConfirmBody extends StatelessWidget {
  final String taskName;
  const _DeleteConfirmBody({required this.taskName});

  @override
  Widget build(BuildContext context) {
    final routeAnim = ModalRoute.of(context)!.animation!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Transform.rotate(
          angle: -1.5 * math.pi / 180,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: TM.cream,
              border: Border.all(color: TM.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: TM.tomato, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOSS THIS TASK?',
                  style: TMText.display(
                    fontSize: 18,
                    letterSpacing: 1,
                    color: TM.ink,
                  ),
                ),
                const MarkerUnderline(width: 130, color: TM.tomato),
                const SizedBox(height: 10),
                Text(
                  '"$taskName"',
                  style: TMText.marker(
                    fontSize: 20,
                    color: TM.ink,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SuitcaseItem(
                        animation: routeAnim,
                        delayFraction: 0.35,
                        spanFraction: 0.55,
                        fromOffset: const Offset(-30, 50),
                        fromRotationDeg: -18,
                        fromScale: 0.80,
                        child: _ConfirmButton(
                          label: 'keep it',
                          fill: TM.cream2,
                          textColor: TM.ink,
                          shadowColor: TM.ink,
                          rotation: -2,
                          onTap: () => Navigator.of(context).pop(false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SuitcaseItem(
                        animation: routeAnim,
                        delayFraction: 0.50,
                        spanFraction: 0.50,
                        fromOffset: const Offset(40, 60),
                        fromRotationDeg: 22,
                        fromScale: 0.78,
                        child: _ConfirmButton(
                          label: 'TOSS IT',
                          fill: TM.tomato,
                          textColor: TM.cream,
                          shadowColor: TM.lemon,
                          rotation: 2,
                          onTap: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final Color fill;
  final Color textColor;
  final Color shadowColor;
  final double rotation;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.label,
    required this.fill,
    required this.textColor,
    required this.shadowColor,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: TM.ink, width: 2),
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(2, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TMText.display(
              fontSize: 13,
              letterSpacing: 1,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

