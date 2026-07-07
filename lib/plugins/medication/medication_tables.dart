import 'package:drift/drift.dart';
import '../../database/tables.dart';

// ── 药品库表 ──
/// Shared drug catalog across all birds.
class DrugLibrary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 药品名称
  TextColumn get drugName => text().withLength(min: 1, max: 100)();

  /// 商品名
  TextColumn get brandName => text().withLength(max: 100).nullable()();

  /// 有效成分
  TextColumn get activeIngredient => text().withLength(max: 200).nullable()();

  /// 药物类别：抗生素/驱虫/维生素/益生菌/抗真菌/其他
  TextColumn get drugCategory =>
      text().withLength(max: 20).withDefault(const Constant('其他'))();

  /// 剂型：滴剂/片剂/胶囊/粉剂/注射液
  TextColumn get formulationType =>
      text().withLength(max: 20).withDefault(const Constant('滴剂'))();

  /// 保存方式
  TextColumn get storageInstructions =>
      text().withLength(max: 100).nullable()();

  /// 开封有效期（天）
  IntColumn get openedExpiryDays => integer().nullable()();

  /// 备注
  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 药品规格/浓度表 ──
/// Multiple formulations per drug (e.g., 25mg/mL, 50mg/mL, 100mg/mL).
class DrugFormulations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 关联药品
  IntColumn get drugId =>
      integer().references(DrugLibrary, #id, onDelete: KeyAction.cascade)();

  /// 浓度数值
  RealColumn get concentration => real()();

  /// 单位：mg/mL, mg/片, IU/mL, % 等
  TextColumn get unit =>
      text().withLength(max: 20).withDefault(const Constant('mg/mL'))();

  /// 是否默认规格
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// 显示标签，如 "25mg/mL 装"
  TextColumn get label => text().withLength(max: 50).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 疾病目录表 ──
class DiseaseCatalog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 疾病名称
  TextColumn get diseaseName => text().withLength(min: 1, max: 100)();

  /// 说明
  TextColumn get description => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 剂量规则表 ──
/// Links drug + disease + species (nullable = general) to a dosing rule.
/// Species-specific rules override general (species=null) rules.
class DoseRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 关联药品
  IntColumn get drugId =>
      integer().references(DrugLibrary, #id, onDelete: KeyAction.cascade)();

  /// 关联疾病
  IntColumn get diseaseId =>
      integer().references(DiseaseCatalog, #id, onDelete: KeyAction.cascade)();

  /// 关联品种（null = 通用规则）
  IntColumn get speciesId => integer().nullable()();

  /// 剂量 (mg/kg)
  RealColumn get mgKgDose => real()();

  /// 每日次数
  IntColumn get timesPerDay => integer()();

  /// 疗程天数
  IntColumn get durationDays => integer()();

  /// 给药途径：口服/注射/外用/滴眼/其他
  TextColumn get administrationRoute =>
      text().withLength(max: 20).withDefault(const Constant('口服'))();

  /// 备注（来源：兽医/教材/文献）
  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 喂药方案表（重构） ──
/// Medication plan for a specific bird.
/// Linked to the drug library for structured dose calculation.
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// 鹦鹉 ID
  IntColumn get birdId =>
      integer().references(Birds, #id, onDelete: KeyAction.cascade)();
  IntColumn get drugLibraryId =>
      integer().references(DrugLibrary, #id, onDelete: KeyAction.cascade)();

  /// 关联药品规格
  IntColumn get formulationId => integer()
      .references(DrugFormulations, #id, onDelete: KeyAction.cascade)();

  /// 关联疾病
  IntColumn get diseaseCatalogId =>
      integer().references(DiseaseCatalog, #id, onDelete: KeyAction.cascade)();

  /// 关联剂量规则（可选，无规则时手动填写剂量）
  IntColumn get doseRuleId => integer()
      .nullable()
      .references(DoseRules, #id, onDelete: KeyAction.setNull)();

  /// 计算出的给药体积，如 "0.35ml"
  TextColumn get calculatedDosage => text().withLength(max: 50)();

  /// 手动填写的剂量（无剂量规则时使用）
  TextColumn get manualDosage => text().withLength(max: 50).nullable()();

  /// 每天次数
  IntColumn get timesPerDay => integer().withDefault(const Constant(1))();

  /// 开始日期
  DateTimeColumn get startDate => dateTime()();

  /// 结束日期（null = 长期）
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 备注
  TextColumn get notes => text().withLength(max: 500).nullable()();

  /// 是否启用
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// 停药原因
  TextColumn get stopReason => text().withLength(max: 100).nullable()();

  /// 实际停药日期
  DateTimeColumn get actualStopDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 喂药记录表 ──
/// Records each actual feeding event with status.
class FeedingRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 关联喂药方案
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();

  /// 关联鹦鹉（冗余）
  IntColumn get birdId =>
      integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 关联任务
  IntColumn get taskId => integer().nullable()();

  /// 喂药状态：已喂/吐出/漏喂/补喂/拒绝
  TextColumn get feedingStatus => text().withLength(max: 10)();

  /// 喂药时间
  DateTimeColumn get fedAt => dateTime()();

  /// 操作人
  IntColumn get fedBy => integer().nullable()();

  /// 备注
  TextColumn get notes => text().withLength(max: 200).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 副作用记录表 ──
class SideEffectRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 关联喂药方案
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();

  /// 关联鹦鹉（冗余）
  IntColumn get birdId =>
      integer().references(Birds, #id, onDelete: KeyAction.cascade)();

  /// 副作用类别：拉稀/食欲下降/呕吐/精神差/恢复/其他
  TextColumn get sideEffectCategory => text().withLength(max: 20)();

  /// 描述
  TextColumn get description => text().withLength(max: 500).nullable()();

  /// 严重程度：轻度/中度/重度
  TextColumn get severity =>
      text().withLength(max: 10).withDefault(const Constant('轻度'))();

  /// 观察时间
  DateTimeColumn get observedAt => dateTime()();

  /// 恢复时间
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── 停药条件表 ──
class StopConditions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 关联喂药方案（一对一）
  IntColumn get medicationId => integer()
      .unique()
      .references(Medications, #id, onDelete: KeyAction.cascade)();

  /// 停药原因
  TextColumn get reason => text().withLength(max: 100)();

  /// 实际停药日期
  DateTimeColumn get actualStopDate => dateTime()();

  /// 备注
  TextColumn get notes => text().withLength(max: 200).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
