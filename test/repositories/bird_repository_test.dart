import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/repositories/room_repository.dart';
import '../../lib/repositories/bird_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test();
    await db.createSpecies('虎皮鹦鹉');
    await db.createSpecies('玄凤鹦鹉');
  });

  tearDown(() async => db.close());

  group('createBird', () {
    test('creates a bird with required fields', () async {
      final bird = await db.createBird(
        name: '小绿',
        speciesId: 1,
        birthDate: DateTime(2024, 3, 15),
      );

      expect(bird.id, isNotNull);
      expect(bird.name, '小绿');
      expect(bird.speciesId, 1);
      expect(bird.birthDate, DateTime(2024, 3, 15));
      expect(bird.gender, '未知'); // default
      expect(bird.sortOrder, 1); // first bird = order 1
    });

    test('auto-increments sortOrder', () async {
      await db.createBird(name: 'A', speciesId: 1, birthDate: DateTime(2024, 1, 1));
      await db.createBird(name: 'B', speciesId: 1, birthDate: DateTime(2024, 2, 1));
      final c = await db.createBird(name: 'C', speciesId: 1, birthDate: DateTime(2024, 3, 1));

      expect(c.sortOrder, 3);
    });

    test('creates bird with optional fields', () async {
      final bird = await db.createBird(
        name: '小蓝',
        speciesId: 2, // 玄凤
        birthDate: DateTime(2023, 6, 1),
        gender: '公',
        ringNumber: 'RING-001',
        notes: '测试备注',
      );

      expect(bird.gender, '公');
      expect(bird.ringNumber, 'RING-001');
      expect(bird.notes, '测试备注');
    });
  });

  group('getBirdById', () {
    test('returns bird by ID', () async {
      await db.createBird(name: '小绿', speciesId: 1, birthDate: DateTime(2024, 1, 1));
      final bird = await db.getBirdById(1);

      expect(bird, isNotNull);
      expect(bird!.name, '小绿');
    });

    test('returns null for non-existent ID', () async {
      final bird = await db.getBirdById(999);
      expect(bird, isNull);
    });
  });

  group('getAllWithDetails', () {
    test('returns birds with species name', () async {
      await db.createBird(name: '小绿', speciesId: 1, birthDate: DateTime(2024, 1, 1));
      await db.createBird(name: '小白', speciesId: 2, birthDate: DateTime(2024, 2, 1));

      final list = await db.getAllWithDetails();
      expect(list.length, 2);
      expect(list[0].bird.name, '小绿');
      expect(list[0].species.name, '虎皮鹦鹉');
      expect(list[1].bird.name, '小白');
      expect(list[1].species.name, '玄凤鹦鹉');
    });

    test('returns empty list when no birds', () async {
      final list = await db.getAllWithDetails();
      expect(list, isEmpty);
    });
  });

  group('getByRoom', () {
    test('returns birds filtered by room', () async {
      await db.createRoom('育雏室');
      await db.createRoom('成鸟室');
      await db.createBird(name: 'A', speciesId: 1, birthDate: DateTime(2024, 1, 1), roomId: 1);
      await db.createBird(name: 'B', speciesId: 1, birthDate: DateTime(2024, 2, 1), roomId: 1);
      await db.createBird(name: 'C', speciesId: 1, birthDate: DateTime(2024, 3, 1), roomId: 2);

      final room1 = await db.getByRoom(1);
      expect(room1.length, 2);
      expect(room1[0].bird.name, 'A');
      expect(room1[1].bird.name, 'B');

      final room2 = await db.getByRoom(2);
      expect(room2.length, 1);
      expect(room2[0].bird.name, 'C');
    });
  });

  group('updateBird', () {
    test('updates bird fields', () async {
      await db.createBird(name: '小绿', speciesId: 1, birthDate: DateTime(2024, 1, 1));
      final updated = await db.updateBird(1, name: '小绿(已改名)', notes: '更新测试');

      expect(updated.name, '小绿(已改名)');
      expect(updated.notes, '更新测试');
      expect(updated.speciesId, 1); // unchanged
    });
  });

  group('getBirdCount', () {
    test('counts birds by species', () async {
      await db.createBird(name: 'A', speciesId: 1, birthDate: DateTime(2024, 1, 1));
      await db.createBird(name: 'B', speciesId: 1, birthDate: DateTime(2024, 2, 1));
      await db.createBird(name: 'C', speciesId: 2, birthDate: DateTime(2024, 3, 1));

      expect(await db.getBirdCountBySpecies(1), 2);
      expect(await db.getBirdCountBySpecies(2), 1);
    });

    test('counts birds by room', () async {
      await db.createRoom('育雏室');
      await db.createBird(name: 'A', speciesId: 1, birthDate: DateTime(2024, 1, 1), roomId: 1);
      await db.createBird(name: 'B', speciesId: 1, birthDate: DateTime(2024, 2, 1));

      expect(await db.getBirdCountByRoom(1), 1);
      expect(await db.getBirdCountByRoom(999), 0);
    });
  });

  group('removeBird', () {
    test('deletes a bird', () async {
      await db.createBird(name: '小绿', speciesId: 1, birthDate: DateTime(2024, 1, 1));
      await db.removeBird(1);

      final bird = await db.getBirdById(1);
      expect(bird, isNull);
    });
  });
}
