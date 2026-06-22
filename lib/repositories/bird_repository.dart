import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/app_clock.dart';
import '../core/plugin_registry.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

extension BirdRepository on AppDatabase {
  Future<List<BirdWithDetails>> getAllWithDetails() async {
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
    ])..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows.map((row) => BirdWithDetails(
          bird: row.readTable(birds),
          species: row.readTable(species),
          room: row.readTableOrNull(rooms),
          enclosure: row.readTableOrNull(enclosures),
        )).toList();
  }

  Future<Bird?> getBirdById(int id) =>
      (select(birds)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get a single bird with its species, room, and enclosure.
  Future<BirdWithDetails?> getWithDetails(int birdId) async {
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
    ])
      ..where(birds.id.equals(birdId))
      ..limit(1)).get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return BirdWithDetails(
      bird: row.readTable(birds),
      species: row.readTable(species),
      room: row.readTableOrNull(rooms),
      enclosure: row.readTableOrNull(enclosures),
    );
  }

  Future<Bird?> getBirdByUuid(String uuid) =>
      (select(birds)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  /// 按名字 + 出生日期查重（用于同步去重）
  Future<Bird?> getBirdByNameAndBirth(String name, DateTime birthDate) {
    final start = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final end = start.add(const Duration(days: 1));
    return (select(birds)
      ..where((t) => t.name.equals(name) & t.birthDate.isBiggerOrEqualValue(start) & t.birthDate.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  Future<Bird> createBird({
    required String name,
    required int speciesId,
    required DateTime birthDate,
    int? roomId,
    int? enclosureId,
    String? ringNumber,
    String gender = '未知',
    String? notes,
    String? uuid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final maxRow = await (selectOnly(birds)
          ..addColumns([birds.sortOrder.max()]))
        .map((row) => row.read(birds.sortOrder.max()))
        .getSingle();
    final bird = await into(birds).insertReturning(BirdsCompanion.insert(
      uuid: uuid ?? genUuid(),
      name: name,
      speciesId: speciesId,
      birthDate: birthDate,
      roomId: Value(roomId),
      enclosureId: Value(enclosureId),
      ringNumber: Value(ringNumber),
      gender: Value(gender),
      notes: Value(notes),
      sortOrder: Value((maxRow ?? 0) + 1),
      createdAt: Value(createdAt ?? AppClock.now),
      updatedAt: Value(updatedAt ?? AppClock.now),
    ));

    // 记录创建操作（fire-and-forget，不影响主流程返回速度）
    pluginRegistry.operationService.record(
      pluginId: 'core',
      actionType: 'bird_created',
      birdId: bird.id,
      summary: '创建新鸟: $name',
      details: {'name': name, 'speciesId': speciesId},
    );

    return bird;
  }

  Future<Bird> updateBird(int id, {
    String? name, int? speciesId, int? roomId, DateTime? birthDate,
    String? gender, int? sortOrder, String? status, String? notes,
    String? ringNumber, int? weighIntervalDays, int? enclosureId,
    double? manualBaselineG, bool? weaningOverride,
  }) async {
    final list = await (update(birds)..where((t) => t.id.equals(id)))
        .writeReturning(BirdsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      speciesId: speciesId != null ? Value(speciesId) : const Value.absent(),
      roomId: Value(roomId),
      birthDate: birthDate != null ? Value(birthDate) : const Value.absent(),
      gender: gender != null ? Value(gender) : const Value.absent(),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      ringNumber: ringNumber != null ? Value(ringNumber) : const Value.absent(),
      weighIntervalDays: weighIntervalDays != null ? Value(weighIntervalDays) : const Value.absent(),
      enclosureId: Value(enclosureId),
      manualBaselineG: Value(manualBaselineG),
      weaningOverride: Value(weaningOverride),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  Future<void> updateBirdUuid(int id, String uuid) async {
    await (update(birds)..where((t) => t.id.equals(id)))
        .write(BirdsCompanion(uuid: Value(uuid)));
  }

  /// 单独设置鸟的容器（支持设为 null 以移出容器）
  Future<void> setBirdEnclosure(int birdId, int? enclosureId) async {
    await (update(birds)..where((t) => t.id.equals(birdId)))
        .write(BirdsCompanion(enclosureId: Value(enclosureId), updatedAt: Value(AppClock.now)));
  }

  Future<void> updateWeighInterval(int birdId, int? days) async {
    await (update(birds)..where((t) => t.id.equals(birdId)))
        .write(BirdsCompanion(weighIntervalDays: Value(days), updatedAt: Value(AppClock.now)));
  }

  Future<void> updateSortOrders(Map<int, int> birdIdToOrder) => batch((b) {
        for (final entry in birdIdToOrder.entries) {
          b.update(
            birds,
            BirdsCompanion(sortOrder: Value(entry.value), updatedAt: Value(AppClock.now)),
            where: (t) => t.id.equals(entry.key),
          );
        }
      });

  Future<int> getBirdCountBySpecies(int speciesId) async {
    final list = await (select(birds)..where((t) => t.speciesId.equals(speciesId))).get();
    return list.length;
  }

  Future<int> getBirdCountByRoom(int roomId) async {
    final list = await (select(birds)..where((t) => t.roomId.equals(roomId))).get();
    return list.length;
  }

  Future<void> removeBird(int id) =>
      (delete(birds)..where((t) => t.id.equals(id))).go();

  Future<List<BirdWithDetails>> getByEnclosure(int enclosureId) async {
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
    ])
      ..where(birds.enclosureId.equals(enclosureId))
      ..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows
        .map((row) => BirdWithDetails(
              bird: row.readTable(birds),
              species: row.readTable(species),
              room: row.readTableOrNull(rooms),
              enclosure: row.readTableOrNull(enclosures),
            ))
        .toList();
  }

  Future<List<BirdWithDetails>> getByRoom(int roomId) async {
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
    ])
      ..where(birds.roomId.equals(roomId))
      ..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows.map((row) => BirdWithDetails(
          bird: row.readTable(birds),
          species: row.readTable(species),
          room: row.readTableOrNull(rooms),
          enclosure: row.readTableOrNull(enclosures),
        )).toList();
  }

  Future<List<BirdWithDetails>> search(String query) async {
    final q = '%$query%';
    final rows = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
      leftOuterJoin(rooms, rooms.id.equalsExp(birds.roomId)),
      leftOuterJoin(enclosures, enclosures.id.equalsExp(birds.enclosureId)),
    ])
      ..where(birds.name.like(q) | birds.ringNumber.like(q))
      ..orderBy([OrderingTerm.asc(birds.sortOrder)])).get();
    return rows.map((row) => BirdWithDetails(
          bird: row.readTable(birds),
          species: row.readTable(species),
          room: row.readTableOrNull(rooms),
          enclosure: row.readTableOrNull(enclosures),
        )).toList();
  }
}

class BirdWithDetails {
  final Bird bird;
  final Specy species;
  final Room? room;
  final Enclosure? enclosure;

  BirdWithDetails({required this.bird, required this.species, this.room, this.enclosure});

  int get ageDays {
    final days = AppClock.now.difference(bird.birthDate).inDays;
    if (days < 0) {
      debugPrint('[BirdWithDetails] ${bird.name}: birthDate is in the future, ageDays=$days — clamping to 0');
      return 0;
    }
    return days;
  }

  String get growthStage {
    if (ageDays <= species.nestlingEndDays) return '雏鸟';
    if (ageDays <= species.juvenileEndDays) return '幼鸟';
    return '成鸟';
  }

  /// 有效称重间隔：鸟级覆盖 > 物种阶段默认
  int get effectiveWeighIntervalDays => computeEffectiveWeighInterval(
        birdOverrideDays: bird.weighIntervalDays,
        species: species,
        ageDays: ageDays,
      );
}

/// 计算有效称重间隔（天）：鸟级覆盖优先，否则按生长阶段取物种默认。
///
/// 供 [AlertService] 和 [TaskRepository.generateTodayTasks] 共用，确保
/// 告警系统和任务系统对同一只鸟使用相同间隔值。
int computeEffectiveWeighInterval({
  required int? birdOverrideDays,
  required Specy species,
  required int ageDays,
}) {
  if (birdOverrideDays != null) return birdOverrideDays;
  if (ageDays <= species.nestlingEndDays) return species.nestlingWeighIntervalDays;
  if (ageDays <= species.juvenileEndDays) return species.juvenileWeighIntervalDays;
  return species.adultWeighIntervalDays;
}
