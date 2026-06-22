import 'package:flutter/foundation.dart' show debugPrint;
import 'app_clock.dart';

/// debugPrint 拦截器 —— 捕获所有日志到环形缓冲区，供调试面板查看。
///
/// 在 [install] 中保存原始 debugPrint 引用，然后替换为包装函数：
/// 先写入环形缓冲区（容量 1000，FIFO），再调用原始函数保证正常日志输出。
///
/// install() 幂等 —— 重复调用不产生额外包装。
class DebugLogSink {
  DebugLogSink._();

  static const int _maxEntries = 1000;
  static final List<LogEntry> _buffer = [];
  static dynamic _original;

  static void _intercept(String? message, {int? wrapWidth}) {
    _buffer.add(LogEntry(
      timestamp: AppClock.now,
      message: message ?? '',
    ));
    if (_buffer.length > _maxEntries) {
      _buffer.removeAt(0);
    }
    if (_original is Function) {
      (_original as Function)(message, wrapWidth: wrapWidth);
    }
  }

  /// 安装拦截器 —— 必须在 WidgetsFlutterBinding 之前调用以捕获启动期日志。
  static void install() {
    if (_original != null) return; // 幂等
    _original = debugPrint;
    debugPrint = _intercept;
  }

  /// 所有日志条目（倒序 —— 最新的在前）。
  static List<LogEntry> get entries => _buffer.reversed.toList();

  /// 清空缓冲区。
  static void clear() => _buffer.clear();

  /// 按标签 & 关键字过滤（倒序返回）。
  static List<LogEntry> filter({String? tag, String? query}) {
    Iterable<LogEntry> result = _buffer;
    if (tag != null && tag.isNotEmpty) {
      result = result.where((e) => e.message.contains(tag));
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((e) => e.message.toLowerCase().contains(q));
    }
    return result.toList().reversed.toList();
  }
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  const LogEntry({required this.timestamp, required this.message});
}
