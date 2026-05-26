import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../repositories/bird_repository.dart';
import 'bird_detail_screen.dart';
import '../weigh/weigh_screen.dart';
import '../../../widgets/server_status_bar.dart';

/// 鹦鹉列表页 — 按房间分组、支持拖动排序
class BirdsScreen extends ConsumerStatefulWidget {
  final int? roomId;
  const BirdsScreen({super.key, this.roomId});

  @override
  ConsumerState<BirdsScreen> createState() => _BirdsScreenState();
}

class _BirdsScreenState extends ConsumerState<BirdsScreen> {
  String _searchText = '';
  int? _filterRoomId;

  @override
  void initState() {
    super.initState();
    _filterRoomId = widget.roomId;
  }

  @override
  Widget build(BuildContext context) {
    final birdsAsync = ref.watch(allBirdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('鹦鹉列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showRoomFilter(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBirdDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索名称或脚环号...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchText = ''),
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchText = v),
            ),
          ),

          // 列表
          Expanded(
            child: birdsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (birds) {
                final filtered = _filterBirds(birds);
                if (filtered.isEmpty) {
                  return const Center(child: Text('暂无鹦鹉'));
                }
                return _buildBirdList(context, filtered, ref);
              },
            ),
          ),
        ],
      ),
      persistentFooterButtons: const [ServerStatusBar()],
    );
  }

  List<BirdWithDetails> _filterBirds(List<BirdWithDetails> birds) {
    var result = birds;
    if (_filterRoomId != null) {
      result = result.where((b) => b.bird.roomId == _filterRoomId).toList();
    }
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      result = result.where((b) =>
          b.bird.name.toLowerCase().contains(q) ||
          (b.bird.ringNumber?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return result;
  }

  Widget _buildBirdList(BuildContext context, List<BirdWithDetails> birds, WidgetRef ref) {
    return ReorderableListView.builder(
      itemCount: birds.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final item = birds.removeAt(oldIndex);
        birds.insert(newIndex, item);
        setState(() {});
        // 持久化排序
        final orders = <int, int>{};
        for (int i = 0; i < birds.length; i++) {
          orders[birds[i].bird.id] = i;
        }
        final db = ref.read(databaseProvider);
        await db.updateSortOrders(orders);
      },
      itemBuilder: (context, index) {
        final b = birds[index];
        return _BirdListTile(
          key: ValueKey(b.bird.id),
          bird: b,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: b)),
          ),
          onWeigh: () => _startWeighing(b.bird.roomId),
        );
      },
    );
  }

  void _startWeighing(int? roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WeighScreen(roomId: roomId)),
    );
  }

  void _showRoomFilter(BuildContext context) {
    final roomsAsync = ref.watch(allRoomsProvider);
    roomsAsync.whenData((rooms) {
      showModalBottomSheet(
        context: this.context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('全部'),
                selected: _filterRoomId == null,
                onTap: () {
                  setState(() => _filterRoomId = null);
                  Navigator.pop(ctx);
                },
              ),
              ...rooms.map((r) => ListTile(
                    leading: const Icon(Icons.meeting_room_outlined),
                    title: Text(r.name),
                    selected: _filterRoomId == r.id,
                    onTap: () {
                      setState(() => _filterRoomId = r.id);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      );
    });
  }

  void _showAddBirdDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ringCtrl = TextEditingController();
    int? selectedSpeciesId;
    String gender = '未知';
    DateTime birthDate = DateTime.now();

    final speciesAsync = ref.read(allSpeciesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => speciesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败')),
        data: (spList) => StatefulBuilder(
          builder: (ctx, setInner) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16, right: 16, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('新增鹦鹉', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '名称', hintText: '例如: 小绿'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ringCtrl,
                  decoration: const InputDecoration(labelText: '脚环号 (选填)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: '品种'),
                  items: spList.map((s) => DropdownMenuItem(
                    value: s.id, child: Text(s.name),
                  )).toList(),
                  onChanged: (v) => selectedSpeciesId = v,
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['公', '母', '未知'].map((g) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: g != '未知' ? 8 : 0),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: gender == g,
                        onSelected: (v) => setInner(() => gender = g),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: birthDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null && ctx.mounted) setInner(() => birthDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '出生日期'),
                    child: Text(
                      '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    if (selectedSpeciesId == null) return;
                    final db = ref.read(databaseProvider);
                    await db.createBird(
                      name: name,
                      speciesId: selectedSpeciesId!,
                      birthDate: birthDate,
                      ringNumber: ringCtrl.text.trim().isEmpty ? null : ringCtrl.text.trim(),
                      gender: gender,
                    );
                    ref.invalidate(allBirdsProvider);
                    Navigator.pop(ctx);
                  },
                  child: const Text('创建'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 鹦鹉列表项
class _BirdListTile extends ConsumerWidget {
  final BirdWithDetails bird;
  final VoidCallback onTap;
  final VoidCallback onWeigh;

  const _BirdListTile({
    super.key,
    required this.bird,
    required this.onTap,
    required this.onWeigh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latestWeight = ref.watch(latestWeightProvider(bird.bird.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: 0,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                ),
              ),
              // 鸟头像
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _stageColor(bird.growthStage, theme),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    bird.growthStage == '雏鸟' ? '🐣' :
                    bird.growthStage == '幼鸟' ? '🐤' : '🦜',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bird.bird.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (bird.bird.ringNumber != null) ...[
                          const SizedBox(width: 6),
                          Text('#${bird.bird.ringNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bird.species.name} · ${bird.growthStage} · ${bird.ageDays}天',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(130)),
                    ),
                  ],
                ),
              ),
              // 体重
              latestWeight.when(
                data: (w) => w != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${w.weightG}g',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary)),
                          Text(_formatDate(w.recordedAt),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                        ],
                      )
                    : const Text('-', style: TextStyle(color: Colors.grey)),
                loading: () => const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('-'),
              ),
              const SizedBox(width: 4),
              // 快速称重
              IconButton(
                icon: const Icon(Icons.monitor_weight_outlined, size: 20),
                tooltip: '称重',
                onPressed: onWeigh,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stageColor(String stage, ThemeData theme) {
    switch (stage) {
      case '雏鸟': return Colors.orange.shade100;
      case '幼鸟': return Colors.green.shade100;
      default: return theme.colorScheme.primaryContainer;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
