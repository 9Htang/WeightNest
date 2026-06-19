import 'package:drift/drift.dart';
import '../../database/database.dart';
import '../../core/plugin_registry.dart';
import '../../utils/uuid.dart';

extension BreedingRepository on AppDatabase {
  // ── 配对 ──

  /// Create a pair. Validates that neither bird is already in an active pair.
  Future<BreedingPair> createPair({
    required int maleBirdId,
    required int femaleBirdId,
    String? pairName,
    String? notes,
  }) async {
    final existingMale = await getActivePairForBird(maleBirdId);
    if (existingMale != null) {
      throw StateError('公鸟已处于活跃配对中');
    }
    final existingFemale = await getActivePairForBird(femaleBirdId);
    if (existingFemale != null) {
      throw StateError('母鸟已处于活跃配对中');
    }

    return into(breedingPairs).insertReturning(
      BreedingPairsCompanion.insert(
        uuid: genUuid(),
        maleBirdId: maleBirdId,
        femaleBirdId: femaleBirdId,
        pairName: Value(pairName),
        notes: Value(notes),
      ),
    );
  }

  /// Separate a pair (status -> 'separated', separatedDate -> now)
  Future<void> separatePair(int pairId) async {
    await (update(breedingPairs)..where((t) => t.id.equals(pairId)))
        .write(BreedingPairsCompanion(
      status: const Value('separated'),
      separatedDate: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Get all active pairs with male/female bird info (batch-loads birds)
  Future<List<({BreedingPair pair, Bird male, Bird female})>> getActivePairs() async {
    final pairs = await (select(breedingPairs)
      ..where((t) => t.status.equals('active'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

    if (pairs.isEmpty) return [];

    final birdIds = <int>{};
    for (final p in pairs) {
      birdIds.add(p.maleBirdId);
      birdIds.add(p.femaleBirdId);
    }

    final birdList = await (select(birds)..where((t) => t.id.isIn(birdIds))).get();
    final birdById = {for (final b in birdList) b.id: b};

    return [
      for (final p in pairs)
        (pair: p, male: birdById[p.maleBirdId]!, female: birdById[p.femaleBirdId]!),
    ];
  }

  /// Get the active pair for a bird, if any
  Future<BreedingPair?> getActivePairForBird(int birdId) async {
    return (select(breedingPairs)
          ..where((t) =>
              (t.maleBirdId.equals(birdId) | t.femaleBirdId.equals(birdId)) &
              t.status.equals('active')))
        .getSingleOrNull();
  }

  /// Get a pair by its ID
  Future<BreedingPair?> getPairById(int id) =>
      (select(breedingPairs)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── 繁育记录 ──

  /// Start a breeding record for a pair. Validates no active record exists for this pair.
  Future<BreedingRecord> createBreedingRecord(int pairId) async {
    final existing = await getActiveRecordForPair(pairId);
    if (existing != null) {
      throw StateError('该配对已有进行中的繁育记录');
    }

    final record = await into(breedingRecords).insertReturning(
      BreedingRecordsCompanion.insert(
        uuid: genUuid(),
        pairId: pairId,
      ),
    );

    // 记录统一操作日志
    final pair = await getPairById(pairId);
    if (pair != null) {
      await pluginRegistry.operationService.record(
        pluginId: 'breeding',
        actionType: 'breeding_started',
        summary: '开始繁育记录',
        details: {
          'pairId': pairId,
          'maleBirdId': pair.maleBirdId,
          'femaleBirdId': pair.femaleBirdId,
          'recordId': record.id,
        },
      );
    }

    return record;
  }

  /// Advance to next stage: 配对->产蛋->孵化->育雏->完结
  Future<void> advanceStage(int recordId) async {
    final record = await (select(breedingRecords)..where((t) => t.id.equals(recordId)))
        .getSingleOrNull();
    if (record == null) throw StateError('繁育记录不存在');

    const stages = ['配对', '产蛋', '孵化', '育雏', '已完结'];
    final currentIndex = stages.indexOf(record.stage);
    if (currentIndex < 0 || currentIndex >= stages.length - 1) {
      throw StateError('繁育记录已完结或处于未知阶段');
    }

    final fromStage = record.stage;
    final nextStage = stages[currentIndex + 1];
    final now = DateTime.now();
    await (update(breedingRecords)..where((t) => t.id.equals(recordId)))
        .write(BreedingRecordsCompanion(
      stage: Value(nextStage),
      endDate: nextStage == '已完结' ? Value(now) : const Value.absent(),
      updatedAt: Value(now),
    ));

    // 记录统一操作日志
    final pair = await getPairById(record.pairId);
    if (pair != null) {
      await pluginRegistry.operationService.record(
        pluginId: 'breeding',
        actionType: 'breeding_stage_advanced',
        summary: '繁育阶段: $fromStage → $nextStage',
        details: {
          'pairId': record.pairId,
          'maleBirdId': pair.maleBirdId,
          'femaleBirdId': pair.femaleBirdId,
          'recordId': recordId,
          'fromStage': fromStage,
          'toStage': nextStage,
        },
      );
    }
  }

  /// Force-finish breeding at any stage with a reason
  Future<void> finishBreeding(int recordId, {String? reason}) async {
    final record = await (select(breedingRecords)..where((t) => t.id.equals(recordId)))
        .getSingleOrNull();
    if (record == null) return;

    final now = DateTime.now();
    await (update(breedingRecords)..where((t) => t.id.equals(recordId)))
        .write(BreedingRecordsCompanion(
      stage: const Value('已完结'),
      endDate: Value(now),
      endReason: Value(reason),
      updatedAt: Value(now),
    ));

    // 记录统一操作日志
    final pair = await getPairById(record.pairId);
    if (pair != null) {
      await pluginRegistry.operationService.record(
        pluginId: 'breeding',
        actionType: 'breeding_finished',
        summary: '繁育结束${reason != null ? ": $reason" : ""}',
        details: {
          'pairId': record.pairId,
          'maleBirdId': pair.maleBirdId,
          'femaleBirdId': pair.femaleBirdId,
          'recordId': recordId,
          'fromStage': record.stage,
          'reason': reason,
        },
      );
    }
  }

  /// Get the active (non-completed) breeding record for a pair
  Future<BreedingRecord?> getActiveRecordForPair(int pairId) async {
    final records = await (select(breedingRecords)
          ..where((t) => t.pairId.equals(pairId)))
        .get();
    for (final r in records) {
      if (r.stage != '已完结') return r;
    }
    return null;
  }

  /// Get the active breeding record for any bird in an active pair
  Future<(BreedingRecord, BreedingPair, Bird male, Bird female)?> getActiveRecordForBird(int birdId) async {
    final pair = await getActivePairForBird(birdId);
    if (pair == null) return null;

    final record = await getActiveRecordForPair(pair.id);
    if (record == null) return null;

    final male = await (select(birds)..where((t) => t.id.equals(pair.maleBirdId))).getSingle();
    final female = await (select(birds)..where((t) => t.id.equals(pair.femaleBirdId))).getSingle();

    return (record, pair, male, female);
  }

  // ── 蛋 ──

  Future<Egg> addEgg(int breedingRecordId, {DateTime? laidDate}) async {
    final egg = await into(eggs).insertReturning(
      EggsCompanion.insert(
        uuid: genUuid(),
        breedingRecordId: breedingRecordId,
        laidDate: laidDate ?? DateTime.now(),
      ),
    );

    // 记录统一操作日志
    final record = await (select(breedingRecords)..where((t) => t.id.equals(breedingRecordId)))
        .getSingleOrNull();
    if (record != null) {
      final pair = await getPairById(record.pairId);
      if (pair != null) {
        await pluginRegistry.operationService.record(
          pluginId: 'breeding',
          actionType: 'egg_laid',
          summary: '产蛋记录',
          details: {
            'pairId': record.pairId,
            'maleBirdId': pair.maleBirdId,
            'femaleBirdId': pair.femaleBirdId,
            'recordId': breedingRecordId,
            'eggId': egg.id,
            'laidDate': egg.laidDate.toIso8601String(),
          },
        );
      }
    }

    return egg;
  }

  Future<List<Egg>> getEggsByRecord(int breedingRecordId) async {
    return (select(eggs)
          ..where((t) => t.breedingRecordId.equals(breedingRecordId))
          ..orderBy([(t) => OrderingTerm.desc(t.laidDate)]))
        .get();
  }

  Future<void> updateEggStatus(int eggId, String status, {DateTime? hatchDate, int? chickBirdId}) async {
    await (update(eggs)..where((t) => t.id.equals(eggId)))
        .write(EggsCompanion(
      status: Value(status),
      hatchDate: Value(hatchDate),
      chickBirdId: Value(chickBirdId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── 踩背 ──

  Future<MatingEvent> addMatingEvent(int breedingRecordId, {DateTime? observedDate, String? notes}) async {
    final event = await into(matingEvents).insertReturning(
      MatingEventsCompanion.insert(
        uuid: genUuid(),
        breedingRecordId: breedingRecordId,
        observedDate: observedDate ?? DateTime.now(),
        notes: Value(notes),
      ),
    );

    // 记录统一操作日志
    final record = await (select(breedingRecords)..where((t) => t.id.equals(breedingRecordId)))
        .getSingleOrNull();
    if (record != null) {
      final pair = await getPairById(record.pairId);
      if (pair != null) {
        await pluginRegistry.operationService.record(
          pluginId: 'breeding',
          actionType: 'mating_observed',
          summary: '踩背观察${notes != null ? ": $notes" : ""}',
          details: {
            'pairId': record.pairId,
            'maleBirdId': pair.maleBirdId,
            'femaleBirdId': pair.femaleBirdId,
            'recordId': breedingRecordId,
            'matingEventId': event.id,
            'observedDate': event.observedDate.toIso8601String(),
          },
        );
      }
    }

    return event;
  }

  Future<List<MatingEvent>> getMatingEventsByRecord(int breedingRecordId) async {
    return (select(matingEvents)
          ..where((t) => t.breedingRecordId.equals(breedingRecordId))
          ..orderBy([(t) => OrderingTerm.desc(t.observedDate)]))
        .get();
  }

  // ── 跨插件查询 ──

  /// Returns set of bird IDs currently in breeding (both male and female of active records)
  Future<Set<int>> getActiveBreedingBirdIds() async {
    final rows = await (select(breedingRecords).join([
      innerJoin(breedingPairs, breedingPairs.id.equalsExp(breedingRecords.pairId)),
    ])).get();
    final activeRecords = rows.where((r) => r.readTable(breedingRecords).stage != '已完结');

    final ids = <int>{};
    for (final r in activeRecords) {
      final pair = r.readTable(breedingPairs);
      ids.add(pair.maleBirdId);
      ids.add(pair.femaleBirdId);
    }
    return ids;
  }

  /// True if this bird is in an active pair with a non-completed breeding record
  Future<bool> isBreeding(int birdId) async {
    final pair = await getActivePairForBird(birdId);
    if (pair == null) return false;

    final record = await getActiveRecordForPair(pair.id);
    return record != null;
  }

}
