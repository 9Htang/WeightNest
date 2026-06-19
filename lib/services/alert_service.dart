import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../core/plugin.dart';
import '../core/plugin_registry.dart';
import '../repositories/bird_repository.dart';
import '../utils/uuid.dart';

class AnomalyAlert {
  final BirdWithDetails bird;
  final String type;
  final String description;
  final AlertSeverity severity;
  final DateTime createdAt;
  AnomalyAlert({required this.bird, required this.type, required this.description, required this.severity, required this.createdAt});
}

class AlertWithStatus {
  final AnomalyAlert alert;
  final bool isConfirmed;
  final DateTime createdAt;
  AlertWithStatus({required this.alert, required this.isConfirmed, required this.createdAt});
}

class AlertService {
  final AppDatabase _db;
  AlertService(this._db);

  /// 聚合所有启用插件的告警。
  ///
  /// 若指定 [birdId]，仅检测该鸟；否则全量扫描。
  Future<List<AnomalyAlert>> detectAll({int? birdId}) async {
    final alerts = <AnomalyAlert>[];

    // 预加载鸟（供告警 enrichment 用）
    final List<BirdWithDetails> allBirds;
    if (birdId != null) {
      final single = await _db.getWithDetails(birdId);
      allBirds = single != null ? [single] : [];
    } else {
      allBirds = await _db.getAllWithDetails();
    }

    // 遍历插件告警
    for (final plugin in pluginRegistry.enabledPlugins) {
      try {
        final pluginAlerts = await plugin.detectAlerts(_db, birdId: birdId);
        for (final pa in pluginAlerts) {
          // birdId 兜底过滤（防止插件忽略参数）
          if (birdId != null && pa.birdId != birdId) continue;
          final bird = allBirds.cast<BirdWithDetails?>().firstWhere(
            (b) => b?.bird.id == pa.birdId,
            orElse: () => null,
          );
          if (bird != null) {
            alerts.add(AnomalyAlert(
              bird: bird,
              type: pa.type,
              description: pa.description,
              severity: pa.severity,
              createdAt: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        debugPrint('[AlertService] plugin ${plugin.id} detectAlerts failed: $e');
      }
    }

    return alerts;
  }
}

/// 异常提醒确认持久化
extension AlertRepository on AppDatabase {
  /// 持久化新检测到的异常（isRead = false），供首页横幅查询
  /// 同一天同一鸟+同一类型只保留一条未读记录；
  /// 若相同描述的已确认记录已存在也跳过（避免确认后立即重复出现）
  ///
  /// 批量实现：单事务内一次查出当天全部记录并在内存去重，避免逐条 2~3 次
  /// 查询的 N+1（每次保存体重都会触发本方法）。
  Future<void> upsertUnreadAlerts(List<AnomalyAlert> alerts) async {
    if (alerts.isEmpty) return;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);

    await transaction(() async {
      final rows = await (select(alertRecords)
            ..where((t) => t.createdAt.isBiggerOrEqualValue(dayStart)))
          .get();
      // 未读去重键：birdId:alertType ；已确认去重键：birdId:alertType:description
      final unreadKeys = <String>{};
      final confirmedKeys = <String>{};
      for (final r in rows) {
        final k = '${r.birdId}:${r.alertType}';
        if (!r.isRead) {
          unreadKeys.add(k);
        } else {
          confirmedKeys.add('$k:${r.description}');
        }
      }

      for (final a in alerts) {
        final k = '${a.bird.bird.id}:${a.type}';
        // 1. 已有未读记录 → 跳过（去重）
        if (unreadKeys.contains(k)) continue;
        // 2. 完全相同描述的已确认记录 → 跳过（用户已确认过这个具体预警）
        if (confirmedKeys.contains('$k:${a.description}')) continue;
        // 3. 新预警 → 写入
        await into(alertRecords).insert(AlertRecordsCompanion.insert(
          uuid: genUuid(),
          birdId: a.bird.bird.id,
          alertType: a.type,
          description: a.description,
          severity: a.severity.name,
          isRead: const Value(false),
        ));
        unreadKeys.add(k); // 防止本次循环内重复写入
      }
    });
  }

  /// 确认单条提醒（当天同鸟+同类型+同描述去重）
  Future<void> confirmAlert(int birdId, String alertType, String description) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final existing = await (select(alertRecords)
      ..where((t) => t.birdId.equals(birdId) &
          t.alertType.equals(alertType) &
          t.description.equals(description) &
          t.createdAt.isBiggerOrEqualValue(dayStart)))
      .getSingleOrNull();
    if (existing != null) {
      await (update(alertRecords)..where((t) => t.id.equals(existing.id)))
          .write(AlertRecordsCompanion(isRead: Value(true), updatedAt: Value(DateTime.now())));
    } else {
      await into(alertRecords).insert(AlertRecordsCompanion.insert(
        uuid: genUuid(),
        birdId: birdId,
        alertType: alertType,
        description: description,
        severity: 'warning',
        isRead: Value(true),
      ));
    }
  }

  /// 批量确认
  Future<void> confirmAllAlerts(List<AnomalyAlert> alerts) async {
    for (final a in alerts) {
      await confirmAlert(a.bird.bird.id, a.type, a.description);
    }
  }

  /// 获取今日已确认的 birdId:alertType:description 集合
  Future<Set<String>> getConfirmedAlertKeys() async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final rows = await (select(alertRecords)
      ..where((t) => t.isRead.equals(true) & t.createdAt.isBiggerOrEqualValue(dayStart)))
      .get();
    return rows.map((r) => '${r.birdId}:${r.alertType}:${r.description}').toSet();
  }

  /// 获取近 N 天内未确认的告警（去重、含鸟详情、含触发时间）
  Future<List<AnomalyAlert>> getUnconfirmedAlerts(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rows = await (select(alertRecords)
      ..where((t) => t.isRead.equals(false) & t.createdAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
    // 批量取鸟详情（单次查询），避免逐行 N+1
    final birdMap = <int, BirdWithDetails>{};
    if (rows.isNotEmpty) {
      for (final b in await getAllWithDetails()) {
        birdMap[b.bird.id] = b;
      }
    }
    // 按 (birdId, alertType, description) 去重，保留最新一条
    final alerts = <AnomalyAlert>[];
    final seen = <String>{};
    for (final r in rows) {
      final key = '${r.birdId}:${r.alertType}:${r.description}';
      if (seen.contains(key)) continue;
      seen.add(key);
      final bird = birdMap[r.birdId];
      if (bird == null) continue;
      alerts.add(AnomalyAlert(
        bird: bird,
        type: r.alertType,
        description: r.description,
        severity: r.severity == 'danger' ? AlertSeverity.danger : AlertSeverity.warning,
        createdAt: r.createdAt,
      ));
    }
    return alerts;
  }

  /// 获取近 N 天内全部告警记录（含确认状态），供全部告警列表使用
  Future<List<AlertWithStatus>> getAllAlertRecordsWithStatus(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rows = await (select(alertRecords)
      ..where((t) => t.createdAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
    // 批量取鸟详情（单次查询），避免逐行 N+1
    final birdMap = <int, BirdWithDetails>{};
    if (rows.isNotEmpty) {
      for (final b in await getAllWithDetails()) {
        birdMap[b.bird.id] = b;
      }
    }
    // 按 (birdId, alertType, description) 去重，保留最新一条
    final results = <AlertWithStatus>[];
    final seen = <String>{};
    for (final r in rows) {
      final key = '${r.birdId}:${r.alertType}:${r.description}';
      if (seen.contains(key)) continue;
      seen.add(key);
      final bird = birdMap[r.birdId];
      if (bird == null) continue;
      results.add(AlertWithStatus(
        alert: AnomalyAlert(
          bird: bird,
          type: r.alertType,
          description: r.description,
          severity: r.severity == 'danger' ? AlertSeverity.danger : AlertSeverity.warning,
          createdAt: r.createdAt,
        ),
        isConfirmed: r.isRead,
        createdAt: r.createdAt,
      ));
    }
    return results;
  }

  /// 获取近 N 天内全部告警记录的确认状态，供全部告警列表 join 用
  Future<Map<String, AlertStatusInfo>> getAlertStatusMap(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rows = await (select(alertRecords)
      ..where((t) => t.createdAt.isBiggerOrEqualValue(cutoff)))
      .get();
    final map = <String, AlertStatusInfo>{};
    for (final r in rows) {
      final key = '${r.birdId}:${r.alertType}:${r.description}';
      map[key] = AlertStatusInfo(isConfirmed: r.isRead, createdAt: r.createdAt);
    }
    return map;
  }
}

class AlertStatusInfo {
  final bool isConfirmed;
  final DateTime createdAt;
  const AlertStatusInfo({required this.isConfirmed, required this.createdAt});
}
