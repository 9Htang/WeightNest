import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';
import '../../providers.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';
import '../worker/worker_screen.dart';


class BirdDetailScreen extends ConsumerWidget {
  final BirdWithDetails bird;

  const BirdDetailScreen({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weightsAsync = ref.watch(birdWeightsProvider(bird.bird.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(bird.bird.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑',
            onPressed: () => _showEditDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context, ref),
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
                              Text(bird.bird.name,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '${bird.species.name} · ${bird.bird.gender} · ${bird.growthStage}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(150)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    _InfoRow(label: '脚环号', value: bird.bird.ringNumber ?? '-'),
                    _InfoRow(label: '出生天数', value: '${bird.ageDays} 天'),
                    _InfoRow(label: '成长阶段', value: bird.growthStage),
                    _InfoRow(label: '所在房间', value: bird.room?.name ?? '未分配'),
                    _InfoRow(label: '状态', value: bird.bird.status),
                    if (bird.bird.notes != null && bird.bird.notes!.isNotEmpty)
                      _InfoRow(label: '备注', value: bird.bird.notes!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 体重曲线
            Text('体重趋势', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: weightsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败')),
                data: (weights) {
                  if (weights.length == 1) {
                    // 单点：显示大数字
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${weights.first.weightG.toStringAsFixed(1)}g',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('仅有一条记录，再称一次即可显示趋势',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  if (weights.length < 2) {
                    return const Center(child: Text('暂无记录'));
                  }
                  return _WeightChart(weights: weights);
                },
              ),
            ),

            const SizedBox(height: 16),

            // 历史记录
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
                          confirmDismiss: (_) => _confirmDeleteWeight(context, ref, w, bird.bird.uuid),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red.shade400,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: _WeightRow(
                            weight: w,
                            theme: theme,
                            onTap: () => _showEditWeightDialog(context, ref, w, bird.bird.uuid),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final spList = await ref.read(allSpeciesProvider.future);
      final roomList = await ref.read(allRoomsProvider.future);
      if (!context.mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => _EditBirdDialog(bird: bird, spList: spList, roomList: roomList),
      ).then((_) => ref.invalidate(allBirdsProvider));
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${bird.bird.name}」吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(databaseProvider).removeBird(bird.bird.id);
              final userId = ref.read(workerProvider).userId;
              if (userId != null) {
                await ref.read(syncQueueProvider).enqueue(
                  userId: userId,
                  action: 'delete_bird',
                  entityType: 'bird',
                  entityUuid: bird.bird.uuid,
                  payload: {'id': bird.bird.id, 'name': bird.bird.name},
                );
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
              ref.invalidate(allBirdsProvider);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteWeight(BuildContext context, WidgetRef ref, Weight weight, String birdUuid) async {
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
      final userId = ref.read(workerProvider).userId;
      if (userId != null) {
        await ref.read(syncQueueProvider).enqueue(
          userId: userId,
          action: 'delete_weight',
          entityType: 'weight',
          entityUuid: weight.uuid,
          payload: {'birdUuid': birdUuid, 'birdId': weight.birdId, 'weightG': weight.weightG, 'recordedAt': weight.recordedAt.toIso8601String()},
        );
      }
      await ref.read(databaseProvider).removeWeight(weight.id);
      ref.read(weightSavedProvider.notifier).state++;
    }
    return result ?? false;
  }

  void _showEditWeightDialog(BuildContext context, WidgetRef ref, Weight weight, String birdUuid) {
    showDialog(
      context: context,
      builder: (ctx) => _WeightEditDialog(weight: weight, onSave: (w, fasting, time) async {
        final db = ref.read(databaseProvider);
        await db.updateWeight(weight.id, weightG: w, isFasting: fasting, recordedAt: time);
        final userId = ref.read(workerProvider).userId;
        if (userId != null) {
          await ref.read(syncQueueProvider).enqueue(
            userId: userId,
            action: 'edit_weight',
            entityType: 'weight',
            entityUuid: weight.uuid,
            payload: {
              'birdUuid': birdUuid,
              'birdId': weight.birdId,
              'weightG': w,
              'isFasting': fasting,
              'recordedAt': time.toIso8601String(),
            },
          );
        }
        ref.read(weightSavedProvider.notifier).state++;
      }),
    );
  }
}

class _EditBirdDialog extends StatefulWidget {
  final BirdWithDetails bird;
  final List<Specy> spList;
  final List<Room> roomList;

  const _EditBirdDialog({required this.bird, required this.spList, required this.roomList});

  @override
  State<_EditBirdDialog> createState() => _EditBirdDialogState();
}

class _EditBirdDialogState extends State<_EditBirdDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ringCtrl;
  late int? _selectedSpeciesId;
  late int? _selectedRoomId;
  late String _gender;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bird.bird.name);
    _ringCtrl = TextEditingController(text: widget.bird.bird.ringNumber ?? '');
    _selectedSpeciesId = widget.bird.bird.speciesId;
    _selectedRoomId = widget.bird.bird.roomId;
    _gender = widget.bird.bird.gender;
    _birthDate = widget.bird.bird.birthDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑鹦鹉'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ringCtrl,
              decoration: const InputDecoration(labelText: '脚环号 (选填)'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('选择品种', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        ...widget.spList.map((s) => ListTile(
                          title: Text(s.name),
                          selected: _selectedSpeciesId == s.id,
                          onTap: () {
                            setState(() => _selectedSpeciesId = s.id);
                            Navigator.pop(ctx);
                          },
                        )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '品种',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedSpeciesId != null
                      ? (widget.spList.any((s) => s.id == _selectedSpeciesId) ? widget.spList.firstWhere((s) => s.id == _selectedSpeciesId).name : "??")
                      : '请选择品种',
                  style: TextStyle(
                    color: _selectedSpeciesId != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 房间选择
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(padding: EdgeInsets.all(16), child: Text('房间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        ListTile(title: const Text('不分配'), leading: const Icon(Icons.block), selected: _selectedRoomId == null, onTap: () { setState(() => _selectedRoomId = null); Navigator.pop(ctx); }),
                        ...widget.roomList.map((r) => ListTile(title: Text(r.name), selected: _selectedRoomId == r.id, onTap: () { setState(() => _selectedRoomId = r.id); Navigator.pop(ctx); })),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '房间', suffixIcon: Icon(Icons.arrow_drop_down)),
                child: Text(_selectedRoomId != null ? (widget.roomList.any((r) => r.id == _selectedRoomId) ? widget.roomList.firstWhere((r) => r.id == _selectedRoomId).name : "??") : '不分配', style: TextStyle(color: _selectedRoomId != null ? null : Colors.grey)),
              ),
            ),
            const SizedBox(height: 12),
            // 性别
            Row(
              children: ['公', '母', '未知'].map((g) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: g != '未知' ? 8 : 0),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: _gender == g,
                    onSelected: (v) => setState(() => _gender = g),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null && mounted) setState(() => _birthDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '出生日期'),
                child: Text(
                  '${_birthDate.year}-${_birthDate.month.toString().padLeft(2, '0')}-${_birthDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入名称'), behavior: SnackBarBehavior.floating),
              );
              return;
            }
            if (_selectedSpeciesId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请选择品种'), behavior: SnackBarBehavior.floating),
              );
              return;
            }
            final db = ProviderScope.containerOf(context).read(databaseProvider);
            final bird = await db.updateBird(
              widget.bird.bird.id,
              name: name,
              speciesId: _selectedSpeciesId,
              roomId: _selectedRoomId,
              birthDate: _birthDate,
              ringNumber: _ringCtrl.text.trim().isEmpty ? null : _ringCtrl.text.trim(),
              gender: _gender,
            );
            final userId = ProviderScope.containerOf(context).read(workerProvider).userId;
            if (userId != null) {
              await ProviderScope.containerOf(context).read(syncQueueProvider).enqueue(
                userId: userId,
                action: 'update_bird',
                entityType: 'bird',
                entityUuid: bird.uuid,
                payload: {
                  'name': name,
                  'speciesId': _selectedSpeciesId,
                  'roomId': _selectedRoomId,
                  'birthDate': _birthDate.toIso8601String(),
                  'ringNumber': _ringCtrl.text.trim().isEmpty ? null : _ringCtrl.text.trim(),
                  'gender': _gender,
                },
              );
            }
            if (mounted) Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(120), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

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

/// 简单折线图（用 CustomPaint 实现，避免依赖 fl_chart）
class _WeightChart extends StatelessWidget {
  final List<Weight> weights;

  const _WeightChart({required this.weights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 按时间升序
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
              // Y 轴标签
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
              // 图表
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _ChartPainter(
                          points: (() {
                            if (sorted.length == 1) {
                              return [const Offset(0.5, 0.5)];
                            }
                            // 时间轴比例：用实际时间戳映射 X 位置
                            final firstTime = sorted.first.recordedAt.millisecondsSinceEpoch.toDouble();
                            final lastTime = sorted.last.recordedAt.millisecondsSinceEpoch.toDouble();
                            var span = (lastTime - firstTime) / 1000 / 3600; // 小时
                            // 上限：最小跨度 12 小时，避免挤压
                            if (span < 12) span = 12;
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
                    // X 轴标签——首尾 + 中间 2 个关键日期
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

  _ChartPainter({
    required this.points,
    required this.values,
    required this.dates,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 1) return;

    // 逐段绘制，根据升降用不同颜色
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      // values[i-1] 是旧值, values[i] 是新值
      // 如果新值 >= 旧值 → 正常/增长 → 绿色；否则 → 下降 → 红色
      final isUp = values[i] >= values[i - 1];
      final segmentPaint = Paint()
        ..color = isUp ? Colors.green : Colors.red
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final midX = (prev.dx + curr.dx) / 2 * size.width;
      path.moveTo(prev.dx * size.width, prev.dy * size.height);
      path.cubicTo(
        midX, prev.dy * size.height,
        midX, curr.dy * size.height,
        curr.dx * size.width, curr.dy * size.height,
      );
      canvas.drawPath(path, segmentPaint);
    }

    // 数据点
    final dotPaint = Paint()..color = dotColor..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        4, dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor || oldDelegate.dotColor != dotColor;
}

/// 日期标签画笔——在 X 轴关键位置画日期
class _DateLabelPainter extends CustomPainter {
  final List<String> dates;
  final List<Offset> points;

  _DateLabelPainter({required this.dates, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    // 显示首尾 + 中间 2 个（均匀间隔）
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('空腹'),
            value: _isFasting,
            onChanged: (v) => setState(() => _isFasting = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('记录时间'),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_recordedAt)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _recordedAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_recordedAt),
              );
              if (time == null) return;
              setState(() {
                _recordedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
              });
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
