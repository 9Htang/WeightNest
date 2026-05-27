import 'package:shared_preferences/shared_preferences.dart';
import 'uuid.dart';

/// 设备唯一标识管理
class DeviceId {
  static String? _cached;

  /// 获取设备 ID（首次启动生成，持久化）
  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = 'dev-${genShortId()}';
      await prefs.setString('device_id', id);
    }
    _cached = id;
    return id;
  }
}
