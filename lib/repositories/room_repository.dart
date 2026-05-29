import 'package:drift/drift.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

extension RoomRepository on AppDatabase {
  Future<List<Room>> getAllRooms() =>
      (select(rooms)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<Room?> getRoomById(int id) =>
      (select(rooms)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Room?> getRoomByName(String name) =>
      (select(rooms)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<Room?> getRoomByUuid(String uuid) =>
      (select(rooms)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  Future<Room> createRoom(String name, {int? assignedUserId}) async {
    final maxRow = await (selectOnly(rooms)
          ..addColumns([rooms.sortOrder.max()]))
        .map((row) => row.read(rooms.sortOrder.max()))
        .getSingle();
    await into(rooms).insert(RoomsCompanion.insert(
      uuid: genUuid(),
      name: name,
      sortOrder: Value((maxRow ?? 0) + 1),
      assignedUserId: assignedUserId != null ? Value(assignedUserId) : const Value.absent(),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getRoomById(rows.first.read<int>('id')))!;
  }

  Future<Room> updateRoom(int id,
      {String? name, int? sortOrder, int? assignedUserId}) async {
    final list = await (update(rooms)..where((t) => t.id.equals(id)))
        .writeReturning(RoomsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      assignedUserId: assignedUserId != null ? Value(assignedUserId) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
    return list.first;
  }

  Future<void> removeRoom(int id) =>
      (delete(rooms)..where((t) => t.id.equals(id))).go();

  Future<List<Room>> getByUser(int userId) =>
      (select(rooms)..where((t) => t.assignedUserId.equals(userId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
}
