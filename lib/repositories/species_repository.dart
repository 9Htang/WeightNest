import 'package:drift/drift.dart';
import '../core/app_clock.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

extension SpeciesRepository on AppDatabase {
  Future<List<Specy>> getAllSpecies() =>
      (select(species)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Specy?> getSpeciesById(int id) =>
      (select(species)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Specy?> getSpeciesByName(String name) =>
      (select(species)..where((t) => t.name.equals(name))).getSingleOrNull();

  /// Safe variant: returns first match even when duplicates exist.
  Future<Specy?> getSpeciesByNameSafe(String name) async {
    final list = await (select(species)
          ..where((t) => t.name.equals(name))
          ..limit(1))
        .get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<Specy?> getSpeciesByUuid(String uuid) =>
      (select(species)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  /// Update only the UUID for matching a local species to server record.
  Future<void> updateSpeciesUuid(int id, String uuid) async {
    await (update(species)..where((t) => t.id.equals(id)))
        .write(SpeciesCompanion(uuid: Value(uuid)));
  }

  /// Upsert by UUID: returns created or updated species
  Future<Specy> upsertByUuid(
    String uuid, {
    required String name,
    int nestlingEndDays = 45,
    int juvenileEndDays = 120,
    int nestlingWeighIntervalDays = 1,
    int juvenileWeighIntervalDays = 3,
    int adultWeighIntervalDays = 7,
    double? minWeightG,
    double? maxWeightG,
  }) async {
    final existing = await getSpeciesByUuid(uuid);
    if (existing != null) {
      return updateSpecies(
        existing.id,
        name: name,
        nestlingEndDays: nestlingEndDays,
        juvenileEndDays: juvenileEndDays,
        nestlingWeighIntervalDays: nestlingWeighIntervalDays,
        juvenileWeighIntervalDays: juvenileWeighIntervalDays,
        adultWeighIntervalDays: adultWeighIntervalDays,
        minWeightG: minWeightG,
        maxWeightG: maxWeightG,
      );
    }
    final id = await into(species).insert(SpeciesCompanion.insert(
      uuid: uuid,
      name: name,
      nestlingEndDays: Value(nestlingEndDays),
      juvenileEndDays: Value(juvenileEndDays),
      nestlingWeighIntervalDays: Value(nestlingWeighIntervalDays),
      juvenileWeighIntervalDays: Value(juvenileWeighIntervalDays),
      adultWeighIntervalDays: Value(adultWeighIntervalDays),
      minWeightG: Value(minWeightG),
      maxWeightG: Value(maxWeightG),
      createdAt: Value(AppClock.now),
      updatedAt: Value(AppClock.now),
    ));
    return (await getSpeciesById(id))!;
  }

  Future<Specy> createSpecies(String name,
      {int nestlingEndDays = 45,
      int juvenileEndDays = 120,
      int nestlingWeighIntervalDays = 1,
      int juvenileWeighIntervalDays = 3,
      int adultWeighIntervalDays = 7,
      double? minWeightG,
      double? maxWeightG,
      String? uuid,
      DateTime? createdAt,
      DateTime? updatedAt}) async {
    await into(species).insert(SpeciesCompanion.insert(
      uuid: uuid ?? genUuid(),
      name: name,
      nestlingEndDays: Value(nestlingEndDays),
      juvenileEndDays: Value(juvenileEndDays),
      nestlingWeighIntervalDays: Value(nestlingWeighIntervalDays),
      juvenileWeighIntervalDays: Value(juvenileWeighIntervalDays),
      adultWeighIntervalDays: Value(adultWeighIntervalDays),
      minWeightG: Value(minWeightG),
      maxWeightG: Value(maxWeightG),
      createdAt: Value(createdAt ?? AppClock.now),
      updatedAt: Value(updatedAt ?? AppClock.now),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getSpeciesById(rows.first.read<int>('id')))!;
  }

  Future<Specy> updateSpecies(int id,
      {String? name,
      int? nestlingEndDays,
      int? juvenileEndDays,
      int? nestlingWeighIntervalDays,
      int? juvenileWeighIntervalDays,
      int? adultWeighIntervalDays,
      double? minWeightG,
      double? maxWeightG}) async {
    final list = await (update(species)..where((t) => t.id.equals(id)))
        .writeReturning(SpeciesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      nestlingEndDays: nestlingEndDays != null
          ? Value(nestlingEndDays)
          : const Value.absent(),
      juvenileEndDays: juvenileEndDays != null
          ? Value(juvenileEndDays)
          : const Value.absent(),
      nestlingWeighIntervalDays: nestlingWeighIntervalDays != null
          ? Value(nestlingWeighIntervalDays)
          : const Value.absent(),
      juvenileWeighIntervalDays: juvenileWeighIntervalDays != null
          ? Value(juvenileWeighIntervalDays)
          : const Value.absent(),
      adultWeighIntervalDays: adultWeighIntervalDays != null
          ? Value(adultWeighIntervalDays)
          : const Value.absent(),
      minWeightG: minWeightG != null ? Value(minWeightG) : const Value.absent(),
      maxWeightG: maxWeightG != null ? Value(maxWeightG) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  Future<void> removeSpecies(int id) =>
      (delete(species)..where((t) => t.id.equals(id))).go();
}
