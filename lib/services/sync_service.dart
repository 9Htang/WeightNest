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
    try {
      int birds = 0, weights = 0, rooms = 0, species = 0, users = 0;

      final spResult = await _syncSpecies();
      species = spResult;

      final roomResult = await _syncRooms();
      rooms = roomResult;

      final userResult = await _syncUsers();
      users = userResult;

      final birdResult = await _syncBirds();
      birds = birdResult;

      final weightResult = await _syncWeights();
      weights = weightResult;

      return SyncResult(
        success: true,
        birdsSynced: birds,
        weightsSynced: weights,
        roomsSynced: rooms,
        speciesSynced: species,
        usersSynced: users,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
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
      await _db.createBird(
        name: item['name'],
        speciesId: item['speciesId'],
        birthDate: DateTime.parse(item['birthDate']),
        roomId: item['roomId'],
        ringNumber: item['ringNumber'],
        gender: item['gender'] ?? '未知',
        notes: item['notes'],
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
    final hourStart = DateTime(
        recordedAt.year, recordedAt.month, recordedAt.day, recordedAt.hour);
    final weights = await _db.getByBird(birdId);
    return weights.any((w) {
      final wh = DateTime(w.recordedAt.year, w.recordedAt.month,
          w.recordedAt.day, w.recordedAt.hour);
      return wh == hourStart;
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
