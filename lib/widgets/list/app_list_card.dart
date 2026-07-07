import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// 统一的列表项卡片 —— Slot 组合式。
///
/// 收口历史上 4 种 margin 与 4 种 padding。
///
/// 视觉规范：
/// - margin：[AppSpacing.cardMargin]（h:12, v:4）
/// - 点击：`InkWell`
///
/// 当 [leading] 不为 null 时采用「左色块 + 右内容」撑满布局（80px 色块从顶到底）。
/// 当 [sharp] 为 true 时卡片为直角；为 false 时保持全局 cardTheme 圆角。
///
/// 三种用法：
/// ```dart
/// // 1. 通用 slot（带头像/图标 → 左侧撑满）
/// AppListCard(leading: avatar, title: Text(name), subtitle: Text(desc));
///
/// // 2. 图标头部（80px 分类色背景 + 图标居中，撑满左侧）
/// AppListCard.icon(icon: Icons.medication, iconTint: scheme.primary, title: ...);
///
/// // 3. ListTile 风格（简单行，sharp: false 保持圆角）
/// AppListCard.tile(leading: Icon(...), title: ..., sharp: false);
/// ```
class AppListCard extends StatelessWidget {
  /// 头部（图标 / 头像），可选。
  /// 不为 null 时左侧 80px 区域从卡片顶边延伸到底边。
  final Widget? leading;

  /// 必填标题。
  final Widget title;

  /// 可选副标题 / 描述区。允许放任意 Widget（chip 行、进度条等）。
  final Widget? subtitle;

  /// 标题右侧徽章（与 title 同行），可选。
  final Widget? badge;

  /// 尾部（操作按钮 / 箭头），可选。
  final Widget? trailing;

  /// 点击回调。提供则包裹 InkWell。
  final VoidCallback? onTap;

  /// 长按回调。
  final VoidCallback? onLongPress;

  /// 覆盖默认 margin（一般不需要）。
  final EdgeInsetsGeometry? margin;

  /// 覆盖默认内容区 padding（一般不需要）。
  final EdgeInsetsGeometry? padding;

  /// 是否直角。默认 true。
  /// - true：Card shape 覆盖为直角（borderRadius: 0）
  /// - false：继承全局 cardTheme 的圆角（16）
  final bool sharp;

  /// 左侧色块固定边长（正方形）。默认 64。
  final double leadingWidth;

  const AppListCard({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.sharp = true,
    this.leadingWidth = 64,
  });

  /// 图标头部变体 —— 自动构建 80px 宽撑满色块容器，
  /// 背景为 [iconBg]，图标居中着色 [iconTint]。
  ///
  /// [iconTint] 通常取自 [CategoryColors] 返回的前景色。
  /// [iconBg] 通常取自 [CategoryColors] 返回的背景色。
  factory AppListCard.icon({
    Key? key,
    required IconData icon,
    required Color iconTint,
    Color? iconBg,
    required Widget title,
    Widget? subtitle,
    Widget? badge,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool sharp = true,
    double leadingWidth = 64,
  }) {
    return AppListCard(
      key: key,
      leading: _IconBox(icon: icon, tint: iconTint, bg: iconBg),
      title: title,
      subtitle: subtitle,
      badge: badge,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      margin: margin,
      padding: padding,
      sharp: sharp,
      leadingWidth: leadingWidth,
    );
  }

  /// ListTile 风格变体 —— 适用于 rooms/enclosures 这类简单行。
  /// 默认 [sharp] 为 false 保持圆角。
  factory AppListCard.tile({
    Key? key,
    Widget? leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool sharp = false,
  }) =>
      AppListCard(
        key: key,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
        margin: margin,
        padding: padding,
        sharp: sharp,
      );

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    // QQ 式无缝列表：垂直 margin 为 0，行与行紧挨，靠分隔线区分。
    final effectiveMargin = margin ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 0);

    // Card shape：sharp 模式直角 + 无描边；非 sharp 继承全局 CardTheme。
    final cardShape = sharp
        ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide.none,
          )
        : null; // null → 继承 CardTheme

    return Card(
      margin: effectiveMargin,
      clipBehavior: Clip.antiAlias,
      shape: cardShape,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: _hasLeading
            ? _buildLeadingLayout(context, sp)
            : _buildSimpleLayout(context, sp),
      ),
    );
  }

  bool get _hasLeading => leading != null;

  /// 带左侧正方形 leading 的布局。
  Widget _buildLeadingLayout(BuildContext context, AppSpacing sp) {
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(sp.sm + sp.xs, sp.sm, sp.sm, sp.sm);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧正方形 leading：64×64
        SizedBox(
          width: leadingWidth,
          height: leadingWidth,
          child: leading!,
        ),
        // 右侧内容区
        Expanded(
          child: Padding(
            padding: effectivePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行：title + badge
                if (badge != null)
                  Row(
                    children: [
                      Expanded(child: title),
                      badge!,
                    ],
                  )
                else
                  Flexible(child: title),
                if (subtitle != null) ...[
                  SizedBox(height: sp.xs),
                  subtitle!,
                ],
              ],
            ),
          ),
        ),
        if (trailing != null)
          Padding(
            padding: EdgeInsets.only(right: sp.sm),
            child: Center(child: trailing!),
          ),
      ],
    );
  }

  /// 无 leading 的简单 Row 布局。
  Widget _buildSimpleLayout(BuildContext context, AppSpacing sp) {
    final effectivePadding = padding ?? sp.paddingSm;

    return Padding(
      padding: effectivePadding,
      child: Row(
        crossAxisAlignment: subtitle != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Row(
                    children: [
                      Expanded(child: title),
                      badge!,
                    ],
                  )
                else
                  Flexible(child: title),
                if (subtitle != null) ...[
                  SizedBox(height: sp.xs),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: sp.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 64×64 图标色块容器（正方形）。
///
/// 图标在色块中居中，背景色为 [bg]（通常取自 [CategoryColors]）。
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color? bg;

  const _IconBox({required this.icon, required this.tint, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: bg,
      child: Center(
        child: Icon(icon, color: tint, size: 28),
      ),
    );
  }
}
