import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database.dart';
import '../repositories/species_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/task_repository.dart';
import 'sync_queue_service.dart';

/// 同步引擎 — 后台定时推送操作 + 拉取服务端变更
class SyncEngine {
  final AppDatabase _db;
  final SyncQueueService _queue;
  Timer? _pushTimer;
  Timer? _sseReconnectTimer;
  http.Client? _sseClient;
  String? _serverHost;
  int _serverPort = 8080;
  String? _token;
  String? _pin;
  DateTime _lastPull = DateTime(2000);

  SyncEngine(this._db, this._queue);

  void Function()? onWeightChanged;

  bool get isConnected => _token != null;
  String? get serverHost => _serverHost;
  int get serverPort => _serverPort;

  /// 连接到服务器（pin 用于 403 自动重连）
  Future<bool> connect(String host, int port, String token, {String? pin}) async {
    _serverHost = host;
    _serverPort = port;
    _token = token;
    _pin = pin;
    // ① 全量拉取基础数据（UUID 锚定）
    await _fullSyncSpecies();
    await _fullSyncRooms();
    await _fullSyncUsers();
    // ② 全量拉取鹦鹉（名称+日期去重）
    await _fullSyncBirds();
    // ③ 增量拉取其他变更
    await pullChanges();
    return true;
  }

  /// 全量拉取品种列表并按 UUID upsert
  Future<void> _fullSyncSpecies() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/species'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['species'] as List;
      for (final sp in list) {
        await _applySpecies(sp as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _fullSyncRooms() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/rooms'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['rooms'] as List;
      for (final r in list) {
        final name = r['name'] as String;
        final assignedId = r['assignedUserId'] as int?;
        final existing = await _db.getRoomByName(name);
        if (existing != null) {
          await _db.updateRoom(existing.id, name: name, assignedUserId: assignedId);
        } else {
          await _db.createRoom(name, assignedUserId: assignedId);
        }
      }
    } catch (_) {}
  }

  Future<void> _fullSyncUsers() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['users'] as List;
      for (final u in list) {
        final username = u['username'] as String;
        final existing = await _db.getByUsername(username);
        if (existing == null) {
          await _db.createUser(username, u['displayName'] as String, '',
            role: u['role'] as String? ?? 'keeper');
        }
      }
    } catch (_) {}
  }

  Future<void> _fullSyncBirds() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/birds'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['birds'] as List;
      for (final b in list) {
        final name = b['name'] as String;
        final birthDate = DateTime.parse(b['birthDate']);
        final serverUuid = b['uuid'] as String;
        final existing = await _db.getBirdByNameAndBirth(name, birthDate);
        if (existing == null) {
          final speciesName = b['speciesName'] as String?;
          final roomName = b['roomName'] as String?;

          int? localSpeciesId = 1;
          if (speciesName != null) {
            final sp = await _db.getSpeciesByName(speciesName);
            localSpeciesId = sp?.id ?? 1;
          }
          int? localRoomId;
          if (roomName != null) {
            final room = await _db.getRoomByName(roomName);
            localRoomId = room?.id;
          }

          await _db.createBird(
            name: name,
            speciesId: localSpeciesId,
            birthDate: birthDate,
            roomId: localRoomId,
            ringNumber: b['ringNumber'] as String?,
            gender: b['gender'] as String? ?? '未知',
            uuid: serverUuid,
          );
        } else if (existing.uuid != serverUuid) {
          await _db.updateBirdUuid(existing.id, serverUuid);
        }
      }
    } catch (_) {}
  }

  /// 设置服务端地址
  void setServer(String host, int port) {
    _serverHost = host;
    _serverPort = port;
  }

  void setToken(String token) => _token = token;

  /// 启动 SSE 监听 + 定时推送
  void start() {
    _sseReconnectTimer?.cancel();
    _sseReconnectTimer = Timer(const Duration(seconds: 0), () => _listenSSE());
    // Push timer — every 5 seconds
    _pushTimer?.cancel();
    _pushTimer = Timer.periodic(const Duration(seconds: 5), (_) => pushOperations());
    pushOperations();
  }

  void stop() {
    _pushTimer?.cancel();
    _sseReconnectTimer?.cancel();
    _sseClient?.close();
    _sseClient = null;
  }

  /// 断开连接
  void disconnect() {
    stop();
    _token = null;
    _pin = null;
    _serverHost = null;
  }

  /// 403 时自动重新认证
  Future<void> _reAuth() async {
    final pin = _pin;
    final base = _baseUrl;
    if (pin == null || base == null) return;
    try {
      final res = await http.post(
        Uri.parse('$base/auth/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin, 'deviceId': 'flutter'}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        _token = jsonDecode(res.body)['token'];
      }
    } catch (_) {}
  }

  /// SSE 长连接监听服务端推送
  Future<void> _listenSSE() async {
    if (_token == null || _serverHost == null) return;
    _sseClient?.close();

    try {
      final request = http.Request('GET',
        Uri.parse('$_baseUrl/changes/stream?since=${_lastPull.millisecondsSinceEpoch}'));
      request.headers['X-Token'] = _token!;

      _sseClient = http.Client();
      final response = await _sseClient!.send(request).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        _scheduleReconnect();
        return;
      }

      // Parse SSE stream
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n\n')) {
          final idx = buffer.indexOf('\n\n');
          final line = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);

          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.contains('"eof"')) break;
            try {
              final change = jsonDecode(data) as Map<String, dynamic>;
              await _applyChanges([change]);
              _lastPull = DateTime.now();
            } catch (_) {}
          }
          // Heartbeat comments (": heartbeat") — ignored
        }
      }
    } catch (_) {}

    // Reconnect after 2 seconds
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _sseReconnectTimer?.cancel();
    _sseReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_token != null) _listenSSE();
    });
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
      final token = _token;
      if (token == null) return;
      final res = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          'X-Token': token,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final successOps = List<String>.from(body['successOps'] ?? []);
        await _queue.markSynced(successOps);
        // Auto-complete tasks for synced weight operations
        await _autoCompleteTasksForWeights(ops, successOps);
      } else if (res.statusCode == 403) {
        await _reAuth();
        final token2 = _token;
        if (token2 != null) {
          final retry = await http.post(
            Uri.parse('$_baseUrl/sync'),
            headers: {'Content-Type': 'application/json', 'X-Token': token2},
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 10));
          if (retry.statusCode == 200) {
            final body = jsonDecode(retry.body);
            final successOps = List<String>.from(body['successOps'] ?? []);
            await _queue.markSynced(successOps);
            await _autoCompleteTasksForWeights(ops, successOps);
          }
        }
      }
    } catch (_) {}
  }

  /// Auto-complete today's tasks when weight ops are confirmed by server
  Future<void> _autoCompleteTasksForWeights(List<SyncQueueData> ops, List<String> successOpIds) async {
    final today = DateTime.now();

    for (final op in ops) {
      if (!successOpIds.contains(op.opId) || op.action != 'add_weight') continue;
      try {
        final payload = jsonDecode(op.payload) as Map<String, dynamic>;
        final birdId = payload['birdId'] as int?;
        if (birdId == null) continue;

        // Find today's pending task for this bird
        final tasks = await _db.getTodayTasks(null);
        final task = tasks.where((t) =>
            t.bird.id == birdId && t.task.status == '待完成').firstOrNull;

        if (task != null) {
          await _db.completeTask(task.task.id, op.userId);
        }
      } catch (_) {}
    }
  }

  // ─── 下载（增量） ───

  Future<void> pullChanges() async {
    if (_serverHost == null) return;
    try {
      final token = _token;
      if (token == null) return;
      final res = await http.get(
        Uri.parse('$_baseUrl/changes?since=${_lastPull.millisecondsSinceEpoch}'),
        headers: {'X-Token': token},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        await _applyChanges(body['changes'] as List? ?? []);
        _lastPull = DateTime.now();
      } else if (res.statusCode == 403) {
        await _reAuth();
        final token2 = _token;
        if (token2 != null) {
          final retry = await http.get(
            Uri.parse('$_baseUrl/changes?since=${_lastPull.millisecondsSinceEpoch}'),
            headers: {'X-Token': token2},
          ).timeout(const Duration(seconds: 10));
          if (retry.statusCode == 200) {
            final body = jsonDecode(retry.body);
            await _applyChanges(body['changes'] as List? ?? []);
            _lastPull = DateTime.now();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _applyChanges(List changes) async {
    for (final c in changes) {
      final type = c['entityType'] as String;
      final action = c['action'] as String?;
      final data = c['data'] as Map<String, dynamic>;
      final entityUuid = c['entityUuid'] as String?;
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
            await _applyBird(data, entityUuid);
            break;
          case 'weight':
            if (action == 'delete_weight') {
              await _applyWeightDelete(data, entityUuid);
            } else if (action == 'edit_weight') {
              await _applyWeightEdit(data, entityUuid);
            } else {
              await _applyWeight(data);
            }
            break;
          case 'task':
            await _applyTask(data);
            break;
        }
      } catch (_) {}
    }
  }

  Future<void> _applySpecies(Map<String, dynamic> d) async {
    final uuid = d['uuid'] as String?;
    final name = d['name'] as String?;
    if (uuid == null || name == null) return;

    // Check by UUID first, then by name to avoid duplicates
    final byUuid = await _db.getSpeciesByUuid(uuid);
    if (byUuid != null) {
      await _db.updateSpecies(byUuid.id,
        name: name,
        nestlingEndDays: d['nestlingEndDays'] ?? 45,
        juvenileEndDays: d['juvenileEndDays'] ?? 120,
        nestlingWeighIntervalDays: d['nestlingWeighIntervalDays'] ?? 1,
        juvenileWeighIntervalDays: d['juvenileWeighIntervalDays'] ?? 3,
        adultWeighIntervalDays: d['adultWeighIntervalDays'] ?? 7,
      );
      return;
    }
    // Match by name — link local record to server UUID
    final byName = await _db.getSpeciesByNameSafe(name);
    if (byName != null) {
      await _db.updateSpeciesUuid(byName.id, uuid);
      return;
    }
    await _db.createSpecies(name,
      nestlingEndDays: d['nestlingEndDays'] ?? 45,
      juvenileEndDays: d['juvenileEndDays'] ?? 120,
      nestlingWeighIntervalDays: d['nestlingWeighIntervalDays'] ?? 1,
      juvenileWeighIntervalDays: d['juvenileWeighIntervalDays'] ?? 3,
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

  Future<void> _applyBird(Map<String, dynamic> d, String? serverUuid) async {
    final existing = await _db.getBirdByNameAndBirth(
      d['name'],
      DateTime.parse(d['birthDate']),
    );
    if (existing != null) {
      if (serverUuid != null && existing.uuid != serverUuid) {
        await _db.updateBirdUuid(existing.id, serverUuid);
      }
      return;
    }
    await _db.createBird(
      name: d['name'],
      speciesId: d['speciesId'] ?? 1,
      birthDate: DateTime.parse(d['birthDate']),
      roomId: d['roomId'] as int?,
      ringNumber: d['ringNumber'] as String?,
      gender: d['gender'] as String? ?? '未知',
      uuid: serverUuid,
    );
  }

  Future<void> _applyWeight(Map<String, dynamic> d) async {
    final birdUuid = d['birdUuid'] as String?;
    int? birdId;
    if (birdUuid != null) {
      birdId = (await _db.getBirdByUuid(birdUuid))?.id;
    }
    birdId ??= d['birdId'] as int?;
    if (birdId == null) return;
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
    onWeightChanged?.call();
  }

  Future<void> _applyWeightDelete(Map<String, dynamic> d, String? entityUuid) async {
    if (entityUuid == null) return;
    await _db.removeWeightByUuid(entityUuid);
    onWeightChanged?.call();
  }

  Future<void> _applyWeightEdit(Map<String, dynamic> d, String? entityUuid) async {
    if (entityUuid == null) return;
    final local = await _db.getWeightByUuid(entityUuid);
    if (local == null) return;
    await _db.updateWeight(local.id,
      weightG: d['weightG'] != null ? (d['weightG'] as num).toDouble() : null,
      isFasting: d['isFasting'] as bool?,
      recordedAt: d['recordedAt'] != null ? DateTime.parse(d['recordedAt']) : null,
    );
    onWeightChanged?.call();
  }

  Future<void> _applyTask(Map<String, dynamic> d) async {
    final birdId = d['birdId'] as int;
    await _db.publishTasksForBirds([birdId]);
  }

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  String? get _baseUrl =>
      _serverHost != null ? 'http://$_serverHost:$_serverPort' : null;
}
