import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../repositories/bird_repository.dart';
import '../../database/database.dart';
import 'bird_detail_screen.dart';
import '../weigh/weigh_screen.dart';
import '../worker/worker_screen.dart';

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
          onWeigh: () => _startWeighing(b.bird.roomId, b.bird.id),
        );
      },
    );
  }

  void _startWeighing(int? roomId, int birdId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WeighScreen(roomId: roomId, birdId: birdId)),
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

  void _showAddBirdDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final spList = await ref.read(allSpeciesProvider.future);
      final roomList = await ref.read(allRoomsProvider.future);
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      showDialog(
        context: context,
        builder: (ctx) => _AddBirdDialog(spList: spList, roomList: roomList),
      ).then((_) => ref.invalidate(allBirdsProvider));
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
  }
}

/// 新增鹦鹉弹窗
class _AddBirdDialog extends StatefulWidget {
  final List<Specy> spList;
  final List<Room> roomList;

  const _AddBirdDialog({required this.spList, required this.roomList});

  @override
  State<_AddBirdDialog> createState() => _AddBirdDialogState();
}

class _AddBirdDialogState extends State<_AddBirdDialog> {
  final _nameCtrl = TextEditingController();
  final _ringCtrl = TextEditingController();
  int? _selectedSpeciesId;
  int? _selectedRoomId;
  String _gender = '未知';
  DateTime _birthDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增鹦鹉'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '例如: 小绿',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ringCtrl,
              decoration: const InputDecoration(labelText: '脚环号 (选填)'),
            ),
            const SizedBox(height: 12),
            // 品种选择——用点击弹窗代替 Dropdown，避免 overlay 冲突
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
                      ? (widget.spList.any((s) => s.id == _selectedSpeciesId)
                          ? widget.spList.firstWhere((s) => s.id == _selectedSpeciesId).name
                          : '未知品种')
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
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('选择房间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        ListTile(
                          title: const Text('不分配房间'),
                          leading: const Icon(Icons.block),
                          selected: _selectedRoomId == null,
                          onTap: () {
                            setState(() => _selectedRoomId = null);
                            Navigator.pop(ctx);
                          },
                        ),
                        ...widget.roomList.map((r) => ListTile(
                          title: Text(r.name),
                          selected: _selectedRoomId == r.id,
                          onTap: () {
                            setState(() => _selectedRoomId = r.id);
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
                  labelText: '房间 (选填)',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedRoomId != null
                      ? (widget.roomList.any((r) => r.id == _selectedRoomId)
                          ? widget.roomList.firstWhere((r) => r.id == _selectedRoomId).name
                          : '未知房间')
                      : '不分配',
                  style: TextStyle(
                    color: _selectedRoomId != null ? null : Colors.grey,
                  ),
                ),
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
            final bird = await db.createBird(
              name: name,
              speciesId: _selectedSpeciesId!,
              birthDate: _birthDate,
              roomId: _selectedRoomId,
              ringNumber: _ringCtrl.text.trim().isEmpty ? null : _ringCtrl.text.trim(),
              gender: _gender,
            );
            final userId = ProviderScope.containerOf(context).read(workerProvider).userId;
            if (userId != null) {
              await ProviderScope.containerOf(context).read(syncQueueProvider).enqueue(
                userId: userId,
                action: 'create_bird',
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
          child: const Text('创建'),
        ),
      ],
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
                          Text('${w.weightG.toStringAsFixed(1)}g',
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
