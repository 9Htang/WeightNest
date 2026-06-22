import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_clock.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? _filterTaskType; // null = 全部, 'weigh', 'medication'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) => setState(() => _searchText = value);

  void _onFilterChanged(String? value) =>
      setState(() => _filterTaskType = value == _filterTaskType ? null : value);

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);

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
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索鸟名或脚环号',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // 筛选标签
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                _buildFilterChip('全部', null),
                const SizedBox(width: 8),
                _buildFilterChip('称重', 'weigh'),
                const SizedBox(width: 8),
                _buildFilterChip('喂药', 'medication'),
              ],
            ),
          ),
          // 标签页内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TodayTasks(
                  tasksAsync: tasksAsync,
                  ref: ref,
                  searchText: _searchText,
                  filterTaskType: _filterTaskType,
                ),
                _OverdueTasks(
                  ref: ref,
                  searchText: _searchText,
                  filterTaskType: _filterTaskType,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final selected = _filterTaskType == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (_) => _onFilterChanged(value),
      visualDensity: VisualDensity.compact,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _TodayTasks extends ConsumerWidget {
  final AsyncValue<List<TaskWithBird>> tasksAsync;
  final WidgetRef ref;
  final String searchText;
  final String? filterTaskType;

  const _TodayTasks({
    required this.tasksAsync,
    required this.ref,
    this.searchText = '',
    this.filterTaskType,
  });

  bool _matchesSearch(TaskWithBird t) {
    if (searchText.isEmpty) return true;
    final q = searchText.toLowerCase();
    return t.bird.name.toLowerCase().contains(q) ||
        (t.bird.ringNumber?.toLowerCase().contains(q) ?? false);
  }

  bool _matchesFilter(TaskWithBird t) {
    if (filterTaskType == null) return true;
    return t.task.taskType == filterTaskType;
  }

  @override
  Widget build(BuildContext context, WidgetRef localRef) {
    final rawTasks = tasksAsync.valueOrNull ?? [];
    final isLoading = tasksAsync.isLoading;

    // 客户端筛选
    final tasks = rawTasks.where((t) => _matchesSearch(t) && _matchesFilter(t)).toList();

    if (isLoading && tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 按 taskType 拆分称重和喂药任务
    final pendingWeigh = tasks.where((t) => t.task.status == '待完成' && t.task.taskType == 'weigh').toList();
    final doneWeigh = tasks.where((t) => t.task.status == '已完成' && t.task.taskType == 'weigh').toList();
    final pendingMeds = tasks.where((t) => t.task.status == '待完成' && t.task.taskType == 'medication').toList();
    final doneMeds = tasks.where((t) => t.task.status == '已完成' || t.task.status == '已跳过').where((t) => t.task.taskType == 'medication').toList();

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

    if (tasks.isEmpty) {
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
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (allPendingCount > 0) ...[
            SectionHeader(title: '待完成 ($allPendingCount)'),
            // 称重任务 — 只保留称重按钮，返回后刷新
            ...pendingWeigh.map((t) => _TaskCard(
              task: t,
              isAnomaly: anomalyBirdIds.contains(t.bird.id),
              onWeigh: () => _startWeighing(context, t.bird.roomId, t.bird.id),
            )),
            // 喂药任务
            ...pendingMeds.map((t) => _MedTaskCard(
              medInfo: MedTaskInfo.fromTask(t.task),
              birdName: t.bird.name,
              birdRingNumber: t.bird.ringNumber,
              onGive: () => _giveMed(t.task.id, ref),
              onSkip: () => _skipMed(t.task.id, ref),
            )),
          ],
          if (allDoneCount > 0) ...[
            SectionHeader(title: '已完成 ($allDoneCount)'),
            ...doneWeigh.map((t) => _TaskCard(
              task: t,
              done: true,
              isAnomaly: anomalyBirdIds.contains(t.bird.id),
            )),
            ...doneMeds.map((t) => _MedTaskCard(
              medInfo: MedTaskInfo.fromTask(t.task),
              birdName: t.bird.name,
              birdRingNumber: t.bird.ringNumber,
              done: true,
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _startWeighing(BuildContext context, int? roomId, int birdId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeighGridScreen(initialRoomId: roomId, initialBirdId: birdId),
      ),
    );
    // 返回后触发 generateTodayTasks 的 upgrade 逻辑，任务会自动标为已完成
    ref.invalidate(todayTasksProvider);
  }

  Future<void> _giveMed(int taskId, WidgetRef ref) async {
    await ref.read(databaseProvider).giveMedication(taskId);
    ref.invalidate(todayTasksProvider);
  }

  Future<void> _skipMed(int taskId, WidgetRef ref) async {
    await ref.read(databaseProvider).skipMedication(taskId);
    ref.invalidate(todayTasksProvider);
  }
}

class _OverdueTasks extends ConsumerWidget {
  final WidgetRef ref;
  final String searchText;
  final String? filterTaskType;

  const _OverdueTasks({
    required this.ref,
    this.searchText = '',
    this.filterTaskType,
  });

  bool _matchesSearch(TaskWithBird t) {
    if (searchText.isEmpty) return true;
    final q = searchText.toLowerCase();
    return t.bird.name.toLowerCase().contains(q) ||
        (t.bird.ringNumber?.toLowerCase().contains(q) ?? false);
  }

  bool _matchesFilter(TaskWithBird t) {
    if (filterTaskType == null) return true;
    return t.task.taskType == filterTaskType;
  }

  @override
  Widget build(BuildContext context, WidgetRef localRef) {
    final overdueAsync = ref.watch(overdueTasksProvider);

    return overdueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('加载失败')),
      data: (rawTasks) {
        // 客户端筛选
        final tasks = rawTasks.where((t) => _matchesSearch(t) && _matchesFilter(t)).toList();

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

        final weighTasks = tasks.where((t) => t.task.taskType == 'weigh').toList();
        final medTasks = tasks.where((t) => t.task.taskType == 'medication').toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            SectionHeader(title: '逾期任务 (${tasks.length})', color: Colors.orange),
            // 称重逾期任务
            ...weighTasks.map((t) => _TaskCard(
              task: t,
              urgent: true,
              onWeigh: () => _startWeighing(context, t.bird.roomId, t.bird.id),
            )),
            // 喂药逾期任务
            ...medTasks.map((t) => _MedTaskCard(
              medInfo: MedTaskInfo.fromTask(t.task),
              birdName: t.bird.name,
              birdRingNumber: t.bird.ringNumber,
              onGive: () => _giveMed(t.task.id, ref),
              onSkip: () => _skipMed(t.task.id, ref),
            )),
          ],
        );
      },
    );
  }

  Future<void> _startWeighing(BuildContext context, int? roomId, int birdId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeighGridScreen(initialRoomId: roomId, initialBirdId: birdId),
      ),
    );
    ref.invalidate(overdueTasksProvider);
  }

  Future<void> _giveMed(int taskId, WidgetRef ref) async {
    await ref.read(databaseProvider).giveMedication(taskId);
    ref.invalidate(overdueTasksProvider);
  }

  Future<void> _skipMed(int taskId, WidgetRef ref) async {
    await ref.read(databaseProvider).skipMedication(taskId);
    ref.invalidate(overdueTasksProvider);
  }
}

Widget _buildPublishTime(DateTime createdAt) {
  final timeStr =
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  return Text(
    '发布 $timeStr',
    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
  );
}

class _TaskCard extends StatelessWidget {
  final TaskWithBird task;
  final bool done;
  final bool urgent;
  final bool isAnomaly;
  final VoidCallback? onWeigh;

  const _TaskCard({
    required this.task,
    this.done = false,
    this.urgent = false,
    this.isAnomaly = false,
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
    final icon = done
        ? Icons.check_circle
        : (isAnomaly || urgent ? Icons.warning_amber_rounded : Icons.radio_button_unchecked);
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
                          color: isAnomaly
                              ? Colors.red.shade800
                              : theme.textTheme.bodyMedium?.color,
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
                    const SizedBox(height: 2),
                    // 第三行：发布时间
                    _buildPublishTime(task.task.createdAt),
                  ],
                ),
              ),
              // 待完成时只显示单个"称重"按钮
              if (!done && onWeigh != null)
                FilledButton.tonal(
                  onPressed: onWeigh,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_weight_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('称重', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
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
  final MedTaskInfo medInfo;
  final String birdName;
  final String? birdRingNumber;
  final bool done;
  final VoidCallback? onGive;
  final VoidCallback? onSkip;

  const _MedTaskCard({
    required this.medInfo,
    required this.birdName,
    this.birdRingNumber,
    this.done = false,
    this.onGive,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadline = medInfo.task.deadline ?? medInfo.task.dueDate;
    final isLate = !done && deadline.isBefore(AppClock.now);
    final overdueDays = isLate ? AppClock.now.difference(deadline).inDays : 0;
    final ring = birdRingNumber;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: done ? Colors.grey.shade50 : (isLate ? Colors.red.shade50 : null),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final medPlugin = pluginRegistry.getPlugin('medication');
          if (medPlugin == null) return;
          final page = medPlugin.onTaskCardTap(context, medInfo.task.birdId);
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: done
                      ? Colors.green.shade100
                      : (isLate ? Colors.red.shade100 : Colors.blue.shade100),
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
                      Text(medInfo.drugName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(medInfo.dosage,
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
                          TextSpan(text: birdName),
                          if (ring != null && ring.isNotEmpty)
                            TextSpan(text: '  #$ring'),
                          TextSpan(text: ' · ${medInfo.timeLabel}'),
                          if (isLate && !done)
                            TextSpan(text: ' (已逾期 $overdueDays 天)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 第三行：发布时间
                    _buildPublishTime(medInfo.task.createdAt),
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
