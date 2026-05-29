import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers.dart';
import '../../screens/worker/worker_screen.dart';
import '../../services/discovery_client.dart';
import '../shell/mobile_shell.dart';
import '../login/login_screen.dart';
import '../connect/connect_screen.dart';

enum _Step { init, mdns, subnet, failed, connecting, done }

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  _Step _step = _Step.init;
  String _status = '';
  String? _myIp;
  DiscoveredServer? _found;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      await _doDiscovery();
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _status = '$e\n\n$st';
      });
    }
  }

  Future<void> _doDiscovery() async {
    final hasCache = ref.read(workerProvider).isSelected;

    // Step 1: get local network info
    setState(() { _step = _Step.init; _status = '检测网络...'; });
    _myIp = await DiscoveryClient.getLanIp();
    if (_myIp == null) {
      setState(() { _status = '未连接到 WiFi，请检查网络'; });
      // Still show UI so user can enter manual IP
    }

    if (!mounted) return;

    // Step 2: mDNS discovery
    setState(() { _step = _Step.mdns; _status = 'mDNS 自动发现...'; });
    _found = await DiscoveryClient.discover();

    if (!mounted) return;

    // Step 3: subnet scan if mDNS failed
    if (_found == null && _myIp != null) {
      setState(() { _step = _Step.subnet; _status = '扫描局域网服务器...'; });
      _found = await DiscoveryClient.subnetScan();
    }

    if (!mounted) return;

    // Step 4: handle result
    if (_found != null) {
      setState(() { _step = _Step.connecting; _status = '找到服务器 ${_found!.host}，连接中...'; });
      final ok = await _connect(_found!.host, _found!.port);
      if (!mounted) return;
      if (ok) {
        _goNext(hasCache);
        return;
      }
      setState(() { _step = _Step.failed; _status = '连接失败: ${_found!.host}:${_found!.port}'; });
    } else {
      setState(() { _step = _Step.failed; });
      if (hasCache) {
        // Cached user → can go offline
        setState(() { _status = '离线模式'; });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _goNext(true);
      }
    }
  }

  Future<bool> _connect(String host, int port) async {
    try {
      final res = await http.post(
        Uri.parse('http://$host:$port/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': '1234', 'deviceId': 'flutter'}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['token'] as String;
        final engine = ref.read(syncEngineProvider);
        await engine.connect(host, port, token, pin: '1234');
        engine.start();
        ref.read(syncConnectedProvider.notifier).state = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _goNext(bool hasCache) {
    if (_step == _Step.done) return;
    _step = _Step.done;

    if (!mounted) return;
    final worker = ref.read(workerProvider);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) {
          try {
            return worker.isSelected
                ? const MobileShell()
                : const LoginScreen();
          } catch (e, st) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: SelectableText('$e\n\n$st',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCache = ref.watch(workerProvider).isSelected;

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

                // Progress indicator
                if (_step != _Step.failed) ...[
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(height: 16),
                  _StepIndicator(step: _step, status: _status, myIp: _myIp),
                ],

                // Failure state
                if (_step == _Step.failed) ...[
                  _FailureContent(
                    status: _status,
                    myIp: _myIp,
                    hasCache: hasCache,
                    onRetry: () => _startDiscovery(),
                    onManual: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ConnectScreen()));
                      if (result == true && mounted) _goNext(hasCache);
                    },
                    onOffline: hasCache ? () => _goNext(true) : null,
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

/// Progress step indicator
class _StepIndicator extends StatelessWidget {
  final _Step step;
  final String status;
  final String? myIp;

  const _StepIndicator({required this.step, required this.status, required this.myIp});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Current status
      Text(status, style: const TextStyle(fontSize: 15, color: Colors.grey)),
      const SizedBox(height: 20),

      // Steps
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _StepDot(label: '网络', done: step.index >= _Step.init.index && myIp != null,
            active: step == _Step.init),
        _StepLine(done: step.index > _Step.init.index),
        _StepDot(label: 'mDNS', done: step.index > _Step.mdns.index,
            active: step == _Step.mdns),
        _StepLine(done: step.index > _Step.mdns.index),
        _StepDot(label: '扫描', done: step.index > _Step.subnet.index,
            active: step == _Step.subnet),
        _StepLine(done: step.index > _Step.subnet.index),
        _StepDot(label: '连接', done: step.index > _Step.connecting.index,
            active: step == _Step.connecting),
      ]),

      const SizedBox(height: 12),
      if (myIp != null)
        Text('本机: $myIp', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    ]);
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StepDot({required this.label, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (done) {
      color = Colors.green;
    } else if (active) {
      color = Theme.of(context).colorScheme.primary;
    } else {
      color = Colors.grey.shade300;
    }
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: done
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : active
                ? const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({this.done = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: done ? Colors.green : Colors.grey.shade200,
    );
  }
}

/// Failure content with action buttons
class _FailureContent extends StatelessWidget {
  final String status;
  final String? myIp;
  final bool hasCache;
  final VoidCallback onRetry;
  final VoidCallback onManual;
  final VoidCallback? onOffline;

  const _FailureContent({
    required this.status,
    required this.myIp,
    required this.hasCache,
    required this.onRetry,
    required this.onManual,
    this.onOffline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewUserNoNetwork = !hasCache && myIp == null;

    return Column(children: [
      Icon(
        isNewUserNoNetwork ? Icons.wifi_off : Icons.cloud_off,
        size: 48,
        color: Colors.grey.shade400,
      ),
      const SizedBox(height: 12),
      Text(
        isNewUserNoNetwork ? '无法连接网络' : '未找到服务器',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),

      // actionable hint
      if (myIp != null) ...[
        Text('WiFi: $myIp', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(status, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ] else ...[
        Text('请连接到 WiFi 网络后重试',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
      const SizedBox(height: 24),

      FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('重试'),
        style: FilledButton.styleFrom(minimumSize: const Size(200, 44)),
      ),
      const SizedBox(height: 12),

      OutlinedButton.icon(
        onPressed: onManual,
        icon: const Icon(Icons.edit, size: 20),
        label: const Text('手动输入 IP'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(200, 44)),
      ),

      if (onOffline != null) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: onOffline,
          child: const Text('离线模式进入', style: TextStyle(fontSize: 14)),
        ),
      ],

      if (isNewUserNoNetwork) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.info_outline, size: 16, color: Colors.amber),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '首次使用需要连接服务器获取账号\n请确保手机和服务器在同一 WiFi',
                style: TextStyle(fontSize: 12, color: Colors.brown),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ],
    ]);
  }
}
