import 'package:flutter/material.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../widgets/feather_icon.dart';
import '../stage/stage_plugin.dart';
import 'nutrition_math.dart';
import 'nutrition_repository.dart';
import 'nutrition_stage.dart';
import 'widgets/nutrition_summary_card.dart';
import 'screens/feeding_plan_editor_screen.dart';

/// 鸟详情页喂养 Tab —— 展示当前阶段的喂养方案 + 营养摘要。
///
/// 流程：
/// 1. StageInferrer.infer(bird) → stage（支持手动覆盖）
/// 2. 查方案：先该鸟覆盖方案，无则品种默认方案
/// 3. 展示营养汇总 + 各餐明细（展开可看配方→食材分解）
class FeedingSection extends StatefulWidget {
  final int birdId;

  const FeedingSection({super.key, required this.birdId});

  @override
  State<FeedingSection> createState() => _FeedingSectionState();
}

class _FeedingSectionState extends State<FeedingSection> {
  AppDatabase get _db => pluginRegistry.db!;

  BirdWithDetails? _bird;
  FeedingPlanWithDetails? _plan;
  String? _currentStage;
  bool _isOverride = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bird = await _db.getWithDetails(widget.birdId);
    if (bird == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // 从 stage 插件读取阶段（同步调用，无缓存时回退到年龄推断）
    final stage = pluginRegistry.call('stage', 'getStage', bird.bird.id);
    final stageStr = (stage is String) ? stage : RecipeStage.adult;
    final isOverride = StageInferrer.isManualOverride(bird);

    // 查方案：先该鸟覆盖，无则品种默认
    FeedingPlanWithDetails? plan;
    plan = await _db.getFeedingPlanForBird(
        bird.bird.id, bird.bird.speciesId, stageStr);

    if (mounted) {
      setState(() {
        _bird = bird;
        _currentStage = stageStr;
        _isOverride = isOverride;
        _plan = plan;
        _loading = false;
      });
    }
  }

  Future<void> _setStageOverride(String? stage) async {
    if (stage == null) {
      // 清除覆盖：清除 Bird 表的 stageOverride，然后让 stage 插件重算
      await _db.updateBird(widget.birdId, clearStageOverride: true);
      await pluginRegistry.call('stage', 'clearStage', widget.birdId);
      await pluginRegistry.call('stage', 'recompute', widget.birdId);
    } else {
      // 设置手动覆盖：同时写入 Bird 表（持久化）和 stage 插件缓存
      await _db.updateBird(widget.birdId, stageOverride: stage);
      await pluginRegistry.call(
          'stage', 'setStage', SetStageArgs(widget.birdId, stage, source: StageSource.manual));
    }
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bird == null) {
      return const Center(child: Text('未找到鹦鹉信息'));
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        _buildStageBadge(theme),
        const SizedBox(height: 8),
        _buildStageSwitcher(theme),
        const SizedBox(height: 8),
        if (_plan == null)
          _buildEmptyState(theme)
        else ...[
          NutritionSummaryCard(summary: _plan!.nutrition),
          const SizedBox(height: 8),
          _buildPlanInfo(theme),
          const SizedBox(height: 8),
          _buildMealsDetail(theme),
        ],
      ],
    );
  }

  Widget _buildStageBadge(ThemeData theme) {
    final isBreeding = RecipeStage.isBreedingStage(_currentStage ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isBreeding
            ? Colors.purple.shade50
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          isBreeding
              ? const Icon(Icons.favorite, size: 20)
              : const FeatherIcon(size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前阶段：${_currentStage ?? '未知'}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  _isOverride
                      ? '手动指定 · ${RecipeStage.descriptionOf(_currentStage ?? '')}'
                      : '自动推断 · ${RecipeStage.descriptionOf(_currentStage ?? '')}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageSwitcher(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('切换阶段', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('自动'),
                  selected: !_isOverride,
                  onSelected: (_) => _setStageOverride(null),
                ),
                ...RecipeStage.all.map((stage) {
                  final selected =
                      _isOverride && _currentStage == stage;
                  return FilterChip(
                    label: Text(stage),
                    selected: selected,
                    onSelected: (_) => _setStageOverride(stage),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInfo(ThemeData theme) {
    final isDefault = _plan!.isSpeciesDefault;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(isDefault ? Icons.group : Icons.person, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isDefault
                    ? '使用品种默认方案（点击编辑可创建自定义方案）'
                    : '使用该鸟的自定义方案',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: _editPlan,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('编辑'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              '该阶段（$_currentStage）暂无喂养方案',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '为「${_bird!.bird.name}」创建自定义方案',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _createPlan,
              icon: const Icon(Icons.add),
              label: const Text('创建喂养方案'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsDetail(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('餐次明细',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._plan!.meals.map((meal) {
              return ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  meal.meal.mealName +
                      (meal.meal.timeOfDay != null
                          ? ' (${meal.meal.timeOfDay})'
                          : ''),
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${meal.meal.grams.toStringAsFixed(1)}g · ${meal.recipes.length} 个配方',
                  style: theme.textTheme.labelSmall,
                ),
                children: meal.recipes.map((r) {
                  return _buildRecipeDetail(theme, r);
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDetail(ThemeData theme, MealRecipeWithBlend recipe) {
    final blendDetail = recipe.blendDetail;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16),
      title: Text(
        '${recipe.blend.name} · ${recipe.item.percent.toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: blendDetail == null || blendDetail.items.isEmpty
          ? null
          : Text(
              blendDetail.items
                  .map((i) =>
                      '${i.food.name} ${i.item.percent.toStringAsFixed(0)}%')
                  .join('、'),
              style: theme.textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Text(
        '${(recipe.item.percent / 100 * 0).toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 1),
      ),
    );
  }

  Future<void> _createPlan() async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => FeedingPlanEditorScreen(
        birdId: widget.birdId,
        stage: _currentStage!,
      ),
    ));
    if (changed == true) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<void> _editPlan() async {
    if (_plan == null) return;
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => FeedingPlanEditorScreen(
        birdId: widget.birdId,
        stage: _currentStage!,
        plan: _plan!.plan,
      ),
    ));
    if (changed == true) {
      setState(() => _loading = true);
      await _load();
    }
  }
}
