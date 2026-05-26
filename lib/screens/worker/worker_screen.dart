import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/user_repository.dart';

/// 当前选中的员工信息
class WorkerInfo {
  final int? userId;
  final String displayName;

  const WorkerInfo({this.userId, this.displayName = '未选择'});

  bool get isSelected => userId != null;
}

/// 员工状态管理
class WorkerNotifier extends StateNotifier<WorkerInfo> {
  WorkerNotifier() : super(const WorkerInfo()) {
    _load();
  }

  static const _keyName = 'worker_name';
  static const _keyId = 'worker_id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyId);
    final name = prefs.getString(_keyName);
    if (id != null && name != null) {
      state = WorkerInfo(userId: id, displayName: name);
    }
  }

  Future<void> selectWorker(int id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyId, id);
    await prefs.setString(_keyName, name);
    state = WorkerInfo(userId: id, displayName: name);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyName);
    state = const WorkerInfo();
  }
}

final workerProvider = StateNotifierProvider<WorkerNotifier, WorkerInfo>((ref) {
  return WorkerNotifier();
});

/// 员工选择页面
class WorkerSelectScreen extends ConsumerWidget {
  const WorkerSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('选择员工')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('还没有员工，请先创建'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.person_add),
                    label: const Text('创建员工'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.person_add),
                  label: const Text('创建新员工'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(u.displayName[0].toUpperCase())),
                        title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(u.role == 'admin' ? '管理员' : '饲养员'),
                        onTap: () async {
                          await ref.read(workerProvider.notifier).selectWorker(u.id, u.displayName);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建员工'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: '员工姓名', hintText: '例如: 张三'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final db = ref.read(databaseProvider);
            final username = 'user_${DateTime.now().millisecondsSinceEpoch}';
            await db.createUser(username, name, '');
            ref.invalidate(allUsersProvider);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('创建')),
        ],
      ),
    );
  }
}

/// 所有用户
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllUsers();
});
