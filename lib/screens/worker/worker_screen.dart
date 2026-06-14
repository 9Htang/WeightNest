import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/user_repository.dart';

/// 当前用户信息
class WorkerInfo {
  final int? userId;
  final String displayName;
  final String username;
  final String role;
  final bool isInitializing;

  const WorkerInfo({this.userId, this.displayName = '未选择', this.username = '', this.role = '', this.isInitializing = false});

  bool get isSelected => userId != null;
}

/// 用户状态管理
class WorkerNotifier extends StateNotifier<WorkerInfo> {
  late final Future<void> _loadFuture;

  WorkerNotifier() : super(const WorkerInfo(isInitializing: true)) {
    _loadFuture = _load();
  }

  /// Completes after SharedPreferences _load() finishes.
  Future<void> get ready => _loadFuture;

  static const _keyName = 'worker_name';
  static const _keyId = 'worker_id';
  static const _keyRole = 'worker_role';
  static const _keyUsername = 'worker_username';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyId);
    final name = prefs.getString(_keyName);
    final role = prefs.getString(_keyRole) ?? '';
    final username = prefs.getString(_keyUsername) ?? '';
    if (id != null && name != null) {
      state = WorkerInfo(userId: id, displayName: name, username: username, role: role);
    } else {
      state = const WorkerInfo();
    }
  }

  Future<void> selectUser(int id, String name, String role, {String username = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyId, id);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyUsername, username);
    state = WorkerInfo(userId: id, displayName: name, username: username, role: role);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUsername);
    state = const WorkerInfo();
  }
}

final workerProvider = StateNotifierProvider<WorkerNotifier, WorkerInfo>((ref) {
  return WorkerNotifier();
});

/// 所有用户
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllUsers();
});

/// 手机端可用用户（所有非删除用户）
final keepableViewerUsersProvider = FutureProvider<List<User>>((ref) async {
  final db = ref.watch(databaseProvider);
  final all = await db.getAllUsers();
  return all.where((u) => u.deletedAt == null).toList();
});
