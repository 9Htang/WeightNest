import 'package:drift/drift.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

extension WeightRepository on AppDatabase {
  Future<List<Weight>> getByBird(int birdId) =>
      (select(weights)
            ..where((t) => t.birdId.equals(birdId))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .get();

  /// 按日期范围获取某鸟的体重记录（时间升序）
  Future<List<Weight>> getByBirdInRange(
    int birdId, {
    required DateTime from,
    required DateTime to,
  }) =>
      (select(weights)
            ..where((t) =>
                t.birdId.equals(birdId) &
                t.recordedAt.isBiggerOrEqualValue(from) &
                t.recordedAt.isSmallerOrEqualValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
          .get();

  Future<List<Weight>> getRecentByBird(int birdId, {int limit = 10}) =>
      (select(weights)
            ..where((t) => t.birdId.equals(birdId))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(limit))
          .get();

  Future<Weight> addWeight({
    required int birdId,
    required double weightG,
    required DateTime recordedAt,
    int? recordedBy,
    bool isFasting = false,
    String? notes,
  }) async {
    // 同一分钟内的记录自动覆盖
    final minuteStart = DateTime(
        recordedAt.year, recordedAt.month, recordedAt.day,
        recordedAt.hour, recordedAt.minute);
    final minuteEnd = minuteStart.add(const Duration(minutes: 1));

    final existing = await (select(weights)
          ..where((t) =>
              t.birdId.equals(birdId) &
              t.recordedAt.isBiggerOrEqualValue(minuteStart) &
              t.recordedAt.isSmallerThanValue(minuteEnd)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(weights)..where((t) => t.id.equals(existing.id))).write(
        WeightsCompanion(
          weightG: Value(weightG),
          recordedAt: Value(recordedAt),
          recordedBy: recordedBy != null ? Value(recordedBy) : const Value.absent(),
          isFasting: Value(isFasting),
          notes: notes != null ? Value(notes) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await (select(weights)..where((w) => w.id.equals(existing.id)))
          .getSingle())!;
    } else {
      await into(weights).insert(WeightsCompanion.insert(
        uuid: genUuid(),
        birdId: birdId,
        weightG: weightG,
        recordedAt: recordedAt,
        isFasting: Value(isFasting),
        recordedBy: Value(recordedBy),
        notes: Value(notes),
      ));
      final rows = await customSelect('SELECT last_insert_rowid() as id').get();
      return (await (select(weights)
            ..where((w) => w.id.equals(rows.first.read<int>('id'))))
          .getSingle())!;
    }
  }

  Future<Weight?> getLatestByBird(int birdId) =>
      (select(weights)
            ..where((t) => t.birdId.equals(birdId))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<Map<int, Weight?>> getLatestByBirds(List<int> birdIds) async {
    if (birdIds.isEmpty) return {};
    final result = <int, Weight?>{};
    for (final id in birdIds) {
      result[id] = await getLatestByBird(id);
    }
    return result;
  }

  Future<void> removeWeight(int id) =>
      (delete(weights)..where((w) => w.id.equals(id))).go();
}
