import 'dart:convert';

import 'package:drift/drift.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import '../../utils/uuid.dart';
import 'nutrition_math.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 营养插件 Repository —— Drift extension on AppDatabase
//
// 分为三部分：
// 1. 食材库 CRUD（Foods）
// 2. 食谱 + 餐次 + 食物项 CRUD（Recipes / RecipeMeals / RecipeMealItems）
// 3. 食谱-物种-阶段绑定管理（RecipeBindings）
// ═══════════════════════════════════════════════════════════════════════════════

extension NutritionRepository on AppDatabase {
  // ────────────────────────────────────────────────────────────────────────────
  // 食材库 CRUD
  // ────────────────────────────────────────────────────────────────────────────

  /// 新增食材。返回插入后的完整行。
  Future<Food> addFood({
    required String name,
    String category = '其他',
    bool isHulled = false,
    String basis = 'As Fed',
    required String dataSource,
    String? dataConfidence,
    String? imageUrl,
    // L1 核心营养
    double moisture = 0,
    double crudeProtein = 0,
    double crudeFat = 0,
    double crudeFiber = 0,
    double? crudeAsh,
    double? metabolizableEnergy,
    // L2 矿物质
    double? calcium,
    double? phosphorus,
    double? magnesium,
    double? potassium,
    double? sodium,
    // L2 脂肪酸
    double? omega3,
    double? omega6,
    double? linoleicAcid,
    double? ala,
    // L2 氨基酸
    double? lysine,
    double? methionine,
    double? cystine,
    double? threonine,
    double? tryptophan,
    double? arginine,
    double? valine,
    double? isoleucine,
    double? leucine,
    // L2 微量元素
    double? zinc,
    double? copper,
    double? iron,
    double? manganese,
    double? selenium,
    double? iodine,
    // L2 维生素
    double? vitA,
    double? vitD3,
    double? vitE,
    double? vitK,
    double? vitB1,
    double? vitB2,
    double? vitB6,
    double? vitB12,
    double? niacin,
    double? pantothenicAcid,
    double? biotin,
    double? folicAcid,
    // 业务规则
    List<String>? recommendedStages,
    double maxRatioPercent = 100,
    double? minRatioPercent,
    bool? needsSoaking,
    bool? canSprout,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    return into(foods).insertReturning(
      FoodsCompanion.insert(
        uuid: genUuid(),
        name: name,
        category: Value(category),
        isHulled: Value(isHulled),
        basis: Value(basis),
        dataSource: dataSource,
        dataConfidence: Value(dataConfidence),
        imageUrl: Value(imageUrl),
        moisture: Value(moisture),
        crudeProtein: Value(crudeProtein),
        crudeFat: Value(crudeFat),
        crudeFiber: Value(crudeFiber),
        crudeAsh: Value(crudeAsh),
        metabolizableEnergy: Value(metabolizableEnergy),
        calcium: Value(calcium),
        phosphorus: Value(phosphorus),
        magnesium: Value(magnesium),
        potassium: Value(potassium),
        sodium: Value(sodium),
        omega3: Value(omega3),
        omega6: Value(omega6),
        linoleicAcid: Value(linoleicAcid),
        ala: Value(ala),
        lysine: Value(lysine),
        methionine: Value(methionine),
        cystine: Value(cystine),
        threonine: Value(threonine),
        tryptophan: Value(tryptophan),
        arginine: Value(arginine),
        valine: Value(valine),
        isoleucine: Value(isoleucine),
        leucine: Value(leucine),
        zinc: Value(zinc),
        copper: Value(copper),
        iron: Value(iron),
        manganese: Value(manganese),
        selenium: Value(selenium),
        iodine: Value(iodine),
        vitA: Value(vitA),
        vitD3: Value(vitD3),
        vitE: Value(vitE),
        vitK: Value(vitK),
        vitB1: Value(vitB1),
        vitB2: Value(vitB2),
        vitB6: Value(vitB6),
        vitB12: Value(vitB12),
        niacin: Value(niacin),
        pantothenicAcid: Value(pantothenicAcid),
        biotin: Value(biotin),
        folicAcid: Value(folicAcid),
        recommendedStages: Value(
            recommendedStages != null ? jsonEncode(recommendedStages) : null),
        maxRatioPercent: Value(maxRatioPercent),
        minRatioPercent: Value(minRatioPercent),
        needsSoaking: Value(needsSoaking),
        canSprout: Value(canSprout),
        notes: Value(notes),
        createdAt: Value(createdAt ?? AppClock.now),
        updatedAt: Value(updatedAt ?? AppClock.now),
      ),
    );
  }

  /// 更新食材（部分更新，null 参数不修改对应字段）。
  Future<Food> updateFood(
    int id, {
    String? name,
    String? category,
    bool? isHulled,
    String? basis,
    String? dataSource,
    String? dataConfidence,
    String? imageUrl,
    double? moisture,
    double? crudeProtein,
    double? crudeFat,
    double? crudeFiber,
    double? crudeAsh,
    double? metabolizableEnergy,
    double? calcium,
    double? phosphorus,
    double? magnesium,
    double? potassium,
    double? sodium,
    double? omega3,
    double? omega6,
    double? linoleicAcid,
    double? ala,
    double? lysine,
    double? methionine,
    double? cystine,
    double? threonine,
    double? tryptophan,
    double? arginine,
    double? valine,
    double? isoleucine,
    double? leucine,
    double? zinc,
    double? copper,
    double? iron,
    double? manganese,
    double? selenium,
    double? iodine,
    double? vitA,
    double? vitD3,
    double? vitE,
    double? vitK,
    double? vitB1,
    double? vitB2,
    double? vitB6,
    double? vitB12,
    double? niacin,
    double? pantothenicAcid,
    double? biotin,
    double? folicAcid,
    List<String>? recommendedStages,
    double? maxRatioPercent,
    double? minRatioPercent,
    bool? needsSoaking,
    bool? canSprout,
    String? notes,
  }) async {
    final list = await (update(foods)..where((t) => t.id.equals(id)))
        .writeReturning(FoodsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
      isHulled: isHulled != null ? Value(isHulled) : const Value.absent(),
      basis: basis != null ? Value(basis) : const Value.absent(),
      dataSource:
          dataSource != null ? Value(dataSource) : const Value.absent(),
      dataConfidence: dataConfidence != null
          ? Value(dataConfidence)
          : const Value.absent(),
      imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
      moisture: moisture != null ? Value(moisture) : const Value.absent(),
      crudeProtein:
          crudeProtein != null ? Value(crudeProtein) : const Value.absent(),
      crudeFat: crudeFat != null ? Value(crudeFat) : const Value.absent(),
      crudeFiber: crudeFiber != null ? Value(crudeFiber) : const Value.absent(),
      crudeAsh: crudeAsh != null ? Value(crudeAsh) : const Value.absent(),
      metabolizableEnergy: metabolizableEnergy != null
          ? Value(metabolizableEnergy)
          : const Value.absent(),
      calcium: calcium != null ? Value(calcium) : const Value.absent(),
      phosphorus:
          phosphorus != null ? Value(phosphorus) : const Value.absent(),
      magnesium:
          magnesium != null ? Value(magnesium) : const Value.absent(),
      potassium:
          potassium != null ? Value(potassium) : const Value.absent(),
      sodium: sodium != null ? Value(sodium) : const Value.absent(),
      omega3: omega3 != null ? Value(omega3) : const Value.absent(),
      omega6: omega6 != null ? Value(omega6) : const Value.absent(),
      linoleicAcid: linoleicAcid != null
          ? Value(linoleicAcid)
          : const Value.absent(),
      ala: ala != null ? Value(ala) : const Value.absent(),
      lysine: lysine != null ? Value(lysine) : const Value.absent(),
      methionine:
          methionine != null ? Value(methionine) : const Value.absent(),
      cystine: cystine != null ? Value(cystine) : const Value.absent(),
      threonine:
          threonine != null ? Value(threonine) : const Value.absent(),
      tryptophan:
          tryptophan != null ? Value(tryptophan) : const Value.absent(),
      arginine: arginine != null ? Value(arginine) : const Value.absent(),
      valine: valine != null ? Value(valine) : const Value.absent(),
      isoleucine:
          isoleucine != null ? Value(isoleucine) : const Value.absent(),
      leucine: leucine != null ? Value(leucine) : const Value.absent(),
      zinc: zinc != null ? Value(zinc) : const Value.absent(),
      copper: copper != null ? Value(copper) : const Value.absent(),
      iron: iron != null ? Value(iron) : const Value.absent(),
      manganese:
          manganese != null ? Value(manganese) : const Value.absent(),
      selenium:
          selenium != null ? Value(selenium) : const Value.absent(),
      iodine: iodine != null ? Value(iodine) : const Value.absent(),
      vitA: vitA != null ? Value(vitA) : const Value.absent(),
      vitD3: vitD3 != null ? Value(vitD3) : const Value.absent(),
      vitE: vitE != null ? Value(vitE) : const Value.absent(),
      vitK: vitK != null ? Value(vitK) : const Value.absent(),
      vitB1: vitB1 != null ? Value(vitB1) : const Value.absent(),
      vitB2: vitB2 != null ? Value(vitB2) : const Value.absent(),
      vitB6: vitB6 != null ? Value(vitB6) : const Value.absent(),
      vitB12: vitB12 != null ? Value(vitB12) : const Value.absent(),
      niacin: niacin != null ? Value(niacin) : const Value.absent(),
      pantothenicAcid: pantothenicAcid != null
          ? Value(pantothenicAcid)
          : const Value.absent(),
      biotin: biotin != null ? Value(biotin) : const Value.absent(),
      folicAcid:
          folicAcid != null ? Value(folicAcid) : const Value.absent(),
      recommendedStages: recommendedStages != null
          ? Value(jsonEncode(recommendedStages))
          : const Value.absent(),
      maxRatioPercent: maxRatioPercent != null
          ? Value(maxRatioPercent)
          : const Value.absent(),
      minRatioPercent: minRatioPercent != null
          ? Value(minRatioPercent)
          : const Value.absent(),
      needsSoaking:
          needsSoaking != null ? Value(needsSoaking) : const Value.absent(),
      canSprout:
          canSprout != null ? Value(canSprout) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  /// 软删除食材。
  Future<void> deleteFood(int id) async {
    await (update(foods)..where((t) => t.id.equals(id)))
        .write(FoodsCompanion(deletedAt: Value(AppClock.now)));
  }

  /// 按 id 查询单个食材（排除已删除）。
  Future<Food?> getFoodById(int id) =>
      (select(foods)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  /// 查询全部食材（排除已删除）。
  /// [category] 筛选分类；[stage] 筛选适用阶段（匹配 recommendedStages JSON）。
  Future<List<Food>> getAllFoods({String? category, String? stage}) {
    final query = select(foods)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (stage != null) {
      // JSON 数组包含阶段名
      query.where((t) => t.recommendedStages.like('%"$stage"%'));
    }
    return query.get();
  }

  /// 按关键词搜索食材（名称模糊匹配）。
  Future<List<Food>> searchFoods(String keyword) {
    return (select(foods)
          ..where(
              (t) => t.deletedAt.isNull() & t.name.like('%$keyword%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// 按名称精确匹配（导入时检测同名）。
  Future<Food?> getFoodByName(String name) =>
      (select(foods)
            ..where((t) => t.deletedAt.isNull() & t.name.equals(name)))
          .getSingleOrNull();

  // ────────────────────────────────────────────────────────────────────────────
  // 配方(Blend) CRUD —— 纯%比例混合粮
  // ────────────────────────────────────────────────────────────────────────────

  /// 新增配方。
  Future<Blend> addBlend({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    return into(blends).insertReturning(
      BlendsCompanion.insert(
        uuid: genUuid(),
        name: name,
        description: Value(description),
        isActive: Value(isActive),
      ),
    );
  }

  /// 更新配方基本信息。
  Future<Blend> updateBlend(
    int id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final list = await (update(blends)..where((t) => t.id.equals(id)))
        .writeReturning(BlendsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  /// 删除配方（真删除，级联删除食材项、绑定、引用）。
  Future<void> deleteBlend(int id) async {
    await (delete(blends)..where((t) => t.id.equals(id))).go();
  }

  /// 查询全部配方（排除已软删除）。
  Future<List<Blend>> getAllBlends() =>
      (select(blends)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// 按 id 查询单个配方。
  Future<Blend?> getBlendById(int id) =>
      (select(blends)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  /// 按名称精确匹配（导入时检测同名）。
  Future<Blend?> getBlendByName(String name) =>
      (select(blends)
            ..where((t) => t.deletedAt.isNull() & t.name.equals(name)))
          .getSingleOrNull();

  // ── 配方食材项 CRUD ──

  /// 新增配方食材项。
  Future<BlendItem> addBlendItem({
    required int blendId,
    required int foodId,
    required double percent,
  }) async {
    return into(blendItems).insertReturning(
      BlendItemsCompanion.insert(
        uuid: genUuid(),
        blendId: blendId,
        foodId: foodId,
        percent: percent,
      ),
    );
  }

  /// 更新配方食材项（主要改占比）。
  Future<BlendItem> updateBlendItem(
    int id, {
    int? foodId,
    double? percent,
  }) async {
    final list =
        await (update(blendItems)..where((t) => t.id.equals(id)))
            .writeReturning(BlendItemsCompanion(
      foodId: foodId != null ? Value(foodId) : const Value.absent(),
      percent: percent != null ? Value(percent) : const Value.absent(),
    ));
    return list.first;
  }

  /// 删除配方食材项。
  Future<void> deleteBlendItem(int id) async {
    await (delete(blendItems)..where((t) => t.id.equals(id))).go();
  }

  // ── 配方聚合查询 ──

  /// 加载配方的完整聚合（含食材项 → 食材营养、绑定）。
  Future<BlendWithDetails?> getBlendWithDetails(int blendId) async {
    final blend = await getBlendById(blendId);
    if (blend == null) return null;

    // 查询食材项（JOIN 食材）
    final itemRows = await (select(blendItems).join([
      innerJoin(foods, foods.id.equalsExp(blendItems.foodId)),
    ])
          ..where(blendItems.blendId.equals(blendId)))
        .get();

    final items = itemRows.map((row) {
      final item = row.readTable(blendItems);
      final food = row.readTable(foods);
      return BlendItemWithFood(item: item, food: food);
    }).toList();

    // 查询绑定
    final bindings = await (select(blendBindings)
          ..where((t) => t.blendId.equals(blendId)))
        .get();

    return BlendWithDetails(
      blend: blend,
      items: items,
      bindings: bindings,
    );
  }

  /// 按物种 + 阶段查询配方列表（用于喂养方案编辑器推荐）。
  /// 同时匹配 speciesId 精确绑定 和 speciesId=null（通用配方）。
  Future<List<Blend>> getBlendsBySpeciesAndStage(
      int speciesId, String stage) async {
    final bindingQuery = selectOnly(blendBindings)
      ..addColumns([blendBindings.blendId]);
    bindingQuery.where(blendBindings.stage.equals(stage) &
        (blendBindings.speciesId.equals(speciesId) |
            blendBindings.speciesId.isNull()));
    final bindingRows =
        await bindingQuery.map((row) => row.read(blendBindings.blendId)!).get();

    if (bindingRows.isEmpty) return [];

    final result = await (select(blends)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.isActive.equals(true) &
              t.id.isIn(bindingRows))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return result;
  }

  // ── 配方-物种-阶段绑定 ──

  /// 绑定配方到物种+阶段。speciesId 为 null 表示通用绑定。
  Future<void> bindBlend({
    required int blendId,
    int? speciesId,
    required String stage,
  }) async {
    final existing = await (select(blendBindings)
          ..where((t) =>
              t.blendId.equals(blendId) &
              t.stage.equals(stage) &
              (speciesId == null
                  ? t.speciesId.isNull()
                  : t.speciesId.equals(speciesId))))
        .get();
    if (existing.isNotEmpty) return;

    await into(blendBindings).insert(BlendBindingsCompanion.insert(
      uuid: genUuid(),
      blendId: blendId,
      stage: stage,
      speciesId: Value(speciesId),
    ));
  }

  /// 解除配方绑定。
  Future<void> unbindBlend({
    required int blendId,
    int? speciesId,
    required String stage,
  }) async {
    await (delete(blendBindings)..where((t) =>
        t.blendId.equals(blendId) &
        t.stage.equals(stage) &
        (speciesId == null
            ? t.speciesId.isNull()
            : t.speciesId.equals(speciesId)))).go();
  }

  /// 查询配方的所有绑定。
  Future<List<BlendBinding>> getBlendBindings(int blendId) =>
      (select(blendBindings)..where((t) => t.blendId.equals(blendId)))
          .get();

  /// 批量查询多个配方的绑定，按 blendId 分组返回。
  ///
  /// 单条 SQL（`blend_id IN (...)`）替代 N 次 [getBlendBindings]，消除列表页 N+1。
  /// [blendIds] 为空时返回空 Map。
  Future<Map<int, List<BlendBinding>>> getBlendBindingsForAll(
      Iterable<int> blendIds) async {
    final ids = blendIds.toList();
    if (ids.isEmpty) return {};
    final rows = await (select(blendBindings)
          ..where((t) => t.blendId.isIn(ids)))
        .get();
    final result = <int, List<BlendBinding>>{};
    for (final r in rows) {
      (result[r.blendId] ??= []).add(r);
    }
    return result;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 喂养方案(FeedingPlan) CRUD —— per-bird 餐饮管理
  // birdId=null → 品种默认方案；birdId=具体鸟 → 该鸟覆盖方案
  // ────────────────────────────────────────────────────────────────────────────

  /// 新增喂养方案。
  /// [birdId] 非空 → 该鸟的覆盖方案；为空 → 品种默认方案(需提供 speciesId)。
  Future<FeedingPlan> addFeedingPlan({
    int? birdId,
    int? speciesId,
    required String stage,
    bool isActive = true,
    String? notes,
  }) async {
    return into(feedingPlans).insertReturning(
      FeedingPlansCompanion.insert(
        uuid: genUuid(),
        birdId: Value(birdId),
        speciesId: Value(speciesId),
        stage: stage,
        isActive: Value(isActive),
        notes: Value(notes),
      ),
    );
  }

  /// 更新喂养方案基本信息。
  Future<FeedingPlan> updateFeedingPlan(
    int id, {
    String? stage,
    bool? isActive,
    String? notes,
  }) async {
    final list =
        await (update(feedingPlans)..where((t) => t.id.equals(id)))
            .writeReturning(FeedingPlansCompanion(
      stage: stage != null ? Value(stage) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  /// 删除喂养方案（真删除，级联删除餐次、配方组合）。
  Future<void> deleteFeedingPlan(int id) async {
    await (delete(feedingPlans)..where((t) => t.id.equals(id))).go();
  }

  /// 查询全部喂养方案（排除已软删除）。
  Future<List<FeedingPlan>> getAllFeedingPlans() =>
      (select(feedingPlans)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.stage)]))
          .get();

  /// 按 id 查询单个喂养方案。
  Future<FeedingPlan?> getFeedingPlanById(int id) =>
      (select(feedingPlans)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  /// 按名称精确匹配（导入时检测同名，用 stage+birdId 组合）。
  Future<FeedingPlan?> getFeedingPlanByBirdAndStage(
          int? birdId, String stage) =>
      (select(feedingPlans)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.stage.equals(stage) &
                (birdId == null
                    ? t.birdId.isNull()
                    : t.birdId.equals(birdId))))
          .getSingleOrNull();

  /// 查询某只鸟在指定阶段的喂养方案（核心查询）。
  /// 优先返回该鸟的覆盖方案(birdId=该鸟)，无则返回品种默认方案(birdId=null)。
  Future<FeedingPlanWithDetails?> getFeedingPlanForBird(
      int birdId, int speciesId, String stage) async {
    // 1. 先查该鸟的覆盖方案
    var plan = await (select(feedingPlans)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.isActive.equals(true) &
              t.birdId.equals(birdId) &
              t.stage.equals(stage)))
        .getSingleOrNull();

    // 2. 无覆盖方案 → 查品种默认方案
    if (plan == null) {
      plan = await (select(feedingPlans)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.isActive.equals(true) &
                t.birdId.isNull() &
                t.speciesId.equals(speciesId) &
                t.stage.equals(stage)))
          .getSingleOrNull();
    }

    if (plan == null) return null;
    return getFeedingPlanWithDetails(plan.id);
  }

  // ── 方案餐次 CRUD ──

  /// 新增方案餐次槽位。
  Future<FeedingPlanMeal> addFeedingPlanMeal({
    required int planId,
    required String mealName,
    String? timeOfDay,
    required double grams,
    int sortOrder = 0,
  }) async {
    return into(feedingPlanMeals).insertReturning(
      FeedingPlanMealsCompanion.insert(
        uuid: genUuid(),
        planId: planId,
        mealName: mealName,
        timeOfDay: Value(timeOfDay),
        grams: grams,
        sortOrder: Value(sortOrder),
      ),
    );
  }

  /// 更新方案餐次。
  Future<FeedingPlanMeal> updateFeedingPlanMeal(
    int id, {
    String? mealName,
    String? timeOfDay,
    double? grams,
    int? sortOrder,
  }) async {
    final list = await (update(feedingPlanMeals)
          ..where((t) => t.id.equals(id)))
        .writeReturning(FeedingPlanMealsCompanion(
      mealName: mealName != null ? Value(mealName) : const Value.absent(),
      timeOfDay:
          timeOfDay != null ? Value(timeOfDay) : const Value.absent(),
      grams: grams != null ? Value(grams) : const Value.absent(),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
    ));
    return list.first;
  }

  /// 删除方案餐次（级联删除其配方组合）。
  Future<void> deleteFeedingPlanMeal(int id) async {
    await (delete(feedingPlanMeals)..where((t) => t.id.equals(id))).go();
  }

  // ── 餐次配方组合 CRUD ──

  /// 新增餐次配方组合项。
  Future<FeedingPlanMealRecipe> addFeedingPlanMealRecipe({
    required int planMealId,
    required int blendId,
    required double percent,
  }) async {
    return into(feedingPlanMealRecipes).insertReturning(
      FeedingPlanMealRecipesCompanion.insert(
        uuid: genUuid(),
        planMealId: planMealId,
        blendId: blendId,
        percent: percent,
      ),
    );
  }

  /// 更新餐次配方组合项（主要改占比）。
  Future<FeedingPlanMealRecipe> updateFeedingPlanMealRecipe(
    int id, {
    int? blendId,
    double? percent,
  }) async {
    final list = await (update(feedingPlanMealRecipes)
          ..where((t) => t.id.equals(id)))
        .writeReturning(FeedingPlanMealRecipesCompanion(
      blendId: blendId != null ? Value(blendId) : const Value.absent(),
      percent: percent != null ? Value(percent) : const Value.absent(),
    ));
    return list.first;
  }

  /// 删除餐次配方组合项。
  Future<void> deleteFeedingPlanMealRecipe(int id) async {
    await (delete(feedingPlanMealRecipes)..where((t) => t.id.equals(id)))
        .go();
  }

  // ── 方案聚合查询 ──

  /// 加载喂养方案的完整聚合（含餐次 → 配方组合 → 配方详情 → 食材营养）。
  /// 预加载每个配方的食材详情，供营养计算引擎使用。
  Future<FeedingPlanWithDetails?> getFeedingPlanWithDetails(
      int planId) async {
    final plan = await getFeedingPlanById(planId);
    if (plan == null) return null;

    // 查询餐次（按排序）
    final meals = await (select(feedingPlanMeals)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    // 查询每餐的配方组合（JOIN 配方），并预加载配方详情
    final mealsWithRecipes = <FeedingPlanMealWithRecipes>[];
    for (final meal in meals) {
      final recipeRows = await (select(feedingPlanMealRecipes).join([
        innerJoin(blends, blends.id.equalsExp(feedingPlanMealRecipes.blendId)),
      ])
            ..where(feedingPlanMealRecipes.planMealId.equals(meal.id)))
          .get();

      final recipes = <MealRecipeWithBlend>[];
      for (final row in recipeRows) {
        final item = row.readTable(feedingPlanMealRecipes);
        final blend = row.readTable(blends);
        // 预加载配方详情（含食材%与营养）
        final blendDetail = await getBlendWithDetails(blend.id);
        recipes.add(MealRecipeWithBlend(
          item: item,
          blend: blend,
          blendDetail: blendDetail,
        ));
      }

      mealsWithRecipes
          .add(FeedingPlanMealWithRecipes(meal: meal, recipes: recipes));
    }

    return FeedingPlanWithDetails(plan: plan, meals: mealsWithRecipes);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 辅助方法
  // ────────────────────────────────────────────────────────────────────────────

  /// 解析食材的推荐阶段 JSON 为 List<String>。
  static List<String> parseRecommendedStages(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
