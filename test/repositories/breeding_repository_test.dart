import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/plugins/breeding/breeding_repository.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../test_helpers/test_clock.dart';
import '../test_helpers/test_factories.dart';

/// ── BreedingRepository 测试 ──────────────────────────────────────────────
///
/// 验证配对唯一性校验、繁育阶段循环、配对分离。

final _fakeNow = DateTime(2025, 6, 15, 12, 0, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int speciesId;
  late Bird male;
  late Bird female;

  setUp(() async {
    await setTestClockWithPrefs(_fakeNow);
    db = await setUpTestDb();
    speciesId = (await db.createSpecies('虎皮鹦鹉')).id;
    male = await db.createBird(
      name: '公鸟',
      speciesId: speciesId,
      birthDate: _fakeNow.subtract(const Duration(days: 300)),
    );
    female = await db.createBird(
      name: '母鸟',
      speciesId: speciesId,
      birthDate: _fakeNow.subtract(const Duration(days: 300)),
    );
  });

  tearDown(() async {
    await tearDownTestDb(db);
    await resetTestClock();
  });

  // ═════════════════════════════════════════════════════════════════════════
  // createPair
  // ═════════════════════════════════════════════════════════════════════════

  group('createPair', () {
    test('正常创建配对', () async {
      final pair = await db.createPair(
        maleBirdId: male.id,
        femaleBirdId: female.id,
        pairName: '第一对',
      );
      expect(pair.id, greaterThan(0));
      expect(pair.maleBirdId, male.id);
      expect(pair.femaleBirdId, female.id);
      expect(pair.pairName, '第一对');
      expect(pair.status, 'active');
    });

    test('公鸟已有活跃配对 → throw StateError', () async {
      await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      final otherFemale = await db.createBird(
        name: '母鸟2',
        speciesId: speciesId,
        birthDate: _fakeNow.subtract(const Duration(days: 300)),
      );
      expect(
        () => db.createPair(maleBirdId: male.id, femaleBirdId: otherFemale.id),
        throwsA(isA<StateError>()),
      );
    });

    test('母鸟已有活跃配对 → throw StateError', () async {
      await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      final otherMale = await db.createBird(
        name: '公鸟2',
        speciesId: speciesId,
        birthDate: _fakeNow.subtract(const Duration(days: 300)),
      );
      expect(
        () => db.createPair(maleBirdId: otherMale.id, femaleBirdId: female.id),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // separatePair
  // ═════════════════════════════════════════════════════════════════════════

  group('separatePair', () {
    test('分离后状态变为 separated', () async {
      final pair = await db.createPair(
        maleBirdId: male.id,
        femaleBirdId: female.id,
      );
      await db.separatePair(pair.id);
      final updated = await db.getPairById(pair.id);
      expect(updated!.status, 'separated');
      expect(updated.separatedDate, isNotNull);
    });

    test('分离后鸟可重新配对', () async {
      final pair = await db.createPair(
        maleBirdId: male.id,
        femaleBirdId: female.id,
      );
      await db.separatePair(pair.id);
      // 重新配对不应抛异常
      final newPair = await db.createPair(
        maleBirdId: male.id,
        femaleBirdId: female.id,
      );
      expect(newPair.status, 'active');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // createBreedingRecord
  // ═════════════════════════════════════════════════════════════════════════

  group('createBreedingRecord', () {
    test('正常创建繁育记录', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      final record = await db.createBreedingRecord(pair.id);
      expect(record.id, greaterThan(0));
      expect(record.pairId, pair.id);
      expect(record.stage, '配对');
    });

    test('重复创建（已有活跃记录）→ throw StateError', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      await db.createBreedingRecord(pair.id);
      expect(
        () => db.createBreedingRecord(pair.id),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // advanceStage
  // ═════════════════════════════════════════════════════════════════════════

  group('advanceStage', () {
    test('配对 → 产蛋', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      final record = await db.createBreedingRecord(pair.id);
      await db.advanceStage(record.id);
      final updated = await (db.select(db.breedingRecords)
            ..where((t) => t.id.equals(record.id)))
          .getSingle();
      expect(updated.stage, '产蛋');
    });

    test('产蛋 → 孵化 → 育雏 → 已完结（完整循环）', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      final record = await db.createBreedingRecord(pair.id);

      await db.advanceStage(record.id); // 配对 → 产蛋
      await db.advanceStage(record.id); // 产蛋 → 孵化
      await db.advanceStage(record.id); // 孵化 → 育雏
      await db.advanceStage(record.id); // 育雏 → 已完结

      final updated = await (db.select(db.breedingRecords)
            ..where((t) => t.id.equals(record.id)))
          .getSingle();
      expect(updated.stage, '已完结');
      expect(updated.endDate, isNotNull);
    });

    test('已完结后再推进 → throw StateError', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      final record = await db.createBreedingRecord(pair.id);
      for (int i = 0; i < 4; i++) {
        await db.advanceStage(record.id);
      }
      // 已完结，再推进应抛异常
      expect(
        () => db.advanceStage(record.id),
        throwsA(isA<StateError>()),
      );
    });

    test('不存在的记录 → throw StateError', () {
      expect(
        () => db.advanceStage(99999),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // isBreeding / getActivePairForBird
  // ═════════════════════════════════════════════════════════════════════════

  group('isBreeding', () {
    test('无配对 → false', () async {
      expect(await db.isBreeding(male.id), isFalse);
    });

    test('有活跃配对但无繁育记录 → false（仅配对不算"繁育中"）', () async {
      await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      expect(await db.isBreeding(male.id), isFalse);
    });

    test('有活跃配对 + 进行中繁育记录 → true', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      await db.createBreedingRecord(pair.id);
      expect(await db.isBreeding(male.id), isTrue);
      expect(await db.isBreeding(female.id), isTrue);
    });

    test('分离后 → false', () async {
      final pair =
          await db.createPair(maleBirdId: male.id, femaleBirdId: female.id);
      await db.createBreedingRecord(pair.id);
      await db.separatePair(pair.id);
      expect(await db.isBreeding(male.id), isFalse);
    });
  });
}
