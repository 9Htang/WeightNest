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
  final String role;

  const WorkerInfo({this.userId, this.displayName = '未选择', this.role = ''});

  bool get isSelected => userId != null;
  bool get isAdmin => role == 'admin';
}

/// 员工状态管理
class WorkerNotifier extends StateNotifier<WorkerInfo> {
  WorkerNotifier() : super(const WorkerInfo()) {
    _load();
  }

  static const _keyName = 'worker_name';
  static const _keyId = 'worker_id';
  static const _keyRole = 'worker_role';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyId);
    final name = prefs.getString(_keyName);
    final role = prefs.getString(_keyRole) ?? '';
    if (id != null && name != null) {
      // 管理员不允许用手机端，自动清除
      if (role == 'admin') {
        await clear();
        return;
      }
      state = WorkerInfo(userId: id, displayName: name, role: role);
    }
  }

  /// 登录（校验后设置，管理员拒绝）
  Future<void> login(int id, String name, String role) async {
    if (role == 'admin') throw Exception('管理员请使用电脑端');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyId, id);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role);
    state = WorkerInfo(userId: id, displayName: name, role: role);
  }

  Future<void> selectWorker(int id, String name) async {
    // 兼容旧流程：selectWorker 不再直接使用，保留以防其他地方引用
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

/// 切换员工页面（仅可在登录后访问，不含创建功能 — 创建仅限桌面端）
class WorkerSelectScreen extends ConsumerWidget {
  const WorkerSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(keepableViewerUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('切换员工')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无饲养员账号'),
                  SizedBox(height: 8),
                  Text('请使用电脑端创建账号', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: ListTile(
                  leading: CircleAvatar(child: Text(u.displayName[0].toUpperCase())),
                  title: Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(u.role == 'keeper' ? '饲养员' : '查看者'),
                  onTap: () async {
                    await ref.read(workerProvider.notifier).login(u.id, u.displayName, u.role);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 所有用户
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllUsers();
});

/// 仅 keeper/viewer（手机端可登录用户，排除管理员）
final keepableViewerUsersProvider = FutureProvider<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  final all = await db.getAllUsers();
  return all.where((u) => u.role != 'admin').toList();
});
