import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers.dart';
import '../../services/discovery_client.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _pinController = TextEditingController(text: '1234');
  bool _scanning = false;
  bool _connecting = false;
  String _status = '';
  String? _myIp;
  String? _discoverDetail;

  @override
  void initState() {
    super.initState();
    _getNetworkInfo();
  }

  Future<void> _getNetworkInfo() async {
    final ip = await DiscoveryClient.getLanIp();
    if (mounted) setState(() => _myIp = ip);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onDetect(String rawValue) {
    if (_connecting) return;
    try {
      final data = jsonDecode(rawValue);
      final host = data['host'] as String?;
      final port = data['port'] as int?;
      final session = data['session'] as String?;
      if (host != null && port != null) {
        _ipController.text = host;
        _portController.text = port.toString();
        if (session != null && session.isNotEmpty) {
          setState(() { _scanning = false; _status = '扫码成功，免密登录中...'; });
          _qrLogin(host, port, session);
          return;
        }
        setState(() { _scanning = false; _status = '已识别: $host:$port，请输入 PIN'; });
      }
    } catch (_) {
      try {
        final uri = Uri.parse(rawValue);
        if (uri.host.isNotEmpty) {
          _ipController.text = uri.host;
          if (uri.hasPort) _portController.text = uri.port.toString();
          setState(() { _scanning = false; _status = '已识别: ${uri.host}:${uri.port}，请输入 PIN'; });
        }
      } catch (_) {}
    }
  }

  /// 自动发现：先 mDNS，再子网扫描
  Future<void> _autoDiscover() async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _status = 'mDNS 搜索中...';
      _discoverDetail = null;
    });

    // mDNS
    final mdns = await DiscoveryClient.discover();
    if (mdns != null && mounted) {
      _applyDiscovery(mdns, 'mDNS 发现');
      return;
    }
    if (!mounted) return;

    // Subnet scan
    if (_myIp != null) {
      setState(() { _status = '扫描局域网...'; _discoverDetail = 'mDNS 未找到，正在逐IP探测'; });
      final scanned = await DiscoveryClient.subnetScan();
      if (scanned != null && mounted) {
        _applyDiscovery(scanned, '子网扫描发现');
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _status = '未找到服务器';
      _discoverDetail = _myIp != null
          ? '请确认桌面端已启动且在同一网络 ($_myIp)'
          : '请先连接 WiFi';
      _connecting = false;
    });
  }

  void _applyDiscovery(DiscoveredServer server, String method) {
    _ipController.text = server.host;
    _portController.text = server.port.toString();
    setState(() {
      _status = '$method: ${server.host}:${server.port}';
      _discoverDetail = '自动填入，点击"连接服务器"继续';
    });
    _connecting = false;
  }

  Future<void> _qrLogin(String host, int port, String session) async {
    setState(() { _connecting = true; _status = '免密登录中...'; });

    try {
      final res = await http.post(
        Uri.parse('http://$host:$port/auth/qr-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session': session, 'deviceId': 'flutter'}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['token'] as String;

        final engine = ref.read(syncEngineProvider);
        await engine.connect(host, port, token);
        engine.start();

        ref.read(syncConnectedProvider.notifier).state = true;

        if (mounted) {
          setState(() { _status = '登录成功，同步数据中...'; _connecting = false; });
          if (mounted) Navigator.of(context).pop(true);
        }
      } else {
        final body = jsonDecode(res.body);
        setState(() { _status = body['error'] ?? '登录失败'; _connecting = false; });
      }
    } catch (e) {
      setState(() { _status = '无法连接: 网络超时或服务器无响应'; _connecting = false; });
    }
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text) ?? 8080;
    final pin = _pinController.text.trim();
    if (ip.isEmpty || pin.isEmpty) return;

    setState(() { _connecting = true; _status = '正在连接 $ip:$port ...'; });

    try {
      final res = await http.post(
        Uri.parse('http://$ip:$port/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin, 'deviceId': 'flutter'}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['token'] as String;

        final engine = ref.read(syncEngineProvider);
        await engine.connect(ip, port, token, pin: pin);
        engine.start();

        ref.read(syncConnectedProvider.notifier).state = true;

        // 保存 PIN 供下次自动发现使用
        final sp = await SharedPreferences.getInstance();
        await sp.setString('connect_pin', pin);

        if (mounted) {
          setState(() { _status = '已连接！同步数据中...'; _connecting = false; });
          if (mounted) Navigator.of(context).pop(true);
        }
      } else if (res.statusCode == 403) {
        setState(() { _status = 'PIN 码错误'; _connecting = false; });
      } else {
        setState(() { _status = '连接失败 (${res.statusCode})'; _connecting = false; });
      }
    } catch (e) {
      if (e is http.ClientException) {
        setState(() { _status = '无法连接: 服务器无响应，请检查 IP 和端口'; _connecting = false; });
      } else {
        setState(() { _status = '连接超时: 请确认设备和服务器在同一网络'; _connecting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_connecting,
      child: Scaffold(
        appBar: AppBar(title: const Text('连接服务器')),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Network info
                  if (_myIp != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.wifi, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text('当前网络: $_myIp',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(children: [
                        Icon(Icons.wifi_off, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('未连接 WiFi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ),

                  // Discovery + QR card
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: _scanning
                        ? SizedBox(
                            height: 250,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MobileScanner(
                                  errorBuilder: (context, error, child) {
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.no_photography, size: 48, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          const Text('无法打开相机', style: TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text('请授予相机权限后重试', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                          const SizedBox(height: 12),
                                          OutlinedButton(
                                            onPressed: () => setState(() => _scanning = false),
                                            child: const Text('手动输入 IP'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDetect: (capture) {
                                    for (final barcode in capture.barcodes) {
                                      if (barcode.rawValue != null) {
                                        _onDetect(barcode.rawValue!);
                                      }
                                    }
                                  },
                                ),
                                Center(
                                  child: Container(
                                    width: 200, height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.greenAccent, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(children: [
                            SizedBox(
                              height: 56,
                              child: Center(
                                child: OutlinedButton.icon(
                                  icon: _connecting
                                      ? const SizedBox(width: 20, height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.wifi_find, size: 24),
                                  label: Text(_connecting ? '搜索中...' : '自动发现服务器'),
                                  onPressed: _connecting ? null : _autoDiscover,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(260, 44),
                                    side: BorderSide(color: Colors.green.shade400),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            SizedBox(
                              height: 56,
                              child: Center(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                                  label: const Text('扫描二维码'),
                                  onPressed: () => setState(() => _scanning = true),
                                ),
                              ),
                            ),
                          ]),
                  ),
                  const SizedBox(height: 16),

                  const Text('或手动输入', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),

                  Row(children: [
                    Expanded(flex: 3, child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(labelText: '服务器 IP', hintText: '192.168.x.x', isDense: true),
                      keyboardType: TextInputType.url,
                      inputFormatters: [],
                    )),
                    const SizedBox(width: 8),
                    Expanded(flex: 1, child: TextField(
                      controller: _portController,
                      decoration: const InputDecoration(labelText: '端口', isDense: true),
                      keyboardType: TextInputType.number,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    decoration: const InputDecoration(labelText: 'PIN 码', isDense: true),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _connecting ? null : _connect,
                    icon: _connecting
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.link),
                    label: Text(_connecting ? '连接中...' : '连接服务器'),
                  ),

                  // Status
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _status == '连接超时: 请确认设备和服务器在同一网络' ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_status,
                          style: TextStyle(fontSize: 13, color: Colors.red.shade800)),
                    ) : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _status.contains('成功') || _status.contains('已连接')
                            ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_status, style: TextStyle(fontSize: 13,
                            color: _status.contains('成功') || _status.contains('已连接')
                                ? Colors.green.shade800 : Colors.orange.shade900)),
                        if (_discoverDetail != null) ...[
                          const SizedBox(height: 4),
                          Text(_discoverDetail!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            if (_connecting)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('连接中...', style: TextStyle(fontSize: 16)),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
