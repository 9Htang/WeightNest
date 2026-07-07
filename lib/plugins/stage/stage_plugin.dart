import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'stage_constants.dart';
import 'stage_repository.dart';

/// 参数封装类 —— setStage 需要多个参数，但 pluginRegistry.call() 只支持单参数。
class SetStageArgs {
  final int birdId;
  final String stage;
  final String source;
  const SetStageArgs(this.birdId, this.stage, {this.source = StageSource.auto});
}

/// 生理阶段管理插件（内部插件，用户不可见）。
///
/// 作为全部鹦鹉生理阶段的单一数据源。其他插件（weight / nutrition / breeding）
/// 通过 `pluginRegistry.call('stage', ...)` 读取阶段，不各自维护阶段逻辑。
///
/// 隐身策略：`pages` / `routes` / `quickActions` / `buildDetailSections` 全部返回空，
/// 因此不出现在侧边栏、首页、鸟详情页。保留 `enabled = true` 以确保能被
/// `getPlugin` / `call` 访问（它们基于 enabledPlugins 过滤）。
class StagePlugin extends FeaturePlugin {
  @override
  String get id => 'stage';

  @override
  bool get isInternal => true;

  @override
  String get displayName => '生理阶段'; // 仅内部标识，用户不会看到

  @override
  String get description => '内部插件：统一管理鹦鹉生理阶段';

  @override
  IconData get icon => Icons.timeline_outlined;

  @override
  IconData? get selectedIcon => Icons.timeline;

  @override
  List<dynamic> get tables => const []; // 表注册在 database.dart 中，不通过插件 tables

  // ── 隐身：所有 UI 钩子返回空 ──

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  @override
  List<PluginPageDescriptor> get pages => const [];

  @override
  List<QuickAction> get quickActions => const [];

  @override
  List<DetailSection> buildDetailSections(int birdId) => [];

  // ── 暴露给其他插件的数据查询 ──

  @override
  Map<String, Function> get dataQueries => {
        // ── 同步读取 ──
        // 返回单只鸟的当前阶段（RecipeStage 常量值）。
        // 无缓存时回退到年龄推断，保证始终有合法返回值。
        'getStage': (int birdId) {
          final db = pluginRegistry.db;
          if (db == null) return RecipeStage.adult;
          return db.getStageSync(birdId);
        },

        // 批量读取多只鸟的阶段，返回 Map<int, String>。
        'getStages': (List<int> birdIds) {
          final db = pluginRegistry.db;
          if (db == null) return <int, String>{};
          return db.getStagesSync(birdIds);
        },

        // ── 异步写入 ──
        // 写入单只鸟的阶段（手动覆盖 / breeding 通知）。
        'setStage': (SetStageArgs args) async {
          final db = pluginRegistry.db;
          if (db == null) return;
          await db.setStage(args.birdId, args.stage, source: args.source);
        },

        // 批量写入（查窝批量更新场景）。
        // 参数为 Map<int, String>{ birdId: stage }，source 默认 breeding。
        'setStages': (Map<int, String> updates) async {
          final db = pluginRegistry.db;
          if (db == null) return;
          await db.setStages(updates);
        },

        // 清除单只鸟的阶段缓存（繁殖完结后回退到年龄推断）。
        'clearStage': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return;
          await db.clearStage(birdId);
        },

        // 重新推断单只鸟的阶段（年龄变化、手动覆盖变更后触发）。
        'recompute': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return;
          await db.recomputeStage(birdId);
        },

        // 为所有鸟重新推断阶段（app 启动初始化）。
        'recomputeAll': () async {
          final db = pluginRegistry.db;
          if (db == null) return;
          await db.recomputeAllStages();
        },

        // 重新推断一只鸟，如果它没有 manual 覆盖也没有 breeding 来源。
        // weight 插件记录体重后调用此方法刷新断奶检测。
        'recomputeIfAuto': (int birdId) async {
          final db = pluginRegistry.db;
          if (db == null) return;
          final existing = await (db.select(db.birdStages)
                ..where((t) => t.birdId.equals(birdId)))
              .getSingleOrNull();
          // 只重算 auto 来源（或无记录）的鸟
          if (existing == null || existing.source == StageSource.auto) {
            await db.recomputeStage(birdId);
          }
        },
      };
}
