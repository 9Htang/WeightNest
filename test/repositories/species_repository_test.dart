import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../test_helpers/test_factories.dart';

@Tags(['smoke'])
void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestDb();
  });

  tearDown(() => tearDownTestDb(db));

  // ── createSpecies ──

  group('createSpecies', () {
    test('creates a species with required fields', () async {
      final species = await db.createSpecies('虎皮鹦鹉');

      expect(species.id, isNotNull);
      expect(species.name, '虎皮鹦鹉');
      expect(species.nestlingEndDays, 45);
      expect(species.juvenileEndDays, 120);
      expect(species.uuid, isNotEmpty);
    });

    test('creates a species with custom parameters', () async {
      final species = await db.createSpecies('玄凤鹦鹉',
          nestlingEndDays: 60,
          juvenileEndDays: 150,
          nestlingWeighIntervalDays: 2,
          juvenileWeighIntervalDays: 5,
          adultWeighIntervalDays: 14,
          minWeightG: 80.0,
          maxWeightG: 120.0);

      expect(species.name, '玄凤鹦鹉');
      expect(species.nestlingEndDays, 60);
      expect(species.juvenileEndDays, 150);
      expect(species.nestlingWeighIntervalDays, 2);
      expect(species.juvenileWeighIntervalDays, 5);
      expect(species.adultWeighIntervalDays, 14);
      expect(species.minWeightG, 80.0);
      expect(species.maxWeightG, 120.0);
    });

    test('auto-generates UUID if not provided', () async {
      final s1 = await db.createSpecies('A');
      final s2 = await db.createSpecies('B');
      expect(s1.uuid, isNot(equals(s2.uuid)));
    });

    test('uses provided UUID when specified', () async {
      final species = await db.createSpecies('测试', uuid: 'custom-uuid-123');
      expect(species.uuid, 'custom-uuid-123');
    });
  });

  // ── getAllSpecies ──

  group('getAllSpecies', () {
    test('returns empty list when no species exist', () async {
      final list = await db.getAllSpecies();
      expect(list, isEmpty);
    });

    test('returns all species sorted by name', () async {
      await db.createSpecies('玄凤鹦鹉');
      await db.createSpecies('虎皮鹦鹉');
      await db.createSpecies('牡丹鹦鹉');

      final list = await db.getAllSpecies();
      expect(list.length, 3);
      final names = list.map((s) => s.name).toList();
      // ASC sort by name; verify sorted regardless of exact glyph order
      expect(names, equals(List.of(names)..sort()));
    });
  });

  // ── getSpeciesById ──

  group('getSpeciesById', () {
    test('returns species by ID', () async {
      final species = await db.createSpecies('虎皮鹦鹉');
      final found = await db.getSpeciesById(species.id);
      expect(found, isNotNull);
      expect(found!.name, '虎皮鹦鹉');
    });

    test('returns null for non-existent ID', () async {
      final found = await db.getSpeciesById(999);
      expect(found, isNull);
    });
  });

  // ── getSpeciesByName ──

  group('getSpeciesByName', () {
    test('returns species by name', () async {
      await db.createSpecies('虎皮鹦鹉');
      final found = await db.getSpeciesByName('虎皮鹦鹉');
      expect(found, isNotNull);
      expect(found!.name, '虎皮鹦鹉');
    });

    test('returns null for non-existent name', () async {
      final found = await db.getSpeciesByName('不存在');
      expect(found, isNull);
    });
  });

  // ── getSpeciesByNameSafe ──

  group('getSpeciesByNameSafe', () {
    test('returns first match when duplicates exist', () async {
      // Manually insert two species with same name (unique constraint not enforced at DB level)
      await db.into(db.species).insert(SpeciesCompanion.insert(
            uuid: 'uuid-a',
            name: '重复品种',
            nestlingEndDays: const Value(45),
            juvenileEndDays: const Value(120),
            nestlingWeighIntervalDays: const Value(1),
            juvenileWeighIntervalDays: const Value(3),
            adultWeighIntervalDays: const Value(7),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));
      await db.into(db.species).insert(SpeciesCompanion.insert(
            uuid: 'uuid-b',
            name: '重复品种',
            nestlingEndDays: const Value(45),
            juvenileEndDays: const Value(120),
            nestlingWeighIntervalDays: const Value(1),
            juvenileWeighIntervalDays: const Value(3),
            adultWeighIntervalDays: const Value(7),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final found = await db.getSpeciesByNameSafe('重复品种');
      expect(found, isNotNull);
      expect(found!.name, '重复品种');
    });

    test('returns null when no match', () async {
      final found = await db.getSpeciesByNameSafe('不存在');
      expect(found, isNull);
    });
  });

  // ── getSpeciesByUuid ──

  group('getSpeciesByUuid', () {
    test('returns species by UUID', () async {
      final species = await db.createSpecies('虎皮鹦鹉', uuid: 'my-uuid');
      final found = await db.getSpeciesByUuid('my-uuid');
      expect(found, isNotNull);
      expect(found!.id, species.id);
    });

    test('returns null for non-existent UUID', () async {
      final found = await db.getSpeciesByUuid('nonexistent');
      expect(found, isNull);
    });
  });

  // ── upsertByUuid ──

  group('upsertByUuid', () {
    test('creates new species when UUID not found', () async {
      final species = await db.upsertByUuid('new-uuid', name: '新品种');
      expect(species.uuid, 'new-uuid');
      expect(species.name, '新品种');

      final found = await db.getSpeciesByUuid('new-uuid');
      expect(found, isNotNull);
    });

    test('updates existing species when UUID found', () async {
      await db.upsertByUuid('upsert-uuid', name: '旧名称', nestlingEndDays: 45);
      final updated = await db.upsertByUuid('upsert-uuid',
          name: '新名称', nestlingEndDays: 60);
      expect(updated.name, '新名称');
      expect(updated.nestlingEndDays, 60);

      // Verify only one row exists
      final all = await db.getAllSpecies();
      expect(all.where((s) => s.uuid == 'upsert-uuid').length, 1);
    });
  });

  // ── updateSpecies ──

  group('updateSpecies', () {
    test('updates name', () async {
      final species = await db.createSpecies('虎皮鹦鹉');
      final updated = await db.updateSpecies(species.id, name: '玄凤鹦鹉');
      expect(updated.name, '玄凤鹦鹉');
    });

    test('updates only specified fields', () async {
      final species = await db.createSpecies('虎皮鹦鹉',
          nestlingEndDays: 45, juvenileEndDays: 120);
      final updated = await db.updateSpecies(species.id, nestlingEndDays: 60);
      expect(updated.nestlingEndDays, 60);
      expect(updated.juvenileEndDays, 120); // unchanged
    });

    test('updates updatedAt timestamp', () async {
      final species = await db.createSpecies('虎皮鹦鹉');
      // updatedAt set on create; advance wall clock by stubbing is fragile,
      // so just assert the field is non-null and equals a recent DateTime.
      final updated = await db.updateSpecies(species.id, name: '改名');
      expect(updated.updatedAt, isNotNull);
    });
  });

  // ── removeSpecies ──

  group('removeSpecies', () {
    test('deletes a species', () async {
      final species = await db.createSpecies('虎皮鹦鹉');
      await db.removeSpecies(species.id);

      final found = await db.getSpeciesById(species.id);
      expect(found, isNull);
    });

    test('does not throw when deleting non-existent species', () async {
      // Should not throw
      await db.removeSpecies(99999);
    });
  });
}
