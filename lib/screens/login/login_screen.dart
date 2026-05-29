import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../worker/worker_screen.dart';
import '../shell/mobile_shell.dart';
import '../connect/connect_screen.dart';
import '../../database/database.dart';
import '../../repositories/user_repository.dart';
import '../../providers.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  User? _selectedUser;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
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

  void _selectUser(User u) {
    _usernameCtrl.text = u.username;
    _selectedUser = u;
    _error = null;
    setState(() {});
    Navigator.pop(context);
  }

  Future<void> _login() async {
    User? u = _selectedUser;
    final typedUsername = _usernameCtrl.text.trim();

    if (u == null && typedUsername.isNotEmpty) {
      final db = ref.read(databaseProvider);
      u = await db.getByUsername(typedUsername);
    }

    if (u == null) {
      final connected = ref.read(syncConnectedProvider);
      if (connected) {
        setState(() => _error = '账号不存在\n请联系管理员在电脑端创建账号');
      } else {
        setState(() => _error = '用户不存在，请检查用户名\n或先连接服务器同步数据');
      }
      return;
    }
    if (_isAdmin(u)) {
      setState(() => _error = '管理员请使用电脑端管理\n手机端仅供饲养员使用');
      return;
    }
    if (u.passwordHash.isNotEmpty) {
      final entered = _passwordCtrl.text;
      final enteredHash = sha256.convert(utf8.encode(entered)).toString();
      // 兼容旧版明文存储：先比较哈希，再比较明文
      if (enteredHash != u.passwordHash && entered != u.passwordHash) {
        setState(() => _error = '密码错误');
        return;
      }
    }

    setState(() { _loggingIn = true; _error = null; });
    try {
      final workerNotifier = ref.read(workerProvider.notifier);
      await workerNotifier.login(u.id, u.displayName, u.role, username: u.username);
      if (mounted) Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileShell()),
      );
    } catch (e) {
      setState(() { _error = '登录失败: $e'; _loggingIn = false; });
    }
  }

  void _showUserPicker(BuildContext context, List<User> users) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择用户', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...users.map((u) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(u.displayName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
              title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${u.displayName} · ${_roleLabel(u)}'),
              trailing: _selectedUser?.id == u.id ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () => _selectUser(u),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(keepableViewerUsersProvider);
    final connected = ref.watch(syncConnectedProvider);

    return usersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败: $e'))),
      data: (users) {
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
                    const SizedBox(height: 16),

                    // Connection status
                    if (connected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.cloud_done, size: 14, color: Colors.green),
                          SizedBox(width: 6),
                          Text('已连接服务器，请登录', style: TextStyle(fontSize: 13, color: Colors.green)),
                        ]),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Column(children: [
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.wifi_off, size: 14, color: Colors.orange),
                            SizedBox(width: 6),
                            Text('未连接服务器', style: TextStyle(fontSize: 13, color: Colors.orange)),
                          ]),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () async {
                                final result = await Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const ConnectScreen()));
                                if (result == true) {
                                  ref.invalidate(keepableViewerUsersProvider);
                                  ref.invalidate(syncConnectedProvider);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.colorScheme.primary),
                              ),
                              child: const Text('连接服务器', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 16),

                    // QR login
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ConnectScreen()));
                        if (result == true) {
                          ref.invalidate(keepableViewerUsersProvider);
                          ref.invalidate(syncConnectedProvider);
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('扫码登录（免密码）'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('或', style: TextStyle(color: Colors.grey))),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),

                    // Empty or populated user state
                    if (users.isEmpty)
                      Card(
                        color: connected ? Colors.amber.shade50 : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Icon(connected ? Icons.person_off : Icons.info_outline,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(
                              connected
                                  ? '服务器上暂无饲养员账号\n请联系管理员在电脑端创建'
                                  : '暂无本地账号\n请先连接服务器同步数据',
                              style: const TextStyle(fontSize: 13),
                            )),
                          ]),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Username input
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            labelText: '用户名',
                            hintText: '输入用户名，如 admin',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() { _selectedUser = null; _error = null; }),
                          onSubmitted: (_) => _login(),
                        ),
                      ),
                      if (users.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 52, height: 56,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_drop_down_circle),
                            tooltip: '从列表选择',
                            color: theme.colorScheme.primary,
                            onPressed: () => _showUserPicker(context, users),
                          ),
                        ),
                      ],
                    ]),
                    if (_selectedUser != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Row(children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('${_selectedUser!.displayName} · ${_roleLabel(_selectedUser!)}',
                              style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                        ]),
                      ),
                    const SizedBox(height: 16),

                    // Password
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

                    // Login button
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

                    // Error
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
