import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import '../lib/database/database.dart';
import '../lib/services/alert_service.dart';
import '../lib/repositories/bird_repository.dart';
import '../lib/repositories/weight_repository.dart';
import '../lib/repositories/species_repository.dart';

/// ============================================
/// 测试框架 —— Mock 数据库 + 数据工厂
/// ============================================

/// 内存数据库工厂
AppDatabase createTestDb() => AppDatabase.test();

/// 数据工厂：快速创建测试用品种
Future<Specy> createTestSpecies(AppDatabase db, {
  String name = '测试品种',
  int nestlingEndDays = 45,
  int juvenileEndDays = 120,
}) async {
  return db.createSpecies(name,
      nestlingEndDays: nestlingEndDays, juvenileEndDays: juvenileEndDays);
}

/// 数据工厂：快速创建测试用鹦鹉
Future<Bird> createTestBird(AppDatabase db, {
  required int speciesId,
  String name = '测试鹦鹉',
  int daysAgo = 0,
}) async {
  return db.createBird(
    name: name,
    speciesId: speciesId,
    birthDate: DateTime.now().subtract(Duration(days: daysAgo)),
  );
}

/// 数据工厂：为鹦鹉添加一系列体重记录
Future<void> addWeightSeries(AppDatabase db, int birdId,
    List<({int hoursAgo, double grams})> entries) async {
  for (final e in entries) {
    await db.addWeight(
      birdId: birdId,
      weightG: e.grams,
      recordedAt: DateTime.now().subtract(Duration(hours: e.hoursAgo)),
    );
  }
}

/// ============================================
/// Alert Service 集成测试
/// ============================================

void main() {
  late AppDatabase db;
  late AlertService alertService;

  setUp(() async {
    db = createTestDb();
    alertService = AlertService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('雏鸟告警', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species = await createTestSpecies(db, nestlingEndDays: 45);
      bird = await createTestBird(db, speciesId: species.id, daysAgo: 10);
    });

    test('正常成长 → 不告警', () async {
      // 48h内从10g连续成长到15g
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
      species = await createTestSpecies(db, nestlingEndDays: 30, juvenileEndDays: 90);
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
      // 7天从100急降至85，EMA趋势明显
      final entries = <({int hoursAgo, double grams})>[];
      for (int i = 0; i < 7; i++) {
        entries.add((hoursAgo: (7 - i) * 24, grams: 100.0 - i * 2.5));
      }
      await addWeightSeries(db, bird.id, entries);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '慢性下降'), isTrue);
    });

    test('急性下降 → danger 告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 72, grams: 100),
        (hoursAgo: 24, grams: 100),
        (hoursAgo: 1, grams: 88),
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '急性下降'), isTrue);
    });
  });

  group('成鸟告警', () {
    late Bird bird;
    late Specy species;

    setUp(() async {
      species = await createTestSpecies(db, nestlingEndDays: 30, juvenileEndDays: 60);
      bird = await createTestBird(db, speciesId: species.id, daysAgo: 180);
    });

    test('连续3次下降 → 下降告警', () async {
      await addWeightSeries(db, bird.id, [
        (hoursAgo: 96, grams: 103),
        (hoursAgo: 72, grams: 100),
        (hoursAgo: 48, grams: 97),
        (hoursAgo: 24, grams: 94),
      ]);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '体重下降'), isTrue);
    });

    test('30日慢性下降 → 趋势告警', () async {
      // 30天内从100降至80，EMA趋势应明显
      final entries = <({int hoursAgo, double grams})>[];
      for (int i = 0; i < 10; i++) {
        entries.add((hoursAgo: (30 - i * 3) * 24, grams: 100.0 - i * 2.2));
      }
      await addWeightSeries(db, bird.id, entries);
      final alerts = await alertService.detectAll();
      expect(alerts.any((a) => a.type == '长期下降趋势'), isTrue);
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
      final w1 = await db.addWeight(
          birdId: bird.id, weightG: 10.0, recordedAt: DateTime.now());
      final w2 = await db.addWeight(
          birdId: bird.id, weightG: 11.0, recordedAt: DateTime.now());
      // 第二次应该覆盖第一次（同分钟）
      final weights = await db.getByBird(bird.id);
      expect(weights.length, 1);
      expect(weights.first.weightG, 11.0);
    });

    test('不同分钟不覆盖', () async {
      final w1 = await db.addWeight(
          birdId: bird.id, weightG: 10.0,
          recordedAt: DateTime.now().subtract(const Duration(minutes: 2)));
      final w2 = await db.addWeight(
          birdId: bird.id, weightG: 11.0, recordedAt: DateTime.now());
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
