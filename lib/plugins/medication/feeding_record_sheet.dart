import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'medication_repository.dart';
import 'drug_library_repository.dart';

/// Bottom sheet for recording feeding status with 5 options.
class FeedingRecordSheet extends StatefulWidget {
  final MedTaskInfo data;
  final VoidCallback onRecorded;

  const FeedingRecordSheet(
      {super.key, required this.data, required this.onRecorded});

  @override
  State<FeedingRecordSheet> createState() => _FeedingRecordSheetState();
}

class _FeedingRecordSheetState extends State<FeedingRecordSheet> {
  String _selectedStatus = '已喂';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _statuses = [
    _StatusOption('已喂', Icons.check_circle, Colors.green, 'taken'),
    _StatusOption('吐出', Icons.replay, Colors.orange, 'vomited'),
    _StatusOption('漏喂', Icons.timer_off, Colors.grey, 'missed'),
    _StatusOption('补喂', Icons.add_circle, Colors.blue, 'supplemented'),
    _StatusOption('拒绝', Icons.cancel, Colors.red, 'refused'),
  ];

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey.shade300),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              const Icon(Icons.medication, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${data.drugName} · ${data.timeLabel}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(data.dosage,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          const SizedBox(height: 16),

          // Status options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final selected = _selectedStatus == s.label;
                return ChoiceChip(
                  avatar: Icon(s.icon,
                      size: 18, color: selected ? s.color : Colors.grey),
                  label: Text(s.label),
                  selected: selected,
                  selectedColor: s.color.withAlpha(30),
                  onSelected: (v) => setState(() => _selectedStatus = s.label),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: '备注 (选填)',
                hintText: '如: 药后吐了一点',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Confirm
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: FilledButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: Text(_saving ? '保存中...' : '确认记录'),
              onPressed: _saving ? null : _doSave,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doSave() async {
    setState(() => _saving = true);
    try {
      final opt = _statuses.firstWhere((s) => s.label == _selectedStatus);
      final medId = int.tryParse(widget.data.task.metadata != null
              ? (() {
                  try {
                    final map =
                        widget.data.task.metadata as Map<String, dynamic>;
                    return map['medicationId']?.toString() ?? '0';
                  } catch (_) {
                    return '0';
                  }
                })()
              : '0') ??
          0;

      // Determine task status based on feeding status
      final taskStatus =
          (opt.key == 'taken' || opt.key == 'supplemented') ? '已完成' : '已跳过';

      // Update task
      await (_db.update(_db.tasks)
            ..where((t) => t.id.equals(widget.data.task.id)))
          .write(TasksCompanion(
        status: Value(taskStatus),
        completedAt:
            taskStatus == '已完成' ? Value(AppClock.now) : const Value.absent(),
        updatedAt: Value(AppClock.now),
      ));

      // Create feeding record
      if (medId > 0) {
        await _db.addFeedingRecord(
          medicationId: medId,
          birdId: widget.data.task.birdId,
          taskId: widget.data.task.id,
          feedingStatus: opt.label,
          fedAt: AppClock.now,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onRecorded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已记录: ${widget.data.drugName} ${opt.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('记录失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StatusOption {
  final String label;
  final IconData icon;
  final Color color;
  final String key;
  const _StatusOption(this.label, this.icon, this.color, this.key);
}
