import 'dart:convert';
import 'package:http/http.dart' as http;

/// 审计日志条目
class AuditLogEntry {
  final int id;
  final String entityType;
  final String entityUuid;
  final Map<String, dynamic> data;
  final String? action;
  final DateTime createdAt;
  final int? userId;
  final String userName;

  AuditLogEntry({
    required this.id,
    required this.entityType,
    required this.entityUuid,
    required this.data,
    this.action,
    required this.createdAt,
    this.userId,
    required this.userName,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      entityType: json['entityType'],
      entityUuid: json['entityUuid'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      action: json['action'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      userName: json['userName'] ?? '未知',
    );
  }

  String get actionLabel {
    switch (action) {
      case 'create_bird': return '新建鹦鹉';
      case 'update_bird': return '编辑鹦鹉';
      case 'add_weight': return '记录体重';
      case 'create_room': return '新建房间';
      case 'create_species': return '新建品种';
      case 'create_user': return '新建用户';
      default: return action ?? '未知操作';
    }
  }

  String get entityLabel {
    switch (entityType) {
      case 'bird': return '鹦鹉';
      case 'weight': return '体重';
      case 'room': return '房间';
      case 'species': return '品种';
      case 'user': return '用户';
      default: return entityType;
    }
  }
}

/// 审计日志分页结果
class AuditLogPage {
  final List<AuditLogEntry> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  AuditLogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory AuditLogPage.fromJson(Map<String, dynamic> json) {
    return AuditLogPage(
      items: (json['items'] as List)
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

/// 审计日志 API 服务
class AuditLogService {
  final String _baseUrl;
  final String _token;

  AuditLogService({required String serverHost, required int serverPort, required String token})
      : _baseUrl = 'http://$serverHost:$serverPort',
        _token = token;

  /// 查询审计日志
  Future<AuditLogPage> fetchLogs({
    int? userId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (userId != null) params['userId'] = '$userId';
    if (action != null && action.isNotEmpty) params['action'] = action;
    if (entityType != null && entityType.isNotEmpty) params['entityType'] = entityType;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse('$_baseUrl/audit-log').replace(queryParameters: params);
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $_token',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return AuditLogPage.fromJson(jsonDecode(res.body));
    }
    throw Exception('API 错误: ${res.statusCode}');
  }

  /// 认证连接
  static Future<String?> authenticate({
    required String serverHost,
    required int serverPort,
    required String pin,
    String deviceId = 'desktop',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('http://$serverHost:$serverPort/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin, 'deviceId': deviceId}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['token'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
