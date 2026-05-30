import 'package:flutter/material.dart';
import '../../database/database.dart';
import 'medication_repository.dart';

class MedicationScreen extends StatefulWidget {
  final AppDatabase db;
  final int? birdId; // null = all birds

  const MedicationScreen({super.key, required this.db, this.birdId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<Medication> _plans = [];
  List<MedicationLogData> _todayLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = widget.db;
    final plans = widget.birdId != null
        ? await db.getMedicationsByBird(widget.birdId!)
        : <Medication>[];
    final logs = widget.birdId != null
        ? await db.getTodayLogs(widget.birdId!)
        : <MedicationLogData>[];
    if (mounted) setState(() { _plans = plans; _todayLogs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 今日喂药任务 ──
        _sectionHeader('今日喂药', Icons.today),
        if (_todayLogs.isEmpty)
          _emptyCard('今天没有喂药任务')
        else
          ..._todayLogs.map((d) => _logCard(d, theme)),

        const SizedBox(height: 24),

        // ── 喂药方案 ──
        _sectionHeader('喂药方案', Icons.medical_services),
        if (_plans.isEmpty)
          _emptyCard('暂无喂药方案')
        else
          ..._plans.map((p) => _planCard(p, theme)),

        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('新增喂药方案'),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(text, style: TextStyle(color: Colors.grey.shade500))),
      ),
    );
  }

  Widget _logCard(MedicationLogData d, ThemeData theme) {
    final isLate = !d.isDone && !d.isSkipped && d.log.scheduledTime.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: d.isDone ? Colors.green.shade50
          : d.isSkipped ? Colors.grey.shade100
          : isLate ? Colors.red.shade50
          : null,
      child: ListTile(
        leading: Icon(
          d.isDone ? Icons.check_circle : d.isSkipped ? Icons.cancel : Icons.access_time,
          color: d.isDone ? Colors.green : d.isSkipped ? Colors.grey : isLate ? Colors.red : Colors.orange,
        ),
        title: Text('${d.medication.drugName} — ${d.medication.dosage}'),
        subtitle: Text('${d.timeLabel}  ·  ${d.statusLabel}${isLate ? "  ⚠️逾期" : ""}'),
        trailing: d.isDone || d.isSkipped ? null : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: '已喂',
              onPressed: () async {
                await widget.db.giveMedication(d.log.id);
                _load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              tooltip: '跳过',
              onPressed: () async {
                await widget.db.skipMedication(d.log.id);
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(Medication p, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.teal),
        title: Text('${p.drugName}  ${p.dosage}'),
        subtitle: Text('${p.drugType}  ·  每天 ${p.timesPerDay} 次  ·  ${p.startDate.toString().substring(0, 10)} 起'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: '停用',
          onPressed: () async {
            await widget.db.deactivateMedication(p.id);
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final birdCtrl = TextEditingController(text: widget.birdId?.toString() ?? '');
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    String drugType = '抗生素';
    int timesPerDay = 1;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('新增喂药方案'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: birdCtrl, decoration: const InputDecoration(labelText: '鹦鹉 ID'), keyboardType: TextInputType.number),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '药品名称', hintText: '如: 伊维菌素')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: drugType,
                  decoration: const InputDecoration(labelText: '药品类型'),
                  items: ['抗生素', '驱虫', '维生素', '益生菌', '其他'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDlg(() => drugType = v!),
                ),
                TextField(controller: dosageCtrl, decoration: const InputDecoration(labelText: '剂量', hintText: '如: 0.2ml, 1片')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: timesPerDay,
                  decoration: const InputDecoration(labelText: '每天次数'),
                  items: [1, 2, 3].map((n) => DropdownMenuItem(value: n, child: Text('$n 次/天  (${_timesToSchedule(n)})'))).toList(),
                  onChanged: (v) => setDlg(() => timesPerDay = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.isNotEmpty && dosageCtrl.text.isNotEmpty) {
      final birdId = int.tryParse(birdCtrl.text) ?? widget.birdId ?? 0;
      if (birdId == 0) return;
      await widget.db.addMedication(
        birdId: birdId,
        drugName: nameCtrl.text,
        dosage: dosageCtrl.text,
        drugType: drugType,
        timesPerDay: timesPerDay,
      );
      _load();
    }
  }

  static String _timesToSchedule(int n) {
    switch (n) {
      case 1: return '8:00';
      case 2: return '8:00, 20:00';
      case 3: return '8:00, 14:00, 20:00';
      default: return '8:00';
    }
  }
}
