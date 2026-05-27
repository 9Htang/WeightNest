import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../../providers.dart';

/// 扫码连接页面
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
      if (host != null && port != null) {
        _ipController.text = host;
        _portController.text = port.toString();
        setState(() { _scanning = false; _status = '已识别: $host:$port'; });
      }
    } catch (_) {
      try {
        final uri = Uri.parse(rawValue);
        if (uri.host.isNotEmpty) {
          _ipController.text = uri.host;
          if (uri.hasPort) _portController.text = uri.port.toString();
          setState(() { _scanning = false; _status = '已识别: ${uri.host}:${uri.port}'; });
        }
      } catch (_) {}
    }
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text) ?? 8080;
    final pin = _pinController.text.trim();
    if (ip.isEmpty || pin.isEmpty) return;

    setState(() { _connecting = true; _status = '连接中...'; });

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
        await engine.connect(ip, port, token);
        engine.start();

        if (mounted) {
          setState(() { _status = '✅ 已连接'; _connecting = false; });
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() { _status = '❌ PIN 错误或连接失败'; _connecting = false; });
      }
    } catch (e) {
      setState(() { _status = '❌ 无法连接: $e'; _connecting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('连接服务器')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 扫码区域
            Card(
              clipBehavior: Clip.antiAlias,
              child: _scanning
                  ? SizedBox(
                      height: 250,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
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
                  : SizedBox(
                      height: 120,
                      child: Center(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner, size: 32),
                          label: const Text('扫描二维码'),
                          onPressed: () => setState(() => _scanning = true),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            const Text('或手动输入', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),

            Row(children: [
              Expanded(flex: 3, child: TextField(controller: _ipController,
                decoration: const InputDecoration(labelText: '服务器 IP', hintText: '192.168.x.x', isDense: true))),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: TextField(controller: _portController,
                decoration: const InputDecoration(labelText: '端口', isDense: true),
                keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN 码', isDense: true),
              obscureText: true),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _connecting ? null : _connect,
              icon: _connecting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.link),
              label: Text(_connecting ? '连接中...' : '连接服务器'),
            ),

            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('✅') ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_status, style: TextStyle(fontSize: 13,
                  color: _status.contains('✅') ? Colors.green.shade800 : Colors.orange.shade900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
