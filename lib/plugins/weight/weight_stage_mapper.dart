import '../stage/stage_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// weight 插件的阶段映射工具。
//
// weight 插件不再维护独立的 3 阶段概念，而是从 stage 插件读取 8 阶段值，
// 然后映射到自己需要的两个维度：
//   1. 告警策略（AlertStrategy）：决定用增长率监测还是基线偏差
//   2. 称重间隔等级（WeighIntervalTier）：决定默认称重频率
// ═══════════════════════════════════════════════════════════════════════════════

/// 体重告警策略。
///
/// weight 插件本质上只有两种告警算法：
/// - [growth]：雏鸟增长率监测（48h 对数增长率）
/// - [baseline]：基线偏差监测（EWMA 或手动基线）
/// - [weaning]：断奶期专用（峰值降幅告警）
enum WeightAlertStrategy { growth, baseline, weaning }

/// 称重间隔等级。
///
/// 映射到 Species 表的 3 个间隔列：
/// - [frequent] → nestlingWeighIntervalDays（雏鸟间隔，默认 1 天）
/// - [medium] → juvenileWeighIntervalDays（幼鸟间隔，默认 3 天）
/// - [sparse] → adultWeighIntervalDays（成鸟间隔，默认 7 天）
enum WeighIntervalTier { frequent, medium, sparse }

/// 从 8 阶段映射到告警策略。
WeightAlertStrategy alertStrategyOf(String stage) {
  switch (stage) {
    case RecipeStage.nestling:
      return WeightAlertStrategy.growth;
    case RecipeStage.weaning:
      return WeightAlertStrategy.weaning;
    default:
      // 亚成体 / 成鸟维护期 / 繁殖准备期 / 产蛋孵化期 / 育雏期 / 换羽期
      return WeightAlertStrategy.baseline;
  }
}

/// 从 8 阶段映射到称重间隔等级。
WeighIntervalTier intervalTierOf(String stage) {
  switch (stage) {
    case RecipeStage.nestling:
    case RecipeStage.weaning:
      return WeighIntervalTier.frequent;
    case RecipeStage.juvenile:
      return WeighIntervalTier.medium;
    default:
      // 成鸟 / 繁殖 / 换羽
      return WeighIntervalTier.sparse;
  }
}

/// 判断该阶段是否为"成长期"（雏鸟/断奶期），用于 UI 条件分支。
///
/// 替代旧代码中 `bird.growthStage != '雏鸟'` 的判断。
bool isGrowingStage(String stage) =>
    stage == RecipeStage.nestling || stage == RecipeStage.weaning;

/// weight 插件内部使用的简化阶段标签（用于 UI 显示）。
///
/// 将 8 阶段归类为 3 个粗粒度标签，兼容旧的 UI 展示需求。
String weightStageLabel(String stage) {
  switch (stage) {
    case RecipeStage.nestling:
    case RecipeStage.weaning:
      return '雏鸟';
    case RecipeStage.juvenile:
      return '幼鸟';
    default:
      return '成鸟';
  }
}
