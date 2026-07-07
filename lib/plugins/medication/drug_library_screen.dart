import 'package:flutter/material.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../theme/app_tokens.dart';
import '../../theme/category_colors.dart';
import '../../widgets/list/app_list_card.dart';
import '../../widgets/list/app_list_scaffold.dart';
import '../../widgets/list/empty_state.dart';
import 'drug_library_repository.dart';
import 'dose_rules_screen.dart';

/// Drug library management screen — list, add, edit, search drugs with formulations.
class DrugLibraryScreen extends StatefulWidget {
  const DrugLibraryScreen({super.key});

  @override
  State<DrugLibraryScreen> createState() => _DrugLibraryScreenState();
}

class _DrugLibraryScreenState extends State<DrugLibraryScreen> {
  List<DrugLibraryData> _drugs = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final drugs = _query.isEmpty
        ? await _db.getAllDrugs()
        : await _db.searchDrugs(_query);
    if (mounted)
      setState(() {
        _drugs = drugs;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppListScaffold<DrugLibraryData>(
      title: '药品库',
      appBarActions: [
        // Import/Export menu
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'export') _exportDrugs();
            if (v == 'import') _importDrugs();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'export',
                child: ListTile(
                    leading: Icon(Icons.upload),
                    title: Text('导出 Excel'),
                    dense: true)),
            PopupMenuItem(
                value: 'import',
                child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('导入 Excel'),
                    dense: true)),
          ],
        ),
      ],
      searchField: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: '搜索药品名/成分/商品名',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: context.r.bLg,
          ),
        ),
        onChanged: (v) {
          _query = v.trim();
          _load();
        },
      ),
      loading: _loading,
      items: _drugs,
      onRefresh: _load,
      emptyState: EmptyState(
        icon: const Icon(Icons.local_pharmacy_outlined, size: 56),
        message: _query.isNotEmpty ? '未找到匹配药品' : '药品库为空',
        hint: _query.isNotEmpty ? '尝试其他关键词搜索' : '点击右下角 + 添加药品',
      ),
      fab: FloatingActionButton(
        onPressed: () => _showEditDialog(null),
        child: const Icon(Icons.add),
      ),
      itemBuilder: (_, d) => _DrugCard(
        drug: d,
        onTap: () => _showEditDialog(d),
        onDelete: () => _confirmDelete(d),
      ),
    );
  }

  Future<void> _exportDrugs() async {
    // Will be implemented in Phase 5
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能将在 Phase 5 实现')),
    );
  }

  Future<void> _importDrugs() async {
    // Will be implemented in Phase 5
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能将在 Phase 5 实现')),
    );
  }

  void _showEditDialog(DrugLibraryData? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _DrugEditSheet(
        existing: existing,
        onSaved: _load,
      ),
    );
  }

  void _confirmDelete(DrugLibraryData drug) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除药品「${drug.drugName}」？\n将同时删除关联的规格和剂量规则。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.removeDrug(drug.id);
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Drug Card
// ═══════════════════════════════════════════════════════════════════════════════

class _DrugCard extends StatelessWidget {
  final DrugLibraryData drug;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DrugCard(
      {required this.drug, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sp = context.sp;
    final a = context.a;
    final (catFg, catBg) = CategoryColors.forCategory(scheme, drug.drugCategory);

    // 副标题：商品名 / 成分 / 剂型行
    final subtitleChildren = <Widget>[
      if (drug.brandName != null && drug.brandName!.isNotEmpty)
        Text(drug.brandName!, style: theme.textTheme.bodySmall),
      if (drug.activeIngredient != null && drug.activeIngredient!.isNotEmpty)
        Text('成分: ${drug.activeIngredient}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant.withAlpha(a.medium))),
      SizedBox(height: sp.xs),
      Row(children: [
        Icon(_formulationIcon(drug.formulationType),
            size: 14, color: scheme.onSurfaceVariant.withAlpha(a.low)),
        SizedBox(width: sp.xs),
        Text(drug.formulationType,
            style: theme.textTheme.labelSmall),
        if (drug.openedExpiryDays != null) ...[
          SizedBox(width: sp.sm + sp.xs),
          Icon(Icons.timer_outlined,
              size: 14, color: scheme.onSurfaceVariant.withAlpha(a.low)),
          SizedBox(width: sp.xs),
          Text('开封${drug.openedExpiryDays}天', style: theme.textTheme.labelSmall),
        ],
      ]),
    ];

    return AppListCard.icon(
      icon: Icons.medication,
      iconTint: catFg,
      iconBg: catBg,
      title: Text(drug.drugName,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleChildren,
      ),
      badge: _CategoryBadge(label: drug.drugCategory, fg: catFg, bg: catBg),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.rule, size: 18),
            color: scheme.onSurfaceVariant.withAlpha(a.low),
            tooltip: '剂量规则',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoseRulesScreen(
                    drugId: drug.id, drugName: drug.drugName),
              ),
            ),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: scheme.error.withAlpha(a.low),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  static IconData _formulationIcon(String type) {
    switch (type) {
      case '滴剂':
        return Icons.water_drop;
      case '片剂':
        return Icons.medication;
      case '胶囊':
        return Icons.medication_liquid;
      case '粉剂':
        return Icons.blender;
      case '注射液':
        return Icons.vaccines;
      default:
        return Icons.medication;
    }
  }
}

/// 药品分类徽章 —— 取自 [CategoryColors] 返回的 (前景, 背景) 一对色。
class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const _CategoryBadge({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.sm + 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: r.bXs,
        color: bg,
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Drug Edit Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _DrugEditSheet extends StatefulWidget {
  final DrugLibraryData? existing;
  final VoidCallback onSaved;

  const _DrugEditSheet({this.existing, required this.onSaved});

  @override
  State<_DrugEditSheet> createState() => _DrugEditSheetState();
}

class _DrugEditSheetState extends State<_DrugEditSheet> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _ingredientCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = '其他';
  String _formType = '滴剂';

  // Formulation editing
  List<_FormEntry> _formulations = [];
  bool _loadingFormulations = false;

  // Static category/form options
  static const _categories = ['抗生素', '驱虫', '维生素', '益生菌', '抗真菌', '其他'];
  static const _formTypes = ['滴剂', '片剂', '胶囊', '粉剂', '注射液'];
  static const _units = ['mg/mL', 'mg/片', 'mg/包', 'IU/mL', '%', 'μg/mL'];

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl.text = e?.drugName ?? '';
    _brandCtrl.text = e?.brandName ?? '';
    _ingredientCtrl.text = e?.activeIngredient ?? '';
    _storageCtrl.text = e?.storageInstructions ?? '';
    _expiryCtrl.text = e?.openedExpiryDays?.toString() ?? '';
    _notesCtrl.text = e?.notes ?? '';
    _category = e?.drugCategory ?? '其他';
    _formType = e?.formulationType ?? '滴剂';

    if (e != null) {
      _loadFormulations(e.id);
    } else {
      _formulations = [_FormEntry()];
    }
  }

  Future<void> _loadFormulations(int drugId) async {
    setState(() => _loadingFormulations = true);
    final forms = await _db.getFormulationsByDrug(drugId);
    _formulations = forms
        .map((f) => _FormEntry(
              concentration: f.concentration,
              unit: f.unit,
              isDefault: f.isDefault,
              label: f.label ?? '',
            ))
        .toList();
    if (_formulations.isEmpty) _formulations = [_FormEntry()];
    if (mounted) setState(() => _loadingFormulations = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _ingredientCtrl.dispose();
    _storageCtrl.dispose();
    _expiryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.grey.shade300))),
              const SizedBox(height: 16),
              Text(isEdit ? '编辑药品' : '添加药品',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Drug name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: '药品名称 *',
                    hintText: '恩诺沙星',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Brand + active ingredient
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(
                        labelText: '商品名',
                        hintText: 'Baytril',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ingredientCtrl,
                    decoration: const InputDecoration(
                        labelText: '有效成分',
                        hintText: 'Enrofloxacin',
                        border: OutlineInputBorder()),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Category + Formulation type
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                        labelText: '药物类别', border: OutlineInputBorder()),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _formType,
                    decoration: const InputDecoration(
                        labelText: '剂型', border: OutlineInputBorder()),
                    items: _formTypes
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child:
                                Text(t, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _formType = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Storage + expiry
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _storageCtrl,
                    decoration: const InputDecoration(
                        labelText: '保存方式',
                        hintText: '冷藏',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: '开封有效期(天)',
                        hintText: '30',
                        border: OutlineInputBorder()),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Formulations section
              Row(children: [
                Text('浓度 / 规格',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加规格', style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      setState(() => _formulations.add(_FormEntry())),
                ),
              ]),
              if (_loadingFormulations)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator()))
              else ...[
                const SizedBox(height: 8),
                ..._formulations
                    .asMap()
                    .entries
                    .map((e) => _buildFormulationRow(e.key, e.value)),
              ],
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    labelText: '备注 (选填)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Save
              FilledButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text('保存'),
                onPressed: _nameCtrl.text.trim().isEmpty ? null : _doSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulationRow(int index, _FormEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        // Concentration
        SizedBox(
          width: 80,
          child: TextField(
            controller: entry.concentrationCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: '浓度',
                hintText: '25',
                border: OutlineInputBorder(),
                isDense: true),
          ),
        ),
        const SizedBox(width: 8),
        // Unit
        SizedBox(
          width: 80,
          child: DropdownButtonFormField<String>(
            value: entry.unit,
            decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder()),
            items: _units
                .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u, style: const TextStyle(fontSize: 11))))
                .toList(),
            onChanged: (v) =>
                setState(() => _formulations[index] = entry.copyWith(unit: v!)),
          ),
        ),
        const SizedBox(width: 8),
        // Label
        Expanded(
          child: TextField(
            controller: entry.labelCtrl,
            decoration: const InputDecoration(
                labelText: '标签',
                hintText: '25mg装',
                border: OutlineInputBorder(),
                isDense: true),
          ),
        ),
        const SizedBox(width: 4),
        // Default toggle
        Column(children: [
          const Text('默认', style: TextStyle(fontSize: 9)),
          Checkbox(
            value: entry.isDefault,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  for (int i = 0; i < _formulations.length; i++) {
                    _formulations[i] =
                        _formulations[i].copyWith(isDefault: i == index);
                  }
                } else {
                  _formulations[index] = entry.copyWith(isDefault: false);
                }
              });
            },
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
        // Delete
        if (_formulations.length > 1)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                size: 18, color: Colors.red),
            onPressed: () => setState(() => _formulations.removeAt(index)),
            visualDensity: VisualDensity.compact,
          ),
      ]),
    );
  }

  Future<void> _doSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final db = _db;
    final isEdit = widget.existing != null;

    if (isEdit) {
      await db.updateDrug(
        widget.existing!.id,
        drugName: name,
        brandName:
            _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        activeIngredient: _ingredientCtrl.text.trim().isEmpty
            ? null
            : _ingredientCtrl.text.trim(),
        drugCategory: _category,
        formulationType: _formType,
        storageInstructions:
            _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
        openedExpiryDays: int.tryParse(_expiryCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // Replace formulations
      final validForms = _formulations
          .where((f) => f.isValid)
          .map((f) => FormulationInput(
                concentration: double.parse(f.concentrationCtrl.text),
                unit: f.unit,
                isDefault: f.isDefault,
                label: f.labelCtrl.text.trim().isEmpty
                    ? null
                    : f.labelCtrl.text.trim(),
              ))
          .toList();
      if (validForms.isNotEmpty) {
        await db.replaceFormulations(widget.existing!.id, validForms);
      }
    } else {
      final drug = await db.addDrug(
        drugName: name,
        brandName:
            _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        activeIngredient: _ingredientCtrl.text.trim().isEmpty
            ? null
            : _ingredientCtrl.text.trim(),
        drugCategory: _category,
        formulationType: _formType,
        storageInstructions:
            _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
        openedExpiryDays: int.tryParse(_expiryCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // Add formulations
      for (final f in _formulations.where((f) => f.isValid)) {
        await db.addFormulation(
          drugId: drug.id,
          concentration: double.parse(f.concentrationCtrl.text),
          unit: f.unit,
          isDefault: f.isDefault,
          label:
              f.labelCtrl.text.trim().isEmpty ? null : f.labelCtrl.text.trim(),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }
}

class _FormEntry {
  final TextEditingController concentrationCtrl;
  final TextEditingController labelCtrl;
  String unit;
  bool isDefault;

  _FormEntry({
    double concentration = 25,
    this.unit = 'mg/mL',
    this.isDefault = false,
    String label = '',
  })  : concentrationCtrl = TextEditingController(
            text: concentration > 0 ? concentration.toString() : ''),
        labelCtrl = TextEditingController(text: label);

  bool get isValid {
    final c = double.tryParse(concentrationCtrl.text);
    return c != null && c > 0;
  }

  _FormEntry copyWith({String? unit, bool? isDefault}) {
    return _FormEntry(
      concentration: double.tryParse(concentrationCtrl.text) ?? 0,
      unit: unit ?? this.unit,
      isDefault: isDefault ?? this.isDefault,
      label: labelCtrl.text,
    );
  }

  void dispose() {
    concentrationCtrl.dispose();
    labelCtrl.dispose();
  }
}
