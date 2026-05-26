import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 离线同步队列
/// 当客户端断网时记录本地操作，恢复连接后自动推送
class OfflineSyncQueue {
  static const _key = 'offline_sync_queue';

  List<Map<String, dynamic>> _queue = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _queue = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_queue));
  }

  Future<void> addSyncItem(String entityType, int entityId, String operation, Map<String, dynamic> data) async {
    _queue.add({
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _save();
  }

  Future<void> addWeightUpdate(int birdId, Map<String, dynamic> data) =>
      addSyncItem('weight', birdId, 'update', data);

  List<Map<String, dynamic>> get pendingItems => List.unmodifiable(_queue);

  bool get hasPending => _queue.isNotEmpty;
  int get pendingCount => _queue.length;

  Future<void> markAllSynced() async {
    _queue.clear();
    await _save();
  }
}
