import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'medication_repository.dart';

/// Full calendar view for medication schedules.
/// Shows a date picker + the selected day's medication timeline.
class MedicationCalendarView extends StatefulWidget {
  final int? birdId;
  final DateTime? initialDay;

  const MedicationCalendarView({super.key, this.birdId, this.initialDay});

  @override
  State<MedicationCalendarView> createState() => _MedicationCalendarViewState();
}

class _MedicationCalendarViewState extends State<MedicationCalendarView> {
  late DateTime _selectedDay;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay ?? DateTime.now();
  }

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = pluginRegistry.db;
    if (db == null) return const Center(child: Text('数据库未就绪'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector
        _buildDateBar(theme),
        const Divider(),
        // Day detail
        Expanded(
          child: _MedicationDayView(
            key: ValueKey('${_selectedDay.toIso8601String()}-$_refreshKey'),
            db: db,
            day: _selectedDay,
            birdId: widget.birdId,
            onChanged: _reload,
          ),
        ),
      ],
    );
  }

  Widget _buildDateBar(ThemeData theme) {
    final today = DateTime.now();
    final selectedStr = _selectedDay == today
        ? '今天'
        : '${_selectedDay.month}月${_selectedDay.day}日';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 1))),
        ),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDay,
              firstDate: DateTime(2024),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              helpText: '选择日期',
              cancelText: '取消',
              confirmText: '确定',
            );
            if (picked != null) setState(() => _selectedDay = picked);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(selectedStr, style: theme.textTheme.titleMedium),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final next = _selectedDay.add(const Duration(days: 1));
            if (!next.isAfter(today.add(const Duration(days: 30)))) {
              setState(() => _selectedDay = next);
            }
          },
        ),
        const Spacer(),
        if (_selectedDay != today)
          TextButton.icon(
            onPressed: () => setState(() => _selectedDay = today),
            icon: const Icon(Icons.today, size: 16),
            label: const Text('今天'),
          ),
      ]),
    );
  }
}

/// Renders medication logs for a single day.
class _MedicationDayView extends StatelessWidget {
  final AppDatabase db;
  final DateTime day;
  final int? birdId;
  final VoidCallback onChanged;

  const _MedicationDayView({
    super.key,
    required this.db,
    required this.day,
    this.birdId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MedicationLogData>>(
      future: _fetchLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('${day.month}月${day.day}日暂无喂药记录',
                  style: TextStyle(color: Colors.grey.shade500)),
            ]),
          );
        }
        return _buildLogList(context, logs);
      },
    );
  }

  Future<List<MedicationLogData>> _fetchLogs() async {
    if (birdId != null) {
      // For a single bird, use the day's logs
      // Query all today logs and filter by bird will already be handled
      return db.getTodayLogs(birdId!);
    }
    // For all birds, we fetch each bird's medications
    // Simplified: query logs for the day
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await (db.select(db.medicationLogs).join([
      innerJoin(db.medications, db.medications.id.equalsExp(db.medicationLogs.medicationId)),
    ])
      ..where(db.medicationLogs.scheduledTime.isBiggerOrEqualValue(dayStart) &
          db.medicationLogs.scheduledTime.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(db.medicationLogs.scheduledTime)])).get();

    return rows.map((r) => MedicationLogData(
      log: r.readTable(db.medicationLogs),
      medication: r.readTable(db.medications),
    )).toList();
  }

  Widget _buildLogList(BuildContext context, List<MedicationLogData> logs) {
    final theme = Theme.of(context);
    final grouped = <int, List<MedicationLogData>>{};
    for (final l in logs) {
      grouped.putIfAbsent(l.medication.birdId, () => []).add(l);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.expand((entry) {
        final birdId = entry.key;
        final items = entry.value;
        final drug = items.first.medication.drugName;
        final doneCount = items.where((l) => l.isDone).length;
        final totalCount = items.length;

        return [
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(doneCount == totalCount ? Icons.check_circle : Icons.medication,
                        color: doneCount == totalCount ? Colors.green : Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$drug  ·  ${items.first.medication.dosage}',
                            style: theme.textTheme.titleSmall),
                        Text('鹦鹉 #$birdId  ·  ${items.first.medication.drugType}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ]),
                    ),
                    Text('$doneCount/$totalCount',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: doneCount == totalCount ? Colors.green : Colors.orange)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: items.map((l) {
                    final isLate = !l.isDone && !l.isSkipped && l.log.scheduledTime.isBefore(DateTime.now());
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: (l.isDone || l.isSkipped) ? null : () async {
                        await db.giveMedication(l.log.id);
                        onChanged();
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: l.isDone ? Colors.green.shade300
                              : l.isSkipped ? Colors.grey.shade300
                              : isLate ? Colors.red.shade300
                              : Colors.blue.shade300),
                          color: l.isDone ? Colors.green.shade50
                              : l.isSkipped ? Colors.grey.shade100
                              : isLate ? Colors.red.shade50
                              : Colors.blue.shade50,
                        ),
                        child: Column(children: [
                          Icon(l.isDone ? Icons.check_circle
                              : l.isSkipped ? Icons.cancel
                              : isLate ? Icons.warning
                              : Icons.schedule,
                              size: 20,
                              color: l.isDone ? Colors.green
                                  : l.isSkipped ? Colors.grey
                                  : isLate ? Colors.red
                                  : Colors.blue),
                          const SizedBox(height: 4),
                          Text(l.timeLabel,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                  color: l.isDone ? Colors.green.shade800
                                      : l.isSkipped ? Colors.grey
                                      : isLate ? Colors.red.shade700
                                      : Colors.blue.shade800)),
                          const SizedBox(height: 2),
                          Text(l.isDone ? '已完成' : l.isSkipped ? '已跳过' : isLate ? '逾期' : '待喂',
                              style: TextStyle(fontSize: 10,
                                  color: l.isDone ? Colors.green.shade600
                                      : l.isSkipped ? Colors.grey
                                      : isLate ? Colors.red
                                      : Colors.blue.shade600)),
                        ]),
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
}
