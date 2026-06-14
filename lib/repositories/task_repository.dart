import 'package:flutter/foundation.dart';
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
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
      leftOuterJoin(weights,
        weights.birdId.equalsExp(tasks.birdId) &
        weights.recordedAt.isBiggerOrEqualValue(dayStart) &
        weights.recordedAt.isSmallerThanValue(dayEnd)),
    ])
      ..where(tasks.dueDate.isBiggerOrEqualValue(dayStart) &
          tasks.dueDate.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(tasks.status)]);

    if (userId != null) {
      query.where(tasks.assignedUserId.equals(userId) |
          tasks.assignedUserId.isNull());
    }

    return query.map((row) => TaskWithBird(
          task: row.readTable(tasks),
          bird: row.readTable(birds),
          species: row.readTableOrNull(species),
          room: row.readTableOrNull(rooms),
          enclosure: row.readTableOrNull(enclosures),
          todayWeight: row.readTableOrNull(weights),
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

  static bool _generating = false;
  static DateTime? _lastGeneratedDay;

  /// Remove duplicate tasks (same bird + same dueDate) keeping only the first.
  Future<void> cleanupDuplicateTasks() async {
    final allTasks = await (select(tasks)).get();
    final grouped = <String, List<Task>>{};
    for (final t in allTasks) {
      final date = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      final key = '${t.birdId}_${date.toIso8601String()}';
      grouped.putIfAbsent(key, () => []).add(t);
    }
    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length > 1) {
        list.sort((a, b) => a.id.compareTo(b.id));
        // Keep first, delete the rest
        for (var i = 1; i < list.length; i++) {
          await (delete(tasks)..where((t) => t.id.equals(list[i].id))).go();
        }
      }
    }
  }

  /// Generate today's weigh tasks based on per-bird interval and last weigh date.
  /// Set [force] to true to skip existing-task guards and always create tasks.
  /// Returns number of newly generated tasks.
  Future<int> generateTodayTasks({bool force = false}) async {
    if (_generating) {
      debugPrint('[TaskGen] already generating, skip');
      return 0;
    }
    _generating = true;
    try {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    debugPrint('[TaskGen] start — ${today.toIso8601String().substring(0, 10)} force=$force');

    // 同一天已生成过任务则跳过（force=true 或跨天时重新生成）
    if (!force && _lastGeneratedDay != null && _lastGeneratedDay!.isAtSameMomentAs(dayStart)) {
      debugPrint('[TaskGen] same-day guard, skip (lastGenerated=$_lastGeneratedDay)');
      return 0;
    }

    await cleanupDuplicateTasks();
    final dayEnd = dayStart.add(const Duration(days: 1));

    // If not forced, check existing tasks and patch missing assignments
    if (!force) {
      final existingTasks = await (select(tasks)
            ..where((t) => t.dueDate.isBiggerOrEqualValue(dayStart) &
                t.dueDate.isSmallerThanValue(dayEnd)))
          .get();

      debugPrint('[TaskGen] existing tasks today: ${existingTasks.length}');
      if (existingTasks.isNotEmpty) {
        int patched = 0;
        int upgraded = 0;
        for (final task in existingTasks) {
          // Patch missing assignedUserId
          if (task.assignedUserId == null) {
            final bird = await (select(birds)..where((b) => b.id.equals(task.birdId))).getSingleOrNull();
            if (bird != null && bird.roomId != null) {
              final room = await (select(rooms)..where((r) => r.id.equals(bird.roomId!))).getSingleOrNull();
              if (room?.assignedUserId != null) {
                await (update(tasks)..where((t) => t.id.equals(task.id)))
                    .write(TasksCompanion(assignedUserId: Value(room!.assignedUserId), updatedAt: Value(DateTime.now())));
                patched++;
              }
            }
          }
          // Upgrade pending task to completed if bird was weighed today
          if (task.status == '待完成') {
            final lastWeigh = await (select(weights)
                  ..where((w) => w.birdId.equals(task.birdId) &
                      w.recordedAt.isBiggerOrEqualValue(dayStart) &
                      w.recordedAt.isSmallerThanValue(dayEnd))
                  ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
                  ..limit(1))
                .getSingleOrNull();
            if (lastWeigh != null) {
              await (update(tasks)..where((t) => t.id.equals(task.id)))
                  .write(TasksCompanion(
                status: const Value('已完成'),
                completedAt: Value(lastWeigh.recordedAt),
                completedBy: Value(lastWeigh.recordedBy),
                updatedAt: Value(DateTime.now()),
              ));
              upgraded++;
            }
          }
        }
        _lastGeneratedDay = dayStart;
        debugPrint('[TaskGen] existing tasks found, patched=$patched upgraded=$upgraded, skip generation');
        if (patched > 0 || upgraded > 0) return patched + upgraded;
        return 0;
      }
    }

    int generated = 0;
    final allBirds = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
    ])).get();

    debugPrint('[TaskGen] total birds with species: ${allBirds.length}');

    for (final row in allBirds) {
      final bird = row.readTable(birds);
      final sp = row.readTable(species);
      final room = row.readTableOrNull(rooms);
      final ageDays = today.difference(bird.birthDate).inDays;

      // Determine weigh interval: bird override > species stage default
      int intervalDays;
      String stage;
      if (bird.weighIntervalDays != null) {
        intervalDays = bird.weighIntervalDays!;
        stage = 'manual';
      } else if (ageDays <= sp.nestlingEndDays) {
        intervalDays = sp.nestlingWeighIntervalDays;
        stage = 'nestling';
      } else if (ageDays <= sp.juvenileEndDays) {
        intervalDays = sp.juvenileWeighIntervalDays;
        stage = 'juvenile';
      } else {
        intervalDays = sp.adultWeighIntervalDays;
        stage = 'adult';
      }

      if (intervalDays <= 0) {
        debugPrint('[TaskGen]   ${bird.name}: interval=$intervalDays, skip');
        continue;
      }

      // Check last weigh date — create task if it's been >= intervalDays
      final lastWeighList = await (select(weights)
            ..where((w) => w.birdId.equals(bird.id))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(1))
          .get();
      final lastWeigh = lastWeighList.isNotEmpty ? lastWeighList.first : null;

      final daysSinceLast = lastWeigh == null ? null
          : today.difference(lastWeigh.recordedAt).inDays;
      final needsTask = lastWeigh == null ||
          daysSinceLast! >= intervalDays;

      if (!needsTask) {
        // Bird already weighed today within interval — create a completed task
        await into(tasks).insert(TasksCompanion.insert(
          uuid: genUuid(),
          birdId: bird.id,
          roomId: Value(bird.roomId),
          assignedUserId: Value(room?.assignedUserId),
          dueDate: today,
          status: const Value('已完成'),
          completedAt: Value(lastWeigh.recordedAt),
          completedBy: Value(lastWeigh.recordedBy),
        ));
        generated++;
        debugPrint('[TaskGen]   ${bird.name} ($stage interval=$intervalDays d) weighed today -> completed task');
        continue;
      }

      // Check no existing task for this bird today (skip when forcing)
      if (!force) {
        final existingTaskList = await (select(tasks)
              ..where((t) =>
                  t.birdId.equals(bird.id) &
                  t.dueDate.isBiggerOrEqualValue(dayStart) &
                  t.dueDate.isSmallerThanValue(dayEnd))
              ..limit(1))
            .get();
        if (existingTaskList.isNotEmpty) {
          debugPrint('[TaskGen]   ${bird.name}: already has task for today, skip');
          continue;
        }
      }

      await into(tasks).insert(TasksCompanion.insert(
        uuid: genUuid(),
        birdId: bird.id,
        roomId: Value(bird.roomId),
        assignedUserId: Value(room?.assignedUserId),
        dueDate: today,
        status: const Value('待完成'),
      ));
      generated++;
      debugPrint('[TaskGen]   ${bird.name} ($stage interval=$intervalDays d) -> task created');
    }

    // Mark overdue
    await (update(tasks)
          ..where((t) =>
              t.dueDate.isSmallerThanValue(dayStart) &
              t.status.equals('待完成')))
        .write(TasksCompanion(status: const Value('逾期'), updatedAt: Value(DateTime.now())));

    _lastGeneratedDay = dayStart;
    debugPrint('[TaskGen] done — generated=$generated');
    return generated;
    } finally {
      _generating = false;
    }
  }

  /// Publish weigh tasks for specific birds unconditionally (admin override)
  Future<int> publishTasksForBirds(List<int> birdIds) async {
    final today = DateTime.now();
    int generated = 0;

    for (final birdId in birdIds) {
      final bird = await (select(birds)..where((b) => b.id.equals(birdId))).getSingleOrNull();
      if (bird == null) continue;

      // Get room assignment
      int? assignedUserId;
      if (bird.roomId != null) {
        final room = await (select(rooms)..where((r) => r.id.equals(bird.roomId!))).getSingleOrNull();
        assignedUserId = room?.assignedUserId;
      }

      await into(tasks).insert(TasksCompanion.insert(
        uuid: genUuid(),
        birdId: bird.id,
        roomId: Value(bird.roomId),
        assignedUserId: Value(assignedUserId),
        dueDate: today,
        status: const Value('待完成'),
      ));
      generated++;
    }
    return generated;
  }

  Future<void> remove(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}

class TaskWithBird {
  final Task task;
  final Bird bird;
  final Specy? species;
  final Room? room;
  final Enclosure? enclosure;
  final Weight? todayWeight;

  TaskWithBird({
    required this.task,
    required this.bird,
    this.species,
    this.room,
    this.enclosure,
    this.todayWeight,
  });
}
