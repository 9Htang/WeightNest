import 'dart:io';

/// 计算 lcov.info 中 lib/ 的线覆盖率（排除 *.g.dart 和 main.dart）。
/// 用法：dart run tools/compute_coverage.dart coverage/lcov.info
void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final content = File(path).readAsStringSync();

  final blocks = content.split('end_of_record');
  int totalLines = 0;
  int hitLines = 0;
  int fileCount = 0;

  for (final block in blocks) {
    if (!block.contains('SF:')) continue;
    final sfMatch = RegExp(r'SF:(.+)').firstMatch(block);
    if (sfMatch == null) continue;
    final filePath = sfMatch.group(1)!.trim();

    // 只统计 lib/（路径形如 lib\xxx 或 lib/xxx）
    final normalized = filePath.replaceAll('\\', '/');
    if (!normalized.startsWith('lib/')) continue;
    // 排除生成代码和入口
    if (normalized.endsWith('.g.dart')) continue;
    if (normalized == 'lib/main.dart') continue;

    fileCount++;
    for (final daLine in block.split('\n')) {
      final m = RegExp(r'^DA:(\d+),(\d+)').firstMatch(daLine);
      if (m == null) continue;
      final hit = int.parse(m.group(2)!);
      totalLines++;
      if (hit > 0) hitLines++;
    }
  }

  final pct = totalLines > 0 ? (hitLines / totalLines * 100) : 0.0;
  print('统计文件数: $fileCount');
  print('可执行行总数: $totalLines');
  print('已覆盖行数: $hitLines');
  print('lib/ 线覆盖率: ${pct.toStringAsFixed(1)}%');
}
