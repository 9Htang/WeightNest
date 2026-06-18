import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';
import '../../services/excel_export_service.dart';

/// 称重插件设置页 — 数据导出 + 品种称重间隔配置
class WeightConfigScreen extends ConsumerStatefulWidget {
  const WeightConfigScreen({super.key});

  @override
  ConsumerState<WeightConfigScreen> createState() => _WeightConfigScreenState();
}

class _WeightConfigScreenState extends ConsumerState<WeightConfigScreen> {
  String? _exportPath;
  int? _selectedYear;
  int? _selectedMonth;
  String? _exportLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spAsync = ref.watch(allSpeciesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('称重设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 数据导出 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, size: 22),
                      const SizedBox(width: 8),
                      Text('数据导出', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('按月份导出所有鹦鹉体重记录为 Excel', style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickMonth(),
                          child: Text(_exportLabel ?? '选择月份'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: (_selectedYear != null && _selectedMonth != null)
                            ? () => _exportData()
                            : null,
                        icon: const Icon(Icons.download),
                        label: const Text('导出 Excel'),
                      ),
                    ],
                  ),
                  if (_exportPath != null && _exportPath != '正在导出...' && !_exportPath!.startsWith('导出失败')) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Share.shareXFiles([XFile(_exportPath!)]),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('分享文件'),
                      ),
                    ),
                  ],
                  if (_exportPath != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _exportPath!.startsWith('导出失败') ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_exportPath!, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 品种称重间隔配置 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.scale, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('品种称重间隔配置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('设置各品种在不同生长阶段的称重频率',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  spAsync.when(
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Center(child: Text('加载失败: $e')),
                    data: (spList) {
                      if (spList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('暂无品种，请先在设置中添加品种', style: TextStyle(color: Colors.grey))),
                        );
                      }
                      return Column(
                        children: spList.map((s) => _SpeciesWeighRow(
                          species: s,
                          onTap: () => _showWeighIntervalDialog(context, s),
                        )).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month),
      helpText: '选择导出月份',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
        _exportLabel = '${picked.year}年${picked.month}月';
        _exportPath = null;
      });
    }
  }

  Future<void> _exportData() async {
    if (_selectedYear == null || _selectedMonth == null) return;
    setState(() => _exportPath = '正在导出...');
    try {
      final db = ref.read(databaseProvider);
      final service = ExcelExportService(db);
      final file = await service.exportMonthly(_selectedYear!, _selectedMonth!);
      if (file != null) {
        setState(() => _exportPath = file.path);
      } else {
        setState(() => _exportPath = '导出失败：无数据');
      }
    } catch (e) {
      setState(() => _exportPath = '导出失败: $e');
    }
  }

  void _showWeighIntervalDialog(BuildContext context, Specy species) {
    final nestlingCtrl = TextEditingController(text: '${species.nestlingWeighIntervalDays}');
    final juvenileCtrl = TextEditingController(text: '${species.juvenileWeighIntervalDays}');
    final adultCtrl = TextEditingController(text: '${species.adultWeighIntervalDays}');

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${species.name} — 称重间隔'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('雏鸟 ≤${species.nestlingEndDays}天 · 幼鸟 ≤${species.juvenileEndDays}天 · 成鸟 >${species.juvenileEndDays}天',
                  style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface.withAlpha(140))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: nestlingCtrl,
                  decoration: const InputDecoration(labelText: '雏鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: juvenileCtrl,
                  decoration: const InputDecoration(labelText: '幼鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: adultCtrl,
                  decoration: const InputDecoration(labelText: '成鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                )),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.updateSpecies(
                species.id,
                nestlingWeighIntervalDays: int.tryParse(nestlingCtrl.text),
                juvenileWeighIntervalDays: int.tryParse(juvenileCtrl.text),
                adultWeighIntervalDays: int.tryParse(adultCtrl.text),
              );
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ).then((saved) {
      nestlingCtrl.dispose();
      juvenileCtrl.dispose();
      adultCtrl.dispose();
      if (saved == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.invalidate(allSpeciesProvider);
        });
      }
    });
  }
}

/// 品种称重间隔行
class _SpeciesWeighRow extends StatelessWidget {
  final Specy species;
  final VoidCallback onTap;

  const _SpeciesWeighRow({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.pets, size: 18, color: scheme.primary.withAlpha(180)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(species.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            _IntervalBadge(label: '雏${species.nestlingWeighIntervalDays}天', color: scheme.tertiary),
            const SizedBox(width: 4),
            _IntervalBadge(label: '幼${species.juvenileWeighIntervalDays}天', color: scheme.primary),
            const SizedBox(width: 4),
            _IntervalBadge(label: '成${species.adultWeighIntervalDays}天', color: scheme.secondary),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withAlpha(80)),
          ],
        ),
      ),
    );
  }
}

class _IntervalBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _IntervalBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withAlpha(25),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
