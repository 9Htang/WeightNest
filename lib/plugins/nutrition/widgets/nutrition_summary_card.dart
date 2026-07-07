import 'package:flutter/material.dart';
import '../nutrition_math.dart';

/// 营养摘要卡片 —— 展示食谱关键营养指标（蛋白、脂肪、钙磷比、能量、总克数）。
class NutritionSummaryCard extends StatelessWidget {
  final NutritionSummary summary;

  const NutritionSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('营养分析',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!summary.dataSufficient)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('数据不足',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.orange.shade800)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 总克数
            _MetricRow(
              label: '每日总量',
              value: '${summary.totalGrams.toStringAsFixed(1)} g',
              icon: Icons.scale,
              iconColor: theme.colorScheme.primary,
            ),
            const Divider(height: 16),
            // 关键营养网格
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 8,
              children: [
                _NutrientChip(
                    label: '粗蛋白', value: summary.protein, unit: '%'),
                _NutrientChip(
                    label: '粗脂肪', value: summary.fat, unit: '%'),
                _NutrientChip(
                    label: '粗纤维', value: summary.fiber, unit: '%'),
                _NutrientChip(
                    label: '水分', value: summary.moisture, unit: '%'),
                _NutrientChip(
                    label: '代谢能',
                    value: summary.energy,
                    unit: 'kcal/100g'),
                _NutrientChip(
                    label: '钙磷比', value: summary.caPRatio, unit: ''),
                _NutrientChip(
                    label: '钙', value: summary.calcium, unit: '%'),
                _NutrientChip(
                    label: '磷', value: summary.phosphorus, unit: '%'),
                _NutrientChip(
                    label: 'Omega-3', value: summary.omega3, unit: '%'),
                _NutrientChip(
                    label: 'Omega-6', value: summary.omega6, unit: '%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value == null
        ? '—'
        : (value == value!.roundToDouble()
            ? value!.toStringAsFixed(0)
            : value!.toStringAsFixed(2));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const Spacer(),
          Text(
            value == null ? displayValue : '$displayValue$unit',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: value == null ? theme.disabledColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
