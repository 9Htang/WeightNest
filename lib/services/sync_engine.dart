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
import 'log/app_logger.dart';

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
    // ① 先推送本地未上传的操作（离线期间产生的数据不能丢）
    await pushOperations();
    // ② 全量拉取基础数据（UUID 锚定）
    await _fullSyncSpecies();
    await _fullSyncRooms();
    await _fullSyncUsers();
    // ③ 全量拉取鹦鹉（名称+日期去重）
    await _fullSyncBirds();
    // ④ 鸟清理后再清理房间（鸟已清除则房间无引用可删）
    await _cleanupRooms();
    // ⑤ 增量拉取其他变更
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
      // 清理本地有而服务端没有的品种（无鹦鹉关联的才删）
      final serverNames = list.map((s) => s['name'] as String).toSet();
      final local = await _db.getAllSpecies();
      for (final sp in local) {
        if (!serverNames.contains(sp.name)) {
          final count = await _db.getBirdCountBySpecies(sp.id);
          if (count == 0) await _db.removeSpecies(sp.id);
        }
      }
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
  }

  Future<void> _fullSyncRooms() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/rooms'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['rooms'] as List;
      final serverNames = <String>{};
      for (final r in list) {
        final name = r['name'] as String;
        serverNames.add(name);
        final assignedId = r['assignedUserId'] as int?;
        final sortOrder = r['sortOrder'] as int?;
        final existing = await _db.getRoomByName(name);
        if (existing != null) {
          await _db.updateRoom(existing.id, name: name, assignedUserId: assignedId, sortOrder: sortOrder);
        } else {
          await _db.createRoom(name, assignedUserId: assignedId);
        }
      }
      // 保存服务端房间名集合，供后续清理用
      _serverRoomNames = serverNames;
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
  }

  Future<void> _cleanupRooms() async {
    if (_serverRoomNames == null) return;
    try {
      final local = await _db.getAllRooms();
      for (final room in local) {
        if (!_serverRoomNames!.contains(room.name)) {
          final count = await _db.getBirdCountByRoom(room.id);
          if (count == 0) await _db.removeRoom(room.id);
        }
      }
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
  }

  Set<String>? _serverRoomNames;

  Future<void> _fullSyncUsers() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['users'] as List;
      final serverUsernames = <String>{};
      for (final u in list) {
        final username = u['username'] as String;
        serverUsernames.add(username);
        final existing = await _db.getByUsername(username);
        if (existing == null) {
          await _db.createUser(username, u['displayName'] as String? ?? username, u['passwordHash'] ?? '',
            role: u['role'] as String? ?? 'keeper');
        } else {
          // 用服务端数据更新本地用户
          await _db.updateUser(existing.id,
            displayName: u['displayName'] as String?,
            role: u['role'] as String?,
            isActive: u['isActive'] as bool?,
          );
        }
      }
      // 禁用在服务端已不存在的本地用户（保留 admin）
      final local = await _db.getAllUsers();
      for (final user in local) {
        if (!serverUsernames.contains(user.username) && user.username != 'admin') {
          await _db.updateUser(user.id, isActive: false);
        }
      }
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
  }

  Future<void> _fullSyncBirds() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/birds'),
        headers: {'X-Token': _token ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body)['birds'] as List;
      final matchedIds = <int>{};
      var ok = true;
      for (final b in list) {
        try {
          final name = b['name'] as String?;
          final birthDateStr = b['birthDate'] as String?;
          if (name == null || birthDateStr == null) continue;
          final birthDate = DateTime.parse(birthDateStr);
          final serverUuid = b['uuid'] as String?;
          if (serverUuid == null) continue;
          final existing = await _db.getBirdByNameAndBirth(name, birthDate);
          final speciesName = b['speciesName'] as String?;

          int? localSpeciesId;
          if (speciesName != null) {
            final sp = await _db.getSpeciesByNameSafe(speciesName);
            if (sp != null) localSpeciesId = sp.id;
          }

          int? localRoomId;
          final roomName = b['roomName'] as String?;
          if (roomName != null) {
            final room = await _db.getRoomByName(roomName);
            if (room != null) localRoomId = room.id;
          }

          if (existing == null) {
            final created = await _db.createBird(
              name: name,
              speciesId: localSpeciesId ?? 1,
              birthDate: birthDate,
              roomId: localRoomId,
              ringNumber: b['ringNumber'] as String?,
              gender: b['gender'] as String? ?? '未知',
              uuid: serverUuid,
            );
            matchedIds.add(created.id);
          } else {
            matchedIds.add(existing.id);
            if (existing.uuid != serverUuid) {
              await _db.updateBirdUuid(existing.id, serverUuid);
            }
            await _db.updateBird(existing.id,
              speciesId: localSpeciesId ?? existing.speciesId,
              roomId: localRoomId,
              ringNumber: b['ringNumber'] as String?,
              gender: b['gender'] as String?,
            );
          }
        } catch (_) {
          ok = false;
        }
      }
      // 仅在全部处理成功时才清理本地孤儿数据
      if (ok) {
        final local = await _db.getAllWithDetails();
        for (final b in local) {
          if (!matchedIds.contains(b.bird.id)) {
            await _db.removeWeightsByBirdId(b.bird.id);
            await _db.removeBird(b.bird.id);
          }
        }
      }
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
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
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
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

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder).timeout(const Duration(seconds: 120))) {
        buffer += chunk;
        // 防止缓冲区无限增长
        if (buffer.length > 65536) buffer = buffer.substring(buffer.length - 32768);
        while (buffer.contains('\n\n')) {
          final idx = buffer.indexOf('\n\n');
          final event = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);

          // 处理多行 SSE 事件（data: 行可有多条）
          String? data;
          for (final line in event.split('\n')) {
            if (line.startsWith('data: ')) {
              data = (data ?? '') + line.substring(6);
            }
          }
          if (data == null) continue; // heartbeat comment, skip
          if (data.contains('"eof"')) return; // 正常的 EOF 信号
          try {
            final change = jsonDecode(data) as Map<String, dynamic>;
            await _applyChanges([change]);
            _lastPull = DateTime.now();
          } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
        }
      }
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _sseReconnectTimer?.cancel();
    _sseReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_token != null) _listenSSE();
    });
  }

  // ─── 上传 ───

  bool _pushing = false;

  Future<void> pushOperations() async {
    if (_pushing) return;
    final ops = await _queue.getUnsynced(batchSize: 50);
    if (ops.isEmpty) return;
    _pushing = true;

    try {
      final payload = <Map<String, dynamic>>[];
      for (final o in ops) {
        try {
          payload.add({
            'opId': o.opId, 'deviceId': o.deviceId, 'userId': o.userId,
            'action': o.action, 'entityType': o.entityType,
            'entityUuid': o.entityUuid,
            'payload': jsonDecode(o.payload),
            'createdAt': o.createdAt.toIso8601String(),
          });
        } catch (e) {
          // 损坏的 payload — 直接标记已同步避免无限重试
          AppLogger.error('SyncEngine', '同步队列损坏 $o.opId', e);
          await _queue.markSynced([o.opId]);
        }
      }
      if (payload.isEmpty) return;

      final token = _token;
      if (token == null) return;
      final res = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: {'Content-Type': 'application/json', 'X-Token': token},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final successOps = List<String>.from(body['successOps'] ?? []);
        await _queue.markSynced(successOps);
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
    } catch (e) {
      AppLogger.error('SyncEngine', '同步推送失败', e);
    } finally {
      _pushing = false;
    }
  }

  /// Auto-complete today's tasks when weight ops are confirmed by server
  Future<void> _autoCompleteTasksForWeights(List<SyncQueueData> ops, List<String> successOpIds) async {

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
      } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
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
    } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
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
      } catch (e) { AppLogger.error('SyncEngine', '同步失败', e); }
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
    // Match by name — link to server UUID and update config values
    final byName = await _db.getSpeciesByNameSafe(name);
    if (byName != null) {
      await _db.updateSpeciesUuid(byName.id, uuid);
      await _db.updateSpecies(byName.id,
        name: name,
        nestlingEndDays: d['nestlingEndDays'] ?? 45,
        juvenileEndDays: d['juvenileEndDays'] ?? 120,
        nestlingWeighIntervalDays: d['nestlingWeighIntervalDays'] ?? 1,
        juvenileWeighIntervalDays: d['juvenileWeighIntervalDays'] ?? 3,
        adultWeighIntervalDays: d['adultWeighIntervalDays'] ?? 7,
      );
      return;
    }
    await _db.createSpecies(name,
      nestlingEndDays: d['nestlingEndDays'] ?? 45,
      juvenileEndDays: d['juvenileEndDays'] ?? 120,
      nestlingWeighIntervalDays: d['nestlingWeighIntervalDays'] ?? 1,
      juvenileWeighIntervalDays: d['juvenileWeighIntervalDays'] ?? 3,
      adultWeighIntervalDays: d['adultWeighIntervalDays'] ?? 7,
      uuid: uuid,
    );
  }

  Future<void> _applyRoom(Map<String, dynamic> d) async {
    final name = d['name'] as String?;
    if (name == null || name.isEmpty) return;
    // 优先按 UUID 匹配（处理改名场景）
    final uuid = d['uuid'] as String?;
    if (uuid != null) {
      final byUuid = await _db.getRoomByUuid(uuid);
      if (byUuid != null) {
        await _db.updateRoom(byUuid.id, name: name,
          assignedUserId: d['assignedUserId'] as int?,
          sortOrder: d['sortOrder'] as int?);
        return;
      }
    }
    final existing = await _db.getRoomByName(name);
    if (existing != null) {
      await _db.updateRoom(existing.id, name: name,
        assignedUserId: d['assignedUserId'] as int?,
        sortOrder: d['sortOrder'] as int?);
      return;
    }
    await _db.createRoom(name, assignedUserId: d['assignedUserId'] as int?);
  }

  Future<void> _applyUser(Map<String, dynamic> d) async {
    final username = d['username'] as String?;
    if (username == null || username.isEmpty) return;
    final existing = await _db.getByUsername(username);
    if (existing != null) {
      await _db.updateUser(existing.id,
        displayName: d['displayName'] as String?,
        role: d['role'] as String?,
        isActive: d['isActive'] as bool?,
      );
      return;
    }
    await _db.createUser(username, d['displayName'] as String? ?? username,
      d['passwordHash'] ?? '', role: d['role'] as String? ?? 'keeper');
  }

  Future<void> _applyBird(Map<String, dynamic> d, String? serverUuid) async {
    final name = d['name'] as String?;
    final birthDateStr = d['birthDate'] as String?;
    if (name == null || birthDateStr == null) return;
    final existing = await _db.getBirdByNameAndBirth(name, DateTime.parse(birthDateStr));
    // 通过品种名/房间名解析本地 ID（不可直接用服务端 ID）
    int? localSpeciesId;
    if (d['speciesName'] != null) {
      localSpeciesId = (await _db.getSpeciesByNameSafe(d['speciesName'] as String))?.id;
    }
    int? localRoomId;
    if (d['roomName'] != null) {
      localRoomId = (await _db.getRoomByName(d['roomName'] as String))?.id;
    }
    if (existing != null) {
      if (serverUuid != null && existing.uuid != serverUuid) {
        await _db.updateBirdUuid(existing.id, serverUuid);
      }
      await _db.updateBird(existing.id,
        speciesId: localSpeciesId ?? existing.speciesId,
        roomId: localRoomId,
        ringNumber: d['ringNumber'] as String?,
        gender: d['gender'] as String?,
        status: d['status'] as String?,
        notes: d['notes'] as String?,
      );
      return;
    }
    await _db.createBird(
      name: name,
      speciesId: localSpeciesId ?? 1,
      birthDate: DateTime.parse(birthDateStr),
      roomId: localRoomId,
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
    if (birdId == null) return; // UUID 解析失败则忽略，不用服务端 ID
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

  final int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  String? get _baseUrl =>
      _serverHost != null ? 'http://$_serverHost:$_serverPort' : null;
}
