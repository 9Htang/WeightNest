import 'package:flutter/material.dart';

/// 大数字展示组件，带 tabular figures 对齐和可选动画
class StatNumber extends StatelessWidget {
  final String value;
  final String? label;
  final Color? color;
  final double valueSize;
  final IconData? icon;

  const StatNumber({
    super.key,
    required this.value,
    this.label,
    this.color,
    this.valueSize = 28,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveColor.withAlpha(30),
            ),
            child: Icon(icon, color: effectiveColor, size: 22),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: effectiveColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              color: effectiveColor.withAlpha(180),
            ),
          ),
        ],
      ],
    );
  }
}
