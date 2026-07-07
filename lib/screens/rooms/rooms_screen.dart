import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/room_repository.dart';
import '../../widgets/list/app_list_card.dart';
import '../../widgets/list/empty_state.dart';
import '../birds/birds_screen.dart';

// 提取独立的输入对话框，彻底解决 TextEditingController 生命周期问题
class _TextInputDialog extends StatefulWidget {
  final String title;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final Future<void> Function(String name) onSave;

  const _TextInputDialog({
    required this.title,
    this.labelText,
    this.hintText,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
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

/// 房间管理页面
class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  List<Room>? _reorderedRooms; // 本地缓存拖拽结果

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
        data: (rooms) {
          final displayRooms = _reorderedRooms ?? rooms;
          return displayRooms.isEmpty
              ? EmptyState(
                  icon: const Icon(Icons.meeting_room_outlined, size: 56),
                  message: '暂无房间',
                  hint: '点击右下角 + 添加房间',
                )
              : ReorderableListView.builder(
                  itemCount: displayRooms.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final reordered = List<Room>.from(displayRooms);
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);

                    // 1. 立即更新本地视图，维持UI流畅
                    setState(() => _reorderedRooms = reordered);

                    // 2. 后台静默更新数据库
                    final db = ref.read(databaseProvider);
                    final futures = <Future>[];
                    for (int i = 0; i < reordered.length; i++) {
                      futures.add(db.updateRoom(reordered[i].id, sortOrder: i));
                    }
                    await Future.wait(futures);

                    // 3. 延迟到下一帧再刷新 Provider，避免打断 ReorderableListView 动画
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      ref.invalidate(allRoomsProvider);
                      setState(() => _reorderedRooms = null);
                    });
                  },
                  itemBuilder: (context, i) {
                    final r = displayRooms[i];
                    return AppListCard.tile(
                      key: ValueKey(r.id),
                      leading: const Icon(Icons.meeting_room),
                      title: Text(r.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('点击查看鹦鹉'),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('删除',
                                  style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showEditDialog(context, r);
                          if (v == 'delete') _confirmDelete(context, r);
                        },
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BirdsScreen(roomId: r.id)),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Room? existing) {
    final db = ref.read(databaseProvider);
    showDialog<bool>(
      context: context,
      builder: (ctx) => _TextInputDialog(
        title: existing != null ? '编辑房间' : '新增房间',
        labelText: '房间名称',
        initialValue: existing?.name,
        onSave: (name) async {
          if (existing != null) {
            await db.updateRoom(existing.id, name: name);
          } else {
            await db.createRoom(name);
          }
        },
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        ref.invalidate(allRoomsProvider);
      }
    });
  }

  void _confirmDelete(BuildContext context, Room r) {
    final db = ref.read(databaseProvider);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除房间「${r.name}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.removeRoom(r.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    ).then((deleted) {
      if (deleted == true && mounted) {
        ref.invalidate(allRoomsProvider);
      }
    });
  }
}
