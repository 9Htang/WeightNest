import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audit_log_service.dart';
import '../services/bird_archive_service.dart';
import '../services/staff_service.dart';
import 'audit_log_screen.dart';
import 'bird_archive_screen.dart';
import 'staff_screen.dart';

/// 桌面端主布局 — 侧边栏 + 内容区
class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  int _selectedIndex = 0;
  AuditLogService? _logService;
  BirdArchiveService? _birdService;
  StaffService? _staffService;
  bool _connecting = true;
  String? _connectError;

  // 连接配置
  final _hostCtrl = TextEditingController(text: 'localhost');
  final _portCtrl = TextEditingController(text: '8080');
  final _pinCtrl = TextEditingController(text: '1234');

  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    await _tryConnect();
  }

  Future<void> _tryConnect() async {
    setState(() { _connecting = true; _connectError = null; });

    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8080;
    final pin = _pinCtrl.text.trim();

    final token = await AuditLogService.authenticate(
      serverHost: host,
      serverPort: port,
      pin: pin,
    );

    if (token != null) {
      setState(() {
        _logService = AuditLogService(serverHost: host, serverPort: port, token: token);
        _birdService = BirdArchiveService(serverHost: host, serverPort: port, token: token);
        _staffService = StaffService(serverHost: host, serverPort: port, token: token);
        _connecting = false;
      });
    } else {
      setState(() {
        _connectError = '连接失败，请检查服务器地址和 PIN';
        _connecting = false;
      });
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 未连接 → 显示登录页
    if (_connecting || _logService == null) {
      return _buildConnectScreen();
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // ── 侧边栏 ──
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(Icons.pets, size: 28, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Text('WeightNest', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: Text('操作日志'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pets),
                selectedIcon: Icon(Icons.pets),
                label: Text('鹦鹉档案'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                selectedIcon: Icon(Icons.people),
                label: Text('人员管理'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),

          // ── 内容区 ──
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                AuditLogScreen(service: _logService!),
                BirdArchiveScreen(service: _birdService!),
                StaffScreen(service: _staffService!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 连接服务器页面
  Widget _buildConnectScreen() {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                const Text('WeightNest 管理端', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('连接服务器以开始', style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                if (_connecting) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('正在连接...'),
                ] else ...[
                  TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(labelText: '服务器地址', hintText: 'localhost'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portCtrl,
                    decoration: const InputDecoration(labelText: '端口', hintText: '8080'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinCtrl,
                    decoration: const InputDecoration(labelText: 'PIN 码'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (_connectError != null) ...[
                    Text(_connectError!, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _tryConnect,
                      child: const Text('连接'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
