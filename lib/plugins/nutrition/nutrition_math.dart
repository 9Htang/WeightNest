import '../../database/database.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 营养计算模块
//
// 两层模型：
// 1. 配方(Blend)营养 = Σ(food.营养 × item.percent / 100) × asFedFactor
//    输出"每 100g 配方"的营养值（无需归一化，percent 已是权重）
// 2. 喂养方案(FeedingPlan)营养 = 各餐展开为食材克数后累加
//    食材 grams = 餐grams × 配方.percent/100 × 食材.percent/100
//    然后用 _NutritionAccumulator.addFood(food, grams) 统一累加
//
// 关键规则：
// 1. basis 为 Dry Matter 时，先按水分换算回 As Fed 再参与计算（统一基准）
// 2. 钙磷比 = calcium / phosphorus（两者皆非空才计算）
// 3. 某食物关键营养缺失（蛋白/脂肪）→ 跳过该字段，但标记 dataSufficient=false
// 4. NULL = 无数据，不参与计算（不当作 0）
// ═══════════════════════════════════════════════════════════════════════════════

/// 营养摘要 —— 配方或喂养方案的聚合营养指标
class NutritionSummary {
  /// 粗蛋白（%，每百克含量）
  final double? protein;

  /// 粗脂肪（%）
  final double? fat;

  /// 粗纤维（%）
  final double? fiber;

  /// 水分（%）
  final double? moisture;

  /// 粗灰分（%）
  final double? ash;

  /// 代谢能（kcal/100g）
  final double? energy;

  /// 钙（%）
  final double? calcium;

  /// 磷（%）
  final double? phosphorus;

  /// 钙磷比（Ca:P，计算值）
  final double? caPRatio;

  /// Omega-3（%）
  final double? omega3;

  /// Omega-6（%）
  final double? omega6;

  /// Omega-6 : Omega-3 比例（计算值）
  final double? omegaRatio;

  /// 每日总克数（方案级别）
  final double totalGrams;

  /// 营养数据完整度 0-100（L1+L2 非空字段占比）
  final int dataCompleteness;

  /// 关键营养（蛋白、脂肪）是否充分，可用于参与自动配方判断
  final bool dataSufficient;

  const NutritionSummary({
    this.protein,
    this.fat,
    this.fiber,
    this.moisture,
    this.ash,
    this.energy,
    this.calcium,
    this.phosphorus,
    this.caPRatio,
    this.omega3,
    this.omega6,
    this.omegaRatio,
    this.totalGrams = 0,
    this.dataCompleteness = 0,
    this.dataSufficient = true,
  });

  /// 空摘要（无数据时）
  static const empty = NutritionSummary(
    totalGrams: 0,
    dataCompleteness: 0,
    dataSufficient: false,
  );
}

/// 营养累加器 —— 内部使用，逐步累加各营养项的加权和
class _NutritionAccumulator {
  // 各营养素的加权和（营养值 × 克数），null 表示尚无数据
  double? _protein, _fat, _fiber, _moisture, _ash, _energy;
  double? _calcium, _phosphorus, _omega3, _omega6;

  // 累计克数
  double totalGrams = 0;

  // 是否所有食物的关键营养（蛋白/脂肪）都齐全
  bool allKeyNutrientsPresent = true;

  /// 添加一份食物（按克数贡献营养）。
  /// [food] 食材数据；[grams] 该食物在方案中的克数
  void addFood(Food food, double grams) {
    if (grams <= 0) return;
    totalGrams += grams;

    // 将 Dry Matter 基准换算为 As Fed 系数
    // As Fed 值 = Dry Matter 值 × (100 - moisture) / 100
    final asFedFactor = _asFedFactor(food);

    _protein = _accumulatePercent(_protein, food.crudeProtein, grams, asFedFactor);
    _fat = _accumulatePercent(_fat, food.crudeFat, grams, asFedFactor);
    _fiber = _accumulatePercent(_fiber, food.crudeFiber, grams, asFedFactor);
    _moisture = _accumulatePercent(_moisture, food.moisture, grams, asFedFactor);
    _ash = _accumulatePercent(_ash, food.crudeAsh, grams, asFedFactor);
    _energy = _accumulateValue(_energy, food.metabolizableEnergy, grams, asFedFactor);

    _calcium = _accumulateValue(_calcium, food.calcium, grams, asFedFactor);
    _phosphorus =
        _accumulateValue(_phosphorus, food.phosphorus, grams, asFedFactor);
    _omega3 = _accumulateValue(_omega3, food.omega3, grams, asFedFactor);
    _omega6 = _accumulateValue(_omega6, food.omega6, grams, asFedFactor);

    // 关键营养缺失检测（蛋白/脂肪是 L1 必填，理论上应有值；
    // 但导入或旧数据可能缺失，此处兜底标记）
    if (food.crudeProtein == 0 && food.crudeFat == 0) {
      allKeyNutrientsPresent = false;
    }
  }

  /// 计算换算系数。basis 为 Dry Matter 时，按水分回算到 As Fed。
  double _asFedFactor(Food food) {
    if (food.basis == 'Dry Matter') {
      final moisture = food.moisture;
      // 干物质占比
      final dmPercent = (100 - moisture) / 100;
      if (dmPercent <= 0) return 1; // 异常数据兜底
      return dmPercent;
    }
    return 1; // As Fed 直接使用
  }

  /// 累加百分比字段（%，每百克 → 总克数贡献）。
  /// result += value × grams / 100 × factor
  double? _accumulatePercent(
      double? current, double? value, double grams, double factor) {
    if (value == null) return current;
    final contribution = value * grams / 100 * factor;
    return (current ?? 0) + contribution;
  }

  /// 累加绝对值字段（kcal、mg，每百克 → 总量贡献）。
  double? _accumulateValue(
      double? current, double? value, double grams, double factor) {
    if (value == null) return current;
    final contribution = value * grams / 100 * factor;
    return (current ?? 0) + contribution;
  }

  /// 构建最终摘要。总量字段按"每百克"折算，便于横向比较。
  NutritionSummary build() {
    if (totalGrams <= 0) {
      return NutritionSummary.empty;
    }

    // 按每百克折算（总量 / totalGrams × 100）
    double? per100(double? total) =>
        total == null ? null : total / totalGrams * 100;

    final proteinPct = per100(_protein);
    final calciumPct = per100(_calcium);
    final phosphorusPct = per100(_phosphorus);
    final omega3Pct = per100(_omega3);
    final omega6Pct = per100(_omega6);

    // 钙磷比（两者皆有才计算）
    double? caPRatio;
    if (calciumPct != null && phosphorusPct != null && phosphorusPct > 0) {
      caPRatio = calciumPct / phosphorusPct;
    }

    // Omega 比例
    double? omegaRatio;
    if (omega3Pct != null && omega6Pct != null && omega3Pct > 0) {
      omegaRatio = omega6Pct / omega3Pct;
    }

    return NutritionSummary(
      protein: proteinPct,
      fat: per100(_fat),
      fiber: per100(_fiber),
      moisture: per100(_moisture),
      ash: per100(_ash),
      energy: per100(_energy),
      calcium: calciumPct,
      phosphorus: phosphorusPct,
      caPRatio: caPRatio,
      omega3: omega3Pct,
      omega6: omega6Pct,
      omegaRatio: omegaRatio,
      totalGrams: totalGrams,
      dataCompleteness: 100, // 完整度由调用方按食材单独计算
      dataSufficient: allKeyNutrientsPresent,
    );
  }
}

/// 计算配方的营养摘要（每 100g 配方的营养值）。
///
/// 配方只有 % 比例，无总量。直接用 percent 作为权重：
/// blendNutrient = Σ(food.nutrient × item.percent / 100) × asFedFactor
/// 输出即"每 100g 配方"的营养，无需再归一化。
NutritionSummary computeBlendNutrition(List<BlendItemWithFood> items) {
  // 复用累加器：把 100g 当作"总量"，percent 当作该食材克数
  // 即 food.营养 × (percent/100) × (100/100) × factor = food.营养 × percent/100 × factor
  final acc = _NutritionAccumulator();
  for (final item in items) {
    // percent 即"在 100g 配方中占 percent 克"，直接当 grams 传入
    acc.addFood(item.food, item.item.percent);
  }
  // 累加器内部会把 totalGrams 算成 Σ percent (= 100 如果配比正确)
  // build() 再除以 totalGrams×100 归一化，恰好得到 per-100g
  return acc.build();
}

/// 计算喂养方案的营养摘要。
///
/// 方案有多餐，每餐有克数 + 配方组合(%)。展开为食材克数：
/// 食材 grams = 餐grams × 配方.percent/100 × 食材.percent/100
/// 然后用累加器统一汇总。
NutritionSummary computeFeedingPlanNutrition(
    FeedingPlanWithDetails planDetails) {
  final acc = _NutritionAccumulator();
  // 需要异步加载每个配方的食材详情，这里通过预加载的 blends map 处理
  // 实际调用方应先加载所有 blend details
  for (final meal in planDetails.meals) {
    // meal.blendDetails 是预加载的配方详情（含食材%）
    for (final mealRecipe in meal.recipes) {
      final blendDetail = mealRecipe.blendDetail;
      if (blendDetail == null) continue;
      for (final blendItem in blendDetail.items) {
        // 食材克数 = 餐克数 × 配方占比% × 食材占比% / 10000
        final foodGrams = meal.meal.grams *
            mealRecipe.item.percent /
            100 *
            blendItem.item.percent /
            100;
        acc.addFood(blendItem.food, foodGrams);
      }
    }
  }
  return acc.build();
}

/// 计算单个食材的营养数据完整度（0-100）。
///
/// 统计 L1（6 字段）+ L2 关键字段（约 30 个）的非空占比。
int computeFoodCompleteness(Food food) {
  // L1 核心字段（6 个）
  final l1Values = <double?>[
    food.moisture,
    food.crudeProtein,
    food.crudeFat,
    food.crudeFiber,
    food.crudeAsh,
    food.metabolizableEnergy,
  ];

  // L2 字段（约 30 个）
  final l2Values = <double?>[
    food.calcium,
    food.phosphorus,
    food.magnesium,
    food.potassium,
    food.sodium,
    food.omega3,
    food.omega6,
    food.linoleicAcid,
    food.ala,
    food.lysine,
    food.methionine,
    food.cystine,
    food.threonine,
    food.tryptophan,
    food.arginine,
    food.valine,
    food.isoleucine,
    food.leucine,
    food.zinc,
    food.copper,
    food.iron,
    food.manganese,
    food.selenium,
    food.iodine,
    food.vitA,
    food.vitD3,
    food.vitE,
    food.vitK,
    food.vitB1,
    food.vitB2,
    food.vitB6,
    food.vitB12,
    food.niacin,
    food.pantothenicAcid,
    food.biotin,
    food.folicAcid,
  ];

  final l1Filled = l1Values.where((v) => v != null).length;
  final l2Filled = l2Values.where((v) => v != null).length;

  // L1 权重 60%，L2 权重 40%
  final l1Score = (l1Filled / l1Values.length) * 60;
  final l2Score = (l2Filled / l2Values.length) * 40;

  return (l1Score + l2Score).round();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 复合数据类型 —— 用于 repository 返回嵌套结构
// ═══════════════════════════════════════════════════════════════════════════════

/// 配方食材项 + 关联食材
class BlendItemWithFood {
  final BlendItem item;
  final Food food;

  const BlendItemWithFood({required this.item, required this.food});
}

/// 配方 + 食材项 + 绑定 的完整聚合
class BlendWithDetails {
  final Blend blend;
  final List<BlendItemWithFood> items;
  final List<BlendBinding> bindings;

  const BlendWithDetails({
    required this.blend,
    required this.items,
    required this.bindings,
  });

  /// 计算该配方的营养摘要（每 100g 配方）
  NutritionSummary get nutrition => computeBlendNutrition(items);

  /// 配方各食材占比之和（应为 100）
  double get totalPercent =>
      items.fold(0.0, (sum, i) => sum + i.item.percent);
}

/// 餐次配方组合项 + 关联配方基本信息
class MealRecipeWithBlend {
  final FeedingPlanMealRecipe item;
  final Blend blend;
  /// 预加载的配方详情（含食材%），计算方案营养时由调用方填充
  BlendWithDetails? blendDetail;

  MealRecipeWithBlend({required this.item, required this.blend, this.blendDetail});
}

/// 方案餐次 + 其下配方组合列表
class FeedingPlanMealWithRecipes {
  final FeedingPlanMeal meal;
  final List<MealRecipeWithBlend> recipes;

  const FeedingPlanMealWithRecipes({required this.meal, required this.recipes});
}

/// 喂养方案 + 餐次 + 配方组合 的完整聚合
class FeedingPlanWithDetails {
  final FeedingPlan plan;
  final List<FeedingPlanMealWithRecipes> meals;

  const FeedingPlanWithDetails({
    required this.plan,
    required this.meals,
  });

  /// 计算该方案的营养摘要
  NutritionSummary get nutrition => computeFeedingPlanNutrition(this);

  /// 每日总克数（所有餐次克数之和）
  double get totalDailyGrams =>
      meals.fold(0.0, (sum, m) => sum + m.meal.grams);

  /// 该方案是否为品种默认方案（birdId 为空）
  bool get isSpeciesDefault => plan.birdId == null;
}

/// 食材 + 其营养完整度（列表展示用，避免每个 cell 单独计算）
class FoodWithCompleteness {
  final Food food;
  final int completeness;

  const FoodWithCompleteness({required this.food, required this.completeness});
}
