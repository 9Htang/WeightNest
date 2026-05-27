import 'dart:convert';
import 'package:http/http.dart' as http;

/// 共享认证管理器 — 所有 service 共用同一个 token
class AuthManager {
  String _token;
  final String host;
  final int port;
  final String pin;

  AuthManager({required this.host, required this.port, required this.pin, required String token})
      : _token = token;

  String get token => _token;

  Map<String, String> authHeaders() => {'X-Token': '$_token'};

  /// 刷新 token（403 时调用）
  Future<bool> refresh() async {
    try {
      final res = await http.post(
        Uri.parse('http://$host:$port/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin, 'deviceId': 'desktop'}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        _token = (jsonDecode(res.body))['token'] as String;
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<String?> authenticate({required String host, required int port, required String pin}) async {
    try {
      final res = await http.post(
        Uri.parse('http://$host:$port/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin, 'deviceId': 'desktop'}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return (jsonDecode(res.body))['token'] as String;
    } catch (_) {}
    return null;
  }
}
