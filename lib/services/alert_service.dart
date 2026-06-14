import 'dart:math';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../core/plugin.dart';
import '../core/plugin_registry.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import '../utils/uuid.dart';

class AnomalyAlert {
  final BirdWithDetails bird;
  final String type;
  final String description;
  final AlertSeverity severity;
  AnomalyAlert({required this.bird, required this.type, required this.description, required this.severity});
}

class AlertService {
  final AppDatabase _db;
  AlertService(this._db);

  /// 检测所有异常——聚合插件告警 + 体重检测
  Future<List<AnomalyAlert>> detectAll() async {
    final alerts = <AnomalyAlert>[];

    // 预加载所有鸟（插件告警 + 体重检测共用）
    final allBirds = await _db.getAllWithDetails();

    // 1. 遍历插件告警（喂药漏喂等）
    for (final plugin in pluginRegistry.enabledPlugins) {
      try {
        final pluginAlerts = await plugin.detectAlerts(_db);
        for (final pa in pluginAlerts) {
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
            ));
          }
        }
      } catch (_) {
        // 单个插件告警失败不影响整体
      }
    }

    // 2. 体重异常检测（仅取最近90天数据，覆盖所有算法窗口）
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    for (final bird in allBirds) {
      final weights = await _db.getByBirdInRange(
        bird.bird.id,
        from: cutoff,
        to: DateTime.now(),
      );

      if (weights.isEmpty) {
        // 90 天以上无记录 → 长期未称重
        alerts.add(AnomalyAlert(
          bird: bird,
          type: '超期未称重',
          description: '超过90天未记录体重',
          severity: AlertSeverity.danger,
        ));
        continue;
      }
      // weights 已按 recorded_at ASC 排序（查询中 ORDER BY）

      switch (bird.growthStage) {
        case '雏鸟':
          alerts.addAll(_chickGrowth(bird, weights));
          break;
        case '幼鸟':
          alerts.addAll(_juvenileStability(bird, weights));
          break;
        case '成鸟':
          alerts.addAll(_adultAnomaly(bird, weights));
          break;
      }
      alerts.addAll(_overdue(bird, weights));
    }
    return alerts;
  }

  // ==================== 工具函数 ====================

  double _logGrowth(double prev, double curr) =>
      prev > 0 && curr > 0 ? log(curr / prev) : 0;

  double _normalize24h(double rate, double h) => h > 0 ? rate * (24 / h) : rate;

  double _hoursBetween(DateTime a, DateTime b) =>
      b.difference(a).inMilliseconds / 3600000.0;

  double _avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  double _stdDev(List<double> v) {
    if (v.length < 2) return 0;
    final a = _avg(v);
    return sqrt(v.map((x) => pow(x - a, 2)).reduce((a, b) => a + b) / v.length);
  }

  List<double> _ema(List<double> values, {double alpha = 0.3}) {
    if (values.isEmpty) return [];
    final r = <double>[values.first];
    for (int i = 1; i < values.length; i++) {
      r.add(values[i] * alpha + r.last * (1 - alpha));
    }
    return r;
  }

  // ==================== 雏鸟算法 ====================
  // 核心：48h 滑动窗口 Log 增长率

  List<AnomalyAlert> _chickGrowth(BirdWithDetails bird, List<Weight> weights) {
    if (weights.length < 2) return [];

    // 取最近 48h 内的所有记录，计算平均 Log 增长率
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 48));
    final recent = weights.where((w) => w.recordedAt.isAfter(cutoff.subtract(const Duration(seconds: 1)))).toList();
    if (recent.length < 2) return [];

    // 计算每对相邻记录的时间标准化 Log 增长率
    final rates = <double>[];
    for (int i = 1; i < recent.length; i++) {
      final h = _hoursBetween(recent[i - 1].recordedAt, recent[i].recordedAt);
      if (h <= 0) continue;
      final logR = _logGrowth(recent[i - 1].weightG, recent[i].weightG);
      rates.add(_normalize24h(logR, h));
    }
    if (rates.isEmpty) return [];

    final avgRate = _avg(rates);
    final alerts = <AnomalyAlert>[];

    // 检查连续下降次数
    int consecDrop = 0;
    for (int i = 1; i < weights.length; i++) {
      if (weights[i].weightG < weights[i - 1].weightG) {
        consecDrop++;
      } else {
        consecDrop = 0;
      }
    }

    // 48h 直观体重变化百分比（仅用于展示）
    final firstW = recent.first.weightG;
    final lastW = recent.last.weightG;
    final displayPct = (lastW - firstW) / firstW * 100;

    if (avgRate > 0.08) {
      // 正常
    } else if (avgRate > 0.03) {
      alerts.add(AnomalyAlert(bird: bird, type: '增长减缓',
        description: '48h 仅增重 ${displayPct.toStringAsFixed(1)}%，增长偏慢',
        severity: AlertSeverity.warning));
    } else if (avgRate > 0) {
      alerts.add(AnomalyAlert(bird: bird, type: '增长停滞',
        description: '48h 仅增重 ${displayPct.toStringAsFixed(1)}%，接近停滞',
        severity: AlertSeverity.danger));
    } else {
      alerts.add(AnomalyAlert(bird: bird, type: '体重下降',
        description: '48h 下降 ${displayPct.abs().toStringAsFixed(1)}%',
        severity: AlertSeverity.danger));
    }

    if (consecDrop >= 3) {
      alerts.add(AnomalyAlert(bird: bird, type: '连续下降',
        description: '连续 $consecDrop 次体重下降',
        severity: consecDrop >= 4 ? AlertSeverity.danger : AlertSeverity.warning));
    }

    return alerts;
  }

  // ==================== 幼鸟算法 ====================
  // 核心：7日 EMA 趋势 + 波动率 + 急性下降

  List<AnomalyAlert> _juvenileStability(BirdWithDetails bird, List<Weight> weights) {
    if (weights.length < 3) return [];
    final alerts = <AnomalyAlert>[];

    // ===== 7日 EMA 趋势 =====
    final now = DateTime.now();
    final cutoff7d = now.subtract(const Duration(days: 7));
    final recent7d = weights.where((w) => w.recordedAt.isAfter(cutoff7d.subtract(const Duration(seconds: 1)))).toList();
    
    if (recent7d.length >= 3) {
      final values = recent7d.map((w) => w.weightG).toList().cast<double>();
      final ema = _ema(values);
      final trendPct = (ema.last - ema.first) / ema.first * 100;
      
      if (trendPct < -5) {
        alerts.add(AnomalyAlert(bird: bird, type: '慢性下降',
          description: '近7日下降 ${trendPct.abs().toStringAsFixed(1)}%',
          severity: trendPct < -8 ? AlertSeverity.danger : AlertSeverity.warning));
      }

      // 波动率
      final std = _stdDev(values);
      final avgV = _avg(values);
      final volatility = std / avgV * 100;
      if (volatility > 8) {
        alerts.add(AnomalyAlert(bird: bird, type: '波动异常',
          description: '近7日波动 ${volatility.toStringAsFixed(0)}%',
          severity: volatility > 12 ? AlertSeverity.danger : AlertSeverity.warning));
      }
    }

    // ===== 24h 急性下降 =====
    if (weights.length >= 2) {
      final latest = weights.last;
      final prev = weights[weights.length - 2];
      final h = _hoursBetween(prev.recordedAt, latest.recordedAt);
      if (h > 0) {
        final dropPct = (prev.weightG - latest.weightG) / prev.weightG * 100;
        final normDrop = _normalize24h(dropPct / 100, h) * 100;
        if (normDrop > 8) {
          alerts.add(AnomalyAlert(bird: bird, type: '急性下降',
            description: '较上次下降 ${dropPct.toStringAsFixed(1)}%',
            severity: AlertSeverity.danger));
        }
      }
    }

    // ===== 连续下降 =====
    int consec = 0;
    for (int i = 1; i < weights.length; i++) {
      if (weights[i].weightG < weights[i - 1].weightG) { consec++; }
      else { consec = 0; }
    }
    if (consec >= 3) {
      alerts.add(AnomalyAlert(bird: bird, type: '连续下降',
        description: '连续 $consec 次体重下降',
        severity: AlertSeverity.warning));
    }

    return alerts;
  }

  // ==================== 成鸟算法 ====================
  // 核心：绝对值比较 + 连续下降检测

  List<AnomalyAlert> _adultAnomaly(BirdWithDetails bird, List<Weight> weights) {
    if (weights.length < 3) return [];
    final alerts = <AnomalyAlert>[];

    // 连续下降检测
    int consec = 0;
    for (int i = 1; i < weights.length; i++) {
      if (weights[i].weightG < weights[i - 1].weightG) { consec++; }
      else { consec = 0; }
    }

    if (consec >= 3) {
      final last3 = weights.sublist(weights.length - 3);
      final oldW = last3.first.weightG;
      final newW = last3.last.weightG;
      final dropPct = (oldW - newW) / oldW * 100;
      alerts.add(AnomalyAlert(bird: bird, type: '体重下降',
        description: '连续 $consec 次下降，${oldW.toStringAsFixed(1)}g→${newW.toStringAsFixed(1)}g (-${dropPct.toStringAsFixed(0)}%)',
        severity: dropPct > 10 ? AlertSeverity.danger : AlertSeverity.warning));
    }

    // 30日趋势（简单线性判断）
    final now = DateTime.now();
    final cutoff30 = now.subtract(const Duration(days: 30));
    final recent30 = weights.where((w) => w.recordedAt.isAfter(cutoff30.subtract(const Duration(seconds: 1)))).toList();
    if (recent30.length >= 4) {
      final values30 = recent30.map((w) => w.weightG).toList().cast<double>();
      final ema30 = _ema(values30, alpha: 0.15);
      final trend30 = (ema30.last - ema30.first) / ema30.first * 100;
      if (trend30 < -10) {
        alerts.add(AnomalyAlert(bird: bird, type: '长期下降趋势',
          description: '近30日下降 ${trend30.abs().toStringAsFixed(0)}%',
          severity: AlertSeverity.danger));
      }
    }

    return alerts;
  }

  // ==================== 通用：超期未称重 ====================

  List<AnomalyAlert> _overdue(BirdWithDetails bird, List<Weight> weights) {
    final latest = weights.last;
    final daysSince = DateTime.now().difference(latest.recordedAt).inDays;
    if (daysSince > 7) {
      return [AnomalyAlert(bird: bird, type: '超期未称重',
        description: '已 $daysSince 天未记录体重',
        severity: daysSince > 14 ? AlertSeverity.danger : AlertSeverity.warning)];
    }
    return [];
  }
}

/// 异常提醒确认持久化
extension AlertRepository on AppDatabase {
  /// 持久化新检测到的异常（isRead = false），供首页横幅查询
  /// 同一天同一鸟+同一类型只保留一条未读记录
  Future<void> upsertUnreadAlerts(List<AnomalyAlert> alerts) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    for (final a in alerts) {
      final existing = await (select(alertRecords)
        ..where((t) => t.birdId.equals(a.bird.bird.id) &
            t.alertType.equals(a.type) &
            t.createdAt.isBiggerOrEqualValue(dayStart)))
        .getSingleOrNull();
      if (existing == null) {
        await into(alertRecords).insert(AlertRecordsCompanion.insert(
          uuid: genUuid(),
          birdId: a.bird.bird.id,
          alertType: a.type,
          description: a.description,
          isRead: const Value(false),
        ));
      }
      // 已存在则保留当前 isRead 状态（不覆盖用户已确认的记录）
    }
  }

  /// 确认单条提醒（当天同鸟+同类型去重）
  Future<void> confirmAlert(int birdId, String alertType, String description) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final existing = await (select(alertRecords)
      ..where((t) => t.birdId.equals(birdId) &
          t.alertType.equals(alertType) &
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

  /// 获取今日已确认的 birdId:alertType 集合
  Future<Set<String>> getConfirmedAlertKeys() async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final rows = await (select(alertRecords)
      ..where((t) => t.isRead.equals(true) & t.createdAt.isBiggerOrEqualValue(dayStart)))
      .get();
    return rows.map((r) => '${r.birdId}:${r.alertType}').toSet();
  }
}
