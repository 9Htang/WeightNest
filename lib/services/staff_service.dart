import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';

class UserInfo {
  final int id; final String uuid, username, displayName, role; final DateTime createdAt; final bool isActive;
  UserInfo({required this.id, required this.uuid, required this.username,
    required this.displayName, required this.role, required this.createdAt, required this.isActive});
  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'], uuid: json['uuid'], username: json['username'], displayName: json['displayName'],
    role: json['role'] ?? 'keeper', createdAt: DateTime.parse(json['createdAt']), isActive: json['isActive'] ?? true);
  String get roleLabel { switch (role) {
    case 'admin': return '管理员'; case 'keeper': return '饲养员'; case 'viewer': return '查看者'; default: return role; }}
}

class StaffService {
  final String _baseUrl;
  final AuthManager _auth;

  StaffService({required String serverHost, required int serverPort, required AuthManager auth})
      : _baseUrl = 'http://$serverHost:$serverPort',
        _auth = auth;

  Map<String, String> get _jsonHeaders => {..._auth.headers, 'Content-Type': 'application/json'};

  Future<http.Response> _get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (params != null && params.isNotEmpty) uri = uri.replace(queryParameters: params);
    var res = await http.get(uri, headers: _auth.headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.get(uri, headers: _auth.headers).timeout(const Duration(seconds: 10)); }
    return res;
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    var res = await http.post(Uri.parse('$_baseUrl$path'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.post(Uri.parse('$_baseUrl$path'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    return res;
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    var res = await http.patch(Uri.parse('$_baseUrl$path'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.patch(Uri.parse('$_baseUrl$path'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    return res;
  }

  Future<List<UserInfo>> fetchUsers() async {
    final res = await _get('/users');
    if (res.statusCode == 200) return (jsonDecode(res.body)['users'] as List).map((e) => UserInfo.fromJson(e as Map<String, dynamic>)).toList();
    throw Exception('API 错误: ${res.statusCode}');
  }

  Future<void> createUser({required String username, required String displayName, String password = '', String role = 'keeper'}) async {
    final res = await _post('/users', {'username': username, 'displayName': displayName, 'password': password, 'role': role});
    if (res.statusCode != 200) throw Exception('创建失败: ${res.statusCode}');
  }

  Future<void> updateUser(int id, {String? displayName, String? role, String? password, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (role != null) body['role'] = role;
    if (password != null) body['password'] = password;
    if (isActive != null) body['isActive'] = isActive;
    final res = await _patch('/users/$id', body);
    if (res.statusCode != 200) throw Exception('更新失败: ${res.statusCode}');
  }
}
