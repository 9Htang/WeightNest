import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/app_clock.dart';
import '../../lib/database/database.dart';
import '../../lib/services/alert_service.dart';
import '../../lib/repositories/weight_repository.dart';
import '../test_helpers/test_factories.dart';

/// ── AlertService + Repository 跨层集成测试 ───────────────────────────────
///
/// 这是一组 vm 级（无头）集成测试，验证 AlertService 在真实内存 DB + 多插件
/// 注册场景下的端到端告警检测，以及 WeightRepository 的时间覆盖/排序行为。
///
/// 注意：此处 *不是* Flutter `integration_test` 包的设备级测试。
/// 设备级 E2E 流程见 integration_test/ 目录（待后续阶段补充）。

void main() {
  late AppDatabase db;
  late AlertService alertService;

  setUp(() async {
    db = await setUpTestDb();
    alertService = AlertService(db);
  });

  tearDown(() => tearDownTestDb(db));

  group('雏鸟告警', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species = await createTestSpecies(db, nestlingEndDays: 45);
      bird = await createTestBird(db, speciesId: species.id, daysAgo: 10);
    });

    test('正常成长 → 不告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 48, grams: 10),
        (hoursAgo: 36, grams: 12),
        (hoursAgo: 24, grams: 14),
        (hoursAgo: 12, grams: 15),
      ]);
      final alerts = await alertService.detectAll();
      final chickAlerts =
          alerts.where((a) => a.bird.bird.id == bird.id).toList();
      expect(chickAlerts.where((a) => a.type == '体重下降'), isEmpty);
    });

    test('增长停滞 → 告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 48, grams: 10),
        (hoursAgo: 24, grams: 10.1),
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '增长停滞'), isTrue);
    });

    test('体重下降 → danger 告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 48, grams: 12),
        (hoursAgo: 24, grams: 10),
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '体重下降'), isTrue);
    });

    test('连续3次下降 → 连续下降告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 96, grams: 17),
        (hoursAgo: 72, grams: 15),
        (hoursAgo: 48, grams: 13),
        (hoursAgo: 24, grams: 11),
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '连续下降'), isTrue);
    });
  });

  group('幼鸟告警', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species =
          await createTestSpecies(db, nestlingEndDays: 30, juvenileEndDays: 90);
      bird = await createTestBird(db, speciesId: species.id, daysAgo: 40);
    });

    test('稳定体重 → 不告警', () async {
      final weights = [100.0, 101.0, 99.5, 100.5, 101.0, 99.8, 100.2];
      final entries = <({int hoursAgo, double grams})>[];
      for (int i = 0; i < weights.length; i++) {
        entries.add((hoursAgo: (weights.length - i) * 24, grams: weights[i]));
      }
      await addWeightSeries(db, bird.id, entries);
      final alerts = await alertService.detectAll();
      final juvenileAlerts = alerts.where((a) => a.bird.bird.id == bird.id);
      // 波动率应 < 8%，不应触发波动异常
      expect(juvenileAlerts.where((a) => a.type == '波动异常'), isEmpty);
    });

    test('慢性下降 → EMA趋势告警', () async {
      // 10天从100降至80，EMA趋势 -8% > 7% 阈值
      final entries = <({int hoursAgo, double grams})>[];
      for (int i = 0; i < 10; i++) {
        entries.add((
          hoursAgo: (10 - i) * 24,
          grams: 100.0 - i * (20.0 / 9.0) // 100, 97.78, 95.56, ... , 80
        ));
      }
      await addWeightSeries(db, bird.id, entries);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '体重持续下降'), isTrue);
    });

    test('急性下降 → danger 告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 72, grams: 100),
        (hoursAgo: 24, grams: 100),
        (hoursAgo: 1, grams: 80), // deviation -17% > 15% danger threshold
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '体重异常偏低'), isTrue);
    });
  });

  group('成鸟告警', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species =
          await createTestSpecies(db, nestlingEndDays: 30, juvenileEndDays: 60);
      bird = await createTestBird(db, speciesId: species.id, daysAgo: 180);
    });

    test('连续3次下降 → 下降告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 96, grams: 120),
        (hoursAgo: 72, grams: 110),
        (hoursAgo: 48, grams: 103),
        (hoursAgo: 24, grams: 95), // deviation -14% > 10% warning threshold
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '体重偏低'), isTrue);
    });

    test('30日慢性下降 → 趋势告警', () async {
      // 30天内从100降至80.2，EMA趋势 -7.5% > 7% 阈值
      final entries = <({int hoursAgo, double grams})>[];
      for (int i = 0; i < 10; i++) {
        entries.add((hoursAgo: (30 - i * 3) * 24, grams: 100.0 - i * 2.2));
      }
      await addWeightSeries(db, bird.id, entries);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '体重持续下降'), isTrue);
    });
  });

  group('超期告警', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species = await createTestSpecies(db);
      bird = await createTestBird(db, speciesId: species.id, daysAgo: 100);
    });

    test('>7天未称重 → 超期告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 8 * 24, grams: 50),
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '超期未称重'), isTrue);
    });
  });

  group('Weight Repository', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species = await createTestSpecies(db);
      bird = await createTestBird(db, speciesId: species.id);
    });

    test('同分钟内覆盖', () async {
      await db.addWeight(
          birdId: bird.id, weightG: 10.0, recordedAt: AppClock.now);
      await db.addWeight(
          birdId: bird.id, weightG: 11.0, recordedAt: AppClock.now);
      final weights = await db.getByBird(bird.id);
      expect(weights.length, 1);
      expect(weights.first.weightG, 11.0);
    });

    test('不同分钟不覆盖', () async {
      await db.addWeight(
          birdId: bird.id,
          weightG: 10.0,
          recordedAt: AppClock.now.subtract(const Duration(minutes: 2)));
      await db.addWeight(
          birdId: bird.id, weightG: 11.0, recordedAt: AppClock.now);
      final weights = await db.getByBird(bird.id);
      expect(weights.length, 2);
    });

    test('按时间降序排列', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 48, grams: 10),
        (hoursAgo: 24, grams: 12),
        (hoursAgo: 1, grams: 11),
      ]);
      final weights = await db.getByBird(bird.id);
      expect(weights.length, 3);
      expect(weights.first.weightG, 11); // 最新
      expect(weights.last.weightG, 10); // 最旧
    });
  });
}
