import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../nutrition_repository.dart';
import '../nutrition_stage.dart';

/// 食材新增/编辑页 —— 分组表单（基础信息 / L1 核心营养 / L2 繁殖营养 / 业务规则）。
///
/// 编辑模式下 [food] 非 null；新建模式下为 null。
class FoodEditorScreen extends StatefulWidget {
  final Food? food;

  const FoodEditorScreen({super.key, this.food});

  @override
  State<FoodEditorScreen> createState() => _FoodEditorScreenState();
}

class _FoodEditorScreenState extends State<FoodEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  AppDatabase get _db => pluginRegistry.db!;

  // 基础信息控制器
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _maxRatioCtrl;
  late final TextEditingController _minRatioCtrl;
  late String _category;
  late bool _isHulled;
  late String _basis;
  late String? _confidence;
  late Set<String> _selectedStages;

  // L1 核心营养控制器
  late final TextEditingController _moistureCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _fiberCtrl;
  late final TextEditingController _ashCtrl;
  late final TextEditingController _energyCtrl;

  // L2 字段控制器（按分组）
  late final Map<String, TextEditingController> _l2Ctrls;
  late final Map<String, TextEditingController> _l2Ctrls2;

  // 业务规则开关
  late bool? _needsSoaking;
  late bool? _canSprout;

  bool _saving = false;
  bool get _isEdit => widget.food != null;

  /// L2 营养字段定义（label → 表字段名），用于批量生成控制器
  static const _l2Minerals = {
    '钙': 'calcium',
    '磷': 'phosphorus',
    '镁': 'magnesium',
    '钾': 'potassium',
    '钠': 'sodium',
  };
  static const _l2FattyAcids = {
    'Omega-3': 'omega3',
    'Omega-6': 'omega6',
    '亚油酸': 'linoleicAcid',
    'α-亚麻酸': 'ala',
  };
  static const _l2AminoAcids = {
    '赖氨酸': 'lysine',
    '蛋氨酸': 'methionine',
    '胱氨酸': 'cystine',
    '苏氨酸': 'threonine',
    '色氨酸': 'tryptophan',
    '精氨酸': 'arginine',
    '缬氨酸': 'valine',
    '异亮氨酸': 'isoleucine',
    '亮氨酸': 'leucine',
  };
  static const _l2TraceElements = {
    '锌': 'zinc',
    '铜': 'copper',
    '铁': 'iron',
    '锰': 'manganese',
    '硒': 'selenium',
    '碘': 'iodine',
  };
  static const _l2Vitamins = {
    'VA': 'vitA',
    'VD3': 'vitD3',
    'VE': 'vitE',
    'VK': 'vitK',
    'B1': 'vitB1',
    'B2': 'vitB2',
    'B6': 'vitB6',
    'B12': 'vitB12',
    '烟酸': 'niacin',
    '泛酸': 'pantothenicAcid',
    '生物素': 'biotin',
    '叶酸': 'folicAcid',
  };

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _sourceCtrl = TextEditingController(text: f?.dataSource ?? '');
    _notesCtrl = TextEditingController(text: f?.notes ?? '');
    _maxRatioCtrl =
        TextEditingController(text: f != null ? f.maxRatioPercent.toString() : '100');
    _minRatioCtrl = TextEditingController(
        text: f?.minRatioPercent?.toString() ?? '');

    _category = f?.category ?? '其他';
    _isHulled = f?.isHulled ?? false;
    _basis = f?.basis ?? 'As Fed';
    _confidence = f?.dataConfidence;
    _selectedStages =
        NutritionRepository.parseRecommendedStages(f?.recommendedStages).toSet();

    _moistureCtrl =
        TextEditingController(text: _fmt(f?.moisture));
    _proteinCtrl =
        TextEditingController(text: _fmt(f?.crudeProtein));
    _fatCtrl = TextEditingController(text: _fmt(f?.crudeFat));
    _fiberCtrl = TextEditingController(text: _fmt(f?.crudeFiber));
    _ashCtrl = TextEditingController(text: _fmt(f?.crudeAsh));
    _energyCtrl =
        TextEditingController(text: _fmt(f?.metabolizableEnergy));

    _needsSoaking = f?.needsSoaking;
    _canSprout = f?.canSprout;

    // 初始化 L2 控制器
    _l2Ctrls = {};
    _l2Ctrls2 = {};
    final allL2 = {
      ..._l2Minerals,
      ..._l2FattyAcids,
      ..._l2AminoAcids,
      ..._l2TraceElements,
      ..._l2Vitamins,
    };
    for (final entry in allL2.entries) {
      final ctrl = TextEditingController(text: _fmt(_readField(f, entry.value)));
      _l2Ctrls[entry.key] = ctrl;
      _l2Ctrls2[entry.value] = ctrl; // 字段名 → 控制器，用于取值
    }
  }

  /// 从 Food 对象读取字段值（通过字段名映射）。
  double? _readField(Food? f, String fieldName) {
    if (f == null) return null;
    switch (fieldName) {
      case 'calcium':
        return f.calcium;
      case 'phosphorus':
        return f.phosphorus;
      case 'magnesium':
        return f.magnesium;
      case 'potassium':
        return f.potassium;
      case 'sodium':
        return f.sodium;
      case 'omega3':
        return f.omega3;
      case 'omega6':
        return f.omega6;
      case 'linoleicAcid':
        return f.linoleicAcid;
      case 'ala':
        return f.ala;
      case 'lysine':
        return f.lysine;
      case 'methionine':
        return f.methionine;
      case 'cystine':
        return f.cystine;
      case 'threonine':
        return f.threonine;
      case 'tryptophan':
        return f.tryptophan;
      case 'arginine':
        return f.arginine;
      case 'valine':
        return f.valine;
      case 'isoleucine':
        return f.isoleucine;
      case 'leucine':
        return f.leucine;
      case 'zinc':
        return f.zinc;
      case 'copper':
        return f.copper;
      case 'iron':
        return f.iron;
      case 'manganese':
        return f.manganese;
      case 'selenium':
        return f.selenium;
      case 'iodine':
        return f.iodine;
      case 'vitA':
        return f.vitA;
      case 'vitD3':
        return f.vitD3;
      case 'vitE':
        return f.vitE;
      case 'vitK':
        return f.vitK;
      case 'vitB1':
        return f.vitB1;
      case 'vitB2':
        return f.vitB2;
      case 'vitB6':
        return f.vitB6;
      case 'vitB12':
        return f.vitB12;
      case 'niacin':
        return f.niacin;
      case 'pantothenicAcid':
        return f.pantothenicAcid;
      case 'biotin':
        return f.biotin;
      case 'folicAcid':
        return f.folicAcid;
      default:
        return null;
    }
  }

  /// 格式化数字显示（去掉 .0 后缀，null 返回空串）
  String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  /// 解析数值输入，空串返回 null
  double? _parseVal(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// 必填数值（空串或非法返回默认 0）
  double _parseRequired(TextEditingController c, [double def = 0]) {
    final v = _parseVal(c);
    return v ?? def;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _sourceCtrl, _notesCtrl, _maxRatioCtrl, _minRatioCtrl,
      _moistureCtrl, _proteinCtrl, _fatCtrl, _fiberCtrl, _ashCtrl, _energyCtrl,
      ..._l2Ctrls.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _saving = false);
      return;
    }

    try {
      if (_isEdit) {
        await _db.updateFood(
          widget.food!.id,
          name: name,
          category: _category,
          isHulled: _isHulled,
          basis: _basis,
          dataSource: _sourceCtrl.text.trim().isEmpty
              ? '未知'
              : _sourceCtrl.text.trim(),
          dataConfidence: _confidence,
          moisture: _parseRequired(_moistureCtrl),
          crudeProtein: _parseRequired(_proteinCtrl),
          crudeFat: _parseRequired(_fatCtrl),
          crudeFiber: _parseRequired(_fiberCtrl),
          crudeAsh: _parseVal(_ashCtrl),
          metabolizableEnergy: _parseVal(_energyCtrl),
          calcium: _parseVal(_l2Ctrls2['calcium']!),
          phosphorus: _parseVal(_l2Ctrls2['phosphorus']!),
          magnesium: _parseVal(_l2Ctrls2['magnesium']!),
          potassium: _parseVal(_l2Ctrls2['potassium']!),
          sodium: _parseVal(_l2Ctrls2['sodium']!),
          omega3: _parseVal(_l2Ctrls2['omega3']!),
          omega6: _parseVal(_l2Ctrls2['omega6']!),
          linoleicAcid: _parseVal(_l2Ctrls2['linoleicAcid']!),
          ala: _parseVal(_l2Ctrls2['ala']!),
          lysine: _parseVal(_l2Ctrls2['lysine']!),
          methionine: _parseVal(_l2Ctrls2['methionine']!),
          cystine: _parseVal(_l2Ctrls2['cystine']!),
          threonine: _parseVal(_l2Ctrls2['threonine']!),
          tryptophan: _parseVal(_l2Ctrls2['tryptophan']!),
          arginine: _parseVal(_l2Ctrls2['arginine']!),
          valine: _parseVal(_l2Ctrls2['valine']!),
          isoleucine: _parseVal(_l2Ctrls2['isoleucine']!),
          leucine: _parseVal(_l2Ctrls2['leucine']!),
          zinc: _parseVal(_l2Ctrls2['zinc']!),
          copper: _parseVal(_l2Ctrls2['copper']!),
          iron: _parseVal(_l2Ctrls2['iron']!),
          manganese: _parseVal(_l2Ctrls2['manganese']!),
          selenium: _parseVal(_l2Ctrls2['selenium']!),
          iodine: _parseVal(_l2Ctrls2['iodine']!),
          vitA: _parseVal(_l2Ctrls2['vitA']!),
          vitD3: _parseVal(_l2Ctrls2['vitD3']!),
          vitE: _parseVal(_l2Ctrls2['vitE']!),
          vitK: _parseVal(_l2Ctrls2['vitK']!),
          vitB1: _parseVal(_l2Ctrls2['vitB1']!),
          vitB2: _parseVal(_l2Ctrls2['vitB2']!),
          vitB6: _parseVal(_l2Ctrls2['vitB6']!),
          vitB12: _parseVal(_l2Ctrls2['vitB12']!),
          niacin: _parseVal(_l2Ctrls2['niacin']!),
          pantothenicAcid: _parseVal(_l2Ctrls2['pantothenicAcid']!),
          biotin: _parseVal(_l2Ctrls2['biotin']!),
          folicAcid: _parseVal(_l2Ctrls2['folicAcid']!),
          recommendedStages: _selectedStages.toList(),
          maxRatioPercent: _parseRequired(_maxRatioCtrl, 100),
          minRatioPercent: _parseVal(_minRatioCtrl),
          needsSoaking: _needsSoaking,
          canSprout: _canSprout,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      } else {
        await _db.addFood(
          name: name,
          category: _category,
          isHulled: _isHulled,
          basis: _basis,
          dataSource: _sourceCtrl.text.trim().isEmpty
              ? '未知'
              : _sourceCtrl.text.trim(),
          dataConfidence: _confidence,
          moisture: _parseRequired(_moistureCtrl),
          crudeProtein: _parseRequired(_proteinCtrl),
          crudeFat: _parseRequired(_fatCtrl),
          crudeFiber: _parseRequired(_fiberCtrl),
          crudeAsh: _parseVal(_ashCtrl),
          metabolizableEnergy: _parseVal(_energyCtrl),
          calcium: _parseVal(_l2Ctrls2['calcium']!),
          phosphorus: _parseVal(_l2Ctrls2['phosphorus']!),
          magnesium: _parseVal(_l2Ctrls2['magnesium']!),
          potassium: _parseVal(_l2Ctrls2['potassium']!),
          sodium: _parseVal(_l2Ctrls2['sodium']!),
          omega3: _parseVal(_l2Ctrls2['omega3']!),
          omega6: _parseVal(_l2Ctrls2['omega6']!),
          linoleicAcid: _parseVal(_l2Ctrls2['linoleicAcid']!),
          ala: _parseVal(_l2Ctrls2['ala']!),
          lysine: _parseVal(_l2Ctrls2['lysine']!),
          methionine: _parseVal(_l2Ctrls2['methionine']!),
          cystine: _parseVal(_l2Ctrls2['cystine']!),
          threonine: _parseVal(_l2Ctrls2['threonine']!),
          tryptophan: _parseVal(_l2Ctrls2['tryptophan']!),
          arginine: _parseVal(_l2Ctrls2['arginine']!),
          valine: _parseVal(_l2Ctrls2['valine']!),
          isoleucine: _parseVal(_l2Ctrls2['isoleucine']!),
          leucine: _parseVal(_l2Ctrls2['leucine']!),
          zinc: _parseVal(_l2Ctrls2['zinc']!),
          copper: _parseVal(_l2Ctrls2['copper']!),
          iron: _parseVal(_l2Ctrls2['iron']!),
          manganese: _parseVal(_l2Ctrls2['manganese']!),
          selenium: _parseVal(_l2Ctrls2['selenium']!),
          iodine: _parseVal(_l2Ctrls2['iodine']!),
          vitA: _parseVal(_l2Ctrls2['vitA']!),
          vitD3: _parseVal(_l2Ctrls2['vitD3']!),
          vitE: _parseVal(_l2Ctrls2['vitE']!),
          vitK: _parseVal(_l2Ctrls2['vitK']!),
          vitB1: _parseVal(_l2Ctrls2['vitB1']!),
          vitB2: _parseVal(_l2Ctrls2['vitB2']!),
          vitB6: _parseVal(_l2Ctrls2['vitB6']!),
          vitB12: _parseVal(_l2Ctrls2['vitB12']!),
          niacin: _parseVal(_l2Ctrls2['niacin']!),
          pantothenicAcid: _parseVal(_l2Ctrls2['pantothenicAcid']!),
          biotin: _parseVal(_l2Ctrls2['biotin']!),
          folicAcid: _parseVal(_l2Ctrls2['folicAcid']!),
          recommendedStages: _selectedStages.toList(),
          maxRatioPercent: _parseRequired(_maxRatioCtrl, 100),
          minRatioPercent: _parseVal(_minRatioCtrl),
          needsSoaking: _needsSoaking,
          canSprout: _canSprout,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑食材' : '新增食材'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildBasicSection(theme),
            const SizedBox(height: 12),
            _buildL1Section(theme),
            const SizedBox(height: 12),
            _buildL2Section(theme, '常量矿物质', _l2Minerals),
            _buildL2Section(theme, '脂肪酸', _l2FattyAcids),
            _buildL2Section(theme, '必需氨基酸', _l2AminoAcids),
            _buildL2Section(theme, '微量元素', _l2TraceElements),
            _buildL2Section(theme, '维生素', _l2Vitamins),
            const SizedBox(height: 12),
            _buildBusinessSection(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── 分组卡片构建 ──────────────────────────────────────────────────────────

  Widget _buildBasicSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基础信息',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '名称 *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入名称' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: '分类 *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const ['主食', '蔬果', '补充剂', '其他']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? '其他'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('是否去壳'),
              value: _isHulled,
              onChanged: (v) => setState(() => _isHulled = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _basis,
              decoration: const InputDecoration(
                labelText: '数据基准 *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const ['As Fed', 'Dry Matter']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _basis = v ?? 'As Fed'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sourceCtrl,
              decoration: const InputDecoration(
                labelText: '数据来源 *',
                hintText: '如 USDA / Feedipedia / 厂家检测报告',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _confidence,
              decoration: const InputDecoration(
                labelText: '数据质量（选填）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('未设置')),
                DropdownMenuItem(value: 'A', child: Text('A - 实验室检测')),
                DropdownMenuItem(value: 'B', child: Text('B - 官方数据库')),
                DropdownMenuItem(value: 'C', child: Text('C - 论文数据')),
                DropdownMenuItem(value: 'D', child: Text('D - 企业标注')),
                DropdownMenuItem(value: 'E', child: Text('E - 经验估算')),
              ],
              onChanged: (v) => setState(() => _confidence = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildL1Section(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('核心营养（每百克）',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('带 * 为必填，其余选填',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 8),
            _numField('水分 * (%)', _moistureCtrl),
            _numField('粗蛋白 * (%)', _proteinCtrl),
            _numField('粗脂肪 * (%)', _fatCtrl),
            _numField('粗纤维 * (%)', _fiberCtrl),
            _numField('粗灰分 (%)', _ashCtrl),
            _numField('代谢能 (kcal/100g)', _energyCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildL2Section(
      ThemeData theme, String title, Map<String, String> fields) {
    return Card(
      child: ExpansionTile(
        title: Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('选填，留空表示无数据',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.hintColor)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: fields.entries
            .map((e) => _numField(e.key, _l2Ctrls[e.key]!))
            .toList(),
      ),
  );
  }

  Widget _buildBusinessSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('业务规则',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // 推荐阶段多选
            Text('适用阶段', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: RecipeStage.all.map((stage) {
                final selected = _selectedStages.contains(stage);
                return FilterChip(
                  label: Text(stage),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedStages.add(stage);
                      } else {
                        _selectedStages.remove(stage);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _numField('最大建议比例 * (%)', _maxRatioCtrl),
            _numField('最小建议比例 (%)', _minRatioCtrl),
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('需要浸泡'),
              value: _needsSoaking ?? false,
              onChanged: (v) => setState(() => _needsSoaking = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('适合发芽'),
              value: _canSprout ?? false,
              onChanged: (v) => setState(() => _canSprout = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 通用数值输入字段（允许小数）
  Widget _numField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
