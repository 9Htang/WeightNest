import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../database/database.dart';
import 'routes.dart';

/// 嵌入式服务器状态
enum ServerState { stopped, starting, running, error }

/// 嵌入式服务器服务
class ServerService {
  final AppDatabase _db;
  HttpServer? _server;
  ServerState _state = ServerState.stopped;
  String? _errorMessage;

  ServerService(this._db);

  ServerState get state => _state;
  String? get errorMessage => _errorMessage;
  int get port => _server?.port ?? 0;

  /// 启动服务器
  Future<void> start({int port = 8080}) async {
    if (_state == ServerState.running) return;
    _state = ServerState.starting;
    _errorMessage = null;

    try {
      final router = createApiRouter(_db);

      // 中间件：CORS + 日志
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, '0.0.0.0', port);
      _state = ServerState.running;

      final ip = await _getLocalIp();
      print('🦜 WeightNest 服务器已启动 → http://$ip:$port');
    } catch (e) {
      _state = ServerState.error;
      _errorMessage = e.toString();
      print('❌ 服务器启动失败: $e');
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _state = ServerState.stopped;
    print('🛑 WeightNest 服务器已停止');
  }

  /// 获取本机局域网 IP
  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final wifiName in ['wlan0', 'en0', 'wlp', 'eth0']) {
        for (final interface in interfaces) {
          if (interface.name.toLowerCase().contains(wifiName)) {
            for (final addr in interface.addresses) {
              if (addr.type == InternetAddressType.IPv4) {
                return addr.address;
              }
            }
          }
        }
      }
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback &&
              !addr.address.startsWith('169.254')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
