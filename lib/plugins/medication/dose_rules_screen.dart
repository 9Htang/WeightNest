import 'package:flutter/material.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';
import '../../widgets/feather_icon.dart';
import 'drug_library_repository.dart';

/// Dose rules management screen for a specific drug.
class DoseRulesScreen extends StatefulWidget {
  final int drugId;
  final String drugName;

  const DoseRulesScreen(
      {super.key, required this.drugId, required this.drugName});

  @override
  State<DoseRulesScreen> createState() => _DoseRulesScreenState();
}

class _DoseRulesScreenState extends State<DoseRulesScreen> {
  List<DoseRuleWithNames> _rules = [];
  List<Specy> _species = [];
  List<DiseaseCatalogData> _diseases = [];
  bool _loading = true;

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _db.getRulesByDrug(widget.drugId),
      _db.getAllSpecies(),
      _db.getAllDiseases(),
    ]);
    if (mounted) {
      setState(() {
        _rules = results[0] as List<DoseRuleWithNames>;
        _species = results[1] as List<Specy>;
        _diseases = results[2] as List<DiseaseCatalogData>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('剂量规则 - ${widget.drugName}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('剂量规则 - ${widget.drugName}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRuleDialog(null),
        child: const Icon(Icons.add),
      ),
      body: _rules.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.rule, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('暂无剂量规则', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                const Text('点击右下角 + 添加',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _rules.length,
              itemBuilder: (ctx, i) => _RuleCard(
                rule: _rules[i],
                onTap: () => _showRuleDialog(_rules[i]),
                onDelete: () => _confirmDelete(_rules[i]),
              ),
            ),
    );
  }

  void _showRuleDialog(DoseRuleWithNames? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _DoseRuleEditDialog(
        db: _db,
        drugId: widget.drugId,
        existing: existing,
        species: _species,
        diseases: _diseases,
        onSaved: _load,
      ),
    );
  }

  void _confirmDelete(DoseRuleWithNames rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除「${rule.diseaseName} - ${rule.speciesLabel}」的剂量规则？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.removeDoseRule(rule.rule.id);
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
// Rule Card
// ═══════════════════════════════════════════════════════════════════════════════

class _RuleCard extends StatelessWidget {
  final DoseRuleWithNames rule;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RuleCard(
      {required this.rule, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGeneral = !rule.isSpeciesSpecific;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isGeneral ? Colors.blue.shade50 : Colors.green.shade50,
                ),
                child: isGeneral
                    ? const Icon(Icons.public, size: 20, color: Colors.blue)
                    : const FeatherIcon(size: 20, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.diseaseName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${rule.rule.mgKgDose} mg/kg · ${rule.rule.timesPerDay}次/日 · ${rule.rule.durationDays}天',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isGeneral
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                        ),
                        child: Text(
                          rule.speciesLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: isGeneral
                                ? Colors.blue.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey.shade100,
                        ),
                        child: Text(rule.rule.administrationRoute,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade700)),
                      ),
                    ]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: Colors.grey.shade400,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dose Rule Edit Dialog
// ═══════════════════════════════════════════════════════════════════════════════

class _DoseRuleEditDialog extends StatefulWidget {
  final AppDatabase db;
  final int drugId;
  final DoseRuleWithNames? existing;
  final List<Specy> species;
  final List<DiseaseCatalogData> diseases;
  final VoidCallback onSaved;

  const _DoseRuleEditDialog({
    required this.db,
    required this.drugId,
    this.existing,
    required this.species,
    required this.diseases,
    required this.onSaved,
  });

  @override
  State<_DoseRuleEditDialog> createState() => _DoseRuleEditDialogState();
}

class _DoseRuleEditDialogState extends State<_DoseRuleEditDialog> {
  int? _diseaseId;
  int? _speciesId;
  final _mgKgCtrl = TextEditingController();
  final _timesCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  String _route = '口服';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _routes = ['口服', '注射', '外用', '滴眼', '其他'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _diseaseId = e?.rule.diseaseId;
    _speciesId = e?.rule.speciesId;
    _mgKgCtrl.text = e?.rule.mgKgDose.toString() ?? '';
    _timesCtrl.text = e?.rule.timesPerDay.toString() ?? '';
    _daysCtrl.text = e?.rule.durationDays.toString() ?? '';
    _route = e?.rule.administrationRoute ?? '口服';
    _notesCtrl.text = e?.rule.notes ?? '';
  }

  @override
  void dispose() {
    _mgKgCtrl.dispose();
    _timesCtrl.dispose();
    _daysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? '编辑剂量规则' : '添加剂量规则'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Disease selector
            DropdownButtonFormField<int>(
              value: _diseaseId,
              decoration: const InputDecoration(
                  labelText: '疾病', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('请选择疾病')),
                ...widget.diseases.map((d) =>
                    DropdownMenuItem(value: d.id, child: Text(d.diseaseName))),
              ],
              onChanged: (v) => setState(() => _diseaseId = v),
            ),
            const SizedBox(height: 12),

            // Species selector (null = general)
            DropdownButtonFormField<int?>(
              value: _speciesId,
              decoration: const InputDecoration(
                  labelText: '品种 (留空=通用)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('通用 (适用所有品种)')),
                ...widget.species.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (v) => setState(() => _speciesId = v),
            ),
            const SizedBox(height: 12),

            // Dose mg/kg
            TextField(
              controller: _mgKgCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '剂量 (mg/kg)',
                  hintText: '15',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // Times per day + duration
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _timesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '每天次数',
                      hintText: '2',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: '疗程(天)',
                      hintText: '7',
                      border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Administration route
            DropdownButtonFormField<String>(
              value: _route,
              decoration: const InputDecoration(
                  labelText: '给药途径', border: OutlineInputBorder()),
              items: _routes
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _route = v!),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                  labelText: '备注 (来源/文献)',
                  hintText: '参考: 兽医教材 2024',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _saving ? null : _doSave,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _doSave() async {
    final mgKg = double.tryParse(_mgKgCtrl.text);
    final times = int.tryParse(_timesCtrl.text);
    final days = int.tryParse(_daysCtrl.text);
    if (mgKg == null || times == null || days == null || _diseaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写疾病、剂量、次数和疗程')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        await widget.db.updateDoseRule(
          widget.existing!.rule.id,
          mgKgDose: mgKg,
          timesPerDay: times,
          durationDays: days,
          administrationRoute: _route,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      } else {
        await widget.db.addDoseRule(
          drugId: widget.drugId,
          diseaseId: _diseaseId!,
          speciesId: _speciesId,
          mgKgDose: mgKg,
          timesPerDay: times,
          durationDays: days,
          administrationRoute: _route,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
