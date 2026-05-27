import 'package:drift/drift.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

extension TaskRepository on AppDatabase {
  Future<List<TaskWithBird>> getTodayTasks(int? userId) {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final query = select(tasks).join([
      innerJoin(birds, birds.id.equalsExp(tasks.birdId)),
      leftOuterJoin(species, species.id.equalsExp(birds.speciesId)),
    ])
      ..where(tasks.dueDate.isBiggerOrEqualValue(dayStart) &
          tasks.dueDate.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(tasks.status)]);

    if (userId != null) {
      query.where(tasks.assignedUserId.equals(userId));
    }

    return query.map((row) => TaskWithBird(
          task: row.readTable(tasks),
          bird: row.readTable(birds),
          species: row.readTableOrNull(species),
        )).get();
  }

  Future<List<TaskWithBird>> getOverdueTasks() {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);

    return (select(tasks).join([
      innerJoin(birds, birds.id.equalsExp(tasks.birdId)),
    ])
      ..where(tasks.dueDate.isSmallerThanValue(dayStart) &
          tasks.status.equals('待完成'))
      ..orderBy([OrderingTerm.asc(tasks.dueDate)]))
        .map((row) => TaskWithBird(
              task: row.readTable(tasks),
              bird: row.readTable(birds),
              species: null,
            )).get();
  }

  Future<List<TaskWithBird>> getTodayTasksByRoom(int roomId) {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return (select(tasks).join([
      innerJoin(birds, birds.id.equalsExp(tasks.birdId)),
    ])
      ..where(tasks.roomId.equals(roomId) &
          tasks.dueDate.isBiggerOrEqualValue(dayStart) &
          tasks.dueDate.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(tasks.status)]))
        .map((row) => TaskWithBird(
              task: row.readTable(tasks),
              bird: row.readTable(birds),
              species: null,
            )).get();
  }

  Future<void> completeTask(int taskId, int completedBy) async {
    await (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        status: const Value('已完成'),
        completedAt: Value(DateTime.now()),
        completedBy: Value(completedBy),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> generateTodayTasks() async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final existingCount = await (selectOnly(tasks)
          ..addColumns([tasks.id.count()])
          ..where(tasks.dueDate.isBiggerOrEqualValue(dayStart) &
              tasks.dueDate.isSmallerThanValue(dayEnd)))
        .map((row) => row.read(tasks.id.count()))
        .getSingle();

    if (existingCount != null && existingCount > 0) return 0;

    int generated = 0;
    final allBirds = await select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
    ]).get();

    for (final row in allBirds) {
      final bird = row.readTable(birds);
      final sp = row.readTable(species);
      final ageDays = today.difference(bird.birthDate).inDays;

      int intervalDays;
      if (ageDays <= sp.nestlingEndDays) {
        intervalDays = 1;
      } else if (ageDays <= sp.juvenileEndDays) {
        intervalDays = 3;
      } else {
        intervalDays = sp.adultWeighIntervalDays;
      }

      if (intervalDays > 0 &&
          (today.difference(bird.birthDate).inDays) % intervalDays == 0) {
        // 检查该鸟今天是否已有任务
        final existing = await (select(tasks)
              ..where((t) =>
                  t.birdId.equals(bird.id) &
                  t.dueDate.isBiggerOrEqualValue(dayStart) &
                  t.dueDate.isSmallerThanValue(dayEnd)))
            .getSingleOrNull();
        if (existing != null) continue;

        await into(tasks).insert(TasksCompanion.insert(
          uuid: genUuid(),
          birdId: bird.id,
          roomId: Value(bird.roomId),
          dueDate: today,
          status: Value('待完成'),
        ));
        generated++;
      }
    }

    // 标记逾期
    await (update(tasks)
          ..where((t) =>
              t.dueDate.isSmallerThanValue(dayStart) &
              t.status.equals('待完成')))
        .write(TasksCompanion(status: const Value('逾期'), updatedAt: Value(DateTime.now())));

    return generated;
  }

  Future<void> remove(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}

class TaskWithBird {
  final Task task;
  final Bird bird;
  final Specy? species;

  TaskWithBird({required this.task, required this.bird, this.species});
}
