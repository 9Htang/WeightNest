import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/room_repository.dart';
import '../birds/birds_screen.dart';
import '../worker/worker_screen.dart';

/// 房间管理页面
class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(allRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('房间管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (rooms) => rooms.isEmpty
            ? const Center(child: Text('暂无房间'))
            : ReorderableListView.builder(
                itemCount: rooms.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  final item = rooms.removeAt(oldIndex);
                  rooms.insert(newIndex, item);
                  setState(() {});
                  final db = ref.read(databaseProvider);
                  for (int i = 0; i < rooms.length; i++) {
                    await db.updateRoom(rooms[i].id, sortOrder: i);
                  }
                  ref.invalidate(allRoomsProvider);
                },
                itemBuilder: (context, i) {
                  final r = rooms[i];
                  return Card(
                    key: ValueKey(r.id),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: ListTile(
                      leading: const Icon(Icons.meeting_room),
                      title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('点击查看鹦鹉'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BirdsScreen(roomId: r.id)),
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showEditDialog(context, r);
                          if (v == 'delete') _confirmDelete(context, r);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Room? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final usersAsync = ref.read(allUsersProvider);

    showDialog(
      context: context,
      builder: (ctx) {
        int? assignedId = existing?.assignedUserId;
        return AlertDialog(
          title: Text(existing != null ? '编辑房间' : '新增房间'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '房间名称'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                usersAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (users) => DropdownButtonFormField<int?>(
                    value: assignedId,
                    decoration: const InputDecoration(labelText: '负责人'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('未分配')),
                      ...users.map((u) => DropdownMenuItem(
                        value: u.id, child: Text(u.displayName),
                      )),
                    ],
                    onChanged: (v) => assignedId = v,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final db = ref.read(databaseProvider);
              if (existing != null) {
                await db.updateRoom(existing.id, name: name, assignedUserId: assignedId);
              } else {
                await db.createRoom(name, assignedUserId: assignedId);
              }
              ref.invalidate(allRoomsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: const Text('保存')),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Room r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除房间「${r.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(databaseProvider).removeRoom(r.id);
              ref.invalidate(allRoomsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
