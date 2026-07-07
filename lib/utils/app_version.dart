import 'package:flutter/services.dart' show rootBundle;

String? _cached;

/// 运行时自动读取 pubspec.yaml 中的版本号
Future<String> getAppVersion() async {
  if (_cached != null) return _cached!;
  try {
    final yaml = await rootBundle.loadString('pubspec.yaml');
    final match =
        RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(yaml);
    // 取 "X.Y.Z+N" 中的 "X.Y.Z"
    _cached = match?.group(1)?.split('+').first ?? '0.0.0';
  } catch (_) {
    _cached = '0.0.0';
  }
  return _cached!;
}
