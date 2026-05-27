import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../utils/uuid.dart';
import '../utils/device_id.dart';

/// 同步队列服务：所有写操作入队
class SyncQueueService {
  final AppDatabase _db;

  SyncQueueService(this._db);

  /// 入队一个操作
  Future<void> enqueue({
    required int userId,
    required String action,
    required String entityType,
    required String entityUuid,
    required Map<String, dynamic> payload,
  }) async {
    final deviceId = await DeviceId.get();
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      opId: genUuid(),
      deviceId: deviceId,
      userId: userId,
      action: action,
      entityType: entityType,
      entityUuid: entityUuid,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    ));
  }

  /// 获取所有未同步操作（按时间升序，上限 batchSize）
  Future<List<SyncQueueData>> getUnsynced({int batchSize = 50}) async {
    final q = _db.select(_db.syncQueue)
      ..where((t) => t.synced.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(batchSize);
    return q.get();
  }

  /// 标记操作已同步
  Future<void> markSynced(List<String> opIds) async {
    if (opIds.isEmpty) return;
    for (final opId in opIds) {
      await (_db.update(_db.syncQueue)
            ..where((t) => t.opId.equals(opId)))
          .write(SyncQueueCompanion(synced: const Value(true)));
    }
  }

  /// 待同步数量
  Future<int> pendingCount() async {
    final q = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.id.count()])
      ..where(_db.syncQueue.synced.equals(false));
    final row = await q.getSingle();
    return row.read(_db.syncQueue.id.count()) ?? 0;
  }
}
