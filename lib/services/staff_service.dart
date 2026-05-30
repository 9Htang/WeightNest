import 'dart:convert';
import 'http/authenticated_client.dart';

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

class StaffService extends AuthenticatedHttpClient {
  StaffService({required super.serverHost, required super.serverPort, required super.auth});

  Future<List<UserInfo>> fetchUsers() async {
    final res = await checkedGet('/users');
    return (jsonDecode(res.body)['users'] as List).map((e) => UserInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createUser({required String username, required String displayName, String password = '', String role = 'keeper'}) async {
    await checkedPost('/users', body: {'username': username, 'displayName': displayName, 'password': password, 'role': role});
  }

  Future<void> updateUser(int id, {String? displayName, String? role, String? password, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (role != null) body['role'] = role;
    if (password != null) body['password'] = password;
    if (isActive != null) body['isActive'] = isActive;
    await checkedPatch('/users/$id', body: body);
  }
}
