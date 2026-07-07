import 'package:drift/drift.dart';
import '../../database/tables.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 鹦鹉营养插件 —— 数据库表定义
//
// 设计原则：
// 1. 配方(Blend) = 一袋混合粮的配方，食材按%配比，不分餐次
// 2. 喂养方案(FeedingPlan) = per-bird 餐饮方案，每餐由多配方按%组合
// 3. 方案支持「品种默认」(birdId=null) 和「鸟覆盖」(birdId=具体鸟)
// 4. 营养字段全 nullable（除 L1 核心 4 项），NULL = 无数据 ≠ 0
// 5. basis（数据基准）统一管理：Dry Matter 计算时换算回 As Fed
// ═══════════════════════════════════════════════════════════════════════════════

/// 食材库表（不变）
///
/// 单位约定：
/// - 水分/粗蛋白/粗脂肪/粗纤维/灰分/钙/磷/脂肪酸/氨基酸：每百克含量（%，g/100g）
/// - 代谢能：kcal/100g
/// - 微量元素（锌/铜/铁/锰/硒/碘）：mg/100g
/// - 维生素：IU/100g 或 mg/100g（按维生素种类）
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  // ── 基础信息（5 必填）──
  /// 食材名称（必填，唯一标识）
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// 分类：主食 / 蔬果 / 补充剂 / 其他（必填）
  TextColumn get category =>
      text().withLength(max: 20).withDefault(const Constant('其他'))();

  /// 是否去壳（必填，影响营养值）
  BoolColumn get isHulled => boolean().withDefault(const Constant(false))();

  /// 数据基准：As Fed（原样）/ Dry Matter（干物质）（必填）
  TextColumn get basis =>
      text().withLength(max: 20).withDefault(const Constant('As Fed'))();

  /// 数据来源（必填，如 USDA / Feedipedia / 厂家检测报告）
  TextColumn get dataSource => text().withLength(max: 200)();

  // ── 元数据（选填）──
  /// 数据质量等级：A（实验室）/ B（官方数据库）/ C（论文）/ D（企业标注）/ E（经验值）
  TextColumn get dataConfidence => text().withLength(max: 1).nullable()();

  /// 食材图片路径
  TextColumn get imageUrl => text().nullable()();

  // ── L1 核心营养（4 必填 + 2 选填）── 单位 %（每百克含量）──
  /// 水分（必填）
  RealColumn get moisture => real().withDefault(const Constant(0))();
  /// 粗蛋白（必填）
  RealColumn get crudeProtein => real().withDefault(const Constant(0))();
  /// 粗脂肪（必填）
  RealColumn get crudeFat => real().withDefault(const Constant(0))();
  /// 粗纤维（必填）
  RealColumn get crudeFiber => real().withDefault(const Constant(0))();
  /// 粗灰分（选填）
  RealColumn get crudeAsh => real().nullable()();
  /// 代谢能 ME（kcal/100g，选填）
  RealColumn get metabolizableEnergy => real().nullable()();

  // ── L2 繁殖营养：常量矿物质（%，选填）──
  RealColumn get calcium => real().nullable()();
  RealColumn get phosphorus => real().nullable()();
  RealColumn get magnesium => real().nullable()();
  RealColumn get potassium => real().nullable()();
  RealColumn get sodium => real().nullable()();

  // ── L2 繁殖营养：脂肪酸（%，选填）──
  RealColumn get omega3 => real().nullable()();
  RealColumn get omega6 => real().nullable()();
  RealColumn get linoleicAcid => real().nullable()();
  /// α-亚麻酸
  RealColumn get ala => real().nullable()();

  // ── L2 繁殖营养：必需氨基酸（%，选填）──
  /// 赖氨酸
  RealColumn get lysine => real().nullable()();
  /// 蛋氨酸
  RealColumn get methionine => real().nullable()();
  /// 胱氨酸
  RealColumn get cystine => real().nullable()();
  /// 苏氨酸
  RealColumn get threonine => real().nullable()();
  /// 色氨酸
  RealColumn get tryptophan => real().nullable()();
  /// 精氨酸
  RealColumn get arginine => real().nullable()();
  /// 缬氨酸
  RealColumn get valine => real().nullable()();
  /// 异亮氨酸
  RealColumn get isoleucine => real().nullable()();
  /// 亮氨酸
  RealColumn get leucine => real().nullable()();

  // ── L2 繁殖营养：微量元素（mg/100g，选填）──
  /// 锌
  RealColumn get zinc => real().nullable()();
  /// 铜
  RealColumn get copper => real().nullable()();
  /// 铁
  RealColumn get iron => real().nullable()();
  /// 锰
  RealColumn get manganese => real().nullable()();
  /// 硒
  RealColumn get selenium => real().nullable()();
  /// 碘
  RealColumn get iodine => real().nullable()();

  // ── L2 繁殖营养：维生素（选填）──
  /// VA
  RealColumn get vitA => real().nullable()();
  /// VD3
  RealColumn get vitD3 => real().nullable()();
  /// VE
  RealColumn get vitE => real().nullable()();
  /// VK
  RealColumn get vitK => real().nullable()();
  /// B1（硫胺素）
  RealColumn get vitB1 => real().nullable()();
  /// B2（核黄素）
  RealColumn get vitB2 => real().nullable()();
  /// B6
  RealColumn get vitB6 => real().nullable()();
  /// B12
  RealColumn get vitB12 => real().nullable()();
  /// 烟酸
  RealColumn get niacin => real().nullable()();
  /// 泛酸
  RealColumn get pantothenicAcid => real().nullable()();
  /// 生物素
  RealColumn get biotin => real().nullable()();
  /// 叶酸
  RealColumn get folicAcid => real().nullable()();

  // ── 业务规则字段 ──
  /// 适用阶段（JSON 数组，如 ["雏鸟","断奶期"]）
  TextColumn get recommendedStages => text().nullable()();

  /// 最大建议比例 %（必填，防止配方超量）
  RealColumn get maxRatioPercent => real().withDefault(const Constant(100))();

  /// 最小建议比例 %（选填，优化配方）
  RealColumn get minRatioPercent => real().nullable()();

  /// 是否需要浸泡（选填）
  BoolColumn get needsSoaking => boolean().nullable()();

  /// 是否适合发芽（选填）
  BoolColumn get canSprout => boolean().nullable()();

  /// 备注
  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 配方层（Blend）—— 纯%比例混合粮配方，不分餐次
// ═══════════════════════════════════════════════════════════════════════════════

/// 配方表 —— 一袋混合粮的配方定义
class Blends extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 配方名称（必填，唯一标识）
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// 描述
  TextColumn get description => text().withLength(max: 500).nullable()();

  /// 是否启用
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 配方食材项 —— 每种食材在配方中的占比
class BlendItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联配方
  IntColumn get blendId =>
      integer().references(Blends, #id, onDelete: KeyAction.cascade)();

  /// 关联食材
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();

  /// 该食材在配方中的占比 %（所有项之和应为 100）
  RealColumn get percent => real()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 配方绑定表 —— 配方 ↔ 物种 + 阶段（用于推荐列表）
class BlendBindings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联配方
  IntColumn get blendId =>
      integer().references(Blends, #id, onDelete: KeyAction.cascade)();

  /// 关联物种（null = 适用所有物种）
  IntColumn get speciesId =>
      integer().nullable().references(Species, #id)();

  /// 生理阶段
  TextColumn get stage => text().withLength(max: 20)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {blendId, speciesId, stage},
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// 喂养方案层（FeedingPlan）—— per-bird 餐饮管理
// birdId=null → 品种默认方案；birdId=具体鸟 → 该鸟的覆盖方案
// ═══════════════════════════════════════════════════════════════════════════════

/// 喂养方案表
class FeedingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联鸟（null = 品种默认方案）
  IntColumn get birdId =>
      integer().nullable().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 关联物种（品种默认方案时必填，鸟覆盖时可 null 表示继承品种）
  IntColumn get speciesId =>
      integer().nullable().references(Species, #id)();

  /// 适用阶段
  TextColumn get stage => text().withLength(max: 20)();

  /// 是否启用
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 备注
  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 方案餐次槽位 —— 用户自定义的每餐
class FeedingPlanMeals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联喂养方案
  IntColumn get planId =>
      integer().references(FeedingPlans, #id, onDelete: KeyAction.cascade)();

  /// 餐次名（如"早餐"）
  TextColumn get mealName => text().withLength(min: 1, max: 50)();

  /// 时间（如 "07:00"，选填）
  TextColumn get timeOfDay => text().withLength(max: 10).nullable()();

  /// 该餐总克数
  RealColumn get grams => real()();

  /// 排序序号
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 每餐配方组合 —— 一餐内多个配方按%混合
class FeedingPlanMealRecipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 关联餐次
  IntColumn get planMealId => integer()
      .references(FeedingPlanMeals, #id, onDelete: KeyAction.cascade)();

  /// 关联配方
  IntColumn get blendId =>
      integer().references(Blends, #id, onDelete: KeyAction.cascade)();

  /// 该配方在此餐中的占比 %（所有项之和应为 100）
  RealColumn get percent => real()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
