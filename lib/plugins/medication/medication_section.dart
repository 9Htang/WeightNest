import 'package:flutter/material.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'medication_repository.dart';
import 'medication_config_screen.dart';

/// 鹦鹉详情页「喂药计划」Tab 内容
class MedicationSection extends StatefulWidget {
  final int birdId;
  const MedicationSection({super.key, required this.birdId});

  @override
  State<MedicationSection> createState() => _MedicationSectionState();
}

class _MedicationSectionState extends State<MedicationSection> {
  int _refreshKey = 0;
  MedicationConfig _config = MedicationConfig.defaults;
  final Set<int> _confirmingDelete = {};

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final c = await MedicationConfig.load();
    if (mounted) setState(() => _config = c);
  }

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Medication>>(
      key: ValueKey('meds_$_refreshKey'),
      future: _db.getMedicationsByBird(widget.birdId),
      builder: (context, medSnapshot) {
        final meds = medSnapshot.data ?? [];

        return FutureBuilder<List<MedTaskInfo>>(
          key: ValueKey('logs_$_refreshKey'),
          future: _db.getTodayLogs(widget.birdId),
          builder: (context, logSnapshot) {
            final logs = logSnapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 活跃药品列表 ──
                if (meds.isNotEmpty) ...[
                  ...meds.asMap().entries.map((entry) {
                    final m = entry.value;
                    final isConfirming = _confirmingDelete.contains(m.id);
                    return _MedicationCard(
                      medication: m,
                      isConfirmingDelete: isConfirming,
                      onDeleteTap: () {
                        if (isConfirming) {
                          _doDelete(m.id);
                        } else {
                          setState(() => _confirmingDelete.add(m.id));
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted && _confirmingDelete.contains(m.id)) {
                              setState(() => _confirmingDelete.remove(m.id));
                            }
                          });
                        }
                      },
                    );
                  }),
                ] else
                  _buildEmpty(theme),

                const SizedBox(height: 12),

                // ── 添加药品按钮 ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加药品'),
                    onPressed: () => _showAddDialog(context),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 今日喂药记录 ──
                if (logs.isNotEmpty) ...[
                  Row(children: [
                    Icon(Icons.today, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('今日喂药记录',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  ...logs.map((l) => _TodayLogItem(
                        data: l,
                        onGive: () => _db.giveMedication(l.task.id).then((_) => _reload()),
                        onSkip: () => _db.skipMedication(l.task.id).then((_) => _reload()),
                      )),
                ],
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
        Text('暂无喂药计划', style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text('点击下方按钮添加药品', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }

  Future<void> _doDelete(int medId) async {
    await _db.deactivateMedication(medId);
    _reload();
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddMedicationSheet(
        birdId: widget.birdId,
        config: _config,
        onAdded: _reload,
      ),
    );
  }
}

/// 药品卡片
class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final bool isConfirmingDelete;
  final VoidCallback onDeleteTap;

  const _MedicationCard({
    required this.medication,
    required this.isConfirmingDelete,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLongTerm = medication.endDate == null;
    final startStr = '${medication.startDate.month}/${medication.startDate.day}';
    final endStr = isLongTerm ? '长期' : '${medication.endDate!.month}/${medication.endDate!.day}';
    final remainDays = isLongTerm ? null : medication.endDate!.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 药品名 + 用量
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(medication.drugName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _drugTypeColor(medication.drugType).withAlpha(30),
                      ),
                      child: Text(medication.drugType,
                          style: TextStyle(fontSize: 10, color: _drugTypeColor(medication.drugType))),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosage} · ${medication.timesPerDay}次/日',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLongTerm
                        ? '$startStr 起 · 长期用药'
                        : '$startStr ~ $endStr${remainDays != null ? " (剩 $remainDays 天)" : ""}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(medication.notes!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            // 删除按钮
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

  static Color _drugTypeColor(String type) {
    switch (type) {
      case '抗生素':
        return Colors.red;
      case '驱虫':
        return Colors.orange;
      case '维生素':
        return Colors.green;
      case '益生菌':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// 今日喂药记录条目
class _TodayLogItem extends StatelessWidget {
  final MedTaskInfo data;
  final VoidCallback onGive;
  final VoidCallback onSkip;

  const _TodayLogItem({required this.data, required this.onGive, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLate = !data.isDone && !data.isSkipped && data.task.dueDate.isBefore(DateTime.now());

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(
            data.isDone ? Icons.check_circle : data.isSkipped ? Icons.cancel : Icons.schedule,
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
                    color: data.isDone ? Colors.green.shade800 : data.isSkipped ? Colors.grey : null,
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
          if (!data.isDone && !data.isSkipped) ...[
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('跳过', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: onGive,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('已喂'),
            ),
          ],
        ]),
      ),
    );
  }
}

/// 添加药品底部 Sheet
class _AddMedicationSheet extends StatefulWidget {
  final int birdId;
  final MedicationConfig config;
  final VoidCallback onAdded;

  const _AddMedicationSheet({
    required this.birdId,
    required this.config,
    required this.onAdded,
  });

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _drugType = '其他';
  int _timesPerDay = 2;
  int _durationDays = 7;
  bool _isLongTerm = false;
  List<TimeOfDay> _customTimes = [];
  bool _useCustomTimes = false;
  final _notesCtrl = TextEditingController();
  MedicationConfig _config = MedicationConfig.defaults;

  @override
  void initState() {
    super.initState();
    _timesPerDay = widget.config.defaultDoses;
    _config = widget.config;
    _regenTimes();
  }

  void _regenTimes() {
    if (!_useCustomTimes) {
      _customTimes = _config.distributeDoses(_timesPerDay);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拖拽条
              Center(
                child: Container(
                  width: 32, height: 4,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),
              Text('添加药品', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 药品名
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '药品名', hintText: '恩诺沙星', border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // 药品类型 + 用量
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
                  child: TextField(
                    controller: _dosageCtrl,
                    decoration: const InputDecoration(labelText: '用量', hintText: '0.5ml', border: OutlineInputBorder()),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // 每日次数 + 自定义切换
              Row(children: [
                Text('每日次数', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(_useCustomTimes ? Icons.auto_fix_high : Icons.edit_calendar, size: 14),
                  label: Text(_useCustomTimes ? '自动分配' : '自定义时间', style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _useCustomTimes = !_useCustomTimes;
                      if (!_useCustomTimes) _regenTimes();
                    });
                  },
                ),
              ]),
              const SizedBox(height: 8),
              if (!_useCustomTimes) ...[
                // 自动模式: 选择次数
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1次'), icon: Icon(Icons.looks_one, size: 14)),
                    ButtonSegment(value: 2, label: Text('2次'), icon: Icon(Icons.looks_two, size: 14)),
                    ButtonSegment(value: 3, label: Text('3次'), icon: Icon(Icons.looks_3, size: 14)),
                    ButtonSegment(value: 4, label: Text('4次'), icon: Icon(Icons.looks_4, size: 14)),
                  ],
                  selected: {_timesPerDay},
                  onSelectionChanged: (v) {
                    setState(() { _timesPerDay = v.first; _regenTimes(); });
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 8),
                // 显示自动生成的时间
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _customTimes.asMap().entries.map((e) {
                    final t = e.value;
                    return ActionChip(
                      avatar: const Icon(Icons.schedule, size: 14),
                      label: Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'),
                      onPressed: () => _pickCustomTime(e.key),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ] else ...[
                // 自定义模式: 手动时间列表
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    ..._customTimes.asMap().entries.map((e) {
                      final t = e.value;
                      return InputChip(
                        avatar: const Icon(Icons.schedule, size: 14),
                        label: Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'),
                        onPressed: () => _pickCustomTime(e.key),
                        onDeleted: () {
                          setState(() => _customTimes.removeAt(e.key));
                        },
                        visualDensity: VisualDensity.compact,
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: const Text('添加时间'),
                      onPressed: _addCustomTime,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // 用药天数
              Row(children: [
                Expanded(
                  child: RadioListTile<bool>(
                    value: false,
                    groupValue: _isLongTerm,
                    onChanged: (v) => setState(() => _isLongTerm = v!),
                    title: const Text('指定天数', style: TextStyle(fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    value: true,
                    groupValue: _isLongTerm,
                    onChanged: (v) => setState(() => _isLongTerm = v!),
                    title: const Text('长期用药', style: TextStyle(fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ]),
              if (!_isLongTerm) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Text('用药', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '7',
                        suffixText: '天',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (v) => _durationDays = int.tryParse(v) ?? 7,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 12),

              // 备注
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: '备注 (选填)', hintText: '饭后服用', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // 保存按钮
              FilledButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text('保存'),
                onPressed: _nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty || _customTimes.isEmpty
                    ? null
                    : () => _doSave(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customTimes[index],
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _customTimes[index] = picked);
    }
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _customTimes.add(picked));
    }
  }

  Future<void> _doSave() async {
    final db = pluginRegistry.db!;
    final endDate = _isLongTerm ? null : DateTime.now().add(Duration(days: _durationDays));

    await db.addMedication(
      birdId: widget.birdId,
      drugName: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      drugType: _drugType,
      timesPerDay: _customTimes.length,
      endDate: endDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      customTimes: _customTimes,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onAdded();
    }
  }
}
