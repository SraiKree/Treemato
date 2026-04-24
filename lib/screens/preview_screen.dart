import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bip_mascot.dart';
import '../widgets/motifs.dart';

/// Temporary canvas that showcases every token and motif primitive.
/// Gets replaced by TimerScreen in step 3. Kept so you can `flutter run`
/// and visually confirm palette, fonts, and decorative pieces render as
/// expected before we build the real screens on top of them.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TM.ink,
      body: Stack(
        children: [
          const DotGridBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  const SizedBox(height: 28),
                  _SectionLabel('PALETTE'),
                  const SizedBox(height: 10),
                  const _PaletteGrid(),
                  const SizedBox(height: 28),
                  _SectionLabel('MOTIFS'),
                  const SizedBox(height: 10),
                  const _MotifsCard(),
                  const SizedBox(height: 28),
                  _SectionLabel('TYPOGRAPHY'),
                  const SizedBox(height: 10),
                  const _TypeCard(),
                  const SizedBox(height: 28),
                  _SectionLabel('BIP — MASCOT STATES'),
                  const SizedBox(height: 12),
                  const _BipGallery(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'TREE',
                style: TMText.display(fontSize: 44, height: 0.95),
              ),
              TextSpan(
                text: '_',
                style: TMText.display(fontSize: 44, color: TM.tomato),
              ),
              TextSpan(
                text: 'MATO',
                style: TMText.display(fontSize: 44, height: 0.95),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Transform.rotate(
          angle: -0.05,
          alignment: Alignment.centerLeft,
          child: Text(
            'a quirky take on the tomato timer',
            style: TMText.marker(fontSize: 22, color: TM.cobalt),
          ),
        ),
        const SizedBox(height: 6),
        const MarkerUnderline(width: 160),
        const SizedBox(height: 10),
        Text(
          'VISUAL DIRECTION · RISO × MEMPHIS · TOKEN PREVIEW',
          style: TMText.ui(
            fontSize: 11,
            letterSpacing: 2,
            color: TM.cream.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TMText.ui(
        fontSize: 11,
        letterSpacing: 2,
        color: TM.cream.withValues(alpha: 0.6),
      ),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid();

  @override
  Widget build(BuildContext context) {
    const swatches = <_Swatch>[
      _Swatch('paper-black', TM.ink, '#0E0D0C', TM.cream),
      _Swatch('bone-cream', TM.cream, '#F5ECD7', TM.ink),
      _Swatch('tomato', TM.tomato, '#FF3B2F', TM.cream),
      _Swatch('lemon', TM.lemon, '#FFD23F', TM.ink),
      _Swatch('cobalt', TM.cobalt, '#2F6BFF', TM.cream),
      _Swatch('mint', TM.mint, '#9BE3C3', TM.ink),
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: swatches.map((s) => _SwatchTile(swatch: s)).toList(),
    );
  }
}

class _Swatch {
  final String name;
  final Color bg;
  final String hex;
  final Color fg;
  const _Swatch(this.name, this.bg, this.hex, this.fg);
}

class _SwatchTile extends StatelessWidget {
  final _Swatch swatch;
  const _SwatchTile({required this.swatch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: swatch.bg,
        border: Border.all(color: TM.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: TM.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            swatch.name,
            style: TMText.marker(fontSize: 20, color: swatch.fg),
          ),
          Text(
            swatch.hex,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 1,
              color: swatch.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotifsCard extends StatelessWidget {
  const _MotifsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: TM.ink2,
        border: Border.all(color: TM.dim2, width: 2),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: const [
          Squiggle(width: 80, height: 14),
          Bolt(size: 22),
          Spark(size: 18, color: TM.cobalt),
          Checker(width: 50, cellsX: 8),
          MarkerUnderline(width: 90),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TM.cream,
        border: Border.all(color: TM.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: TM.tomato, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '25:00 HEY',
            style: TMText.display(
              fontSize: 48,
              letterSpacing: -2,
              color: TM.ink,
            ),
          ),
          Text(
            'ARCHIVO BLACK · DISPLAY',
            style: TMText.ui(
              fontSize: 10,
              letterSpacing: 2,
              color: TM.ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Clean geometric body copy for UI, labels, timestamps.',
            style: TMText.ui(fontSize: 15, color: TM.ink),
          ),
          Text(
            'SPACE GROTESK · UI',
            style: TMText.ui(
              fontSize: 10,
              letterSpacing: 2,
              color: TM.ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'refactor the UI engine',
            style: TMText.marker(fontSize: 28, color: TM.tomato),
          ),
          Text(
            'CAVEAT · MARKER',
            style: TMText.ui(
              fontSize: 10,
              letterSpacing: 2,
              color: TM.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _BipGallery extends StatelessWidget {
  const _BipGallery();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _BipCard(
          state: BipState.idle,
          caption: 'breathes slowly · waiting',
        ),
        SizedBox(height: 14),
        _BipCard(
          state: BipState.focus,
          caption: 'squints · subtle breathing · sweat bead',
        ),
        SizedBox(height: 14),
        _BipCard(
          state: BipState.done,
          caption: 'streamers · big smile · wobbles',
        ),
      ],
    );
  }
}

class _BipCard extends StatelessWidget {
  final BipState state;
  final String caption;
  const _BipCard({required this.state, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: TM.ink2,
        border: Border.all(color: TM.dim2, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Center(child: BipMascot(state: state, size: 140)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.name,
                  style: TMText.marker(fontSize: 28, color: TM.lemon),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: TMText.ui(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: TM.cream.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
