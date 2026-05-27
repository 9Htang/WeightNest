import 'package:flutter/material.dart';
import '../../services/staff_service.dart';

/// 人员管理页面
class StaffScreen extends StatefulWidget {
  final StaffService service;

  const StaffScreen({super.key, required this.service});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<UserInfo> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await widget.service.fetchUsers();
      setState(() { _users = users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleActive(UserInfo user) async {
    try {
      await widget.service.updateUser(user.id, isActive: !user.isActive);
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final displayCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    String role = 'keeper';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建员工账号'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '登录用户名', hintText: '英文或拼音'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayCtrl,
                  decoration: const InputDecoration(labelText: '显示姓名', hintText: '例如: 张三'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pwCtrl,
                  decoration: const InputDecoration(labelText: '密码', hintText: '留空则不设密码'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: '角色'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('管理员 — 全部权限')),
                    DropdownMenuItem(value: 'keeper', child: Text('饲养员 — 录入数据')),
                    DropdownMenuItem(value: 'viewer', child: Text('查看者 — 仅查看')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                final uname = nameCtrl.text.trim();
                final dname = displayCtrl.text.trim();
                if (uname.isEmpty || dname.isEmpty) return;
                try {
                  await widget.service.createUser(
                    username: uname,
                    displayName: dname,
                    password: pwCtrl.text,
                    role: role,
                  );
                  Navigator.pop(ctx);
                  await _loadUsers();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('创建失败: $e')));
                  }
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(UserInfo user) {
    final displayCtrl = TextEditingController(text: user.displayName);
    final pwCtrl = TextEditingController();
    String role = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('编辑: ${user.displayName}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayCtrl,
                  decoration: const InputDecoration(labelText: '显示姓名'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pwCtrl,
                  decoration: const InputDecoration(labelText: '新密码', hintText: '留空则不修改'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: '角色'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('管理员 — 全部权限')),
                    DropdownMenuItem(value: 'keeper', child: Text('饲养员 — 录入数据')),
                    DropdownMenuItem(value: 'viewer', child: Text('查看者 — 仅查看')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.service.updateUser(
                    user.id,
                    displayName: displayCtrl.text.trim(),
                    role: role,
                    password: pwCtrl.text.isNotEmpty ? pwCtrl.text : null,
                  );
                  Navigator.pop(ctx);
                  await _loadUsers();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('更新失败: $e')));
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggle(UserInfo user) {
    final action = user.isActive ? '停用' : '启用';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action账号'),
        content: Text('确定要${action}「${user.displayName}」的账号吗？${user.isActive ? "停用后该账号将无法登录。" : ""}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: user.isActive ? Colors.orange : Colors.green),
            onPressed: () { Navigator.pop(ctx); _toggleActive(user); },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── 顶部操作栏 ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 8),
              Text('人员管理', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('新建账号'),
              ),
            ],
          ),
        ),

        // ── 内容区 ──
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadUsers, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('暂无员工', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('新建第一个账号'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            dataTextStyle: const TextStyle(fontSize: 13),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('姓名')),
              DataColumn(label: Text('用户名')),
              DataColumn(label: Text('角色')),
              DataColumn(label: Text('状态')),
              DataColumn(label: Text('创建时间')),
              DataColumn(label: Text('操作')),
            ],
            rows: _users.map((u) => DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (_) => u.isActive ? null : Colors.grey.shade100,
              ),
              cells: [
                DataCell(Text(u.displayName, style: TextStyle(fontWeight: FontWeight.w600,
                    color: u.isActive ? null : Colors.grey))),
                DataCell(Text(u.username, style: TextStyle(color: u.isActive ? null : Colors.grey))),
                DataCell(_roleChip(u, theme)),
                DataCell(_statusChip(u)),
                DataCell(Text(u.createdAt.toString().substring(0, 10),
                    style: TextStyle(fontSize: 11, color: u.isActive ? null : Colors.grey))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: '编辑',
                      onPressed: () => _showEditDialog(u),
                    ),
                    IconButton(
                      icon: Icon(u.isActive ? Icons.block : Icons.check_circle, size: 18,
                          color: u.isActive ? Colors.orange : Colors.green),
                      tooltip: u.isActive ? '停用' : '启用',
                      onPressed: () => _confirmToggle(u),
                    ),
                  ],
                )),
              ],
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(UserInfo user, ThemeData theme) {
    Color color;
    switch (user.role) {
      case 'admin': color = Colors.red; break;
      case 'keeper': color = Colors.blue; break;
      case 'viewer': color = Colors.grey; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(user.roleLabel, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusChip(UserInfo user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        user.isActive ? '正常' : '已停用',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: user.isActive ? Colors.green : Colors.red),
      ),
    );
  }
}
