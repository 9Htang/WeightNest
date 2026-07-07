import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// 全局可覆盖时钟。
///
/// 生产代码通过 [now] 获取"应用时间"，默认等同于 `DateTime.now()`。
/// 调试模式下可通过 [override]/[advance]/[reset] 偏移时间（以真实速率流动）。
/// 偏移量持久化到 SharedPreferences，重启后自动恢复。
///
/// Release 模式下 override/advance/reset/restore 被 Dart assert 树摇移除，零开销。
class AppClock {
  AppClock._();

  static const _kOffsetKey = 'debug_clock_offset_ms';

  static final DateTime Function() _defaultImpl = () => DateTime.now();
  static DateTime Function() _impl = _defaultImpl;

  /// 当前应用时间。
  static DateTime get now => _impl();

  /// 时间是否已被覆盖（仅 debug 模式可能为 true）。
  static bool get isOverridden => !identical(_impl, _defaultImpl);

  /// 将时间偏移到 [dateTime]，之后以真实速率流动（debug 专用）。
  /// 偏移量同步写入 SharedPreferences。
  static Future<void> override(DateTime dateTime) async {
    assert(kDebugMode, 'AppClock.override only available in debug mode');
    final offset = dateTime.difference(DateTime.now());
    _impl = () => DateTime.now().add(offset);
    await _saveOffset(offset);
  }

  /// 在当前偏移点上向前跳跃 [duration]，之后继续流动（debug 专用）。
  /// 偏移量同步写入 SharedPreferences。
  static Future<void> advance(Duration duration) async {
    assert(kDebugMode, 'AppClock.advance only available in debug mode');
    final offset = _impl().add(duration).difference(DateTime.now());
    _impl = () => DateTime.now().add(offset);
    await _saveOffset(offset);
  }

  /// 恢复为真实时间，并清除持久化偏移（debug 专用）。
  static Future<void> reset() async {
    assert(kDebugMode, 'AppClock.reset only available in debug mode');
    _impl = _defaultImpl;
    await _clearOffset();
  }

  /// 启动时调用，从 SharedPreferences 恢复上次的偏移（debug 专用）。
  /// 建议在 main() 的 runApp 之前 await 此方法。
  static Future<void> restore() async {
    assert(kDebugMode, 'AppClock.restore only available in debug mode');
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kOffsetKey);
    if (ms != null) {
      final offset = Duration(milliseconds: ms);
      _impl = () => DateTime.now().add(offset);
    }
  }

  // ── 私有工具 ──────────────────────────────────────

  static Future<void> _saveOffset(Duration offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kOffsetKey, offset.inMilliseconds);
  }

  static Future<void> _clearOffset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOffsetKey);
  }
}
