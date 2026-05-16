import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/session_record.dart';
import 'providers/session_provider.dart';
import 'providers/task_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/main_shell.dart';
import 'services/phase_audio_task_handler.dart' show kAppForegrounded;
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open a SendPort the foreground service's isolate can use to ping
  // the UI isolate. Required before runApp() in flutter_foreground_task
  // 8.x; cheap, no plugin work happens here yet.
  FlutterForegroundTask.initCommunicationPort();
  // Offline-only: never let google_fonts attempt a runtime HTTP fetch.
  // All used families are bundled under assets/google_fonts/.
  GoogleFonts.config.allowRuntimeFetching = false;
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
        // WithForegroundTask re-attaches the running service to the
        // Activity if Android recreates it (e.g. rotation, config
        // change). Wrapping the root once is enough.
        //
        // _ForegroundLifecycleSync mirrors AppLifecycleState into the
        // plugin's cross-isolate storage so the service can tell whether
        // the UI is active. Used by PhaseAudioTaskHandler to skip the
        // chime when the UI's own SFX widget will play it.
        home: const WithForegroundTask(
          child: _ForegroundLifecycleSync(child: MainShell()),
        ),
      ),
    );
  }
}

/// Writes the current `AppLifecycleState` into the foreground-task
/// plugin's shared storage as a bool under [kAppForegrounded]. The
/// service handler reads this on every chime decision to avoid
/// double-firing while the app is visible.
///
/// Why a separate widget instead of doing this in `main()`:
/// `WidgetsBindingObserver` callbacks only fire once a widget is
/// mounted in the tree, and we want the very first state write to
/// happen as early as possible *after* the MaterialApp is built — so
/// the foreground service, if it spins up immediately on first
/// `startTimer`, already sees `appForegrounded = true`.
class _ForegroundLifecycleSync extends StatefulWidget {
  const _ForegroundLifecycleSync({required this.child});

  final Widget child;

  @override
  State<_ForegroundLifecycleSync> createState() =>
      _ForegroundLifecycleSyncState();
}

class _ForegroundLifecycleSyncState extends State<_ForegroundLifecycleSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First frame == app is foregrounded by definition.
    _writeForegrounded(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `resumed` is the only state where the UI isolate is reliably
    // ticking and can play the chime. `inactive` (transient, e.g.
    // pulling down the notification shade), `paused` (backgrounded),
    // `hidden`, and `detached` all hand authority to the service.
    final fg = state == AppLifecycleState.resumed;
    _writeForegrounded(fg);
    if (fg) {
      // Coming back from background: the UI ticker has been frozen
      // (probably stale by minutes if the screen was off). Ask the
      // provider to compare its remaining-seconds against the
      // service's wall-clock end and either snap forward to the next
      // phase or correct the displayed countdown. Without this, the
      // ticker would catch up tick-by-tick and would replay the
      // chime when it eventually hits zero — the very double-fire we
      // suppress in PhaseAudioTaskHandler is also possible from the
      // other direction.
      //
      // `context.mounted` guard: `didChangeAppLifecycleState` can fire
      // during teardown, and reading off an unmounted context throws.
      if (!mounted) return;
      unawaited(context.read<TimerProvider>().reconcileFromWallClock());
    }
  }

  void _writeForegrounded(bool value) {
    // Fire-and-forget — saveData is a single MethodChannel call and
    // an out-of-order write between two lifecycle transitions only
    // matters at the chime moment, which is minutes away from any
    // realistic lifecycle change.
    unawaited(
      FlutterForegroundTask.saveData(key: kAppForegrounded, value: value),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
