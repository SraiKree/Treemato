import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox<dynamic>('settings');
  final tasksBox = await Hive.openBox<dynamic>('tasks');

  // Construct providers eagerly so the timer can hold a direct callback
  // into the task provider — one-way coupling, no circular dependency.
  final taskProvider = TaskProvider(tasksBox: tasksBox);
  final timerProvider = TimerProvider(
    settingsBox: settingsBox,
    onFocusCompleted: taskProvider.decrementActive,
  );

  runApp(TreematoApp(
    timerProvider: timerProvider,
    taskProvider: taskProvider,
  ));
}

class TreematoApp extends StatelessWidget {
  final TimerProvider timerProvider;
  final TaskProvider taskProvider;

  const TreematoApp({
    super.key,
    required this.timerProvider,
    required this.taskProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TimerProvider>.value(value: timerProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
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
