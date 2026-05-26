import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/species_repository.dart';
import '../repositories/user_repository.dart';

/// 同步结果
class SyncResult {
  final bool success;
  final int birdsSynced;
  final int weightsSynced;
  final int roomsSynced;
  final int speciesSynced;
  final int usersSynced;
  final String? error;

  SyncResult({
    required this.success,
    this.birdsSynced = 0,
    this.weightsSynced = 0,
    this.roomsSynced = 0,
    this.speciesSynced = 0,
    this.usersSynced = 0,
    this.error,
  });
}

/// 局域网数据同步服务
class SyncService {
  final AppDatabase _db;
  final String _baseUrl;

  SyncService(this._db, String serverIp, {int port = 8080})
      : _baseUrl = 'http://$serverIp:$port/api';

  /// 从服务端同步所有数据
  Future<SyncResult> syncAll() async {
    int birds = 0, weights = 0, rooms = 0, species = 0, users = 0;
    final errors = <String>[];

    // 单表失败不中断全程
    try { species = await _syncSpecies(); } catch (e) { errors.add('物种: $e'); }
    try { rooms = await _syncRooms(); } catch (e) { errors.add('房间: $e'); }
    try { users = await _syncUsers(); } catch (e) { errors.add('用户: $e'); }
    try { birds = await _syncBirds(); } catch (e) { errors.add('鹦鹉: $e'); }
    try { weights = await _syncWeights(); } catch (e) { errors.add('体重: $e'); }

    final total = birds + weights + rooms + species + users;
    if (errors.isNotEmpty && total == 0) {
      return SyncResult(success: false, error: errors.join('; '));
    }

    return SyncResult(
      success: true,
      birdsSynced: birds,
      weightsSynced: weights,
      roomsSynced: rooms,
      speciesSynced: species,
      usersSynced: users,
      error: errors.isNotEmpty ? errors.join('; ') : null,
    );
  }

  Future<int> _syncSpecies() async {
    final res = await http.get(Uri.parse('$_baseUrl/species'));
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    final list = body['data'] as List;
    int count = 0;
    for (final item in list) {
      final existing = await _db.getSpeciesByName(item['name']);
      if (existing == null) {
        await _db.createSpecies(
          item['name'],
          nestlingEndDays: item['nestlingEndDays'] ?? 45,
          juvenileEndDays: item['juvenileEndDays'] ?? 120,
          adultWeighIntervalDays: item['adultWeighIntervalDays'] ?? 7,
        );
        count++;
      }
    }
    return count;
  }

  Future<int> _syncRooms() async {
    final res = await http.get(Uri.parse('$_baseUrl/rooms'));
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    final list = body['data'] as List;
    int count = 0;
    for (final item in list) {
      final existing = await _db.getRoomByName(item['name']);
      if (existing == null) {
        await _db.createRoom(item['name'],
            assignedUserId: item['assignedUserId']);
        count++;
      }
    }
    return count;
  }

  Future<int> _syncUsers() async {
    final res = await http.get(Uri.parse('$_baseUrl/users'));
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    final list = body['data'] as List;
    int count = 0;
    for (final item in list) {
      final existing = await _db.getByUsername(item['username']);
      if (existing == null) {
        await _db.createUser(
          item['username'],
          item['displayName'],
          item['passwordHash'] ?? '',
          role: item['role'] ?? 'keeper',
        );
        count++;
      }
    }
    return count;
  }

  Future<int> _syncBirds() async {
    final res = await http.get(Uri.parse('$_baseUrl/birds'));
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    final list = body['data'] as List;
    int count = 0;
    for (final item in list) {
      // 去重：按名字 + 出生日期判断是否已存在
      final existing = await _db.getBirdByNameAndBirth(
        item['name'],
        DateTime.parse(item['birthDate']),
      );
      if (existing != null) continue;
      await _db.createBird(
        name: item['name'],
        speciesId: item['speciesId'] ?? 1,
        birthDate: DateTime.parse(item['birthDate']),
        roomId: item['roomId'] as int?,
        ringNumber: item['ringNumber'] as String?,
        gender: item['gender'] as String? ?? '未知',
        notes: item['notes'] as String?,
      );
      count++;
    }
    return count;
  }

  Future<int> _syncWeights() async {
    // Sync weights for each bird
    final birds = await _db.getAllWithDetails();
    int count = 0;
    for (final b in birds) {
      try {
        final res = await http.get(
            Uri.parse('$_baseUrl/weights/${b.bird.id}'));
        if (res.statusCode != 200) continue;
        final body = jsonDecode(res.body);
        final list = body['data'] as List;
        for (final item in list) {
          final recordedAt = DateTime.parse(item['recordedAt']);
          final exists = await _checkWeightExists(b.bird.id, recordedAt);
          if (!exists) {
            await _db.addWeight(
              birdId: b.bird.id,
              weightG: (item['weightG'] as num).toDouble(),
              recordedAt: recordedAt,
              recordedBy: item['recordedBy'],
              isFasting: item['isFasting'] ?? false,
              notes: item['notes'],
            );
            count++;
          }
        }
      } catch (_) {}
    }
    return count;
  }

  Future<bool> _checkWeightExists(int birdId, DateTime recordedAt) async {
    final minuteStart = DateTime(
        recordedAt.year, recordedAt.month, recordedAt.day,
        recordedAt.hour, recordedAt.minute);
    final weights = await _db.getByBird(birdId);
    return weights.any((w) {
      final wm = DateTime(w.recordedAt.year, w.recordedAt.month,
          w.recordedAt.day, w.recordedAt.hour, w.recordedAt.minute);
      return wm == minuteStart;
    });
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
