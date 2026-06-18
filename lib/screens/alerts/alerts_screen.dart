import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/plugin.dart';
import '../../providers.dart';
import '../../services/alert_service.dart';
import '../birds/bird_detail_screen.dart';
import '../../widgets/section_header.dart';

enum AlertsMode { unconfirmed, all }

class AlertsScreen extends ConsumerWidget {
  final AlertsMode mode;
  const AlertsScreen({super.key, this.mode = AlertsMode.unconfirmed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAllMode = mode == AlertsMode.all;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAllMode ? '全部提醒' : '异常提醒'),
        actions: isAllMode
            ? null
            : [
                TextButton(
                  onPressed: () async {
                    final db = ref.read(databaseProvider);
                    final alerts = ref.read(alertListProvider).valueOrNull ?? [];
                    if (alerts.isEmpty) return;
                    await db.confirmAllAlerts(alerts);
                    ref.read(alertConfirmedVersionProvider.notifier).update((s) => s + 1);
                  },
                  child: const Text('全部确认', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ],
      ),
      body: isAllMode ? _AllAlertsList(theme: theme) : _UnconfirmedAlertsList(theme: theme),
    );
  }
}

class _UnconfirmedAlertsList extends ConsumerWidget {
  final ThemeData theme;
  const _UnconfirmedAlertsList({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertListProvider);
    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (alerts) => _buildList(context, ref, alerts, showConfirm: true),
    );
  }
}

class _AllAlertsList extends ConsumerWidget {
  final ThemeData theme;
  const _AllAlertsList({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(allAlertsProvider);
    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (alerts) {
        final anomalyAlerts = alerts.map((a) => a.alert).toList();
        return _buildList(context, ref, anomalyAlerts, showConfirm: false, statuses: alerts);
      },
    );
  }
}

Widget _buildList(BuildContext context, WidgetRef ref, List<AnomalyAlert> alerts,
    {required bool showConfirm, List<AlertWithStatus>? statuses}) {
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

  final danger = <AnomalyAlert>[];
  final warning = <AnomalyAlert>[];
  final statusMap = <String, AlertWithStatus>{};
  if (statuses != null) {
    for (final s in statuses) {
      statusMap['${s.alert.bird.bird.id}:${s.alert.type}:${s.alert.description}'] = s;
    }
  }

  for (final a in alerts) {
    if (a.severity == AlertSeverity.danger) {
      danger.add(a);
    } else {
      warning.add(a);
    }
  }

  return ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      if (danger.isNotEmpty) ...[
        SectionHeader(title: '⚠️ 严重异常 (${danger.length})', color: Colors.red),
        ...danger.map((a) => _AlertCard(
              alert: a,
              theme: Theme.of(context),
              showConfirm: showConfirm,
              status: statusMap['${a.bird.bird.id}:${a.type}:${a.description}'],
            )),
      ],
      if (warning.isNotEmpty) ...[
        SectionHeader(title: '⚡ 提示 (${warning.length})', color: Colors.orange),
        ...warning.map((a) => _AlertCard(
              alert: a,
              theme: Theme.of(context),
              showConfirm: showConfirm,
              status: statusMap['${a.bird.bird.id}:${a.type}:${a.description}'],
            )),
      ],
    ],
  );
}

class _AlertCard extends ConsumerWidget {
  final AnomalyAlert alert;
  final ThemeData theme;
  final bool showConfirm;
  final AlertWithStatus? status;

  const _AlertCard({
    required this.alert,
    required this.theme,
    this.showConfirm = true,
    this.status,
  });

  String _fmtTime(DateTime dt) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        Expanded(
                          child: Text(alert.bird.bird.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(alert.type,
                              style: TextStyle(
                                  fontSize: 13, color: iconColor, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(alert.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontSize: 13,
                        )),
                    const SizedBox(height: 4),
                    // 时间戳 + 确认状态
                    Row(
                      children: [
                        if (status != null) ...[
                          Icon(
                            status!.isConfirmed ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 14,
                            color: status!.isConfirmed ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status!.isConfirmed ? '已确认' : '未确认',
                            style: TextStyle(
                              fontSize: 12,
                              color: status!.isConfirmed ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                          Text(
                            _fmtTime(alert.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showConfirm)
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
