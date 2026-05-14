import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'suitcase_entrance.dart';

/// Outcome of [showFreezeOptions]. `null` means the user dismissed without
/// choosing (tap-outside).
enum FreezeChoice { skip, reset }

/// Pops the SKIP / RESET decision modal that follows a completed freeze
/// gesture. Tapping outside the buttons (the dimmed barrier) dismisses
/// without selection (resolves to `null`); tapping a button resolves to the
/// matching [FreezeChoice].
Future<FreezeChoice?> showFreezeOptions(BuildContext context) {
  return showGeneralDialog<FreezeChoice>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss freeze options',
    barrierColor: TM.ink.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (_, anim, __) => _FreezeOptionsBody(animation: anim),
  );
}

class _FreezeOptionsBody extends StatelessWidget {
  final Animation<double> animation;
  const _FreezeOptionsBody({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuitcaseItem(
              animation: animation,
              delayFraction: 0.10,
              spanFraction: 0.70,
              fromOffset: const Offset(-40, 60),
              fromRotationDeg: -22,
              fromScale: 0.75,
              child: _StickerButton(
                label: 'SKIP THIS ONE  →',
                fill: TM.tomato,
                textColor: TM.cream,
                shadowColor: TM.ink,
                rotation: -2 * math.pi / 180,
                onTap: () =>
                    Navigator.of(context).pop(FreezeChoice.skip),
              ),
            ),
            const SizedBox(height: 16),
            SuitcaseItem(
              animation: animation,
              delayFraction: 0.30,
              spanFraction: 0.70,
              fromOffset: const Offset(50, 80),
              fromRotationDeg: 28,
              fromScale: 0.72,
              child: _StickerButton(
                label: '↻  REDO THIS ONE',
                fill: TM.cream,
                textColor: TM.ink,
                shadowColor: TM.lemon,
                rotation: 2 * math.pi / 180,
                onTap: () =>
                    Navigator.of(context).pop(FreezeChoice.reset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerButton extends StatelessWidget {
  final String label;
  final Color fill;
  final Color textColor;
  final Color shadowColor;
  final double rotation;
  final VoidCallback onTap;

  const _StickerButton({
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
      angle: rotation,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: TM.ink, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(4, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TMText.display(
              fontSize: 18,
              letterSpacing: 2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
