import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../server/server_service.dart';
import '../database/database.dart';
import '../providers.dart';

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

  NetworkNotifier(this._db) : super(NetworkState()) {
    _detectLocalIp();
  }

  Future<void> _detectLocalIp() async {
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
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
