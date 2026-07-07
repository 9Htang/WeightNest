import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/app_clock.dart';
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
    final now = AppClock.now;
    final isCurrentMonth = (year == now.year && month == now.month);

    // 获取所有鹦鹉，按房间→容器分组排序
    final birds = await _db.getAllWithDetails();
    birds.sort((a, b) {
      final ra = a.room?.name ?? '', rb = b.room?.name ?? '';
      if (ra != rb) {
        if (ra.isEmpty) return 1;
        if (rb.isEmpty) return -1;
        return ra.compareTo(rb);
      }
      final ea = a.enclosure?.name ?? '', eb = b.enclosure?.name ?? '';
      if (ea.isEmpty) return 1;
      if (eb.isEmpty) return -1;
      return ea.compareTo(eb);
    });

    // 先收集所有数据：birdIndex → day → value
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    final data = <int, Map<int, String>>{}; // birdIndex → day → value
    for (int i = 0; i < birds.length; i++) {
      data[i] = {};
      final weights = await _db.getByBirdInRange(birds[i].bird.id,
          from: monthStart, to: monthEnd);
      for (final w in weights) {
        // 体重数据格式：时间\n体重[+是否空腹]
        final fasting = w.isFasting ? '' : '*';
        final timeStr =
            '${w.recordedAt.hour.toString().padLeft(2, '0')}:${w.recordedAt.minute.toString().padLeft(2, '0')}\n${w.weightG.toStringAsFixed(1)}$fasting';
        final existing = data[i]![w.recordedAt.day];
        data[i]![w.recordedAt.day] =
            existing != null ? '$existing\n$timeStr' : timeStr;
      }
    }

    // ── 表头：脚环号 | 品种 | 房间 | 容器 ──
    final ringRow = <String>['脚环号'];
    final speciesRow = <String>['品种'];
    final roomRow = <String>['房间'];
    final enclosureRow = <String>['容器'];
    for (final b in birds) {
      ringRow.add((b.bird.ringNumber?.isNotEmpty == true
              ? b.bird.ringNumber
              : b.bird.name) ??
          b.bird.name);
      speciesRow.add(b.species.name);
      roomRow.add(b.room?.name ?? '');
      enclosureRow.add(b.enclosure?.name ?? '');
    }

    _writeRow(sheet, 0, ringRow, bold: true);
    _writeRow(sheet, 1, speciesRow, bold: true);
    _writeRow(sheet, 2, roomRow, bold: true);
    _writeRow(sheet, 3, enclosureRow, bold: true);

    // 合并房间行和容器行的相邻相同单元格
    _mergeRow(sheet, 2, roomRow);
    _mergeRow(sheet, 3, enclosureRow);

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
      _writeRow(sheet, d + 3, row);
    }

    // 设置列宽自适应：日期列 + 每只鸟一列
    sheet.setColumnWidth(0, 10); // 日期列

    for (int c = 1; c <= birds.length; c++) {
      sheet.setColumnWidth(c, 8);
    }

    // 保存文件
    final dir = await _getExportDir();
    final file = File('${dir.path}/$year年$month月体重记录.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('编码失败');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 合并同一行中相邻相同内容的单元格（跳过第一列标签列）
  void _mergeRow(Sheet sheet, int row, List<String> values) {
    int start = 1;
    for (int i = 2; i <= values.length; i++) {
      if (i < values.length && values[i] == values[i - 1]) continue;
      final end = i - 1;
      if (end > start) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: start, rowIndex: row),
          CellIndex.indexByColumnRow(columnIndex: end, rowIndex: row),
        );
      }
      start = i;
    }
  }

  /// 获取导出目录（Android 10+ scoped storage 不允直接写 Download，改用内部存储 + 分享）
  Future<Directory> _getExportDir() async {
    if (Platform.isAndroid) return getTemporaryDirectory();
    return getApplicationDocumentsDirectory();
  }

  void _writeRow(Sheet sheet, int row, List<dynamic> values,
      {bool bold = false}) {
    for (int col = 0; col < values.length; col++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
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

  // ── 药品库与剂量规则导出 ──

  /// Export drug library + dose rules to Excel.
  Future<File?> exportDrugLibrary({
    required List<dynamic> drugs,
    required List<dynamic> allFormulations,
    required List<dynamic> allDoseRules,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, '药品库');

    // Sheet 1: Drug Library
    final drugSheet = excel['药品库'];
    _writeRow(
        drugSheet,
        0,
        [
          '药品名称',
          '商品名',
          '有效成分',
          '药物类别',
          '剂型',
          '保存方式',
          '开封有效期(天)',
          '浓度/规格',
          '备注'
        ],
        bold: true);

    int row = 1;
    for (final drug in drugs) {
      final drugId = (drug as dynamic).id as int;
      final drugName = (drug).drugName as String;
      final brandName = (drug).brandName as String?;
      final activeIngredient = (drug).activeIngredient as String?;
      final drugCategory = (drug).drugCategory as String;
      final formulationType = (drug).formulationType as String;
      final storageInstructions = (drug).storageInstructions as String?;
      final openedExpiryDays = (drug).openedExpiryDays as int?;
      final notes = (drug).notes as String?;

      final forms = (allFormulations as List)
          .where((f) => (f as dynamic).drugId == drugId)
          .map((f) {
        final form = f as dynamic;
        final def = form.isDefault == true ? ' (默认)' : '';
        return '${form.concentration}${form.unit}$def';
      }).join(', ');

      _writeRow(drugSheet, row++, [
        drugName,
        brandName ?? '',
        activeIngredient ?? '',
        drugCategory,
        formulationType,
        storageInstructions ?? '',
        openedExpiryDays?.toString() ?? '',
        forms,
        notes ?? '',
      ]);
    }

    drugSheet.setColumnWidth(0, 20);
    drugSheet.setColumnWidth(1, 15);
    drugSheet.setColumnWidth(2, 20);
    drugSheet.setColumnWidth(3, 12);
    drugSheet.setColumnWidth(4, 10);
    drugSheet.setColumnWidth(5, 12);
    drugSheet.setColumnWidth(6, 14);
    drugSheet.setColumnWidth(7, 30);
    drugSheet.setColumnWidth(8, 20);

    // Sheet 2: Dose Rules
    final ruleSheet = excel['剂量规则'];
    _writeRow(ruleSheet, 0,
        ['药品', '疾病', '品种', '剂量(mg/kg)', '每天次数', '疗程(天)', '给药途径', '备注'],
        bold: true);

    row = 1;
    for (final r in allDoseRules) {
      final rule = r as dynamic;
      _writeRow(ruleSheet, row++, [
        rule.drugName ?? '',
        rule.diseaseName,
        rule.speciesName ?? '通用',
        rule.rule.mgKgDose.toString(),
        rule.rule.timesPerDay.toString(),
        rule.rule.durationDays.toString(),
        rule.rule.administrationRoute,
        rule.rule.notes ?? '',
      ]);
    }

    ruleSheet.setColumnWidth(0, 20);
    ruleSheet.setColumnWidth(1, 15);
    ruleSheet.setColumnWidth(2, 12);
    ruleSheet.setColumnWidth(3, 14);
    ruleSheet.setColumnWidth(4, 10);
    ruleSheet.setColumnWidth(5, 10);
    ruleSheet.setColumnWidth(6, 12);
    ruleSheet.setColumnWidth(7, 20);

    final dir = await _getExportDir();
    final file = File('${dir.path}/药品库与剂量规则.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('编码失败');
    await file.writeAsBytes(bytes);
    return file;
  }
}

/// 格式化体重单元格：非空腹 → "HH:mm\n{weight}*"，空腹 → "HH:mm\n{weight}"。
///
/// 与 [ExcelExportService.exportMonthly] 内联格式化逻辑严格一致；
/// 抽取为顶层纯函数以便单元测试验证格式规则。
@visibleForTesting
String formatWeightCell(double weightG, DateTime recordedAt,
    {bool isFasting = false}) {
  final fasting = isFasting ? '' : '*';
  final timeStr =
      '${recordedAt.hour.toString().padLeft(2, '0')}:${recordedAt.minute.toString().padLeft(2, '0')}';
  return '$timeStr\n${weightG.toStringAsFixed(1)}$fasting';
}
