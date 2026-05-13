import 'dart:async';

import 'package:flutter/foundation.dart';

/// The six phases of a full Pomodoro cycle.
///
/// P1 → shortBreak → P2 → shortBreak → P3 → longBreak → (repeat)
enum TimerPhase {
  pomodoro1,
  shortBreak1,
  pomodoro2,
  shortBreak2,
  pomodoro3,
  longBreak,
}

/// Whether the timer is counting down, paused, or idle (reset / not started).
enum TimerStatus { idle, running, paused }

/// Pure in-memory timer state machine.
///
/// Manages the 6-phase Pomodoro cycle with start / pause / reset and
/// auto-advance when a phase completes.  Durations and the strict /
/// chime flags are runtime-mutable but in-memory only — they reset on
/// app restart until Hive persistence is wired in a follow-up step.
class TimerProvider extends ChangeNotifier {
  // ── Configurable durations (minutes) ─────────────────────────────────
  // Stored in minutes since that is the unit the UI exposes; converted
  // to seconds on read. Bounds match the clamps in the public setters.
  int _pomodoroMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  // ── Workflow flags ───────────────────────────────────────────────────
  bool _strictMode = true;
  bool _chimeSounds = false;

  // ── State ────────────────────────────────────────────────────────────
  TimerPhase _phase = TimerPhase.pomodoro1;
  TimerStatus _status = TimerStatus.idle;
  late int _secondsRemaining = _durationForPhase(_phase);

  Timer? _ticker;
  bool _celebrating = false;

  // ── Getters ──────────────────────────────────────────────────────────
  TimerPhase get phase => _phase;
  TimerStatus get status => _status;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _status == TimerStatus.running;
  bool get isPaused => _status == TimerStatus.paused;
  bool get isIdle => _status == TimerStatus.idle;
  bool get isCelebrating => _celebrating;

  int get pomodoroMinutes => _pomodoroMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  bool get strictModeOn => _strictMode;
  bool get chimeSoundsOn => _chimeSounds;

  /// How far through the current phase we are, 0.0 → 1.0.
  double get progress {
    final total = _durationForPhase(_phase);
    if (total == 0) return 0;
    return 1.0 - (_secondsRemaining / total);
  }

  /// Whether the current phase is a focus (Pomodoro) phase.
  bool get isFocusPhase =>
      _phase == TimerPhase.pomodoro1 ||
      _phase == TimerPhase.pomodoro2 ||
      _phase == TimerPhase.pomodoro3;

  /// Human-readable label for the current phase.
  String get phaseLabel {
    switch (_phase) {
      case TimerPhase.pomodoro1:
      case TimerPhase.pomodoro2:
      case TimerPhase.pomodoro3:
        return 'Focus';
      case TimerPhase.shortBreak1:
      case TimerPhase.shortBreak2:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  /// Which Pomodoro number we're on (1, 2, or 3).
  /// Returns 0 during break phases.
  int get pomodoroNumber {
    switch (_phase) {
      case TimerPhase.pomodoro1:
        return 1;
      case TimerPhase.shortBreak1:
        return 1; // just finished pomo 1
      case TimerPhase.pomodoro2:
        return 2;
      case TimerPhase.shortBreak2:
        return 2;
      case TimerPhase.pomodoro3:
        return 3;
      case TimerPhase.longBreak:
        return 3;
    }
  }

  /// Number of completed Pomodoro phases in the current cycle (0-3).
  int get completedPomodoros {
    switch (_phase) {
      case TimerPhase.pomodoro1:
        return 0;
      case TimerPhase.shortBreak1:
      case TimerPhase.pomodoro2:
        return 1;
      case TimerPhase.shortBreak2:
      case TimerPhase.pomodoro3:
        return 2;
      case TimerPhase.longBreak:
        return 3;
    }
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
    _status = TimerStatus.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  /// Pause the countdown, keeping the current remaining time.
  void pauseTimer() {
    if (_status != TimerStatus.running) return;
    _ticker?.cancel();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  /// Reset the current phase back to its full duration.
  /// Does NOT change the phase — stays in the current one.
  void resetTimer() {
    _ticker?.cancel();
    _celebrating = false;
    _status = TimerStatus.idle;
    _secondsRemaining = _durationForPhase(_phase);
    notifyListeners();
  }

  /// Reset the entire cycle back to Pomodoro 1, idle.
  void resetCycle() {
    _ticker?.cancel();
    _celebrating = false;
    _phase = TimerPhase.pomodoro1;
    _status = TimerStatus.idle;
    _secondsRemaining = _durationForPhase(_phase);
    notifyListeners();
  }

  /// Manually skip to the next phase (useful for testing / skipping breaks).
  void skipPhase() {
    _celebrating = false;
    _advancePhase();
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
    _syncIdleRemaining();
    notifyListeners();
  }

  void setShortBreakMinutes(int v) {
    final clamped = v.clamp(1, 30);
    if (clamped == _shortBreakMinutes) return;
    _shortBreakMinutes = clamped;
    _syncIdleRemaining();
    notifyListeners();
  }

  void setLongBreakMinutes(int v) {
    final clamped = v.clamp(5, 60);
    if (clamped == _longBreakMinutes) return;
    _longBreakMinutes = clamped;
    _syncIdleRemaining();
    notifyListeners();
  }

  /// While idle, the displayed remaining time always equals the current
  /// phase's full duration (set at construction, on resetTimer, on
  /// resetCycle, and on _advancePhase). Re-snap it whenever a duration
  /// setting changes so the timer display reflects the new value live.
  /// No-op if the change is for a different kind of phase than we're
  /// currently sitting on.
  void _syncIdleRemaining() {
    if (_status != TimerStatus.idle) return;
    _secondsRemaining = _durationForPhase(_phase);
  }

  void toggleStrictMode() {
    _strictMode = !_strictMode;
    notifyListeners();
  }

  void toggleChimeSounds() {
    _chimeSounds = !_chimeSounds;
    notifyListeners();
  }

  // ── Internal ─────────────────────────────────────────────────────────

  void _tick() {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
    } else {
      // Phase finished — advance.
      _advancePhase();
    }
  }

  void _advancePhase() {
    _ticker?.cancel();
    final completedPhase = _phase;
    final phases = TimerPhase.values;
    final nextIndex = (_phase.index + 1) % phases.length;
    _phase = phases[nextIndex];
    _secondsRemaining = _durationForPhase(_phase);
    // Pause between phases so the user explicitly starts the next one.
    _status = TimerStatus.idle;

    // Celebrate for 3 seconds after completing a focus phase.
    final wasFocus = completedPhase == TimerPhase.pomodoro1 ||
        completedPhase == TimerPhase.pomodoro2 ||
        completedPhase == TimerPhase.pomodoro3;
    if (wasFocus) {
      _celebrating = true;
    }

    notifyListeners();
  }

  int _durationForPhase(TimerPhase p) {
    switch (p) {
      case TimerPhase.pomodoro1:
      case TimerPhase.pomodoro2:
      case TimerPhase.pomodoro3:
        return _pomodoroMinutes * 60;
      case TimerPhase.shortBreak1:
      case TimerPhase.shortBreak2:
        return _shortBreakMinutes * 60;
      case TimerPhase.longBreak:
        return _longBreakMinutes * 60;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
