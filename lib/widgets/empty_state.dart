import 'package:flutter/material.dart';

/// 空状态占位组件
class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.pets_outlined,
  });

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
              child: Icon(
                icon,
                size: 36,
                color: scheme.onSurface.withAlpha(100),
              ),
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
