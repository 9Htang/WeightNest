import 'package:flutter/material.dart';

/// 温暖风格通用卡片，支持渐变背景、细边框、可选阴影
class WarmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;

  const WarmCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.color,
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.surfaceContainerLow;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: gradient,
      color: gradient == null ? effectiveColor : null,
      border: Border.all(
        color: scheme.outlineVariant.withAlpha(50),
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withAlpha(8),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );

    final card = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Container(
            decoration: decoration,
            margin: margin,
            child: card,
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      margin: margin,
      child: card,
    );
  }
}
