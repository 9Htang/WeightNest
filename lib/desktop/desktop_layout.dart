import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_manager.dart';
import '../services/audit_log_service.dart';
import '../services/bird_archive_service.dart';
import '../services/staff_service.dart';
import 'audit_log_screen.dart';
import 'bird_archive_screen.dart';
import 'staff_screen.dart';

const _defaultHost = 'localhost';
const _defaultPort = 8080;
const _defaultPin = '1234';

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
  final _refreshKey = ValueNotifier(0);
  Timer? _pollTimer;
  int _lastVersion = 0;
  String? _token;

  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    setState(() { _connecting = true; _connectError = null; });
    final token = await AuthManager.authenticate(host: _defaultHost, port: _defaultPort, pin: _defaultPin);
    if (token != null) {
      _token = token;
      final auth = AuthManager(host: _defaultHost, port: _defaultPort, pin: _defaultPin, token: token);
      setState(() {
        _logService = AuditLogService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _birdService = BirdArchiveService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _staffService = StaffService(serverHost: _defaultHost, serverPort: _defaultPort, auth: auth);
        _connecting = false;
      });
      _startPolling();
    } else {
      setState(() { _connectError = '无法连接到服务器 $_defaultHost:$_defaultPort'; _connecting = false; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVersion());
  }

  Future<void> _checkVersion() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse('http://$_defaultHost:$_defaultPort/data-version'),
        headers: {'X-Token': _token!},
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final v = int.tryParse(res.body) ?? 0;
        if (v > _lastVersion) { _lastVersion = v; _doRefresh(); }
      }
    } catch (_) {}
  }

  void _doRefresh() => _refreshKey.value++;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _refreshKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) return _buildLoading();
    if (_connectError != null) return _buildError();
    final theme = Theme.of(context);

    final screens = [
      AuditLogScreen(service: _logService!, refreshKey: _refreshKey),
      BirdArchiveScreen(service: _birdService!, refreshKey: _refreshKey),
      StaffScreen(service: _staffService!, refreshKey: _refreshKey),
    ];

    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          labelType: NavigationRailLabelType.all,
          leading: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [
            Icon(Icons.pets, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text('WeightNest', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ])),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: Text('操作日志')),
            NavigationRailDestination(icon: Icon(Icons.pets), selectedIcon: Icon(Icons.pets), label: Text('鹦鹉档案')),
            NavigationRailDestination(icon: Icon(Icons.people), selectedIcon: Icon(Icons.people), label: Text('人员管理')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: Stack(children: [
          IndexedStack(index: _selectedIndex, children: screens),
          Positioned(top: 8, right: 8, child: FloatingActionButton.small(
            onPressed: _doRefresh, tooltip: '刷新数据',
            child: const Icon(Icons.refresh, size: 20),
          )),
        ])),
      ]),
    );
  }

  Widget _buildLoading() => const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.pets, size: 48), SizedBox(height: 16),
    Text('WeightNest 管理端', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    SizedBox(height: 24), CircularProgressIndicator(), SizedBox(height: 12),
    Text('正在连接服务器...'),
  ])));

  Widget _buildError() => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.cloud_off, size: 48, color: Colors.red.shade300), SizedBox(height: 12),
    Text(_connectError!, style: TextStyle(color: Colors.red.shade400)), SizedBox(height: 16),
    FilledButton.icon(onPressed: _autoConnect, icon: const Icon(Icons.refresh), label: const Text('重试连接')),
  ])));
}
