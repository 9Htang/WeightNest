import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../server/server_service.dart';
import '../database/database.dart';
import '../providers.dart';
import 'discovery_service.dart';

/// 客户端连接状态
enum ConnectionMode { standalone, server, client }

class NetworkState {
  final ConnectionMode mode;
  final ServerService? serverService;
  final String? serverIp;
  final int serverPort;
  final String? localIp;
  final bool isServerRunning;

  NetworkState({
    this.mode = ConnectionMode.standalone,
    this.serverService,
    this.serverIp,
    this.serverPort = 8080,
    this.localIp,
    this.isServerRunning = false,
  });

  NetworkState copyWith({
    ConnectionMode? mode,
    ServerService? serverService,
    String? serverIp,
    int? serverPort,
    String? localIp,
    bool? isServerRunning,
  }) =>
      NetworkState(
        mode: mode ?? this.mode,
        serverService: serverService ?? this.serverService,
        serverIp: serverIp ?? this.serverIp,
        serverPort: serverPort ?? this.serverPort,
        localIp: localIp ?? this.localIp,
        isServerRunning: isServerRunning ?? this.isServerRunning,
      );
}

class NetworkNotifier extends StateNotifier<NetworkState> {
  final AppDatabase _db;
  final DiscoveryService _discovery = DiscoveryService();

  NetworkNotifier(this._db) : super(NetworkState()) {
    _detectLocalIp();
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      // 优先找物理局域网接口（排除 VPN 虚拟适配器）
      for (final wifiName in ['wlan', 'en0', 'eth', 'Wi-Fi', '以太网']) {
        for (final interface in interfaces) {
          final name = interface.name.toLowerCase();
          // 跳过 VPN 接口
          if (name.contains('vpn') || name.contains('tun') ||
              name.contains('utun') || name.contains('tap') ||
              name.contains('ppp') || name.contains('pppoe')) continue;
          if (!name.contains(wifiName.toLowerCase())) continue;
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              final ip = addr.address;
              // 优先 192.168.x.x（局域网段）
              if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
                if (!ip.startsWith('169.254')) {
                  state = state.copyWith(localIp: ip);
                  return;
                }
              }
            }
          }
        }
      }
      // 回退：找第一个非 loopback 的 192.168 地址
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('vpn') || name.contains('tun') || name.contains('utun')) continue;
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback &&
              addr.address.startsWith('192.168.')) {
            state = state.copyWith(localIp: addr.address);
            return;
          }
        }
      }
      // 最后兜底：任意非 loopback IPv4，但也排除 169.254（自动配置）
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback &&
              !addr.address.startsWith('169.254') &&
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('0.')) {
            state = state.copyWith(localIp: addr.address);
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> startServer({int port = 8080}) async {
    final service = ServerService(_db);
    await service.start(port: port);
    await _detectLocalIp(); // 刷新 IP
    state = state.copyWith(
      mode: ConnectionMode.server,
      serverService: service,
      serverPort: port,
      isServerRunning: true,
    );
  }

  Future<void> stopServer() async {
    await _discovery.stop();
    await state.serverService?.stop();
    state = state.copyWith(
      mode: ConnectionMode.standalone,
      serverService: null,
      isServerRunning: false,
    );
  }

  void connectToServer(String ip, {int port = 8080}) {
    state = state.copyWith(
      mode: ConnectionMode.client,
      serverIp: ip,
      serverPort: port,
    );
  }

  void disconnect() {
    state = state.copyWith(
      mode: ConnectionMode.standalone,
      serverIp: null,
    );
  }
}

final networkProvider =
    StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  final db = ref.watch(databaseProvider);
  return NetworkNotifier(db);
});
