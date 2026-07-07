import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/plugin_registry.dart';
import '../repositories/bird_repository.dart';
import '../theme/app_tokens.dart';
import '../theme/theme.dart';

/// Reusable bird list tile — shows avatar, name, ring#, species, stage, age.
///
/// Uses [IntrinsicHeight] + 80px left avatar column for sharp edge-to-edge look.
/// Used by birds list, bird picker sheet, and any other UI that needs to
/// display a bird row.
class BirdListTile extends ConsumerWidget {
  final BirdWithDetails bird;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  const BirdListTile({
    super.key,
    required this.bird,
    this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sp = context.sp;

    final cardColor = theme.colorScheme.surfaceContainerLow;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧头像：正圆形裁切
            Padding(
              padding: EdgeInsets.fromLTRB(sp.sm, sp.sm, 0, sp.sm),
              child: leading ??
                  buildAvatar(
                    bird.bird.id,
                    growthStage: bird.growthStage,
                    theme: theme,
                    circle: true,
                    cardColor: cardColor,
                  ),
            ),
            // 右侧内容区
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    sp.sm + sp.xs, sp.sm, sp.sm, sp.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bird.bird.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (bird.bird.ringNumber != null) ...[
                          SizedBox(width: sp.sm),
                          Text('#${bird.bird.ringNumber}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                    SizedBox(height: sp.xs),
                    Text(
                      '${bird.species.name} · ${bird.growthStage} · ${bird.ageDays}天',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
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
        ),
      ),
    );
  }

  /// Builds an avatar widget for the given bird.
  ///
  /// When [circle] is true, returns a circular-clipped avatar (QQ/WeChat style)
  /// sized [circleSize]×[circleSize] (default 56), used by [BirdListTile] list rows.
  /// When [fillHeight] is true, returns a sharp-cornered avatar sized 64×64
  /// (legacy edge-to-edge card style).
  /// When both are false, returns a square avatar with rounded corners.
  static Widget buildAvatar(
    int birdId, {
    double size = 48,
    double circleSize = 56,
    String? growthStage,
    ThemeData? theme,
    bool fillHeight = false,
    bool circle = false,
    Color? cardColor,
  }) {
    for (final plugin in pluginRegistry.enabledPlugins) {
      final avatar = plugin.buildAvatar(
        birdId,
        size: size,
        growthStage: growthStage,
        fillHeight: fillHeight && !circle,
        backgroundColor: circle ? cardColor : null,
      );
      if (avatar != null) {
        if (circle) {
          return SizedBox(
            width: circleSize,
            height: circleSize,
            child: ClipOval(child: avatar),
          );
        }
        return fillHeight
            ? SizedBox(width: 64, height: 64, child: avatar)
            : avatar;
      }
    }

    final fallbackTheme = theme ?? ThemeData.fallback();
    // Fallback: stage-colored avatar with emoji
    if (circle || fillHeight) {
      if (circle) {
        return _CircularAvatar(
          growthStage: growthStage ?? '',
          theme: fallbackTheme,
          size: circleSize,
          cardColor: cardColor,
        );
      }
      return _SquareAvatar(
        growthStage: growthStage ?? '',
        theme: fallbackTheme,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: stageColor(growthStage ?? '', fallbackTheme),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          stageEmoji(growthStage ?? ''),
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  /// Growth-stage emoji: 🐣 雏鸟, 🐤 幼鸟, 🦜 成鸟.
  static String stageEmoji(String stage) {
    if (stage == '雏鸟') return '🐣';
    if (stage == '幼鸟') return '🐤';
    return '🦜';
  }

  /// Background color matching growth stage.
  ///
  /// 雏鸟/幼鸟用语义色（[StatusColors.nestling]/[juvenile]）叠加透明度，
  /// 成鸟回退到 primaryContainer —— 三者均自动适配明暗模式。
  static Color stageColor(String stage, ThemeData theme) {
    final sc = AppTheme.statusColors(theme.colorScheme);
    if (stage == '雏鸟') return sc.nestling.withAlpha(40);
    if (stage == '幼鸟') return sc.juvenile.withAlpha(40);
    return theme.colorScheme.primaryContainer;
  }

  static String formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 64×64 正方形头像 fallback for [BirdListTile] —
/// stage color background + centered emoji, sharp corners (直角).
class _SquareAvatar extends StatelessWidget {
  final String growthStage;
  final ThemeData theme;

  const _SquareAvatar({required this.growthStage, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = BirdListTile.stageColor(growthStage, theme);
    return Container(
      width: 64,
      height: 64,
      color: color,
      child: Center(
        child: Text(
          BirdListTile.stageEmoji(growthStage),
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

/// 64×64 圆形头像 fallback for [BirdListTile] —
/// stage color background + centered emoji, clipped to circle.
class _CircularAvatar extends StatelessWidget {
  final String growthStage;
  final ThemeData theme;
  final double size;
  final Color? cardColor;

  const _CircularAvatar({
    required this.growthStage,
    required this.theme,
    this.size = 56,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: cardColor ?? theme.colorScheme.surfaceContainerLow,
        child: Center(
          child: Text(
            BirdListTile.stageEmoji(growthStage),
            style: TextStyle(fontSize: size * 0.45),
          ),
        ),
      ),
    );
  }
}
