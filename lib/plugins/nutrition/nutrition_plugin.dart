import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../core/event_bus.dart';
import '../../database/database.dart';
import 'nutrition_repository.dart';
import 'feeding_section.dart';
import 'nutrition_config_screen.dart';
import 'screens/food_library_screen.dart';
import 'screens/blend_library_screen.dart';

/// 营养插件
///
/// 功能：食材库管理（含 L1/L2 营养素）、%比例混合粮配方、per-bird 喂养方案、
/// 按物种与生理阶段匹配、营养自动计算、鸟详情页喂养摘要。
class NutritionPlugin extends FeaturePlugin {
  @override
  String get id => 'nutrition';

  @override
  String get displayName => '营养';

  @override
  String get description => '食材营养库、混合粮配方、喂养方案管理、按生理阶段匹配餐饮';

  @override
  IconData get icon => Icons.restaurant_outlined;

  @override
  IconData get selectedIcon => Icons.restaurant;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  // ── Pages: 食材库 + 配方库（侧边栏入口）──

  @override
  List<PluginPageDescriptor> get pages => [
        PluginPageDescriptor(
          key: 'food-library',
          title: '食材库',
          icon: Icons.rice_bowl,
          uniqueness: PageUniqueness.singleton,
          showInSidebar: true,
          builder: (ctx) => const FoodLibraryScreen(),
        ),
        PluginPageDescriptor(
          key: 'blend-library',
          title: '配方库',
          icon: Icons.menu_book,
          uniqueness: PageUniqueness.singleton,
          showInSidebar: true,
          builder: (ctx) => const BlendLibraryScreen(),
        ),
      ];

  // ── Slot B: 鸟详情页喂养 Tab ──

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
        DetailSection(
          title: '喂养方案',
          icon: Icons.restaurant,
          priority: 50,
          defaultExpanded: true,
          child: FeedingSection(birdId: birdId),
        ),
      ];

  // ── Slot E: 首页快速操作 ──

  @override
  List<QuickAction> get quickActions => [
        QuickAction(
          label: '食材库',
          icon: Icons.rice_bowl,
          builder: () => const FoodLibraryScreen(),
        ),
        QuickAction(
          label: '配方库',
          icon: Icons.menu_book,
          builder: () => const BlendLibraryScreen(),
        ),
      ];

  // ── 跨插件数据查询 ──

  @override
  Map<String, Function> get dataQueries => {
        // 其他插件可调用: registry.call('nutrition', 'getActiveBlendForBird', speciesId, stage)
        'getActiveBlendForBird': (int speciesId, String stage) async {
          final db = pluginRegistry.db;
          if (db == null) return null;
          return db.getBlendsBySpeciesAndStage(speciesId, stage);
        },
      };

  // ── Plugin settings ──

  @override
  WidgetBuilder? get settingsBuilder => (_) => const NutritionConfigScreen();

  @override
  void registerEvents(EventBus bus) {}
}
