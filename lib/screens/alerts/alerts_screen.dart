import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/plugin.dart';
import '../../providers.dart';
import '../../services/alert_service.dart';
import '../birds/bird_detail_screen.dart';
import '../../widgets/section_header.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('异常提醒'),
        actions: [
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final alerts = alertsAsync.valueOrNull ?? [];
              if (alerts.isEmpty) return;
              await db.confirmAllAlerts(alerts);
              ref.read(alertConfirmedVersionProvider.notifier).update((s) => s + 1);
            },
            child: const Text('全部确认', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 72, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text('一切正常 🎉',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('没有发现异常情况',
                      style: TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
            );
          }

          final danger = alerts.where((a) => a.severity == AlertSeverity.danger).toList();
          final warning = alerts.where((a) => a.severity == AlertSeverity.warning).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (danger.isNotEmpty) ...[
                SectionHeader(title: '⚠️ 严重异常 (${danger.length})', color: Colors.red),
                ...danger.map((a) => _AlertCard(alert: a, theme: theme)),
              ],
              if (warning.isNotEmpty) ...[
                SectionHeader(title: '⚡ 提示 (${warning.length})', color: Colors.orange),
                ...warning.map((a) => _AlertCard(alert: a, theme: theme)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  final AnomalyAlert alert;
  final ThemeData theme;

  const _AlertCard({required this.alert, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDanger = alert.severity == AlertSeverity.danger;
    final bgColor = isDanger ? Colors.red.shade50 : Colors.orange.shade50;
    final iconColor = isDanger ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: bgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: alert.bird)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDanger ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: iconColor, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(alert.bird.bird.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(alert.type,
                              style: TextStyle(fontSize: 13, color: iconColor, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(alert.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
              // 确认按钮
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 22),
                tooltip: '确认',
                color: Colors.grey,
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await db.confirmAlert(alert.bird.bird.id, alert.type, alert.description);
                  ref.read(alertConfirmedVersionProvider.notifier).update((s) => s + 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
