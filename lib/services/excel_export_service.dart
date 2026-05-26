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

  /// 按月导出体重宽表（纵轴：日期，横轴：鹦鹉 → 手机友好）
  Future<File?> exportMonthly(int year, int month) async {
    final excel = Excel.createExcel();
    // excel 4.0.6 的 delete() 在只剩 1 个 sheet 时无效
    // 改用 rename 将默认 Sheet1 改名为「体重记录」
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, '体重记录');
    final sheet = excel['体重记录'];

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = (year == now.year && month == now.month);

    // 获取所有鹦鹉
    final birds = await _db.getAllWithDetails();

    // 先收集所有数据：birdIndex → day → value
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    final data = <int, Map<int, String>>{}; // birdIndex → day → value
    for (int i = 0; i < birds.length; i++) {
      data[i] = {};
      final weights = await _db.getByBirdInRange(birds[i].bird.id, from: monthStart, to: monthEnd);
      for (final w in weights) {
        final timeStr = '${w.recordedAt.hour.toString().padLeft(2, '0')}:${w.recordedAt.minute.toString().padLeft(2, '0')}\n${w.weightG.toStringAsFixed(1)}';
        final existing = data[i]![w.recordedAt.day];
        data[i]![w.recordedAt.day] = existing != null ? '$existing\n\n$timeStr' : timeStr;
      }
    }

    // ── 表头三行：第1行脚环号 | 第2行品种 | 第3行日期 ──
    final ringRow = <String>['脚环号'];
    final speciesRow = <String>['品种'];
    for (final b in birds) {
      ringRow.add((b.bird.ringNumber?.isNotEmpty == true ? b.bird.ringNumber : b.bird.name) ?? b.bird.name);
      speciesRow.add(b.species.name);
    }
    final dateHeaderRow = <String>['日期'];
    for (final b in birds) {
      dateHeaderRow.add(''); // 日期行对应鸟列留空，日期在第一列
    }
    _writeRow(sheet, 0, ringRow, bold: true);
    _writeRow(sheet, 1, speciesRow, bold: true);

    // ── 每天一行：日期 | 鸟1数据 | 鸟2数据 | ... ──
    for (int d = 1; d <= daysInMonth; d++) {
      final row = <dynamic>['$d日'];
      for (int i = 0; i < birds.length; i++) {
        if (isCurrentMonth && d > now.day) {
          row.add('\\');
        } else {
          row.add(data[i]?[d] ?? '');
        }
      }
      _writeRow(sheet, d + 1, row);
    }

    // 设置列宽自适应：日期列 + 每只鸟一列
    for (int c = 0; c <= birds.length; c++) {
      sheet.setColumnAutoFit(c);
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
      cell.cellStyle = CellStyle(
        bold: bold,
        textWrapping: TextWrapping.WrapText,
      );
    }
  }
}
