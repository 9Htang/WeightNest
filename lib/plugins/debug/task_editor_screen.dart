import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/app_clock.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../repositories/task_repository.dart';
import '../../providers.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  DateTime _from = AppClock.now.subtract(const Duration(days: 7));
  DateTime _to = AppClock.now.add(const Duration(days: 1));
  List<TaskWithBird> _tasks = [];
  bool _loading = true;
  String? _error;

  // Bulk seed
  final _seedDaysCtl = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _seedDaysCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = pluginRegistry.db;
    if (db == null) {
      setState(() {
        _loading = false;
        _error = '数据库未初始化';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fromDay = DateTime(_from.year, _from.month, _from.day);
      final toDay =
          DateTime(_to.year, _to.month, _to.day).add(const Duration(days: 1));
      final query = db.select(db.tasks).join([
        innerJoin(db.birds, db.birds.id.equalsExp(db.tasks.birdId)),
      ]);
      query
        ..where(db.tasks.dueDate.isBiggerOrEqualValue(fromDay) &
            db.tasks.dueDate.isSmallerThanValue(toDay))
        ..orderBy([OrderingTerm.desc(db.tasks.dueDate)])
        ..limit(200);

      final rows = await query.get();
      setState(() {
        _tasks = rows
            .map((row) => TaskWithBird(
                  task: row.readTable(db.tasks),
                  bird: row.readTable(db.birds),
                  species: null,
                  room: null,
                  enclosure: null,
                  todayWeight: null,
                ))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _updateStatus(Task task, String newStatus) async {
    final db = pluginRegistry.db!;
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id)))
        .write(TasksCompanion(
      status: Value(newStatus),
      completedAt:
          newStatus == '已完成' ? Value(AppClock.now) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    ref.invalidate(todayTasksProvider);
    ref.invalidate(overdueTasksProvider);
    _load();
  }

  Future<void> _deleteTask(Task task) async {
    final db = pluginRegistry.db!;
    await (db.delete(db.tasks)..where((t) => t.id.equals(task.id))).go();
    ref.invalidate(todayTasksProvider);
    ref.invalidate(overdueTasksProvider);
    _load();
  }

  Future<void> _bulkSeed() async {
    final db = pluginRegistry.db!;
    final days = int.tryParse(_seedDaysCtl.text.trim()) ?? 3;
    final clamped = days.clamp(1, 30);

    for (int i = 0; i < clamped; i++) {
      final d = AppClock.now.add(Duration(days: i));
      await AppClock.override(d);
      try {
        await db.generateTodayTasks(force: true);
      } finally {
        await AppClock.reset();
      }
    }
    if (mounted) {
      ref.invalidate(todayTasksProvider);
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已生成 $clamped 天测试任务')),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: AppClock.now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务编辑器'),
        actions: [
          IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: '日期范围',
              onPressed: _pickDateRange),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Date range display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Text(
              '${_fmtDay(_from)} — ${_fmtDay(_to)}  ·  ${_tasks.length} 个任务',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(160)),
            ),
          ),

          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: theme.colorScheme.error.withAlpha(20),
              child: Text(_error!,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ),

          // Task list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Text('此日期范围内无任务',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(120))))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (_, i) {
                          final twb = _tasks[i];
                          final t = twb.task;
                          final birdName = twb.bird.name;
                          final isLate = t.deadline != null &&
                              t.deadline!.isBefore(AppClock.now) &&
                              t.status == '待完成';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$birdName · ${t.taskType}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (isLate)
                                      const Icon(Icons.warning_amber,
                                          color: Colors.orange, size: 16),
                                    const SizedBox(width: 6),
                                    _StatusDropdown(
                                      value: t.status,
                                      onChange: (v) => _updateStatus(t, v),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18,
                                          color: theme.colorScheme.error),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('删除任务'),
                                          content: Text(
                                              '删除 $birdName 的 ${t.taskType} 任务？'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('取消')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteTask(t);
                                              },
                                              child: Text('删除',
                                                  style: TextStyle(
                                                      color: theme
                                                          .colorScheme.error)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '截止: ${_fmtDay(t.dueDate)}${t.deadline != null ? "  ·  逾期线: ${_fmtDay(t.deadline!)}" : ""}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(120)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // ── Bulk Seed ──
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seedDaysCtl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: '批量生成天数',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _bulkSeed,
                  icon: const Icon(Icons.science, size: 18),
                  label: const Text('生成测试任务'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDay(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0'),
        d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const _StatusDropdown({required this.value, required this.onChange});

  static const _all = ['待完成', '已完成', '逾期', '已跳过'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (value) {
      '已完成' => Colors.green,
      '逾期' => scheme.error,
      '已跳过' => scheme.onSurface.withAlpha(120),
      _ => scheme.primary,
    };

    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChange,
      itemBuilder: (_) => _all
          .map((s) => PopupMenuItem(
              value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
