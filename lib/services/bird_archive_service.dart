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
    var res = await http.get(uri, headers: _auth.authHeaders()).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) {
      await _auth.refresh();
      res = await http.get(uri, headers: _auth.authHeaders()).timeout(const Duration(seconds: 10));
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

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    var res = await http.patch(Uri.parse('$_baseUrl$path'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.patch(Uri.parse('$_baseUrl$path'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    return res;
  }

  Map<String, String> get _jsonHeaders => {..._auth.authHeaders(), 'Content-Type': 'application/json'};

  Future<void> updateBird(int id, {String? name, int? speciesId, int? roomId, String? status, String? notes, String? ringNumber, int? weighIntervalDays}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (speciesId != null) body['speciesId'] = speciesId;
    if (roomId != null) body['roomId'] = roomId;
    if (status != null) body['status'] = status;
    if (notes != null) body['notes'] = notes;
    if (ringNumber != null) body['ringNumber'] = ringNumber;
    if (weighIntervalDays != null) body['weighIntervalDays'] = weighIntervalDays;
    final res = await _patch('/birds/$id', body);
    if (res.statusCode != 200) throw Exception('更新失败: ${res.statusCode}');
  }

  Future<void> publishTasks(List<int> birdIds) async {
    final body = jsonEncode({'birdIds': birdIds});
    var res = await http.post(Uri.parse('$_baseUrl/tasks/publish'), headers: _jsonHeaders, body: body).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.post(Uri.parse('$_baseUrl/tasks/publish'), headers: _jsonHeaders, body: body).timeout(const Duration(seconds: 10)); }
    if (res.statusCode != 200) throw Exception('发布失败: ${res.statusCode}');
  }
}

class SpeciesInfo {
  final int id; final String uuid, name;
  final int nestlingEndDays, juvenileEndDays;
  final int nestlingWeighIntervalDays, juvenileWeighIntervalDays, adultWeighIntervalDays;

  SpeciesInfo({required this.id, required this.uuid, required this.name,
    required this.nestlingEndDays, required this.juvenileEndDays,
    required this.nestlingWeighIntervalDays, required this.juvenileWeighIntervalDays,
    required this.adultWeighIntervalDays});

  factory SpeciesInfo.fromJson(Map<String, dynamic> j) => SpeciesInfo(
    id: j['id'], uuid: j['uuid'], name: j['name'],
    nestlingEndDays: j['nestlingEndDays'] ?? 45, juvenileEndDays: j['juvenileEndDays'] ?? 120,
    nestlingWeighIntervalDays: j['nestlingWeighIntervalDays'] ?? 1,
    juvenileWeighIntervalDays: j['juvenileWeighIntervalDays'] ?? 3,
    adultWeighIntervalDays: j['adultWeighIntervalDays'] ?? 7,
  );
}

class SpeciesService {
  final String _baseUrl; final AuthManager _auth;
  SpeciesService({required String serverHost, required int serverPort, required AuthManager auth})
      : _baseUrl = 'http://$serverHost:$serverPort', _auth = auth;

  Map<String, String> get _jsonHeaders => {..._auth.authHeaders(), 'Content-Type': 'application/json'};

  Future<List<SpeciesInfo>> fetchAll() async {
    var res = await http.get(Uri.parse('$_baseUrl/species'), headers: _auth.authHeaders()).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.get(Uri.parse('$_baseUrl/species'), headers: _auth.authHeaders()).timeout(const Duration(seconds: 10)); }
    if (res.statusCode == 200) return (jsonDecode(res.body)['species'] as List).map((e) => SpeciesInfo.fromJson(e as Map<String, dynamic>)).toList();
    throw Exception('API 错误: ${res.statusCode}');
  }

  Future<void> create(String name, {int? nestlingEndDays, int? juvenileEndDays, int? nestlingWeighIntervalDays, int? juvenileWeighIntervalDays, int? adultWeighIntervalDays}) async {
    final body = <String, dynamic>{'name': name};
    if (nestlingEndDays != null) body['nestlingEndDays'] = nestlingEndDays;
    if (juvenileEndDays != null) body['juvenileEndDays'] = juvenileEndDays;
    if (nestlingWeighIntervalDays != null) body['nestlingWeighIntervalDays'] = nestlingWeighIntervalDays;
    if (juvenileWeighIntervalDays != null) body['juvenileWeighIntervalDays'] = juvenileWeighIntervalDays;
    if (adultWeighIntervalDays != null) body['adultWeighIntervalDays'] = adultWeighIntervalDays;
    var res = await http.post(Uri.parse('$_baseUrl/species'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.post(Uri.parse('$_baseUrl/species'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    if (res.statusCode != 200) throw Exception('创建失败: ${res.statusCode}');
  }

  Future<void> update(int id, {int? nestlingEndDays, int? juvenileEndDays, int? nestlingWeighIntervalDays, int? juvenileWeighIntervalDays, int? adultWeighIntervalDays}) async {
    final body = <String, dynamic>{};
    if (nestlingEndDays != null) body['nestlingEndDays'] = nestlingEndDays;
    if (juvenileEndDays != null) body['juvenileEndDays'] = juvenileEndDays;
    if (nestlingWeighIntervalDays != null) body['nestlingWeighIntervalDays'] = nestlingWeighIntervalDays;
    if (juvenileWeighIntervalDays != null) body['juvenileWeighIntervalDays'] = juvenileWeighIntervalDays;
    if (adultWeighIntervalDays != null) body['adultWeighIntervalDays'] = adultWeighIntervalDays;
    var res = await http.patch(Uri.parse('$_baseUrl/species/$id'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.patch(Uri.parse('$_baseUrl/species/$id'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    if (res.statusCode != 200) throw Exception('更新失败: ${res.statusCode}');
  }
}

class RoomInfo {
  final int id; final String uuid, name; final int sortOrder;
  final int? assignedUserId; final String assignedUserName; final int birdCount;

  RoomInfo({required this.id, required this.uuid, required this.name, required this.sortOrder,
    this.assignedUserId, required this.assignedUserName, required this.birdCount});

  factory RoomInfo.fromJson(Map<String, dynamic> j) => RoomInfo(
    id: j['id'], uuid: j['uuid'], name: j['name'], sortOrder: j['sortOrder'] ?? 0,
    assignedUserId: j['assignedUserId'], assignedUserName: j['assignedUserName'] ?? '',
    birdCount: j['birdCount'] ?? 0,
  );
}

class RoomService {
  final String _baseUrl; final AuthManager _auth;
  RoomService({required String serverHost, required int serverPort, required AuthManager auth})
      : _baseUrl = 'http://$serverHost:$serverPort', _auth = auth;

  Map<String, String> get _jsonHeaders => {..._auth.authHeaders(), 'Content-Type': 'application/json'};

  Future<List<RoomInfo>> fetchAll() async {
    var res = await http.get(Uri.parse('$_baseUrl/rooms'), headers: _auth.authHeaders()).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.get(Uri.parse('$_baseUrl/rooms'), headers: _auth.authHeaders()).timeout(const Duration(seconds: 10)); }
    if (res.statusCode == 200) return (jsonDecode(res.body)['rooms'] as List).map((e) => RoomInfo.fromJson(e as Map<String, dynamic>)).toList();
    throw Exception('API 错误: ${res.statusCode}');
  }

  Future<void> create(String name, {int? assignedUserId}) async {
    final body = {'name': name, 'assignedUserId': assignedUserId};
    var res = await http.post(Uri.parse('$_baseUrl/rooms'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.post(Uri.parse('$_baseUrl/rooms'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    if (res.statusCode != 200) throw Exception('创建失败: ${res.statusCode}');
  }

  Future<void> update(int id, {String? name, int? sortOrder, int? assignedUserId}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (assignedUserId != null) body['assignedUserId'] = assignedUserId;
    var res = await http.patch(Uri.parse('$_baseUrl/rooms/$id'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) { await _auth.refresh(); res = await http.patch(Uri.parse('$_baseUrl/rooms/$id'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 10)); }
    if (res.statusCode != 200) throw Exception('更新失败: ${res.statusCode}');
  }
}
