import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/session_record.dart';
import 'providers/session_provider.dart';
import 'providers/task_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SessionRecordAdapter());
  final settingsBox = await Hive.openBox<dynamic>('settings');
  final tasksBox = await Hive.openBox<dynamic>('tasks');
  final sessionsBox = await Hive.openBox<SessionRecord>('sessions');

  // Construct providers eagerly so the timer can hold direct callbacks
  // into the task and session providers — one-way coupling, no circular
  // dependency.
  final taskProvider = TaskProvider(tasksBox: tasksBox);
  final sessionProvider = SessionProvider(sessionsBox: sessionsBox);
  final timerProvider = TimerProvider(
    settingsBox: settingsBox,
    onFocusCompleted: taskProvider.decrementActive,
    // Fires BEFORE onFocusCompleted, so the active task here is the one
    // that owned the just-finished pomodoro — even if decrementActive
    // is about to knock its remaining count to 0 and clear it.
    onFocusSessionCompleted: (start, end, minutes, skipped) {
      final active = taskProvider.activeTask;
      sessionProvider.addPomodoro(
        startTime: start,
        endTime: end,
        durationMinutes: minutes,
        taskId: active?.id,
        taskName: active?.name,
        skipped: skipped,
      );
    },
  );

  runApp(TreematoApp(
    timerProvider: timerProvider,
    taskProvider: taskProvider,
    sessionProvider: sessionProvider,
  ));
}

class TreematoApp extends StatelessWidget {
  final TimerProvider timerProvider;
  final TaskProvider taskProvider;
  final SessionProvider sessionProvider;

  const TreematoApp({
    super.key,
    required this.timerProvider,
    required this.taskProvider,
    required this.sessionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TimerProvider>.value(value: timerProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Treemato',
        theme: buildTreematoTheme(),
        home: const MainShell(),
      ),
    );
  }
}
