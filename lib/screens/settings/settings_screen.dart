import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/network_service.dart';
import '../../services/sync_service.dart';
import '../../services/excel_export_service.dart';
import '../../services/discovery_service.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  String _syncStatus = '';
  String? _exportPath;
  bool _isScanning = false;
  List<DiscoveredServer> _discoveredServers = [];

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final net = ref.watch(networkProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 当前状态 ──
          _StatusCard(net: net, theme: theme),
          const SizedBox(height: 16),

          // ── 服务器模式 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, size: 22),
                      const SizedBox(width: 8),
                      Text('服务器模式', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('作为局域网主机，其他设备可连接到此设备', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (net.isServerRunning) ...[
                    if (net.localIp != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'http://${net.localIp}:${net.serverPort}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                // Copy to clipboard logic would go here
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => ref.read(networkProvider.notifier).stopServer(),
                        child: const Text('停止服务器'),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => ref.read(networkProvider.notifier).startServer(),
                        child: const Text('启动服务器'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 客户端模式 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_android, size: 22),
                      const SizedBox(width: 8),
                      Text('连接服务器', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 自动发现按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : () => _scanNetwork(),
                      icon: _isScanning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.wifi_find, size: 18),
                      label: Text(_isScanning ? '扫描中...' : '扫描局域网设备'),
                    ),
                  ),
                  // 发现的服务器列表
                  if (_discoveredServers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('发现的设备:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    ..._discoveredServers.map((s) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.dns, color: Colors.green, size: 22),
                        title: Text(s.address, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        subtitle: const Text('点击自动填入', style: TextStyle(fontSize: 11)),
                        onTap: () {
                          setState(() {
                            _ipController.text = s.ip;
                            _portController.text = s.port.toString();
                            _discoveredServers = [];
                          });
                        },
                      ),
                    )),
                  ],
                  const SizedBox(height: 8),
                  Text('或手动输入', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: '服务器 IP',
                            hintText: '192.168.x.x',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: '端口',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _testConnection(net),
                          child: const Text('测试连接'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _syncData(net),
                          child: const Text('同步数据'),
                        ),
                      ),
                    ],
                  ),
                  if (net.mode == ConnectionMode.client) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => ref.read(networkProvider.notifier).disconnect(),
                        child: const Text('断开连接'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 数据导出 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, size: 22),
                      const SizedBox(width: 8),
                      Text('数据导出', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('导出全部数据为 Excel 文件', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _exportData(),
                      icon: const Icon(Icons.download),
                      label: const Text('导出 Excel'),
                    ),
                  ),
                  if (_exportPath != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('✅ 已导出: $_exportPath', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_syncStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _syncStatus.contains('成功') ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_syncStatus, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _testConnection(NetworkState net) async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text) ?? 8080;
    if (ip.isEmpty) {
      setState(() => _syncStatus = '请输入服务器 IP');
      return;
    }
    setState(() => _syncStatus = '正在测试...');
    final db = ref.read(databaseProvider);
    final service = SyncService(db, ip, port: port);
    final ok = await service.testConnection();
    setState(() => _syncStatus = ok ? '✅ 连接成功' : '❌ 连接失败');
    if (ok) {
      ref.read(networkProvider.notifier).connectToServer(ip, port: port);
    }
  }

  Future<void> _syncData(NetworkState net) async {
    final ip = net.serverIp ?? _ipController.text.trim();
    final port = net.serverPort;
    if (ip.isEmpty) {
      setState(() => _syncStatus = '请先连接服务器');
      return;
    }
    setState(() => _syncStatus = '正在同步...');
    final db = ref.read(databaseProvider);
    final service = SyncService(db, ip, port: port);
    final result = await service.syncAll();
    if (result.success) {
      setState(() => _syncStatus =
          '✅ 同步成功！鸟${result.birdsSynced} 体重${result.weightsSynced} 房间${result.roomsSynced}');
      ref.invalidate(allBirdsProvider);
      ref.invalidate(allRoomsProvider);
    } else {
      setState(() => _syncStatus = '❌ 同步失败: ${result.error}');
    }
  }

  Future<void> _exportData() async {
    setState(() => _exportPath = '正在导出...');
    try {
      final db = ref.read(databaseProvider);
      final service = ExcelExportService(db);
      final file = await service.exportAll();
      if (file != null) {
        setState(() => _exportPath = file.path);
      } else {
        setState(() => _exportPath = '导出失败：无数据');
      }
    } catch (e) {
      setState(() => _exportPath = '导出失败: $e');
    }
  }

  Future<void> _scanNetwork() async {
    setState(() { _isScanning = true; _discoveredServers = []; });
    final service = DiscoveryService();
    final servers = await service.discover();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _discoveredServers = servers;
        if (servers.isEmpty) {
          _syncStatus = '未发现设备，请检查是否在同一局域网';
        } else {
          _syncStatus = '发现 ${servers.length} 台设备';
        }
      });
    }
  }
}

class _StatusCard extends StatelessWidget {
  final NetworkState net;
  final ThemeData theme;

  const _StatusCard({required this.net, required this.theme});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (net.mode) {
      case ConnectionMode.server:
        icon = Icons.cloud_done;
        color = Colors.green;
        label = '服务器运行中';
        break;
      case ConnectionMode.client:
        icon = Icons.cloud_sync;
        color = Colors.blue;
        label = '已连接 ${net.serverIp}';
        break;
      case ConnectionMode.standalone:
        icon = Icons.phone_iphone;
        color = Colors.grey;
        label = '单机模式';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  net.localIp != null ? '本机: ${net.localIp}' : '检测中...',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
