import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../widgets/weight_chart.dart';
import '../../repositories/weight_repository.dart';
import '../../repositories/bird_repository.dart';
import '../../screens/weigh/weigh_grid_screen.dart';
import '../../screens/birds/bird_detail_screen.dart';
import 'weight_table.dart';
import 'weight_config_screen.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';

// ==================== 体重告警阈值常量 ====================

const double _warningDeviationPct = 10.0;
const double _dangerDeviationPct = 15.0;
const double _overdueWarningMultiplier = 1.5;
const double _overdueDangerMultiplier = 3.0;
const double _chronicTrendPct = 7.0;
const double _chickGrowthHealthyRate = 0.08;
const double _chickGrowthSlowRate = 0.03;
const double _weaningWarningDropPct = 10.0;
const double _weaningDangerDropPct = 15.0;
const int _analysisWindowDays = 90;

// ==================== 工具函数 ====================

double _logGrowth(double prev, double curr) =>
    prev > 0 && curr > 0 ? log(curr / prev) : 0;

double _normalize24h(double rate, double h) => h > 0 ? rate * (24 / h) : rate;

double _hoursBetween(DateTime a, DateTime b) =>
    b.difference(a).inMilliseconds / 3600000.0;

double _avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;

/// EWMA 序列，alpha=0.2（基线平滑）
List<double> _ewma(List<double> values, {double alpha = 0.2}) {
  if (values.isEmpty) return [];
  final r = <double>[values.first];
  for (int i = 1; i < values.length; i++) {
    r.add(values[i] * alpha + r.last * (1 - alpha));
  }
  return r;
}

int _effectiveInterval(BirdWithDetails bird) => bird.effectiveWeighIntervalDays;

// ==================== 断奶期检测 ====================

/// 判断是否处于断奶期（手动覆盖优先，否则自动检测）
/// [weights] 需按 recordedAt ASC（最早在前）
bool isWeaningPhase(BirdWithDetails bird, List<Weight> weights) {
  // 手动覆盖
  if (bird.bird.weaningOverride == true) return true;
  if (bird.bird.weaningOverride == false) return false;

  // 不在日龄窗口内
  if (bird.ageDays < bird.species.nestlingEndDays - 5 ||
      bird.ageDays > bird.species.juvenileEndDays) {
    return false;
  }

  if (weights.length < 3) return false;

  // 自动进入条件：从峰值下降 >5%，且最近 3 次中 >=2 次下降
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

  // 条件 3：体重回升 > 断奶期最低 x 1.05
  final subset = weights.skip(weights.length * 2 ~/ 3).toList();
  final weaningMin =
      subset.map((w) => w.weightG).reduce((a, b) => a < b ? a : b);
  if (latest > weaningMin * 1.05) return false;

  return true;
}

/// 判断该鸟最近一次称重是否异常（用于称重表格标记）
/// weights 按 recordedAt DESC（最新在前）
bool isLatestAbnormal(BirdWithDetails bird, List<Weight> weights) {
  if (weights.length < 2) return false;
  final latest = weights.first.weightG;

  // 断奶期 -> 峰值下降检查（reverse 为 ASC 后调用统一方法）
  final inWeaning =
      bird.growthStage == '雏鸟' &&
      isWeaningPhase(bird, weights.reversed.toList());
  if (inWeaning) {
    final peak =
        weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
    final drop = (peak - latest) / peak * 100;
    return drop > _weaningWarningDropPct;
  }

  switch (bird.growthStage) {
    case '雏鸟':
      final now = DateTime.now();
      final cutoff48h = now.subtract(const Duration(hours: 48));
      final recent =
          weights.where((w) => w.recordedAt.isAfter(cutoff48h)).toList();
      if (recent.length < 2) return false;
      final asc = recent.reversed.toList(); // DESC -> ASC
      final rates = <double>[];
      for (int i = 1; i < asc.length; i++) {
        final h = asc[i]
                .recordedAt
                .difference(asc[i - 1].recordedAt)
                .inMilliseconds /
            3600000.0;
        if (h <= 0) continue;
        if (asc[i - 1].weightG > 0 && asc[i].weightG > 0) {
          final logR = log(asc[i].weightG / asc[i - 1].weightG);
          rates.add(logR * (24 / h));
        }
      }
      if (rates.isEmpty) return false;
      final avgRate = rates.reduce((a, b) => a + b) / rates.length;
      return avgRate < _chickGrowthSlowRate;
    case '幼鸟':
    case '成鸟':
      final manualB = bird.bird.manualBaselineG;
      if (manualB != null) {
        return (latest - manualB).abs() / manualB >
            _warningDeviationPct / 100;
      }
      if (weights.length < 3) return false;
      final values = weights.reversed.map((w) => w.weightG).toList();
      double ema = values.first;
      for (int i = 1; i < values.length; i++) {
        ema = 0.2 * values[i] + 0.8 * ema;
      }
      return (latest - ema).abs() / ema > _warningDeviationPct / 100;
  }
  return false;
}

// ==================== 告警检测实现 ====================

List<PluginAlert> _weaningAlerts(BirdWithDetails bird, List<Weight> weights) {
  final peak =
      weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
  final latest = weights.last.weightG;
  final dropPct = (peak - latest) / peak * 100;

  if (dropPct > _weaningDangerDropPct) {
    return [
      PluginAlert(
        birdId: bird.bird.id,
        type: '断奶期体重下降过多',
        description:
            '从峰值 ${peak.toStringAsFixed(1)}g 下降 ${dropPct.toStringAsFixed(1)}%，超出正常范围，建议检查',
        severity: AlertSeverity.danger,
      ),
    ];
  }
  if (dropPct > _weaningWarningDropPct) {
    return [
      PluginAlert(
        birdId: bird.bird.id,
        type: '断奶期体重下降',
        description:
            '从峰值 ${peak.toStringAsFixed(1)}g 下降 ${dropPct.toStringAsFixed(1)}%，属正常范围',
        severity: AlertSeverity.warning,
      ),
    ];
  }
  return [];
}

List<PluginAlert> _chickGrowth(BirdWithDetails bird, List<Weight> weights) {
  if (weights.length < 2) return [];

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(hours: 48));
  final recent = weights
      .where(
          (w) => w.recordedAt.isAfter(cutoff.subtract(const Duration(seconds: 1))))
      .toList();
  if (recent.length < 2) return [];

  final rates = <double>[];
  for (int i = 1; i < recent.length; i++) {
    final h = _hoursBetween(recent[i - 1].recordedAt, recent[i].recordedAt);
    if (h <= 0) continue;
    final logR = _logGrowth(recent[i - 1].weightG, recent[i].weightG);
    rates.add(_normalize24h(logR, h));
  }
  if (rates.isEmpty) return [];

  final avgRate = _avg(rates);
  final alerts = <PluginAlert>[];

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

  bool hasDropAlert = false;
  if (avgRate > _chickGrowthHealthyRate) {
    // 正常
  } else if (avgRate > _chickGrowthSlowRate) {
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '增长减缓',
      description: '48h 仅增重 ${displayPct.toStringAsFixed(1)}%，增长偏慢',
      severity: AlertSeverity.warning,
    ));
  } else if (avgRate > 0) {
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '增长停滞',
      description: '48h 仅增重 ${displayPct.toStringAsFixed(1)}%，接近停滞',
      severity: AlertSeverity.danger,
    ));
  } else {
    hasDropAlert = true;
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '体重下降',
      description: '48h 下降 ${displayPct.abs().toStringAsFixed(1)}%',
      severity: AlertSeverity.danger,
    ));
  }

  // Step B：最后一对独立检查
  if (!hasDropAlert && rates.isNotEmpty) {
    final lastRate = rates.last;
    if (lastRate < -0.05) {
      final prev = recent[recent.length - 2];
      final curr = recent.last;
      final dropPct = (prev.weightG - curr.weightG) / prev.weightG * 100;
      alerts.add(PluginAlert(
        birdId: bird.bird.id,
        type: '体重下降',
        description:
            '较上次下降 ${dropPct.toStringAsFixed(1)}%（48h平均正常，近期下降值得关注）',
        severity: lastRate < -0.15 ? AlertSeverity.danger : AlertSeverity.warning,
      ));
    }
  }

  // Step C：连续下降
  if (consecDrop >= 3) {
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '连续下降',
      description: '连续 $consecDrop 次体重下降',
      severity: consecDrop >= 4 ? AlertSeverity.danger : AlertSeverity.warning,
    ));
  }

  return alerts;
}

List<PluginAlert> _baselineAlerts(BirdWithDetails bird, List<Weight> weights) {
  final alerts = <PluginAlert>[];

  final baseline = bird.bird.manualBaselineG ??
      _ewma(weights.map((w) => w.weightG).toList()).last;
  final latest = weights.last.weightG;
  final deviation = (latest - baseline) / baseline * 100;

  // 维度 A：单点偏离基线（急性）
  if (deviation.abs() > _dangerDeviationPct) {
    final dir = deviation > 0 ? '偏高' : '偏低';
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '体重异常$dir',
      description:
          '当前 ${latest.toStringAsFixed(1)}g，较基线 ${baseline.toStringAsFixed(1)}g '
          '$dir ${deviation.abs().toStringAsFixed(0)}%（${deviation > 0 ? "可能为产蛋、过肥或疾病" : "值得关注"}）',
      severity: AlertSeverity.danger,
    ));
  } else if (deviation.abs() > _warningDeviationPct) {
    final dir = deviation > 0 ? '偏高' : '偏低';
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '体重$dir',
      description:
          '当前 ${latest.toStringAsFixed(1)}g，较基线 ${baseline.toStringAsFixed(1)}g '
          '$dir ${deviation.abs().toStringAsFixed(0)}%',
      severity: AlertSeverity.warning,
    ));
  }

  // 维度 B：基线持续趋势（慢性）
  if (weights.length >= 4) {
    final values = weights.map((w) => w.weightG).toList();
    final emaSnapshots = _ewma(values);

    final recentN =
        (emaSnapshots.length / 3).ceil().clamp(2, emaSnapshots.length - 1);
    final earlyBaseline = emaSnapshots[emaSnapshots.length - 1 - recentN];
    final currentBaseline = emaSnapshots.last;
    final trend = (currentBaseline - earlyBaseline) / earlyBaseline * 100;

    if (trend < -_chronicTrendPct) {
      alerts.add(PluginAlert(
        birdId: bird.bird.id,
        type: '体重持续下降',
        description:
            '基线从 ${earlyBaseline.toStringAsFixed(1)}g 降至 '
            '${currentBaseline.toStringAsFixed(1)}g（${trend.abs().toStringAsFixed(0)}%），持续下行值得关注',
        severity: AlertSeverity.warning,
      ));
    } else if (trend > _chronicTrendPct) {
      alerts.add(PluginAlert(
        birdId: bird.bird.id,
        type: '体重持续上升',
        description:
            '基线从 ${earlyBaseline.toStringAsFixed(1)}g 升至 '
            '${currentBaseline.toStringAsFixed(1)}g（${trend.toStringAsFixed(0)}%），可能为过肥或非繁育增重',
        severity: AlertSeverity.warning,
      ));
    }
  }

  return alerts;
}

List<PluginAlert> _overdue(BirdWithDetails bird, List<Weight> weights) {
  final latest = weights.last;
  final daysSince = DateTime.now().difference(latest.recordedAt).inDays;
  final interval = _effectiveInterval(bird);

  if (interval <= 0) return [];

  if (daysSince > interval * _overdueDangerMultiplier) {
    return [
      PluginAlert(
        birdId: bird.bird.id,
        type: '超期未称重',
        description: '已 $daysSince 天未记录体重（间隔 $interval 天），严重超期',
        severity: AlertSeverity.danger,
      ),
    ];
  }
  if (daysSince > interval * _overdueWarningMultiplier) {
    return [
      PluginAlert(
        birdId: bird.bird.id,
        type: '超期未称重',
        description: '已 $daysSince 天未记录体重（间隔 $interval 天）',
        severity: AlertSeverity.warning,
      ),
    ];
  }
  return [];
}

// ==================== WeightPlugin ====================

class WeightPlugin extends FeaturePlugin {
  @override
  String get id => 'weights';

  @override
  String get displayName => '称重';

  @override
  String get description => '体重记录、趋势图表、AI 预警分析';

  @override
  IconData get icon => Icons.monitor_weight_outlined;

  @override
  IconData get selectedIcon => Icons.monitor_weight;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  @override
  List<PluginPageDescriptor> get pages => [
        PluginPageDescriptor(
          key: 'weigh',
          title: '称重录入',
          icon: Icons.monitor_weight,
          uniqueness: PageUniqueness.none,
          showInSidebar: true,
          builder: (ctx) => WeighGridScreen(
            initialRoomId: ctx.params['roomId'] as int?,
            initialBirdId: ctx.birdId,
          ),
        ),
      ];

  // ── Slot E: 首页快捷操作 ──

  @override
  List<QuickAction> get quickActions => [
        QuickAction(
          label: '快速称重',
          icon: Icons.monitor_weight,
          builder: () => const WeighGridScreen(),
        ),
      ];

  // ── Slot G: 容器称重 ──

  @override
  EnclosureWeighAction? get enclosureWeighAction => EnclosureWeighAction(
        icon: Icons.monitor_weight,
        tooltip: '称重',
        builder: (enclosureId) =>
            WeighGridScreen(initialEnclosureId: enclosureId),
      );

  // ── Slot H: 房间称重 ──

  @override
  RoomWeighAction? get roomWeighAction => RoomWeighAction(
        icon: Icons.monitor_weight,
        tooltip: '称重',
        builder: (roomId) => WeighGridScreen(initialRoomId: roomId),
      );

  // ── Plugin settings ──

  @override
  WidgetBuilder? get settingsBuilder => (_) => const WeightConfigScreen();

  // ── Task card navigation ──

  @override
  Widget? onTaskCardTap(BuildContext context, int birdId) {
    final db = pluginRegistry.db;
    if (db == null) return null;
    return _WeightTaskDetailPage(birdId: birdId, initialPluginId: id);
  }

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
        DetailSection(
          title: '体重趋势与记录',
          icon: Icons.show_chart,
          priority: 10,
          child: _WeightDetailView(birdId: birdId),
        ),
      ];

  // ── Slot G: 任务派发 ──

  @override
  Future<List<PluginTaskDescriptor>> detectTasks(AppDatabase db, {int? birdId}) async {
    final descriptors = <PluginTaskDescriptor>[];
    try {
      final today = DateTime.now();

      // Query birds — scoped to birdId if provided, otherwise all
      final List<BirdWithDetails> allBirds;
      if (birdId != null) {
        final single = await db.getWithDetails(birdId);
        allBirds = single != null ? [single] : [];
      } else {
        allBirds = await db.getAllWithDetails();
      }

      // 批量取每只鸟的最新体重（单条 SQL），避免循环内 N+1
      final latestWeightByBird = await db.getLatestByBirds(
        allBirds.map((b) => b.bird.id).toList(),
      );
      for (final bird in allBirds) {
        final ageDays = today.difference(bird.bird.birthDate).inDays;
        final intervalDays = computeEffectiveWeighInterval(
          birdOverrideDays: bird.bird.weighIntervalDays,
          species: bird.species,
          ageDays: ageDays,
        );
        if (intervalDays <= 0) continue;

        // Check last weigh date — need task if >= intervalDays has elapsed
        final lastWeigh = latestWeightByBird[bird.bird.id];

        // Compare calendar days (not exact time) — a weigh at 23:50 yesterday
        // and a login at 00:10 today are 1 calendar day apart, not 0 hours.
        final todayDay = DateTime(today.year, today.month, today.day);
        final lastWeighDay = lastWeigh == null ? null
            : DateTime(lastWeigh.recordedAt.year, lastWeigh.recordedAt.month, lastWeigh.recordedAt.day);
        final daysSinceLast = lastWeighDay == null ? null
            : todayDay.difference(lastWeighDay).inDays;
        final needsTask = lastWeigh == null ||
            daysSinceLast! >= intervalDays;

        if (needsTask) {
          descriptors.add(PluginTaskDescriptor(
            birdId: bird.bird.id,
            taskType: 'weigh',
            dueDate: todayDay, // midnight — stable dedup key across restarts
            label: '称重',
          ));
        }
      }
    } catch (e) {
      debugPrint('[WeightPlugin] detectTasks failed: $e');
    }
    return descriptors;
  }

  // ── Slot F: 告警检测 ──

  @override
  Future<List<PluginAlert>> detectAlerts(AppDatabase db, {int? birdId}) async {
    final alerts = <PluginAlert>[];

    // 加载鸟
    final List<BirdWithDetails> allBirds;
    if (birdId != null) {
      final single = await db.getWithDetails(birdId);
      allBirds = single != null ? [single] : [];
    } else {
      allBirds = await db.getAllWithDetails();
    }

    // 对每只鸟执行体重检测（批量查询，避免 N+1）
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: _analysisWindowDays));
    // 查询繁育中的鸟：繁育期间不催称重
    final activeBreedingIds = (pluginRegistry
        .call('breeding', 'getActiveBreedingBirdIds') as Set<int>?) ?? {};
    final weightsByBird = await db.getByBirdsInRange(
      allBirds.map((b) => b.bird.id).toList(),
      from: cutoff,
      to: now,
    );
    for (final bird in allBirds) {
      final weights = weightsByBird[bird.bird.id] ?? const <Weight>[];

      // 90天无体重：安全网兜底
      if (weights.isEmpty) {
        alerts.add(PluginAlert(
          birdId: bird.bird.id,
          type: '超期未称重',
          description: '超过90天未记录体重，请尽快称重',
          severity: AlertSeverity.warning,
        ));
        continue;
      }

      // 断奶期分支
      final inWeaning =
          bird.growthStage == '雏鸟' && isWeaningPhase(bird, weights);
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
      // 繁育中的鸟跳过逾期告警（故意不称重）
      if (!activeBreedingIds.contains(bird.bird.id)) {
        alerts.addAll(_overdue(bird, weights));
      }
    }

    return alerts;
  }

  @override
  void registerEvents(EventBus bus) {
    bus.on<OperationRecordedEvent>((e) {
      if (e.pluginId == 'medication' && e.actionType == 'medication_given') {
        debugPrint('[WeightPlugin] 观察到喂药事件: ${e.summary} (birdId=${e.birdId})');
      }
    });
  }
}

// ==================== 辅助 Widget ====================

class _WeightDetailView extends StatelessWidget {
  final int birdId;

  const _WeightDetailView({required this.birdId});

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) return const SizedBox.shrink();

    return FutureBuilder<List<Weight>>(
      future: db.getByBird(birdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final weights = snapshot.data ?? [];
        return Column(children: [
          WeightChartWidget(weights: weights, chartHeight: 260),
          const SizedBox(height: 12),
          WeightTable(db: db, birdId: birdId),
        ]);
      },
    );
  }
}

/// Loads bird details and shows [BirdDetailScreen] for task card tap navigation.
class _WeightTaskDetailPage extends StatelessWidget {
  final int birdId;
  final String? initialPluginId;
  const _WeightTaskDetailPage({required this.birdId, this.initialPluginId});

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('详情')),
        body: const Center(child: Text('数据库未初始化')),
      );
    }
    return FutureBuilder<BirdWithDetails?>(
      future: db.getWithDetails(birdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final bird = snapshot.data;
        if (bird == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('详情')),
            body: const Center(child: Text('未找到该鹦鹉')),
          );
        }
        return BirdDetailScreen(bird: bird, initialPluginId: initialPluginId);
      },
    );
  }
}
