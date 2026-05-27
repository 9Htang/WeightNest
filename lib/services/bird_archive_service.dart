import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';

class BirdInfo {
  final int id; final String uuid, name; final String? ringNumber;
  final int speciesId; final int? roomId; final DateTime birthDate;
  final String gender, status; final String? notes;
  final String speciesName; final String? roomName;

  BirdInfo({required this.id, required this.uuid, required this.name, this.ringNumber,
    required this.speciesId, this.roomId, required this.birthDate, required this.gender,
    required this.status, this.notes, required this.speciesName, this.roomName});

  factory BirdInfo.fromJson(Map<String, dynamic> json) => BirdInfo(
    id: json['id'], uuid: json['uuid'], name: json['name'], ringNumber: json['ringNumber'],
    speciesId: json['speciesId'], roomId: json['roomId'], birthDate: DateTime.parse(json['birthDate']),
    gender: json['gender'] ?? '未知', status: json['status'] ?? '正常',
    notes: json['notes'], speciesName: json['speciesName'] ?? '', roomName: json['roomName']);

  int get ageDays => DateTime.now().difference(birthDate).inDays;
}

class WeightRecord {
  final int id; final double weightG; final DateTime recordedAt;
  final bool isFasting; final String? notes;

  WeightRecord({required this.id, required this.weightG, required this.recordedAt, required this.isFasting, this.notes});
  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
    id: json['id'], weightG: (json['weightG'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recordedAt']), isFasting: json['isFasting'] ?? false, notes: json['notes']);
}

class BirdArchiveService {
  final String _baseUrl;
  final AuthManager _auth;

  BirdArchiveService({required String serverHost, required int serverPort, required AuthManager auth})
      : _baseUrl = 'http://$serverHost:$serverPort',
        _auth = auth;

  Future<http.Response> _get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (params != null && params.isNotEmpty) uri = uri.replace(queryParameters: params);
    var res = await http.get(uri, headers: _auth.headers).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) {
      await _auth.refresh();
      res = await http.get(uri, headers: _auth.headers).timeout(const Duration(seconds: 10));
    }
    return res;
  }

  Future<List<BirdInfo>> fetchBirds({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _get('/birds', params: params.isNotEmpty ? params : null);
    if (res.statusCode == 200) return (jsonDecode(res.body)['birds'] as List).map((e) => BirdInfo.fromJson(e as Map<String, dynamic>)).toList();
    throw Exception('API 错误: ${res.statusCode}');
  }

  Future<List<WeightRecord>> fetchWeights(int birdId) async {
    final res = await _get('/birds/$birdId/weights');
    if (res.statusCode == 200) return (jsonDecode(res.body)['weights'] as List).map((e) => WeightRecord.fromJson(e as Map<String, dynamic>)).toList();
    throw Exception('API 错误: ${res.statusCode}');
  }
}
