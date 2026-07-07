import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_clock.dart';
import '../../providers.dart';
import '../../core/plugin_registry.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/enclosure_repository.dart';
import '../../repositories/task_repository.dart';
import '../../database/database.dart';
import '../../services/bird_export_service.dart';
import '../../widgets/bird_list_tile.dart';
import '../../widgets/bird_search_bar.dart';
import 'bird_detail_screen.dart';
import '../weigh/weigh_grid_screen.dart';

/// 鹦鹉列表页 — 按房间分组、支持拖动排序
class BirdsScreen extends ConsumerStatefulWidget {
  final int? roomId;
  const BirdsScreen({super.key, this.roomId});

  @override
  ConsumerState<BirdsScreen> createState() => _BirdsScreenState();
}

class _BirdsScreenState extends ConsumerState<BirdsScreen> {
  String _searchText = '';
  Set<int> _filterSpeciesIds = {};
  Set<String> _filterPhysioStages = {};
  Set<String> _filterGenders = {};
  Set<int> _filterRoomIds = {};
  bool _selecting = false;
  final _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _filterRoomIds.add(widget.roomId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birdsAsync = ref.watch(allBirdsProvider);
    final isPro = ref.watch(premiumStatusProvider) == PremiumStatus.pro;

    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: TextButton(
                onPressed: () => setState(() {
                  _selecting = false;
                  _selectedIds.clear();
                }),
                child: const Text('取消'),
              ),
              title: Text('已选择 ${_selectedIds.length} 只'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      birdsAsync.whenData((birds) {
                        final filtered = _filterBirds(birds);
                        final allSelected = filtered
                            .every((b) => _selectedIds.contains(b.bird.id));
                        if (allSelected) {
                          for (final b in filtered) {
                            _selectedIds.remove(b.bird.id);
                          }
                        } else {
                          for (final b in filtered) {
                            _selectedIds.add(b.bird.id);
                          }
                        }
                      });
                    });
                  },
                  child: const Text('全选'),
                ),
              ],
            )
          : AppBar(
              title: const Text('鹦鹉列表'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: '导出',
                  onPressed: () => _onExportTap(isPro),
                ),
              ],
            ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddBirdDialog(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: _selecting
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : () => _doExport(),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: Text('导出选中 (${_selectedIds.length})'),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // 搜索 + 多字段过滤
          BirdSearchBar(
            showSearchBox: true,
            showGenderFilter: true,
            showSpeciesFilter: true,
            showStageFilter: true,
            showRoomFilter: true,
            onChanged: ({
              required searchText,
              required genders,
              required speciesIds,
              required stages,
              required roomIds,
            }) =>
                setState(() {
              _searchText = searchText;
              _filterGenders = genders;
              _filterSpeciesIds = speciesIds;
              _filterPhysioStages = stages;
              _filterRoomIds = roomIds;
            }),
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
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      result = result
          .where((b) =>
              b.bird.name.toLowerCase().contains(q) ||
              (b.bird.ringNumber?.toLowerCase().contains(q) ?? false) ||
              b.physioStage.toLowerCase().contains(q))
          .toList();
    }
    if (_filterSpeciesIds.isNotEmpty) {
      result =
          result.where((b) => _filterSpeciesIds.contains(b.bird.speciesId)).toList();
    }
    if (_filterPhysioStages.isNotEmpty) {
      result = result
          .where((b) => _filterPhysioStages.contains(b.physioStage))
          .toList();
    }
    if (_filterGenders.isNotEmpty) {
      result = result
          .where((b) => _filterGenders.contains(b.bird.gender))
          .toList();
    }
    if (_filterRoomIds.isNotEmpty) {
      result = result
          .where((b) => _filterRoomIds.contains(b.bird.roomId))
          .toList();
    }
    return result;
  }

  // _buildFilterBar / _buildFilterChip / _showMultiSelectSheet
  // extracted to lib/widgets/bird_search_bar.dart

  Widget _buildBirdList(
      BuildContext context, List<BirdWithDetails> birds, WidgetRef ref) {
    // 用 .select() 提取稳定的 Map 引用与加载标志，避免 AsyncValue 包装对象
    // 引用变化（如 isLoading 态切换）触发整列表无谓重建。
    final weightsMap = ref.watch(
        allLatestWeightsProvider.select((a) => a.valueOrNull ?? const <int, Weight?>{}));
    final weightsLoading = ref.watch(allLatestWeightsProvider.select((a) => a.isLoading));

    if (_selecting) {
      return ListView.builder(
        itemCount: birds.length,
        itemBuilder: (context, index) {
          final b = birds[index];
          return BirdListTile(
            key: ValueKey(b.bird.id),
            bird: b,
            onTap: () {
              setState(() {
                if (_selectedIds.contains(b.bird.id)) {
                  _selectedIds.remove(b.bird.id);
                } else {
                  _selectedIds.add(b.bird.id);
                }
              });
            },
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BirdListTile.buildAvatar(b.bird.id, size: 56, circleSize: 56, growthStage: b.growthStage, circle: true, cardColor: Theme.of(context).colorScheme.surfaceContainerLow),
                const SizedBox(width: 4),
                Checkbox(
                  value: _selectedIds.contains(b.bird.id),
                  onChanged: (_) {
                    setState(() {
                      if (_selectedIds.contains(b.bird.id)) {
                        _selectedIds.remove(b.bird.id);
                      } else {
                        _selectedIds.add(b.bird.id);
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            trailing: _buildWeightTrailing(weightsMap, weightsLoading, b.bird.id),
          );
        },
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: birds.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<BirdWithDetails>.from(birds);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        setState(() {
          birds
            ..clear()
            ..addAll(reordered);
        });
        final orders = <int, int>{};
        for (int i = 0; i < reordered.length; i++) {
          orders[reordered[i].bird.id] = i;
        }
        final db = ref.read(databaseProvider);
        await db.updateSortOrders(orders);
      },
      itemBuilder: (context, index) {
        final b = birds[index];
        // Wrap the whole row in a delayed drag listener so users can
        // long-press anywhere on the tile to start reordering — no
        // separate drag handle icon next to the avatar.
        return ReorderableDelayedDragStartListener(
          key: ValueKey(b.bird.id),
          index: index,
          child: BirdListTile(
            bird: b,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: b)),
            ),
            leading: BirdListTile.buildAvatar(b.bird.id, size: 56, circleSize: 56, growthStage: b.growthStage, circle: true, cardColor: Theme.of(context).colorScheme.surfaceContainerLow),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWeightTrailing(weightsMap, weightsLoading, b.bird.id),
                if (pluginRegistry.enabledPlugins
                    .any((p) => p.id == 'weights')) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.monitor_weight_outlined, size: 20),
                    tooltip: '称重',
                    onPressed: () => _startWeighing(b.bird.roomId, b.bird.id),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeightTrailing(
      Map<int, Weight?> weightsMap, bool weightsLoading, int birdId) {
    final theme = Theme.of(context);
    if (weightsLoading && weightsMap.isEmpty) {
      return const SizedBox.shrink();
    }
    final w = weightsMap[birdId];
    if (w != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${w.weightG.toStringAsFixed(1)}g',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
          Text(BirdListTile.formatDate(w.recordedAt),
              style: theme.textTheme.labelSmall),
        ],
      );
    }
    return Text('-',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }

  void _startWeighing(int? roomId, int birdId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              WeighGridScreen(initialRoomId: roomId, initialBirdId: birdId)),
    );
  }

  void _onExportTap(bool isPro) {
    if (!isPro) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pro 功能'),
          content: const Text('导出鹦鹉数据是 Pro 功能，请先激活。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // 跳转到设置页
                Navigator.pushNamed(context, '/settings');
              },
              child: const Text('激活 Pro'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _selecting = true;
      _selectedIds.clear();
    });
  }

  Future<void> _doExport() async {
    if (_selectedIds.isEmpty) return;

    // 显示进度
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = ref.read(databaseProvider);
      final file =
          await BirdExportService().exportBirds(_selectedIds.toList(), db);

      if (mounted) Navigator.pop(context); // 关闭进度

      if (file != null && mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'WeightNest 鹦鹉数据',
        );
        // 分享后删除临时文件
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('导出失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }

    setState(() {
      _selecting = false;
      _selectedIds.clear();
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

      final birdId = await showDialog<int>(
        context: context,
        builder: (ctx) => _AddBirdDialog(spList: spList, roomList: roomList),
      );

      if (birdId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(allBirdsProvider);
          ref.invalidate(allRoomsProvider);
        });
        await ref.read(databaseProvider).generateTasksForBird(birdId);
        ref.invalidate(todayTasksProvider);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('加载失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
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
  int? _selectedEnclosureId;
  String? _selectedEnclosureName;
  String _gender = '未知';
  DateTime _birthDate = AppClock.now;

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
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('选择品种',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
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
                          ? widget.spList
                              .firstWhere((s) => s.id == _selectedSpeciesId)
                              .name
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
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('选择房间',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        ListTile(
                          title: const Text('不分配房间'),
                          leading: const Icon(Icons.block),
                          selected: _selectedRoomId == null,
                          onTap: () {
                            setState(() {
                              _selectedRoomId = null;
                              _selectedEnclosureId = null;
                              _selectedEnclosureName = null;
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        ...widget.roomList.map((r) => ListTile(
                              title: Text(r.name),
                              selected: _selectedRoomId == r.id,
                              onTap: () {
                                setState(() {
                                  _selectedRoomId = r.id;
                                  _selectedEnclosureId = null;
                                  _selectedEnclosureName = null;
                                });
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
                          ? widget.roomList
                              .firstWhere((r) => r.id == _selectedRoomId)
                              .name
                          : '未知房间')
                      : '不分配',
                  style: TextStyle(
                    color: _selectedRoomId != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 容器选择 — 依赖房间
            InkWell(
              onTap: _selectedRoomId == null
                  ? null
                  : () async {
                      final scope = ProviderScope.containerOf(context);
                      final db = scope.read(databaseProvider);
                      final enclosures =
                          await db.getEnclosuresByRoom(_selectedRoomId!);
                      if (!mounted) return;
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        builder: (ctx) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('选择容器',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              ListTile(
                                title: const Text('不放入容器'),
                                leading: const Icon(Icons.block),
                                selected: _selectedEnclosureId == null,
                                onTap: () {
                                  setState(() {
                                    _selectedEnclosureId = null;
                                    _selectedEnclosureName = null;
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                              ...enclosures.map((e) => ListTile(
                                    title: Text(e.name),
                                    selected: _selectedEnclosureId == e.id,
                                    onTap: () {
                                      setState(() {
                                        _selectedEnclosureId = e.id;
                                        _selectedEnclosureName = e.name;
                                      });
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
                decoration: InputDecoration(
                  labelText: '容器 (选填)',
                  suffixIcon: Icon(Icons.arrow_drop_down,
                      color: _selectedRoomId == null
                          ? Colors.grey.shade400
                          : null),
                ),
                child: Text(
                  _selectedEnclosureName ?? '不分配',
                  style: TextStyle(
                    color: _selectedRoomId == null
                        ? Colors.grey.shade400
                        : _selectedEnclosureId != null
                            ? null
                            : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 性别
            Row(
              children: ['公', '母', '未知']
                  .map((g) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: g != '未知' ? 8 : 0),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: _gender == g,
                            onSelected: (v) => setState(() => _gender = g),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: DateTime(2020),
                  lastDate: AppClock.now,
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
                const SnackBar(
                    content: Text('请输入名称'),
                    behavior: SnackBarBehavior.floating),
              );
              return;
            }
            if (_selectedSpeciesId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('请选择品种'),
                    behavior: SnackBarBehavior.floating),
              );
              return;
            }
            final db =
                ProviderScope.containerOf(context).read(databaseProvider);
            final bird = await db.createBird(
              name: name,
              speciesId: _selectedSpeciesId!,
              birthDate: _birthDate,
              roomId: _selectedRoomId,
              enclosureId: _selectedEnclosureId,
              ringNumber:
                  _ringCtrl.text.trim().isEmpty ? null : _ringCtrl.text.trim(),
              gender: _gender,
            );
            if (mounted) {
              ProviderScope.containerOf(context)
                  .read(weightSavedBirdsProvider.notifier)
                  .notifySaved(bird.id);
              Navigator.pop(context, bird.id);
            }
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}

// _BirdListTile extracted to lib/widgets/bird_list_tile.dart
