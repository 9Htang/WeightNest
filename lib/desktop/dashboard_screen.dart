import 'package:flutter/material.dart';
import '../services/bird_archive_service.dart';
import '../services/staff_service.dart';
import '../services/audit_log_service.dart';

/// 仪表盘 — 全局统计 + 异常告警 + 称重进度
class DashboardScreen extends StatefulWidget {
  final BirdArchiveService birdService;
  final StaffService staffService;
  final AuditLogService logService;
  final ValueNotifier<int> refreshKey;

  const DashboardScreen({
    super.key,
    required this.birdService,
    required this.staffService,
    required this.logService,
    required this.refreshKey,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<BirdInfo> _birds = [];
  List<UserInfo> _users = [];
  int _todayWeighs = 0;
  List<_DashboardAlert> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    widget.refreshKey.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshKey.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() => _loadDashboard();

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.birdService.fetchBirds(),
        widget.staffService.fetchUsers(),
        _fetchTodayWeighs(),
      ]);
      final birds = results[0] as List<BirdInfo>;
      final users = results[1] as List<UserInfo>;
      final todayWeighs = results[2] as int;
      final alerts = await _computeAlerts(birds);
      if (mounted) {
        setState(() {
          _birds = birds;
          _users = users;
          _todayWeighs = todayWeighs;
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<int> _fetchTodayWeighs() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final page = await widget.logService.fetchLogs(
        action: 'add_weight', startDate: startOfDay, pageSize: 200,
      );
      return page.total;
    } catch (_) {
      return 0;
    }
  }

  Future<List<_DashboardAlert>> _computeAlerts(List<BirdInfo> birds) async {
    final alerts = <_DashboardAlert>[];
    for (final bird in birds) {
      try {
        final weights = await widget.birdService.fetchWeights(bird.id);
        if (weights.length < 2) continue;
        final sorted = weights.toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
        final values = sorted.map((w) => w.weightG).toList();

        // Check last 3 values for consecutive decline
        final last3 = values.length >= 3 ? values.sublist(values.length - 3) : values;
        var consecDrop = 0;
        for (var i = 1; i < last3.length; i++) {
          if (last3[i] < last3[i - 1]) consecDrop++;
        }
        if (consecDrop >= 2) {
          final first = sorted[sorted.length - 3].weightG;
          final last = sorted.last.weightG;
          final pct = ((first - last) / first * 100).toStringAsFixed(1);
          alerts.add(_DashboardAlert(
            birdName: bird.name,
            speciesName: bird.speciesName,
            type: '体重下降',
            desc: '连续 ${consecDrop + 1} 次下降: ${first.toStringAsFixed(1)}g → ${last.toStringAsFixed(1)}g (-$pct%)',
            severity: consecDrop >= 3 ? _AlertSeverity.danger : _AlertSeverity.warning,
          ));
          continue;
        }

        // Check 7-day trend for older birds
        if (weights.length >= 4) {
          final last7 = weights.where((w) =>
            w.recordedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
          ).toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

          if (last7.length >= 3) {
            final vals7 = last7.map((w) => w.weightG).toList();
            final ema = _ema(vals7);
            final trend = (ema.last - ema.first) / ema.first * 100;
            if (trend < -3) {
              alerts.add(_DashboardAlert(
                birdName: bird.name,
                speciesName: bird.speciesName,
                type: '趋势下降',
                desc: '7日趋势下降 ${trend.abs().toStringAsFixed(1)}%',
                severity: trend < -8 ? _AlertSeverity.danger : _AlertSeverity.warning,
              ));
            }
          }
        }
      } catch (_) {}
    }
    // Sort: danger first, then warning
    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return alerts;
  }

  List<double> _ema(List<double> values, {double alpha = 0.3}) {
    if (values.isEmpty) return [];
    final r = <double>[values.first];
    for (var i = 1; i < values.length; i++) {
      r.add(values[i] * alpha + r.last * (1 - alpha));
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
        const SizedBox(height: 8),
        Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _loadDashboard, child: const Text('重试')),
      ]));
    }

    final activeUsers = _users.where((u) => u.isActive).length;
    final dangerCount = _alerts.where((a) => a.severity == _AlertSeverity.danger).length;
    final totalWeighTarget = _birds.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Text('概览', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // Stats cards
        Row(children: [
          Expanded(child: _StatCard(icon: Icons.pets, label: '鹦鹉总数', value: '${_birds.length}', color: theme.colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(icon: Icons.meeting_room, label: '活跃员工', value: '$activeUsers', color: Colors.indigo)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(icon: Icons.scale, label: '今日称重', value: '$_todayWeighs', sub: '/$totalWeighTarget 只', color: Colors.teal)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(icon: Icons.warning_amber, label: '异常提醒', value: '${_alerts.length}', color: dangerCount > 0 ? Colors.red : Colors.orange.shade700)),
        ]),
        const SizedBox(height: 24),

        // Today's weigh progress
        if (_birds.isNotEmpty) ...[
          _buildWeighProgress(theme, totalWeighTarget),
          const SizedBox(height: 24),
        ],

        // Alerts section
        if (_alerts.isNotEmpty) ...[
          Text('体重异常', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(_alerts.map((a) => _AlertCard(alert: a))),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(children: [
                  Icon(Icons.check_circle, size: 40, color: Colors.green.shade300),
                  const SizedBox(height: 8),
                  Text('所有鹦鹉体重正常', style: TextStyle(color: Colors.grey.shade600)),
                ]),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Bird summary list
        Text('鹦鹉概览', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...(_birds.map((b) => _BirdSummaryCard(bird: b, onTap: () {}))),
        if (_birds.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('暂无鹦鹉数据', style: TextStyle(color: Colors.grey.shade500))))),
      ]),
    );
  }

  Widget _buildWeighProgress(ThemeData theme, int total) {
    final pct = total > 0 ? (_todayWeighs / total).clamp(0.0, 1.0) : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.assignment_turned_in, size: 18),
            const SizedBox(width: 8),
            Text('今日称重进度', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: pct >= 1 ? Colors.green : theme.colorScheme.primary)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(pct >= 1 ? Colors.green : theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_todayWeighs / $total 只已称重', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

// ─── Dashboard Models ───

enum _AlertSeverity { danger, warning }

class _DashboardAlert {
  final String birdName, speciesName, type, desc;
  final _AlertSeverity severity;
  _DashboardAlert({required this.birdName, required this.speciesName, required this.type, required this.desc, required this.severity});
}

// ─── Widgets ───

class _StatCard extends StatelessWidget {
  final IconData icon; final String label, value; final String? sub; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          if (sub != null) Text(sub!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _DashboardAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isDanger = alert.severity == _AlertSeverity.danger;
    final color = isDanger ? Colors.red : Colors.orange;
    return Card(
      color: color.withAlpha(15),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(isDanger ? Icons.dangerous : Icons.warning_amber, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${alert.birdName}  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color.shade800)),
              TextSpan(text: alert.speciesName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ])),
            const SizedBox(height: 2),
            Text(alert.desc, style: TextStyle(fontSize: 12, color: color.shade700)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(4)),
            child: Text(alert.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ),
        ]),
      ),
    );
  }
}

class _BirdSummaryCard extends StatelessWidget {
  final BirdInfo bird;
  final VoidCallback onTap;

  const _BirdSummaryCard({required this.bird, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = bird.status == '正常' ? Colors.green : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(bird.name[0], style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bird.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${bird.speciesName} · ${bird.gender} · ${bird.ageDays}天',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: Text(bird.status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}
