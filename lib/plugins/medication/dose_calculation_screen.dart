import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme.dart';
import '../../widgets/feather_icon.dart';
import '../../widgets/bird_picker_sheet.dart';
import 'drug_library_repository.dart';

/// 4-step dose calculation wizard:
/// Step 1: Select bird → show weight
/// Step 2: Select drug → choose formulation
/// Step 3: Select disease → auto-match dose rule (species-specific > general)
/// Step 4: Result display + weight warning + create plan
class DoseCalculationScreen extends StatefulWidget {
  final int? initialBirdId;

  const DoseCalculationScreen({super.key, this.initialBirdId});

  @override
  State<DoseCalculationScreen> createState() => _DoseCalculationScreenState();
}

class _DoseCalculationScreenState extends State<DoseCalculationScreen> {
  int _currentStep = 0;

  // Step 1 data
  BirdWithDetails? _selectedBird;
  Weight? _latestWeight;

  // Step 2 data
  DrugLibraryData? _selectedDrug;
  List<DrugFormulation> _formulations = [];
  DrugFormulation? _selectedFormulation;

  // Step 3 data
  List<DiseaseCatalogData> _diseases = [];
  DiseaseCatalogData? _selectedDisease;
  List<DoseRuleWithNames> _matchedRules = [];
  DoseRuleWithNames? _selectedRule;
  bool _ruleMatched = false;

  // Step 4 data
  DoseCalculationResult? _calcResult;
  bool _calculating = false;

  // Manual entry mode (no dose rule matched)
  final _manualMgKgCtrl = TextEditingController();
  final _manualTimesCtrl = TextEditingController(text: '1');
  final _manualDaysCtrl = TextEditingController(text: '7');
  String _manualRoute = '口服';

  AppDatabase get _db => pluginRegistry.db!;
  bool get _useManualDose => !_ruleMatched;

  @override
  void initState() {
    super.initState();
    if (widget.initialBirdId != null) {
      _loadBird(widget.initialBirdId!);
    }
  }

  @override
  void dispose() {
    _manualMgKgCtrl.dispose();
    _manualTimesCtrl.dispose();
    _manualDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBird(int birdId) async {
    final bird = await _db.getWithDetails(birdId);
    final weight = await _db.getLatestByBird(birdId);
    if (mounted)
      setState(() {
        _selectedBird = bird;
        _latestWeight = weight;
      });
  }

  Future<void> _loadFormulations(int drugId) async {
    final forms = await _db.getFormulationsByDrug(drugId);
    if (mounted) {
      setState(() {
        _formulations = forms;
        _selectedFormulation = forms.isNotEmpty
            ? (forms.firstWhereOrNull((f) => f.isDefault) ?? forms.first)
            : null;
      });
    }
  }

  Future<void> _loadDiseases() async {
    final diseases = await _db.getAllDiseases();
    if (mounted) setState(() => _diseases = diseases);
  }

  Future<void> _matchDoseRules() async {
    if (_selectedDrug == null ||
        _selectedDisease == null ||
        _selectedBird == null) return;

    final rules = await _db.getRulesByDrugAndDisease(
        _selectedDrug!.id, _selectedDisease!.id);
    // Sort: species-specific first, general last
    rules.sort((a, b) {
      if (a.isSpeciesSpecific && !b.isSpeciesSpecific) return -1;
      if (!a.isSpeciesSpecific && b.isSpeciesSpecific) return 1;
      return 0;
    });

    setState(() {
      _matchedRules = rules;
      if (rules.isNotEmpty) {
        // Try to find species-specific match
        final speciesMatch = rules
            .where((r) => r.rule.speciesId == _selectedBird!.bird.speciesId);
        _selectedRule =
            speciesMatch.isNotEmpty ? speciesMatch.first : rules.first;
        _ruleMatched = true;
      } else {
        _selectedRule = null;
        _ruleMatched = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('剂量计算器')),
      body: Column(children: [
        // Step indicator
        _StepIndicator(
            currentStep: _currentStep,
            onStepTap: (i) {
              if (i < _currentStep) setState(() => _currentStep = i);
            }),
        const Divider(height: 1),
        // Step content
        Expanded(child: _buildStepContent(theme)),
        // Bottom navigation
        _buildBottomNav(theme),
      ]),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(theme);
      case 1:
        return _buildStep2(theme);
      case 2:
        return _buildStep3(theme);
      case 3:
        return _buildStep4(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Select Bird ──
  Widget _buildStep1(ThemeData theme) {
    if (_selectedBird != null) {
      final bird = _selectedBird!;
      final isOutOfRange = _latestWeight != null &&
          bird.isWeightOutOfRangeForSpecies(_latestWeight!.weightG);

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('已选择鹦鹉', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(child: Text(bird.bird.name[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bird.bird.name, style: theme.textTheme.titleSmall),
                        Text('${bird.species.name} · ${bird.growthStage}',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant)),
                        if (_latestWeight != null)
                          Text(
                              '当前体重: ${_latestWeight!.weightG.toStringAsFixed(1)}g',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isOutOfRange
                                      ? theme.colorScheme.error
                                      : null)),
                      ]),
                ),
                TextButton(
                    onPressed: () => setState(() {
                          _selectedBird = null;
                          _latestWeight = null;
                        }),
                    child: const Text('更换')),
              ],
            ),
            ),
          ),
          if (_latestWeight == null) ...[
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.warning_amber,
                      size: 18, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('该鹦鹉暂无体重记录，请先称重',
                          style: TextStyle(fontSize: 13))),
                ]),
              ),
            ),
          ],
          if (isOutOfRange &&
              bird.species.minWeightG != null &&
              bird.species.maxWeightG != null)
            _WeightWarning(
              weightG: _latestWeight!.weightG,
              minG: bird.species.minWeightG!,
              maxG: bird.species.maxWeightG!,
            ),
        ]),
      );
    }

    return FutureBuilder<List<BirdWithDetails>>(
      future: _db.getAllWithDetails(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final birds = snap.data ?? [];
        if (birds.isEmpty) {
          return Center(
              child: Text('暂无鹦鹉记录',
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)));
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('从 ${birds.length} 只鹦鹉中选择',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.outline)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final bird = await BirdPickerSheet.show(
                      ctx,
                      title: '选择鹦鹉',
                      birds: birds,
                      showSpeciesFilter: true,
                      showStageFilter: true,
                    );
                    if (bird != null) {
                      _loadBird(bird.bird.id);
                      if (mounted) setState(() => _currentStep = 1);
                    }
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('搜索并选择鹦鹉'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Step 2: Select Drug + Formulation ──
  Widget _buildStep2(ThemeData theme) {
    if (_selectedDrug != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('已选择药品', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(_selectedDrug!.drugName,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _drugCategoryColor(
                                  _selectedDrug!.drugCategory, theme)
                              .withAlpha(30),
                        ),
                        child: Text(_selectedDrug!.drugCategory,
                            style: TextStyle(
                                fontSize: 10,
                                color: _drugCategoryColor(
                                    _selectedDrug!.drugCategory, theme))),
                      ),
                    ]),
                    if (_selectedDrug!.brandName != null &&
                        _selectedDrug!.brandName!.isNotEmpty)
                      Text(_selectedDrug!.brandName!,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                        '${_selectedDrug!.formulationType} · ${_selectedDrug!.activeIngredient ?? ""}',
                        style: TextStyle(
                            fontSize: 11, color: theme.colorScheme.outline)),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          if (_formulations.isNotEmpty) ...[
            Text('选择规格', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._formulations.map((f) {
              final selected = _selectedFormulation?.id == f.id;
              return Card(
                color: selected ? theme.colorScheme.primaryContainer : null,
                child: ListTile(
                  title: Text('${f.concentration} ${f.unit}',
                      style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: f.label != null ? Text(f.label!) : null,
                  trailing: f.isDefault
                      ? const Chip(
                          label: Text('默认', style: TextStyle(fontSize: 10)))
                      : null,
                  selected: selected,
                  onTap: () => setState(() => _selectedFormulation = f),
                ),
              );
            }),
          ] else
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('该药品暂无规格，请先在药品库添加浓度/规格'))),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () => setState(() {
                    _selectedDrug = null;
                    _formulations = [];
                    _selectedFormulation = null;
                  }),
              child: const Text('更换药品')),
        ]),
      );
    }

    return FutureBuilder<List<DrugLibraryData>>(
      future: _db.getAllDrugs(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final drugs = snap.data ?? [];
        if (drugs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_pharmacy_outlined,
                  size: 48,
                  color: Theme.of(ctx).colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text('药品库为空，请先添加药品',
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: drugs.length,
          itemBuilder: (ctx, i) {
            final d = drugs[i];
            return Card(
              child: ListTile(
                leading: Icon(Icons.medication,
                    color: _drugCategoryColor(d.drugCategory, Theme.of(ctx))),
                title: Text(d.drugName),
                subtitle: Text(d.activeIngredient ?? d.formulationType),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedDrug = d;
                  });
                  _loadFormulations(d.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  // ── Step 3: Select Disease → Auto-match ──
  Widget _buildStep3(ThemeData theme) {
    if (_selectedDisease != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('已选择疾病: ${_selectedDisease!.diseaseName}',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_ruleMatched && _selectedRule != null) ...[
            _DoseRuleCard(
              rule: _selectedRule!,
              onTap: () {
                // Show rule picker if multiple
                if (_matchedRules.length > 1) _showRulePicker();
              },
            ),
            if (_matchedRules.length > 1)
              TextButton(
                  onPressed: _showRulePicker,
                  child: Text('查看其他 ${_matchedRules.length - 1} 条剂量规则')),
          ] else ...[
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('暂无参考剂量规则，请手动输入剂量参数',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Text('手动输入剂量参数', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _manualMgKgCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: '剂量(mg/kg)',
                      hintText: '15',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _manualTimesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '次/天', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _manualDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '疗程(天)', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _manualRoute,
              decoration: const InputDecoration(
                  labelText: '给药途径', border: OutlineInputBorder()),
              items: ['口服', '注射', '外用', '滴眼', '其他']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _manualRoute = v!),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => setState(() {
                    _selectedDisease = null;
                    _matchedRules = [];
                    _selectedRule = null;
                    _ruleMatched = false;
                  }),
              child: const Text('更换疾病')),
        ]),
      );
    }

    return FutureBuilder<List<DiseaseCatalogData>>(
      future: _db.getAllDiseases(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final diseases = snap.data ?? [];
        if (diseases.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.coronavirus_outlined,
                  size: 48,
                  color: Theme.of(ctx).colorScheme.outlineVariant),
              const SizedBox(height: 12),
              const Text('疾病库为空，请先在药品库中添加疾病'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addDiseaseQuick,
                child: const Text('快速添加疾病'),
              ),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: diseases.length,
          itemBuilder: (ctx, i) {
            final d = diseases[i];
            return Card(
              child: ListTile(
                leading: Icon(Icons.coronavirus,
                    color: Theme.of(ctx).colorScheme.tertiary),
                title: Text(d.diseaseName),
                subtitle: d.description != null
                    ? Text(d.description!, style: const TextStyle(fontSize: 12))
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedDisease = d;
                  });
                  _matchDoseRules();
                },
              ),
            );
          },
        );
      },
    );
  }

  // ── Step 4: Result ──
  Widget _buildStep4(ThemeData theme) {
    if (_calcResult == null && !_calculating) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calculate, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('点击下方按钮计算剂量',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
    }
    if (_calculating) {
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('计算中...'),
      ]));
    }

    final r = _calcResult!;
    if (r.hasError) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 36, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(r.error!,
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 15)),
            ]),
          ),
        ),
      );
    }

    final bird = _selectedBird;
    final drug = _selectedDrug;
    final form = _selectedFormulation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Weight warning
        if (r.isWeightOutOfRange &&
            r.speciesMinWeight != null &&
            r.speciesMaxWeight != null)
          _WeightWarning(
              weightG: r.weightG!,
              minG: r.speciesMinWeight!,
              maxG: r.speciesMaxWeight!),

        // Calculation card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.calculate, size: 20),
                const SizedBox(width: 8),
                Text('计算结果',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
              const Divider(),
              _calcRow('鹦鹉',
                  '${bird?.bird.name ?? "-"} (${r.weightG?.toStringAsFixed(1) ?? "-"}g)'),
              _calcRow('品种', '${bird?.species.name ?? "-"}'),
              _calcRow('药品',
                  '${drug?.drugName ?? "-"} · ${form != null ? "${form.concentration}${form.unit}" : "-"}'),
              _calcRow(
                  '疾病', r.diseaseName ?? _selectedDisease?.diseaseName ?? '-'),
              _calcRow('剂量规则', '${r.doseMgKg ?? 0} mg/kg'),
              _calcRow('给药途径', r.administrationRoute ?? '-'),
              const Divider(),
              // Result highlight
              Center(
                child: Column(children: [
                  Text('每次给药量',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Text('${r.volumeDisplay} mL',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        )),
                  ),
                ]),
              ),
              const Divider(),
              _calcRow('每日次数', '${r.timesPerDay ?? 0} 次'),
              _calcRow('疗程', '${r.durationDays ?? 0} 天'),
              _calcRow(
                  '剂量来源',
                  _ruleMatched
                      ? (_selectedRule?.sourceLabel ??
                          _selectedRule?.speciesLabel ??
                          '通用')
                      : '手动输入'),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Warning
        Card(
          color: theme.colorScheme.tertiaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.warning_amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('计算结果仅供参考，实际用药应以有鸟类经验的兽医指导为准',
                    style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Create plan button
        FilledButton.icon(
          icon: const Icon(Icons.medication),
          label: const Text('创建喂药方案'),
          onPressed: _createPlan,
        ),
      ]),
    );
  }

  Widget _calcRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
        color: theme.scaffoldBackgroundColor,
      ),
      child: Row(children: [
        if (_currentStep > 0)
          OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('上一步')),
        const Spacer(),
        if (_currentStep < 3)
          FilledButton(
            onPressed:
                _canProceed() ? () => setState(() => _currentStep++) : null,
            child: Text(_currentStep == 2 ? '计算' : '下一步'),
          ),
        if (_currentStep == 3)
          FilledButton(onPressed: _calculate, child: const Text('重新计算')),
      ]),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedBird != null && _latestWeight != null;
      case 1:
        return _selectedDrug != null && _selectedFormulation != null;
      case 2:
        return _selectedDisease != null &&
            (_ruleMatched ||
                (_manualMgKgCtrl.text.isNotEmpty &&
                    double.tryParse(_manualMgKgCtrl.text) != null));
      default:
        return false;
    }
  }

  Future<void> _calculate() async {
    if (_selectedBird == null || _selectedFormulation == null) return;

    setState(() => _calculating = true);
    try {
      if (_ruleMatched && _selectedRule != null) {
        _calcResult = await _db.calculateDosage(
          birdId: _selectedBird!.bird.id,
          formulationId: _selectedFormulation!.id,
          doseRuleId: _selectedRule!.rule.id,
        );
      } else {
        final mgKg = double.tryParse(_manualMgKgCtrl.text) ?? 0;
        final times = int.tryParse(_manualTimesCtrl.text) ?? 1;
        final days = int.tryParse(_manualDaysCtrl.text) ?? 7;
        _calcResult = await _db.calculateManualDosage(
          birdId: _selectedBird!.bird.id,
          formulationId: _selectedFormulation!.id,
          mgKgDose: mgKg,
          timesPerDay: times,
          durationDays: days,
          administrationRoute: _manualRoute,
        );
      }
    } catch (e) {
      _calcResult = DoseCalculationResult(error: '计算失败: $e');
    }
    if (mounted) setState(() => _calculating = false);
  }

  Future<void> _createPlan() async {
    if (_calcResult == null ||
        _selectedBird == null ||
        _selectedDrug == null ||
        _selectedFormulation == null ||
        _selectedDisease == null) return;

    final startDate = AppClock.now;
    final endDate =
        startDate.add(Duration(days: _calcResult!.durationDays ?? 7));

    try {
      await _db.addMedicationFromLibrary(
        birdId: _selectedBird!.bird.id,
        drugLibraryId: _selectedDrug!.id,
        formulationId: _selectedFormulation!.id,
        diseaseCatalogId: _selectedDisease!.id,
        doseRuleId: _ruleMatched ? _selectedRule?.rule.id : null,
        calculatedDosage: '${_calcResult!.volumeDisplay} mL',
        manualDosage: _ruleMatched ? null : '${_calcResult!.volumeDisplay} mL',
        timesPerDay: _calcResult!.timesPerDay ?? 1,
        startDate: startDate,
        endDate: endDate,
        notes: _ruleMatched
            ? '剂量来源: ${_selectedRule?.speciesLabel ?? "通用"}规则'
            : '手动输入剂量',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '喂药方案已创建: ${_selectedDrug!.drugName} ${_calcResult!.volumeDisplay} mL')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  void _showRulePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: _matchedRules
            .map((r) => ListTile(
                  leading: r.isSpeciesSpecific
                      ? const FeatherIcon(size: 24)
                      : const Icon(Icons.public),
                  title: Text('${r.diseaseName} · ${r.speciesLabel}'),
                  subtitle: Text(
                      '${r.rule.mgKgDose} mg/kg · ${r.rule.timesPerDay}次/日 · ${r.rule.durationDays}天'),
                  selected: _selectedRule?.rule.id == r.rule.id,
                  onTap: () {
                    setState(() => _selectedRule = r);
                    Navigator.pop(ctx);
                  },
                ))
            .toList(),
      ),
    );
  }

  Future<void> _addDiseaseQuick() async {
    final ctrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加疾病'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  labelText: '疾病名称',
                  hintText: '呼吸道感染',
                  border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: '说明(选填)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('添加')),
        ],
      ),
    );
    ctrl.dispose();
    descCtrl.dispose();
    if (result == true && ctrl.text.trim().isNotEmpty) {
      await _db.addDisease(
          diseaseName: ctrl.text.trim(),
          description:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
      _loadDiseases();
    }
  }

  /// 药品分类色。业务语义色（非主题色），按 [DrugCategoryColors] 局部常量映射。
  Color _drugCategoryColor(String cat, ThemeData theme) {
    final c = DrugCategoryColors.of(cat);
    return c ?? theme.colorScheme.onSurfaceVariant;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTap;
  const _StepIndicator({required this.currentStep, required this.onStepTap});

  static const _labels = ['选鸟', '选药', '选病', '结果'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
          children: List.generate(4, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Expanded(
          child: Row(children: [
            if (i > 0)
              Expanded(
                  child: Container(
                height: 2,
                color: isDone
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              )),
            InkWell(
              onTap: i <= currentStep ? () => onStepTap(i) : null,
              child: Column(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? theme.colorScheme.primary
                        : isDone
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check,
                            size: 16, color: theme.colorScheme.primary)
                        : Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_labels[i],
                    style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal)),
              ]),
            ),
          ]),
        );
      })),
    );
  }
}

class _DoseRuleCard extends StatelessWidget {
  final DoseRuleWithNames rule;
  final VoidCallback onTap;
  const _DoseRuleCard({required this.rule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              rule.isSpeciesSpecific
                  ? FeatherIcon(
                      size: 16,
                      color: rule.isSpeciesSpecific
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary)
                  : Icon(Icons.public,
                      size: 16,
                      color: rule.isSpeciesSpecific
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary),
              const SizedBox(width: 6),
              Text(
                  rule.isSpeciesSpecific ? '${rule.speciesLabel} 专属规则' : '通用规则',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: rule.isSpeciesSpecific
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary)),
            ]),
            const SizedBox(height: 8),
            Text('${rule.rule.mgKgDose} mg/kg',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                '${rule.rule.timesPerDay} 次/日 · ${rule.rule.durationDays} 天 · ${rule.rule.administrationRoute}'),
            if (rule.rule.notes != null && rule.rule.notes!.isNotEmpty)
              Text(rule.rule.notes!,
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.outline)),
          ]),
        ),
      ),
    );
  }
}

class _WeightWarning extends StatelessWidget {
  final double weightG;
  final double minG;
  final double maxG;
  const _WeightWarning(
      {required this.weightG, required this.minG, required this.maxG});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(Icons.warning, color: scheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                '体重异常: 当前 ${weightG.toStringAsFixed(1)}g，'
                '正常范围 ${minG.toStringAsFixed(0)}-${maxG.toStringAsFixed(0)}g',
                style: TextStyle(fontSize: 13, color: scheme.error)),
          ),
        ]),
      ),
    );
  }
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// 药品分类业务色 —— 与主题无关的固定语义色（用于药品分类徽章/图标）。
///
/// 这些颜色代表药品类别本身（抗生素/驱虫/维生素/益生菌/抗真菌），
/// 不随明暗模式变化，故保留为字面量常量而非映射到 ColorScheme。
class DrugCategoryColors {
  DrugCategoryColors._();

  static const _map = <String, Color>{
    '抗生素': Color(0xFFE53935),
    '驱虫': Color(0xFFFB8C00),
    '维生素': Color(0xFF43A047),
    '益生菌': Color(0xFF1E88E5),
    '抗真菌': Color(0xFF8E24AA),
  };

  /// 返回分类对应的业务色；未知分类返回 null（由调用方回退到主题色）。
  static Color? of(String category) => _map[category];
}
