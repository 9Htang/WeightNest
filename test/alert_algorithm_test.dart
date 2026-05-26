import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// ============================================
/// 时间标准化 + Log增长率 + EMA + StdDev 工具函数
/// ============================================

/// 标准化为 24 小时增长率
/// 例：12h内从10g到12g → 实际增长20%，但标准化后=40%
double normalizeTo24h(double rate, double hourDiff) {
  if (hourDiff <= 0) return rate;
  return rate * (24 / hourDiff);
}

/// Log 增长率（适配指数成长）
/// ln(current / previous)
double logGrowthRate(double previous, double current) {
  if (previous <= 0 || current <= 0) return 0;
  return log(current / previous);
}

/// 指数移动平均
/// α = 0.3
List<double> calcEMA(List<double> values, {double alpha = 0.3}) {
  if (values.isEmpty) return [];
  final result = <double>[values.first];
  for (int i = 1; i < values.length; i++) {
    result.add(values[i] * alpha + result.last * (1 - alpha));
  }
  return result;
}

/// 标准差
double calcStdDev(List<double> values) {
  if (values.length < 2) return 0;
  final avg = values.reduce((a, b) => a + b) / values.length;
  final squaredDiffs = values.map((v) => pow(v - avg, 2)).toList();
  return sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
}

/// ============================================
/// 单元测试
/// ============================================

void main() {
  group('logGrowthRate', () {
    test('10→12 = ln(1.2) ≈ 0.182', () {
      final rate = logGrowthRate(10, 12);
      expect(rate.toStringAsFixed(3), '0.182');
    });

    test('3→4 = ln(1.333) ≈ 0.288', () {
      final rate = logGrowthRate(3, 4);
      expect(rate.toStringAsFixed(3), '0.288');
    });

    test('30→31 = ln(1.033) ≈ 0.033', () {
      final rate = logGrowthRate(30, 31);
      expect(rate.toStringAsFixed(3), '0.033');
    });
  });

  group('normalizeTo24h', () {
    test('20% over 24h → 20%', () {
      expect(normalizeTo24h(0.20, 24).toStringAsFixed(3), '0.200');
    });

    test('20% over 12h → 40% (normalized)', () {
      expect(normalizeTo24h(0.20, 12).toStringAsFixed(3), '0.400');
    });

    test('20% over 33h → 14.5% (normalized)', () {
      final v = normalizeTo24h(0.20, 33);
      expect(v.toStringAsFixed(3), '0.145');
    });

    test('20% over 48h → 10% (normalized)', () {
      final v = normalizeTo24h(0.20, 48);
      expect(v.toStringAsFixed(3), '0.100');
    });
  });

  group('calcEMA', () {
    test('simple series', () {
      final values = [10.0, 12.0, 11.0, 13.0];
      final ema = calcEMA(values);
      expect(ema.length, 4);
      expect(ema[0], 10.0); // 第一点不计算
      // EMA[1] = 12*0.3 + 10*0.7 = 3.6 + 7 = 10.6
      expect(ema[1].toStringAsFixed(2), '10.60');
      
      // EMA[2] = 11*0.3 + 10.6*0.7 = 3.3 + 7.42 = 10.72
      expect(ema[2].toStringAsFixed(2), '10.72');
    });
  });

  group('calcStdDev', () {
    test('stable', () {
      final std = calcStdDev([10, 10, 10, 10.5, 9.5]);
      expect(std.toStringAsFixed(2), '0.32');  // avg=10, variance=0.1, sqrt=0.316
    });

    test('volatile', () {
      final std = calcStdDev([10, 8, 12, 7, 13]);
      expect(std.toStringAsFixed(1), '2.3');
    });
  });

  group('integration: 雏鸟场景', () {
    test('正常成长不告警 (Log > 0.08)', () {
      // 48h内 3→5g: ln(5/3)=0.511 * (24/48) = 0.255 ✓
      final logR = logGrowthRate(3, 5);
      final norm = normalizeTo24h(logR, 48);
      expect(norm > 0.08, isTrue);
    });

    test('增长停滞告警 (Log < 0.03)', () {
      // 48h内 10→10.3g: ln(10.3/10)=0.030 * (24/48) = 0.015 ✗
      final logR = logGrowthRate(10, 10.3);
      final norm = normalizeTo24h(logR, 48);
      expect(norm < 0.03, isTrue);
    });

    test('体重下降告警 (Log < 0)', () {
      // 24h内 10→9.5g: ln(9.5/10)=-0.051 ✗
      final logR = logGrowthRate(10, 9.5);
      expect(logR < 0, isTrue);
    });
  });

  group('integration: 幼鸟场景', () {
    test('稳定 → 正常', () {
      final weights = [100.0, 101.0, 99.5, 100.5, 101.0, 99.8, 100.2];
      final ema = calcEMA(weights);
      final std = calcStdDev(weights);
      
      // 7日标准差 < 5% of avg
      final stdPct = std / (weights.reduce((a, b) => a + b) / weights.length);
      expect(stdPct < 0.05, isTrue, reason: '波动率应 <5%');

      // EMA 趋势判断：首尾变化 < 5%
      final trendPct = (ema.last - ema.first) / ema.first;
      expect(trendPct.abs() < 0.05, isTrue, reason: '趋势应稳定');
    });

    test('慢性下降 → 告警', () {
      // 7天连续下降，实际7%，EMA平滑后约3.9%
      final weights = [100.0, 99.0, 98.0, 97.0, 96.0, 95.0, 94.0];
      final ema = calcEMA(weights);
      final trendPct = (ema.last - ema.first) / ema.first;
      expect(trendPct < -0.03, isTrue, reason: 'EMA趋势应显示下降');
    });
  });
}
