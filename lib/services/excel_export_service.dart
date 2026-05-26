import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/species_repository.dart';
import '../repositories/task_repository.dart';

/// Excel 导出服务
class ExcelExportService {
  final AppDatabase _db;

  ExcelExportService(this._db);

  /// 导出所有数据到 Excel 文件
  Future<File?> exportAll() async {
    try {
      final excel = Excel.createExcel();
      // 重命名默认 sheet 为鹦鹉信息，避免删除后 encode 失败
      final defaultSheet = excel.sheets['Sheet1'];
      if (defaultSheet != null) {
        excel.rename('Sheet1', '鹦鹉信息');
      }

      await _exportBirds(excel);
      await _exportWeights(excel);
      await _exportRooms(excel);
      await _exportSpecies(excel);
      await _exportTasks(excel);

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${dir.path}/WeightNest_$timestamp.xlsx');
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('编码失败：数据为空');
      }
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _exportBirds(Excel excel) async {
    final sheet = excel['鹦鹉信息'];
    final birds = await _db.getAllWithDetails();

    // 表头
    _writeRow(sheet, 0, [
      'ID', '名称', '脚环号', '品种', '性别', '出生日期',
      '出生天数', '成长阶段', '所在房间', '状态', '备注'
    ], bold: true);

    for (int i = 0; i < birds.length; i++) {
      final b = birds[i];
      _writeRow(sheet, i + 1, [
        b.bird.id, b.bird.name,
        b.bird.ringNumber ?? '', b.species.name,
        b.bird.gender,
        '${b.bird.birthDate.year}-${b.bird.birthDate.month.toString().padLeft(2, '0')}-${b.bird.birthDate.day.toString().padLeft(2, '0')}',
        b.ageDays, b.growthStage,
        b.room?.name ?? '',
        b.bird.status,
        b.bird.notes ?? '',
      ]);
    }
  }

  Future<void> _exportWeights(Excel excel) async {
    final sheet = excel['体重记录'];
    final birds = await _db.getAllWithDetails();

    _writeRow(sheet, 0, [
      'ID', '鹦鹉ID', '鹦鹉名称', '体重(g)', '记录时间',
      '是否空腹', '备注'
    ], bold: true);

    int row = 1;
    for (final bird in birds) {
      final weights = await _db.getByBird(bird.bird.id);
      for (final w in weights) {
        _writeRow(sheet, row++, [
          w.id, w.birdId, bird.bird.name,
          w.weightG,
          '${w.recordedAt.year}-${w.recordedAt.month.toString().padLeft(2, '0')}-${w.recordedAt.day.toString().padLeft(2, '0')} '
              '${w.recordedAt.hour.toString().padLeft(2, '0')}:${w.recordedAt.minute.toString().padLeft(2, '0')}',
          w.isFasting ? '是' : '否',
          w.notes ?? '',
        ]);
      }
    }
  }

  Future<void> _exportRooms(Excel excel) async {
    final sheet = excel['房间'];
    final rooms = await _db.getAllRooms();

    _writeRow(sheet, 0, ['ID', '名称', '排序', '负责人ID'], bold: true);
    for (int i = 0; i < rooms.length; i++) {
      final r = rooms[i];
      _writeRow(sheet, i + 1, [r.id, r.name, r.sortOrder, r.assignedUserId ?? '']);
    }
  }

  Future<void> _exportSpecies(Excel excel) async {
    final sheet = excel['品种配置'];
    final spList = await _db.getAllSpecies();

    _writeRow(sheet, 0, [
      'ID', '名称', '雏鸟结束(天)', '幼鸟结束(天)', '成鸟称重周期(天)'
    ], bold: true);

    for (int i = 0; i < spList.length; i++) {
      final s = spList[i];
      _writeRow(sheet, i + 1, [
        s.id, s.name,
        s.nestlingEndDays, s.juvenileEndDays, s.adultWeighIntervalDays
      ]);
    }
  }

  Future<void> _exportTasks(Excel excel) async {
    final sheet = excel['任务记录'];
    final tasks = await _db.getTodayTasks(null);

    _writeRow(sheet, 0, [
      'ID', '鹦鹉ID', '鹦鹉名称', '任务日期', '状态', '完成时间'
    ], bold: true);

    for (int i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      _writeRow(sheet, i + 1, [
        t.task.id, t.bird.id, t.bird.name,
        '${t.task.dueDate.month}/${t.task.dueDate.day}',
        t.task.status,
        t.task.completedAt?.toString() ?? '',
      ]);
    }
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
      if (bold) {
        cell.cellStyle = CellStyle(bold: true);
      }
    }
  }
}
