import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../../../repositories/bird_repository.dart';
import '../../../repositories/species_repository.dart';
import '../../../widgets/feather_icon.dart';
import '../meal_template_provider.dart';
import '../nutrition_math.dart';
import '../nutrition_repository.dart';
import '../nutrition_stage.dart';
import '../widgets/nutrition_summary_card.dart';
import 'blend_library_screen.dart';

/// 喂养方案编辑器 —— 管理某只鸟（或品种默认）的餐饮方案。
///
/// 方案 = 多个餐次槽位，每餐由 1~N 个配方按%组合 + 该餐克数。
///
/// 用法：
/// - 从鸟详情页进入：[birdId] 非空，[stage] 为推断阶段
/// - 从配置页进入：[birdId] 为空，编辑品种默认方案
class FeedingPlanEditorScreen extends ConsumerStatefulWidget {
  /// 目标鸟（null = 品种默认方案编辑）
  final int? birdId;

  /// 阶段（必填）
  final String stage;

  /// 物种 ID（品种默认方案时必填；鸟方案时可空，从 birdId 推断）
  final int? speciesId;

  /// 已存在的方案（编辑模式）；null = 新建
  final FeedingPlan? plan;

  const FeedingPlanEditorScreen({
    super.key,
    this.birdId,
    required this.stage,
    this.speciesId,
    this.plan,
  });

  @override
  ConsumerState<FeedingPlanEditorScreen> createState() =>
      _FeedingPlanEditorScreenState();
}

class _FeedingPlanEditorScreenState
    extends ConsumerState<FeedingPlanEditorScreen> {
  AppDatabase get _db => pluginRegistry.db!;

  BirdWithDetails? _bird;
  List<Specy> _species = [];
  List<Blend> _allBlends = [];
  FeedingPlanWithDetails? _details;
  bool _loading = true;
  bool _saving = false;

  bool get _isBirdPlan => widget.birdId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _species = await _db.getAllSpecies();
    _allBlends = await _db.getAllBlends();
    if (_isBirdPlan) {
      _bird = await _db.getWithDetails(widget.birdId!);
    }
    if (widget.plan != null) {
      _details = await _db.getFeedingPlanWithDetails(widget.plan!.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_details == null) return;
    _details = await _db.getFeedingPlanWithDetails(_details!.plan.id);
    if (mounted) setState(() {});
  }

  Future<void> _ensurePlanCreated() async {
    if (_details != null) return;
    // 创建方案
    // 品种默认方案(birdId=null)时必须传 speciesId，否则查找时永远匹配不上
    final speciesId =
        _isBirdPlan ? _bird?.bird.speciesId : widget.speciesId;
    final plan = await _db.addFeedingPlan(
      birdId: widget.birdId,
      speciesId: speciesId,
      stage: widget.stage,
    );
    _details = await _db.getFeedingPlanWithDetails(plan.id);
    setState(() {});
  }

  String get _targetLabel {
    if (_isBirdPlan && _bird != null) {
      return _bird!.bird.name;
    }
    return '品种默认';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('喂养方案 · $_targetLabel'),
        actions: [
          if (_details != null)
            IconButton(
              onPressed: _saving ? null : () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          if (_details == null)
            _buildCreateCard(theme)
          else ...[
            ..._details!.meals.map((m) => _buildMealCard(theme, m)),
            const SizedBox(height: 8),
            _buildAddMealButton(theme),
            const SizedBox(height: 16),
            _buildNutritionCard(theme),
            const SizedBox(height: 12),
            _buildActions(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            RecipeStage.isBreedingStage(widget.stage)
                ? const Icon(Icons.favorite)
                : const FeatherIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_targetLabel · ${widget.stage}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(_isBirdPlan ? '自定义方案（覆盖品种默认）' : '品种默认方案',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text('为「$_targetLabel」创建${widget.stage}喂养方案',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await _ensurePlanCreated();
                // 一键应用模板
                await _applyTemplate();
              },
              icon: const Icon(Icons.add),
              label: const Text('创建并应用餐次模板'),
            ),
            TextButton(
              onPressed: () async {
                await _ensurePlanCreated();
              },
              child: const Text('创建空方案'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTemplate() async {
    if (_details == null) return;
    final template = ref.read(mealTemplateProvider);
    int sortOrder = 0;
    for (final preset in template.presets) {
      await _db.addFeedingPlanMeal(
        planId: _details!.plan.id,
        mealName: preset.name,
        timeOfDay: preset.timeOfDay,
        grams: 5, // 默认每餐 5g，用户可调整
        sortOrder: sortOrder++,
      );
    }
    _refresh();
  }

  Widget _buildMealCard(ThemeData theme, FeedingPlanMealWithRecipes meal) {
    final totalPct =
        meal.recipes.fold<double>(0, (s, r) => s + r.item.percent);
    final isValidPct = (totalPct - 100).abs() < 0.5 || meal.recipes.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          meal.meal.mealName +
              (meal.meal.timeOfDay != null ? ' (${meal.meal.timeOfDay})' : ''),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${meal.meal.grams.toStringAsFixed(1)}g · ${meal.recipes.length} 个配方'
          '${!isValidPct ? ' · ⚠️配比${totalPct.toStringAsFixed(0)}%' : ''}',
          style: theme.textTheme.labelSmall,
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // 克数编辑
          Row(
            children: [
              Text('克数', style: theme.textTheme.labelMedium),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: TextEditingController(
                      text: meal.meal.grams.toStringAsFixed(1)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: 'g',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onSubmitted: (v) async {
                    final g = double.tryParse(v) ?? 0;
                    await _db.updateFeedingPlanMeal(meal.meal.id, grams: g);
                    _refresh();
                  },
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: theme.colorScheme.error,
                onPressed: () async {
                  await _db.deleteFeedingPlanMeal(meal.meal.id);
                  _refresh();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 配方列表
          ...meal.recipes.map((r) => _buildRecipeRow(theme, r)),
          // 添加配方
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addRecipe(meal.meal.id),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加配方'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeRow(ThemeData theme, MealRecipeWithBlend recipe) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16),
      title: Text(recipe.blend.name, style: const TextStyle(fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(
                  text: recipe.item.percent.toStringAsFixed(0)),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                suffixText: '%',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onSubmitted: (v) async {
                final pct = double.tryParse(v) ?? 0;
                await _db.updateFeedingPlanMealRecipe(recipe.item.id,
                    percent: pct);
                _refresh();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: theme.colorScheme.error,
            onPressed: () async {
              await _db.deleteFeedingPlanMealRecipe(recipe.item.id);
              _refresh();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addRecipe(int mealId) async {
    if (_allBlends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('暂无可用配方，请先创建配方'),
          action: SnackBarAction(
            label: '去创建',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BlendLibraryScreen()),
            ),
          ),
        ),
      );
      return;
    }
    final blend = await showDialog<Blend>(
      context: context,
      builder: (_) => _BlendPickerDialog(blends: _allBlends),
    );
    if (blend == null) return;

    await _db.addFeedingPlanMealRecipe(
      planMealId: mealId,
      blendId: blend.id,
      percent: 100, // 默认100%，多配方时用户调整
    );
    _refresh();
  }

  Widget _buildAddMealButton(ThemeData theme) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showMealDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('添加餐次'),
      ),
    );
  }

  Future<void> _showMealDialog(FeedingPlanMeal? existing) async {
    final nameCtrl =
        TextEditingController(text: existing?.mealName ?? '');
    final timeCtrl = TextEditingController(text: existing?.timeOfDay ?? '');
    final gramsCtrl = TextEditingController(
        text: existing?.grams.toStringAsFixed(1) ?? '5.0');

    final result = await showDialog<({String name, String? time, double grams})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '添加餐次' : '编辑餐次'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '餐次名称 *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(
                labelText: '时间（选填，如 07:00）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gramsCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '克数 (g)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final t = timeCtrl.text.trim();
              final g = double.tryParse(gramsCtrl.text.trim()) ?? 0;
              Navigator.pop(ctx, (name: name, time: t.isEmpty ? null : t, grams: g));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (existing == null) {
      await _db.addFeedingPlanMeal(
        planId: _details!.plan.id,
        mealName: result.name,
        timeOfDay: result.time,
        grams: result.grams,
        sortOrder: _details!.meals.length,
      );
    } else {
      await _db.updateFeedingPlanMeal(existing.id,
          mealName: result.name, timeOfDay: result.time, grams: result.grams);
    }
    _refresh();
  }

  Widget _buildNutritionCard(ThemeData theme) {
    if (_details == null || _details!.meals.isEmpty) {
      return const SizedBox.shrink();
    }
    final summary = _details!.nutrition;
    return NutritionSummaryCard(summary: summary);
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        if (_isBirdPlan)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _deletePlan,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('删除方案', style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }

  Future<void> _deletePlan() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除方案'),
        content: const Text('删除后该鸟将回退到品种默认方案。确定？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && _details != null) {
      await _db.deleteFeedingPlan(_details!.plan.id);
      if (mounted) Navigator.pop(context, true);
    }
  }
}

/// 配方选择器对话框
class _BlendPickerDialog extends StatelessWidget {
  final List<Blend> blends;
  const _BlendPickerDialog({required this.blends});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择配方'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: blends.length,
          itemBuilder: (_, i) {
            final b = blends[i];
            return ListTile(
              title: Text(b.name),
              subtitle: Text(b.description ?? '', style: const TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, b),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
      ],
    );
  }
}
