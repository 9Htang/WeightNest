import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../weigh/weigh_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeightNest'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.scale,
                size: 64,
                color: theme.colorScheme.primary.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                '鹦鹉体重记录',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '快速录入 · 多人协同 · 局域网同步',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 48),

              // 称重入口
              SizedBox(
                width: 260,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeighScreen()),
                  ),
                  icon: const Icon(Icons.monitor_weight, size: 24),
                  label: const Text('开始称重', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),

              // 快捷入口
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _NavChip(
                    icon: Icons.list_alt,
                    label: '鹦鹉列表',
                    onTap: () {},
                  ),
                  _NavChip(
                    icon: Icons.meeting_room,
                    label: '房间管理',
                    onTap: () {},
                  ),
                  _NavChip(
                    icon: Icons.assignment_turned_in,
                    label: '今日任务',
                    onTap: () {},
                  ),
                  _NavChip(
                    icon: Icons.warning_amber,
                    label: '异常提醒',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
