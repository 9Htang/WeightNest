import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 设计系统 Token —— 间距 / 圆角 / 透明度。
///
/// 这些维度历史上散落为 magic number（全项目 53 个文件、约 1000 处
/// EdgeInsets/SizedBox、131 处圆角、158 处透明度）。本文件收口为单一数据源，
/// 通过 [ThemeExtension] 注入，自动适配浅色/深色模式。
///
/// 用法：
/// ```dart
/// final sp = context.sp, r = context.r, a = context.a;
/// Padding(padding: EdgeInsets.all(sp.md));            // 12
/// BorderRadius.circular(r.xl);                         // 12
/// colorScheme.onSurface.withAlpha(a.high);             // 140
/// ```
///
/// 字号不在此处定义 —— 优先使用 `Theme.of(context).textTheme.*`（已定义 10 档）。
/// 颜色不在此处定义 —— 使用 `Theme.of(context).colorScheme` + [AppAlpha] 组合，
/// 或 [StatusColors]（业务语义色）。

// ──────────────────────────────────────────────────────────────
// 间距
// ──────────────────────────────────────────────────────────────

/// 间距阶梯。数值依据代码实际出现频率反推，4 的倍数为主。
///
/// | token | 值 | 典型用途 |
/// |-------|----|---------|
/// | xs | 4 | 紧凑元素内间距（图标与文字） |
/// | sm | 8 | 小间距、Chip 内、列表项纵向 |
/// | md | 12 | 卡片外边距、列表 padding |
/// | lg | 16 | 页面 padding、卡片内间距 |
/// | xl | 24 | 区块间距、对话框 padding |
/// | xxl | 32 | 大留白 |
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
  });

  /// 4 —— 紧凑元素内间距。
  final double xs;

  /// 8 —— 小间距。
  final double sm;

  /// 12 —— 卡片外边距、列表 padding。
  final double md;

  /// 16 —— 页面 padding、卡片内间距。
  final double lg;

  /// 24 —— 区块间距。
  final double xl;

  /// 32 —— 大留白。
  final double xxl;

  /// 常用 EdgeInsets 快捷构造（值见各字段注释）。
  EdgeInsets get paddingXs => EdgeInsets.all(xs);
  EdgeInsets get paddingSm => EdgeInsets.all(sm);
  EdgeInsets get paddingMd => EdgeInsets.all(md);
  EdgeInsets get paddingLg => EdgeInsets.all(lg);
  EdgeInsets get paddingXl => EdgeInsets.all(xl);

  /// 页面标准 padding —— 水平 [md]（12）、垂直 [xs]（4）。
  /// 历史上 `fromLTRB(12, 8, 12, 4)` / `symmetric(horizontal: 12)` 的统一替代。
  EdgeInsets get pageHorizontal => EdgeInsets.symmetric(horizontal: md);

  /// 卡片标准外边距 —— 水平 [md]（12）、垂直 [xs]（4）。
  EdgeInsets get cardMargin => EdgeInsets.symmetric(horizontal: md, vertical: xs);

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) =>
      AppSpacing(
        xs: xs ?? this.xs,
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
        xxl: xxl ?? this.xxl,
      );

  @override
  AppSpacing lerp(AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 圆角
// ──────────────────────────────────────────────────────────────

/// 圆角阶梯。131 处历史用法中 7 级覆盖约 95%。
///
/// | token | 值 | 典型用途 |
/// |-------|----|---------|
/// | xs | 2 | 色块/徽章小圆角 |
/// | sm | 4 | 小图标容器、内联按钮 |
/// | md | 6 | 图例、表格容器顶部 |
/// | lg | 8 | 中等卡片、头像 |
/// | xl | 12 | 主力圆角（卡片、输入框、列表项） |
/// | xxl | 16 | 大卡片、FAB |
/// | pill | 20 | 对话框、全圆角胶囊 |
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.xs = 2,
    this.sm = 4,
    this.md = 6,
    this.lg = 8,
    this.xl = 12,
    this.xxl = 16,
    this.pill = 20,
  });

  /// 2 —— 色块/徽章。
  final double xs;

  /// 4 —— 小图标容器、内联按钮。
  final double sm;

  /// 6 —— 图例、表格容器顶部。
  final double md;

  /// 8 —— 中等卡片、头像。
  final double lg;

  /// 12 —— 主力圆角（卡片、输入框、列表项）。
  final double xl;

  /// 16 —— 大卡片、FAB。
  final double xxl;

  /// 20 —— 对话框、全圆角胶囊。
  final double pill;

  /// 便捷 BorderRadius 构造。
  BorderRadius get bXs => BorderRadius.circular(xs);
  BorderRadius get bSm => BorderRadius.circular(sm);
  BorderRadius get bMd => BorderRadius.circular(md);
  BorderRadius get bLg => BorderRadius.circular(lg);
  BorderRadius get bXl => BorderRadius.circular(xl);
  BorderRadius get bXxl => BorderRadius.circular(xxl);
  BorderRadius get bPill => BorderRadius.circular(pill);

  @override
  AppRadius copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? pill,
  }) =>
      AppRadius(
        xs: xs ?? this.xs,
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
        xxl: xxl ?? this.xxl,
        pill: pill ?? this.pill,
      );

  @override
  AppRadius lerp(AppRadius? other, double t) {
    if (other == null) return this;
    return AppRadius(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
      pill: lerpDouble(pill, other.pill, t) ?? pill,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 透明度
// ──────────────────────────────────────────────────────────────

/// 透明度阶梯。历史上 158 处用法、22 个不同 alpha 值，本类收口为 6 级语义化。
///
/// 合并规则（旧值 → token）：
/// - 8/12/15/18/20/25 → [subtle] (20)
/// - 30/40 → [faint] (30)
/// - 50/60 → [low] (60)
/// - 80/100/110 → [medium] (100)
/// - 120/130/140 → [high] (140)
/// - 150/160/180/200/204 → [heavy] (180)
///
/// 用法：`colorScheme.onSurface.withAlpha(a.medium)`
class AppAlpha extends ThemeExtension<AppAlpha> {
  const AppAlpha({
    this.subtle = 20,
    this.faint = 30,
    this.low = 60,
    this.medium = 100,
    this.high = 140,
    this.heavy = 180,
  });

  /// 20 —— 极淡（分隔线、卡片描边底色）。
  final int subtle;

  /// 30 —— 淡（表格网格线、容器底纹）。
  final int faint;

  /// 60 —— 低（次要图标、占位）。
  final int low;

  /// 100 —— 中（正文弱化、bodyMedium 文本色）。
  final int medium;

  /// 140 —— 高（次要文本、`Colors.grey` 的默认替代）。
  final int high;

  /// 180 —— 重（辅助文本、labelMedium 文本色）。
  final int heavy;

  @override
  AppAlpha copyWith({
    int? subtle,
    int? faint,
    int? low,
    int? medium,
    int? high,
    int? heavy,
  }) =>
      AppAlpha(
        subtle: subtle ?? this.subtle,
        faint: faint ?? this.faint,
        low: low ?? this.low,
        medium: medium ?? this.medium,
        high: high ?? this.high,
        heavy: heavy ?? this.heavy,
      );

  @override
  AppAlpha lerp(AppAlpha? other, double t) {
    // alpha 是整数语义值，不做插值（透明度渐变无实际意义）。
    return this;
  }
}

// ──────────────────────────────────────────────────────────────
// BuildContext 便捷访问器
// ──────────────────────────────────────────────────────────────

/// Token 访问快捷方式。在任意 widget 中：
/// ```dart
/// final sp = context.sp;  // AppSpacing
/// final r = context.r;    // AppRadius
/// final a = context.a;    // AppAlpha
/// ```
extension AppTokensX on BuildContext {
  /// 间距 token。
  AppSpacing get sp => Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();

  /// 圆角 token。
  AppRadius get r => Theme.of(this).extension<AppRadius>() ?? const AppRadius();

  /// 透明度 token。
  AppAlpha get a => Theme.of(this).extension<AppAlpha>() ?? const AppAlpha();
}
