import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/bird_archive_service.dart';

/// 鹦鹉全息档案页面
class BirdArchiveScreen extends StatefulWidget {
  final BirdArchiveService service;

  const BirdArchiveScreen({super.key, required this.service});

  @override
  State<BirdArchiveScreen> createState() => _BirdArchiveScreenState();
}

class _BirdArchiveScreenState extends State<BirdArchiveScreen> {
  List<BirdInfo> _birds = [];
  BirdInfo? _selected;
  List<WeightRecord> _weights = [];
  bool _loading = false;
  bool _loadingWeights = false;
  String? _error;
  final _searchCtrl = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadBirds();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadBirds());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBirds({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final birds = await widget.service.fetchBirds(search: search);
      setState(() { _birds = birds; _loading = false; });
      // 保留当前选中
      if (_selected != null) {
        final updated = birds.where((b) => b.id == _selected!.id).firstOrNull;
        if (updated != null) _selected = updated;
      } else if (birds.isNotEmpty) {
        _selectBird(birds.first);
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _selectBird(BirdInfo bird) async {
    setState(() { _selected = bird; _loadingWeights = true; });
    try {
      final weights = await widget.service.fetchWeights(bird.id);
      setState(() { _weights = weights; _loadingWeights = false; });
    } catch (_) {
      setState(() { _weights = []; _loadingWeights = false; });
    }
  }

  void _search() {
    _loadBirds(search: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // ── 左侧：鹦鹉列表 ──
        SizedBox(
          width: 280,
          child: Column(
            children: [
              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '搜索名称/脚环号...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _search(); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const Divider(height: 1),
              // 列表
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError()
                        : _birds.isEmpty
                            ? Center(child: Text('暂无鹦鹉', style: TextStyle(color: Colors.grey.shade400)))
                            : ListView.builder(
                                itemCount: _birds.length,
                                itemBuilder: (context, i) {
                                  final bird = _birds[i];
                                  final isSelected = _selected?.id == bird.id;
                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(80),
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                                      child: Text(
                                        bird.name.isNotEmpty ? bird.name[0] : '?',
                                        style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontSize: 13),
                                      ),
                                    ),
                                    title: Text(bird.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${bird.speciesName}  ${bird.gender}  ${bird.ageDays}天',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: bird.ringNumber != null
                                        ? Text(bird.ringNumber!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500))
                                        : null,
                                    onTap: () => _selectBird(bird),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),

        // ── 右侧：详情 ──
        Expanded(child: _selected == null ? _buildEmpty() : _buildDetail(theme)),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 36, color: Colors.red.shade300),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _loadBirds(), child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('选择一只鹦鹉查看详情', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDetail(ThemeData theme) {
    final bird = _selected!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 基本信息卡片 ──
          _buildInfoCard(theme, bird),
          const SizedBox(height: 20),

          // ── 体重趋势图 ──
          _buildWeightChart(theme),
          const SizedBox(height: 20),

          // ── 体重记录表 ──
          _buildWeightTable(theme),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, BirdInfo bird) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(bird.name[0], style: const TextStyle(fontSize: 20, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bird.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${bird.speciesName} · ${bird.gender}', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bird.status == '正常' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(bird.status, style: TextStyle(fontSize: 12, color: bird.status == '正常' ? Colors.green : Colors.orange)),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                _infoItem('脚环号', bird.ringNumber ?? '-'),
                _infoItem('品种', bird.speciesName),
                _infoItem('房间', bird.roomName ?? '-'),
                _infoItem('日龄', '${bird.ageDays} 天'),
                _infoItem('出生日期', bird.birthDate.toString().substring(0, 10)),
              ],
            ),
            if (bird.notes != null && bird.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('备注: ${bird.notes}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildWeightChart(ThemeData theme) {
    if (_loadingWeights) {
      return const Card(child: SizedBox(height: 250, child: Center(child: CircularProgressIndicator())));
    }
    if (_weights.isEmpty) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('暂无体重记录', style: TextStyle(color: Colors.grey.shade400))),
        ),
      );
    }

    // 按时间升序排列
    final sorted = _weights.reversed.toList();
    final minWeight = sorted.map((w) => w.weightG).reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = sorted.map((w) => w.weightG).reduce((a, b) => a > b ? a : b) + 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 18),
                const SizedBox(width: 6),
                Text('体重趋势 (${_weights.length} 条)', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxWeight - minWeight) / 4).clamp(1, 50).ceilToDouble(),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}g', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (sorted.length / 6).ceilToDouble().clamp(1, 100),
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              sorted[i].recordedAt.toString().substring(5, 10),
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minWeight,
                  maxY: maxWeight,
                  lineBarsData: [
                    LineChartBarData(
                      spots: sorted.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.weightG);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: theme.colorScheme.primary,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: sorted.length <= 60,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 2.5,
                          color: theme.colorScheme.primary,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withAlpha(25),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.toInt();
                        final w = sorted[i];
                        return LineTooltipItem(
                          '${w.weightG}g  ${w.recordedAt.toString().substring(0, 16).replaceAll('T', ' ')}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTable(ThemeData theme) {
    if (_weights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 6),
                Text('体重记录', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _weights.length,
                itemBuilder: (context, i) {
                  final w = _weights[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text(w.recordedAt.toString().substring(0, 19).replaceAll('T', ' '),
                            style: const TextStyle(fontSize: 11)),
                        const Spacer(),
                        Text('${w.weightG.toStringAsFixed(1)} g',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: w.isFasting ? theme.colorScheme.primary : Colors.orange)),
                        if (!w.isFasting)
                          const Text(' *', style: TextStyle(fontSize: 11, color: Colors.orange)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
