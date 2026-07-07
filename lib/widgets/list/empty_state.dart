import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// 统一的空状态视图。
///
/// 历史 4 种写法（双层 Icon+主+副 / 单层 Icon+主 / 纯 Text / 占位）的统一替代。
///
/// 视觉规范：
/// - Icon 56px、`theme.disabledColor`
/// - 主文案 `bodyMedium`
/// - 副文案 `bodySmall` + `onSurfaceVariant`
/// - 间距：Icon → 主文案 [AppSpacing.lg]（16），主 → 副 [AppSpacing.sm]（8）
class EmptyState extends StatelessWidget {
  /// 主图标。可传入 Icon 或 featherIcon 等 Widget。
  final Widget icon;

  /// 主文案，如「暂无疾病」。
  final String message;

  /// 副文案（可选），如「点击右下角 + 添加」。
  final String? hint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sp = context.sp;
    return Center(
      child: Padding(
        padding: sp.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: icon,
            ),
            SizedBox(height: sp.lg),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (hint != null) ...[
              SizedBox(height: sp.sm),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
