import 'package:drift/drift.dart';
import '../core/app_clock.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

class EnclosureWithCount {
  final Enclosure enclosure;
  final int birdCount;

  const EnclosureWithCount({required this.enclosure, required this.birdCount});
}

extension EnclosureRepository on AppDatabase {
  Future<List<Enclosure>> getEnclosuresByRoom(int roomId) => (select(enclosures)
        ..where((t) => t.roomId.equals(roomId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  Future<Enclosure?> getEnclosureById(int id) =>
      (select(enclosures)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> getBirdCountByEnclosure(int enclosureId) async {
    final count = await (selectOnly(birds)
          ..addColumns([birds.id.count()])
          ..where(birds.enclosureId.equals(enclosureId)))
        .map((row) => row.read(birds.id.count()) ?? 0)
        .getSingle();
    return count;
  }

  Future<EnclosureWithCount> getEnclosureWithCount(int enclosureId) async {
    final enclosure = (await getEnclosureById(enclosureId))!;
    final count = await getBirdCountByEnclosure(enclosureId);
    return EnclosureWithCount(enclosure: enclosure, birdCount: count);
  }

  Future<List<EnclosureWithCount>> getByRoomWithCounts(int roomId) async {
    // 单条 JOIN SQL：一次查询拿到该房间所有容器及其鸟数，
    // 替代旧实现里"先查容器列表，再逐容器 getBirdCountByEnclosure"的 N+1。
    // 与 [getAllEnclosureCounts] 共用同一查询写法，仅多了 room_id 过滤。
    final rows = await customSelect(
      'SELECT e.*, COUNT(b.id) as bird_count '
      'FROM enclosures e '
      'LEFT JOIN birds b ON b.enclosure_id = e.id AND b.deleted_at IS NULL '
      'WHERE e.deleted_at IS NULL AND e.room_id = ? '
      'GROUP BY e.id '
      'ORDER BY e.sort_order',
      variables: [Variable.withInt(roomId)],
    ).get();

    return rows
        .map((row) => EnclosureWithCount(
              enclosure: Enclosure(
                id: row.read<int>('id'),
                uuid: row.read<String>('uuid'),
                name: row.read<String>('name'),
                roomId: row.read<int>('room_id'),
                sortOrder: row.read<int>('sort_order'),
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    row.read<int>('created_at') * 1000),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    row.read<int>('updated_at') * 1000),
                deletedAt: row.read<int?>('deleted_at') != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        row.read<int>('deleted_at') * 1000)
                    : null,
              ),
              birdCount: row.read<int>('bird_count'),
            ))
        .toList();
  }

  /// 批量查询所有容器的鸟数（单条 SQL，避免 N+1）
  /// 返回 `Map<roomId, List<EnclosureWithCount>>`
  Future<Map<int, List<EnclosureWithCount>>> getAllEnclosureCounts() async {
    final rows = await customSelect(
      'SELECT e.*, COUNT(b.id) as bird_count '
      'FROM enclosures e '
      'LEFT JOIN birds b ON b.enclosure_id = e.id AND b.deleted_at IS NULL '
      'WHERE e.deleted_at IS NULL '
      'GROUP BY e.id '
      'ORDER BY e.room_id, e.sort_order',
    ).get();

    final result = <int, List<EnclosureWithCount>>{};
    for (final row in rows) {
      final enclosure = Enclosure(
        id: row.read<int>('id'),
        uuid: row.read<String>('uuid'),
        name: row.read<String>('name'),
        roomId: row.read<int>('room_id'),
        sortOrder: row.read<int>('sort_order'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('created_at') * 1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('updated_at') * 1000),
        deletedAt: row.read<int?>('deleted_at') != null
            ? DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('deleted_at') * 1000)
            : null,
      );
      result.putIfAbsent(enclosure.roomId, () => []).add(
            EnclosureWithCount(
                enclosure: enclosure, birdCount: row.read<int>('bird_count')),
          );
    }
    return result;
  }

  Future<Enclosure> createEnclosure(String name, int roomId,
      {DateTime? createdAt, DateTime? updatedAt}) async {
    final maxRow = await (selectOnly(enclosures)
          ..addColumns([enclosures.sortOrder.max()]))
        .map((row) => row.read(enclosures.sortOrder.max()))
        .getSingle();
    await into(enclosures).insert(EnclosuresCompanion.insert(
      uuid: genUuid(),
      name: name,
      roomId: roomId,
      sortOrder: Value((maxRow ?? 0) + 1),
      createdAt: Value(createdAt ?? AppClock.now),
      updatedAt: Value(updatedAt ?? AppClock.now),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getEnclosureById(rows.first.read<int>('id')))!;
  }

  Future<Enclosure> updateEnclosure(int id,
      {String? name, int? sortOrder}) async {
    final list = await (update(enclosures)..where((t) => t.id.equals(id)))
        .writeReturning(EnclosuresCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  Future<void> updateEnclosureSortOrders(Map<int, int> enclosureIdToOrder) =>
      batch((b) {
        for (final entry in enclosureIdToOrder.entries) {
          b.update(
            enclosures,
            EnclosuresCompanion(
                sortOrder: Value(entry.value), updatedAt: Value(AppClock.now)),
            where: (t) => t.id.equals(entry.key),
          );
        }
      });

  Future<void> removeEnclosure(int id) =>
      (delete(enclosures)..where((t) => t.id.equals(id))).go();
}
