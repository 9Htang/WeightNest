import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/enclosure_repository.dart';
import '../../core/plugin_registry.dart';

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
  @override
  Widget build(BuildContext context) {
    ref.watch(pluginToggleVersionProvider); // 插件开关时重建称重按钮
    final enclosuresAsync =
        ref.watch(roomEnclosuresWithCountsProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: Text('容器管理 - ${widget.roomName}'),
        actions: [
          // 房间级称重按钮（插件提供）
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
        data: (enclosures) => enclosures.isEmpty
            ? const Center(child: Text('暂无容器，点击右下角 + 添加'))
            : ReorderableListView.builder(
                itemCount: enclosures.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  final reordered =
                      List<EnclosureWithCount>.from(enclosures);
                  final item = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, item);
                  setState(() {
                    enclosures
                      ..clear()
                      ..addAll(reordered);
                  });
                  final db = ref.read(databaseProvider);
                  final map = <int, int>{};
                  for (int i = 0; i < reordered.length; i++) {
                    map[reordered[i].enclosure.id] = i;
                  }
                  await db.updateEnclosureSortOrders(map);
                  ref.invalidate(roomEnclosuresWithCountsProvider);
                },
                itemBuilder: (context, i) {
                  final e = enclosures[i];
                  // 查找插件提供的容器称重操作
                  final encAction = pluginRegistry.enabledPlugins
                      .map((p) => p.enclosureWeighAction)
                      .firstWhere((a) => a != null, orElse: () => null);
                  return Card(
                    key: ValueKey(e.enclosure.id),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 3),
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(e.enclosure.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
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
                                    builder: (_) => encAction.builder(e.enclosure.id),
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
                              if (v == 'delete')
                                _confirmDelete(context, e);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Enclosure? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing != null ? '编辑容器' : '新增容器'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: '容器名称', hintText: '如：1号保温箱、飞行笼'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final db = ref.read(databaseProvider);
                if (existing != null) {
                  await db.updateEnclosure(existing.id, name: name);
                } else {
                  await db.createEnclosure(name, widget.roomId);
                }
                ref.invalidate(roomEnclosuresProvider);
                ref.invalidate(roomEnclosuresWithCountsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, EnclosureWithCount e) {
    final hasBirds = e.birdCount > 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(hasBirds
            ? '删除容器「${e.enclosure.name}」？\n\n容器中有 ${e.birdCount} 只鹦鹉，删除后它们将移出容器（不会被删除）。'
            : '删除容器「${e.enclosure.name}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(databaseProvider)
                  .removeEnclosure(e.enclosure.id);
              ref.invalidate(roomEnclosuresProvider);
              ref.invalidate(roomEnclosuresWithCountsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
