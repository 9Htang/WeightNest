import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/weight_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test();
    // Set up minimum required data: species → bird
    final species = await db.createSpecies('虎皮鹦鹉');
    await db.createBird(
      name: '测试鸟1',
      speciesId: species.id,
      birthDate: DateTime(2024, 1, 1),
    );
    await db.createBird(
      name: '测试鸟2',
      speciesId: species.id,
      birthDate: DateTime(2024, 6, 1),
    );
  });

  tearDown(() async => db.close());

  // ── addWeight ──

  group('addWeight', () {
    test('inserts a weight record and returns it', () async {
      final w = await db.addWeight(
        birdId: 1,
        weightG: 45.5,
        recordedAt: DateTime(2025, 1, 1, 8, 30),
      );

      expect(w.id, isNotNull);
      expect(w.birdId, 1);
      expect(w.weightG, 45.5);
      expect(w.isFasting, false);
    });

    test('overwrites existing record in the same minute', () async {
      final first = await db.addWeight(
        birdId: 1,
        weightG: 45.5,
        recordedAt: DateTime(2025, 1, 1, 8, 30),
      );
      final second = await db.addWeight(
        birdId: 1,
        weightG: 46.0,
        recordedAt: DateTime(2025, 1, 1, 8, 30, 30), // same minute
      );

      expect(second.id, first.id); // overwritten, same row
      expect(second.weightG, 46.0);

      final all = await db.getByBird(1);
      expect(all.length, 1); // only one record
    });

    test('creates separate record for different minute', () async {
      await db.addWeight(
        birdId: 1,
        weightG: 45.5,
        recordedAt: DateTime(2025, 1, 1, 8, 30),
      );
      await db.addWeight(
        birdId: 1,
        weightG: 46.0,
        recordedAt: DateTime(2025, 1, 1, 8, 31), // different minute
      );

      final all = await db.getByBird(1);
      expect(all.length, 2);
    });
  });

  // ── getByBird ──

  group('getByBird', () {
    test('returns weights sorted by recorded_at DESC', () async {
      await db.addWeight(birdId: 1, weightG: 40.0, recordedAt: DateTime(2025, 1, 1, 8, 0));
      await db.addWeight(birdId: 1, weightG: 42.0, recordedAt: DateTime(2025, 1, 1, 9, 0));
      await db.addWeight(birdId: 1, weightG: 41.0, recordedAt: DateTime(2025, 1, 1, 8, 30));

      final results = await db.getByBird(1);
      expect(results.length, 3);
      expect(results[0].weightG, 42.0); // latest first
      expect(results[2].weightG, 40.0); // earliest last
    });

    test('returns empty list for bird with no weights', () async {
      final results = await db.getByBird(2);
      expect(results, isEmpty);
    });
  });

  // ── getLatestByBird ──

  group('getLatestByBird', () {
    test('returns the most recent weight record', () async {
      await db.addWeight(birdId: 1, weightG: 40.0, recordedAt: DateTime(2025, 1, 1, 8, 0));
      await db.addWeight(birdId: 1, weightG: 44.0, recordedAt: DateTime(2025, 1, 3, 12, 0));

      final latest = await db.getLatestByBird(1);
      expect(latest, isNotNull);
      expect(latest!.weightG, 44.0);
    });

    test('returns null for bird with no weights', () async {
      final latest = await db.getLatestByBird(2);
      expect(latest, isNull);
    });
  });

  // ── getLatestByBirds (N+1 optimized) ──

  group('getLatestByBirds', () {
    test('returns latest weight for each bird in one query', () async {
      await db.addWeight(birdId: 1, weightG: 40.0, recordedAt: DateTime(2025, 1, 1, 8, 0));
      await db.addWeight(birdId: 1, weightG: 42.0, recordedAt: DateTime(2025, 1, 2, 8, 0));
      await db.addWeight(birdId: 2, weightG: 50.0, recordedAt: DateTime(2025, 1, 1, 10, 0));
      await db.addWeight(birdId: 2, weightG: 52.0, recordedAt: DateTime(2025, 1, 3, 10, 0));

      final result = await db.getLatestByBirds([1, 2]);

      expect(result[1]!.weightG, 42.0);
      expect(result[2]!.weightG, 52.0);
    });

    test('returns null for birds with no weights', () async {
      await db.addWeight(birdId: 1, weightG: 40.0, recordedAt: DateTime(2025, 1, 1, 8, 0));

      final result = await db.getLatestByBirds([1, 2]);

      expect(result[1]!.weightG, 40.0);
      expect(result[2], isNull);
    });

    test('returns empty map for empty input', () async {
      final result = await db.getLatestByBirds([]);
      expect(result, isEmpty);
    });
  });

  // ── checkWeightExists ──

  group('checkWeightExists', () {
    test('returns true when a weight exists in the same minute', () async {
      await db.addWeight(birdId: 1, weightG: 45.0, recordedAt: DateTime(2025, 1, 1, 8, 30));

      final exists = await db.checkWeightExists(1, DateTime(2025, 1, 1, 8, 30, 45));
      expect(exists, isTrue);
    });

    test('returns false when no weight exists for that minute', () async {
      final exists = await db.checkWeightExists(1, DateTime(2025, 1, 1, 9, 0));
      expect(exists, isFalse);
    });
  });

  // ── removeWeight ──

  group('removeWeight', () {
    test('deletes a weight record by ID', () async {
      final w = await db.addWeight(birdId: 1, weightG: 45.0, recordedAt: DateTime(2025, 1, 1, 8, 0));
      await db.removeWeight(w.id);

      final results = await db.getByBird(1);
      expect(results, isEmpty);
    });
  });
}
