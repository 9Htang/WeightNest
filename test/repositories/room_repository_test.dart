import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/room_repository.dart';
import '../test_helpers/test_factories.dart';

@Tags(['smoke'])
void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestDb();
  });

  tearDown(() => tearDownTestDb(db));

  // ── createRoom ──

  group('createRoom', () {
    test('creates a room with name', () async {
      final room = await db.createRoom('育雏室');
      expect(room.id, isNotNull);
      expect(room.name, '育雏室');
      expect(room.uuid, isNotEmpty);
      expect(room.sortOrder, 1); // first room = order 1
    });

    test('auto-increments sortOrder', () async {
      final r1 = await db.createRoom('A');
      final r2 = await db.createRoom('B');
      final r3 = await db.createRoom('C');
      expect(r1.sortOrder, 1);
      expect(r2.sortOrder, 2);
      expect(r3.sortOrder, 3);
    });
  });

  // ── getAllRooms ──

  group('getAllRooms', () {
    test('returns empty list when no rooms', () async {
      final list = await db.getAllRooms();
      expect(list, isEmpty);
    });

    test('returns rooms sorted by sortOrder', () async {
      await db.createRoom('B');
      await db.createRoom('A');
      final list = await db.getAllRooms();
      expect(list.length, 2);
      expect(list[0].name, 'B'); // sortOrder 1
      expect(list[1].name, 'A'); // sortOrder 2
    });
  });

  // ── getRoomById ──

  group('getRoomById', () {
    test('returns room by ID', () async {
      final room = await db.createRoom('育雏室');
      final found = await db.getRoomById(room.id);
      expect(found, isNotNull);
      expect(found!.name, '育雏室');
    });

    test('returns null for non-existent ID', () async {
      final found = await db.getRoomById(999);
      expect(found, isNull);
    });
  });

  // ── getRoomByName ──

  group('getRoomByName', () {
    test('returns room by name', () async {
      await db.createRoom('育雏室');
      final found = await db.getRoomByName('育雏室');
      expect(found, isNotNull);
      expect(found!.name, '育雏室');
    });

    test('returns null for non-existent name', () async {
      final found = await db.getRoomByName('不存在');
      expect(found, isNull);
    });
  });

  // ── updateRoom ──

  group('updateRoom', () {
    test('updates name', () async {
      final room = await db.createRoom('育雏室');
      final updated = await db.updateRoom(room.id, name: '成鸟室');
      expect(updated.name, '成鸟室');
    });

    test('updates sortOrder', () async {
      final r1 = await db.createRoom('A');
      final r2 = await db.createRoom('B');
      // Swap order
      await db.updateRoom(r1.id, sortOrder: 2);
      await db.updateRoom(r2.id, sortOrder: 1);
      final list = await db.getAllRooms();
      expect(list[0].name, 'B');
      expect(list[1].name, 'A');
    });
  });

  // ── removeRoom ──

  group('removeRoom', () {
    test('deletes a room', () async {
      final room = await db.createRoom('育雏室');
      await db.removeRoom(room.id);
      final found = await db.getRoomById(room.id);
      expect(found, isNull);
    });
  });
}
