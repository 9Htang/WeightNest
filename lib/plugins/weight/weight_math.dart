import 'dart:math';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import 'weight_stage_mapper.dart';

// ==================== 体重告警阈值常量 ====================

const double warningDeviationPct = 10.0;
const double dangerDeviationPct = 15.0;
const double overdueWarningMultiplier = 1.5;
const double overdueDangerMultiplier = 3.0;
const double chronicTrendPct = 7.0;
const double chickGrowthHealthyRate = 0.08;
const double chickGrowthSlowRate = 0.03;
const double weaningWarningDropPct = 10.0;
const double weaningDangerDropPct = 15.0;
const int analysisWindowDays = 90;

// ==================== 异常方向枚举 ====================

/// 最近一次称重的异常方向，供称重表格多色标记使用。
enum AbnormalDirection {
  none, // 正常
  high, // 体重偏高
  low, // 体重偏低
}

// ==================== 纯数学工具函数 ====================

/// Log 增长率 ln(curr / prev)。任一 ≤0 时安全返回 0。
double logGrowth(double prev, double curr) =>
    prev > 0 && curr > 0 ? log(curr / prev) : 0;

/// 标准化为 24 小时增长率。h ≤ 0 时返回原值（不做外推）。
double normalize24h(double rate, double h) => h > 0 ? rate * (24 / h) : rate;

/// 两个时刻之间的小时数（可为负）。
double hoursBetween(DateTime a, DateTime b) =>
    b.difference(a).inMilliseconds / 3600000.0;

/// 算术平均。调用方保证列表非空（空列表将抛出 StateError）。
double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;

/// EWMA 指数移动平均序列，默认 alpha=0.2（基线平滑）。
/// 空列表返回 []，单元素返回自身。
List<double> ewma(List<double> values, {double alpha = 0.2}) {
  if (values.isEmpty) return [];
  final r = <double>[values.first];
  for (int i = 1; i < values.length; i++) {
    r.add(values[i] * alpha + r.last * (1 - alpha));
  }
  return r;
}

int effectiveInterval(BirdWithDetails bird) => bird.effectiveWeighIntervalDays;

// ==================== 断奶期检测 ====================

/// 判断是否处于断奶期（手动覆盖优先，否则自动检测）。
/// [weights] 需按 recordedAt ASC（最早在前）。
bool isWeaningPhase(BirdWithDetails bird, List<Weight> weights) {
  // 手动覆盖
  if (bird.bird.weaningOverride == true) return true;
  if (bird.bird.weaningOverride == false) return false;

  // 不在日龄窗口内
  if (bird.ageDays < bird.species.nestlingEndDays - 5 ||
      bird.ageDays > bird.species.juvenileEndDays) {
    return false;
  }

  if (weights.length < 3) return false;

  // 自动进入条件：从峰值下降 >5%，且最近 3 次中 >=2 次下降
  final peak = weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
  final latest = weights.last.weightG;
  if (latest >= peak * 0.95) return false; // 尚未明显下降

  int recentDrops = 0;
  for (int i = weights.length - 1; i > 0 && i > weights.length - 4; i--) {
    if (weights[i].weightG < weights[i - 1].weightG) recentDrops++;
  }
  if (recentDrops < 2) return false;

  // 自动退出条件
  // 条件 1：超龄强制退出
  if (bird.ageDays > bird.species.juvenileEndDays + 10) return false;

  // 条件 2：最近 3 次体重企稳（波动 <3%，且末次不低于第 3 次）
  if (weights.length >= 3) {
    final last3 = weights.sublist(weights.length - 3);
    final vals = last3.map((w) => w.weightG).toList();
    final avg3 = avg(vals);
    final range = vals.reduce((a, b) => a > b ? a : b) -
        vals.reduce((a, b) => a < b ? a : b);
    if (range / avg3 * 100 < 3 && vals.last >= vals.first) return false;
  }

  // 条件 3：体重回升 > 断奶期最低 x 1.05
  final subset = weights.skip(weights.length * 2 ~/ 3).toList();
  final weaningMin =
      subset.map((w) => w.weightG).reduce((a, b) => a < b ? a : b);
  if (latest > weaningMin * 1.05) return false;

  return true;
}

/// 判断最近一次称重的异常方向，供称重表格多色标记使用。
/// [weights] 按 recordedAt DESC（最新在前）。
///
/// 返回：
///   AbnormalDirection.none — 正常
///   AbnormalDirection.high — 偏高（体重高于基线 >warningPct）
///   AbnormalDirection.low  — 偏低（体重低于基线 >warningPct，或雏鸟生长不足/断奶期下降）
AbnormalDirection isLatestAbnormalDirection(
  BirdWithDetails bird,
  List<Weight> weights,
) {
  if (weights.length < 2) return AbnormalDirection.none;
  final latest = weights.first.weightG;
  final stage = bird.physioStage;

  // 断奶期 → low（从峰值下降）
  final inWeaning = alertStrategyOf(stage) == WeightAlertStrategy.weaning &&
      isWeaningPhase(bird, weights.reversed.toList());
  if (inWeaning) {
    final peak = weights.map((w) => w.weightG).reduce((a, b) => a > b ? a : b);
    final drop = (peak - latest) / peak * 100;
    return drop > weaningWarningDropPct
        ? AbnormalDirection.low
        : AbnormalDirection.none;
  }

  switch (alertStrategyOf(stage)) {
    case WeightAlertStrategy.growth:
      final now = AppClock.now;
      final cutoff48h = now.subtract(const Duration(hours: 48));
      final recent =
          weights.where((w) => w.recordedAt.isAfter(cutoff48h)).toList();
      if (recent.length < 2) return AbnormalDirection.none;
      final asc = recent.reversed.toList(); // DESC -> ASC
      final rates = <double>[];
      for (int i = 1; i < asc.length; i++) {
        final h =
            asc[i].recordedAt.difference(asc[i - 1].recordedAt).inMilliseconds /
                3600000.0;
        if (h <= 0) continue;
        if (asc[i - 1].weightG > 0 && asc[i].weightG > 0) {
          final logR = log(asc[i].weightG / asc[i - 1].weightG);
          rates.add(logR * (24 / h));
        }
      }
      if (rates.isEmpty) return AbnormalDirection.none;
      final avgRate = rates.reduce((a, b) => a + b) / rates.length;
      // 增长率不足 → low；雏鸟正常不会"偏高"
      if (avgRate < chickGrowthSlowRate) return AbnormalDirection.low;
      return AbnormalDirection.none;

    case WeightAlertStrategy.baseline:
    case WeightAlertStrategy.weaning:
      // weaning 已在上面处理，此处 baseline 逻辑同时覆盖亚成体/成鸟/繁殖/换羽
      final manualB = bird.bird.manualBaselineG;
      final double baseline;
      if (manualB != null) {
        baseline = manualB.toDouble();
      } else {
        if (weights.length < 3) return AbnormalDirection.none;
        final values = weights.reversed.map((w) => w.weightG).toList();
        double ema = values.first;
        for (int i = 1; i < values.length; i++) {
          ema = 0.2 * values[i] + 0.8 * ema;
        }
        baseline = ema;
      }
      final deviation = (latest - baseline) / baseline * 100;
      if (deviation.abs() <= warningDeviationPct) return AbnormalDirection.none;
      return deviation > 0 ? AbnormalDirection.high : AbnormalDirection.low;
  }
}

/// 向后兼容：判断该鸟最近一次称重是否异常。
/// [weights] 按 recordedAt DESC（最新在前）。
bool isLatestAbnormal(BirdWithDetails bird, List<Weight> weights) =>
    isLatestAbnormalDirection(bird, weights) != AbnormalDirection.none;
