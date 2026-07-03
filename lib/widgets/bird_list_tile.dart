import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/plugin_registry.dart';
import '../repositories/bird_repository.dart';
import '../theme/app_tokens.dart';
import '../theme/theme.dart';

/// Reusable bird list tile — shows avatar, name, ring#, species, stage, age.
///
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
    final r = context.r;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: sp.md, vertical: 3),
      child: InkWell(
        borderRadius: r.bXl,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: sp.sm, horizontal: sp.xs),
          child: Row(
            children: [
              leading ?? _buildAvatar(theme),
              SizedBox(width: sp.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bird.bird.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (bird.bird.ringNumber != null) ...[
                          SizedBox(width: sp.xs + 2),
                          Text('#${bird.bird.ringNumber}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${bird.species.name} · ${bird.growthStage} · ${bird.ageDays}天',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an avatar widget for the given bird, delegating to plugin
  /// [FeaturePlugin.buildAvatar] or falling back to the stage emoji.
  static Widget buildAvatar(int birdId, {double size = 40, String? growthStage, ThemeData? theme}) {
    for (final plugin in pluginRegistry.enabledPlugins) {
      final avatar = plugin.buildAvatar(birdId, size: size, growthStage: growthStage);
      if (avatar != null) return avatar;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: stageColor(growthStage ?? '', theme ?? ThemeData.fallback()),
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

  Widget _buildAvatar(ThemeData theme) {
    return buildAvatar(bird.bird.id, size: 40, growthStage: bird.growthStage, theme: theme);
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
