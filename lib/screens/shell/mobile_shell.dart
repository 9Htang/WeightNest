import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/user_repository.dart';
import '../../core/plugin_registry.dart';
import '../../utils/app_version.dart';
import '../worker/worker_screen.dart';
import '../tasks/tasks_screen.dart';
import '../birds/birds_screen.dart';
import '../rooms/rooms_screen.dart';
import '../settings/settings_screen.dart';
import '../species/species_screen.dart';
import '../alerts/alerts_screen.dart';
import '../enclosures/enclosure_management_screen.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _dateCheckTimer;

  // 懒加载 Tab：仅构建当前激活的标签页，首次访问后缓存
  final List<Widget?> _tabCache = List.filled(4, null);

  static const _tabs = [
    _TabData(Icons.home_outlined, Icons.home_rounded, '首页'),
    _TabData(Icons.assignment_outlined, Icons.assignment, '任务'),
    _TabData(Icons.pets_outlined, Icons.pets, '鹦鹉'),
    _TabData(Icons.settings_outlined, Icons.settings, '设置'),
  ];

  Widget _makeTab(int i) => switch (i) {
    0 => const HomeShell(),
    1 => const TasksScreen(),
    2 => const BirdsScreen(),
    3 => const SettingsScreen(),
    _ => const HomeShell(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startDateCheckTimer();
    // 首帧渲染后执行数据库初始化，不阻塞首页显示
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAfterBuild());
  }

  Future<void> _initAfterBuild() async {
    try {
      // 1. 确保 DB 已迁移、种子数据已创建
      await ref.read(initDefaultsProvider.future);
      // 2. 自动选择第一个用户（首次启动无缓存用户时）
      if (!ref.read(workerProvider).isSelected) {
        final users = await ref.read(databaseProvider).getAllUsers();
        if (users.isNotEmpty) {
          final u = users.first;
          await ref.read(workerProvider.notifier).selectUser(
              u.id, u.displayName, u.role, username: u.username);
        }
      }
      // 3. 预生成今日任务
      await ref.read(databaseProvider).generateTodayTasks();
      // 4. 刷新任务列表（首帧查询时可能还没有生成的任务）
      ref.invalidate(todayTasksProvider);
      // 5. 触发异常检测（由 alertListProvider 统一管理，避免重复 detectAll）
      ref.invalidate(alertListProvider);
      ref.invalidate(hasRecentAlertRecordsProvider);
    } catch (_) {
      // DB 异常时静默失败，首页在加载状态中显示错误
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(databaseProvider).generateTodayTasks();
      ref.invalidate(todayTasksProvider);
      ref.invalidate(alertListProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateCheckTimer?.cancel();
    super.dispose();
  }

  void _startDateCheckTimer() {
    _dateCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        ref.read(databaseProvider).generateTodayTasks();
        ref.invalidate(todayTasksProvider);
        ref.invalidate(alertListProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: _tabCache[_currentIndex] ??= _makeTab(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
        },
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer.withAlpha(100),
        surfaceTintColor: Colors.transparent,
        destinations: List.generate(_tabs.length, (i) {
          final t = _tabs[i];
          return NavigationDestination(
            icon: Icon(t.outlinedIcon, size: 24),
            selectedIcon: Icon(t.filledIcon, size: 24),
            label: t.label,
          );
        }),
      ),
    );
  }
}

class _TabData {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;

  const _TabData(this.outlinedIcon, this.filledIcon, this.label);
}

/// Wrapper for HomeScreen to use within the shell (no Scaffold wrapper needed)
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: getAppVersion(),
          builder: (context, snapshot) {
            final v = snapshot.data ?? '';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('WeightNest'),
                const SizedBox(width: 8),
                Text(
                  'v$v',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(110),
                  ),
                ),
              ],
            );
          },
        ),
        actions: const [],
      ),
      body: const HomeScreenContent(),
    );
  }
}

/// Extracted home screen body without Scaffold
class HomeScreenContent extends ConsumerWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(initDefaultsProvider);
    ref.watch(pluginToggleVersionProvider); // 插件开关时重建快捷操作/称重按钮
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(todayTasksProvider);
    final hasRecentAlerts = ref.watch(hasRecentAlertRecordsProvider);
    final roomsAsync = ref.watch(allRoomsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayTasksProvider);
        ref.invalidate(alertListProvider);
        ref.invalidate(allRoomsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 今日统计卡片 ──
          tasksAsync.when(
            loading: () => const _StatsSkeleton(),
            error: (e, _) => Center(child: Text('$e')),
            data: (tasks) {
              final pending =
                  tasks.where((t) => t.task.status == '待完成').length;
              final done =
                  tasks.where((t) => t.task.status == '已完成').length;
              return _StatsCardWarm(
                  pending: pending, done: done, ref: ref);
            },
          ),
          const SizedBox(height: 16),

          // ── 异常提醒入口 ──
          if (hasRecentAlerts.valueOrNull == true)
            _AlertBannerWarm(),

          const SizedBox(height: 16),

          // ── 快捷操作（在房间列表上方）──
          Text('快捷操作',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                icon: Icons.warning_amber,
                label: '异常提醒',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AlertsScreen(mode: AlertsMode.all))),
              ),
              _QuickChip(
                icon: Icons.pets,
                label: '品种管理',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SpeciesScreen())),
              ),
              // 插件贡献的快捷操作
              ...pluginRegistry.enabledPlugins.expand((p) => p.quickActions).map(
                (a) => _QuickChip(
                  icon: a.icon,
                  label: a.label,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => a.builder())),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 房间列表 ──
          Row(
            children: [
              Expanded(
                child: Text('房间',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 22),
                tooltip: '管理房间',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoomsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          roomsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rooms) => rooms.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text('暂无房间，请先创建房间',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(140))),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RoomsScreen()),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('创建房间'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RoomCardWarm(room: rooms[i]),
                  ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// 温暖风格统计卡片
class _StatsCardWarm extends ConsumerWidget {
  final int pending, done;
  final WidgetRef ref;

  const _StatsCardWarm(
      {required this.pending, required this.done, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = pending + done;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withAlpha(120),
            scheme.secondaryContainer.withAlpha(80),
          ],
        ),
        border: Border.all(
          color: scheme.primaryContainer.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItemWarm(
                    icon: Icons.scale,
                    label: '待完成',
                    value: '$pending',
                    color: scheme.secondary),
                _StatItemWarm(
                    icon: Icons.check_circle,
                    label: '已完成',
                    value: '$done',
                    color: scheme.primary),
                _StatItemWarm(
                    icon: Icons.pie_chart,
                    label: '完成率',
                    value: '$pct%',
                    color: scheme.tertiary),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? done / total : 0,
                minHeight: 10,
                backgroundColor: scheme.primary.withAlpha(30),
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            if (pending > 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TasksScreen())),
                  icon:
                      const Icon(Icons.assignment_turned_in, size: 20),
                  label: Text('查看任务 ($pending 只)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItemWarm extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatItemWarm(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(30),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style: TextStyle(fontSize: 12, color: color.withAlpha(180))),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
}

class _AlertBannerWarm extends StatelessWidget {
  final int? count;
  const _AlertBannerWarm({this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = count != null ? '$count 只鹦鹉存在异常' : '查看异常提醒';

    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.error.withAlpha(20),
        border: Border.all(color: scheme.error.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AlertsScreen(mode: AlertsMode.unconfirmed))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.error.withAlpha(30),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: scheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.error)),
              ),
              Icon(Icons.chevron_right,
                  color: scheme.error.withAlpha(160)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCardWarm extends ConsumerWidget {
  final Room room;
  const _RoomCardWarm({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final birdsAsync = ref.watch(roomBirdsProvider(room.id));

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: scheme.outlineVariant.withAlpha(60),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => BirdsScreen(roomId: room.id))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: scheme.secondary.withAlpha(40),
                      ),
                      child: Icon(Icons.meeting_room_rounded,
                          size: 18, color: scheme.secondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        room.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 房间设置按钮
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      tooltip: '房间设置',
                      color: scheme.onSurface.withAlpha(120),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _onRoomTap(context, ref, room),
                    ),
                    // 插件提供的房间称重按钮
                    ...(() {
                      final action = pluginRegistry.enabledPlugins
                          .map((p) => p.roomWeighAction)
                          .firstWhere((a) => a != null, orElse: () => null);
                      if (action == null) return const <Widget>[];
                      return <Widget>[
                        IconButton(
                          icon: Icon(action.icon, size: 20),
                          tooltip: action.tooltip,
                          color: scheme.primary,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => action.builder(room.id),
                              ),
                            );
                          },
                        ),
                      ];
                    })(),
                  ],
                ),
                const SizedBox(height: 12),
                birdsAsync.when(
                  loading: () => const SizedBox(
                    height: 16,
                    child: Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const Text('-'),
                  data: (birds) => Text(
                    '${birds.length} 只鹦鹉',
                    style: TextStyle(
                      color: scheme.onSurface.withAlpha(140),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 房间设置按钮：进入容器管理页面
void _onRoomTap(BuildContext context, WidgetRef ref, Room room) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EnclosureManagementScreen(
        roomId: room.id,
        roomName: room.name,
      ),
    ),
  );
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2 - 4,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: scheme.primaryContainer.withAlpha(100),
                  ),
                  child:
                      Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
