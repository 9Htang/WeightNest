import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_clock.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';
import '../../services/excel_export_service.dart';
import '../../widgets/feather_icon.dart';
import '../../screens/weigh/weigh_input_config.dart';
import '../../theme/app_tokens.dart';
import 'grid_color_config.dart';

/// 称重插件设置页 — 数据导出 + 表格颜色 + 品种称重间隔配置
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
    final scheme = theme.colorScheme;
    final sp = context.sp;
    final r = context.r;
    final spAsync = ref.watch(allSpeciesProvider);
    final cfg = ref.watch(gridColorConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('称重设置')),
      body: ListView(
        padding: sp.paddingLg,
        children: [
          // ── 数据导出 ──
          Card(
            child: Padding(
              padding: sp.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, size: 22),
                      SizedBox(width: sp.sm),
                      Text('数据导出',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: sp.sm),
                  Text('按月份导出所有鹦鹉体重记录为 Excel',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  SizedBox(height: sp.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickMonth(),
                          child: Text(_exportLabel ?? '选择月份'),
                        ),
                      ),
                      SizedBox(width: sp.md),
                      FilledButton.tonalIcon(
                        onPressed:
                            (_selectedYear != null && _selectedMonth != null)
                                ? () => _exportData()
                                : null,
                        icon: const Icon(Icons.download),
                        label: const Text('导出 Excel'),
                      ),
                    ],
                  ),
                  if (_exportPath != null &&
                      _exportPath != '正在导出...' &&
                      !_exportPath!.startsWith('导出失败')) ...[
                    SizedBox(height: sp.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Share.shareXFiles([XFile(_exportPath!)]),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('分享文件'),
                      ),
                    ),
                  ],
                  if (_exportPath != null) ...[
                    SizedBox(height: sp.sm),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _exportPath!.startsWith('导出失败')
                            ? scheme.errorContainer
                            : scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(r.lg),
                      ),
                      child: Text(_exportPath!,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: sp.lg),

          // ── 称重表格颜色配置 ──
          _ColorConfigCard(
            config: cfg,
            onChanged: (newCfg) =>
                ref.read(gridColorConfigProvider.notifier).update(newCfg),
          ),

          SizedBox(height: sp.lg),

          // ── 输入偏好 ──
          _InputPrefsCard(),

          SizedBox(height: sp.lg),

          // ── 品种称重间隔配置 ──
          Card(
            child: Padding(
              padding: sp.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.scale, size: 22),
                    SizedBox(width: sp.sm),
                    Expanded(
                      child: Text('品种称重间隔配置',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  SizedBox(height: sp.xs),
                  Text('设置各品种在不同生长阶段的称重频率',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  SizedBox(height: sp.md),
                  spAsync.when(
                    loading: () => Center(
                        child: Padding(
                      padding: EdgeInsets.all(sp.xl),
                      child: const CircularProgressIndicator(),
                    )),
                    error: (e, _) => Center(child: Text('加载失败: $e')),
                    data: (spList) {
                      if (spList.isEmpty) {
                        return Padding(
                          padding: sp.paddingLg,
                          child: Center(
                              child: Text('暂无品种，请先在设置中添加品种',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant))),
                        );
                      }
                      return Column(
                        children: spList
                            .map((s) => _SpeciesWeighRow(
                                  species: s,
                                  onTap: () =>
                                      _showWeighIntervalDialog(context, s),
                                ))
                            .toList(),
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
    final now = AppClock.now;
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
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
    final nestlingCtrl =
        TextEditingController(text: '${species.nestlingWeighIntervalDays}');
    final juvenileCtrl =
        TextEditingController(text: '${species.juvenileWeighIntervalDays}');
    final adultCtrl =
        TextEditingController(text: '${species.adultWeighIntervalDays}');

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${species.name} — 称重间隔'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '雏鸟 ≤${species.nestlingEndDays}天 · 幼鸟 ≤${species.juvenileEndDays}天 · 成鸟 >${species.juvenileEndDays}天',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: nestlingCtrl,
                  decoration:
                      const InputDecoration(labelText: '雏鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: juvenileCtrl,
                  decoration:
                      const InputDecoration(labelText: '幼鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: adultCtrl,
                  decoration:
                      const InputDecoration(labelText: '成鸟(天)', isDense: true),
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
    final sp = context.sp;
    final a = context.a;
    final r = context.r;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            FeatherIcon(size: 18, color: scheme.primary.withAlpha(a.heavy)),
            SizedBox(width: sp.sm + 2),
            Expanded(
              child: Text(species.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            _IntervalBadge(
                label: '雏${species.nestlingWeighIntervalDays}天',
                color: scheme.tertiary),
            SizedBox(width: sp.xs),
            _IntervalBadge(
                label: '幼${species.juvenileWeighIntervalDays}天',
                color: scheme.primary),
            SizedBox(width: sp.xs),
            _IntervalBadge(
                label: '成${species.adultWeighIntervalDays}天',
                color: scheme.secondary),
            SizedBox(width: sp.xs),
            Icon(Icons.chevron_right,
                size: 18, color: scheme.onSurface.withAlpha(a.medium)),
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
    final r = context.r;
    final a = context.a;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.sm),
        color: color.withAlpha(a.subtle),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// ═══════════════════════════════════════════════
// 颜色配置卡片
// ═══════════════════════════════════════════════

const _palette = <Color>[
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFF009688),
  Color(0xFF2196F3),
  Color(0xFF3F51B5),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
  Color(0xFFE91E63),
  Color(0xFFFF5722),
  Color(0xFFFF9800),
  Color(0xFFFFEB3B),
  Color(0xFF795548),
  Color(0xFF607D8B),
  Color(0xFF9E9E9E),
  Color(0xFFE0E0E0),
];

class _ColorConfigCard extends StatelessWidget {
  final GridColorConfig config;
  final ValueChanged<GridColorConfig> onChanged;

  const _ColorConfigCard({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sp = context.sp;

    final states = [
      BirdCellState.weighedToday,
      BirdCellState.overdue,
      BirdCellState.abnormalHigh,
      BirdCellState.abnormalLow,
      BirdCellState.weaning,
    ];

    return Card(
      child: Padding(
        padding: sp.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.palette_outlined, size: 22),
              SizedBox(width: sp.sm),
              Text('称重表格颜色',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            SizedBox(height: sp.xs),
            Text('自定义各状态的单元格颜色与显示方式',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),

            const Divider(height: 24),

            // 显示模式
            Text('显示方式',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            SizedBox(height: sp.sm),
            SegmentedButton<CellDisplayMode>(
              segments: CellDisplayMode.values
                  .map((m) => ButtonSegment(
                      value: m,
                      label: Text(m.label, style: theme.textTheme.bodySmall)))
                  .toList(),
              selected: {config.displayMode},
              onSelectionChanged: (s) =>
                  onChanged(config.copyWith(displayMode: s.first)),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(horizontal: sp.sm)),
              ),
            ),

            SizedBox(height: sp.lg),

            // 边框粗细
            if (config.displayMode != CellDisplayMode.fill) ...[
              Row(children: [
                Text('边框粗细',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const Spacer(),
                Text('${config.borderWidth.toStringAsFixed(1)} px',
                    style: theme.textTheme.bodySmall),
              ]),
              Slider(
                value: config.borderWidth,
                min: 1.0,
                max: 4.0,
                divisions: 6,
                onChanged: (v) => onChanged(config.copyWith(borderWidth: v)),
              ),
            ],

            // 填充透明度
            if (config.displayMode != CellDisplayMode.border) ...[
              Row(children: [
                Text('填充浓度',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const Spacer(),
                Text('${(config.fillOpacity * 100).round()}%',
                    style: theme.textTheme.bodySmall),
              ]),
              Slider(
                value: config.fillOpacity,
                min: 0.05,
                max: 0.40,
                divisions: 7,
                onChanged: (v) => onChanged(config.copyWith(fillOpacity: v)),
              ),
            ],

            // 表格最小列宽
            Row(children: [
              Text('表格最小列宽',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text('${config.minColumnWidth.round()} px',
                  style: theme.textTheme.bodySmall),
            ]),
            Slider(
              value: config.minColumnWidth,
              min: GridColorConfig.minColumnWidthFloor,
              max: GridColorConfig.minColumnWidthCeil,
              divisions: 49,
              onChanged: (v) => onChanged(config.copyWith(minColumnWidth: v)),
            ),
            SizedBox(height: sp.sm),

            // 图例开关
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('显示图例', style: theme.textTheme.labelLarge),
              subtitle: Text('在称重表格右下角显示颜色含义',
                  style: theme.textTheme.bodySmall),
              value: config.showLegend,
              onChanged: (v) => onChanged(config.copyWith(showLegend: v)),
            ),

            const Divider(height: 8),
            SizedBox(height: sp.sm),

            // 各状态颜色行
            ...states.map((s) => _StateColorRow(
                  state: s,
                  color: config.borderColor(s),
                  displayMode: config.displayMode,
                  fillOpacity: config.fillOpacity,
                  onColorPicked: (c) {
                    final updated =
                        Map<BirdCellState, Color>.from(config.colors);
                    updated[s] = c;
                    onChanged(config.copyWith(colors: updated));
                  },
                )),

            SizedBox(height: sp.sm),

            // 恢复默认
            Center(
              child: TextButton.icon(
                onPressed: () => onChanged(GridColorConfig.defaults()),
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('恢复默认颜色'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 状态颜色行
// ═══════════════════════════════════════════════

class _StateColorRow extends StatelessWidget {
  final BirdCellState state;
  final Color color;
  final CellDisplayMode displayMode;
  final double fillOpacity;
  final ValueChanged<Color> onColorPicked;

  const _StateColorRow({
    required this.state,
    required this.color,
    required this.displayMode,
    required this.fillOpacity,
    required this.onColorPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sp = context.sp;
    final r = context.r;
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(r.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Expanded(
              child: Text(state.label, style: TextStyle(fontSize: 13))),
          Container(
            width: 48,
            height: 22,
            decoration: BoxDecoration(
              color: displayMode == CellDisplayMode.border
                  ? Colors.transparent
                  : color.withValues(alpha: fillOpacity),
              border: displayMode == CellDisplayMode.fill
                  ? null
                  : Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(r.sm),
            ),
          ),
          SizedBox(width: sp.sm),
          Icon(Icons.chevron_right,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final theme = Theme.of(context);
    final r = context.r;
    Color picked = color;
    showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${state.label} 颜色'),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((c) {
                  final selected = c.value == picked.value;
                  return GestureDetector(
                    onTap: () => setState(() => picked = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: displayMode == CellDisplayMode.border
                      ? Colors.transparent
                      : picked.withValues(alpha: fillOpacity),
                  border: displayMode == CellDisplayMode.fill
                      ? null
                      : Border.all(color: picked, width: 2),
                  borderRadius: BorderRadius.circular(r.md),
                ),
                child: Center(
                  child: Text('预览效果',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, picked),
              child: const Text('应用')),
        ],
      ),
    ).then((c) {
      if (c != null) onColorPicked(c);
    });
  }
}

// ═══════════════════════════════════════════════
// 输入偏好卡片
// ═══════════════════════════════════════════════

class _InputPrefsCard extends ConsumerWidget {
  const _InputPrefsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sp = context.sp;
    final cfg = ref.watch(weighInputConfigProvider);
    final notifier = ref.read(weighInputConfigProvider.notifier);

    // 滑块参数行样式：标题 + 当前值
    final paramLabelStyle =
        theme.textTheme.labelLarge ?? const TextStyle();
    final paramValueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: scheme.primary,
    );

    return Card(
      child: Padding(
        padding: sp.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, size: 22),
                SizedBox(width: sp.sm),
                Text(
                  '输入偏好',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: sp.xs),
            Text(
              '设置快速称重的默认输入方式和转盘参数',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: sp.lg),

            // ── 默认输入模式 ──
            Row(
              children: [
                Expanded(child: Text('默认输入模式', style: paramLabelStyle)),
                SegmentedButton<WeighInputMode>(
                  segments: WeighInputMode.values.map((m) {
                    return ButtonSegment<WeighInputMode>(
                      value: m,
                      label: Text(m.label, style: theme.textTheme.bodySmall),
                    );
                  }).toList(),
                  selected: {cfg.mode},
                  onSelectionChanged: (sel) => notifier.setMode(sel.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: scheme.primaryContainer,
                  ),
                ),
              ],
            ),
            SizedBox(height: sp.md),

            // ── 转盘位置 ──
            Row(
              children: [
                Expanded(child: Text('转盘位置', style: paramLabelStyle)),
                SegmentedButton<DialSide>(
                  segments: DialSide.values.map((s) {
                    return ButtonSegment<DialSide>(
                      value: s,
                      label: Text(s.label, style: theme.textTheme.bodySmall),
                      icon: Icon(
                        s == DialSide.left
                            ? Icons.swipe_left
                            : Icons.swipe_right,
                        size: 16,
                      ),
                    );
                  }).toList(),
                  selected: {cfg.dialSide},
                  onSelectionChanged: (sel) => notifier.setDialSide(sel.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: scheme.primaryContainer,
                  ),
                ),
              ],
            ),
            SizedBox(height: sp.lg),

            // ── 转盘灵敏度 ──
            _buildSliderSection(
              context: context,
              label: '转盘灵敏度',
              value: '${cfg.sensitivity.toStringAsFixed(0)}°',
              leftHint: '粗',
              rightHint: '细',
              help: '每刻度角度，值越小越灵敏（一圈=360°）',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.sensitivity,
                min: WeighInputConfig.sensitivityMin,
                max: WeighInputConfig.sensitivityMax,
                divisions: 20,
                label: '${cfg.sensitivity.toStringAsFixed(0)}°',
                onChanged: (v) => notifier.setSensitivity(v),
              ),
            ),
            SizedBox(height: sp.lg),

            // ── 速度阈值 ──
            _buildSliderSection(
              context: context,
              label: '速度阈值',
              value: '${cfg.speedThreshold.toStringAsFixed(0)}°/s',
              leftHint: '灵敏',
              rightHint: '迟钝',
              help: '慢/快的分界线，超过此速度触发快速档',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.speedThreshold,
                min: WeighInputConfig.speedThresholdMin,
                max: WeighInputConfig.speedThresholdMax,
                divisions: 10,
                label: '${cfg.speedThreshold.toStringAsFixed(0)}°/s',
                onChanged: (v) => notifier.setSpeedThreshold(v),
              ),
            ),
            SizedBox(height: sp.md),

            // ── 窗口大小 ──
            _buildSliderSection(
              context: context,
              label: '平滑窗口',
              value: '${cfg.windowSize}帧',
              leftHint: '灵敏',
              rightHint: '平缓',
              help: '滑动平均帧数，越大越平缓，越不易误触快档',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.windowSize.toDouble(),
                min: WeighInputConfig.windowSizeMin.toDouble(),
                max: WeighInputConfig.windowSizeMax.toDouble(),
                divisions: 9,
                label: '${cfg.windowSize}帧',
                onChanged: (v) => notifier.setWindowSize(v.round()),
              ),
            ),
            SizedBox(height: sp.md),

            // ── 快速步长 ──
            _buildSliderSection(
              context: context,
              label: '快速步长',
              value: '${cfg.fastStep.toStringAsFixed(1)}g',
              leftHint: '细',
              rightHint: '粗',
              help: '快速滑动时的步长（慢速始终 0.1g）',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.fastStep,
                min: WeighInputConfig.fastStepMin,
                max: WeighInputConfig.fastStepMax,
                divisions: 7,
                label: '${cfg.fastStep.toStringAsFixed(1)}g',
                onChanged: (v) => notifier.setFastStep(v),
              ),
            ),
            SizedBox(height: sp.lg),

            // ── 转盘宽度 ──
            _buildSliderSection(
              context: context,
              label: '转盘宽度',
              value: '${(cfg.dialWidthPercent * 100).round()}%',
              leftHint: '窄',
              rightHint: '宽',
              help: '转盘占屏幕宽度的百分比，影响图表可用空间',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.dialWidthPercent,
                min: WeighInputConfig.dialWidthPercentMin,
                max: WeighInputConfig.dialWidthPercentMax,
                divisions: 40,
                label: '${(cfg.dialWidthPercent * 100).round()}%',
                onChanged: (v) => notifier.setDialWidthPercent(v),
              ),
            ),
            SizedBox(height: sp.lg),

            // ── 弧线半径 ──
            _buildSliderSection(
              context: context,
              label: '弧线半径',
              value: '${(cfg.arcRadiusPercent * 100).round()}%',
              leftHint: '弯',
              rightHint: '直',
              help: '大圆半径占屏幕高度的百分比，越大弧线越平直',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.arcRadiusPercent,
                min: WeighInputConfig.arcRadiusPercentMin,
                max: WeighInputConfig.arcRadiusPercentMax,
                divisions: 35,
                label: '${(cfg.arcRadiusPercent * 100).round()}%',
                onChanged: (v) => notifier.setArcRadiusPercent(v),
              ),
            ),
            SizedBox(height: sp.lg),

            // ── 弧线粗细 ──
            _buildSliderSection(
              context: context,
              label: '弧线粗细',
              value: '${cfg.strokeWidth.round()}px',
              leftHint: '细',
              rightHint: '粗',
              help: '弧线轨道的描边宽度',
              valueStyle: paramValueStyle,
              slider: Slider(
                value: cfg.strokeWidth,
                min: WeighInputConfig.strokeWidthMin,
                max: WeighInputConfig.strokeWidthMax,
                divisions: 12,
                label: '${cfg.strokeWidth.round()}px',
                onChanged: (v) => notifier.setStrokeWidth(v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 通用滑块配置区块：标题+值行、滑块（两端 hint）、帮助说明。
  /// 统一了 6 个重复滑块的间距/字号/颜色 token。
  Widget _buildSliderSection({
    required BuildContext context,
    required String label,
    required String value,
    required String leftHint,
    required String rightHint,
    required String help,
    required TextStyle valueStyle,
    required Widget slider,
  }) {
    final theme = Theme.of(context);
    final sp = context.sp;
    final hintStyle = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: theme.textTheme.labelLarge),
          SizedBox(width: sp.sm),
          Text(value, style: valueStyle),
        ]),
        SizedBox(height: sp.xs),
        Row(children: [
          Text(leftHint, style: hintStyle),
          Expanded(child: slider),
          Text(rightHint, style: hintStyle),
        ]),
        Padding(
          padding: EdgeInsets.only(left: sp.xs),
          child: Text(help, style: hintStyle),
        ),
      ],
    );
  }
}
