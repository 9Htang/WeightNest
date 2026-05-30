import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../services/log/app_logger.dart';
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
      final apiRouter = createApiRouter(_db);
      final router = Router()..mount('/api/', apiRouter.call);

      // 中间件：CORS + 日志
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, '0.0.0.0', port);
      _state = ServerState.running;

      final ip = await _getLocalIp();
      AppLogger.info('ServerService', '服务器已启动 → http://$ip:$port');
    } catch (e) {
      _state = ServerState.error;
      _errorMessage = e.toString();
      AppLogger.error('ServerService', '服务器启动失败', e);
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _state = ServerState.stopped;
    AppLogger.info('ServerService', '服务器已停止');
  }

  /// 获取本机局域网 IP
  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      // 优先物理接口，排除 VPN
      for (final name in ['wlan', 'en0', 'eth', 'Wi-Fi', '以太网']) {
        for (final interface in interfaces) {
          final n = interface.name.toLowerCase();
          if (n.contains('vpn') || n.contains('tun') || n.contains('utun') || n.contains('tap')) continue;
          if (!n.contains(name.toLowerCase())) continue;
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 &&
                addr.address.startsWith('192.168.')) {
              return addr.address;
            }
          }
        }
      }
      // 回退
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback &&
              addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
