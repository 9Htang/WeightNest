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

  // ── Slot G: 任务派发 ──

  @override
  Future<List<PluginTaskDescriptor>> detectTasks(AppDatabase db, {int? birdId}) async {
    final descriptors = <PluginTaskDescriptor>[];
    try {
      final today = DateTime.now();

      var query = db.select(db.medications)
            ..where((t) => t.active.equals(true));
      if (birdId != null) {
        query = query..where((t) => t.birdId.equals(birdId));
      }
      final meds = await query.get();

      for (final med in meds) {
        if (today.isBefore(med.startDate)) continue;
        if (med.endDate != null && today.isAfter(med.endDate!)) continue;

        final slots = await distributedTimeSlots(med.timesPerDay);
        for (final slot in slots) {
          final dueDate = DateTime(today.year, today.month, today.day, slot.hour, slot.minute);
          descriptors.add(PluginTaskDescriptor(
            birdId: med.birdId,
            taskType: 'medication',
            dueDate: dueDate,
            label: '${med.drugName} ${med.dosage}',
            metadata: {
              'medicationId': med.id.toString(),
              'drugName': med.drugName,
              'dosage': med.dosage,
            },
          ));
        }
      }
    } catch (e) {
      debugPrint('[MedicationPlugin] detectTasks failed: $e');
    }
    return descriptors;
  }

  // ── Slot F: 告警检测 ──

  @override
  Future<List<PluginAlert>> detectAlerts(AppDatabase db, {int? birdId}) async {
    final alerts = <PluginAlert>[];
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);

      // 查询今日待完成但已超时的喂药任务
      final allMedTasks = await (db.select(db.tasks)
            ..where((t) => t.taskType.equals('medication')))
          .get();
      final missedTasks = allMedTasks.where((t) =>
          t.status == '待完成' &&
          !t.dueDate.isBefore(dayStart) &&
          t.dueDate.isBefore(now)).toList();

      for (final task in missedTasks) {
        if (birdId != null && task.birdId != birdId) continue;
        final medInfo = MedTaskInfo.fromTask(task);
        final birdRow = await (db.select(db.birds)
              ..where((b) => b.id.equals(task.birdId))
              ..limit(1))
            .getSingleOrNull();
        final birdName = birdRow?.name ?? '未知';
        alerts.add(PluginAlert(
          birdId: task.birdId,
          type: 'missed_medication',
          description: '$birdName ${medInfo.drugName} ${medInfo.timeLabel} 未按时喂药 (${medInfo.dosage})',
          severity: AlertSeverity.warning,
        ));
      }
    } catch (e) {
      debugPrint('[MedicationPlugin] detectAlerts failed: $e');
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
