import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';
import '../../providers.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/enclosure_repository.dart';
import '../../repositories/weight_repository.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';

class BirdDetailScreen extends ConsumerStatefulWidget {
  final BirdWithDetails bird;
  final String? initialPluginId;

  const BirdDetailScreen({super.key, required this.bird, this.initialPluginId});

  @override
  ConsumerState<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends ConsumerState<BirdDetailScreen> {
  late BirdWithDetails _bird;

  @override
  void initState() {
    super.initState();
    _bird = widget.bird;
  }

  /// 更新本地状态并持久化到数据库
  Future<void> _save(Map<String, dynamic> fields) async {
    final db = ref.read(databaseProvider);
    await db.updateBird(
      _bird.bird.id,
      name: fields['name'] as String?,
      speciesId: fields['speciesId'] as int?,
      roomId: fields.containsKey('roomId') ? fields['roomId'] as int? : _bird.bird.roomId,
      enclosureId: fields.containsKey('enclosureId') ? fields['enclosureId'] as int? : _bird.bird.enclosureId,
      birthDate: fields['birthDate'] as DateTime?,
      gender: fields['gender'] as String?,
      status: fields['status'] as String?,
      notes: fields['notes'] as String?,
      ringNumber: fields['ringNumber'] as String?,
      manualBaselineG: fields.containsKey('manualBaselineG') ? fields['manualBaselineG'] as double? : _bird.bird.manualBaselineG,
      weaningOverride: fields.containsKey('weaningOverride') ? fields['weaningOverride'] as bool? : _bird.bird.weaningOverride,
    );
    // 刷新本地状态
    final updated = await db.getAllWithDetails();
    final fresh = updated.where((b) => b.bird.id == _bird.bird.id).firstOrNull;
    if (fresh != null && mounted) {
      setState(() => _bird = fresh);
      ref.invalidate(allBirdsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightsAsync = ref.watch(birdWeightsProvider(_bird.bird.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_bird.bird.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 头部：头像 + 名称 + 副标题
                    _EditableHeader(
                      bird: _bird,
                      onNameSaved: (name) => _save({'name': name}),
                      onSpeciesChanged: (spId) => _save({'speciesId': spId}),
                      onGenderChanged: (g) => _save({'gender': g}),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    _InfoRow(label: '脚环号', value: _bird.bird.ringNumber ?? '-', onTap: () => _editText(
                      label: '脚环号',
                      initial: _bird.bird.ringNumber ?? '',
                      hint: '选填',
                      onSaved: (v) => _save({'ringNumber': v.isEmpty ? null : v}),
                    )),
                    _InfoRow(label: '出生天数', value: '${_bird.ageDays} 天'),
                    _InfoRow(label: '成长阶段', value: _bird.growthStage),
                    _InfoRow(label: '所在房间', value: _bird.room?.name ?? '未分配', onTap: () => _pickRoom()),
                    _InfoRow(label: '所在容器', value: _bird.enclosure?.name ?? '未分配', onTap: () => _pickEnclosure()),
                    _InfoRow(label: '状态', value: _bird.bird.status, onTap: () => _pickStatus()),
                    _InfoRow(label: '出生日期', value: DateFormat('yyyy-MM-dd').format(_bird.bird.birthDate), onTap: () => _pickBirthDate()),
                    _InfoRow(
                      label: '备注',
                      value: (_bird.bird.notes != null && _bird.bird.notes!.isNotEmpty) ? _bird.bird.notes! : '+ 添加备注',
                      isHint: _bird.bird.notes == null || _bird.bird.notes!.isEmpty,
                      onTap: () => _editText(
                        label: '备注',
                        initial: _bird.bird.notes ?? '',
                        hint: '添加备注...',
                        multiline: true,
                        onSaved: (v) => _save({'notes': v.isEmpty ? null : v}),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 基准体重 & 断奶状态（仅称重插件启用时显示）
            if (pluginRegistry.getPlugin('weights')?.enabled == true) ...[
              _BaselineCard(
                bird: _bird,
                onBaselineSaved: (v) => _save({'manualBaselineG': v}),
                onWeaningChanged: (v) => _save({'weaningOverride': v}),
              ),
              const SizedBox(height: 16),
            ],

            // 插件详情区
            _PluginDetailTabs(birdId: _bird.bird.id, weightsAsync: weightsAsync, theme: theme, initialPluginId: widget.initialPluginId),

            // 历史记录
            if (pluginRegistry.getPlugin('weights')?.enabled == true) ...[
              const SizedBox(height: 16),
              Text('历史记录', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              weightsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败')),
                data: (weights) => weights.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('暂无体重记录'),
                      ))
                    : Column(
                        children: weights.map((w) {
                          return Dismissible(
                            key: ValueKey('weight_${w.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDeleteWeight(context, w, _bird.bird.uuid),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: _WeightRow(
                              weight: w,
                              theme: theme,
                              onTap: () => _showEditWeightDialog(context, w, _bird.bird.uuid),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 行内编辑器
  // ═══════════════════════════════════════════════

  /// 行内文本编辑（脚环号、备注）
  void _editText({
    required String label,
    required String initial,
    String hint = '',
    bool multiline = false,
    required void Function(String) onSaved,
  }) {
    final ctrl = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: multiline ? 3 : 1,
          decoration: InputDecoration(hintText: hint),
          textInputAction: multiline ? TextInputAction.newline : TextInputAction.done,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSaved(ctrl.text.trim());
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 房间选择
  Future<void> _pickRoom() async {
    final roomList = await ref.read(allRoomsProvider.future);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('选择房间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ListTile(
              title: const Text('不分配'),
              leading: const Icon(Icons.block),
              selected: _bird.bird.roomId == null,
              onTap: () { Navigator.pop(ctx); _save({'roomId': null, 'enclosureId': null}); },
            ),
            ...roomList.map((r) => ListTile(
              title: Text(r.name),
              selected: _bird.bird.roomId == r.id,
              onTap: () { Navigator.pop(ctx); _save({'roomId': r.id, 'enclosureId': null}); },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 容器选择
  Future<void> _pickEnclosure() async {
    if (_bird.bird.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先分配房间'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final enclosures = await db.getEnclosuresByRoom(_bird.bird.roomId!);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('选择容器', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ListTile(
              title: const Text('不放入容器'),
              leading: const Icon(Icons.block),
              selected: _bird.bird.enclosureId == null,
              onTap: () { Navigator.pop(ctx); _save({'enclosureId': null}); },
            ),
            ...enclosures.map((e) => ListTile(
              title: Text(e.name),
              selected: _bird.bird.enclosureId == e.id,
              onTap: () { Navigator.pop(ctx); _save({'enclosureId': e.id}); },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 状态选择
  void _pickStatus() {
    final presets = ['正常', '观察中', '治疗中', '隔离中'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('选择状态', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ...presets.map((s) => ListTile(
              title: Text(s),
              selected: _bird.bird.status == s,
              onTap: () { Navigator.pop(ctx); _save({'status': s}); },
            )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('自定义...'),
              onTap: () {
                Navigator.pop(ctx);
                final ctrl = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('自定义状态'),
                    content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: '输入状态')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('取消')),
                      FilledButton(onPressed: () { Navigator.pop(ctx2); _save({'status': ctrl.text.trim()}); }, child: const Text('确定')),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 出生日期选择
  Future<void> _pickBirthDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _bird.bird.birthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null && mounted) {
      _save({'birthDate': d});
    }
  }

  // ═══════════════════════════════════════════════
  // 删除相关
  // ═══════════════════════════════════════════════

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${_bird.bird.name}」吗？\n此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(databaseProvider).removeBird(_bird.bird.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    ).then((deleted) {
      if (deleted == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(allBirdsProvider);
            ref.invalidate(allRoomsProvider);
          }
        });
        if (context.mounted) Navigator.pop(context);
      }
    });
  }

  Future<bool> _confirmDeleteWeight(BuildContext context, Weight weight, String birdUuid) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 ${weight.weightG.toStringAsFixed(1)}g 的体重记录？'),
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
    if (result == true && context.mounted) {
      await ref.read(databaseProvider).removeWeight(weight.id);
      ref.read(weightSavedProvider.notifier).state++;
    }
    return result ?? false;
  }

  void _showEditWeightDialog(BuildContext context, Weight weight, String birdUuid) {
    showDialog(
      context: context,
      builder: (ctx) => _WeightEditDialog(weight: weight, onSave: (w, fasting, time) async {
        final db = ref.read(databaseProvider);
        await db.updateWeight(weight.id, weightG: w, isFasting: fasting, recordedAt: time);
        ref.read(weightSavedProvider.notifier).state++;
      }),
    );
  }
}

// ═══════════════════════════════════════════════
// 可编辑头部（名称 + 物种 + 性别）
// ═══════════════════════════════════════════════

class _EditableHeader extends StatefulWidget {
  final BirdWithDetails bird;
  final void Function(String) onNameSaved;
  final void Function(int) onSpeciesChanged;
  final void Function(String) onGenderChanged;

  const _EditableHeader({
    required this.bird,
    required this.onNameSaved,
    required this.onSpeciesChanged,
    required this.onGenderChanged,
  });

  @override
  State<_EditableHeader> createState() => _EditableHeaderState();
}

class _EditableHeaderState extends State<_EditableHeader> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;
  bool _showGender = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bird.bird.name);
  }

  @override
  void didUpdateWidget(_EditableHeader old) {
    super.didUpdateWidget(old);
    if (old.bird.bird.id != widget.bird.bird.id) {
      _nameCtrl.text = widget.bird.bird.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🦜', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称：点击进入编辑
                  if (_editingName)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                            onSubmitted: (_) => _confirmName(),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.check, size: 20, color: Colors.green), onPressed: _confirmName, visualDensity: VisualDensity.compact),
                        IconButton(icon: const Icon(Icons.close, size: 20, color: Colors.red), onPressed: () => setState(() { _editingName = false; _nameCtrl.text = widget.bird.bird.name; }), visualDensity: VisualDensity.compact),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _editingName = true),
                      child: Text(widget.bird.bird.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 4),
                  // 物种 + 性别 + 阶段
                  GestureDetector(
                    onTap: () => _pickSpecies(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.bird.species.name} · ${widget.bird.bird.gender} · ${widget.bird.growthStage}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16, color: theme.colorScheme.onSurface.withAlpha(100)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 性别切换
                  if (_showGender) ...[
                    const SizedBox(height: 4),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '公', label: Text('公')),
                        ButtonSegment(value: '母', label: Text('母')),
                        ButtonSegment(value: '未知', label: Text('未知')),
                      ],
                      selected: {widget.bird.bird.gender},
                      onSelectionChanged: (v) {
                        widget.onGenderChanged(v.first);
                        setState(() => _showGender = false);
                      },
                      showSelectedIcon: false,
                      style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: () => setState(() => _showGender = true),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('修改性别', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmName() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onNameSaved(name);
    setState(() => _editingName = false);
  }

  Future<void> _pickSpecies(BuildContext context) async {
    final spList = await ProviderScope.containerOf(context).read(allSpeciesProvider.future);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('选择品种', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ...spList.map((s) => ListTile(
              title: Text(s.name),
              selected: widget.bird.bird.speciesId == s.id,
              onTap: () { Navigator.pop(ctx); widget.onSpeciesChanged(s.id); },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 信息行
// ═══════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isHint;

  const _InfoRow({required this.label, required this.value, this.onTap, this.isHint = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label,
            style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(120), fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: isHint ? Colors.grey : null))),
          if (onTap != null)
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurface.withAlpha(60)),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: child);
    }
    return child;
  }
}

// ═══════════════════════════════════════════════
// 基准体重 & 断奶状态卡片（可编辑）
// ═══════════════════════════════════════════════

class _BaselineCard extends ConsumerWidget {
  final BirdWithDetails bird;
  final void Function(double?) onBaselineSaved;
  final void Function(bool?) onWeaningChanged;

  const _BaselineCard({required this.bird, required this.onBaselineSaved, required this.onWeaningChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weightsAsync = ref.watch(birdWeightsProvider(bird.bird.id));
    final weights = weightsAsync.valueOrNull ?? <Weight>[];

    // EWMA 基线
    double emaBaseline = 0;
    if (weights.isNotEmpty) {
      emaBaseline = weights.first.weightG;
      for (int i = 1; i < weights.length; i++) {
        emaBaseline = 0.2 * weights[i].weightG + 0.8 * emaBaseline;
      }
    }

    final manualB = bird.bird.manualBaselineG;
    final baseline = manualB ?? (weights.isNotEmpty ? emaBaseline : 0);
    final baselineLabel = manualB != null ? '手动设置' : '自动推断';

    // 断奶状态
    String weaningStatus;
    final weaningOverride = bird.bird.weaningOverride;
    if (weaningOverride == true) {
      weaningStatus = '强制断奶';
    } else if (weaningOverride == false) {
      weaningStatus = '强制正常';
    } else {
      final ageOk = bird.ageDays >= bird.species.nestlingEndDays - 5 &&
          bird.ageDays <= bird.species.juvenileEndDays;
      if (!ageOk) {
        weaningStatus = '正常（非断奶期）';
      } else if (weights.length < 3) {
        weaningStatus = '正常（数据不足）';
      } else {
        final peak = weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
        final latest = weights.last.weightG;
        final droppedFromPeak = latest < peak * 0.95;
        int recentDrops = 0;
        for (int i = weights.length - 1; i > 0 && i > weights.length - 4; i--) {
          if (weights[i].weightG < weights[i - 1].weightG) recentDrops++;
        }
        if (droppedFromPeak && recentDrops >= 2) {
          weaningStatus = '断奶期（自动检测）';
        } else {
          weaningStatus = '正常';
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bird.growthStage != '雏鸟')
              InkWell(
                onTap: () => _editBaseline(context),
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('基准体重', style: theme.textTheme.labelLarge),
                    const Spacer(),
                    Text('$baselineLabel ${baseline > 0 ? baseline.toStringAsFixed(1) + 'g' : '-'}',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurface.withAlpha(60)),
                  ],
                ),
              ),
            if (bird.growthStage != '雏鸟')
              const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickWeaning(context),
              child: Row(
                children: [
                  Icon(Icons.baby_changing_station_outlined, size: 18,
                      color: weaningStatus.contains('断奶')
                          ? Colors.orange
                          : theme.colorScheme.onSurface.withAlpha(120)),
                  const SizedBox(width: 6),
                  Text('断奶状态', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text(weaningStatus,
                      style: TextStyle(
                          fontSize: 13,
                          color: weaningStatus.contains('断奶')
                              ? Colors.orange
                              : theme.colorScheme.onSurface.withAlpha(150))),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurface.withAlpha(60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBaseline(BuildContext context) {
    final ctrl = TextEditingController(
      text: bird.bird.manualBaselineG?.toStringAsFixed(1) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('基准体重'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '基准体重 (g)',
            hintText: '留空则自动推断',
            suffixText: 'g',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final text = ctrl.text.trim();
              if (text.isEmpty) {
                onBaselineSaved(null); // 恢复自动推断
              } else {
                final v = double.tryParse(text);
                if (v == null || v <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入大于 0 的有效体重'), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }
                onBaselineSaved(v);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _pickWeaning(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('断奶模式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ListTile(
              leading: const Icon(Icons.auto_mode),
              title: const Text('自动检测'),
              subtitle: const Text('由算法根据体重变化自动判断'),
              selected: bird.bird.weaningOverride == null,
              onTap: () { Navigator.pop(ctx); onWeaningChanged(null); },
            ),
            ListTile(
              leading: const Icon(Icons.baby_changing_station),
              title: const Text('断奶期'),
              subtitle: const Text('强制标记为断奶状态'),
              selected: bird.bird.weaningOverride == true,
              onTap: () { Navigator.pop(ctx); onWeaningChanged(true); },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('正常'),
              subtitle: const Text('强制标记为非断奶状态（已断奶）'),
              selected: bird.bird.weaningOverride == false,
              onTap: () { Navigator.pop(ctx); onWeaningChanged(false); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 以下保持不变：体重行、图表、插件Tab、体重编辑
// ═══════════════════════════════════════════════

class _WeightRow extends StatelessWidget {
  final Weight weight;
  final ThemeData theme;
  final VoidCallback? onTap;
  const _WeightRow({required this.weight, required this.theme, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MM-dd HH:mm').format(weight.recordedAt);
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: theme.textTheme.bodySmall),
                  if (weight.notes != null && weight.notes!.isNotEmpty)
                    Text(weight.notes!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            if (weight.isFasting)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Chip(label: Text('空腹', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
              ),
            Text(
              '${weight.weightG.toStringAsFixed(1)}g',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: card);
  }
}

class _WeightChart extends StatelessWidget {
  final List<Weight> weights;
  const _WeightChart({required this.weights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Weight>.from(weights)..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final minW = (sorted.map((w) => w.weightG).reduce((a, b) => a < b ? a : b) - 5);
    final maxW = (sorted.map((w) => w.weightG).reduce((a, b) => a > b ? a : b) + 5);
    final range = maxW - minW;
    if (range <= 0) return const SizedBox();

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 20),
          child: SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${maxW.toStringAsFixed(0)}g', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
                  Text('${((maxW + minW) / 2).toStringAsFixed(0)}g', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
                  Text('${minW.toStringAsFixed(0)}g', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _ChartPainter(
                          points: (() {
                            if (sorted.length == 1) return [const Offset(0.5, 0.5)];
                            final firstTime = sorted.first.recordedAt.millisecondsSinceEpoch.toDouble();
                            final lastTime = sorted.last.recordedAt.millisecondsSinceEpoch.toDouble();
                            return sorted.map((w) {
                              final t = w.recordedAt.millisecondsSinceEpoch.toDouble();
                              final x = sorted.length > 1
                                  ? (t - firstTime) / (lastTime - firstTime)
                                  : 0.5;
                              final y = 1 - ((w.weightG - minW) / range);
                              return Offset(x, y);
                            }).toList();
                          })(),
                          values: sorted.map((w) => w.weightG).toList(),
                          dates: sorted.map((w) => '${w.recordedAt.month}/${w.recordedAt.day}').toList(),
                          lineColor: theme.colorScheme.primary,
                          dotColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 14,
                      child: CustomPaint(
                        size: const Size(double.infinity, 14),
                        painter: _DateLabelPainter(
                          dates: sorted.map((w) => '${w.recordedAt.month}/${w.recordedAt.day}').toList(),
                          points: (() {
                            if (sorted.length == 1) return [const Offset(0.5, 0)];
                            final firstTime = sorted.first.recordedAt.millisecondsSinceEpoch.toDouble();
                            final lastTime = sorted.last.recordedAt.millisecondsSinceEpoch.toDouble();
                            return sorted.map((w) {
                              final t = w.recordedAt.millisecondsSinceEpoch.toDouble();
                              final x = (t - firstTime) / (lastTime - firstTime);
                              return Offset(x, 0);
                            }).toList();
                          })(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Offset> points;
  final List<double> values;
  final List<String> dates;
  final Color lineColor;
  final Color dotColor;

  _ChartPainter({required this.points, required this.values, required this.dates, required this.lineColor, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final isUp = values[i] >= values[i - 1];
      final segmentPaint = Paint()
        ..color = isUp ? Colors.green : Colors.red
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      final midX = (prev.dx + curr.dx) / 2 * size.width;
      path.moveTo(prev.dx * size.width, prev.dy * size.height);
      path.cubicTo(midX, prev.dy * size.height, midX, curr.dy * size.height, curr.dx * size.width, curr.dy * size.height);
      canvas.drawPath(path, segmentPaint);
    }
    final dotPaint = Paint()..color = dotColor..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor || oldDelegate.dotColor != dotColor;
}

class _DateLabelPainter extends CustomPainter {
  final List<String> dates;
  final List<Offset> points;

  _DateLabelPainter({required this.dates, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final indices = <int>[0, points.length - 1];
    if (points.length > 3) indices.insert(1, points.length ~/ 3);
    if (points.length > 4) indices.insert(2, points.length * 2 ~/ 3);

    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (final i in indices) {
      if (i >= points.length) continue;
      tp.text = TextSpan(text: dates[i], style: const TextStyle(fontSize: 9, color: Colors.grey));
      tp.layout();
      final x = points[i].dx * size.width - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0, size.width - tp.width), 0));
    }
  }

  @override
  bool shouldRepaint(covariant _DateLabelPainter oldDelegate) =>
      oldDelegate.dates != dates || oldDelegate.points != points;
}

class _PluginDetailTabs extends StatefulWidget {
  final int birdId;
  final AsyncValue<List<Weight>> weightsAsync;
  final ThemeData theme;
  final String? initialPluginId;

  const _PluginDetailTabs({required this.birdId, required this.weightsAsync, required this.theme, this.initialPluginId});

  @override
  State<_PluginDetailTabs> createState() => _PluginDetailTabsState();
}

class _PluginDetailTabsState extends State<_PluginDetailTabs> {
  int _selectedIndex = 0;
  List<DetailSection> _sections = [];
  Map<String, int> _pluginFirstTab = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initSections();
      _initialized = true;
    }
  }

  void _initSections() {
    final sections = <DetailSection>[];
    final pluginFirstTab = <String, int>{};
    for (final plugin in pluginRegistry.enabledPlugins) {
      final pluginSections = plugin.buildDetailSections(widget.birdId);
      if (pluginSections.isNotEmpty) pluginFirstTab[plugin.id] = sections.length;
      sections.addAll(pluginSections);
    }
    sections.sort((a, b) => a.priority.compareTo(b.priority));

    pluginFirstTab.clear();
    for (final plugin in pluginRegistry.enabledPlugins) {
      final pluginSections = plugin.buildDetailSections(widget.birdId);
      if (pluginSections.isEmpty) continue;
      final minPriority = pluginSections.map((s) => s.priority).reduce((a, b) => a < b ? a : b);
      final idx = sections.indexWhere((s) => s.priority == minPriority);
      if (idx >= 0) pluginFirstTab[plugin.id] = idx;
    }

    _sections = sections;
    _pluginFirstTab = pluginFirstTab;
    if (widget.initialPluginId != null) {
      _selectedIndex = (pluginFirstTab[widget.initialPluginId] ?? 0).clamp(0, sections.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty) {
      if (pluginRegistry.getPlugin('weights')?.enabled != true) return const SizedBox.shrink();
      return SizedBox(
        height: 260,
        child: widget.weightsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败')),
          data: (weights) => _buildWeightChart(weights),
        ),
      );
    }

    if (_sections.length == 1) return _sections.first.child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: List.generate(_sections.length, (i) {
              final s = _sections[i];
              final selected = i == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.icon != null) ...[
                        Icon(s.icon, size: 16, color: selected ? widget.theme.colorScheme.primary : null),
                        const SizedBox(width: 4),
                      ],
                      Text(s.title, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: selected,
                  onSelected: (v) {
                    if (v) setState(() => _selectedIndex = i);
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 400,
          child: IndexedStack(
            index: _selectedIndex,
            children: _sections.map((s) => SingleChildScrollView(child: s.child)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(List<Weight> weights) {
    if (weights.length == 1) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${weights.first.weightG.toStringAsFixed(1)}g',
              style: widget.theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: widget.theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('仅有一条记录，再称一次即可显示趋势', style: widget.theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }
    if (weights.length < 2) return const Center(child: Text('暂无记录'));
    return _WeightChart(weights: weights);
  }
}

class _WeightEditDialog extends StatefulWidget {
  final Weight weight;
  final void Function(double weightG, bool isFasting, DateTime recordedAt) onSave;

  const _WeightEditDialog({required this.weight, required this.onSave});

  @override
  State<_WeightEditDialog> createState() => _WeightEditDialogState();
}

class _WeightEditDialogState extends State<_WeightEditDialog> {
  late TextEditingController _weightCtrl;
  late bool _isFasting;
  late DateTime _recordedAt;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.weight.weightG.toStringAsFixed(1));
    _isFasting = widget.weight.isFasting;
    _recordedAt = widget.weight.recordedAt;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑体重记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '体重 (g)', suffixText: 'g'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('空腹'), value: _isFasting, onChanged: (v) => setState(() => _isFasting = v)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('记录时间'),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_recordedAt)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _recordedAt, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (date == null || !mounted) return;
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_recordedAt));
              if (time == null) return;
              setState(() => _recordedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final w = double.tryParse(_weightCtrl.text);
            if (w == null || w <= 0) return;
            widget.onSave(w, _isFasting, _recordedAt);
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
