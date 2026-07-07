import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/excel_export_service.dart';

/// ── formatWeightCell 单元测试 ────────────────────────────────────────────
///
/// 验证体重单元格格式化规则，与 ExcelExportService.exportMonthly 内联逻辑
/// 严格一致。

void main() {
  group('formatWeightCell 基本格式', () {
    test('非空腹 → "HH:mm\n{weight}*"', () {
      final result = formatWeightCell(
        50.0,
        DateTime(2025, 6, 15, 9, 30),
      );
      expect(result, '09:30\n50.0*');
    });

    test('空腹 → "HH:mm\n{weight}"（无星号）', () {
      final result = formatWeightCell(
        50.0,
        DateTime(2025, 6, 15, 9, 30),
        isFasting: true,
      );
      expect(result, '09:30\n50.0');
    });
  });

  group('时间格式', () {
    test('9:05 → "09:05"（补零）', () {
      final result = formatWeightCell(
        10.0,
        DateTime(2025, 6, 15, 9, 5),
      );
      expect(result.startsWith('09:05'), isTrue);
    });

    test('0:00 → "00:00"（午夜补零）', () {
      final result = formatWeightCell(
        10.0,
        DateTime(2025, 6, 15, 0, 0),
      );
      expect(result.startsWith('00:00'), isTrue);
    });

    test('23:59 → "23:59"', () {
      final result = formatWeightCell(
        10.0,
        DateTime(2025, 6, 15, 23, 59),
      );
      expect(result.startsWith('23:59'), isTrue);
    });
  });

  group('体重格式', () {
    test('整数体重 → 一位小数（toStringAsFixed(1)）', () {
      final result = formatWeightCell(50, DateTime(2025, 1, 1, 12, 0));
      expect(result, contains('50.0'));
    });

    test('多位小数 → 截断到一位', () {
      final result = formatWeightCell(50.25, DateTime(2025, 1, 1, 12, 0));
      // toStringAsFixed(1) 四舍五入：50.25 → "50.3"（IEEE 浮点表示略大于 0.25）
      expect(result, contains('50.3'));
    });

    test('0g 边界', () {
      final result = formatWeightCell(0, DateTime(2025, 1, 1, 12, 0));
      expect(result, contains('0.0'));
    });

    test('大体重 9999.9g', () {
      final result = formatWeightCell(9999.9, DateTime(2025, 1, 1, 12, 0));
      expect(result, contains('9999.9'));
    });
  });

  group('空腹标记', () {
    test('默认 isFasting=false（非空腹）→ 带星号', () {
      final result = formatWeightCell(10.0, DateTime(2025, 1, 1, 12, 0));
      expect(result.endsWith('*'), isTrue);
    });

    test('isFasting=true → 不带星号', () {
      final result = formatWeightCell(
        10.0,
        DateTime(2025, 1, 1, 12, 0),
        isFasting: true,
      );
      expect(result.endsWith('*'), isFalse);
    });
  });
}
