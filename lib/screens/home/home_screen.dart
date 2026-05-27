import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../weigh/weigh_screen.dart';
import '../birds/birds_screen.dart';
import '../tasks/tasks_screen.dart';
import '../alerts/alerts_screen.dart';
import '../species/species_screen.dart';
import '../rooms/rooms_screen.dart';
import '../settings/settings_screen.dart';
import '../connect/connect_screen.dart';
import '../worker/worker_screen.dart';
import '../../../widgets/server_status_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(initDefaultsProvider);
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(todayTasksProvider);
    final alertsAsync = ref.watch(alertCountProvider);
    final roomsAsync = ref.watch(allRoomsProvider);
    final myRoomsAsync = ref.watch(myRoomsProvider);
    final worker = ref.watch(workerProvider);
    final isAdmin = worker.userId == 1; // admin is always user id 1

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeightNest'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WorkerSelectScreen())),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: worker.isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  child: Text(
                    worker.isSelected ? worker.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      persistentFooterButtons: const [ServerStatusBar()],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayTasksProvider);
          ref.invalidate(alertCountProvider);
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
                final pending = tasks.where((t) => t.task.status == '待完成').length;
                final done = tasks.where((t) => t.task.status == '已完成').length;
                return _StatsCard(pending: pending, done: done, ref: ref);
              },
            ),
            const SizedBox(height: 16),

            // ── 异常提醒入口 ──
            alertsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (alertCount) => _AlertBanner(count: alertCount),
            ),

            const SizedBox(height: 16),

            // ── 房间列表 ──
            Text(worker.isSelected && !isAdmin ? '我的房间' : '房间',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            (worker.isSelected && !isAdmin ? myRoomsAsync : roomsAsync).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (rooms) => rooms.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('暂无房间，请先创建房间')),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rooms.map((r) => _RoomCard(room: r)).toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // ── 快捷操作 ──
            Text('快捷操作', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionBtn(
                  icon: Icons.list_alt, label: '鹦鹉列表',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirdsScreen())),
                ),
                _ActionBtn(
                  icon: Icons.assignment_turned_in, label: '称重任务',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                ),
                _ActionBtn(
                  icon: Icons.pets, label: '品种管理',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeciesScreen())),
                ),
                _ActionBtn(
                  icon: Icons.link, label: '连接服务器',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectScreen())),
                ),
                _ActionBtn(
                  icon: Icons.meeting_room, label: '房间管理',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomsScreen())),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// 今日统计卡片
class _StatsCard extends ConsumerWidget {
  final int pending, done;
  final WidgetRef ref;

  const _StatsCard({required this.pending, required this.done, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final theme = Theme.of(context);
    final total = pending + done;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    return Card(
      color: theme.colorScheme.primaryContainer.withAlpha(100),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(icon: Icons.scale, label: '待称重', value: '$pending', color: Colors.orange),
                _StatItem(icon: Icons.check_circle, label: '已完成', value: '$done', color: Colors.green),
                _StatItem(icon: Icons.pie_chart, label: '完成率', value: '$pct%', color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? done / total : 0,
                      minHeight: 8,
                      backgroundColor: Colors.orange.shade100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pending > 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TasksScreen())),
                  icon: const Icon(Icons.assignment_turned_in, size: 20),
                  label: Text('查看任务 ($pending 只)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withAlpha(180))),
      ],
    );
  }
}

/// 架构骨架
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

/// 异常提醒横幅
class _AlertBanner extends StatelessWidget {
  final int count;
  const _AlertBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      color: Colors.red.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AlertsScreen())),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('$count 只鹦鹉存在异常',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.red.shade800)),
              ),
              const Icon(Icons.chevron_right, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

/// 房间卡片
class _RoomCard extends ConsumerWidget {
  final Room room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 获取该房间的鸟
    final birdsAsync = ref.watch(roomBirdsProvider(room.id));

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40) / 2 - 4,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => WeighScreen(roomId: room.id))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room, size: 18, color: Colors.brown),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(room.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                birdsAsync.when(
                  loading: () => const SizedBox(height: 16, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const Text('-'),
                  data: (birds) => Text('${birds.length} 只鹦鹉',
                      style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(140), fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 快捷操作按钮
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2 - 4,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
