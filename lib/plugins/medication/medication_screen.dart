import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import 'drug_library_repository.dart';
import 'medication_repository.dart';
import 'drug_library_screen.dart';
import 'dose_calculation_screen.dart';
import 'feeding_record_sheet.dart';

class MedicationScreen extends StatefulWidget {
  final AppDatabase db;
  final int? birdId;

  const MedicationScreen({super.key, required this.db, this.birdId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<MedicationWithDetails> _plans = [];
  List<MedTaskInfo> _todayLogs = [];
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
        : <MedicationWithDetails>[];
    final logs = widget.birdId != null
        ? await db.getTodayMedTasks(widget.birdId!)
        : <MedTaskInfo>[];
    if (mounted)
      setState(() {
        _plans = plans;
        _todayLogs = logs;
        _loading = false;
      });
  }

  void _showFeedingSheet(MedTaskInfo log) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => FeedingRecordSheet(data: log, onRecorded: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 快捷操作 ──
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DoseCalculationScreen(initialBirdId: widget.birdId)),
                );
                if (result == true) _load();
              },
              icon: const Icon(Icons.calculate, size: 16),
              label: const Text('剂量计算器', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DrugLibraryScreen())),
              icon: const Icon(Icons.local_pharmacy, size: 16),
              label: const Text('药品库', style: TextStyle(fontSize: 13)),
            ),
          ),
        ]),
        const SizedBox(height: 20),

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
          _emptyCard('暂无喂药方案，使用剂量计算器创建')
        else
          ..._plans.map((p) => _planCard(p, theme)),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Text(text, style: TextStyle(color: Colors.grey.shade500))),
      ),
    );
  }

  Widget _logCard(MedTaskInfo d, ThemeData theme) {
    final threshold = d.task.deadline ?? d.task.dueDate;
    final isLate =
        !d.isDone && !d.isSkipped && threshold.isBefore(AppClock.now);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: d.isDone
          ? Colors.green.shade50
          : d.isSkipped
              ? Colors.grey.shade100
              : isLate
                  ? Colors.red.shade50
                  : null,
      child: InkWell(
        onTap: (d.isDone || d.isSkipped) ? null : () => _showFeedingSheet(d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(
              d.isDone
                  ? Icons.check_circle
                  : d.isSkipped
                      ? Icons.cancel
                      : Icons.access_time,
              color: d.isDone
                  ? Colors.green
                  : d.isSkipped
                      ? Colors.grey
                      : isLate
                          ? Colors.red
                          : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d.drugName} — ${d.dosage}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                        '${d.timeLabel}  ·  ${d.statusLabel}${isLate ? "  ⚠️逾期" : ""}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ]),
            ),
            if (!d.isDone && !d.isSkipped)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  Widget _planCard(MedicationWithDetails p, ThemeData theme) {
    final med = p.medication;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.teal),
        title: Text('${p.drugName}  ${p.dosageDisplay}'),
        subtitle: Text(
            '${p.drugCategory} · ${p.formulation} · ${p.diseaseName} · 每天 ${med.timesPerDay} 次'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: '停用',
          onPressed: () async {
            await widget.db.deactivateMedication(med.id);
            _load();
          },
        ),
      ),
    );
  }
}
