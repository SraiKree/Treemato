import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/motifs.dart';

/// Focus Stats screen.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _TargetCard(count: 8),
                      ),
                      SizedBox(height: 14),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _WeekChart(),
                      ),
                      SizedBox(height: 14),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _MonthlyHarvest(),
                      ),
                      SizedBox(height: 14),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _QuoteCard(),
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
            'FOCUS STATS',
            style: TMText.display(fontSize: 20, letterSpacing: 1),
          ),
          const MarkerUnderline(width: 120, color: TM.cobalt),
        ],
      ),
    );
  }
}

// Target card

class _TargetCard extends StatelessWidget {
  final int count;
  const _TargetCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: TM.ink2,
            border: Border.all(color: TM.dim2, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BigTargetNumber(count: count),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.rotate(
                      angle: -2 * math.pi / 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: TM.tomato,
                          border: Border.all(color: TM.ink, width: 2),
                        ),
                        child: Text(
                          'TARGET HIT!',
                          style: TMText.display(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: TM.cream,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'pomos completed today',
                      style: TMText.ui(
                        fontSize: 13,
                        color: TM.cream.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: -8,
          child: Transform.rotate(
            angle: 18 * math.pi / 180,
            child: const Bolt(size: 22, color: TM.lemon),
          ),
        ),
      ],
    );
  }
}

class _BigTargetNumber extends StatelessWidget {
  final int count;
  const _BigTargetNumber({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(-2, 2),
          child: Text(
            '$count',
            style: TMText.display(
              fontSize: 58,
              letterSpacing: -2,
              color: TM.tomato.withValues(alpha: 0.5),
              height: 0.9,
            ),
          ),
        ),
        Text(
          '$count',
          style: TMText.display(
            fontSize: 58,
            letterSpacing: -2,
            color: TM.lemon,
            height: 0.9,
          ),
        ),
        const Positioned(
          top: -8,
          right: -18,
          child: Spark(size: 14, color: TM.cobalt),
        ),
      ],
    );
  }
}

// Week chart

class _WeekChart extends StatelessWidget {
  const _WeekChart();

  static const _week = [3, 5, 2, 6, 4, 0, 8];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxValue = _week.reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THIS WEEK',
          style: TMText.ui(
            fontSize: 11,
            letterSpacing: 2,
            color: TM.cream.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 112,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: TM.ink2,
            border: Border.all(color: TM.dim2, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < _week.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _WeekBar(
                    value: _week[i],
                    max: maxValue,
                    day: _days[i],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekBar extends StatelessWidget {
  final int value;
  final int max;
  final String day;
  const _WeekBar({required this.value, required this.max, required this.day});

  @override
  Widget build(BuildContext context) {
    final isMax = value == max;
    final color = value == 0 ? TM.dim : (isMax ? TM.lemon : TM.tomato);
    final barHeight = value == 0 ? 4.0 : (value / max) * 64.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 28),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: TM.ink, width: 2),
                ),
              ),
            ),
            if (isMax)
              const Positioned(
                top: -14,
                child: Spark(size: 12, color: TM.lemon),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TMText.display(
            fontSize: 10,
            color: TM.cream.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// Monthly harvest

class _MonthlyHarvest extends StatelessWidget {
  const _MonthlyHarvest();

  static const _cells = 30;

  static Color _heatColor(int v) {
    switch (v) {
      case 0:
        return TM.dim;
      case 1:
        return const Color(0xFF5A2A24);
      case 2:
        return const Color(0xFF9A3528);
      case 3:
        return TM.tomato2;
      case 4:
        return TM.tomato;
      default:
        return TM.lemon;
    }
  }

  int _heat(int i) => (((i * 7 + 3) % 11) / 2).floor();
  double _rotDeg(int i) => (((i * 7) % 6) - 3).toDouble();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'MONTHLY HARVEST',
              style: TMText.ui(
                fontSize: 11,
                letterSpacing: 2,
                color: TM.cream.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            const Squiggle(width: 40, height: 6, strokeWidth: 2),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TM.ink2,
            border: Border.all(color: TM.dim2, width: 2),
          ),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 10,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_cells, (i) {
                  return Transform.rotate(
                    angle: _rotDeg(i) * math.pi / 180,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _heatColor(_heat(i)),
                        border: Border.all(color: TM.ink, width: 1.5),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SLEEPY',
                    style: TMText.ui(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: TM.cream.withValues(alpha: 0.7),
                    ),
                  ),
                  Row(
                    children: List.generate(6, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _heatColor(i),
                            border: Border.all(color: TM.ink, width: 1),
                          ),
                        ),
                      );
                    }),
                  ),
                  Text(
                    'ON FIRE',
                    style: TMText.ui(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: TM.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Quote card

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  static const _quotes = <String>[
    '"discipline is just self-respect with a stopwatch."',
    '"the work was never the hard part. sitting still was."',
    '"you don\'t find time. you corner it."',
    '"a finished bad draft outranks a perfect imaginary one."',
    '"boredom is the doorway. most people leave before knocking."',
    '"small repeated acts are how mountains get tired of standing."',
    '"focus is a muscle. yours has been on vacation."',
    '"the cure for overthinking is undertaking."',
    '"you can do anything for 25 minutes. probably."',
    '"starting is the tax. paying it gets cheaper."',
  ];

  String get _quoteOfTheDay {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -1 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              _quoteOfTheDay,
              style: TMText.marker(fontSize: 20, color: TM.ink, height: 1.1),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: TMText.ui(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: TM.ink.withValues(alpha: 0.6),
                ),
                children: [
                  const TextSpan(text: '— '),
                  TextSpan(
                    text: 'Treemato',
                    style: TMText.brand(
                      fontSize: 14,
                      color: TM.ink.withValues(alpha: 0.75),
                    ),
                  ),
                  const TextSpan(text: ', probably'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
