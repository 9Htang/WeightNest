// ═══════════════════════════════════════════════════════════════════════════════
// 营养插件的阶段定义 —— 已迁移到 stage 内部插件。
//
// 本文件保留 re-export 以确保向后兼容（其他文件 import nutrition_stage.dart 不会断裂）。
// 新代码请直接 import '../stage/stage_constants.dart'。
// ═══════════════════════════════════════════════════════════════════════════════

export '../stage/stage_constants.dart';
import '../stage/stage_constants.dart' show RecipeStage;

import '../../core/plugin_registry.dart';
import '../../repositories/bird_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// StageInferrer —— 保留用于判断 isManualOverride。
//
// 阶段推断已迁移到 stage 插件的 StageRepository，此处的 infer() 保留为
// convenience wrapper，供尚未迁移的旧代码使用。新代码请直接调用：
//   pluginRegistry.call('stage', 'getStage', birdId)
// ═══════════════════════════════════════════════════════════════════════════════

/// 推断某只鸟当前所处的生理阶段。
///
/// 优先级：
/// 0. 手动覆盖（bird.stageOverride 非空）→ 直接返回
/// 1. stage 插件缓存（来自 breeding 通知或之前的推断）→ 直接返回
/// 2. 鸟龄 + 物种阈值 → 回退推断
class StageInferrer {
  StageInferrer._();

  /// 判断当前阶段是否为手动覆盖（用于 UI 区分"自动/手动"）。
  static bool isManualOverride(BirdWithDetails bird) {
    return bird.bird.stageOverride != null &&
        RecipeStage.all.contains(bird.bird.stageOverride);
  }

  /// 推断鸟的当前阶段（convenience wrapper，优先读 stage 插件缓存）。
  static Future<String> infer(BirdWithDetails bird) async {
    // 0) 手动覆盖优先
    if (bird.bird.stageOverride != null &&
        RecipeStage.all.contains(bird.bird.stageOverride)) {
      return bird.bird.stageOverride!;
    }

    // 1) 从 stage 插件读取（可能有 breeding 来源的缓存）
    try {
      final stage = pluginRegistry.call('stage', 'getStage', bird.bird.id);
      if (stage is String && stage.isNotEmpty) return stage;
    } catch (_) {}

    // 2) 回退到年龄推断
    return _inferFromAge(bird);
  }

  /// 纯年龄推断（不涉及繁殖状态）。
  static String _inferFromAge(BirdWithDetails bird) {
    final ageDays = bird.ageDays;
    final weaningOverride = bird.bird.weaningOverride;
    final nestlingEnd = bird.species.nestlingEndDays;
    final juvenileEnd = bird.species.juvenileEndDays;

    if (weaningOverride == true) {
      if (ageDays < juvenileEnd) return RecipeStage.weaning;
    }

    if (ageDays < nestlingEnd) return RecipeStage.nestling;

    if (weaningOverride == false) {
      if (ageDays < juvenileEnd) return RecipeStage.juvenile;
      return RecipeStage.adult;
    }

    final weaningWindow = (juvenileEnd - nestlingEnd) ~/ 3;
    if (ageDays < nestlingEnd + weaningWindow) return RecipeStage.weaning;
    if (ageDays < juvenileEnd) return RecipeStage.juvenile;
    return RecipeStage.adult;
  }
}
