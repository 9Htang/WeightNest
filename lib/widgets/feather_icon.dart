import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 羽毛图标 Widget — 自动继承 [IconTheme]。
///
/// 从 [IconTheme.of(context)] 读取颜色和尺寸（优先使用显式参数），
/// 因此可在 [NavigationBar] / [NavigationRail] 的 `icon` / `selectedIcon`
/// 槽位中正确响应选中 / 未选中状态。
///
/// 用法：
/// ```dart
/// const FeatherIcon()                          // 继承 IconTheme 颜色和尺寸
/// const FeatherIcon(size: 20)                  // 固定 20 px，颜色继承
/// FeatherIcon(size: 16, color: scheme.primary) // 强制颜色
/// ```
class FeatherIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const FeatherIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedColor = color ?? iconTheme.color;
    final resolvedSize = size ?? iconTheme.size ?? 24;

    return SvgPicture.asset(
      'assets/icons/feather.svg',
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: resolvedColor != null
          ? ColorFilter.mode(resolvedColor, BlendMode.srcIn)
          : null,
    );
  }
}

/// 向后兼容的函数包装 — 返回 [FeatherIcon]。
///
/// 推荐直接使用 `FeatherIcon(...)` 构造函数（支持 `const`）。
Widget featherIcon({double? size, Color? color}) =>
    FeatherIcon(size: size, color: color);
