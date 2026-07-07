import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import '../../core/plugin_registry.dart';
import '../../repositories/bird_repository.dart';
import '../../utils/uuid.dart';
import '../stage/stage_constants.dart';

extension BreedingRepository on AppDatabase {
  // ── 内部工具 ──

  /// 通知 stage 插件更新两只鸟的生理阶段为繁殖阶段。
  /// 根据繁殖记录阶段映射到 [RecipeStage]：
  ///   配对 → 繁殖准备期, 产蛋/孵化 → 产蛋孵化期, 育雏 → 育雏期
  /// 完结时清除繁殖阶段（回退到年龄推断）。
  Future<void> _notifyStagePlugin({
    required int maleBirdId,
    required int femaleBirdId,
    required String breedingStage,
  }) async {
    try {
      if (breedingStage == '已完结') {
        // 完结：清除繁殖阶段，回退到年龄推断
        await pluginRegistry.call('stage', 'clearStage', maleBirdId);
        await pluginRegistry.call('stage', 'clearStage', femaleBirdId);
        await pluginRegistry.call('stage', 'recompute', maleBirdId);
        await pluginRegistry.call('stage', 'recompute', femaleBirdId);
        return;
      }

      final recipeStage = switch (breedingStage) {
        '配对' => RecipeStage.preBreeding,
        '产蛋' || '孵化' => RecipeStage.eggLaying,
        '育雏' => RecipeStage.chickRearing,
        _ => RecipeStage.preBreeding,
      };

      await pluginRegistry.call('stage', 'setStages', <int, String>{
        maleBirdId: recipeStage,
        femaleBirdId: recipeStage,
      });
    } catch (e) {
      // 通知失败不影响繁殖记录保存（最终一致性）
      debugPrint('[BreedingRepository] 通知 stage 插件失败: $e');
    }
  }

  /// Record a breeding operation in the activity log for BOTH male and female birds.
  /// Returns immediately; errors are fire-and-forget (logged but not thrown).
  Future<void> _recordBreedingOp({
    required int maleBirdId,
    required int femaleBirdId,
    required String actionType,
    required String summary,
    Map<String, dynamic>? details,
  }) async {
    try {
      await pluginRegistry.operationService.record(
        pluginId: 'breeding',
        actionType: actionType,
        birdId: maleBirdId,
        summary: summary,
        details: details,
      );
    } catch (_) {}
    try {
      await pluginRegistry.operationService.record(
        pluginId: 'breeding',
        actionType: actionType,
        birdId: femaleBirdId,
        summary: summary,
        details: details,
      );
    } catch (_) {}
  }

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

    final pair = await into(breedingPairs).insertReturning(
      BreedingPairsCompanion.insert(
        uuid: genUuid(),
        maleBirdId: maleBirdId,
        femaleBirdId: femaleBirdId,
        pairName: Value(pairName),
        notes: Value(notes),
        createdAt: Value(AppClock.now),
        updatedAt: Value(AppClock.now),
      ),
    );

    // Record operation for both birds
    await _recordBreedingOp(
      maleBirdId: maleBirdId,
      femaleBirdId: femaleBirdId,
      actionType: 'pair_created',
      summary: '创建配对${pairName != null ? ": $pairName" : ""}',
      details: {'pairId': pair.id, 'pairName': pairName},
    );

    return pair;
  }

  /// Separate a pair (status -> 'separated', separatedDate -> now)
  Future<void> separatePair(int pairId) async {
    await (update(breedingPairs)..where((t) => t.id.equals(pairId)))
        .write(BreedingPairsCompanion(
      status: const Value('separated'),
      separatedDate: Value(AppClock.now),
      updatedAt: Value(AppClock.now),
    ));
  }

  /// Get all active pairs with male/female bird info (batch-loads birds)
  Future<List<({BreedingPair pair, Bird male, Bird female})>>
      getActivePairs() async {
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

    final birdList =
        await (select(birds)..where((t) => t.id.isIn(birdIds))).get();
    final birdById = {for (final b in birdList) b.id: b};

    return [
      for (final p in pairs)
        (
          pair: p,
          male: birdById[p.maleBirdId]!,
          female: birdById[p.femaleBirdId]!
        ),
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
        createdAt: Value(AppClock.now),
        updatedAt: Value(AppClock.now),
      ),
    );

    // 记录统一操作日志（关联两只鸟）
    final pair = await getPairById(pairId);
    if (pair != null) {
      await _recordBreedingOp(
        maleBirdId: pair.maleBirdId,
        femaleBirdId: pair.femaleBirdId,
        actionType: 'breeding_started',
        summary: '开始繁育记录',
        details: {
          'pairId': pairId,
          'recordId': record.id,
        },
      );
      // 新建繁殖记录，初始阶段为"配对" → 通知 stage 插件设为繁殖准备期
      await _notifyStagePlugin(
        maleBirdId: pair.maleBirdId,
        femaleBirdId: pair.femaleBirdId,
        breedingStage: '配对',
      );
    }

    return record;
  }

  /// Advance to next stage: 配对->产蛋->孵化->育雏->完结
  Future<void> advanceStage(int recordId) async {
    final record = await (select(breedingRecords)
          ..where((t) => t.id.equals(recordId)))
        .getSingleOrNull();
    if (record == null) throw StateError('繁育记录不存在');

    const stages = ['配对', '产蛋', '孵化', '育雏', '已完结'];
    final currentIndex = stages.indexOf(record.stage);
    if (currentIndex < 0 || currentIndex >= stages.length - 1) {
      throw StateError('繁育记录已完结或处于未知阶段');
    }

    final fromStage = record.stage;
    final nextStage = stages[currentIndex + 1];
    final now = AppClock.now;
    await (update(breedingRecords)..where((t) => t.id.equals(recordId)))
        .write(BreedingRecordsCompanion(
      stage: Value(nextStage),
      endDate: nextStage == '已完结' ? Value(now) : const Value.absent(),
      updatedAt: Value(now),
    ));

    // 记录统一操作日志（关联两只鸟）
    final pair = await getPairById(record.pairId);
    if (pair != null) {
      await _recordBreedingOp(
        maleBirdId: pair.maleBirdId,
        femaleBirdId: pair.femaleBirdId,
        actionType: 'breeding_stage_advanced',
        summary: '繁育阶段: $fromStage → $nextStage',
        details: {
          'pairId': record.pairId,
          'recordId': recordId,
          'fromStage': fromStage,
          'toStage': nextStage,
        },
      );
      // 通知 stage 插件更新生理阶段
      await _notifyStagePlugin(
        maleBirdId: pair.maleBirdId,
        femaleBirdId: pair.femaleBirdId,
        breedingStage: nextStage,
      );
    }
  }

  /// Force-finish breeding at any stage with a reason
  Future<void> finishBreeding(int recordId, {String? reason}) async {
    final record = await (select(breedingRecords)
          ..where((t) => t.id.equals(recordId)))
        .getSingleOrNull();
    if (record == null) return;

    final now = AppClock.now;
    await (update(breedingRecords)..where((t) => t.id.equals(recordId)))
        .write(BreedingRecordsCompanion(
      stage: const Value('已完结'),
      endDate: Value(now),
      endReason: Value(reason),
      updatedAt: Value(now),
    ));

    // 记录统一操作日志（关联两只鸟）
    final pair = await getPairById(record.pairId);
    if (pair != null) {
      await _recordBreedingOp(
        maleBirdId: pair.maleBirdId,
        femaleBirdId: pair.femaleBirdId,
        actionType: 'breeding_finished',
        summary: '繁育结束${reason != null ? ": $reason" : ""}',
        details: {
          'pairId': record.pairId,
          'recordId': recordId,
          'fromStage': record.stage,
          'reason': reason,
        },
      );
      // 完结：通知 stage 插件回退到年龄推断
      await _notifyStagePlugin(
        maleBirdId: pair.maleBirdId,
        femaleBirdId: pair.femaleBirdId,
        breedingStage: '已完结',
      );
    }
  }

  /// Get the active (non-completed) breeding record for a pair.
  ///
  /// [createBreedingRecord] enforces a single active record per pair, so we can
  /// push the stage filter into SQL and use [getSingleOrNull].
  Future<BreedingRecord?> getActiveRecordForPair(int pairId) =>
      (select(breedingRecords)
            ..where((t) =>
                t.pairId.equals(pairId) & t.stage.equals('已完结').not())
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .getSingleOrNull();

  /// Get the active breeding record for any bird in an active pair.
  ///
  /// Replaces 4 sequential queries (pair → record → male → female) with a single
  /// JOIN over `breeding_records ⨝ breeding_pairs ⨝ birds(male) ⨝ birds(female)`.
  /// The bird must be the male or female of an active pair, the pair must be
  /// active, and the record must not be completed.
  Future<(BreedingRecord, BreedingPair, Bird male, Bird female)?>
      getActiveRecordForBird(int birdId) async {
    final maleBirds = alias(birds, 'male_bird');
    final femaleBirds = alias(birds, 'female_bird');

    final rows = await (select(breedingRecords).join([
      innerJoin(
          breedingPairs, breedingPairs.id.equalsExp(breedingRecords.pairId)),
      innerJoin(maleBirds, maleBirds.id.equalsExp(breedingPairs.maleBirdId)),
      innerJoin(
          femaleBirds, femaleBirds.id.equalsExp(breedingPairs.femaleBirdId)),
    ])
          ..where((breedingPairs.maleBirdId.equals(birdId) |
                  breedingPairs.femaleBirdId.equals(birdId)) &
              breedingPairs.status.equals('active') &
              breedingRecords.stage.equals('已完结').not())
          ..limit(1))
        .get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    return (
      row.readTable(breedingRecords),
      row.readTable(breedingPairs),
      row.readTable(maleBirds),
      row.readTable(femaleBirds),
    );
  }

  // ── 蛋 ──

  Future<Egg> addEgg(int breedingRecordId, {DateTime? laidDate}) async {
    final egg = await into(eggs).insertReturning(
      EggsCompanion.insert(
        uuid: genUuid(),
        breedingRecordId: breedingRecordId,
        laidDate: laidDate ?? AppClock.now,
        createdAt: Value(AppClock.now),
        updatedAt: Value(AppClock.now),
      ),
    );

    // 记录统一操作日志（关联两只鸟）
    final record = await (select(breedingRecords)
          ..where((t) => t.id.equals(breedingRecordId)))
        .getSingleOrNull();
    if (record != null) {
      final pair = await getPairById(record.pairId);
      if (pair != null) {
        await _recordBreedingOp(
          maleBirdId: pair.maleBirdId,
          femaleBirdId: pair.femaleBirdId,
          actionType: 'egg_laid',
          summary: '产蛋记录',
          details: {
            'pairId': record.pairId,
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

  Future<void> updateEggStatus(int eggId, String status,
      {DateTime? hatchDate, int? chickBirdId}) async {
    await (update(eggs)..where((t) => t.id.equals(eggId))).write(EggsCompanion(
      status: Value(status),
      hatchDate: Value(hatchDate),
      chickBirdId: Value(chickBirdId),
      updatedAt: Value(AppClock.now),
    ));

    // When a chick is linked to a hatched egg, record a lineage operation for the chick
    if (chickBirdId != null && status == '已出壳') {
      final egg = await (select(eggs)..where((t) => t.id.equals(eggId)))
          .getSingleOrNull();
      if (egg != null) {
        final record = await (select(breedingRecords)
              ..where((t) => t.id.equals(egg.breedingRecordId)))
            .getSingleOrNull();
        if (record != null) {
          final pair = await getPairById(record.pairId);
          if (pair != null) {
            await pluginRegistry.operationService.record(
              pluginId: 'breeding',
              actionType: 'chick_hatched',
              birdId: chickBirdId,
              summary: '从蛋出壳',
              details: {
                'pairId': pair.id,
                'recordId': record.id,
                'eggId': eggId,
                'fatherId': pair.maleBirdId,
                'motherId': pair.femaleBirdId,
                'hatchDate': hatchDate?.toIso8601String(),
              },
            );
          }
        }
      }
    }
  }

  // ── 踩背 ──

  Future<MatingEvent> addMatingEvent(int breedingRecordId,
      {DateTime? observedDate, String? notes}) async {
    final event = await into(matingEvents).insertReturning(
      MatingEventsCompanion.insert(
        uuid: genUuid(),
        breedingRecordId: breedingRecordId,
        observedDate: observedDate ?? AppClock.now,
        notes: Value(notes),
        createdAt: Value(AppClock.now),
      ),
    );

    // 记录统一操作日志（关联两只鸟）
    final record = await (select(breedingRecords)
          ..where((t) => t.id.equals(breedingRecordId)))
        .getSingleOrNull();
    if (record != null) {
      final pair = await getPairById(record.pairId);
      if (pair != null) {
        await _recordBreedingOp(
          maleBirdId: pair.maleBirdId,
          femaleBirdId: pair.femaleBirdId,
          actionType: 'mating_observed',
          summary: '踩背观察${notes != null ? ": $notes" : ""}',
          details: {
            'pairId': record.pairId,
            'recordId': breedingRecordId,
            'matingEventId': event.id,
            'observedDate': event.observedDate.toIso8601String(),
          },
        );
      }
    }

    return event;
  }

  Future<List<MatingEvent>> getMatingEventsByRecord(
      int breedingRecordId) async {
    return (select(matingEvents)
          ..where((t) => t.breedingRecordId.equals(breedingRecordId))
          ..orderBy([(t) => OrderingTerm.desc(t.observedDate)]))
        .get();
  }

  // ── 跨插件查询 ──

  /// Returns set of bird IDs currently in breeding (both male and female of active records)
  Future<Set<int>> getActiveBreedingBirdIds() async {
    final rows = await (select(breedingRecords).join([
      innerJoin(
          breedingPairs, breedingPairs.id.equalsExp(breedingRecords.pairId)),
    ])).get();
    final activeRecords =
        rows.where((r) => r.readTable(breedingRecords).stage != '已完结');

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

  // ── 族谱查询 ──

  /// Get a bird's parents by tracing through the egg they hatched from.
  ///
  /// Returns (father, mother) if the lineage can be determined, null otherwise.
  Future<({Bird father, Bird mother})?> getBirdParents(int birdId) async {
    // Find the egg this bird hatched from
    final egg = await (select(eggs)..where((t) => t.chickBirdId.equals(birdId)))
        .getSingleOrNull();
    if (egg == null) return null;

    // Find the breeding record for that egg
    final record = await (select(breedingRecords)
          ..where((t) => t.id.equals(egg.breedingRecordId)))
        .getSingleOrNull();
    if (record == null) return null;

    // Find the pair for that record
    final pair = await getPairById(record.pairId);
    if (pair == null) return null;

    final male = await getBirdById(pair.maleBirdId);
    final female = await getBirdById(pair.femaleBirdId);
    if (male == null || female == null) return null;

    return (father: male, mother: female);
  }

  /// Get a bird's offspring — birds that hatched from eggs in pairs where this
  /// bird was either the father or the mother.
  ///
  /// Replaces an O(pairs × records × eggs) nested loop of individual queries with
  /// a single JOIN: `eggs ⨝ breeding_records ⨝ breeding_pairs ⨝ birds(chick/father/mother)`.
  /// The inner join on `chicks` via `eggs.chickBirdId` naturally excludes eggs
  /// that never hatched (NULL), matching the original `isNotNull` filter.
  Future<List<({Bird chick, Bird father, Bird mother})>> getBirdOffspring(
      int birdId) async {
    final chicks = alias(birds, 'chicks');
    final fathers = alias(birds, 'fathers');
    final mothers = alias(birds, 'mothers');

    final rows = await (select(eggs).join([
      innerJoin(breedingRecords,
          breedingRecords.id.equalsExp(eggs.breedingRecordId)),
      innerJoin(
          breedingPairs, breedingPairs.id.equalsExp(breedingRecords.pairId)),
      innerJoin(chicks, chicks.id.equalsExp(eggs.chickBirdId)),
      innerJoin(fathers, fathers.id.equalsExp(breedingPairs.maleBirdId)),
      innerJoin(mothers, mothers.id.equalsExp(breedingPairs.femaleBirdId)),
    ])
          ..where(breedingPairs.maleBirdId.equals(birdId) |
              breedingPairs.femaleBirdId.equals(birdId)))
        .get();

    return [
      for (final row in rows)
        (
          chick: row.readTable(chicks),
          father: row.readTable(fathers),
          mother: row.readTable(mothers),
        ),
    ];
  }

  /// Get siblings of a bird (other chicks from the same parents).
  ///
  /// Replaces an O(pairs × records × eggs) nested loop with a single JOIN over
  /// `birds(chick) ⨝ eggs ⨝ breeding_records ⨝ breeding_pairs`, restricted to
  /// pairs containing this bird's parents (in either gender assignment) and
  /// excluding the bird itself. Sibling IDs are de-duplicated on the Dart side
  /// to match the original `Set<int>` semantics.
  Future<List<Bird>> getBirdSiblings(int birdId) async {
    final parents = await getBirdParents(birdId);
    if (parents == null) return [];

    final chicks = alias(birds, 'chicks');
    final rows = await (select(chicks).join([
      innerJoin(eggs, eggs.chickBirdId.equalsExp(chicks.id)),
      innerJoin(breedingRecords,
          breedingRecords.id.equalsExp(eggs.breedingRecordId)),
      innerJoin(
          breedingPairs, breedingPairs.id.equalsExp(breedingRecords.pairId)),
    ])
          ..where(
              ((breedingPairs.maleBirdId.equals(parents.father.id) &
                          breedingPairs.femaleBirdId.equals(parents.mother.id)) |
                      (breedingPairs.maleBirdId.equals(parents.mother.id) &
                          breedingPairs.femaleBirdId.equals(parents.father.id))) &
                  chicks.id.equals(birdId).not()))
        .get();

    final seen = <int>{};
    final siblings = <Bird>[];
    for (final row in rows) {
      final chick = row.readTable(chicks);
      if (seen.add(chick.id)) siblings.add(chick);
    }
    return siblings;
  }
}
