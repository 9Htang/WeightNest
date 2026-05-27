import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../worker/worker_screen.dart';
import '../connect/connect_screen.dart';
import '../../database/database.dart';
import '../../providers.dart';

/// 手机端员工登录页面 — 管理员禁止登录，仅 keeper/viewer 可用
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  User? _selectedUser;
  final _passwordCtrl = TextEditingController();
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _isAdmin(User u) => u.role == 'admin';
  String _roleLabel(User u) {
    switch (u.role) {
      case 'admin': return '管理员';
      case 'keeper': return '饲养员';
      default: return '查看者';
    }
  }

  Future<void> _login() async {
    final u = _selectedUser;
    if (u == null) {
      setState(() => _error = '请选择用户');
      return;
    }
    if (_isAdmin(u)) {
      setState(() => _error = '管理员请使用电脑端管理\n手机端仅供饲养员使用');
      return;
    }
    // 密码校验：有密码则必须匹配，无密码则直接通过
    if (u.passwordHash.isNotEmpty && _passwordCtrl.text != u.passwordHash) {
      setState(() => _error = '密码错误');
      return;
    }

    setState(() { _loggingIn = true; _error = null; });
    try {
      final workerNotifier = ref.read(workerProvider.notifier);
      await workerNotifier.login(u.id, u.displayName, u.role);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = '登录失败: $e'; _loggingIn = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(keepableViewerUsersProvider);

    return usersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败: $e'))),
      data: (users) {
        if (users.isEmpty) {
          // 检查是否已连接服务器
          final connected = ref.watch(syncConnectedProvider);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('暂无可登录的饲养员账号', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (connected)
                      const Text('请使用电脑端创建账号', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      const Text('请先连接服务器同步数据', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ConnectScreen()));
                        // 连接后刷新用户列表
                        ref.invalidate(keepableViewerUsersProvider);
                      },
                      icon: const Icon(Icons.link),
                      label: Text(connected ? '重新连接服务器' : '连接服务器'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Icon(Icons.pets, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('WeightNest', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('员工登录', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                    const SizedBox(height: 32),

                    // 用户选择
                    DropdownButtonFormField<User>(
                      value: _selectedUser,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '选择用户',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: users.map((u) => DropdownMenuItem(
                        value: u,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(
                                u.displayName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(_roleLabel(u), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      onChanged: (u) => setState(() { _selectedUser = u; _error = null; }),
                    ),
                    const SizedBox(height: 16),

                    // 密码
                    TextField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: _selectedUser != null && _selectedUser!.passwordHash.isEmpty
                            ? '该用户未设置密码'
                            : '请输入密码',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),

                    // 登录按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _loggingIn ? null : _login,
                        child: _loggingIn
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('登 录', style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    // 错误提示
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13), textAlign: TextAlign.center),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
