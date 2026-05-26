import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';

/// Excel 导出服务
class ExcelExportService {
  final AppDatabase _db;
  ExcelExportService(this._db);

  /// 按月导出体重宽表
  Future<File?> exportMonthly(int year, int month) async {
    final excel = Excel.createExcel();
    // 删除默认的 Sheet1，只保留体重记录表
    excel.delete('Sheet1');
    final sheet = excel['体重记录'];

    // 计算当月天数
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // 表头：脚环号 | 品种 | 1 | 2 | ... | 28/29/30/31
    final headers = <String>['脚环号', '品种'];
    for (int d = 1; d <= daysInMonth; d++) headers.add('$d日');
    _writeRow(sheet, 0, headers, bold: true);

    // 获取所有鹦鹉
    final birds = await _db.getAllWithDetails();
    final now = DateTime.now();
    final isCurrentMonth = (year == now.year && month == now.month);

    for (int i = 0; i < birds.length; i++) {
      final b = birds[i];
      final row = <dynamic>[b.bird.ringNumber ?? '', b.species.name];

      // 获取该鸟当月的所有体重记录（时间升序）
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
      final allWeights = await _db.getByBirdInRange(
        b.bird.id,
        from: monthStart,
        to: monthEnd,
      );

      // 按天分组（记录已按时间升序排列）
      final dayMap = <int, List<String>>{};
      for (final w in allWeights) {
        final day = w.recordedAt.day;
        final timeStr = '${w.recordedAt.hour.toString().padLeft(2, '0')}:${w.recordedAt.minute.toString().padLeft(2, '0')} ${w.weightG.toStringAsFixed(1)}g';
        dayMap.putIfAbsent(day, () => []).add(timeStr);
      }

      // 填每天的数据（按时间升序）
      for (int d = 1; d <= daysInMonth; d++) {
        if (isCurrentMonth && d > now.day) {
          row.add('\\');
        } else {
          final records = dayMap[d] ?? [];
          if (records.isEmpty) {
            row.add('');
          } else {
            // 按时间排序已在数据库查询中完成
            row.add(records.join('\n'));
          }
        }
      }
      _writeRow(sheet, i + 1, row);
    }

    // 保存文件
    final dir = await _getExportDir();
    final file = File('${dir.path}/${year}年${month}月体重记录.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('编码失败');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 获取导出目录
  Future<Directory> _getExportDir() async {
    if (Platform.isAndroid) return Directory('/storage/emulated/0/Download');
    return getApplicationDocumentsDirectory();
  }

  void _writeRow(Sheet sheet, int row, List<dynamic> values, {bool bold = false}) {
    for (int col = 0; col < values.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      final v = values[col];
      if (v is int) {
        cell.value = IntCellValue(v);
      } else if (v is double) {
        cell.value = DoubleCellValue(v);
      } else if (v is bool) {
        cell.value = BoolCellValue(v);
      } else {
        cell.value = TextCellValue(v?.toString() ?? '');
      }
      if (bold) cell.cellStyle = CellStyle(bold: true);
    }
  }
}
