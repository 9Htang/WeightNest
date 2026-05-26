import 'package:drift/drift.dart';
import '../database/database.dart';

extension BirdRepository on AppDatabase {
  Future<List<BirdWithDetails>> getAllWithDetails() async {
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
    ])..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows.map((row) => BirdWithDetails(
          bird: row.readTable(birds),
          species: row.readTable(species),
          room: row.readTableOrNull(rooms),
        )).toList();
  }

  Future<Bird?> getBirdById(int id) =>
      (select(birds)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Bird> createBird({
    required String name,
    required int speciesId,
    required DateTime birthDate,
    int? roomId,
    String? ringNumber,
    String gender = '未知',
    String? notes,
  }) async {
    final maxRow = await (selectOnly(birds)
          ..addColumns([birds.sortOrder.max()]))
        .map((row) => row.read(birds.sortOrder.max()))
        .getSingle();
    await into(birds).insert(BirdsCompanion.insert(
      name: name,
      speciesId: speciesId,
      birthDate: birthDate,
      roomId: Value(roomId),
      ringNumber: Value(ringNumber),
      gender: Value(gender),
      notes: Value(notes),
      sortOrder: Value((maxRow ?? 0) + 1),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getBirdById(rows.first.read<int>('id')))!;
  }

  Future<Bird> updateBird(int id, {
    String? name, int? speciesId, int? roomId, DateTime? birthDate,
    String? gender, int? sortOrder, String? status, String? notes,
    String? ringNumber,
  }) async {
    final list = await (update(birds)..where((t) => t.id.equals(id)))
        .writeReturning(BirdsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      speciesId: speciesId != null ? Value(speciesId) : const Value.absent(),
      roomId: roomId != null ? Value(roomId) : const Value.absent(),
      birthDate: birthDate != null ? Value(birthDate) : const Value.absent(),
      gender: gender != null ? Value(gender) : const Value.absent(),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      ringNumber: ringNumber != null ? Value(ringNumber) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
    return list.first;
  }

  Future<void> updateSortOrders(Map<int, int> birdIdToOrder) => batch((b) {
        for (final entry in birdIdToOrder.entries) {
          b.update(
            birds,
            BirdsCompanion(sortOrder: Value(entry.value)),
            where: (t) => t.id.equals(entry.key),
          );
        }
      });

  Future<void> removeBird(int id) =>
      (delete(birds)..where((t) => t.id.equals(id))).go();

  Future<List<BirdWithDetails>> getByRoom(int roomId) async {
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
    ])
      ..where(birds.roomId.equals(roomId))
      ..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows.map((row) => BirdWithDetails(
          bird: row.readTable(birds),
          species: row.readTable(species),
          room: null,
        )).toList();
  }

  Future<List<BirdWithDetails>> search(String query) async {
    final q = '%$query%';
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
    ])
      ..where(birds.name.like(q) | birds.ringNumber.like(q))
      ..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows.map((row) => BirdWithDetails(
          bird: row.readTable(birds),
          species: row.readTable(species),
          room: row.readTableOrNull(rooms),
        )).toList();
  }
}

class BirdWithDetails {
  final Bird bird;
  final Specy species;
  final Room? room;

  BirdWithDetails({required this.bird, required this.species, this.room});

  int get ageDays => DateTime.now().difference(bird.birthDate).inDays;

  String get growthStage {
    if (ageDays <= species.nestlingEndDays) return '雏鸟';
    if (ageDays <= species.juvenileEndDays) return '幼鸟';
    return '成鸟';
  }
}
