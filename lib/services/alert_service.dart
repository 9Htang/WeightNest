import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';

/// 异常检测结果
class AnomalyAlert {
  final BirdWithDetails bird;
  final String type;
  final String description;
  final AlertSeverity severity;

  AnomalyAlert({
    required this.bird,
    required this.type,
    required this.description,
    required this.severity,
  });
}

enum AlertSeverity { warning, danger }

/// 异常检测服务
class AlertService {
  final AppDatabase _db;

  AlertService(this._db);

  /// 检测所有鹦鹉的异常
  Future<List<AnomalyAlert>> detectAll() async {
    final alerts = <AnomalyAlert>[];
    final allBirds = await _db.getAllWithDetails();

    for (final bird in allBirds) {
      final weights = await _db.getByBird(bird.bird.id);
      if (weights.isEmpty) continue;

      alerts.addAll(_checkWeightDrop(bird, weights));
      alerts.addAll(_checkGrowthStagnation(bird, weights));
      alerts.addAll(_checkOverdue(bird, weights));
    }

    return alerts;
  }

  /// 体重持续下降（连续3次）
  List<AnomalyAlert> _checkWeightDrop(BirdWithDetails bird, List<Weight> weights) {
    if (weights.length < 3) return [];

    final recent = weights.sublist(0, 3);
    var dropping = true;
    for (int i = 1; i < recent.length; i++) {
      if (recent[i].weightG >= recent[i - 1].weightG) {
        dropping = false;
        break;
      }
    }

    if (dropping) {
      final drop = recent.last.weightG - recent.first.weightG;
      final pct = (drop / recent.first.weightG * 100).abs();
      return [AnomalyAlert(
        bird: bird,
        type: '体重下降',
        description: '连续3次下降，${recent.first.weightG}g → ${recent.last.weightG}g (${pct.toStringAsFixed(0)}%)',
        severity: pct > 10 ? AlertSeverity.danger : AlertSeverity.warning,
      )];
    }
    return [];
  }

  /// 雏鸟/幼鸟成长停滞
  List<AnomalyAlert> _checkGrowthStagnation(BirdWithDetails bird, List<Weight> weights) {
    if (bird.growthStage == '成鸟') return [];
    if (weights.length < 2) return [];

    final recent = weights.sublist(0, 2);
    if (recent.first.weightG <= recent.last.weightG) return [];

    return [AnomalyAlert(
      bird: bird,
      type: '增长停滞',
      description: '${bird.growthStage}体重从 ${recent.last.weightG}g 降至 ${recent.first.weightG}g',
      severity: AlertSeverity.danger,
    )];
  }

  /// 超期未称重（>7天）
  List<AnomalyAlert> _checkOverdue(BirdWithDetails bird, List<Weight> weights) {
    final latest = weights.first;
    final daysSince = DateTime.now().difference(latest.recordedAt).inDays;

    if (daysSince > 7) {
      return [AnomalyAlert(
        bird: bird,
        type: '超期未称重',
        description: '已 $daysSince 天未记录体重',
        severity: daysSince > 14 ? AlertSeverity.danger : AlertSeverity.warning,
      )];
    }
    return [];
  }
}
