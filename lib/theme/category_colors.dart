import 'package:flutter/material.dart';

/// 业务分类色集中映射 —— 把历史上散落的 `Colors.orange/green/blue/red` 全部
/// 收口到 [ColorScheme] 的语义槽位，自动适配浅/深色模式。
///
/// 返回 `(foreground, background)` 一对色：
/// - `foreground` 用于图标、文字、徽章
/// - `background` 用于容器底色（已是 Container 色，无需再叠 alpha）
///
/// 用法：
/// ```dart
/// final (fg, bg) = CategoryColors.forCategory(scheme, food.category);
/// Container(color: bg, child: Icon(icon, color: fg));
/// ```
class CategoryColors {
  const CategoryColors._();

  /// 按业务分类返回 (前景, 背景) 一对色。
  ///
  /// 映射原则：
  /// - 暖色类（疾病/产蛋/育雏/警告/补充剂）→ tertiary（暖木色调）
  /// - 主色类（幼鸟/主食/活跃/孵化）→ primary（森林绿）
  /// - 次色类（成鸟/蔬果/已完结）→ secondary
  /// - 中性 → onSurfaceVariant / surfaceContainerHighest
  static (Color fg, Color bg) forCategory(ColorScheme s, String category) {
    return switch (category) {
      // ── 营养：食材分类 ──
      '主食' => (s.primary, s.primaryContainer),
      '蔬果' => (s.secondary, s.secondaryContainer),
      '补充剂' => (s.tertiary, s.tertiaryContainer),
      '其他' => (s.onSurfaceVariant, s.surfaceContainerHighest),

      // ── 用药：药品分类（与 _categories 列表对齐）──
      '抗生素' => (s.tertiary, s.tertiaryContainer),
      '维生素' => (s.primary, s.primaryContainer),
      '驱虫' => (s.secondary, s.secondaryContainer),
      '益生菌' => (s.primary, s.primaryContainer),
      '抗真菌' => (s.tertiary, s.tertiaryContainer),
      '保健' => (s.secondary, s.secondaryContainer),

      // ── 用药：疾病（统一暖色调，便于视觉警示）──
      '疾病' => (s.tertiary, s.tertiaryContainer),

      // ── 繁殖：阶段 ──
      '配对' => (s.primary, s.primaryContainer),
      '产蛋' => (s.tertiary, s.tertiaryContainer),
      '孵化' => (s.primary, s.primaryContainer),
      '育雏' => (s.secondary, s.secondaryContainer),
      '已完结' => (s.onSurfaceVariant, s.surfaceContainerHighest),

      // ── 鸟只生长阶段（与 StatusColors 对齐）──
      '雏鸟' => (s.tertiary, s.tertiaryContainer),
      '幼鸟' => (s.primary, s.primaryContainer),
      '成鸟' => (s.secondary, s.secondaryContainer),

      // ── 兜底 ──
      _ => (s.onSurfaceVariant, s.surfaceContainerHighest),
    };
  }
}
