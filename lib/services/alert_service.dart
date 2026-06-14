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
        alerts.add(AnomalyAlert(
          bird: bird,
          type: '超期未称重',
          description: '超过90天未记录体重',
          severity: AlertSeverity.danger,
        ));
        continue;
      }

      // 断奶期分支：进入断奶则仅用断奶逻辑
      final inWeaning = bird.growthStage == '雏鸟' && _isWeaningPhase(bird, weights);
      if (inWeaning) {
        alerts.addAll(_weaningAlerts(bird, weights));
      } else {
        switch (bird.growthStage) {
          case '雏鸟':
            alerts.addAll(_chickGrowth(bird, weights));
            break;
          case '幼鸟':
            alerts.addAll(_baselineAlerts(bird, weights));
            break;
          case '成鸟':
            alerts.addAll(_baselineAlerts(bird, weights));
            break;
        }
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

  /// 计算 EWMA 序列，α=0.2（基线平滑）
  List<double> _ewma(List<double> values, {double alpha = 0.2}) {
    if (values.isEmpty) return [];
    final r = <double>[values.first];
    for (int i = 1; i < values.length; i++) {
      r.add(values[i] * alpha + r.last * (1 - alpha));
    }
    return r;
  }

  /// 获取鸟的有效称重间隔（天）
  int _effectiveInterval(BirdWithDetails bird) {
    if (bird.bird.weighIntervalDays != null) return bird.bird.weighIntervalDays!;
    switch (bird.growthStage) {
      case '雏鸟':
        return bird.species.nestlingWeighIntervalDays;
      case '幼鸟':
        return bird.species.juvenileWeighIntervalDays;
      default:
        return bird.species.adultWeighIntervalDays;
    }
  }

  // ==================== 断奶期检测 ====================

  /// 判断是否处于断奶期（手动覆盖优先，否则自动检测）
  bool _isWeaningPhase(BirdWithDetails bird, List<Weight> weights) {
    // 手动覆盖
    if (bird.bird.weaningOverride == true) return true;
    if (bird.bird.weaningOverride == false) return false;

    // 不在日龄窗口内
    if (bird.ageDays < bird.species.nestlingEndDays - 5 ||
        bird.ageDays > bird.species.juvenileEndDays) {
      return false;
    }

    if (weights.length < 3) return false;

    // 自动进入条件：从峰值下降 >5%，且最近 3 次中 ≥2 次下降
    final peak = weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
    final latest = weights.last.weightG;
    if (latest >= peak * 0.95) return false; // 尚未明显下降

    int recentDrops = 0;
    for (int i = weights.length - 1; i > 0 && i > weights.length - 4; i--) {
      if (weights[i].weightG < weights[i - 1].weightG) recentDrops++;
    }
    if (recentDrops < 2) return false;

    // 自动退出条件
    // 条件 1：超龄强制退出
    if (bird.ageDays > bird.species.juvenileEndDays + 10) return false;

    // 条件 2：最近 3 次体重企稳（波动 <3%，且末次不低于第 3 次）
    if (weights.length >= 3) {
      final last3 = weights.sublist(weights.length - 3);
      final vals = last3.map((w) => w.weightG).toList();
      final avg3 = _avg(vals);
      final range = vals.reduce((a, b) => a > b ? a : b) -
          vals.reduce((a, b) => a < b ? a : b);
      if (range / avg3 * 100 < 3 && vals.last >= vals.first) return false;
    }

    // 条件 3：体重回升 > 断奶期最低 × 1.05
    // 断奶期内最低体重（取后 1/3 历史中的最低值，粗略近似）
    final subset = weights.skip(weights.length * 2 ~/ 3).toList();
    final weaningMin =
        subset.map((w) => w.weightG).reduce((a, b) => a < b ? a : b);
    if (latest > weaningMin * 1.05) return false;

    return true;
  }

  /// 断奶期告警：峰值→当前百分比
  List<AnomalyAlert> _weaningAlerts(BirdWithDetails bird, List<Weight> weights) {
    final peak = weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
    final latest = weights.last.weightG;
    final dropPct = (peak - latest) / peak * 100;

    if (dropPct > 15) {
      return [AnomalyAlert(
        bird: bird,
        type: '断奶期体重下降过多',
        description: '从峰值 ${peak.toStringAsFixed(1)}g 下降 ${dropPct.toStringAsFixed(1)}%，超出正常范围，建议检查',
        severity: AlertSeverity.danger,
      )];
    }
    if (dropPct > 10) {
      return [AnomalyAlert(
        bird: bird,
        type: '断奶期体重下降',
        description: '从峰值 ${peak.toStringAsFixed(1)}g 下降 ${dropPct.toStringAsFixed(1)}%，属正常范围',
        severity: AlertSeverity.warning,
      )];
    }
    // dropPct <= 10%：断奶正常进行中，不告警
    return [];
  }

  // ==================== 雏鸟算法 ====================
  // 核心：48h 滑动窗口 Log 增长率 + 最后一对独立检查

  List<AnomalyAlert> _chickGrowth(BirdWithDetails bird, List<Weight> weights) {
    if (weights.length < 2) return [];

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 48));
    final recent = weights
        .where((w) => w.recordedAt
            .isAfter(cutoff.subtract(const Duration(seconds: 1))))
        .toList();
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

    // 连续下降
    int consecDrop = 0;
    for (int i = 1; i < weights.length; i++) {
      if (weights[i].weightG < weights[i - 1].weightG) {
        consecDrop++;
      } else {
        consecDrop = 0;
      }
    }

    final firstW = recent.first.weightG;
    final lastW = recent.last.weightG;
    final displayPct = (lastW - firstW) / firstW * 100;

    // Step A：48h 平均趋势
    bool hasDropAlert = false;
    if (avgRate > 0.08) {
      // 正常
    } else if (avgRate > 0.03) {
      alerts.add(AnomalyAlert(
          bird: bird,
          type: '增长减缓',
          description: '48h 仅增重 ${displayPct.toStringAsFixed(1)}%，增长偏慢',
          severity: AlertSeverity.warning));
    } else if (avgRate > 0) {
      alerts.add(AnomalyAlert(
          bird: bird,
          type: '增长停滞',
          description: '48h 仅增重 ${displayPct.toStringAsFixed(1)}%，接近停滞',
          severity: AlertSeverity.danger));
    } else {
      hasDropAlert = true;
      alerts.add(AnomalyAlert(
          bird: bird,
          type: '体重下降',
          description: '48h 下降 ${displayPct.abs().toStringAsFixed(1)}%',
          severity: AlertSeverity.danger));
    }

    // Step B：最后一对独立检查（防止平均稀释）
    if (!hasDropAlert && rates.isNotEmpty) {
      final lastRate = rates.last;
      if (lastRate < -0.05) {
        final prev = recent[recent.length - 2];
        final curr = recent.last;
        final dropPct =
            (prev.weightG - curr.weightG) / prev.weightG * 100;
        alerts.add(AnomalyAlert(
          bird: bird,
          type: '体重下降',
          description: '较上次下降 ${dropPct.toStringAsFixed(1)}%（48h平均正常，近期下降值得关注）',
          severity:
              lastRate < -0.15 ? AlertSeverity.danger : AlertSeverity.warning,
        ));
      }
    }

    // Step C：连续下降
    if (consecDrop >= 3) {
      alerts.add(AnomalyAlert(
          bird: bird,
          type: '连续下降',
          description: '连续 $consecDrop 次体重下降',
          severity:
              consecDrop >= 4 ? AlertSeverity.danger : AlertSeverity.warning));
    }

    return alerts;
  }

  // ==================== 幼鸟 / 成鸟：基线检测 ====================
  // 核心：EWMA 个体基线 + 双维度（单点偏离 + 持续趋势）

  List<AnomalyAlert> _baselineAlerts(BirdWithDetails bird, List<Weight> weights) {
    final alerts = <AnomalyAlert>[];

    // 获取基线：手动设定优先，否则 EWMA 自动推断
    final baseline = bird.bird.manualBaselineG ??
        _ewma(weights.map((w) => w.weightG).toList()).last;
    final latest = weights.last.weightG;
    final deviation = (latest - baseline) / baseline * 100; // + 偏高，- 偏低

    // 维度 A：单点偏离基线（急性）
    if (deviation.abs() > 15) {
      final dir = deviation > 0 ? '偏高' : '偏低';
      alerts.add(AnomalyAlert(
        bird: bird,
        type: '体重异常$dir',
        description: '当前 ${latest.toStringAsFixed(1)}g，较基线 ${baseline.toStringAsFixed(1)}g '
            '$dir ${deviation.abs().toStringAsFixed(0)}%（${deviation > 0 ? "可能为产蛋、过肥或疾病" : "值得关注"}）',
        severity: AlertSeverity.danger,
      ));
    } else if (deviation.abs() > 10) {
      final dir = deviation > 0 ? '偏高' : '偏低';
      alerts.add(AnomalyAlert(
        bird: bird,
        type: '体重$dir',
        description: '当前 ${latest.toStringAsFixed(1)}g，较基线 ${baseline.toStringAsFixed(1)}g '
            '${dir} ${deviation.abs().toStringAsFixed(0)}%',
        severity: AlertSeverity.warning,
      ));
    }

    // 维度 B：基线持续趋势（慢性）
    // 将权重分成前后两半，比较各自 EWMA 终值变化幅度
    if (weights.length >= 4) {
      final values = weights.map((w) => w.weightG).toList();
      final emaSnapshots = _ewma(values);

      // 取最近约 1/3 与前 1/3 的 EWMA 对比
      final recentN = (emaSnapshots.length / 3).ceil().clamp(2, emaSnapshots.length - 1);
      final earlyBaseline = emaSnapshots[emaSnapshots.length - 1 - recentN];
      final currentBaseline = emaSnapshots.last;
      final trend =
          (currentBaseline - earlyBaseline) / earlyBaseline * 100;

      if (trend < -7) {
        alerts.add(AnomalyAlert(
          bird: bird,
          type: '体重持续下降',
          description: '基线从 ${earlyBaseline.toStringAsFixed(1)}g 降至 '
              '${currentBaseline.toStringAsFixed(1)}g（${trend.abs().toStringAsFixed(0)}%），持续下行值得关注',
          severity: AlertSeverity.warning,
        ));
      } else if (trend > 7) {
        alerts.add(AnomalyAlert(
          bird: bird,
          type: '体重持续上升',
          description: '基线从 ${earlyBaseline.toStringAsFixed(1)}g 升至 '
              '${currentBaseline.toStringAsFixed(1)}g（${trend.toStringAsFixed(0)}%），可能为过肥或非繁育增重',
          severity: AlertSeverity.warning,
        ));
      }
    }

    return alerts;
  }

  // ==================== 通用：超期未称重 ====================

  List<AnomalyAlert> _overdue(BirdWithDetails bird, List<Weight> weights) {
    final latest = weights.last;
    final daysSince = DateTime.now().difference(latest.recordedAt).inDays;
    final interval = _effectiveInterval(bird);

    // 超过间隔 3 倍 → danger
    if (daysSince > interval * 3) {
      return [AnomalyAlert(
        bird: bird,
        type: '超期未称重',
        description: '已 $daysSince 天未记录体重（间隔 ${interval}天），严重超期',
        severity: AlertSeverity.danger,
      )];
    }
    // 超过间隔 1.5 倍 → warning
    if (daysSince > interval * 1.5) {
      return [AnomalyAlert(
        bird: bird,
        type: '超期未称重',
        description: '已 $daysSince 天未记录体重（间隔 ${interval}天）',
        severity: AlertSeverity.warning,
      )];
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
