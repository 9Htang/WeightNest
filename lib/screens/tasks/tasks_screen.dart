import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../repositories/task_repository.dart';
import '../../database/database.dart';
import '../../core/plugin_registry.dart';
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

    // 异常鸟 ID 集合 — 用于标红和排序
    final alertsAsync = ref.watch(alertListProvider);
    final anomalyBirdIds = alertsAsync.valueOrNull
        ?.map((a) => a.bird.bird.id).toSet() ?? <int>{};

    // 待完成排序：异常鸟在前
    pendingWeigh.sort((a, b) {
      final aAnomaly = anomalyBirdIds.contains(a.bird.id) ? 0 : 1;
      final bAnomaly = anomalyBirdIds.contains(b.bird.id) ? 0 : 1;
      return aAnomaly.compareTo(bAnomaly);
    });

    // 已完成排序：异常鸟在前
    doneWeigh.sort((a, b) {
      final aAnomaly = anomalyBirdIds.contains(a.bird.id) ? 0 : 1;
      final bAnomaly = anomalyBirdIds.contains(b.bird.id) ? 0 : 1;
      return aAnomaly.compareTo(bAnomaly);
    });

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
              isAnomaly: anomalyBirdIds.contains(t.bird.id),
              onComplete: () => _completeWeighTask(t.task.id, ref),
              onWeigh: () => _startWeighing(context, t.bird.roomId, t.bird.id),
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
            ...doneWeigh.map((t) => _TaskCard(
              task: t,
              done: true,
              isAnomaly: anomalyBirdIds.contains(t.bird.id),
            )),
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

  void _startWeighing(BuildContext context, int? roomId, int birdId) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => WeighGridScreen(initialRoomId: roomId, initialBirdId: birdId)));
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
  final bool isAnomaly;
  final VoidCallback? onComplete;
  final VoidCallback? onWeigh;

  const _TaskCard({
    required this.task,
    this.done = false,
    this.urgent = false,
    this.isAnomaly = false,
    this.onComplete,
    this.onWeigh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ring = task.bird.ringNumber;
    final speciesName = task.species?.name ?? '';
    final roomName = task.room?.name;
    final enclosureName = task.enclosure?.name;
    final w = task.todayWeight;

    // 背景色
    Color? bgColor;
    if (done && isAnomaly) {
      bgColor = Colors.red.shade50;
    } else if (done) {
      bgColor = Colors.grey.shade50;
    } else if (isAnomaly || urgent) {
      bgColor = Colors.red.shade50;
    }

    // 图标
    final icon = done ? Icons.check_circle : (isAnomaly || urgent ? Icons.warning_amber_rounded : Icons.radio_button_unchecked);
    final iconColor = done ? Colors.green : (isAnomaly || urgent ? Colors.red : Colors.grey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: bgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final weightPlugin = pluginRegistry.getPlugin('weights');
          if (weightPlugin == null) return;
          final page = weightPlugin.onTaskCardTap(context, task.bird.id);
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：鸟名 + 脚环
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAnomaly ? Colors.red.shade800 : theme.textTheme.bodyMedium?.color,
                        ),
                        children: [
                          TextSpan(text: task.bird.name),
                          if (ring != null && ring.isNotEmpty) ...[
                            TextSpan(
                              text: '  #$ring',
                              style: TextStyle(
                                fontSize: 12,
                                color: (isAnomaly ? Colors.red : Colors.grey).shade500,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 第二行
                    _buildSecondLine(context, done, w, speciesName, roomName, enclosureName),
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
      ),
    );
  }

  Widget _buildSecondLine(BuildContext context, bool done, Weight? w,
      String speciesName, String? roomName, String? enclosureName) {
    final theme = Theme.of(context);
    if (done && w != null) {
      // 已完成：显示体重和时间
      final timeStr =
          '${w.recordedAt.hour.toString().padLeft(2, '0')}:${w.recordedAt.minute.toString().padLeft(2, '0')}';
      final parts = <String>[
        '称重 ${w.weightG.toStringAsFixed(1)}g',
        timeStr,
      ];
      if (!w.isFasting) parts.add('非空腹');
      return Text(
        parts.join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
      );
    }
    // 待完成：位置信息
    final parts = <String>[
      if (speciesName.isNotEmpty) speciesName,
      if (roomName != null && roomName.isNotEmpty) roomName,
      if (enclosureName != null && enclosureName.isNotEmpty) enclosureName,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
    final ring = logData.birdRingNumber;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: done ? Colors.grey.shade50 : (isLate ? Colors.red.shade50 : null),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final medPlugin = pluginRegistry.getPlugin('medication');
          if (medPlugin == null) return;
          final page = medPlugin.onTaskCardTap(context, logData.log.birdId);
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
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
                  // 第一行：药名 + 剂量
                  Row(children: [
                    Text(logData.medication.drugName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(logData.medication.dosage,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 2),
                  // 第二行：鸟名 + 脚环 · 时间
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLate && !done ? Colors.red : Colors.grey,
                      ),
                      children: [
                        TextSpan(text: logData.birdName ?? ''),
                        if (ring != null && ring.isNotEmpty)
                          TextSpan(text: '  #$ring'),
                        TextSpan(text: ' · ${logData.timeLabel}'),
                        if (isLate && !done)
                          const TextSpan(text: ' (已逾期)'),
                      ],
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
      ),
    );
  }
}
