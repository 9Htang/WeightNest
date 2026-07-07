import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'drug_library_repository.dart';
import 'medication_repository.dart';
import 'feeding_record_sheet.dart';
import 'dose_calculation_screen.dart';

/// 鹦鹉详情页「喂药计划」Tab 内容
class MedicationSection extends StatefulWidget {
  final int birdId;
  const MedicationSection({super.key, required this.birdId});

  @override
  State<MedicationSection> createState() => _MedicationSectionState();
}

class _MedicationSectionState extends State<MedicationSection> {
  final Set<int> _confirmingDelete = {};

  AppDatabase get _db => pluginRegistry.db!;

  // Cache the two load Futures in State. Reloading swaps the Futures (the
  // FutureBuilders re-subscribe) without changing widget keys, so the subtree
  // is reconciled in place rather than being torn down and rebuilt.
  late Future<List<MedicationWithDetails>> _medsFuture;
  late Future<List<MedTaskInfo>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _medsFuture = _db.getMedicationsByBird(widget.birdId);
    _logsFuture = _db.getTodayMedTasks(widget.birdId);
  }

  void _reload() {
    setState(() {
      _medsFuture = _db.getMedicationsByBird(widget.birdId);
      _logsFuture = _db.getTodayMedTasks(widget.birdId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<MedicationWithDetails>>(
      future: _medsFuture,
      builder: (context, medSnapshot) {
        final meds = medSnapshot.data ?? [];

        return FutureBuilder<List<MedTaskInfo>>(
          future: _logsFuture,
          builder: (context, logSnapshot) {
            final logs = logSnapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 活跃药品方案列表 ──
                if (meds.isNotEmpty) ...[
                  ...meds.asMap().entries.map((entry) {
                    final m = entry.value;
                    final isConfirming =
                        _confirmingDelete.contains(m.medication.id);
                    return _MedicationPlanCard(
                      medication: m,
                      isConfirmingDelete: isConfirming,
                      onDeleteTap: () {
                        if (isConfirming) {
                          _doDelete(m.medication.id);
                        } else {
                          setState(
                              () => _confirmingDelete.add(m.medication.id));
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted &&
                                _confirmingDelete.contains(m.medication.id)) {
                              setState(() =>
                                  _confirmingDelete.remove(m.medication.id));
                            }
                          });
                        }
                      },
                      onRecordFeeding: () => _reload(),
                    );
                  }),
                ] else
                  _buildEmpty(theme),

                const SizedBox(height: 12),

                // ── 剂量计算器入口 ──
                OutlinedButton.icon(
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('剂量计算器'),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoseCalculationScreen(initialBirdId: widget.birdId),
                      ),
                    );
                    if (result == true) _reload();
                  },
                ),

                const SizedBox(height: 16),

                // ── 今日喂药记录 ──
                if (logs.isNotEmpty) ...[
                  Row(children: [
                    Icon(Icons.today,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('今日喂药记录',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  ...logs.map((l) => _TodayLogItem(
                        data: l,
                        onTap: () => _showFeedingSheet(l),
                      )),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('今天暂无喂药任务',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(children: [
        Icon(Icons.medication_outlined, size: 36, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text('暂无喂药方案', style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text('使用剂量计算器创建方案',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }

  Future<void> _doDelete(int medId) async {
    await _db.deactivateMedication(medId);
    _reload();
  }

  void _showFeedingSheet(MedTaskInfo log) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => FeedingRecordSheet(
        data: log,
        onRecorded: _reload,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Medication Plan Card (new schema)
// ═══════════════════════════════════════════════════════════════════════════════

class _MedicationPlanCard extends StatelessWidget {
  final MedicationWithDetails medication;
  final bool isConfirmingDelete;
  final VoidCallback onDeleteTap;
  final VoidCallback onRecordFeeding;

  const _MedicationPlanCard({
    required this.medication,
    required this.isConfirmingDelete,
    required this.onDeleteTap,
    required this.onRecordFeeding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = medication.medication;
    final isLongTerm = med.endDate == null;
    final startStr = '${med.startDate.month}/${med.startDate.day}';
    final endStr =
        isLongTerm ? '长期' : '${med.endDate!.month}/${med.endDate!.day}';
    final remainDays =
        isLongTerm ? null : med.endDate!.difference(AppClock.now).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(medication.drugName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _drugCategoryColor(medication.drugCategory)
                            .withAlpha(30),
                      ),
                      child: Text(medication.drugCategory,
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  _drugCategoryColor(medication.drugCategory))),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosageDisplay} · ${medication.formulation} · ${med.timesPerDay}次/日',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.orange.shade100,
                      ),
                      child: Text(medication.diseaseName,
                          style: TextStyle(
                              fontSize: 10, color: Colors.orange.shade800)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLongTerm
                          ? '$startStr 起 · 长期用药'
                          : '$startStr ~ $endStr${remainDays != null ? " (剩 $remainDays 天)" : ""}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ]),
                  if (med.notes != null && med.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(med.notes!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                  // Stop reason if deactivated
                  if (med.stopReason != null && med.stopReason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.stop_circle,
                          size: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('停药: ${med.stopReason}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.red)),
                    ]),
                  ],
                ],
              ),
            ),
            // Delete button
            TextButton(
              onPressed: onDeleteTap,
              style: TextButton.styleFrom(
                foregroundColor: isConfirmingDelete ? Colors.red : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isConfirmingDelete ? '确认删除?' : '删除',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  static Color _drugCategoryColor(String type) {
    switch (type) {
      case '抗生素':
        return Colors.red;
      case '驱虫':
        return Colors.orange;
      case '维生素':
        return Colors.green;
      case '益生菌':
        return Colors.blue;
      case '抗真菌':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Today Log Item (opens feeding record sheet on tap)
// ═══════════════════════════════════════════════════════════════════════════════

class _TodayLogItem extends StatelessWidget {
  final MedTaskInfo data;
  final VoidCallback onTap;

  const _TodayLogItem({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final threshold = data.task.deadline ?? data.task.dueDate;
    final isLate =
        !data.isDone && !data.isSkipped && threshold.isBefore(AppClock.now);

    Color bgColor;
    if (data.isDone) {
      bgColor = Colors.green.shade50;
    } else if (data.isSkipped) {
      bgColor = Colors.grey.shade100;
    } else if (isLate) {
      bgColor = Colors.red.shade50;
    } else {
      bgColor = theme.colorScheme.surfaceContainerLow;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: bgColor,
      child: InkWell(
        onTap: data.isDone || data.isSkipped ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(
              data.isDone
                  ? Icons.check_circle
                  : data.isSkipped
                      ? Icons.cancel
                      : Icons.schedule,
              size: 18,
              color: data.isDone
                  ? Colors.green
                  : data.isSkipped
                      ? Colors.grey
                      : isLate
                          ? Colors.red
                          : Colors.blue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.timeLabel}  ${data.drugName}  ${data.dosage}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: data.isDone
                          ? Colors.green.shade800
                          : data.isSkipped
                              ? Colors.grey
                              : null,
                    ),
                  ),
                  Text(data.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: data.isDone
                            ? Colors.green
                            : data.isSkipped
                                ? Colors.grey
                                : isLate
                                    ? Colors.red
                                    : Colors.blue,
                      )),
                ],
              ),
            ),
            if (!data.isDone && !data.isSkipped)
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}
