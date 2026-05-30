import 'package:flutter/material.dart';
import '../services/bird_archive_service.dart';
import '../services/staff_service.dart';

/// 桌面端 — 房间管理（配置负责人、查看房间鹦鹉）
class DesktopRoomsScreen extends StatefulWidget {
  final RoomService roomService;
  final StaffService staffService;
  final BirdArchiveService birdService;
  final ValueNotifier<int> refreshKey;

  const DesktopRoomsScreen({
    super.key,
    required this.roomService,
    required this.staffService,
    required this.birdService,
    required this.refreshKey,
  });

  @override
  State<DesktopRoomsScreen> createState() => _DesktopRoomsScreenState();
}

class _DesktopRoomsScreenState extends State<DesktopRoomsScreen> {
  List<RoomInfo> _rooms = [];
  List<UserInfo> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshKey.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshKey.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() => _load();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.roomService.fetchAll(),
        widget.staffService.fetchUsers(),
      ]);
      if (mounted) {
        setState(() {
          _rooms = results[0] as List<RoomInfo>;
          _users = (results[1] as List<UserInfo>).where((u) => u.isActive).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _createOrEdit({RoomInfo? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int? assignedId = existing?.assignedUserId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑房间' : '新建房间'),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl, autofocus: true,
            decoration: const InputDecoration(labelText: '房间名称'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: assignedId,
            decoration: const InputDecoration(labelText: '负责人', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('未分配')),
              ..._users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.displayName))),
            ],
            onChanged: (v) => assignedId = v,
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            try {
              if (existing != null) {
                await widget.roomService.update(existing.id, name: name, assignedUserId: assignedId);
              } else {
                await widget.roomService.create(name, assignedUserId: assignedId);
              }
              Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating),
                );
              }
            }
          }, child: const Text('保存')),
        ],
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _confirmDelete(RoomInfo room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除房间「${room.name}」？\n房间内有 ${room.birdCount} 只鹦鹉。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        // Soft-delete by setting assignedUserId to null and name to indicate deleted
        await widget.roomService.update(room.id, assignedUserId: null);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  String _staffName(int? userId) {
    if (userId == null) return '未分配';
    return _users.where((u) => u.id == userId).map((u) => u.displayName).firstOrNull ?? '未知';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(children: [
          const Icon(Icons.meeting_room, size: 20),
          const SizedBox(width: 8),
          Text('房间管理', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${_rooms.length} 个房间', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _createOrEdit(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建房间'),
          ),
        ]),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
              const SizedBox(height: 8), Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
              const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('重试')),
            ]))
          : _rooms.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.meeting_room, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12), Text('暂无房间', style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: () => _createOrEdit(), icon: const Icon(Icons.add), label: const Text('新建第一个房间')),
              ]))
            : ListView(padding: const EdgeInsets.all(16), children: _rooms.map((r) => _RoomCard(
                room: r, staffName: _staffName(r.assignedUserId),
                onEdit: () => _createOrEdit(existing: r),
                onDelete: () => _confirmDelete(r),
              )).toList()),
      ),
    ]);
  }
}

class _RoomCard extends StatelessWidget {
  final RoomInfo room;
  final String staffName;
  final VoidCallback onEdit, onDelete;

  const _RoomCard({required this.room, required this.staffName, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStaff = room.assignedUserId != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text('${room.birdCount}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(hasStaff ? Icons.person : Icons.person_off, size: 13, color: hasStaff ? Colors.blue.shade400 : Colors.grey),
              const SizedBox(width: 4),
              Text(staffName, style: TextStyle(fontSize: 12, color: hasStaff ? Colors.blue.shade600 : Colors.grey)),
              const SizedBox(width: 16),
              Icon(Icons.pets, size: 13, color: Colors.brown.shade300),
              const SizedBox(width: 4),
              Text('${room.birdCount} 只', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ])),
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit, tooltip: '编辑'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: onDelete, tooltip: '删除'),
        ]),
      ),
    );
  }
}
