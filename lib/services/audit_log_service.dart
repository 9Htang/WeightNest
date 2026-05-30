import 'dart:convert';
import 'http/authenticated_client.dart';

class AuditLogEntry {
  final int id; final String entityType, entityUuid; final Map<String, dynamic> data;
  final String? action; final DateTime createdAt; final int? userId; final String userName;

  AuditLogEntry({required this.id, required this.entityType, required this.entityUuid,
    required this.data, this.action, required this.createdAt, this.userId, required this.userName});

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
    id: json['id'], entityType: json['entityType'], entityUuid: json['entityUuid'],
    data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
    action: json['action'], createdAt: DateTime.parse(json['createdAt']),
    userId: json['userId'], userName: json['userName'] ?? '未知');

  String get actionLabel { switch (action) {
    case 'create_bird': return '新建鹦鹉'; case 'update_bird': return '编辑鹦鹉';
    case 'add_weight': return '记录体重'; case 'edit_weight': return '修改体重';
    case 'delete_weight': return '删除体重'; case 'create_room': return '新建房间';
    case 'create_species': return '新建品种'; case 'create_user': return '新建用户';
    default: return action ?? '未知操作'; }}

  String get entityLabel { switch (entityType) {
    case 'bird': return '鹦鹉'; case 'weight': return '体重'; case 'room': return '房间';
    case 'species': return '品种'; case 'user': return '用户'; default: return entityType; }}
}

class AuditLogPage {
  final List<AuditLogEntry> items; final int total, page, pageSize, totalPages;
  AuditLogPage({required this.items, required this.total, required this.page, required this.pageSize, required this.totalPages});
  factory AuditLogPage.fromJson(Map<String, dynamic> json) => AuditLogPage(
    items: (json['items'] as List).map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>)).toList(),
    total: json['total'], page: json['page'], pageSize: json['pageSize'], totalPages: json['totalPages']);
}

class AuditLogService extends AuthenticatedHttpClient {
  AuditLogService({required super.serverHost, required super.serverPort, required super.auth});

  Future<AuditLogPage> fetchLogs({int? userId, String? action, String? entityType,
    DateTime? startDate, DateTime? endDate, int page = 1, int pageSize = 50}) async {
    final params = <String, String>{'page': '$page', 'pageSize': '$pageSize'};
    if (userId != null) params['userId'] = '$userId';
    if (action != null && action.isNotEmpty) params['action'] = action;
    if (entityType != null && entityType.isNotEmpty) params['entityType'] = entityType;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    final res = await checkedGet('/audit-log', params: params);
    return AuditLogPage.fromJson(jsonDecode(res.body));
  }
}
