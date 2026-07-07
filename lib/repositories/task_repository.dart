import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../core/app_clock.dart';
import '../core/plugin_registry.dart';
import '../services/notification_service.dart';
import '../utils/uuid.dart';

extension TaskRepository on AppDatabase {
  Future<List<TaskWithBird>> getTodayTasks(int? userId) {
    final today = AppClock.now;
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final query = select(tasks).join([
      innerJoin(birds, birds.id.equalsExp(tasks.birdId)),
      leftOuterJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
      leftOuterJoin(
          weights,
          weights.birdId.equalsExp(tasks.birdId) &
              weights.recordedAt.isBiggerOrEqualValue(dayStart) &
              weights.recordedAt.isSmallerThanValue(dayEnd)),
    ])
      ..where(tasks.dueDate.isBiggerOrEqualValue(dayStart) &
          tasks.dueDate.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(tasks.status)]);

    if (userId != null) {
      query.where(
          tasks.assignedUserId.equals(userId) | tasks.assignedUserId.isNull());
    }

    return query
        .map((row) => TaskWithBird(
              task: row.readTable(tasks),
              bird: row.readTable(birds),
              species: row.readTableOrNull(species),
              room: row.readTableOrNull(rooms),
              enclosure: row.readTableOrNull(enclosures),
              todayWeight: row.readTableOrNull(weights),
            ))
        .get();
  }

  Future<List<TaskWithBird>> getOverdueTasks() {
    final now = AppClock.now;

    return (select(tasks).join([
      innerJoin(birds, birds.id.equalsExp(tasks.birdId)),
    ])
          ..where(tasks.deadline.isSmallerThanValue(now) &
              (tasks.status.equals('待完成') | tasks.status.equals('逾期')))
          ..orderBy([OrderingTerm.asc(tasks.dueDate)]))
        .map((row) => TaskWithBird(
              task: row.readTable(tasks),
              bird: row.readTable(birds),
              species: null,
            ))
        .get();
  }

  Future<List<TaskWithBird>> getTodayTasksByRoom(int roomId) {
    final today = AppClock.now;
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
            ))
        .get();
  }

  /// 定向查询某鸟今日指定类型的待完成任务（最多一条）。
  ///
  /// 替代 saveWeight 等单点路径里调用 [getTodayTasks]（JOIN 5 表、拉全部今日任务）
  /// 再在内存中过滤的写法。这里只走单表 `tasks` 的 WHERE + limit(1)。
  /// [date] 默认为今天，可显式传入以便测试。
  Future<Task?> getTodayPendingTask(
    int birdId,
    String taskType, {
    DateTime? date,
  }) {
    final today = date ?? AppClock.now;
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return (select(tasks)
          ..where((t) =>
              t.birdId.equals(birdId) &
              t.taskType.equals(taskType) &
              t.status.equals('待完成') &
              t.dueDate.isBiggerOrEqualValue(dayStart) &
              t.dueDate.isSmallerThanValue(dayEnd))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 今日已完成任务数（COUNT，不加载行、不 JOIN）。
  ///
  /// 替代 saveWeight 中"拉全部今日任务再取 `已完成.length`"的全量加载写法。
  /// [date] 默认为今天，可显式传入以便测试。
  Future<int> getTodayCompletedCount({DateTime? date}) async {
    final today = date ?? AppClock.now;
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final count = await (selectOnly(tasks)
          ..addColumns([tasks.id.count()])
          ..where(tasks.dueDate.isBiggerOrEqualValue(dayStart) &
              tasks.dueDate.isSmallerThanValue(dayEnd) &
              tasks.status.equals('已完成')))
        .map((row) => row.read(tasks.id.count()) ?? 0)
        .getSingle();
    return count;
  }

  Future<void> completeTask(int taskId, int completedBy) async {
    await (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        status: const Value('已完成'),
        completedAt: Value(AppClock.now),
        completedBy: Value(completedBy),
        updatedAt: Value(AppClock.now),
      ),
    );
  }

  static bool _generating = false;
  static DateTime? _lastRun;

  /// Reset the throttle so the next [generateTodayTasks] call always runs.
  /// Test-only; not called in production.
  @visibleForTesting
  static void resetThrottleForTest() {
    _generating = false;
    _lastRun = null;
  }

  /// Mark all past-due pending tasks as 逾期.
  /// Runs before the concurrency lock and throttle in [generateTodayTasks],
  /// so overdue marking always executes even when generation is skipped.
  ///
  /// Returns the list of tasks that were just marked (for notification).
  Future<List<Task>> _markOverdueTasks() async {
    final now = AppClock.now;
    // 先查询即将被标记的任务，用于后续发通知
    final due = await (select(tasks)
          ..where((t) =>
              t.deadline.isSmallerThanValue(now) & t.status.equals('待完成')))
        .get();
    if (due.isNotEmpty) {
      await (update(tasks)
            ..where((t) =>
                t.deadline.isSmallerThanValue(now) & t.status.equals('待完成')))
          .write(TasksCompanion(
              status: const Value('逾期'), updatedAt: Value(AppClock.now)));
    }
    return due;
  }

  /// 发送逾期任务本地通知（异步，不阻塞主流程）。
  Future<void> _notifyOverdue(List<Task> tasks) async {
    try {
      final taskTypeLabel = <String, String>{
        'weigh': '称重',
        'medication': '喂药',
      };
      final birdIds = tasks.map((t) => t.birdId).toSet().toList();
      final birds =
          await (select(this.birds)..where((b) => b.id.isIn(birdIds))).get();
      final birdMap = {for (final b in birds) b.id: b};
      final items = [
        for (final t in tasks)
          (
            birdName: birdMap[t.birdId]?.name ?? '未知 #${t.birdId}',
            taskType: taskTypeLabel[t.taskType] ?? t.taskType,
          ),
      ];
      await NotificationService.instance.showOverdueTasks(items);
    } catch (_) {
      // 通知失败不影响主流程
    }
  }

  /// Remove duplicate tasks keeping only the first per dedup key.
  ///
  /// Dedup key:
  /// - weigh tasks → (birdId, taskType, dueDate's day) — same-day dupes collapse
  /// - medication tasks → (birdId, taskType, dueDate full timestamp) — distinct
  ///   time slots on the same day are legitimate
  ///
  /// Implementation: two single-statement bulk DELETEs using SQLite CTEs.
  /// This replaces the previous "load all → group in Dart → delete row-by-row"
  /// pattern that fired one DELETE per duplicate (N+1).
  ///
  /// Uses `strftime('%Y-%m-%d', due_date, 'unixepoch')` to derive the day key
  /// for weigh tasks, matching the previous `toIso8601String().substring(0,10)`
  /// behavior. Drift stores DateTime columns as unix seconds.
  Future<void> cleanupDuplicateTasks() async {
    // ── weigh: dedup by day ──
    await customStatement(r'''
      DELETE FROM tasks
      WHERE task_type = 'weigh'
        AND id NOT IN (
          SELECT MIN(id)
          FROM tasks
          WHERE task_type = 'weigh'
          GROUP BY bird_id,
                   task_type,
                   strftime('%Y-%m-%d', due_date, 'unixepoch')
        )
    ''');

    // ── medication (and any non-weigh typed tasks): dedup by exact timestamp ──
    await customStatement(r'''
      DELETE FROM tasks
      WHERE task_type != 'weigh'
        AND id NOT IN (
          SELECT MIN(id)
          FROM tasks
          WHERE task_type != 'weigh'
          GROUP BY bird_id, task_type, due_date
        )
    ''');
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
      // 逾期标记：_markOverdueTasks 幂等，多次并发执行无副作用。
      final justOverdue = await _markOverdueTasks();
      if (justOverdue.isNotEmpty) {
        _notifyOverdue(justOverdue);
      }

      final today = AppClock.now;
      final dayStart = DateTime(today.year, today.month, today.day);
      debugPrint(
          '[TaskGen] start — ${today.toIso8601String().substring(0, 10)} force=$force');

      // 60 秒节流：避免冷启动/切前台/定时器短时间内重复跑生成逻辑
      if (!force &&
          _lastRun != null &&
          AppClock.now.difference(_lastRun!).inSeconds < 60) {
        debugPrint('[TaskGen] throttle, skip (lastRun=$_lastRun)');
        return 0;
      }
      _lastRun = AppClock.now;

      // 包裹事务：cleanup + 修补/生成原子执行，防止崩溃导致任务丢失
      final result = await transaction(() async {
        await cleanupDuplicateTasks();
        final dayEnd = dayStart.add(const Duration(days: 1));

        // ── 预加载映射（消除 N+1）：patching 与 generation 共用 ──
        //
        // birds/rooms 是小型参考表，全量加载后构建 O(1) 查询 Map，
        // 替代循环内逐条 select(birds) → select(rooms) 的链式查询。
        // 同时一次性查出今日所有称重的 birdId，替代逐任务查询。
        //
        // 注意：与原逐条查询一致，不过滤 deleted_at（保持原行为）。
        final allBirds = await (select(birds)).get();
        final birdMap = {for (final b in allBirds) b.id: b};

        final allRooms = await (select(rooms)).get();
        final roomAssigneeByRoomId = {
          for (final r in allRooms) r.id: r.assignedUserId,
        };
        // birdId → assignedUserId（roomId 为 null 时 value 为 null）
        final birdAssigneeMap = {
          for (final b in allBirds)
            b.id: b.roomId == null ? null : roomAssigneeByRoomId[b.roomId],
        };

        // 单条 SQL：今日有称重记录的所有 birdId（替代逐任务 limit-1 查询）
        final weighRows = await (selectOnly(weights)
              ..addColumns([weights.birdId])
              ..where(weights.recordedAt.isBiggerOrEqualValue(dayStart) &
                  weights.recordedAt.isSmallerThanValue(dayEnd)))
            .map((row) => row.read(weights.birdId))
            .get();
        final weighedBirdIdsToday =
            weighRows.whereType<int>().toSet();
        // 候选任务所需最新体重行：仅在确有候选时填充
        final latestWeighByBirdId = <int, Weight>{};

        // Build dedup key set from existing tasks for today (medication uses full timestamp).
        var existingTodayKeys = <String>{};
        // Weigh cross-day dedup: bird IDs that already have an uncompleted weigh task.
        var weighIncompleteBirdIds = <int>{};
        if (!force) {
          final existingTasks = await (select(tasks)
                ..where((t) =>
                    t.dueDate.isBiggerOrEqualValue(dayStart) &
                    t.dueDate.isSmallerThanValue(dayEnd)))
              .get();

          existingTodayKeys = existingTasks
              .map((t) =>
                  '${t.birdId}_${t.taskType}_${t.dueDate.toIso8601String()}')
              .toSet();
          debugPrint('[TaskGen] existing tasks today: ${existingTasks.length}');

          // 称重跨天去重：收集所有未完成称重任务的 birdId
          final weighIncomplete = await (select(tasks)
                ..where((t) =>
                    t.taskType.equals('weigh') &
                    (t.status.equals('待完成') | t.status.equals('逾期'))))
              .get();
          weighIncompleteBirdIds = weighIncomplete.map((t) => t.birdId).toSet();
          if (weighIncompleteBirdIds.isNotEmpty) {
            debugPrint(
                '[TaskGen] weigh incomplete birds: ${weighIncompleteBirdIds.length}');
          }

          // Patch / upgrade existing tasks
          int patched = 0;
          int upgraded = 0;
          final taskIdsToMarkWeighed = <int, int>{}; // taskId → birdId
          for (final task in existingTasks) {
            // Patch missing assignedUserId（从预加载 Map 取）
            if (task.assignedUserId == null) {
              final assignedUserId = birdAssigneeMap[task.birdId];
              if (assignedUserId != null) {
                await (update(tasks)..where((t) => t.id.equals(task.id)))
                    .write(TasksCompanion(
                        assignedUserId: Value(assignedUserId),
                        updatedAt: Value(AppClock.now)));
                patched++;
              }
            }
            // 兜底：称重入口未传 relatedTaskId 时，事后检测今日体重自动完成称重任务。
            // 用预加载的 weighedBirdIdsToday 判定候选，避免逐任务查询。
            if (task.status == '待完成' &&
                task.taskType == 'weigh' &&
                weighedBirdIdsToday.contains(task.birdId)) {
              taskIdsToMarkWeighed[task.id] = task.birdId;
            }
          }
          // 仅对确有候选的 birdId 各查一次最新体重（候选数通常远小于任务总数）
          if (taskIdsToMarkWeighed.isNotEmpty) {
            final missingBirdIds = taskIdsToMarkWeighed.values
                .toSet()
                .where((id) => !latestWeighByBirdId.containsKey(id))
                .toList();
            if (missingBirdIds.isNotEmpty) {
              final fetched = await (select(weights)
                    ..where((w) =>
                        w.birdId.isIn(missingBirdIds) &
                        w.recordedAt.isBiggerOrEqualValue(dayStart) &
                        w.recordedAt.isSmallerThanValue(dayEnd))
                    ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
                  .get();
              // 每只鸟保留最新一条
              for (final w in fetched) {
                final existing = latestWeighByBirdId[w.birdId];
                if (existing == null ||
                    w.recordedAt.isAfter(existing.recordedAt)) {
                  latestWeighByBirdId[w.birdId] = w;
                }
              }
            }
            for (final entry in taskIdsToMarkWeighed.entries) {
              final w = latestWeighByBirdId[entry.value];
              if (w == null) continue;
              await (update(tasks)..where((t) => t.id.equals(entry.key))).write(
                  TasksCompanion(
                status: const Value('已完成'),
                completedAt: Value(w.recordedAt),
                completedBy: Value(w.recordedBy),
                updatedAt: Value(AppClock.now),
              ));
              upgraded++;
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
            debugPrint(
                '[TaskGen] plugin ${plugin.id}: ${descriptors.length} task descriptors');

            for (final d in descriptors) {
              // 称重跨天去重：该鸟已有未完成称重任务 → 跳过
              if (d.taskType == 'weigh' &&
                  weighIncompleteBirdIds.contains(d.birdId)) {
                continue;
              }
              // 今日去重：检查 (birdId, taskType, dueDate) 是否已存在
              final key =
                  '${d.birdId}_${d.taskType}_${d.dueDate.toIso8601String()}';
              if (existingTodayKeys.contains(key)) {
                continue;
              }

              // Resolve bird and room for assignee（从预加载 Map 取，O(1)）
              final bird = birdMap[d.birdId];
              if (bird == null) continue;
              final assignedUserId = birdAssigneeMap[d.birdId];

              await into(tasks).insert(TasksCompanion.insert(
                uuid: genUuid(),
                birdId: d.birdId,
                roomId: Value(bird.roomId),
                assignedUserId: Value(assignedUserId),
                taskType: Value(d.taskType),
                dueDate: d.dueDate,
                deadline: Value(d.deadline),
                status: const Value('待完成'),
                metadata:
                    Value(d.metadata != null ? jsonEncode(d.metadata) : null),
                createdAt: Value(AppClock.now),
                updatedAt: Value(AppClock.now),
              ));
              existingTodayKeys.add(key);
              weighIncompleteBirdIds
                  .add(d.birdId); // prevent intra-run weigh duplicates
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
    final today = AppClock.now;
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Build dedup key set from existing tasks for this bird today
    final existingTasks = await (select(tasks)
          ..where((t) =>
              t.birdId.equals(birdId) &
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

          final key =
              '${d.birdId}_${d.taskType}_${d.dueDate.toIso8601String()}';
          if (existingKeys.contains(key)) continue;

          // Resolve bird and room for assignee
          final bird = await (select(birds)
                ..where((b) => b.id.equals(d.birdId)))
              .getSingleOrNull();
          if (bird == null) continue;
          int? assignedUserId;
          if (bird.roomId != null) {
            final room = await (select(rooms)
                  ..where((r) => r.id.equals(bird.roomId!)))
                .getSingleOrNull();
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
            createdAt: Value(AppClock.now),
            updatedAt: Value(AppClock.now),
          ));
          existingKeys.add(key);
          generated++;
        }
      } catch (e) {
        debugPrint(
            '[TaskGen] plugin ${plugin.id} detectTasks(birdId=$birdId) failed: $e');
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
