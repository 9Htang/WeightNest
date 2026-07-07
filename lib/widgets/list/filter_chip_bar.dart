import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// 横向滚动的筛选 chip 行。
///
/// 收口 [FoodLibraryScreen]（44 高 + h:12 padding）与 [BlendLibraryScreen]
/// （Container + Wrap）两种写法。统一为：[AppSpacing.md] padding、44 高、
/// 单选语义（点击已选项回到「全部」即 null）。
///
/// 第一个 option 通常为「全部」，对应 [selected] == null。
///
/// 用法：
/// ```dart
/// FilterChipBar<String>(
///   options: [
///     (value: null, label: '全部'),  // 或用 allLabel
///     (value: '主食', label: '主食'),
///     (value: '蔬果', label: '蔬果'),
///   ],
///   selected: _categoryFilter,
///   onSelected: (v) => setState(() => _categoryFilter = v),
/// );
/// ```
class FilterChipBar<T> extends StatelessWidget {
  /// 选项列表。`value` 为 null 表示「全部」。
  final List<({T? value, String label})> options;

  /// 当前选中值。null 表示「全部」未筛选。
  final T? selected;

  /// 选择回调。点击已选项会回传 null（切换为「全部」）。
  final ValueChanged<T?> onSelected;

  const FilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: sp.md),
        separatorBuilder: (_, __) => SizedBox(width: sp.xs + 2),
        itemCount: options.length,
        itemBuilder: (context, i) {
          final opt = options[i];
          final isSelected = opt.value == selected;
          return Padding(
            padding: EdgeInsets.only(top: sp.xs + 2),
            child: FilterChip(
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (_) =>
                  onSelected(isSelected ? null : opt.value),
            ),
          );
        },
      ),
    );
  }
}
