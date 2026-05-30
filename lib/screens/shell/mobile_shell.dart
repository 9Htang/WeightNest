import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../worker/worker_screen.dart';
import '../tasks/tasks_screen.dart';
import '../birds/birds_screen.dart';
import '../settings/settings_screen.dart';
import '../weigh/weigh_screen.dart';
import '../login/login_screen.dart';
import '../alerts/alerts_screen.dart';

Future<void> _showLogoutConfirm(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('退出登录'),
      content: const Text('确定要退出当前账号吗？'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出')),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(workerProvider.notifier).clear();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabData(Icons.home_outlined, Icons.home_rounded, '首页'),
    _TabData(Icons.assignment_outlined, Icons.assignment, '任务'),
    _TabData(Icons.monitor_weight_outlined, Icons.monitor_weight, '称重'),
    _TabData(Icons.pets_outlined, Icons.pets, '鹦鹉'),
    _TabData(Icons.settings_outlined, Icons.settings, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final worker = ref.watch(workerProvider);

    if (worker.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!worker.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeShell(),
          TasksScreen(),
          WeighScreen(roomId: null),
          BirdsScreen(),
          SettingsScreen(),
        ],
      ),
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
    final worker = ref.watch(workerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeightNest'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              worker.displayName.isNotEmpty
                  ? worker.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: () => _showLogoutConfirm(context, ref),
          ),
        ],
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
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(todayTasksProvider);
    final alertCount = ref.watch(alertCountProvider);
    final roomsAsync = ref.watch(allRoomsProvider);
    final myRoomsAsync = ref.watch(myRoomsProvider);
    final worker = ref.watch(workerProvider);
    final isAdmin = worker.isAdmin;

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
          if (alertCount > 0) _AlertBannerWarm(count: alertCount),

          const SizedBox(height: 16),

          // ── 房间列表 ──
          Text(
              worker.isSelected && !isAdmin ? '我的房间' : '房间',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          (worker.isSelected && !isAdmin ? myRoomsAsync : roomsAsync).when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rooms) => rooms.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('暂无房间，请先创建房间',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha(140))),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rooms
                        .map((r) => _RoomCardWarm(room: r))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // ── 快捷操作 ──
          Text('快捷操作',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                icon: Icons.list_alt,
                label: '鹦鹉列表',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BirdsScreen())),
              ),
              _QuickChip(
                icon: Icons.assignment_turned_in,
                label: '称重任务',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TasksScreen())),
              ),
              _QuickChip(
                icon: Icons.warning_amber,
                label: '异常提醒',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AlertsScreen())),
              ),
              _QuickChip(
                icon: Icons.scale,
                label: '快速称重',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            WeighScreen(roomId: null))),
              ),
            ],
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
                    label: '待称重',
                    value: '$pending',
                    color: const Color(0xFFC4956A)),
                _StatItemWarm(
                    icon: Icons.check_circle,
                    label: '已完成',
                    value: '$done',
                    color: const Color(0xFF6B8F71)),
                _StatItemWarm(
                    icon: Icons.pie_chart,
                    label: '完成率',
                    value: '$pct%',
                    color: scheme.primary),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? done / total : 0,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                color: const Color(0xFF6B8F71),
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
  final int count;
  const _AlertBannerWarm({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFC44F4F).withAlpha(20),
        border: Border.all(color: const Color(0xFFC44F4F).withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AlertsScreen())),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC44F4F).withAlpha(30),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFC44F4F), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('$count 只鹦鹉存在异常',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC44F4F))),
              ),
              Icon(Icons.chevron_right,
                  color: const Color(0xFFC44F4F).withAlpha(160)),
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
      width: (MediaQuery.of(context).size.width - 40) / 2 - 4,
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
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WeighScreen(roomId: room.id))),
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
                        color: const Color(0xFFC4956A).withAlpha(40),
                      ),
                      child: const Icon(Icons.meeting_room_rounded,
                          size: 18, color: Color(0xFFC4956A)),
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


