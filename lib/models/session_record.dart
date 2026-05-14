import 'package:hive/hive.dart';

part 'session_record.g.dart';

@HiveType(typeId: 1)
class SessionRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? taskId;

  @HiveField(2)
  String? taskName;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime endTime;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  bool isPomodoro; // false = break

  /// Skipped focus phases are still logged so the user sees them in
  /// history, but startTime/endTime/durationMinutes are placeholders —
  /// the row renders task-name + "(skipped)" only.
  @HiveField(7)
  bool skipped;

  SessionRecord({
    required this.id,
    this.taskId,
    this.taskName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isPomodoro,
    this.skipped = false,
  });
}
