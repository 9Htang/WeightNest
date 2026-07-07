import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
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
import 'weight_math.dart';
import 'weight_stage_mapper.dart';
export 'weight_math.dart'; // ponytail: re-export so existing importers don't break
import '../../services/work_hours_config.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';

// ==================== 告警检测实现 ====================

List<PluginAlert> _weaningAlerts(BirdWithDetails bird, List<Weight> weights) {
  final peak = weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
  final latest = weights.last.weightG;
  final dropPct = (peak - latest) / peak * 100;

  if (dropPct > weaningDangerDropPct) {
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
  if (dropPct > weaningWarningDropPct) {
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

  final now = AppClock.now;
  final cutoff = now.subtract(const Duration(hours: 48));
  final recent = weights
      .where((w) =>
          w.recordedAt.isAfter(cutoff.subtract(const Duration(seconds: 1))))
      .toList();
  if (recent.length < 2) return [];

  final rates = <double>[];
  for (int i = 1; i < recent.length; i++) {
    final h = hoursBetween(recent[i - 1].recordedAt, recent[i].recordedAt);
    if (h <= 0) continue;
    final logR = logGrowth(recent[i - 1].weightG, recent[i].weightG);
    rates.add(normalize24h(logR, h));
  }
  if (rates.isEmpty) return [];

  final avgRate = avg(rates);
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
  if (avgRate > chickGrowthHealthyRate) {
    // 正常
  } else if (avgRate > chickGrowthSlowRate) {
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
        description: '较上次下降 ${dropPct.toStringAsFixed(1)}%（48h平均正常，近期下降值得关注）',
        severity:
            lastRate < -0.15 ? AlertSeverity.danger : AlertSeverity.warning,
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
      ewma(weights.map((w) => w.weightG).toList()).last;
  final latest = weights.last.weightG;
  final deviation = (latest - baseline) / baseline * 100;

  // 维度 A：单点偏离基线（急性）
  if (deviation.abs() > dangerDeviationPct) {
    final dir = deviation > 0 ? '偏高' : '偏低';
    alerts.add(PluginAlert(
      birdId: bird.bird.id,
      type: '体重异常$dir',
      description:
          '当前 ${latest.toStringAsFixed(1)}g，较基线 ${baseline.toStringAsFixed(1)}g '
          '$dir ${deviation.abs().toStringAsFixed(0)}%（${deviation > 0 ? "可能为产蛋、过肥或疾病" : "值得关注"}）',
      severity: AlertSeverity.danger,
    ));
  } else if (deviation.abs() > warningDeviationPct) {
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
    final emaSnapshots = ewma(values);

    final recentN =
        (emaSnapshots.length / 3).ceil().clamp(2, emaSnapshots.length - 1);
    final earlyBaseline = emaSnapshots[emaSnapshots.length - 1 - recentN];
    final currentBaseline = emaSnapshots.last;
    final trend = (currentBaseline - earlyBaseline) / earlyBaseline * 100;

    if (trend < -chronicTrendPct) {
      alerts.add(PluginAlert(
        birdId: bird.bird.id,
        type: '体重持续下降',
        description: '基线从 ${earlyBaseline.toStringAsFixed(1)}g 降至 '
            '${currentBaseline.toStringAsFixed(1)}g（${trend.abs().toStringAsFixed(0)}%），持续下行值得关注',
        severity: AlertSeverity.warning,
      ));
    } else if (trend > chronicTrendPct) {
      alerts.add(PluginAlert(
        birdId: bird.bird.id,
        type: '体重持续上升',
        description: '基线从 ${earlyBaseline.toStringAsFixed(1)}g 升至 '
            '${currentBaseline.toStringAsFixed(1)}g（${trend.toStringAsFixed(0)}%），可能为过肥或非繁育增重',
        severity: AlertSeverity.warning,
      ));
    }
  }

  return alerts;
}

List<PluginAlert> _overdue(BirdWithDetails bird, List<Weight> weights) {
  final latest = weights.last;
  final daysSince = AppClock.now.difference(latest.recordedAt).inDays;
  final interval = effectiveInterval(bird);

  if (interval <= 0) return [];

  if (daysSince > interval * overdueDangerMultiplier) {
    return [
      PluginAlert(
        birdId: bird.bird.id,
        type: '超期未称重',
        description: '已 $daysSince 天未记录体重（间隔 $interval 天），严重超期',
        severity: AlertSeverity.danger,
      ),
    ];
  }
  if (daysSince > interval * overdueWarningMultiplier) {
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
  Future<List<PluginTaskDescriptor>> detectTasks(AppDatabase db,
      {int? birdId}) async {
    final descriptors = <PluginTaskDescriptor>[];
    try {
      final today = AppClock.now;

      // 时间闸门：每日批量生成时，未到 taskReadyTime 不生成
      WorkHoursConfig? wh;
      if (birdId == null) {
        wh = await WorkHoursConfig.load();
        final ready = wh.taskReadyTime;
        final todayReady = DateTime(
            today.year, today.month, today.day, ready.hour, ready.minute);
        if (AppClock.now.isBefore(todayReady)) return [];
      }

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
        final intervalDays = computeEffectiveWeighInterval(
          birdOverrideDays: bird.bird.weighIntervalDays,
          species: bird.species,
          stage: bird.physioStage,
        );
        if (intervalDays <= 0) continue;

        // Check last weigh date — need task if >= intervalDays has elapsed
        final lastWeigh = latestWeightByBird[bird.bird.id];

        // Compare calendar days (not exact time) — a weigh at 23:50 yesterday
        // and a login at 00:10 today are 1 calendar day apart, not 0 hours.
        final todayDay = DateTime(today.year, today.month, today.day);
        final lastWeighDay = lastWeigh == null
            ? null
            : DateTime(lastWeigh.recordedAt.year, lastWeigh.recordedAt.month,
                lastWeigh.recordedAt.day);
        final daysSinceLast = lastWeighDay == null
            ? null
            : todayDay.difference(lastWeighDay).inDays;
        final needsTask = lastWeigh == null || daysSinceLast! >= intervalDays;

        if (needsTask) {
          // 确保已加载工作时段配置（birdId != null 路径未经过闸门）
          wh ??= await WorkHoursConfig.load();
          final ready = wh.taskReadyTime; // TimeOfDay
          final todayReady = DateTime(
              today.year, today.month, today.day, ready.hour, ready.minute);
          // deadline = 次日 taskReadyTime
          final tomorrow = today.add(const Duration(days: 1));
          final tomorrowReady = DateTime(tomorrow.year, tomorrow.month,
              tomorrow.day, ready.hour, ready.minute);

          descriptors.add(PluginTaskDescriptor(
            birdId: bird.bird.id,
            taskType: 'weigh',
            dueDate: todayReady,
            deadline: tomorrowReady,
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
    final now = AppClock.now;
    final cutoff = now.subtract(Duration(days: analysisWindowDays));
    // 查询繁育中的鸟：繁育期间不催称重
    final activeBreedingIds = (pluginRegistry.call(
            'breeding', 'getActiveBreedingBirdIds') as Set<int>?) ??
        {};
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
      final stage = bird.physioStage;
      final strategy = alertStrategyOf(stage);
      final inWeaning = strategy == WeightAlertStrategy.weaning &&
          isWeaningPhase(bird, weights);
      if (inWeaning) {
        alerts.addAll(_weaningAlerts(bird, weights));
      } else {
        switch (strategy) {
          case WeightAlertStrategy.growth:
            alerts.addAll(_chickGrowth(bird, weights));
            break;
          case WeightAlertStrategy.baseline:
          case WeightAlertStrategy.weaning:
            // weaning 已在上面处理；baseline 覆盖亚成体/成鸟/繁殖/换羽
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
      // 体重记录后通知 stage 插件重算断奶期（仅重算 auto 来源的记录）
      if (e.pluginId == 'weights' &&
          e.actionType == 'weight_recorded' &&
          e.birdId != null) {
        pluginRegistry.call('stage', 'recomputeIfAuto', e.birdId);
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
          // 复用同一份 weights，避免 WeightTable 内部再次 getByBird(birdId)
          WeightTable(weights: weights),
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
