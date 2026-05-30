import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../core/event_bus.dart';
import '../../database/database.dart';
import 'medication_screen.dart';
import 'medication_calendar.dart';
import 'medication_repository.dart';
import 'medication_routes.dart';

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

  @override
  shelf.Router? serverRoutes(AppDatabase db) => createMedicationRoutes(db);

  // ── Pages (Singleton + Calendar) ──

  @override
  List<PluginPageDescriptor> get pages => [
        PluginPageDescriptor(
          key: 'drug-config',
          title: '药品配置',
          icon: Icons.medical_services,
          uniqueness: PageUniqueness.singleton,
          showInSidebar: true,
          builder: (ctx) => const _DrugConfigPage(),
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

  // ── Slot B: 详情嵌入 ──

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
        DetailSection(
          title: '喂药计划',
          icon: Icons.medication,
          priority: 20,
          defaultExpanded: false,
          child: _MedicationDetailView(birdId: birdId),
        ),
      ];

  @override
  void registerEvents(EventBus bus) {}
}

class _MedicationDetailView extends StatefulWidget {
  final int birdId;
  const _MedicationDetailView({required this.birdId});
  @override
  State<_MedicationDetailView> createState() => _MedicationDetailViewState();
}

class _MedicationDetailViewState extends State<_MedicationDetailView> {
  int _refreshKey = 0;

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) return const SizedBox.shrink();

    return FutureBuilder<List<MedicationLogData>>(
      key: ValueKey(_refreshKey),
      future: db.getTodayLogs(widget.birdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return _buildEmpty(context);
        }
        return _buildTimeline(context, logs, db, _reload);
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(Icons.medication_outlined, size: 32, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text('今天没有喂药任务', style: TextStyle(color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildTimeline(BuildContext context, List<MedicationLogData> logs, AppDatabase db, VoidCallback reload) {
    final grouped = <String, List<MedicationLogData>>{};
    for (final l in logs) {
      grouped.putIfAbsent(l.medication.drugName, () => []).add(l);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final drug = entry.key;
        final items = entry.value;
        final doneCount = items.where((l) => l.isDone).length;
        final allDone = doneCount == items.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: allDone ? Colors.green.shade200 : Colors.orange.shade200),
            color: allDone ? Colors.green.shade50 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(allDone ? Icons.check_circle : Icons.access_time,
                    size: 16, color: allDone ? Colors.green : Colors.orange),
                const SizedBox(width: 6),
                Text(drug,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: allDone ? Colors.green.shade800 : null)),
                const Spacer(),
                Text('${items.first.medication.dosage}  ·  ${items.first.medication.drugType}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: items.map((l) {
                final isLate = !l.isDone && !l.isSkipped && l.log.scheduledTime.isBefore(DateTime.now());
                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: l.isDone || l.isSkipped ? null : () async {
                    await db.giveMedication(l.log.id);
                    reload();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: l.isDone ? Colors.green.shade100
                          : l.isSkipped ? Colors.grey.shade200
                          : isLate ? Colors.red.shade50
                          : Colors.blue.shade50,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        l.isDone ? Icons.check : l.isSkipped ? Icons.close : Icons.schedule,
                        size: 12,
                        color: l.isDone ? Colors.green : l.isSkipped ? Colors.grey : isLate ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(l.timeLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                              color: l.isDone ? Colors.green.shade800
                                  : l.isSkipped ? Colors.grey
                                  : isLate ? Colors.red.shade700
                                  : Colors.blue.shade800)),
                    ]),
                  ),
                );
              }).toList()),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Drug Config Page (Singleton) ──

class _DrugConfigPage extends StatefulWidget {
  const _DrugConfigPage();

  @override
  State<_DrugConfigPage> createState() => _DrugConfigPageState();
}

class _DrugConfigPageState extends State<_DrugConfigPage> {
  String _drugName = '';
  String _dosage = '';
  double _coefficient = 0.001;
  String _drugType = '驱虫';
  int _timesPerDay = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('药品配置'),
        actions: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text('剂量 = 体重(g) × 系数',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('添加药品', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: '药品名称', hintText: '伊维菌素', border: OutlineInputBorder()),
                    onChanged: (v) => _drugName = v,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: '每次剂量', hintText: '0.1ml', border: OutlineInputBorder()),
                        onChanged: (v) => _dosage = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: '系数 (mg/g)', hintText: '0.001', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _coefficient = double.tryParse(v) ?? 0.001,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _drugType,
                        decoration: const InputDecoration(labelText: '类型', border: OutlineInputBorder()),
                        items: ['抗生素', '驱虫', '维生素', '益生菌', '其他']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _drugType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _timesPerDay,
                        decoration: const InputDecoration(labelText: '每天次数', border: OutlineInputBorder()),
                        items: [1, 2, 3].map((n) => DropdownMenuItem(
                            value: n,
                            child: Text('$n 次/天  (${_hourLabel(n)})'))).toList(),
                        onChanged: (v) => setState(() => _timesPerDay = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _drugName.isEmpty || _dosage.isEmpty
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$_drugName 已添加')),
                            );
                            setState(() {
                              _drugName = '';
                              _dosage = '';
                            });
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('添加药品'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('自动剂量计算', style: theme.textTheme.titleSmall),
                ]),
                const SizedBox(height: 8),
                Text(
                  '当从鹦鹉详情页添加喂药方案时，系统会自动读取该鸟的最新体重，'
                  '按「体重(g) × 系数」计算建议剂量。',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  '例: 100g × 0.001 = 0.1ml   |   150g × 0.001 = 0.15ml',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.blue.shade700),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static String _hourLabel(int n) {
    switch (n) {
      case 1: return '8:00';
      case 2: return '8:00, 20:00';
      case 3: return '8:00, 14:00, 20:00';
      default: return '8:00';
    }
  }
}
