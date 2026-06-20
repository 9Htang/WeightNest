import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../core/plugin_registry.dart';
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
    final now = DateTime.now();

    return (select(tasks).join([
      innerJoin(birds, birds.id.equalsExp(tasks.birdId)),
    ])
      ..where(tasks.deadline.isSmallerThanValue(now) &
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
  static DateTime? _lastRun;

  /// Mark all past-due pending tasks as 逾期.
  /// Called on every [generateTodayTasks] invocation, before the throttle,
  /// so overdue marking always runs regardless of whether generation is skipped.
  Future<void> _markOverdueTasks() async {
    final now = DateTime.now();
    await (update(tasks)
          ..where((t) =>
              t.deadline.isSmallerThanValue(now) &
              t.status.equals('待完成')))
        .write(TasksCompanion(status: const Value('逾期'), updatedAt: Value(DateTime.now())));
  }

  /// Remove duplicate tasks (same bird + same taskType + same dueDate) keeping only the first.
  Future<void> cleanupDuplicateTasks() async {
    final allTasks = await (select(tasks)).get();
    final grouped = <String, List<Task>>{};
    for (final t in allTasks) {
      // Weigh tasks dedup by date only;
      // medication tasks keep full timestamp — different time slots on the same day are legitimate.
      final key = t.taskType == 'weigh'
          ? '${t.birdId}_${t.taskType}_${t.dueDate.toIso8601String().substring(0, 10)}'
          : '${t.birdId}_${t.taskType}_${t.dueDate.toIso8601String()}';
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

  /// Generate today's tasks by aggregating [FeaturePlugin.detectTasks] from all
  /// enabled plugins. Each plugin contributes zero or more [PluginTaskDescriptor]s;
  /// deduplication is by (birdId, taskType, dueDate).
  ///
  /// Set [force] to true to skip existing-task guards and always create tasks.
  /// Returns total number of patched + upgraded + newly generated tasks.
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

    // 逾期标记始终执行，不受节流影响
    await _markOverdueTasks();

    // 60 秒节流：避免冷启动/切前台/定时器短时间内重复跑生成逻辑
    if (!force && _lastRun != null && DateTime.now().difference(_lastRun!).inSeconds < 60) {
      debugPrint('[TaskGen] throttle, skip (lastRun=$_lastRun)');
      return 0;
    }
    _lastRun = DateTime.now();

    // 包裹事务：cleanup + 修补/生成原子执行，防止崩溃导致任务丢失
    final result = await transaction(() async {
      await cleanupDuplicateTasks();
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Build dedup key set from existing tasks for today (medication uses full timestamp).
      var existingTodayKeys = <String>{};
      // Weigh cross-day dedup: bird IDs that already have an uncompleted weigh task.
      var weighIncompleteBirdIds = <int>{};
      if (!force) {
        final existingTasks = await (select(tasks)
              ..where((t) => t.dueDate.isBiggerOrEqualValue(dayStart) &
                  t.dueDate.isSmallerThanValue(dayEnd)))
            .get();

        existingTodayKeys = existingTasks
            .map((t) => '${t.birdId}_${t.taskType}_${t.dueDate.toIso8601String()}')
            .toSet();
        debugPrint('[TaskGen] existing tasks today: ${existingTasks.length}');

        // 称重跨天去重：收集所有未完成称重任务的 birdId
        final weighIncomplete = await (select(tasks)
              ..where((t) => t.taskType.equals('weigh') &
                  (t.status.equals('待完成') | t.status.equals('逾期'))))
            .get();
        weighIncompleteBirdIds = weighIncomplete.map((t) => t.birdId).toSet();
        if (weighIncompleteBirdIds.isNotEmpty) {
          debugPrint('[TaskGen] weigh incomplete birds: ${weighIncompleteBirdIds.length}');
        }

        // Patch / upgrade existing tasks
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
          // 兜底：称重入口未传 relatedTaskId 时，事后检测今日体重自动完成称重任务。
          if (task.status == '待完成' && task.taskType == 'weigh') {
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
        if (patched > 0 || upgraded > 0) {
          debugPrint('[TaskGen] patched=$patched upgraded=$upgraded');
        }
      }

      // ── Plugin-driven task generation ──
      int generated = 0;
      for (final plugin in pluginRegistry.enabledPlugins) {
        try {
          final descriptors = await plugin.detectTasks(this);
          if (descriptors.isEmpty) continue;
          debugPrint('[TaskGen] plugin ${plugin.id}: ${descriptors.length} task descriptors');

          for (final d in descriptors) {
            // 称重跨天去重：该鸟已有未完成称重任务 → 跳过
            if (d.taskType == 'weigh' && weighIncompleteBirdIds.contains(d.birdId)) {
              continue;
            }
            // 今日去重：检查 (birdId, taskType, dueDate) 是否已存在
            final key = '${d.birdId}_${d.taskType}_${d.dueDate.toIso8601String()}';
            if (existingTodayKeys.contains(key)) {
              continue;
            }

            // Resolve bird and room for assignee
            final bird = await (select(birds)..where((b) => b.id.equals(d.birdId))).getSingleOrNull();
            if (bird == null) continue;
            int? assignedUserId;
            if (bird.roomId != null) {
              final room = await (select(rooms)..where((r) => r.id.equals(bird.roomId!))).getSingleOrNull();
              assignedUserId = room?.assignedUserId;
            }

            await into(tasks).insert(TasksCompanion.insert(
              uuid: genUuid(),
              birdId: d.birdId,
              roomId: Value(bird.roomId),
              assignedUserId: Value(assignedUserId),
              taskType: Value(d.taskType),
              dueDate: d.dueDate,
              deadline: Value(d.deadline),
              status: const Value('待完成'),
              metadata: Value(d.metadata != null ? jsonEncode(d.metadata) : null),
            ));
            existingTodayKeys.add(key);
            weighIncompleteBirdIds.add(d.birdId); // prevent intra-run weigh duplicates
            generated++;
          }
        } catch (e) {
          debugPrint('[TaskGen] plugin ${plugin.id} detectTasks failed: $e');
        }
      }

      debugPrint('[TaskGen] done — generated=$generated');
      return generated;
    });

    return result;
    } finally {
      _generating = false;
    }
  }

  /// Generate tasks for a specific bird by aggregating [FeaturePlugin.detectTasks]
  /// from all enabled plugins. Each plugin is asked to produce tasks for the given
  /// bird, and results are deduplicated against existing tasks for today.
  ///
  /// Returns the number of newly generated tasks.
  Future<int> generateTasksForBird(int birdId) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Build dedup key set from existing tasks for this bird today
    final existingTasks = await (select(tasks)
          ..where((t) => t.birdId.equals(birdId) &
              t.dueDate.isBiggerOrEqualValue(dayStart) &
              t.dueDate.isSmallerThanValue(dayEnd)))
        .get();
    final existingKeys = existingTasks
        .map((t) => '${t.birdId}_${t.taskType}_${t.dueDate.toIso8601String()}')
        .toSet();

    int generated = 0;
    for (final plugin in pluginRegistry.enabledPlugins) {
      try {
        final descriptors = await plugin.detectTasks(this, birdId: birdId);
        if (descriptors.isEmpty) continue;

        for (final d in descriptors) {
          // Guard: only create tasks for the requested bird
          if (d.birdId != birdId) continue;

          final key = '${d.birdId}_${d.taskType}_${d.dueDate.toIso8601String()}';
          if (existingKeys.contains(key)) continue;

          // Resolve bird and room for assignee
          final bird = await (select(birds)..where((b) => b.id.equals(d.birdId))).getSingleOrNull();
          if (bird == null) continue;
          int? assignedUserId;
          if (bird.roomId != null) {
            final room = await (select(rooms)..where((r) => r.id.equals(bird.roomId!))).getSingleOrNull();
            assignedUserId = room?.assignedUserId;
          }

          await into(tasks).insert(TasksCompanion.insert(
            uuid: genUuid(),
            birdId: d.birdId,
            roomId: Value(bird.roomId),
            assignedUserId: Value(assignedUserId),
            taskType: Value(d.taskType),
            dueDate: d.dueDate,
            deadline: Value(d.deadline),
            status: const Value('待完成'),
            metadata: Value(d.metadata != null ? jsonEncode(d.metadata) : null),
          ));
          existingKeys.add(key);
          generated++;
        }
      } catch (e) {
        debugPrint('[TaskGen] plugin ${plugin.id} detectTasks(birdId=$birdId) failed: $e');
      }
    }

    debugPrint('[TaskGen] generateTasksForBird $birdId — generated=$generated');
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
