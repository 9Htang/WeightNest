import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../database/database.dart';

class _TrendSegment {
  final List<FlSpot> spots;
  final bool isDown;
  _TrendSegment({required this.spots, required this.isDown});
}

class WeightChartWidget extends StatefulWidget {
  final List<Weight> weights;
  final double chartHeight;

  const WeightChartWidget({
    super.key,
    required this.weights,
    this.chartHeight = 300,
  });

  @override
  State<WeightChartWidget> createState() => _WeightChartWidgetState();
}

class _WeightChartWidgetState extends State<WeightChartWidget> {
  double _zoomLevel = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_TrendSegment> _splitTrendSegments(List<Weight> sorted) {
    if (sorted.length < 2) {
      return [
        _TrendSegment(
          spots: sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weightG)).toList(),
          isDown: false,
        )
      ];
    }
    final segments = <_TrendSegment>[];
    var segStart = 0;
    var currentIsDown = sorted[1].weightG < sorted[0].weightG;
    for (var i = 1; i < sorted.length; i++) {
      final stepIsDown = sorted[i].weightG < sorted[i - 1].weightG;
      if (stepIsDown != currentIsDown) {
        segments.add(_TrendSegment(
          spots: List.generate(i - segStart, (j) => FlSpot((segStart + j).toDouble(), sorted[segStart + j].weightG)),
          isDown: currentIsDown,
        ));
        segStart = i - 1;
        currentIsDown = stepIsDown;
      }
    }
    segments.add(_TrendSegment(
      spots: List.generate(sorted.length - segStart, (j) => FlSpot((segStart + j).toDouble(), sorted[segStart + j].weightG)),
      isDown: currentIsDown,
    ));
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.weights.isEmpty) {
      return _emptyState();
    }
    final sorted = widget.weights.reversed.toList();
    final minWeight = sorted.map((w) => w.weightG).reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = sorted.map((w) => w.weightG).reduce((a, b) => a > b ? a : b) + 2;
    final segments = _splitTrendSegments(sorted);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.show_chart, size: 18),
                const SizedBox(width: 6),
                Text('体重趋势 (${sorted.length} 条)', style: theme.textTheme.titleSmall),
                const SizedBox(width: 12),
                _buildLegend(theme),
              ],
            ),
            const SizedBox(height: 8),
            _buildZoomChips(),
            const SizedBox(height: 10),
            _buildChart(sorted, minWeight, maxWeight, segments, theme),
            const SizedBox(height: 4),
            Text('← 左右拖动查看不同时间段 · 鼠标滚轮/拖动平移 · 橙色空心圆=非空腹',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: SizedBox(
        height: 200,
        child: Center(child: Text('暂无体重记录', style: TextStyle(color: Colors.grey.shade400))),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text('上升/持平', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ]),
      const SizedBox(width: 8),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, color: Colors.red.shade400),
        const SizedBox(width: 4),
        Text('下降', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ]),
      const SizedBox(width: 8),
      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange.shade600, width: 1.5))),
      const SizedBox(width: 4),
      Text('非空腹', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
    ]);
  }

  Widget _buildZoomChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _zoomChip('适应宽度', 0),
        _zoomChip('2x', 2),
        _zoomChip('4x', 4),
        _zoomChip('8x', 8),
      ]),
    );
  }

  Widget _zoomChip(String label, double level) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: _zoomLevel == level,
        onSelected: (_) => setState(() => _zoomLevel = level),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildChart(List<Weight> sorted, double minWeight, double maxWeight,
      List<_TrendSegment> segments, ThemeData theme) {
    return LayoutBuilder(builder: (_, constraints) {
      final baseWidth = constraints.maxWidth - 56;
      final chartWidth = _zoomLevel <= 0
          ? baseWidth
          : (sorted.length * 12.0 * _zoomLevel).clamp(baseWidth, 8000.0);
      final showDots = _zoomLevel >= 4 || sorted.length <= 30;

      return SizedBox(
        height: widget.chartHeight,
        child: Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              _scrollController.jumpTo(
                (_scrollController.offset + e.scrollDelta.dx).clamp(0, _scrollController.position.maxScrollExtent),
              );
            }
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: SizedBox(
              width: chartWidth,
              height: widget.chartHeight,
              child: LineChart(
                duration: const Duration(milliseconds: 250),
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxWeight - minWeight) / 5).clamp(1, 50).ceilToDouble(),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}g', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                          final step = (sorted.length / 10).ceil().clamp(1, 50);
                          if (i % step != 0 && i != sorted.length - 1) return const SizedBox.shrink();
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(sorted[i].recordedAt.toString().substring(5, 10), style: const TextStyle(fontSize: 9)),
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
                  lineBarsData: segments.map((seg) => LineChartBarData(
                    spots: seg.spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: seg.isDown ? Colors.red.shade400 : theme.colorScheme.primary,
                    barWidth: _zoomLevel >= 4 ? 2.5 : 1.8,
                    dotData: FlDotData(
                      show: showDots,
                      getDotPainter: (spot, _, __, ___) {
                        final i = spot.x.toInt();
                        if (i < 0 || i >= sorted.length) {
                          return FlDotCirclePainter(radius: 2, color: seg.isDown ? Colors.red.shade400 : theme.colorScheme.primary, strokeWidth: 0);
                        }
                        final w = sorted[i];
                        if (!w.isFasting) {
                          return FlDotCirclePainter(radius: 3.5, color: Colors.white, strokeWidth: 1.5, strokeColor: Colors.orange.shade600);
                        }
                        return FlDotCirclePainter(radius: 2.5, color: seg.isDown ? Colors.red.shade400 : theme.colorScheme.primary, strokeWidth: 0);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (seg.isDown ? Colors.red : theme.colorScheme.primary).withAlpha(20),
                    ),
                  )).toList(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.toInt();
                        final w = sorted[i];
                        final prevW = i > 0 ? sorted[i - 1].weightG : w.weightG;
                        final isDown = w.weightG < prevW;
                        return LineTooltipItem(
                          '${w.weightG.toStringAsFixed(1)}g${isDown ? " ↓" : ""}${w.isFasting ? "" : " (非空腹)"}  ${w.recordedAt.toString().substring(0, 16).replaceAll('T', ' ')}',
                          TextStyle(color: Colors.white, fontSize: 11, fontWeight: isDown ? FontWeight.bold : FontWeight.normal),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
