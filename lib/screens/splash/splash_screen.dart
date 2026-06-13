import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../repositories/user_repository.dart';
import '../../screens/worker/worker_screen.dart';
import '../shell/mobile_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndGo();
  }

  Future<void> _checkAndGo() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final worker = ref.read(workerProvider);

      // 确保默认数据存在
      try {
        await ref.read(initDefaultsProvider.future);
      } catch (e) {
        if (mounted) setState(() => _error = '初始化数据失败: $e');
      }

      if (!mounted) return;

      // 自动选择第一个本地用户
      if (!worker.isSelected) {
        final db = ref.read(databaseProvider);
        try {
          final users = await db.getAllUsers();
          if (users.isNotEmpty) {
            final u = users.first;
            await ref.read(workerProvider.notifier).selectUser(u.id, u.displayName, u.role, username: u.username);
          }
        } catch (_) {}
      }

      if (!mounted) return;
      _goNext();
    } catch (e, st) {
      if (mounted) setState(() => _error = '$e\n\n$st');
    }
  }

  void _goNext() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MobileShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('WeightNest',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (_error == null) ...[
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(height: 16),
                  Text('加载中...', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                ] else ...[
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('启动失败', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _error = null);
                      _checkAndGo();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('重试'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
