import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int pomodorosRemaining;

  @HiveField(3)
  int pomodorosTotal;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    required this.pomodorosRemaining,
    required this.pomodorosTotal,
    this.isCompleted = false,
    required this.createdAt,
  });
}
