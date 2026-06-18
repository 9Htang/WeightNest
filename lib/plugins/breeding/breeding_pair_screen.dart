import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weight_nest/core/plugin_registry.dart';
import 'package:weight_nest/database/database.dart';
import 'package:weight_nest/plugins/breeding/breeding_repository.dart';
import 'package:weight_nest/repositories/bird_repository.dart';
import 'breeding_record_screen.dart';

/// 配对管理主页 — 展示所有活跃配对
class BreedingPairListScreen extends StatefulWidget {
  const BreedingPairListScreen({super.key});

  @override
  State<BreedingPairListScreen> createState() => _BreedingPairListScreenState();
}

class _BreedingPairListScreenState extends State<BreedingPairListScreen> {
  AppDatabase? get _db => pluginRegistry.db;
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final db = _db;
    if (db == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('配对管理')),
        body: const Center(child: Text('数据库未初始化')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('配对管理')),
      body: FutureBuilder<List<({BreedingPair pair, Bird male, Bird female})>>(
        key: ValueKey('pairs_$_refreshKey'),
        future: db.getActivePairs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final pairs = snapshot.data ?? [];
          if (pairs.isEmpty) {
            return const Center(child: Text('暂无活跃配对'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pairs.length,
            itemBuilder: (context, index) => _PairCard(
              data: pairs[index],
              onTap: () => _openRecord(context, pairs[index].pair.id),
              onLongPress: () => _confirmSeparate(context, pairs[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openRecord(BuildContext context, int pairId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BreedingRecordDetailScreen(pairId: pairId),
    ));
  }

  void _confirmSeparate(BuildContext context, ({BreedingPair pair, Bird male, Bird female}) data) {
    final displayName = data.pair.pairName ?? '♂${data.male.name} × ♀${data.female.name}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解除配对'),
        content: Text('确定要解除「$displayName」的配对吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db?.separatePair(data.pair.id);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() => _refreshKey++);
            },
            child: const Text('解除'),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final db = _db;
    if (db == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _CreatePairSheet(
        db: db,
        onCreated: () {
          Navigator.pop(ctx);
          setState(() => _refreshKey++);
        },
      ),
    );
  }
}

/// 配对卡片
class _PairCard extends StatelessWidget {
  final ({BreedingPair pair, Bird male, Bird female}) data;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PairCard({required this.data, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = data.pair.pairName ?? '♂${data.male.name} × ♀${data.female.name}';
    final dateStr = DateFormat('yyyy-MM-dd').format(data.pair.pairedDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('配对日期: $dateStr',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    _ActiveStageBadge(pairId: data.pair.id),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// 在卡片内异步加载当前阶段标签
class _ActiveStageBadge extends StatelessWidget {
  final int pairId;
  const _ActiveStageBadge({required this.pairId});

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) return const SizedBox.shrink();

    return FutureBuilder<BreedingRecord?>(
      future: db.getActiveRecordForPair(pairId),
      builder: (context, snapshot) {
        final record = snapshot.data;
        if (record == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _stageChip(record.stage),
        );
      },
    );
  }

  Widget _stageChip(String stage) {
    final color = _stageColor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withAlpha(30),
      ),
      child: Text(stage,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  static Color _stageColor(String stage) {
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
}

/// 创建配对底部弹窗
class _CreatePairSheet extends StatefulWidget {
  final AppDatabase db;
  final VoidCallback onCreated;

  const _CreatePairSheet({required this.db, required this.onCreated});

  @override
  State<_CreatePairSheet> createState() => _CreatePairSheetState();
}

class _CreatePairSheetState extends State<_CreatePairSheet> {
  BirdWithDetails? _maleBird;
  BirdWithDetails? _femaleBird;
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  List<BirdWithDetails> _birds = [];
  bool _loadingBirds = true;

  @override
  void initState() {
    super.initState();
    _loadBirds();
  }

  Future<void> _loadBirds() async {
    try {
      final birds = await widget.db.getAllWithDetails();
      if (mounted) {
        setState(() {
          _birds = birds;
          _loadingBirds = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBirds = false);
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拖拽条
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),
              Text('创建配对',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (_loadingBirds)
                const Center(child: CircularProgressIndicator())
              else ...[
                // 公鸟选择
                DropdownButtonFormField<BirdWithDetails?>(
                  value: _maleBird,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: '公鸟', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('请选择公鸟')),
                    ..._birds
                        .where(
                            (b) => b.bird.gender == '公' && b != _femaleBird)
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b.bird.name))),
                  ],
                  onChanged: (v) => setState(() => _maleBird = v),
                ),
                const SizedBox(height: 12),

                // 母鸟选择
                DropdownButtonFormField<BirdWithDetails?>(
                  value: _femaleBird,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: '母鸟', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('请选择母鸟')),
                    ..._birds
                        .where(
                            (b) => b.bird.gender == '母' && b != _maleBird)
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b.bird.name))),
                  ],
                  onChanged: (v) => setState(() => _femaleBird = v),
                ),
                const SizedBox(height: 12),

                // 配对名称
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '配对名称（选填）',
                    hintText: '蓝公 × 绿母',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton.icon(
                  icon: const Icon(Icons.favorite, size: 18),
                  label: Text(_saving ? '创建中...' : '创建配对'),
                  onPressed: (_maleBird != null && _femaleBird != null && !_saving)
                      ? () => _createPair()
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPair() async {
    if (_maleBird == null || _femaleBird == null) return;
    setState(() => _saving = true);
    // 在 await 之前读取控制器值 —— await 期间底部弹窗可能被关闭导致控制器被 dispose
    final pairName = _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
    final maleId = _maleBird!.bird.id;
    final femaleId = _femaleBird!.bird.id;
    try {
      await widget.db.createPair(
        maleBirdId: maleId,
        femaleBirdId: femaleId,
        pairName: pairName,
      );
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e'),
              behavior: SnackBarBehavior.floating),
        );
        setState(() => _saving = false);
      }
    }
  }
}
