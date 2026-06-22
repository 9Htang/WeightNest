import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../core/app_clock.dart';
import '../core/event_bus.dart';
import '../core/events.dart';
import '../utils/uuid.dart';

/// 统一操作服务 —— 所有插件写操作的唯一入口。
///
/// 在同一个事务中完成：
/// 1. 写入 [ActivityLogs] 流水记录
/// 2. 自动完成关联的 [Tasks] 待办任务（如有 [relatedTaskId]）
/// 3. 通过 [EventBus] 发出 [OperationRecordedEvent] 供其他插件响应
///
/// 插件通过 [pluginRegistry.operationService] 调用，无需修改 [FeaturePlugin] 接口。
class OperationService {
  final AppDatabase? Function() _dbGetter;
  final EventBus _eventBus;

  AppDatabase get _db => _dbGetter()!;

  OperationService(this._dbGetter, this._eventBus);

  /// 记录一次操作。
  ///
  /// [pluginId] 和 [actionType] 组合标识操作来源，如 `('weights', 'weight_recorded')`。
  /// [birdId] 可空（繁育等场景可能不关联单只鸟）。
  /// [summary] 是人类可读简述，直接展示在时间轴 UI 上。
  /// [details] 是 JSON 可序列化的详情 Map，插件可存入专业表 ID 等信息。
  /// [relatedTaskId] 不为 null 时，对应任务会被自动标记为"已完成"。
  /// [operatedBy] 是操作人 ID。
  /// [operatedAt] 是操作发生时间，默认当前时间。
  ///
  /// 返回新创建的 [ActivityLog] 记录。
  Future<ActivityLog> record({
    required String pluginId,
    required String actionType,
    required String summary,
    int? birdId,
    Map<String, dynamic>? details,
    int? relatedTaskId,
    int? operatedBy,
    DateTime? operatedAt,
  }) async {
    final opAt = operatedAt ?? AppClock.now;

    final log = await _db.transaction(() async {
      // 1. 写入统一操作日志
      final logId = await _db.into(_db.activityLogs).insertReturning(
        ActivityLogsCompanion.insert(
          uuid: genUuid(),
          birdId: Value(birdId),
          pluginId: pluginId,
          actionType: actionType,
          summary: summary,
          details: Value(details != null ? jsonEncode(details) : null),
          relatedTaskId: Value(relatedTaskId),
          operatedBy: Value(operatedBy),
          operatedAt: Value(opAt),
          createdAt: Value(AppClock.now),
        ),
      );

      // 2. 自动完成关联的待办任务
      if (relatedTaskId != null) {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(relatedTaskId)))
            .write(TasksCompanion(
          status: const Value('已完成'),
          completedAt: Value(AppClock.now),
          completedBy: Value(operatedBy),
          updatedAt: Value(AppClock.now),
        ));
      }

      return logId;
    });

    // 3. 事务提交成功后，触发事件总线
    _eventBus.emit(OperationRecordedEvent(
      logId: log.id,
      pluginId: pluginId,
      actionType: actionType,
      birdId: birdId,
      summary: summary,
      details: details,
      relatedTaskId: relatedTaskId,
      operatedBy: operatedBy,
      operatedAt: opAt,
    ));

    debugPrint('[OperationService] $pluginId/$actionType #${log.id}: $summary');
    return log;
  }

  /// 在外部事务中记录一次操作（不自启事务）。
  ///
  /// 调用方负责开启事务，例如：
  /// ```dart
  /// await _db.transaction(() async {
  ///   final w = await _db.addWeight(...);
  ///   await pluginRegistry.operationService.recordInTransaction(
  ///     pluginId: 'weights',
  ///     actionType: 'weight_recorded',
  ///     summary: '...',
  ///     ...,
  ///   );
  /// });
  /// ```
  ///
  /// 参数含义同 [record]，但不发出 EventBus 事件（由外层决定是否发）。
  Future<ActivityLog> recordInTransaction({
    required String pluginId,
    required String actionType,
    required String summary,
    int? birdId,
    Map<String, dynamic>? details,
    int? relatedTaskId,
    int? operatedBy,
    DateTime? operatedAt,
  }) async {
    final opAt = operatedAt ?? AppClock.now;

    // 1. 写入统一操作日志（参与外层事务）
    final log = await _db.into(_db.activityLogs).insertReturning(
      ActivityLogsCompanion.insert(
        uuid: genUuid(),
        birdId: Value(birdId),
        pluginId: pluginId,
        actionType: actionType,
        summary: summary,
        details: Value(details != null ? jsonEncode(details) : null),
        relatedTaskId: Value(relatedTaskId),
        operatedBy: Value(operatedBy),
        operatedAt: Value(opAt),
        createdAt: Value(AppClock.now),
      ),
    );

    // 2. 自动完成关联的待办任务（参与外层事务）
    if (relatedTaskId != null) {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(relatedTaskId)))
          .write(TasksCompanion(
        status: const Value('已完成'),
        completedAt: Value(AppClock.now),
        completedBy: Value(operatedBy),
        updatedAt: Value(AppClock.now),
      ));
    }

    // 3. 外层事务提交后触发事件
    _eventBus.emit(OperationRecordedEvent(
      logId: log.id,
      pluginId: pluginId,
      actionType: actionType,
      birdId: birdId,
      summary: summary,
      details: details,
      relatedTaskId: relatedTaskId,
      operatedBy: operatedBy,
      operatedAt: opAt,
    ));

    debugPrint('[OperationService] $pluginId/$actionType #${log.id} (in-tx): $summary');
    return log;
  }

  /// 撤销一次操作 —— 在同一事务中回滚 Task 状态并删除 ActivityLog。
  ///
  /// 适用于用户误操作（如误点"已喂"）后需要回退的场景。
  /// 调用方需自行处理专业表数据的回滚（如删除 Weights 记录）。
  ///
  /// 返回被撤销的 [ActivityLog] 记录（已删除），失败返回 null。
  Future<ActivityLog?> revokeOperation(int logId) async {
    return _db.transaction(() async {
      final log = await (_db.select(_db.activityLogs)
            ..where((t) => t.id.equals(logId)))
          .getSingleOrNull();
      if (log == null) return null;

      // 回滚关联任务状态：已完成/已跳过 → 待完成
      if (log.relatedTaskId != null) {
        await (_db.update(_db.tasks)
              ..where((t) => t.id.equals(log.relatedTaskId!)))
            .write(TasksCompanion(
          status: const Value('待完成'),
          completedAt: const Value(null),
          completedBy: const Value(null),
          updatedAt: Value(AppClock.now),
        ));
      }

      // 删除操作日志
      await (_db.delete(_db.activityLogs)..where((t) => t.id.equals(logId))).go();

      debugPrint('[OperationService] revoked #$logId: ${log.summary}');
      return log;
    });
  }
}
