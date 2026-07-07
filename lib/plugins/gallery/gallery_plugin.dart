import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'widgets/bird_avatar.dart';
import 'widgets/gallery_section.dart';

/// Gallery plugin — parrot photo management and custom avatars.
///
/// ## Slots used
/// - **Slot B** ([buildDetailSections]): photo gallery (grid + swipe + batch
///   delete + reorder).
/// - **Slot I** ([buildAvatar]): custom avatar widget with matching size.
/// - **Data queries**: exposes `getAvatarPath` and `getPhotos` for cross-plugin
///   access.
class GalleryPlugin extends FeaturePlugin {
  @override
  String get id => 'gallery';

  @override
  String get displayName => '鹦鹉相册';

  @override
  String get description => '鹦鹉照片管理与头像设置';

  @override
  IconData get icon => Icons.photo_library_outlined;

  @override
  IconData get selectedIcon => Icons.photo_library;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  // ── Slot B: 详情页嵌入 —— 照片画廊 ──

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
        DetailSection(
          title: '相册',
          icon: Icons.photo_library_outlined,
          priority: 40,
          defaultExpanded: true,
          child: GallerySection(birdId: birdId),
        ),
      ];

  // ── Slot I: 头像 ──

  @override
  Widget? buildAvatar(int birdId, {double size = 56, VoidCallback? onTap, String? growthStage, bool fillHeight = false, Color? backgroundColor}) {
    return BirdAvatarWidget(
      birdId: birdId,
      size: size,
      onTap: onTap,
      growthStage: growthStage,
      forceSharp: fillHeight,
      backgroundColor: backgroundColor,
    );
  }

  // ── 跨插件数据查询 ──

  @override
  Map<String, Function> get dataQueries => {
        'getAvatarPath': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return null;
          final row = await (db.select(db.birdAvatars)
                ..where((t) => t.birdId.equals(birdId)))
              .getSingleOrNull();
          return row?.filePath;
        },
        'getPhotos': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return <BirdPhoto>[];
          return (db.select(db.birdPhotos)
                ..where((t) => t.birdId.equals(birdId))
                ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
              .get();
        },
      };
}
