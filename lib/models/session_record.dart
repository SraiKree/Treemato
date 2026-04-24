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

  SessionRecord({
    required this.id,
    this.taskId,
    this.taskName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isPomodoro,
  });
}
