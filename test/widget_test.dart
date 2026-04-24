import 'package:flutter_test/flutter_test.dart';

import 'package:pomo_app/main.dart';

void main() {
  testWidgets('Treemato app boots and renders timer home', (tester) async {
    await tester.pumpWidget(const TreematoApp());
    expect(find.text('TREEMATO'), findsOneWidget);
    expect(find.text('25:00'), findsWidgets);
    expect(find.text('PAUSE'), findsOneWidget);
  });
}
