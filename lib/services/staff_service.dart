import 'dart:convert';
import 'package:http/http.dart' as http;

/// 用户信息
class UserInfo {
  final int id;
  final String uuid;
  final String username;
  final String displayName;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  UserInfo({
    required this.id, required this.uuid, required this.username,
    required this.displayName, required this.role, required this.createdAt,
    required this.isActive,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'], uuid: json['uuid'], username: json['username'],
    displayName: json['displayName'], role: json['role'] ?? 'keeper',
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'] ?? true,
  );

  String get roleLabel {
    switch (role) {
      case 'admin': return '管理员';
      case 'keeper': return '饲养员';
      case 'viewer': return '查看者';
      default: return role;
    }
  }
}

/// 人员管理 API 服务
class StaffService {
  final String _baseUrl;
  final String _token;

  StaffService({required String serverHost, required int serverPort, required String token})
      : _baseUrl = 'http://$serverHost:$serverPort',
        _token = token;

  Map<String, String> get _headers => {
    'Authorization': '***',
    'Content-Type': 'application/json',
  };

  /// 获取用户列表
  Future<List<UserInfo>> fetchUsers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['users'] as List)
          .map((e) => UserInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('API 错误: ${res.statusCode}');
  }

  /// 创建用户
  Future<void> createUser({
    required String username,
    required String displayName,
    String password = '',
    String role = 'keeper',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'displayName': displayName,
        'password': password,
        'role': role,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('创建失败: ${res.statusCode}');
  }

  /// 更新用户（角色、启停、重置密码）
  Future<void> updateUser(int id, {
    String? displayName,
    String? role,
    String? password,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (role != null) body['role'] = role;
    if (password != null) body['password'] = password;
    if (isActive != null) body['isActive'] = isActive;

    final res = await http.patch(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('更新失败: ${res.statusCode}');
  }
}
