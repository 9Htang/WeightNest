import 'package:flutter/material.dart';
import 'feather_icon.dart';

/// 空状态占位组件
class EmptyState extends StatelessWidget {
  final String message;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget icon;

  EmptyState({
    super.key,
    required this.message,
    this.hint,
    this.actionLabel,
    this.onAction,
    Widget? icon,
  }) : icon = icon ?? const FeatherIcon(size: 36);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest.withAlpha(120),
              ),
              child: icon,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
