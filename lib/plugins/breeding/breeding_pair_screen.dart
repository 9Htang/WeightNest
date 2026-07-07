import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weight_nest/core/plugin_registry.dart';
import 'package:weight_nest/database/database.dart';
import 'package:weight_nest/plugins/breeding/breeding_repository.dart';
import 'package:weight_nest/repositories/bird_repository.dart';
import 'package:weight_nest/theme/app_tokens.dart';
import 'package:weight_nest/theme/category_colors.dart';
import 'package:weight_nest/widgets/bird_picker_sheet.dart';
import 'package:weight_nest/widgets/list/app_list_card.dart';
import 'package:weight_nest/widgets/list/empty_state.dart';
import 'breeding_record_screen.dart';

/// 配对管理主页 — 展示所有活跃配对
class BreedingPairListScreen extends StatefulWidget {
  const BreedingPairListScreen({super.key});

  @override
  State<BreedingPairListScreen> createState() => _BreedingPairListScreenState();
}

class _BreedingPairListScreenState extends State<BreedingPairListScreen> {
  AppDatabase? get _db => pluginRegistry.db;

  // Cache the load Future in State. Refreshing swaps only the Future (and
  // triggers FutureBuilder to re-subscribe) without changing the widget's key,
  // so the FutureBuilder and its subtree are reconciled in place instead of
  // being torn down and rebuilt from scratch.
  Future<List<({BreedingPair pair, Bird male, Bird female})>>? _pairsFuture;

  @override
  void initState() {
    super.initState();
    _pairsFuture = _db?.getActivePairs();
  }

  void _reload() {
    setState(() {
      _pairsFuture = _db?.getActivePairs();
    });
  }

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
        future: _pairsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final pairs = snapshot.data ?? [];
          if (pairs.isEmpty) {
            return EmptyState(
              icon: const Icon(Icons.favorite_border, size: 56),
              message: '暂无活跃配对',
              hint: '点击右下角 + 创建配对',
            );
          }
          return ListView.builder(
            padding: context.sp.paddingLg,
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
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BreedingRecordDetailScreen(pairId: pairId),
        ));
  }

  void _confirmSeparate(BuildContext context,
      ({BreedingPair pair, Bird male, Bird female}) data) {
    final displayName =
        data.pair.pairName ?? '♂${data.male.name} × ♀${data.female.name}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解除配对'),
        content: Text('确定要解除「$displayName」的配对吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db?.separatePair(data.pair.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _reload();
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
          _reload();
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

  const _PairCard(
      {required this.data, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sp = context.sp;
    final displayName =
        data.pair.pairName ?? '♂${data.male.name} × ♀${data.female.name}';
    final dateStr = DateFormat('yyyy-MM-dd').format(data.pair.pairedDate);

    return AppListCard(
      title: Text(displayName,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('配对日期: $dateStr', style: theme.textTheme.bodySmall),
          SizedBox(height: sp.xs),
          _ActiveStageBadge(pairId: data.pair.id),
        ],
      ),
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant.withAlpha(context.a.medium)),
      onTap: onTap,
      onLongPress: onLongPress,
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
          child: _stageChip(context, record.stage),
        );
      },
    );
  }

  Widget _stageChip(BuildContext context, String stage) {
    final theme = Theme.of(context);
    final r = context.r;
    final (fg, bg) = CategoryColors.forCategory(theme.colorScheme, stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: r.bXs,
        color: bg,
      ),
      child: Text(stage,
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
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
                InkWell(
                  onTap: () async {
                    final bird = await BirdPickerSheet.show(
                      context,
                      title: '选择公鸟',
                      birds: _birds,
                      genderFilter: {'公'},
                      excludeBirdId: _femaleBird?.bird.id,
                      showSpeciesFilter: true,
                      showStageFilter: true,
                    );
                    if (bird != null && mounted) {
                      setState(() => _maleBird = bird);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '公鸟',
                      hintText: '请选择公鸟',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(),
                    ),
                    isEmpty: _maleBird == null,
                    child: _maleBird != null
                        ? Text(_maleBird!.bird.name)
                        : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),

                // 母鸟选择
                InkWell(
                  onTap: () async {
                    final bird = await BirdPickerSheet.show(
                      context,
                      title: '选择母鸟',
                      birds: _birds,
                      genderFilter: {'母'},
                      excludeBirdId: _maleBird?.bird.id,
                      showSpeciesFilter: true,
                      showStageFilter: true,
                    );
                    if (bird != null && mounted) {
                      setState(() => _femaleBird = bird);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '母鸟',
                      hintText: '请选择母鸟',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(),
                    ),
                    isEmpty: _femaleBird == null,
                    child: _femaleBird != null
                        ? Text(_femaleBird!.bird.name)
                        : const SizedBox.shrink(),
                  ),
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
                  onPressed:
                      (_maleBird != null && _femaleBird != null && !_saving)
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
    final pairName =
        _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
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
          SnackBar(
              content: Text('创建失败: $e'), behavior: SnackBarBehavior.floating),
        );
        setState(() => _saving = false);
      }
    }
  }
}
