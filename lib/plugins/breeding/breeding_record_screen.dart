import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weight_nest/core/app_clock.dart';
import 'package:weight_nest/core/plugin_registry.dart';
import 'package:weight_nest/database/database.dart';
import 'package:weight_nest/plugins/breeding/breeding_repository.dart';
import 'package:weight_nest/repositories/bird_repository.dart';
import 'package:weight_nest/screens/birds/bird_detail_screen.dart';

/// 繁育记录详情 — 展示配对信息、阶段推进、蛋记录、踩背记录
class BreedingRecordDetailScreen extends StatefulWidget {
  final int pairId;

  const BreedingRecordDetailScreen({super.key, required this.pairId});

  @override
  State<BreedingRecordDetailScreen> createState() =>
      _BreedingRecordDetailScreenState();
}

class _BreedingRecordDetailScreenState
    extends State<BreedingRecordDetailScreen> {
  AppDatabase? get _db => pluginRegistry.db;

  bool _loading = true;
  String? _error;

  BreedingPair? _pair;
  Bird? _male;
  Bird? _female;
  BreedingRecord? _record;
  List<Egg> _eggs = [];
  List<MatingEvent> _matingEvents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = _db;
    if (db == null) {
      if (mounted) setState(() => _error = '数据库未初始化');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pair = await db.getPairById(widget.pairId);
      if (pair == null) {
        if (mounted) setState(() {
          _error = '未找到该配对';
          _loading = false;
        });
        return;
      }

      final male = await db.getBirdById(pair.maleBirdId);
      final female = await db.getBirdById(pair.femaleBirdId);
      final record = await db.getActiveRecordForPair(pair.id);

      List<Egg> eggs = [];
      List<MatingEvent> matingEvents = [];

      if (record != null) {
        eggs = await db.getEggsByRecord(record.id);
        matingEvents = await db.getMatingEventsByRecord(record.id);
      }

      if (mounted) {
        setState(() {
          _pair = pair;
          _male = male;
          _female = female;
          _record = record;
          _eggs = eggs;
          _matingEvents = matingEvents;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  String get _displayName {
    if (_pair == null) return '';
    return _pair!.pairName ??
        '♂${_male?.name ?? "?"} × ♀${_female?.name ?? "?"}';
  }

  bool get _isFinished => _record?.stage == '已完结';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_displayName)),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card 1: 配对信息 + 阶段进度 ──
            _buildPairInfoCard(theme),
            const SizedBox(height: 12),

            // ── Card 2: 蛋的记录 ──
            _buildEggsCard(theme),
            const SizedBox(height: 12),

            // ── Card 3: 踩背记录 ──
            _buildMatingEventsCard(theme),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 卡片 1: 配对信息 + 阶段进度
  // ═══════════════════════════════════════════════

  Widget _buildPairInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 公母鸟名称（可点击跳转）
            Row(
              children: [
                Expanded(
                  child: _birdTile(
                    icon: const Icon(Icons.male, color: Colors.blue, size: 20),
                    label: '公鸟',
                    birdId: _pair?.maleBirdId,
                    birdName: _male?.name,
                  ),
                ),
                const SizedBox(width: 8),
                Text('×',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: _birdTile(
                    icon: const Icon(Icons.female, color: Colors.pink, size: 20),
                    label: '母鸟',
                    birdId: _pair?.femaleBirdId,
                    birdName: _female?.name,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 阶段进度条
            Text('当前阶段',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildStageIndicator(),

            if (_record != null) ...[
              const SizedBox(height: 16),

              // 开始日期
              Text(
                '开始日期: ${DateFormat('yyyy-MM-dd').format(_record!.startDate)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              if (_record!.endDate != null)
                Text(
                  '结束日期: ${DateFormat('yyyy-MM-dd').format(_record!.endDate!)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              if (_record!.endReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '完结原因: ${_record!.endReason}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),

              const SizedBox(height: 16),

              // 操作按钮
              if (!_isFinished) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('推进阶段'),
                        onPressed: _record!.stage == '育雏'
                            ? null
                            : () => _advanceStage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('提前完结'),
                        onPressed: () => _showFinishDialog(context),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('开始繁育'),
                  onPressed: () => _startBreeding(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _birdTile({
    required Widget icon,
    required String label,
    int? birdId,
    String? birdName,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: birdId != null && _db != null
          ? () => _navigateToBird(context, birdId)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(birdName ?? '未知',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator() {
    const stages = ['配对', '产蛋', '孵化', '育雏', '已完结'];
    final currentIdx = _record != null
        ? stages.indexOf(_record!.stage)
        : -1;

    return Row(
      children: List.generate(stages.length, (i) {
        final isCurrent = i == currentIdx;
        final isPast = i < currentIdx;
        final isLast = i == stages.length - 1;

        final Color chipColor;
        if (isCurrent) {
          chipColor = _stageColor(stages[i]);
        } else if (isPast) {
          chipColor = Colors.green;
        } else {
          chipColor = Colors.grey.shade300;
        }

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: chipColor.withAlpha(isCurrent || isPast ? 30 : 10),
                    border: isCurrent
                        ? Border.all(color: chipColor, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    stages[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent || isPast
                          ? chipColor
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.chevron_right,
                      size: 14, color: Colors.grey.shade400),
                ),
            ],
          ),
        );
      }),
    );
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case '配对':
        return Colors.blue;
      case '产蛋':
        return Colors.orange;
      case '孵化':
        return Colors.purple;
      case '育雏':
        return Colors.teal;
      case '已完结':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // ═══════════════════════════════════════════════
  // 卡片 2: 蛋的记录
  // ═══════════════════════════════════════════════

  Widget _buildEggsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('蛋的记录',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加蛋'),
                  onPressed: _record != null && !_isFinished
                      ? () => _addEgg(context)
                      : null,
                ),
              ],
            ),
            if (_record == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('请先开始繁育记录',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else if (_eggs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('暂无蛋的记录',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._eggs.map((egg) => _EggTile(
                    egg: egg,
                    isFinished: _isFinished,
                    onTap: () => _updateEgg(context, egg),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _addEgg(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: AppClock.now,
      firstDate: DateTime(2020),
      lastDate: AppClock.now,
      helpText: '选择产蛋日期',
    );
    if (date == null || !mounted || _record == null) return;

    try {
      await _db!.addEgg(_record!.id, laidDate: date);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _updateEgg(BuildContext context, Egg egg) async {
    String selectedStatus = egg.status;
    DateTime? hatchDate = egg.hatchDate;
    bool showHatchPicker = selectedStatus == '已出壳';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('更新蛋状态'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: '状态'),
                items: ['孵化中', '已出壳', '未受精', '损坏']
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setDlg(() {
                    selectedStatus = v!;
                    showHatchPicker = v == '已出壳';
                    if (!showHatchPicker) hatchDate = null;
                  });
                },
              ),
              if (showHatchPicker) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: hatchDate ?? AppClock.now,
                      firstDate: DateTime(2020),
                      lastDate: AppClock.now,
                      helpText: '选择出壳日期',
                    );
                    if (d != null) setDlg(() => hatchDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '出壳日期',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(hatchDate != null
                        ? DateFormat('yyyy-MM-dd').format(hatchDate!)
                        : '请选择'),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                await _db!.updateEggStatus(egg.id, selectedStatus,
                    hatchDate: hatchDate);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 卡片 3: 踩背记录
  // ═══════════════════════════════════════════════

  Widget _buildMatingEventsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('踩背记录',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('记录踩背'),
                  onPressed: _record != null && !_isFinished
                      ? () => _addMatingEvent(context)
                      : null,
                ),
              ],
            ),
            if (_record == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('请先开始繁育记录',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else if (_matingEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('暂无踩背记录',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._matingEvents.map((event) => _MatingEventTile(event: event)),
          ],
        ),
      ),
    );
  }

  Future<void> _addMatingEvent(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: AppClock.now,
      firstDate: DateTime(2020),
      lastDate: AppClock.now,
      helpText: '选择观察日期',
    );
    if (date == null || !mounted || _record == null) return;

    try {
      await _db!.addMatingEvent(_record!.id, observedDate: date);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════
  // 操作
  // ═══════════════════════════════════════════════

  Future<void> _startBreeding() async {
    try {
      await _db!.createBreedingRecord(widget.pairId);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _advanceStage() async {
    if (_record == null) return;
    try {
      await _db!.advanceStage(_record!.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showFinishDialog(BuildContext context) {
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('提前完结'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请选择完结原因：'),
              const SizedBox(height: 12),
              ...['正常完结', '亲鸟弃窝', '人工掏窝', '其他'].map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (v) => setDlg(() => selectedReason = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      await _db!.finishBreeding(_record!.id,
                          reason: selectedReason);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
              child: const Text('确认完结'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 导航
  // ═══════════════════════════════════════════════

  Future<void> _navigateToBird(BuildContext context, int birdId) async {
    final db = _db;
    if (db == null) return;
    final birdWithDetails = await db.getWithDetails(birdId);
    if (!mounted || birdWithDetails == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BirdDetailScreen(
        bird: birdWithDetails,
        initialPluginId: 'breeding',
      ),
    ));
  }
}

// ═══════════════════════════════════════════════
// 蛋记录条目
// ═══════════════════════════════════════════════

class _EggTile extends StatelessWidget {
  final Egg egg;
  final bool isFinished;
  final VoidCallback onTap;

  const _EggTile({
    required this.egg,
    required this.isFinished,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _eggStatusColor(egg.status);
    final laidStr = DateFormat('MM-dd').format(egg.laidDate);
    final hatchStr =
        egg.hatchDate != null ? DateFormat('MM-dd').format(egg.hatchDate!) : null;

    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isFinished ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('产蛋: $laidStr',
                          style: theme.textTheme.bodyMedium),
                      if (hatchStr != null) ...[
                        const SizedBox(width: 8),
                        Text('出壳: $hatchStr',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ]),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: statusColor.withAlpha(25),
                ),
                child: Text(egg.status,
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _eggStatusColor(String status) {
    switch (status) {
      case '孵化中':
        return Colors.orange;
      case '已出壳':
        return Colors.green;
      case '未受精':
        return Colors.grey;
      case '损坏':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ═══════════════════════════════════════════════
// 踩背记录条目
// ═══════════════════════════════════════════════

class _MatingEventTile extends StatelessWidget {
  final MatingEvent event;

  const _MatingEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(event.observedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.favorite, size: 16, color: Colors.pink.shade300),
          const SizedBox(width: 8),
          Text(dateStr,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(event.notes!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}
