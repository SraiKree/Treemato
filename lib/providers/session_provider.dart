import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/session_record.dart';

/// Hive-backed log of completed sessions. Currently records pomodoro
/// (focus) completions only — breaks are not persisted, mirroring the
/// "history shows pomodoro slots only" product rule.
///
/// Holds an in-memory list mirroring the box so reads stay synchronous;
/// writes are mirrored to disk on every change.
class SessionProvider extends ChangeNotifier {
  final Box<SessionRecord> _box;
  final List<SessionRecord> _records = [];

  SessionProvider({required Box<SessionRecord> sessionsBox}) : _box = sessionsBox {
    _records.addAll(_box.values);
  }

  /// Unmodifiable view — callers should never mutate the list directly.
  List<SessionRecord> get records => List.unmodifiable(_records);

  /// Pomodoros only, newest first. Convenience for the History screen.
  List<SessionRecord> get pomodorosNewestFirst {
    final list = _records.where((r) => r.isPomodoro).toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  /// Log a pomodoro slot. Called by the wiring in `main.dart` whenever a
  /// focus phase ends — either naturally ([skipped] = false) or by the
  /// user pressing skip ([skipped] = true). Skipped rows ignore the
  /// time fields at render time, so callers may pass placeholders for
  /// them when no real session data exists.
  void addPomodoro({
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    String? taskId,
    String? taskName,
    bool skipped = false,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final rec = SessionRecord(
      id: id,
      taskId: taskId,
      taskName: taskName,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      isPomodoro: true,
      skipped: skipped,
    );
    _records.add(rec);
    _box.put(id, rec);
    notifyListeners();
  }
}
