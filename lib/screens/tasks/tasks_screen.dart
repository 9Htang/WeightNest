import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../repositories/task_repository.dart';
import '../weigh/weigh_screen.dart';
import '../worker/worker_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('称重任务'),
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
            tooltip: '重新生成',
            onPressed: () => ref.invalidate(todayTasksProvider),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTasks(tasksAsync: tasksAsync, ref: ref),
          _OverdueTasks(ref: ref),
        ],
      ),
    );
  }
}

class _TodayTasks extends ConsumerWidget {
  final AsyncValue<List<TaskWithBird>> tasksAsync;
  final WidgetRef ref;

  const _TodayTasks({required this.tasksAsync, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef localRef) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (tasks) {
        final pending = tasks.where((t) => t.task.status == '待完成').toList();
        final done = tasks.where((t) => t.task.status == '已完成').toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                const SizedBox(height: 12),
                const Text('今天没有称重任务'),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(todayTasksProvider),
                  child: const Text('生成任务'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(todayTasksProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(title: '待完成 (${pending.length})'),
                ...pending.map((t) => _TaskCard(
                  task: t,
                  onComplete: () => _completeTask(t.task.id, t.task.uuid, ref),
                  onWeigh: () => _startWeighing(context, t.bird.roomId),
                )),
              ],
              if (done.isNotEmpty) ...[
                _SectionHeader(title: '已完成 (${done.length})'),
                ...done.map((t) => _TaskCard(task: t, done: true)),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeTask(int taskId, String taskUuid, WidgetRef ref) async {
    await ref.read(databaseProvider).completeTask(taskId, 1);
    final userId = ref.read(workerProvider).userId;
    if (userId != null) {
      await ref.read(syncQueueProvider).enqueue(
        userId: userId,
        action: 'complete_task',
        entityType: 'task',
        entityUuid: taskUuid,
        payload: {'taskId': taskId, 'status': '已完成', 'completedBy': 1},
      );
    }
    ref.invalidate(todayTasksProvider);
  }

  void _startWeighing(BuildContext context, int? roomId) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => WeighScreen(roomId: roomId)));
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
            _SectionHeader(title: '逾期未称重 (${tasks.length})', color: Colors.orange),
            ...tasks.map((t) => _TaskCard(
              task: t,
              urgent: true,
              onComplete: () async {
                await ref.read(databaseProvider).completeTask(t.task.id, 1);
                final userId = ref.read(workerProvider).userId;
                if (userId != null) {
                  await ref.read(syncQueueProvider).enqueue(
                    userId: userId,
                    action: 'complete_task',
                    entityType: 'task',
                    entityUuid: t.task.uuid,
                    payload: {'taskId': t.task.id, 'status': '已完成', 'completedBy': 1},
                  );
                }
                ref.invalidate(overdueTasksProvider);
              },
            )),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: color ?? Theme.of(context).colorScheme.onSurface.withAlpha(160),
      )),
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
