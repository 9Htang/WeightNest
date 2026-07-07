import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/enclosure_repository.dart';
import '../../core/plugin_registry.dart';
import '../../widgets/list/app_list_card.dart';
import '../../widgets/list/empty_state.dart';

// 提取独立的输入对话框
class _EnclosureTextInputDialog extends StatefulWidget {
  final String title;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final Future<void> Function(String name) onSave;

  const _EnclosureTextInputDialog({
    required this.title,
    this.labelText,
    this.hintText,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<_EnclosureTextInputDialog> createState() =>
      _EnclosureTextInputDialogState();
}

class _EnclosureTextInputDialogState extends State<_EnclosureTextInputDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final name = _controller.text.trim();
                  if (name.isEmpty) return;
                  setState(() => _saving = true); // 防抖
                  await widget.onSave(name);
                  if (mounted) Navigator.pop(context, true);
                },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 容器管理页面（房间内的保温箱、飞行笼等）
class EnclosureManagementScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;

  const EnclosureManagementScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<EnclosureManagementScreen> createState() =>
      _EnclosureManagementScreenState();
}

class _EnclosureManagementScreenState
    extends ConsumerState<EnclosureManagementScreen> {
  List<EnclosureWithCount>? _reorderedEnclosures; // 本地缓存拖拽结果

  @override
  Widget build(BuildContext context) {
    ref.watch(pluginToggleVersionProvider);
    final enclosuresAsync =
        ref.watch(roomEnclosuresWithCountsProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: Text('容器管理 - ${widget.roomName}'),
        actions: [
          ...(() {
            final roomAction = pluginRegistry.enabledPlugins
                .map((p) => p.roomWeighAction)
                .firstWhere((a) => a != null, orElse: () => null);
            if (roomAction == null) return const <Widget>[];
            return <Widget>[
              IconButton(
                icon: Icon(roomAction.icon, size: 22),
                tooltip: '称重全部鸟',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => roomAction.builder(widget.roomId),
                    ),
                  );
                },
              ),
            ];
          })(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: enclosuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (enclosures) {
          final displayEnclosures = _reorderedEnclosures ?? enclosures;
          return displayEnclosures.isEmpty
              ? EmptyState(
                  icon: const Icon(Icons.inventory_2_outlined, size: 56),
                  message: '暂无容器，点击右下角 + 添加',
                )
              : ReorderableListView.builder(
                  itemCount: displayEnclosures.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final reordered =
                        List<EnclosureWithCount>.from(displayEnclosures);
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);

                    // 1. 立即更新本地视图，维持UI流畅
                    setState(() => _reorderedEnclosures = reordered);

                    // 2. 后台静默更新数据库
                    final db = ref.read(databaseProvider);
                    final map = <int, int>{};
                    for (int i = 0; i < reordered.length; i++) {
                      map[reordered[i].enclosure.id] = i;
                    }
                    await db.updateEnclosureSortOrders(map);

                    // 3. 延迟到下一帧再刷新 Provider，避免打断动画
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      ref.invalidate(roomEnclosuresWithCountsProvider);
                      setState(() => _reorderedEnclosures = null);
                    });
                  },
                  itemBuilder: (context, i) {
                    final e = displayEnclosures[i];
                    final encAction = pluginRegistry.enabledPlugins
                        .map((p) => p.enclosureWeighAction)
                        .firstWhere((a) => a != null, orElse: () => null);
                    return AppListCard.tile(
                      key: ValueKey(e.enclosure.id),
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(e.enclosure.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${e.birdCount} 只鹦鹉'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (encAction != null)
                            IconButton(
                              icon: Icon(encAction.icon, size: 20),
                              tooltip: encAction.tooltip,
                              color: Theme.of(context).colorScheme.primary,
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        encAction.builder(e.enclosure.id),
                                  ),
                                );
                              },
                            ),
                          PopupMenuButton(
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('编辑')),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('删除',
                                      style: TextStyle(color: Colors.red))),
                            ],
                            onSelected: (v) {
                              if (v == 'edit')
                                _showEditDialog(context, e.enclosure);
                              if (v == 'delete') _confirmDelete(context, e);
                            },
                          ),
                        ],
                      ),
                      onTap: null,
                    );
                  },
                );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Enclosure? existing) {
    final db = ref.read(databaseProvider);
    showDialog<bool>(
      context: context,
      builder: (ctx) => _EnclosureTextInputDialog(
        title: existing != null ? '编辑容器' : '新增容器',
        labelText: '容器名称',
        hintText: '如：1号保温箱、飞行笼',
        initialValue: existing?.name,
        onSave: (name) async {
          if (existing != null) {
            await db.updateEnclosure(existing.id, name: name);
          } else {
            await db.createEnclosure(name, widget.roomId);
          }
        },
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        ref.invalidate(roomEnclosuresWithCountsProvider(widget.roomId));
      }
    });
  }

  void _confirmDelete(BuildContext context, EnclosureWithCount e) {
    final hasBirds = e.birdCount > 0;
    final db = ref.read(databaseProvider);

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(hasBirds
            ? '删除容器「${e.enclosure.name}」？\n\n容器中有 ${e.birdCount} 只鹦鹉，删除后它们将移出容器（不会被删除）。'
            : '删除容器「${e.enclosure.name}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.removeEnclosure(e.enclosure.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    ).then((deleted) {
      if (deleted == true && mounted) {
        ref.invalidate(roomEnclosuresWithCountsProvider(widget.roomId));
      }
    });
  }
}
