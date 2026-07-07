import 'package:flutter/material.dart';
import '../../core/event_bus.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'breeding_repository.dart';
import 'breeding_pair_screen.dart';
import 'breeding_detail_section.dart';

class BreedingPlugin extends FeaturePlugin {
  @override
  String get id => 'breeding';

  @override
  String get displayName => '繁育';

  @override
  String get description => '配对管理、繁育周期追踪、产蛋与孵化记录';

  @override
  IconData get icon => Icons.egg_outlined;

  @override
  IconData get selectedIcon => Icons.egg;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  @override
  List<PluginPageDescriptor> get pages => [
        PluginPageDescriptor(
          key: 'pairs',
          title: '配对管理',
          icon: Icons.favorite_outline,
          uniqueness: PageUniqueness.singleton,
          showInSidebar: true,
          builder: (ctx) => BreedingPairListScreen(),
        ),
      ];

  @override
  Map<String, Function> get dataQueries => {
        'getActiveBreedingBirdIds': () async {
          final db = pluginRegistry.db;
          if (db == null) return <int>{};
          return db.getActiveBreedingBirdIds();
        },
        'isBreeding': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return false;
          return db.isBreeding(birdId);
        },
        'getActivePair': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return null;
          return db.getActivePairForBird(birdId);
        },
        // 返回该鸟当前活跃繁殖记录的阶段（'配对'/'产蛋'/'孵化'/'育雏'/'已完结'），
        // 无活跃繁殖记录时返回 null。供营养插件推断生理阶段用。
        'getActiveRecordStage': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return null;
          final result = await db.getActiveRecordForBird(birdId);
          return result?.$1.stage;
        },
      };

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
        DetailSection(
          title: '繁育信息',
          icon: Icons.egg_outlined,
          priority: 30,
          defaultExpanded: true,
          child: BreedingDetailSection(birdId: birdId),
        ),
      ];

  @override
  Future<List<PluginAlert>> detectAlerts(AppDatabase db, {int? birdId}) async =>
      [];

  @override
  List<QuickAction> get quickActions => [
        QuickAction(
          label: '配对管理',
          icon: Icons.favorite_outline,
          builder: () => const BreedingPairListScreen(),
        ),
      ];

  @override
  void registerEvents(EventBus bus) {}
}
