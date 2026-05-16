import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../services/phase_timer_service.dart';

// Hive keys for the single 'settings' box. Keep stringly-typed constants
// here so a typo in one place can't silently miss the persisted value.
const _kPomodoroMinutes = 'pomodoroMinutes';
const _kShortBreakMinutes = 'shortBreakMinutes';
const _kLongBreakMinutes = 'longBreakMinutes';
const _kPomodorosPerCycle = 'pomodorosPerCycle';
const _kShortBreaksOn = 'shortBreaksOn';
const _kStrictMode = 'strictMode';
const _kChimeSounds = 'chimeSounds';
const _kDailyTargetPomodoros = 'dailyTargetPomodoros';
const _kHasSeenFreezeHintPulse = 'hasSeenFreezeHintPulse';

/// Kind of a single phase in the cycle. The sequence the provider walks
/// through is a list of these — the same kind may appear multiple times
/// (e.g. multiple focus blocks per cycle).
enum TimerPhase { focus, shortBreak, longBreak }

/// Whether the timer is counting down, paused, or idle (reset / not started).
enum TimerStatus { idle, running, paused }

/// Persistent timer state machine.
///
/// Manages a dynamic Pomodoro cycle (N focus blocks, optionally interleaved
/// with short breaks, capped by one long break) with start / pause / reset
/// and auto-advance when a phase completes. Durations, cycle shape and the
/// strict / chime flags are persisted to a Hive `settings` box so they
/// survive app restart.
class TimerProvider extends ChangeNotifier {
  /// Backing store for all user-configurable settings. All values are
  /// primitives (`int` / `bool`), so no `TypeAdapter` registration is
  /// needed. Construction reads any existing values; setters write back.
  final Box<dynamic> _box;

  /// Fired once every time a focus phase completes (either by natural
  /// countdown or by `skipPhase()`). Wired in `main.dart` to the task
  /// provider so the active task's remaining count drops by one.
  final VoidCallback? onFocusCompleted;

  /// Fired every time a focus phase ends — either by natural countdown
  /// ([skipped] = false) or via `skipPhase()` ([skipped] = true). Wired
  /// in `main.dart` to the session provider so both outcomes show up in
  /// history. Always fires *before* [onFocusCompleted] so the wiring
  /// can snapshot the active task before [TaskProvider.decrementActive]
  /// potentially clears it. Skipped firings pass placeholder time
  /// values; the History row hides them anyway.
  final void Function(
    DateTime startTime,
    DateTime endTime,
    int durationMinutes,
    bool skipped,
  )? onFocusSessionCompleted;

  TimerProvider({
    required Box<dynamic> settingsBox,
    this.onFocusCompleted,
    this.onFocusSessionCompleted,
  }) : _box = settingsBox {
    _pomodoroMinutes = (_box.get(_kPomodoroMinutes) as int?) ?? 25;
    _shortBreakMinutes = (_box.get(_kShortBreakMinutes) as int?) ?? 5;
    _longBreakMinutes = (_box.get(_kLongBreakMinutes) as int?) ?? 15;
    _pomodorosPerCycle = (_box.get(_kPomodorosPerCycle) as int?) ?? 3;
    _shortBreaksOn = (_box.get(_kShortBreaksOn) as bool?) ?? true;
    _strictMode = (_box.get(_kStrictMode) as bool?) ?? true;
    _chimeSounds = (_box.get(_kChimeSounds) as bool?) ?? true;
    _dailyTargetPomodoros = (_box.get(_kDailyTargetPomodoros) as int?) ?? 8;
    _hasSeenFreezeHintPulse =
        (_box.get(_kHasSeenFreezeHintPulse) as bool?) ?? false;
    // Rebuild sequence + remaining seconds from the restored config so
    // the very first frame already reflects the persisted state.
    _sequence = _buildSequence();
    _secondsRemaining = _durationForPhase(_sequence[_phaseIndex]);
  }

  // ── Configurable durations (minutes) ─────────────────────────────────
  // Stored in minutes since that is the unit the UI exposes; converted
  // to seconds on read. Bounds match the clamps in the public setters.
  int _pomodoroMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  // ── Cycle shape ──────────────────────────────────────────────────────
  // The cycle is built fresh from these two knobs whenever they change
  // while idle (mid-session changes wait for the next phase boundary).
  int _pomodorosPerCycle = 3;
  bool _shortBreaksOn = true;

  // ── Workflow flags ───────────────────────────────────────────────────
  bool _strictMode = true;
  bool _chimeSounds = true;


  int _dailyTargetPomodoros = 8;

  // One-time first-run flag: the freeze-hint pulses on the user's first
  bool _hasSeenFreezeHintPulse = false;

  // ── State ────────────────────────────────────────────────────────────
  List<TimerPhase> _sequence = const [TimerPhase.focus];
  int _phaseIndex = 0;
  TimerStatus _status = TimerStatus.idle;
  int _secondsRemaining = 0;

  Timer? _ticker;
  bool _celebrating = false;
  // Flips true on the tick a short/long break phase ends, mirroring
  // [_celebrating] for focus completions. Consumed by the UI layer to
  // drive the onBreakOver SFX. Cleared on the next start/reset.
  bool _onBreakOver = false;

  // Wall-clock timestamp captured the first time the user starts a focus
  // phase. Survives pauses (so the recorded session reflects the real
  // span from kick-off to finish). Cleared on every phase boundary and
  // on either reset path so an aborted focus phase produces no record.
  DateTime? _focusPhaseStartedAt;

  // Set when the user reshapes the cycle (pomodorosPerCycle or
  // shortBreaksOn) while a phase is mid-flight. Consumed inside
  // _advancePhase so the current countdown is never interrupted — the
  // new shape only takes effect at the natural phase boundary.
  bool _pendingSequenceRebuild = false;

  // ── Getters ──────────────────────────────────────────────────────────
  TimerPhase get phase => _sequence[_phaseIndex];
  int get phaseIndex => _phaseIndex;
  int get sequenceLength => _sequence.length;

  /// Kind of the i-th phase in the current cycle sequence. Lets the UI
  /// render a labelled pill row without depending on `_buildSequence`'s
  /// generation logic.
  TimerPhase phaseAt(int i) => _sequence[i];
  TimerStatus get status => _status;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _status == TimerStatus.running;
  bool get isPaused => _status == TimerStatus.paused;
  bool get isIdle => _status == TimerStatus.idle;
  bool get isCelebrating => _celebrating;
  bool get isOnBreakOver => _onBreakOver;

  int get pomodoroMinutes => _pomodoroMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get pomodorosPerCycle => _pomodorosPerCycle;
  bool get shortBreaksOn => _shortBreaksOn;
  bool get strictModeOn => _strictMode;
  bool get chimeSoundsOn => _chimeSounds;
  int get dailyTargetPomodoros => _dailyTargetPomodoros;
  bool get hasSeenFreezeHintPulse => _hasSeenFreezeHintPulse;

  /// How far through the current phase we are, 0.0 → 1.0.
  double get progress {
    final total = _durationForPhase(phase);
    if (total == 0) return 0;
    return 1.0 - (_secondsRemaining / total);
  }

  /// Whether the current phase is a focus (Pomodoro) phase.
  bool get isFocusPhase => phase == TimerPhase.focus;

  /// Human-readable label for the current phase.
  String get phaseLabel {
    switch (phase) {
      case TimerPhase.focus:
        return 'Focus';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  /// Which Pomodoro number we're on within the current cycle.
  /// For a focus phase: 1-based ordinal of this focus block in the sequence.
  /// For a break phase: the count of focus blocks that came before it.
  int get pomodoroNumber {
    var count = 0;
    for (var i = 0; i <= _phaseIndex && i < _sequence.length; i++) {
      if (_sequence[i] == TimerPhase.focus) count++;
    }
    return count;
  }

  /// Number of completed Pomodoro phases in the current cycle.
  /// Counts focus phases strictly *before* the current index.
  int get completedPomodoros {
    var count = 0;
    for (var i = 0; i < _phaseIndex && i < _sequence.length; i++) {
      if (_sequence[i] == TimerPhase.focus) count++;
    }
    return count;
  }

  /// Formatted "MM:SS" string for the current remaining time.
  String get formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Start or resume the countdown.
  void startTimer() {
    if (_status == TimerStatus.running) return;
    _celebrating = false;
    _onBreakOver = false;
    // Stamp the focus session's start at the *first* run of this phase.
    // Resumes after a pause keep the original stamp so the recorded
    // session reflects the real wall-clock span.
    if (phase == TimerPhase.focus && _focusPhaseStartedAt == null) {
      _focusPhaseStartedAt = DateTime.now();
    }
    _status = TimerStatus.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Spin up the foreground service so the timer survives screen-off.
    // Fire-and-forget — the in-app ticker above is the foreground
    // source of truth; the service only matters when the OS suspends us.
    unawaited(PhaseTimerService.start(
      phaseLabel: phaseLabel,
      totalSeconds: _secondsRemaining,
      currentPhase: phase.name,
      isLastFocusOfCycle: _isNextLongBreak(),
      chimeSoundsOn: _chimeSounds,
    ));
    notifyListeners();
  }

  /// True when the current phase is a focus block and the very next
  /// phase in the sequence is the long break — i.e. completing the
  /// current phase will end the cycle. Mirrors the post-advance check
  /// `t.phase == TimerPhase.longBreak` used by the in-app SFX widget,
  /// but evaluated *before* advance so the service can decide variant
  /// without a `TimerProvider` instance.
  ///
  /// Same caveat as `_PhaseCompletionSfx`: a `_pendingSequenceRebuild`
  /// queued mid-flight will shift the post-advance phase, so this
  /// lookahead can mis-predict. Acceptable — the user has the same
  /// behaviour in the foreground path today.
  bool _isNextLongBreak() {
    if (phase != TimerPhase.focus) return false;
    final next = (_phaseIndex + 1) % _sequence.length;
    return _sequence[next] == TimerPhase.longBreak;
  }

  /// Reconcile the in-app countdown against the service's wall-clock
  /// end timestamp. Call this whenever the app returns to the
  /// foreground (see `_ForegroundLifecycleSync` in `main.dart`).
  ///
  /// Why this exists: while the app is backgrounded with the screen
  /// off, Android suspends the UI isolate, which freezes
  /// [Timer.periodic]. When the user reopens the app, the ticker
  /// resumes from wherever [_secondsRemaining] was at suspension —
  /// not where the wall-clock actually is. Without this reconcile,
  /// the timer display would lag by minutes and would *replay* the
  /// chime when it eventually catches up to zero (even though the
  /// service already played it through the speaker while the user
  /// was away).
  ///
  /// Behaviour:
  ///   - Not running → no-op (paused / idle phases don't have a
  ///     stamped wall-clock end, so there's nothing to reconcile
  ///     against).
  ///   - Wall-clock end already passed → snap forward to the next
  ///     phase via [_advancePhase] with `replayCelebration: false`
  ///     so the chime / mascot don't fire (service handled both).
  ///   - Wall-clock end still in the future → update
  ///     [_secondsRemaining] to the true remaining count.
  Future<void> reconcileFromWallClock() async {
    if (_status != TimerStatus.running) return;
    final endMs = await PhaseTimerService.readPhaseEndsAtMs();
    if (endMs == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs >= endMs) {
      // Phase ended while we were suspended. The service already
      // chimed at the wall-clock boundary, so suppress celebration
      // flags but still record the session at its true end time.
      final realEnd = DateTime.fromMillisecondsSinceEpoch(endMs);
      _advancePhase(
        natural: true,
        replayCelebration: false,
        overrideEndTime: realEnd,
      );
    } else {
      final remaining = ((endMs - nowMs) / 1000).ceil();
      if (remaining != _secondsRemaining) {
        _secondsRemaining = remaining;
        notifyListeners();
      }
    }
  }

  /// Pause the countdown, keeping the current remaining time.
  void pauseTimer() {
    if (_status != TimerStatus.running) return;
    _ticker?.cancel();
    _status = TimerStatus.paused;
    unawaited(PhaseTimerService.stop());
    notifyListeners();
  }

  /// Reset the current phase back to its full duration.
  /// Does NOT change the phase — stays in the current one.
  void resetTimer() {
    _ticker?.cancel();
    _celebrating = false;
    _onBreakOver = false;
    _status = TimerStatus.idle;
    _secondsRemaining = _durationForPhase(phase);
    _focusPhaseStartedAt = null;
    unawaited(PhaseTimerService.stop());
    notifyListeners();
  }

  /// Reset the entire cycle back to the first phase, idle.
  void resetCycle() {
    _ticker?.cancel();
    _celebrating = false;
    _onBreakOver = false;
    _phaseIndex = 0;
    _status = TimerStatus.idle;
    _secondsRemaining = _durationForPhase(phase);
    _focusPhaseStartedAt = null;
    unawaited(PhaseTimerService.stop());
    notifyListeners();
  }

  /// Manually skip to the next phase (useful for testing / skipping breaks).
  /// Skips do NOT log a session record — only natural completions do.
  void skipPhase() {
    _celebrating = false;
    _onBreakOver = false;
    _advancePhase(natural: false);
  }

  // ── Settings mutators ────────────────────────────────────────────────
  // Duration changes never disturb a phase that's already counting down
  // (running OR paused — that countdown represents real elapsed focus
  // and must not jump). But while the timer is idle the displayed
  // remaining time still equals the phase's full duration, so we can
  // safely re-snap it to the new value — gives the user a live preview
  // in the timer display before they hit START.

  void setPomodoroMinutes(int v) {
    final clamped = v.clamp(5, 90);
    if (clamped == _pomodoroMinutes) return;
    _pomodoroMinutes = clamped;
    _box.put(_kPomodoroMinutes, clamped);
    _syncIdleRemaining();
    notifyListeners();
  }

  void setShortBreakMinutes(int v) {
    final clamped = v.clamp(1, 30);
    if (clamped == _shortBreakMinutes) return;
    _shortBreakMinutes = clamped;
    _box.put(_kShortBreakMinutes, clamped);
    _syncIdleRemaining();
    notifyListeners();
  }

  void setLongBreakMinutes(int v) {
    final clamped = v.clamp(5, 60);
    if (clamped == _longBreakMinutes) return;
    _longBreakMinutes = clamped;
    _box.put(_kLongBreakMinutes, clamped);
    _syncIdleRemaining();
    notifyListeners();
  }

  /// Reshape the cycle to use [v] focus blocks per cycle (clamped 2..6).
  /// Idle  → applied immediately, cycle restarts at index 0.
  /// Running / paused → deferred until the current phase ends so the
  /// active countdown is preserved (mirrors duration-setter discipline).
  void setPomodorosPerCycle(int v) {
    final clamped = v.clamp(2, 6);
    if (clamped == _pomodorosPerCycle) return;
    _pomodorosPerCycle = clamped;
    _box.put(_kPomodorosPerCycle, clamped);
    _applyShapeChange();
    notifyListeners();
  }

  /// Toggle whether short breaks sit between focus blocks. Same
  /// idle-vs-mid-flight rules as [setPomodorosPerCycle].
  void setShortBreaksOn(bool v) {
    if (v == _shortBreaksOn) return;
    _shortBreaksOn = v;
    _box.put(_kShortBreaksOn, v);
    _applyShapeChange();
    notifyListeners();
  }

  /// Either rebuild the sequence now (idle) or queue a rebuild for the
  /// next phase boundary (running / paused). On rebuild the cycle
  /// restarts at index 0 — predictable behaviour, avoids translating
  /// mid-cycle progress between two differently-shaped sequences.
  void _applyShapeChange() {
    if (_status == TimerStatus.idle) {
      _sequence = _buildSequence();
      _phaseIndex = 0;
      _pendingSequenceRebuild = false;
      _secondsRemaining = _durationForPhase(_sequence[_phaseIndex]);
    } else {
      _pendingSequenceRebuild = true;
    }
  }

  /// While idle, the displayed remaining time always equals the current
  /// phase's full duration (set at construction, on resetTimer, on
  /// resetCycle, and on _advancePhase). Re-snap it whenever a duration
  /// setting changes so the timer display reflects the new value live.
  /// No-op if the change is for a different kind of phase than we're
  /// currently sitting on.
  void _syncIdleRemaining() {
    if (_status != TimerStatus.idle) return;
    _secondsRemaining = _durationForPhase(phase);
  }

  /// Daily target pomodoro count shown on the Stats target card. Clamped
  /// 1..20 — zero would mean "the target is always met" which defeats the
  /// purpose, and 20 is a generous ceiling (8h+ of focus).
  void setDailyTargetPomodoros(int v) {
    final clamped = v.clamp(1, 20);
    if (clamped == _dailyTargetPomodoros) return;
    _dailyTargetPomodoros = clamped;
    _box.put(_kDailyTargetPomodoros, clamped);
    notifyListeners();
  }

  void toggleStrictMode() {
    _strictMode = !_strictMode;
    _box.put(_kStrictMode, _strictMode);
    notifyListeners();
  }

  void toggleChimeSounds() {
    _chimeSounds = !_chimeSounds;
    _box.put(_kChimeSounds, _chimeSounds);
    notifyListeners();
  }

  /// Mark the one-time freeze-hint pulse as shown.
  void markFreezeHintPulseSeen() {
    if (_hasSeenFreezeHintPulse) return;
    _hasSeenFreezeHintPulse = true;
    _box.put(_kHasSeenFreezeHintPulse, true);
    notifyListeners();
  }

  // ── Internal ─────────────────────────────────────────────────────────

  /// Build the phase sequence for one cycle from the current shape knobs.
  /// On  → [focus, shortBreak, focus, shortBreak, …, focus, longBreak]
  /// Off → [focus, focus, …, focus, longBreak]
  List<TimerPhase> _buildSequence() {
    final out = <TimerPhase>[];
    for (var i = 0; i < _pomodorosPerCycle; i++) {
      out.add(TimerPhase.focus);
      final isLastFocus = i == _pomodorosPerCycle - 1;
      if (!isLastFocus && _shortBreaksOn) {
        out.add(TimerPhase.shortBreak);
      }
    }
    out.add(TimerPhase.longBreak);
    return out;
  }

  void _tick() {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
    } else {
      // Phase finished — advance.
      _advancePhase();
    }
  }

  /// [natural] — true when the phase ended by countdown; false when
  ///   the user skipped. Drives session-record placeholders.
  /// [replayCelebration] — set false ONLY when reconciling on app
  ///   resume (see [reconcileFromWallClock]). The service already
  ///   chimed and the mascot would be celebrating something the user
  ///   has long since missed, so we suppress those edge-flag flips.
  ///   Session recording and task-decrement still fire — the work
  ///   genuinely happened, just unattended.
  /// [overrideEndTime] — when reconciling, the user re-opens the app
  ///   minutes after the wall-clock phase end. Using `DateTime.now()`
  ///   as the session end would falsify the History row, so the
  ///   caller passes the real end timestamp here.
  void _advancePhase({
    bool natural = true,
    bool replayCelebration = true,
    DateTime? overrideEndTime,
  }) {
    _ticker?.cancel();
    // The service was spun up by [startTimer] for the just-finished
    // phase. Tear it down here — the next phase auto-pauses to idle
    // (see status assignment below), so there is no reason to keep
    // the foreground notification alive between phases.
    unawaited(PhaseTimerService.stop());
    final completedPhase = _sequence[_phaseIndex];
    // Snapshot before clearing — the session-completed callback fires
    // below and needs the stamp captured at first-start of this phase.
    final startedAt = _focusPhaseStartedAt;
    _focusPhaseStartedAt = null;

    if (_pendingSequenceRebuild) {
      // Shape edit landed while the timer was running/paused — current
      // phase has now finished its real-time slot, so safe to swap in
      // the new sequence and start a fresh cycle.
      _sequence = _buildSequence();
      _phaseIndex = 0;
      _pendingSequenceRebuild = false;
    } else {
      _phaseIndex = (_phaseIndex + 1) % _sequence.length;
    }
    _secondsRemaining = _durationForPhase(_sequence[_phaseIndex]);
    // Pause between phases so the user explicitly starts the next one.
    _status = TimerStatus.idle;

    // Edge flag for the onBreakOver SFX listener. Cleared on next
    // start/reset like _celebrating.
    if (replayCelebration &&
        (completedPhase == TimerPhase.shortBreak ||
            completedPhase == TimerPhase.longBreak)) {
      _onBreakOver = true;
    }

    // Celebrate for ~3 seconds after completing a focus phase.
    if (completedPhase == TimerPhase.focus) {
      if (replayCelebration) _celebrating = true;
      // Session record FIRST so the wiring in main.dart can read the
      // active task before onFocusCompleted potentially clears it.
      // Natural completion → real start stamp, configured duration.
      // Skip → placeholder stamps (the History row ignores them).
      final now = overrideEndTime ?? DateTime.now();
      onFocusSessionCompleted?.call(
        startedAt ?? now,
        now,
        natural ? _pomodoroMinutes : 0,
        !natural,
      );
      onFocusCompleted?.call();
    }

    notifyListeners();
  }

  int _durationForPhase(TimerPhase p) {
    switch (p) {
      case TimerPhase.focus:
        return _pomodoroMinutes * 60;
      case TimerPhase.shortBreak:
        return _shortBreakMinutes * 60;
      case TimerPhase.longBreak:
        return _longBreakMinutes * 60;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(PhaseTimerService.stop());
    super.dispose();
  }
}
