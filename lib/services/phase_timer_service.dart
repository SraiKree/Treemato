import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'phase_audio_task_handler.dart'
    show
        phaseTaskCallback,
        kPhaseEndsAtMs,
        kCurrentPhase,
        kIsLastFocusOfCycle,
        kChimeSoundsOn;

/// Thin wrapper around `flutter_foreground_task` so the rest of the app
/// never imports the plugin directly. The provider just calls
/// [start] / [stop] and does not need to know about notification
/// channels, callbacks, or service IDs.
///
/// Step 2 scope: bare start/stop only. The data payload (phaseEndsAt
/// etc.) and audio-related configuration arrive in step 3.
class PhaseTimerService {
  PhaseTimerService._();

  static const String _channelId = 'phase_timer';
  static const String _channelName = 'Pomodoro Timer';
  static const int _serviceId = 1001;

  // Idempotency guard. The plugin's [init] is safe to call multiple
  // times but [startService] is not — calling it while the service is
  // already running returns an error. We track our own intent here.
  static bool _initialized = false;
  static bool _running = false;

  /// Configure the notification channel + tick cadence. Cheap, called
  /// once on first [start]. Splitting it out (instead of doing it in
  /// `main.dart`) keeps the plugin contained to this file.
  static void _init() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: 'Keeps the active pomodoro phase alive so '
            'the end-of-phase chime plays when the screen is off.',
        // LOW importance → no sound, no vibration, no heads-up popup
        // from the OS. The chime is played by our own AudioPlayer.
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Wake the handler once per second. Matches the UI ticker so
        // the wall-clock comparison stays simple.
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        // Holds a partial wake lock while the service is running so
        // the CPU keeps scheduling the Dart isolate. Without this,
        // Doze/idle modes can still suspend the timer.
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// On Android 13+ POST_NOTIFICATIONS is a runtime permission. The
  /// foreground service will fail to start if it's denied. Safe to
  /// call repeatedly — only prompts the user if not yet granted.
  static Future<bool> _ensureNotificationPermission() async {
    final current = await FlutterForegroundTask.checkNotificationPermission();
    if (current == NotificationPermission.granted) return true;
    final asked = await FlutterForegroundTask.requestNotificationPermission();
    return asked == NotificationPermission.granted;
  }

  /// Spin up the foreground service for the duration of one phase.
  /// Fire-and-forget — callers do not need to await the returned future
  /// because the UI's own [Timer.periodic] is the source of truth while
  /// the app is in the foreground.
  ///
  /// [phaseLabel] is shown as the notification title. [totalSeconds] is
  /// the remaining seconds of the phase at the moment of start (matches
  /// the UI's `_secondsRemaining`); it is converted to an absolute
  /// wall-clock end timestamp and stashed in the plugin's cross-isolate
  /// storage so the handler can detect hit-zero independently. The
  /// other three params drive variant selection inside the handler.
  static Future<void> start({
    required String phaseLabel,
    required int totalSeconds,
    required String currentPhase,
    required bool isLastFocusOfCycle,
    required bool chimeSoundsOn,
  }) async {
    _init();
    final ok = await _ensureNotificationPermission();
    if (!ok) {
      // Permission denied — the chime simply will not play with screen
      // off. We do not block the timer from starting; the in-app SFX
      // path still works while the app is foregrounded.
      return;
    }
    // Stash the phase data BEFORE starting the service so the
    // handler's first onRepeatEvent already sees the right values.
    final endMs = DateTime.now()
        .add(Duration(seconds: totalSeconds))
        .millisecondsSinceEpoch;
    await FlutterForegroundTask.saveData(key: kPhaseEndsAtMs, value: endMs);
    await FlutterForegroundTask.saveData(key: kCurrentPhase, value: currentPhase);
    await FlutterForegroundTask.saveData(
      key: kIsLastFocusOfCycle,
      value: isLastFocusOfCycle,
    );
    await FlutterForegroundTask.saveData(
      key: kChimeSoundsOn,
      value: chimeSoundsOn,
    );

    if (_running) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Treemato — $phaseLabel',
        notificationText: '',
      );
      return;
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'Treemato — $phaseLabel',
      notificationText: '',
      callback: phaseTaskCallback,
    );
    _running = result is ServiceRequestSuccess;
  }

  /// Tear down the service. Safe to call when no service is running.
  static Future<void> stop() async {
    if (!_running) return;
    await FlutterForegroundTask.stopService();
    _running = false;
  }

  /// Read the wall-clock end timestamp (ms since epoch) the service is
  /// currently counting down to, or `null` if none has been stamped.
  ///
  /// Used by [TimerProvider.reconcileFromWallClock] on app-resume to
  /// detect whether the active phase ended while the UI isolate was
  /// suspended (screen off / app backgrounded). Returning the raw
  /// timestamp keeps the comparison logic in the provider — this
  /// wrapper exists purely so the plugin import stays contained here.
  static Future<int?> readPhaseEndsAtMs() {
    return FlutterForegroundTask.getData<int>(key: kPhaseEndsAtMs);
  }
}
