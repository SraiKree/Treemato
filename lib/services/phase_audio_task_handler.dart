import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Shared key constants. Both isolates read/write the same keys so a
// typo here is one fix instead of two. The values are plugin-storage
// primitives only — int / bool / string. No DateTime or enum, since
// FlutterForegroundTask.saveData only supports JSON-shaped scalars.
const String kPhaseEndsAtMs = 'phaseEndsAt';
const String kCurrentPhase = 'currentPhase';
const String kIsLastFocusOfCycle = 'isLastFocusOfCycle';
const String kChimeSoundsOn = 'chimeSoundsOn';
// Foreground/background dedup flag. Written by the UI isolate every
// time `AppLifecycleState` changes; read by the service at chime time.
// When true, the in-app `_PhaseCompletionSfx` widget is the canonical
// chime source and the service stays silent (otherwise we get a
// double-trigger). When false, the UI isolate is suspended (screen
// off / app backgrounded) and the service is the only one that can
// still play audio, so the service fires.
const String kAppForegrounded = 'appForegrounded';

// String tokens for [kCurrentPhase]. Mirrors TimerPhase.name from the
// UI isolate. Kept here so the handler does not need to import the
// provider (and pull a chunk of UI dependency into the service).
const String kPhaseFocus = 'focus';
const String kPhaseShortBreak = 'shortBreak';
const String kPhaseLongBreak = 'longBreak';

// Entry point for the foreground service's Dart isolate.
//
// `flutter_foreground_task` boots a *separate* isolate when the service
// starts. That isolate has no shared memory with the UI isolate — it
// re-imports app code from scratch. The plugin uses this top-level
// function (which MUST be annotated with `@pragma('vm:entry-point')` so
// the Dart tree-shaker does not drop it from the release build) to bind
// our `TaskHandler` inside that fresh isolate.
@pragma('vm:entry-point')
void phaseTaskCallback() {
  // The service runs in a brand-new Dart isolate with its own
  // FlutterEngine — plugin registrations from the UI isolate do not
  // carry over. Without this line, calling into any plugin
  // (audioplayers, the foreground-task plugin's own getData/saveData,
  // path_provider, etc.) throws MissingPluginException because the
  // isolate has no method channels wired up. Cheap and idempotent
  // — safe to call here.
  DartPluginRegistrant.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(PhaseAudioTaskHandler());
}

/// Service-side timer handler.
///
/// Step 3 scope: primes the three chime players, watches the
/// wall-clock against [kPhaseEndsAtMs] on each tick, plays the
/// correct variant on hit-zero, then stops the service. No
/// foreground-vs-background dedup yet — that lands in step 4, so
/// expect a double-chime if you happen to be testing with the app
/// foregrounded right now.
class PhaseAudioTaskHandler extends TaskHandler {
  AudioPlayer? _regularPlayer;
  AudioPlayer? _finalPlayer;
  AudioPlayer? _breakOverPlayer;

  // Edge-trigger guard: hit-zero is checked every tick, but the
  // chime + stopService sequence only fires once per service lifetime.
  bool _chimeFired = false;
  // Reentrancy guard for the async tick handler. onRepeatEvent fires
  // every second; if the chime check (which awaits Hive-ish reads)
  // overlaps with the next tick, we skip the new one rather than
  // racing.
  bool _checking = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _chimeFired = false;
    _regularPlayer = await _prime('audio/pomo_complete.mp3');
    _finalPlayer = await _prime('audio/onFinalPomoComplete.mp3');
    _breakOverPlayer = await _prime('audio/onBreakOver.mp3');
  }

  Future<AudioPlayer?> _prime(String asset) async {
    final p = AudioPlayer();
    try {
      // mediaPlayer mode (default for AudioPlayer): no size cap, plays
      // the full clip even past ~6 s. Matches the UI-side primer in
      // _PhaseCompletionSfx so both code paths sound identical.
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.mediaPlayer);
      await p.setSource(AssetSource(asset));
      return p;
    } catch (_) {
      await p.dispose();
      return null;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Fire-and-forget; the body is internally guarded.
    unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_chimeFired) return;
    if (_checking) return;
    _checking = true;
    try {
      final endMs = await FlutterForegroundTask.getData<int>(key: kPhaseEndsAtMs);
      if (endMs == null) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs < endMs) {
        // Still counting down — refresh the notification text so the
        // lockscreen shows the right MM:SS even after the UI ticker
        // has been suspended.
        final remainingSec = ((endMs - nowMs) / 1000).ceil();
        final mm = (remainingSec ~/ 60).toString().padLeft(2, '0');
        final ss = (remainingSec % 60).toString().padLeft(2, '0');
        await FlutterForegroundTask.updateService(
          notificationText: '$mm:$ss',
        );
        return;
      }
      // Hit zero. Latch the edge guard *before* the async chime
      // sequence so a stray tick can't double-fire.
      _chimeFired = true;
      await _fireChime();
      // Self-terminate: the next phase auto-pauses to idle in the UI
      // (see TimerProvider._advancePhase), so there is no reason to
      // keep the service banner around between phases.
      await FlutterForegroundTask.stopService();
    } finally {
      _checking = false;
    }
  }

  Future<void> _fireChime() async {
    // Foreground dedup. When the app is visible, the UI-side
    // `_PhaseCompletionSfx` widget is responsible for playing the
    // chime — bailing here prevents a double-trigger. The service
    // still self-terminates after this call (see _tick) so the
    // notification banner clears either way.
    //
    // Default `false` is deliberate: if the flag is somehow missing
    // (e.g. service started before the lifecycle widget mounted, or
    // the UI isolate was killed by the OS), we'd rather over-play
    // than miss the chime entirely.
    final foregrounded =
        await FlutterForegroundTask.getData<bool>(key: kAppForegrounded) ??
            false;
    if (foregrounded) return;
    final chimeOn =
        await FlutterForegroundTask.getData<bool>(key: kChimeSoundsOn) ?? true;
    if (!chimeOn) return;
    final phase = await FlutterForegroundTask.getData<String>(key: kCurrentPhase);
    final isLast =
        await FlutterForegroundTask.getData<bool>(key: kIsLastFocusOfCycle) ??
            false;
    final AudioPlayer? player;
    if (phase == kPhaseFocus) {
      player = isLast ? _finalPlayer : _regularPlayer;
    } else {
      // Both short and long break completions share the same chime,
      // mirroring the UI-side _PhaseCompletionSfx contract.
      player = _breakOverPlayer;
    }
    if (player == null) return;
    await player.stop();
    await player.resume();
    // Wait for the clip to finish before letting the caller stop the
    // service — otherwise stopService would tear down the audio engine
    // mid-playback. Final-pomo clip is the longest (~25 s); 35 s ceiling
    // is comfortable.
    final completer = Completer<void>();
    late StreamSubscription<void> sub;
    sub = player.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) completer.complete();
      sub.cancel();
    });
    await completer.future.timeout(
      const Duration(seconds: 35),
      onTimeout: () {
        sub.cancel();
      },
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _regularPlayer?.dispose();
    await _finalPlayer?.dispose();
    await _breakOverPlayer?.dispose();
    _regularPlayer = null;
    _finalPlayer = null;
    _breakOverPlayer = null;
  }
}
