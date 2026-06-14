import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../core/event_bus.dart';
import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../screens/birds/bird_detail_screen.dart';
import 'medication_screen.dart';
import 'medication_calendar.dart';
import 'medication_repository.dart';
import 'medication_config_screen.dart';
import 'medication_section.dart';

class MedicationPlugin extends FeaturePlugin {
  @override
  String get id => 'medication';

  @override
  String get displayName => '喂药';

  @override
  String get description => '药品类型、剂量、频率管理，自动生成定时喂药任务';

  @override
  IconData get icon => Icons.medication_outlined;

  @override
  IconData get selectedIcon => Icons.medication;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => {
        '/medication': (_) => MedicationScreen(db: db),
      };

  // ── Pages (Singleton + Calendar) ──

  @override
  List<PluginPageDescriptor> get pages => [
        PluginPageDescriptor(
          key: 'drug-config',
          title: '药品配置',
          icon: Icons.medical_services,
          uniqueness: PageUniqueness.singleton,
          showInSidebar: true,
          builder: (ctx) => const MedicationConfigScreen(),
        ),
        PluginPageDescriptor(
          key: 'calendar',
          title: '喂药日历',
          icon: Icons.calendar_month,
          uniqueness: PageUniqueness.none,
          showInSidebar: true,
          builder: (ctx) => MedicationCalendarView(birdId: ctx.birdId),
        ),
      ];

  @override
  Map<String, Function> get dataQueries => {
        // 其他插件可调用: registry.call('medication', 'getPlans', birdId)
        'getPlans': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return <Medication>[];
          return db.getMedicationsByBird(birdId);
        },
      };

  // ── Slot D: 日历视图 ──

  @override
  String get calendarTitle => '喂药';

  @override
  Widget? buildDayView(DateTime day, {int? birdId}) =>
      MedicationCalendarView(birdId: birdId, initialDay: day);

  // ── Task card navigation ──

  @override
  Widget? onTaskCardTap(BuildContext context, int birdId) {
    final db = pluginRegistry.db;
    if (db == null) return null;
    return _MedicationTaskDetailPage(birdId: birdId, initialPluginId: id);
  }

  // ── Slot B: 详情嵌入 ──

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
        DetailSection(
          title: '喂药计划',
          icon: Icons.medication,
          priority: 20,
          defaultExpanded: true,
          child: MedicationSection(birdId: birdId),
        ),
      ];

  // ── Plugin settings ──

  @override
  WidgetBuilder? get settingsBuilder => (_) => const MedicationConfigScreen();

  // ── Slot F: 告警检测 ──

  @override
  Future<List<PluginAlert>> detectAlerts(AppDatabase db) async {
    final alerts = <PluginAlert>[];
    try {
      final today = DateTime.now();
      final allLogs = await db.getAllTodayLogs();
      for (final log in allLogs) {
        if (!log.isDone && !log.isSkipped && log.log.scheduledTime.isBefore(today)) {
          final birdName = log.birdName ?? '未知';
          alerts.add(PluginAlert(
            birdId: log.log.birdId,
            type: 'missed_medication',
            description: '$birdName ${log.medication.drugName} ${log.timeLabel} 未按时喂药 (${log.medication.dosage})',
            severity: AlertSeverity.warning,
          ));
        }
      }
    } catch (_) {
      // 查询失败时返回空
    }
    return alerts;
  }

  @override
  void registerEvents(EventBus bus) {}
}

/// Loads bird details and shows [BirdDetailScreen] for task card tap navigation.
class _MedicationTaskDetailPage extends StatelessWidget {
  final int birdId;
  final String? initialPluginId;
  const _MedicationTaskDetailPage({required this.birdId, this.initialPluginId});

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
