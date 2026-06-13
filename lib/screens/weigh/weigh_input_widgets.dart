import 'package:flutter/material.dart';

/// 体重数字显示区 — 大字体体重 + 单位 + 消息
class WeighDisplay extends StatelessWidget {
  final String weightText;
  final String? message;
  final ThemeData theme;

  const WeighDisplay({
    super.key,
    required this.weightText,
    this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = weightText.isEmpty ? '0.0' : weightText;
    return Column(
      children: [
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '克 (g)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            style: TextStyle(
              color: message!.startsWith('✅') ? Colors.green : Colors.orange,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

/// 快速调整按钮 — -1g / +1g / 空腹开关
class QuickAdjustBar extends StatelessWidget {
  final bool isFasting;
  final ThemeData theme;
  final VoidCallback onMinus1;
  final VoidCallback onMinus10;
  final VoidCallback onPlus1;
  final VoidCallback onPlus10;
  final VoidCallback onToggleFasting;

  const QuickAdjustBar({
    super.key,
    required this.isFasting,
    required this.theme,
    required this.onMinus1,
    required this.onMinus10,
    required this.onPlus1,
    required this.onPlus10,
    required this.onToggleFasting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _QuickBtn(
            icon: Icons.remove,
            label: '-1g',
            onTap: onMinus1,
            onLongPress: onMinus10,
          ),
          const SizedBox(width: 16),
          _QuickBtn(
            icon: Icons.add,
            label: '+1g',
            onTap: onPlus1,
            onLongPress: onPlus10,
          ),
          const SizedBox(width: 16),
          ActionChip(
            avatar: Icon(
              isFasting ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: isFasting ? Colors.white : null,
            ),
            label: const Text('空腹'),
            backgroundColor: isFasting ? theme.colorScheme.primary : null,
            onPressed: onToggleFasting,
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// 数字键盘 — 1-9 / . / 0 / ⌫
class WeighNumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final ThemeData theme;

  const WeighNumPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['.', '0', '⌫'],
          ])
            Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      height: 60,
                      child: Material(
                        color: key == '⌫'
                            ? const Color(0xFFC44F4F).withAlpha(25)
                            : theme.colorScheme.surfaceContainerHighest
                                .withAlpha(80),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (key == '⌫') {
                              onDelete();
                            } else {
                              onDigit(key);
                            }
                          },
                          child: Center(
                            child: key == '⌫'
                                ? const Icon(Icons.backspace_outlined, size: 24)
                                : Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      color: key == '.'
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
