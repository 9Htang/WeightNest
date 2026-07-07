// ═══════════════════════════════════════════════════════════════════════════════
// 鹦鹉生理阶段常量定义
//
// 8 个生理阶段是领域固定值，不建表用常量管理。
// 本文件由 stage 插件（内部插件）统一管理，供 weight / nutrition / breeding 等插件共用。
// ═══════════════════════════════════════════════════════════════════════════════

/// 鹦鹉生理阶段常量。
///
/// 这些值与食谱绑定、物种推荐等业务关联，不要随意修改字面量。
class RecipeStage {
  RecipeStage._();

  static const nestling = '雏鸟'; // 人工喂养
  static const weaning = '断奶期';
  static const juvenile = '亚成体';
  static const adult = '成鸟维护期';
  static const preBreeding = '繁殖准备期';
  static const eggLaying = '产蛋孵化期';
  static const chickRearing = '育雏期';
  static const molting = '换羽期';

  /// 全部阶段列表（用于多选 UI 与导入校验）
  static const all = [
    nestling,
    weaning,
    juvenile,
    adult,
    preBreeding,
    eggLaying,
    chickRearing,
    molting,
  ];

  /// 繁殖相关阶段（用于按物种+阶段筛选食谱时的特殊处理）
  static const breedingStages = [preBreeding, eggLaying, chickRearing];

  /// 阶段是否为繁殖阶段
  static bool isBreedingStage(String stage) =>
      breedingStages.contains(stage);

  /// 阶段描述（用于 UI 提示）
  static String descriptionOf(String stage) {
    switch (stage) {
      case nestling:
        return '雏鸟阶段，需人工喂养';
      case weaning:
        return '断奶过渡期';
      case juvenile:
        return '亚成体，生长发育期';
      case adult:
        return '成鸟日常维护';
      case preBreeding:
        return '繁殖准备期，需提升营养';
      case eggLaying:
        return '产蛋孵化期，需高钙高蛋白';
      case chickRearing:
        return '育雏期，需高营养密度';
      case molting:
        return '换羽期，需含硫氨基酸';
      default:
        return '';
    }
  }
}

/// 阶段来源（标记一条阶段记录是自动推断还是手动指定）。
class StageSource {
  StageSource._();

  /// 自动推断（年龄 + weaningOverride）
  static const auto = 'auto';

  /// 手动覆盖（用户在 UI 手动选择，如换羽期）
  static const manual = 'manual';

  /// 繁殖状态（由 breeding 插件通知写入）
  static const breeding = 'breeding';
}
