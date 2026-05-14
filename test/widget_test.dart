import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:pomo_app/main.dart';
import 'package:pomo_app/models/session_record.dart';
import 'package:pomo_app/providers/session_provider.dart';
import 'package:pomo_app/providers/task_provider.dart';
import 'package:pomo_app/providers/timer_provider.dart';

void main() {
  late Box<dynamic> settingsBox;
  late Box<dynamic> tasksBox;
  late Box<SessionRecord> sessionsBox;

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync().path);
    Hive.registerAdapter(SessionRecordAdapter());
    settingsBox = await Hive.openBox<dynamic>('test_settings');
    tasksBox = await Hive.openBox<dynamic>('test_tasks');
    sessionsBox = await Hive.openBox<SessionRecord>('test_sessions');
  });

  tearDownAll(() async {
    await settingsBox.close();
    await tasksBox.close();
    await sessionsBox.close();
  });

  testWidgets('Treemato app boots and renders timer home', (tester) async {
    final taskProvider = TaskProvider(tasksBox: tasksBox);
    final sessionProvider = SessionProvider(sessionsBox: sessionsBox);
    final timerProvider = TimerProvider(
      settingsBox: settingsBox,
      onFocusCompleted: taskProvider.decrementActive,
    );
    await tester.pumpWidget(
      TreematoApp(
        timerProvider: timerProvider,
        taskProvider: taskProvider,
        sessionProvider: sessionProvider,
      ),
    );
    expect(find.text('Treemato'), findsWidgets);
    expect(find.text('25:00'), findsWidgets);
    expect(find.text('START'), findsOneWidget);
  });
}
