import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// One row in the daily task list. Persisted as a primitive `Map` in the
/// `'tasks'` Hive box — no `TypeAdapter` needed.
@immutable
class Task {
  final String id;
  final String name;

  /// Pomodoros remaining for this task. 0 == done. Counts down by 1 each
  /// time a focus phase completes while the task is active.
  final int remaining;

  /// At most one task is active at a time. Active task's name surfaces in
  /// the timer's "Now Tree-mah-doing" label.
  final bool active;

  /// Insertion order tiebreaker. Stored as ms since epoch.
  final int createdAt;

  const Task({
    required this.id,
    required this.name,
    required this.remaining,
    required this.active,
    required this.createdAt,
  });

  bool get done => remaining == 0;

  Task copyWith({String? name, int? remaining, bool? active}) => Task(
        id: id,
        name: name ?? this.name,
        remaining: remaining ?? this.remaining,
        active: active ?? this.active,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'remaining': remaining,
        'active': active,
        'createdAt': createdAt,
      };

  factory Task.fromMap(Map<dynamic, dynamic> m) => Task(
        id: m['id'] as String,
        name: m['name'] as String,
        remaining: m['remaining'] as int,
        active: m['active'] as bool,
        createdAt: m['createdAt'] as int,
      );
}

/// Hive-backed task list. Holds an in-memory list mirroring the box so
/// reads stay synchronous, with writes mirrored to disk on every change.
class TaskProvider extends ChangeNotifier {
  final Box<dynamic> _box;
  final List<Task> _tasks = [];

  TaskProvider({required Box<dynamic> tasksBox}) : _box = tasksBox {
    _loadFromBox();
  }

  /// Unmodifiable view — callers should never mutate the list directly.
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// The single active task, if any.
  Task? get activeTask {
    for (final t in _tasks) {
      if (t.active) return t;
    }
    return null;
  }

  void _loadFromBox() {
    _tasks.clear();
    for (final raw in _box.values) {
      if (raw is Map) {
        _tasks.add(Task.fromMap(raw));
      }
    }
    _sort();
  }

  /// Add a new task. Empty / whitespace names are rejected.
  /// [remaining] is clamped to 1..99.
  void addTask(String name, {int remaining = 1}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final clamped = remaining.clamp(1, 99);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final task = Task(
      id: id,
      name: trimmed,
      remaining: clamped,
      active: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _tasks.add(task);
    _box.put(id, task.toMap());
    _sort();
    notifyListeners();
  }

  void removeTask(String id) {
    final removed = _tasks.indexWhere((t) => t.id == id);
    if (removed < 0) return;
    _tasks.removeAt(removed);
    _box.delete(id);
    notifyListeners();
  }

  /// Tap the selection circle to set [id] active. Tapping the already-
  /// active row deactivates it (re-tap to unset). Done tasks cannot be
  /// activated.
  void setActive(String id) {
    final wasActive = activeTask?.id == id;
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      final shouldBeActive = !wasActive && t.id == id && !t.done;
      if (t.active != shouldBeActive) {
        final updated = t.copyWith(active: shouldBeActive);
        _tasks[i] = updated;
        _box.put(updated.id, updated.toMap());
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Called by the timer when a focus phase completes. Knocks one off
  /// the active task's remaining count; if it hits 0 the active flag
  /// clears so the row settles into the done state.
  void decrementActive() {
    final active = activeTask;
    if (active == null) return;
    final newRemaining = (active.remaining - 1).clamp(0, 99);
    final stayActive = newRemaining > 0;
    final updated = active.copyWith(
      remaining: newRemaining,
      active: stayActive,
    );
    final idx = _tasks.indexWhere((t) => t.id == active.id);
    if (idx < 0) return;
    _tasks[idx] = updated;
    _box.put(updated.id, updated.toMap());
    _sort();
    notifyListeners();
  }

  /// Sort: undone first (by createdAt asc), then done at the bottom.
  /// Keeps the active task near the top of the visible region.
  void _sort() {
    _tasks.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
}
