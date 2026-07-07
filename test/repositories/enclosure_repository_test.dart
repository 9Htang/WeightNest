import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/repositories/room_repository.dart';
import '../../lib/repositories/enclosure_repository.dart';
import '../test_helpers/test_factories.dart';

@Tags(['smoke'])
void main() {
  late AppDatabase db;
  late int speciesId;

  setUp(() async {
    db = await setUpTestDb();
    speciesId = (await db.createSpecies('虎皮鹦鹉')).id;
  });

  tearDown(() => tearDownTestDb(db));

  /// Helper: create a room and return it.
  Future<Room> _room({String name = '测试房间'}) async {
    return db.createRoom(name);
  }

  // ── createEnclosure ──

  group('createEnclosure', () {
    test('creates an enclosure in a room', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      expect(enclosure.id, isNotNull);
      expect(enclosure.name, 'A笼');
      expect(enclosure.roomId, room.id);
      expect(enclosure.sortOrder, 1);
    });

    test('auto-increments sortOrder within room', () async {
      final room = await _room();
      final e1 = await db.createEnclosure('A笼', room.id);
      final e2 = await db.createEnclosure('B笼', room.id);
      expect(e1.sortOrder, 1);
      expect(e2.sortOrder, 2);
    });

    test('sortOrder is global across rooms (continues incrementing)', () async {
      final room1 = await _room(name: '房间1');
      final room2 = await _room(name: '房间2');
      final e1 = await db.createEnclosure('笼A', room1.id);
      final e2 = await db.createEnclosure('笼B', room2.id);
      // sortOrder max is computed globally (not per-room)
      expect(e1.sortOrder, 1);
      expect(e2.sortOrder, 2);
    });
  });

  // ── getEnclosuresByRoom ──

  group('getEnclosuresByRoom', () {
    test('returns enclosures for a room, sorted by sortOrder', () async {
      final room = await _room();
      await db.createEnclosure('B笼', room.id);
      await db.createEnclosure('A笼', room.id);
      final list = await db.getEnclosuresByRoom(room.id);
      expect(list.length, 2);
      expect(list[0].name, 'B笼'); // sortOrder 1
      expect(list[1].name, 'A笼'); // sortOrder 2
    });

    test('returns empty list for room with no enclosures', () async {
      final room = await _room();
      final list = await db.getEnclosuresByRoom(room.id);
      expect(list, isEmpty);
    });
  });

  // ── getEnclosureById ──

  group('getEnclosureById', () {
    test('returns enclosure by ID', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      final found = await db.getEnclosureById(enclosure.id);
      expect(found, isNotNull);
      expect(found!.name, 'A笼');
    });

    test('returns null for non-existent ID', () async {
      final found = await db.getEnclosureById(999);
      expect(found, isNull);
    });
  });

  // ── getBirdCountByEnclosure ──

  group('getBirdCountByEnclosure', () {
    test('returns 0 for empty enclosure', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      final count = await db.getBirdCountByEnclosure(enclosure.id);
      expect(count, 0);
    });

    test('returns correct count with birds', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      await db.createBird(
        name: '鸟1',
        speciesId: speciesId,
        birthDate: DateTime(2024, 1, 1),
        roomId: room.id,
        enclosureId: enclosure.id,
      );
      await db.createBird(
        name: '鸟2',
        speciesId: speciesId,
        birthDate: DateTime(2024, 1, 1),
        roomId: room.id,
        enclosureId: enclosure.id,
      );
      final count = await db.getBirdCountByEnclosure(enclosure.id);
      expect(count, 2);
    });
  });

  // ── getEnclosureWithCount ──

  group('getEnclosureWithCount', () {
    test('returns enclosure with bird count', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      final result = await db.getEnclosureWithCount(enclosure.id);
      expect(result.enclosure.name, 'A笼');
      expect(result.birdCount, 0);
    });
  });

  // ── getByRoomWithCounts ──

  group('getByRoomWithCounts', () {
    test('returns all enclosures with bird counts for a room', () async {
      final room = await _room();
      final e1 = await db.createEnclosure('A笼', room.id);
      final e2 = await db.createEnclosure('B笼', room.id);

      // Add a bird to e1
      await db.createBird(
        name: '鸟1',
        speciesId: speciesId,
        birthDate: DateTime(2024, 1, 1),
        roomId: room.id,
        enclosureId: e1.id,
      );

      final result = await db.getByRoomWithCounts(room.id);
      expect(result.length, 2);
      expect(result[0].enclosure.name, 'A笼');
      expect(result[0].birdCount, 1);
      expect(result[1].enclosure.name, 'B笼');
      expect(result[1].birdCount, 0);
    });
  });

  // ── updateEnclosure ──

  group('updateEnclosure', () {
    test('updates name', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      final updated = await db.updateEnclosure(enclosure.id, name: 'B笼');
      expect(updated.name, 'B笼');
    });

    test('updates sortOrder', () async {
      final room = await _room();
      final e1 = await db.createEnclosure('A笼', room.id);
      final e2 = await db.createEnclosure('B笼', room.id);
      await db.updateEnclosure(e1.id, sortOrder: 3);
      final list = await db.getEnclosuresByRoom(room.id);
      expect(list[0].name, 'B笼');
      expect(list[1].name, 'A笼');
    });
  });

  // ── removeEnclosure ──

  group('removeEnclosure', () {
    test('deletes an enclosure', () async {
      final room = await _room();
      final enclosure = await db.createEnclosure('A笼', room.id);
      await db.removeEnclosure(enclosure.id);
      final found = await db.getEnclosureById(enclosure.id);
      expect(found, isNull);
    });
  });
}
