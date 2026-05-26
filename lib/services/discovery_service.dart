import 'dart:async';
import 'dart:io';
import 'dart:convert';

/// 局域网自动发现服务
/// 服务端：监听 UDP 广播，回复本机 IP + 端口
/// 客户端：发送广播，收集可用服务器列表

class DiscoveryService {
  static const int _discoveryPort = 8082;
  static const String _multicastGroup = '239.255.0.1'; // 组播备用

  RawDatagramSocket? _socket;
  StreamSubscription? _subscription;
  bool _isServer = false;

  /// 获取子网广播地址 (如 192.168.1.255)
  static Future<String?> _getSubnetBroadcast() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              addr.address.startsWith('192.168.')) {
            // 从 IP 和子网掩码计算广播地址
            final parts = addr.address.split('.');
            // 常见家用路由器 /24 子网
            return '${parts[0]}.${parts[1]}.${parts[2]}.255';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// 启动服务端发现（响应客户端的扫描请求）
  Future<void> startServer(String serverIp, int serverPort) async {
    if (_socket != null) return;
    _isServer = true;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _discoveryPort);
    _socket!.broadcastEnabled = true;
    _socket!.multicastLoopback = false;

    // 加入组播组 — 部分路由器阻断广播但放行组播
    try {
      _socket!.joinMulticast(InternetAddress(_multicastGroup));
      print('📡 已加入组播组 $_multicastGroup');
    } catch (_) {
      print('⚠️ 无法加入组播组，仅使用广播');
    }

    _subscription = _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket!.receive();
      if (datagram == null) return;
      final msg = utf8.decode(datagram.data);
      if (msg == 'WEIGHTNEST_DISCOVER') {
        // 回复本机信息
        final response = jsonEncode({
          'type': 'WEIGHTNEST_SERVER',
          'ip': serverIp,
          'port': serverPort,
          'version': '1.6.2',
        });
        _socket!.send(
          utf8.encode(response),
          datagram.address,
          datagram.port,
        );
      }
    });

    print('🔄 局域网发现服务已启动 (UDP $_discoveryPort)');
  }

  /// 客户端扫描局域网
  /// 返回发现的服务器列表 [{ip, port, version}]
  Future<List<DiscoveredServer>> discover({Duration timeout = const Duration(seconds: 3)}) async {
    final servers = <DiscoveredServer>[];
    final completer = Completer<List<DiscoveredServer>>();

    RawDatagramSocket? client;
    try {
      client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      client.broadcastEnabled = true;

      client.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = client!.receive();
        if (datagram == null) return;
        try {
          final data = jsonDecode(utf8.decode(datagram.data));
          if (data['type'] == 'WEIGHTNEST_SERVER') {
            final ip = datagram.address.address;
            final port = data['port'] as int;
            // 去重
            if (!servers.any((s) => s.ip == ip && s.port == port)) {
              servers.add(DiscoveredServer(
                ip: ip,
                port: port,
                version: data['version'] ?? '',
              ));
            }
          }
        } catch (_) {}
      });

      // 广播发现请求 — 三保险：全局广播 + 子网广播 + 组播
      // 某些 Android 设备/路由器会丢掉 255.255.255.255，但接受子网广播或组播
      client.send(
        utf8.encode('WEIGHTNEST_DISCOVER'),
        InternetAddress('255.255.255.255'),
        _discoveryPort,
      );
      final subnetBroadcast = await _getSubnetBroadcast();
      if (subnetBroadcast != null) {
        client.send(
          utf8.encode('WEIGHTNEST_DISCOVER'),
          InternetAddress(subnetBroadcast),
          _discoveryPort,
        );
      }
      // 组播通道
      try {
        client.send(
          utf8.encode('WEIGHTNEST_DISCOVER'),
          InternetAddress(_multicastGroup),
          _discoveryPort,
        );
      } catch (_) {}

      // 等待收集响应
      Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(servers);
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(servers);
    }

    return completer.future;
  }

  /// 停止服务
  Future<void> stop() async {
    await _subscription?.cancel();
    if (_socket != null && _isServer) {
      try { _socket!.leaveMulticast(InternetAddress(_multicastGroup)); } catch (_) {}
    }
    _socket?.close();
    _socket = null;
    _subscription = null;
    _isServer = false;
  }
}

class DiscoveredServer {
  final String ip;
  final int port;
  final String version;

  DiscoveredServer({required this.ip, required this.port, this.version = ''});

  String get address => '$ip:$port';
}
