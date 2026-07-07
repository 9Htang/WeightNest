import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../../../repositories/species_repository.dart';
import '../nutrition_math.dart';
import '../nutrition_repository.dart';
import '../nutrition_stage.dart';
import '../widgets/nutrition_summary_card.dart';
import 'food_picker_dialog.dart';

/// 配方编辑器 —— 管理%比例混合粮配方。
///
/// 配方 = 食材按%配比，合计应为 100%。
/// 可绑定物种+阶段（用于喂养方案编辑器推荐）。
class BlendEditorScreen extends StatefulWidget {
  final Blend? blend;
  final int? prefillSpeciesId;
  final String? prefillStage;

  const BlendEditorScreen({
    super.key,
    this.blend,
    this.prefillSpeciesId,
    this.prefillStage,
  });

  @override
  State<BlendEditorScreen> createState() => _BlendEditorScreenState();
}

class _BlendEditorScreenState extends State<BlendEditorScreen> {
  AppDatabase get _db => pluginRegistry.db!;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late bool _isActive;

  BlendWithDetails? _details;
  List<Specy> _species = [];
  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.blend != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.blend?.name ?? '');
    _descCtrl = TextEditingController(text: widget.blend?.description ?? '');
    _isActive = widget.blend?.isActive ?? true;
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _species = await _db.getAllSpecies();
    if (_isEdit) {
      _details = await _db.getBlendWithDetails(widget.blend!.id);
      // 如果有 prefill 绑定且配方无绑定，自动添加
      if (_details!.bindings.isEmpty &&
          (widget.prefillSpeciesId != null || widget.prefillStage != null)) {
        await _db.bindBlend(
          blendId: widget.blend!.id,
          speciesId: widget.prefillSpeciesId,
          stage: widget.prefillStage ?? RecipeStage.adult,
        );
        _details = await _db.getBlendWithDetails(widget.blend!.id);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (!_isEdit) return;
    _details = await _db.getBlendWithDetails(widget.blend!.id);
    if (mounted) setState(() {});
  }

  Future<void> _saveBasic() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入配方名称')));
      return;
    }
    setState(() => _saving = true);

    if (_isEdit) {
      await _db.updateBlend(widget.blend!.id,
          name: name, description: _descCtrl.text.trim(), isActive: _isActive);
      if (mounted) Navigator.pop(context, true);
    } else {
      final blend = await _db.addBlend(
          name: name,
          description: _descCtrl.text.trim(),
          isActive: _isActive);
      // 自动绑定（从鸟详情页进入时）
      if (widget.prefillSpeciesId != null || widget.prefillStage != null) {
        await _db.bindBlend(
          blendId: blend.id,
          speciesId: widget.prefillSpeciesId,
          stage: widget.prefillStage ?? RecipeStage.adult,
        );
      }
      if (mounted) {
        // 进入编辑模式
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BlendEditorScreen(blend: blend),
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑配方' : '新建配方'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveBasic,
            icon: _saving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicSection(theme),
          if (_isEdit) ...[
            const SizedBox(height: 12),
            _buildItemsSection(theme),
            const SizedBox(height: 12),
            _buildNutritionSection(theme),
            const SizedBox(height: 12),
            _buildBindingSection(theme),
          ] else
            _buildCreateHint(theme),
        ],
      ),
    );
  }

  Widget _buildBasicSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基本信息',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '配方名称 *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '描述（选填）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('启用'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateHint(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 40, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text('填写名称后点击右上角 ✓ 保存，即可编辑食材配比',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(ThemeData theme) {
    final items = _details?.items ?? [];
    final total = items.fold<double>(0, (s, i) => s + i.item.percent);
    final isValid = (total - 100).abs() < 0.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('食材配比',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('合计: ${total.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isValid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 4),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('⚠️ 配比合计应为 100%',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.red)),
              ),
            ...items.map((item) => _buildItemRow(theme, item)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加食材'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, BlendItemWithFood item) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(item.food.name),
      subtitle: Text(
        '${item.food.category} · 蛋白${item.food.crudeProtein.toStringAsFixed(1)}%',
        style: theme.textTheme.labelSmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: TextField(
              controller:
                  TextEditingController(text: item.item.percent.toStringAsFixed(1)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                suffixText: '%',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onSubmitted: (v) async {
                final pct = double.tryParse(v) ?? 0;
                await _db.updateBlendItem(item.item.id, percent: pct);
                _refresh();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: theme.colorScheme.error,
            onPressed: () async {
              await _db.deleteBlendItem(item.item.id);
              _refresh();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final food = await showDialog<Food>(
      context: context,
      builder: (_) => const FoodPickerDialog(),
    );
    if (food == null) return;

    // 计算剩余可分配比例
    final items = _details?.items ?? [];
    final used = items.fold<double>(0, (s, i) => s + i.item.percent);
    final remaining = (100 - used).clamp(0.0, 100.0);
    final defaultPercent = items.isEmpty ? 100.0 : remaining;

    final percent = await _showPercentDialog(defaultPercent);
    if (percent == null) return;

    await _db.addBlendItem(
      blendId: widget.blend!.id,
      foodId: food.id,
      percent: percent,
    );
    _refresh();
  }

  Future<double?> _showPercentDialog(double initial) {
    final ctrl = TextEditingController(text: initial.toStringAsFixed(1));
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('配比'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '占比 (%)',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(ctx, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(ThemeData theme) {
    final items = _details?.items ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    final summary = computeBlendNutrition(items);
    return NutritionSummaryCard(summary: summary);
  }

  Widget _buildBindingSection(ThemeData theme) {
    final bindings = _details?.bindings ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('适用物种与阶段',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...bindings.map((b) => Chip(
                      label: Text(_bindingLabel(b)),
                      onDeleted: () async {
                        await _db.unbindBlend(
                          blendId: widget.blend!.id,
                          speciesId: b.speciesId,
                          stage: b.stage,
                        );
                        _refresh();
                      },
                    )),
                ActionChip(
                  label: const Text('添加绑定'),
                  avatar: const Icon(Icons.add, size: 18),
                  onPressed: _addBinding,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _bindingLabel(BlendBinding b) {
    final speciesName = b.speciesId == null
        ? '通用'
        : _species.where((s) => s.id == b.speciesId).firstOrNull?.name ?? '物种${b.speciesId}';
    return '$speciesName / ${b.stage}';
  }

  Future<void> _addBinding() async {
    final result = await showDialog<({int? speciesId, String stage})>(
      context: context,
      builder: (ctx) => _BindingDialog(species: _species),
    );
    if (result == null) return;
    await _db.bindBlend(
      blendId: widget.blend!.id,
      speciesId: result.speciesId,
      stage: result.stage,
    );
    _refresh();
  }
}

/// 绑定选择对话框
class _BindingDialog extends StatefulWidget {
  final List<Specy> species;
  const _BindingDialog({required this.species});

  @override
  State<_BindingDialog> createState() => _BindingDialogState();
}

class _BindingDialogState extends State<_BindingDialog> {
  int? _speciesId; // null = 通用
  String _stage = RecipeStage.adult;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加绑定'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int?>(
            value: _speciesId,
            decoration: const InputDecoration(
              labelText: '物种',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('通用（适用所有物种）')),
              ...widget.species
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
            ],
            onChanged: (v) => setState(() => _speciesId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _stage,
            decoration: const InputDecoration(
              labelText: '阶段',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: RecipeStage.all
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _stage = v ?? RecipeStage.adult),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (speciesId: _speciesId, stage: _stage)),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
