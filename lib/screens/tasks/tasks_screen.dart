import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../repositories/task_repository.dart';
import '../../plugins/medication/medication_repository.dart';
import '../weigh/weigh_grid_screen.dart';
import '../../widgets/section_header.dart';
/// 任务页面 — 今日任务 + 逾期任务
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final medLogsAsync = ref.watch(todayAllMedicationLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日任务'),
            Tab(text: '逾期'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(todayTasksProvider);
              ref.invalidate(todayAllMedicationLogsProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTasks(tasksAsync: tasksAsync, medLogsAsync: medLogsAsync, ref: ref),
          _OverdueTasks(ref: ref),
        ],
      ),
    );
  }
}

class _TodayTasks extends ConsumerWidget {
  final AsyncValue<List<TaskWithBird>> tasksAsync;
  final AsyncValue<List<MedicationLogData>> medLogsAsync;
  final WidgetRef ref;

  const _TodayTasks({required this.tasksAsync, required this.medLogsAsync, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef localRef) {
    final tasks = tasksAsync.valueOrNull ?? [];
    final medLogs = medLogsAsync.valueOrNull ?? [];
    final isLoading = tasksAsync.isLoading || medLogsAsync.isLoading;

    if (isLoading && tasks.isEmpty && medLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingWeigh = tasks.where((t) => t.task.status == '待完成').toList();
    final doneWeigh = tasks.where((t) => t.task.status == '已完成').toList();
    final pendingMeds = medLogs.where((l) => !l.isDone && !l.isSkipped).toList();
    final doneMeds = medLogs.where((l) => l.isDone || l.isSkipped).toList();

    final allPendingCount = pendingWeigh.length + pendingMeds.length;
    final allDoneCount = doneWeigh.length + doneMeds.length;

    if (tasks.isEmpty && medLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64,
                color: Theme.of(context).colorScheme.primary.withAlpha(80)),
            const SizedBox(height: 12),
            const Text('今天没有任务'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                ref.invalidate(todayTasksProvider);
                ref.invalidate(todayAllMedicationLogsProvider);
              },
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayTasksProvider);
        ref.invalidate(todayAllMedicationLogsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (allPendingCount > 0) ...[
            SectionHeader(title: '待完成 ($allPendingCount)'),
            // 称重任务
            ...pendingWeigh.map((t) => _TaskCard(
              task: t,
              onComplete: () => _completeWeighTask(t.task.id, ref),
              onWeigh: () => _startWeighing(context, t.bird.roomId),
            )),
            // 喂药任务
            ...pendingMeds.map((l) => _MedTaskCard(
              logData: l,
              onGive: () => _giveMed(l.log.id, ref),
              onSkip: () => _skipMed(l.log.id, ref),
            )),
          ],
          if (allDoneCount > 0) ...[
            SectionHeader(title: '已完成 ($allDoneCount)'),
            ...doneWeigh.map((t) => _TaskCard(task: t, done: true)),
            ...doneMeds.map((l) => _MedTaskCard(logData: l, done: true)),
          ],
        ],
      ),
    );
  }

  Future<void> _completeWeighTask(int taskId, WidgetRef ref) async {
    await ref.read(databaseProvider).completeTask(taskId, 1);
    ref.invalidate(todayTasksProvider);
  }

  Future<void> _giveMed(int logId, WidgetRef ref) async {
    await ref.read(databaseProvider).giveMedication(logId);
    ref.invalidate(todayAllMedicationLogsProvider);
  }

  Future<void> _skipMed(int logId, WidgetRef ref) async {
    await ref.read(databaseProvider).skipMedication(logId);
    ref.invalidate(todayAllMedicationLogsProvider);
  }

  void _startWeighing(BuildContext context, int? roomId) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => WeighGridScreen(initialRoomId: roomId)));
  }
}

class _OverdueTasks extends ConsumerWidget {
  final WidgetRef ref;

  const _OverdueTasks({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef localRef) {
    final overdueAsync = ref.watch(overdueTasksProvider);

    return overdueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                const SizedBox(height: 12),
                const Text('没有逾期任务 🎉'),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            SectionHeader(title: '逾期未称重 (${tasks.length})', color: Colors.orange),
            ...tasks.map((t) => _TaskCard(
              task: t,
              urgent: true,
              onComplete: () async {
                await ref.read(databaseProvider).completeTask(t.task.id, 1);
                ref.invalidate(overdueTasksProvider);
              },
            )),
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskWithBird task;
  final bool done;
  final bool urgent;
  final VoidCallback? onComplete;
  final VoidCallback? onWeigh;

  const _TaskCard({
    required this.task,
    this.done = false,
    this.urgent = false,
    this.onComplete,
    this.onWeigh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: urgent ? Colors.orange.shade50 : (done ? Colors.grey.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : (urgent ? Icons.warning : Icons.radio_button_unchecked),
              color: done ? Colors.green : (urgent ? Colors.orange : Colors.grey),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.bird.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${task.species?.name ?? ''} · ${task.task.dueDate.month}/${task.task.dueDate.day} · 房间 ${task.bird.roomId ?? "?"}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  if (task.task.assignedUserId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('已指派 #${task.task.assignedUserId}',
                          style: TextStyle(fontSize: 10, color: Colors.blue.shade400)),
                    ),
                ],
              ),
            ),
            if (!done) ...[
              if (onWeigh != null)
                IconButton(
                  icon: const Icon(Icons.monitor_weight_outlined, size: 20),
                  tooltip: '称重',
                  onPressed: onWeigh,
                ),
              FilledButton.tonal(
                onPressed: onComplete,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(60, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('完成', style: TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 喂药任务卡片
class _MedTaskCard extends StatelessWidget {
  final MedicationLogData logData;
  final bool done;
  final VoidCallback? onGive;
  final VoidCallback? onSkip;

  const _MedTaskCard({
    required this.logData,
    this.done = false,
    this.onGive,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLate = !done && logData.log.scheduledTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: done ? Colors.grey.shade50 : (isLate ? Colors.red.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: done ? Colors.green.shade100 : (isLate ? Colors.red.shade100 : Colors.blue.shade100),
              ),
              child: Icon(
                done ? Icons.check_circle : Icons.medication,
                size: 20,
                color: done ? Colors.green : (isLate ? Colors.red : Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(logData.medication.drugName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(logData.medication.dosage,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    '${logData.birdName ?? ''} · ${logData.timeLabel}${isLate && !done ? " (已逾期)" : ""}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLate && !done ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!done) ...[
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('跳过', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onGive,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(56, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('已喂'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
