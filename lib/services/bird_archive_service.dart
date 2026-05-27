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

  WeightRecord({
    required this.id, required this.weightG, required this.recordedAt,
    required this.isFasting, this.notes,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
    id: json['id'],
    weightG: (json['weightG'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recordedAt']),
    isFasting: json['isFasting'] ?? false,
    notes: json['notes'],
  );
}

/// 鹦鹉档案 API 服务
class BirdArchiveService {
  final String _baseUrl;
  final String _token;

  BirdArchiveService({required String serverHost, required int serverPort, required String token})
      : _baseUrl = 'http://$serverHost:$serverPort',
        _token = token;

  Map<String, String> get _headers => {'Authorization': '***'};

  /// 查询鹦鹉列表
  Future<List<BirdInfo>> fetchBirds({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$_baseUrl/birds').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['birds'] as List)
          .map((e) => BirdInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('API 错误: ${res.statusCode}');
  }

  /// 查询体重历史
  Future<List<WeightRecord>> fetchWeights(int birdId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/birds/$birdId/weights'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['weights'] as List)
          .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('API 错误: ${res.statusCode}');
  }
}
