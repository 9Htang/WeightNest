import 'dart:convert';
import 'package:http/http.dart' as http;

/// 鹦鹉基本信息
class BirdInfo {
  final int id;
  final String uuid;
  final String name;
  final String? ringNumber;
  final int speciesId;
  final int? roomId;
  final DateTime birthDate;
  final String gender;
  final String status;
  final String? notes;
  final String speciesName;
  final String? roomName;

  BirdInfo({
    required this.id, required this.uuid, required this.name,
    this.ringNumber, required this.speciesId, this.roomId,
    required this.birthDate, required this.gender, required this.status,
    this.notes, required this.speciesName, this.roomName,
  });

  factory BirdInfo.fromJson(Map<String, dynamic> json) => BirdInfo(
    id: json['id'], uuid: json['uuid'], name: json['name'],
    ringNumber: json['ringNumber'], speciesId: json['speciesId'],
    roomId: json['roomId'], birthDate: DateTime.parse(json['birthDate']),
    gender: json['gender'] ?? '未知', status: json['status'] ?? '正常',
    notes: json['notes'], speciesName: json['speciesName'] ?? '',
    roomName: json['roomName'],
  );

  int get ageDays => DateTime.now().difference(birthDate).inDays;
}

/// 体重记录
class WeightRecord {
  final int id;
  final double weightG;
  final DateTime recordedAt;
  final bool isFasting;
  final String? notes;

  WeightRecord({required this.id, required this.weightG, required this.recordedAt, required this.isFasting, this.notes});

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
    id: json['id'], weightG: (json['weightG'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recordedAt']),
    isFasting: json['isFasting'] ?? false, notes: json['notes'],
  );
}

/// 鹦鹉档案 API 服务
class BirdArchiveService {
  String _baseUrl;
  String _token;
  final String _host;
  final int _port;
  final String _pin;

  BirdArchiveService({required String serverHost, required int serverPort, required String token, String pin = '1234'})
      : _host = serverHost,
        _port = serverPort,
        _baseUrl = 'http://$serverHost:$serverPort',
        _token = token,
        _pin = pin;

  Map<String, String> get _headers => {'Authorization': '***'};

  /// 403 时自动重新认证
  Future<void> _ensureAuth() async {
    final newToken = await _authenticate();
    if (newToken != null) _token = newToken;
  }

  Future<String?> _authenticate() async {
    try {
      final res = await http.post(
        Uri.parse('http://$_host:$_port/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': _pin, 'deviceId': 'desktop'}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body))['token'] as String;
      }
    } catch (_) {}
    return null;
  }

  Future<http.Response> _get(String path, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    var res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) {
      await _ensureAuth();
      res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    }
    return res;
  }

  /// 查询鹦鹉列表
  Future<List<BirdInfo>> fetchBirds({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await _get('/birds', queryParams: params.isNotEmpty ? params : null);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['birds'] as List).map((e) => BirdInfo.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('API 错误: ${res.statusCode}');
  }

  /// 查询体重历史
  Future<List<WeightRecord>> fetchWeights(int birdId) async {
    final res = await _get('/birds/$birdId/weights');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['weights'] as List).map((e) => WeightRecord.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('API 错误: ${res.statusCode}');
  }
}
