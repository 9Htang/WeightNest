import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database.dart';
import '../repositories/species_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import 'sync_queue_service.dart';

/// 同步引擎 — 后台定时推送操作 + 拉取服务端变更
class SyncEngine {
  final AppDatabase _db;
  final SyncQueueService _queue;
  Timer? _timer;
  String? _serverHost;
  int _serverPort = 8080;
  String? _token;
  DateTime _lastPull = DateTime(2000);

  SyncEngine(this._db, this._queue);

  bool get isConnected => _token != null;

  /// 连接到服务器
  Future<bool> connect(String host, int port, String token) async {
    _serverHost = host;
    _serverPort = port;
    _token = token;
    // 立即拉取一次
    await pullChanges();
    return true;
  }

  /// 设置服务端地址
  void setServer(String host, int port) {
    _serverHost = host;
    _serverPort = port;
  }

  void setToken(String token) => _token = token;

  /// 启动定时同步
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
    _tick(); // 立即执行一次
  }

  void stop() => _timer?.cancel();

  Future<void> _tick() async {
    if (_token == null || _serverHost == null) return;
    await pushOperations();
    await pullChanges();
  }

  // ─── 上传 ───

  Future<void> pushOperations() async {
    final ops = await _queue.getUnsynced(batchSize: 50);
    if (ops.isEmpty) return;

    final payload = ops.map((o) => {
      'opId': o.opId,
      'deviceId': o.deviceId,
      'userId': o.userId,
      'action': o.action,
      'entityType': o.entityType,
      'entityUuid': o.entityUuid,
      'payload': jsonDecode(o.payload),
      'createdAt': o.createdAt.toIso8601String(),
    }).toList();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final successOps = List<String>.from(body['successOps'] ?? []);
        await _queue.markSynced(successOps);
      }
    } catch (_) {
      // 网络不通，下次重试
    }
  }

  // ─── 下载（增量） ───

  Future<void> pullChanges() async {
    if (_serverHost == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/changes?since=${_lastPull.millisecondsSinceEpoch}'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        await _applyChanges(body['changes'] as List? ?? []);
        _lastPull = DateTime.now();
      }
    } catch (_) {}
  }

  Future<void> _applyChanges(List changes) async {
    for (final c in changes) {
      final type = c['entityType'] as String;
      final data = c['data'] as Map<String, dynamic>;
      try {
        switch (type) {
          case 'species':
            await _applySpecies(data);
            break;
          case 'room':
            await _applyRoom(data);
            break;
          case 'user':
            await _applyUser(data);
            break;
          case 'bird':
            await _applyBird(data);
            break;
          case 'weight':
            await _applyWeight(data);
            break;
        }
      } catch (_) {}
    }
  }

  Future<void> _applySpecies(Map<String, dynamic> d) async {
    final existing = await _db.getSpeciesByName(d['name']);
    if (existing != null) return;
    await _db.createSpecies(d['name'],
      nestlingEndDays: d['nestlingEndDays'] ?? 45,
      juvenileEndDays: d['juvenileEndDays'] ?? 120,
      adultWeighIntervalDays: d['adultWeighIntervalDays'] ?? 7,
    );
  }

  Future<void> _applyRoom(Map<String, dynamic> d) async {
    final existing = await _db.getRoomByName(d['name']);
    if (existing != null) return;
    await _db.createRoom(d['name']);
  }

  Future<void> _applyUser(Map<String, dynamic> d) async {
    final existing = await _db.getByUsername(d['username']);
    if (existing != null) return;
    await _db.createUser(d['username'], d['displayName'], d['passwordHash'] ?? '',
      role: d['role'] ?? 'keeper');
  }

  Future<void> _applyBird(Map<String, dynamic> d) async {
    final existing = await _db.getBirdByNameAndBirth(
      d['name'],
      DateTime.parse(d['birthDate']),
    );
    if (existing != null) return;
    await _db.createBird(
      name: d['name'],
      speciesId: d['speciesId'] ?? 1,
      birthDate: DateTime.parse(d['birthDate']),
      roomId: d['roomId'] as int?,
      ringNumber: d['ringNumber'] as String?,
      gender: d['gender'] as String? ?? '未知',
    );
  }

  Future<void> _applyWeight(Map<String, dynamic> d) async {
    final birdId = d['birdId'] as int;
    final recordedAt = DateTime.parse(d['recordedAt']);
    final exists = await _db.checkWeightExists(birdId, recordedAt);
    if (exists) return;
    await _db.addWeight(
      birdId: birdId,
      weightG: (d['weightG'] as num).toDouble(),
      recordedAt: recordedAt,
      recordedBy: d['recordedBy'] as int?,
      isFasting: d['isFasting'] as bool? ?? true,
    );
  }

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  String? get _baseUrl =>
      _serverHost != null ? 'http://$_serverHost:$_serverPort' : null;
}
