import 'package:drift/drift.dart';
import '../database/database.dart';

extension SpeciesRepository on AppDatabase {
  Future<List<Specy>> getAllSpecies() =>
      (select(species)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Specy?> getSpeciesById(int id) =>
      (select(species)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Specy> createSpecies(String name,
      {int nestlingEndDays = 45,
      int juvenileEndDays = 120,
      int adultWeighIntervalDays = 7}) async {
    await into(species).insert(SpeciesCompanion.insert(
      name: name,
      nestlingEndDays: Value(nestlingEndDays),
      juvenileEndDays: Value(juvenileEndDays),
      adultWeighIntervalDays: Value(adultWeighIntervalDays),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getSpeciesById(rows.first.read<int>('id')))!;
  }

  Future<Specy> updateSpecies(int id,
      {String? name,
      int? nestlingEndDays,
      int? juvenileEndDays,
      int? adultWeighIntervalDays}) async {
    final list = await (update(species)..where((t) => t.id.equals(id)))
        .writeReturning(SpeciesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      nestlingEndDays: nestlingEndDays != null
          ? Value(nestlingEndDays)
          : const Value.absent(),
      juvenileEndDays: juvenileEndDays != null
          ? Value(juvenileEndDays)
          : const Value.absent(),
      adultWeighIntervalDays: adultWeighIntervalDays != null
          ? Value(adultWeighIntervalDays)
          : const Value.absent(),
    ));
    return list.first;
  }

  Future<void> removeSpecies(int id) =>
      (delete(species)..where((t) => t.id.equals(id))).go();
}
