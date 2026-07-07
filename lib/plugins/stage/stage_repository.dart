import 'package:drift/drift.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import 'stage_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 生理阶段缓存表的读写 + 自动推断逻辑。
//
// 推断优先级（由 [StageRepository.recomputeStage] 实现）：
//   0. 手动覆盖（bird.stageOverride 非空）→ 直接写入，source=manual
//   1. 繁殖阶段（由 breeding 插件通过 setStage 主动写入，source=breeding）→ 不重算
//   2. 年龄推断（nestlingEndDays / juvenileEndDays + weaningOverride）→ source=auto
//
// 注意：繁殖阶段的写入与清除由 breeding 插件负责（它知道何时进入/退出繁殖），
//       recomputeStage 不会覆盖 source=breeding 的记录，除非鸟已有 manual 覆盖。
// ═══════════════════════════════════════════════════════════════════════════════

/// 内存缓存 —— 提供同步读取能力。
/// 写入 DB 后同步更新此缓存，保证 getStage/getStages 可同步调用。
class _StageCache {
  final Map<int, String> _stages = {};

  String? get(int birdId) => _stages[birdId];

  void put(int birdId, String stage) => _stages[birdId] = stage;

  void remove(int birdId) => _stages.remove(birdId);

  void putAll(Map<int, String> updates) => _stages.addAll(updates);

  void clear() => _stages.clear();
}

final _cache = _StageCache();

/// 鸟信息缓存（ageDays, species, weaningOverride），供同步年龄推断使用。
final _birdInfoCache = <int, (int, Specy, bool?)>{};

extension StageRepository on AppDatabase {
  // ── 同步读取（内存缓存 + 年龄推断回退）──

  /// 同步读取单只鸟的当前生理阶段。
  ///
  /// 优先从内存缓存获取；无缓存时查鸟信息做年龄推断（不写库），
  /// 保证调用方总能拿到一个合法的 [RecipeStage] 值。
  String getStageSync(int birdId) {
    final cached = _cache.get(birdId);
    if (cached != null) return cached;
    // 无缓存 → 异步预加载（fire-and-forget）+ 同步年龄推断兜底
    _prefetchStage(birdId);
    final birdWithSpecies = _getBirdWithSpeciesSync(birdId);
    if (birdWithSpecies == null) return RecipeStage.adult;
    return _inferFromAge(
      birdWithSpecies.$1,
      birdWithSpecies.$2,
      birdWithSpecies.$3,
    );
  }

  /// 同步批量读取多只鸟的生理阶段。
  ///
  /// 未命中缓存的鸟用年龄推断补齐，同时触发异步预加载。
  Map<int, String> getStagesSync(List<int> birdIds) {
    if (birdIds.isEmpty) return {};
    final result = <int, String>{};
    final missing = <int>[];

    for (final id in birdIds) {
      final cached = _cache.get(id);
      if (cached != null) {
        result[id] = cached;
      } else {
        missing.add(id);
      }
    }

    // 缺失的鸟做同步年龄推断
    if (missing.isNotEmpty) {
      _prefetchStages(missing);
      for (final id in missing) {
        final info = _getBirdWithSpeciesSync(id);
        if (info != null) {
          result[id] = _inferFromAge(info.$1, info.$2, info.$3);
        } else {
          result[id] = RecipeStage.adult;
        }
      }
    }

    return result;
  }

  // ── 异步写入（写 DB + 更新缓存）──

  /// 写入单只鸟的阶段（breeding 插件 / 手动覆盖调用）。
  Future<void> setStage(
    int birdId,
    String stage, {
    String source = StageSource.auto,
  }) async {
    await into(birdStages).insertOnConflictUpdate(
      BirdStagesCompanion.insert(
        birdId: birdId,
        stage: stage,
        source: Value(source),
        updatedAt: Value(AppClock.now),
      ),
    );
    _cache.put(birdId, stage);
  }

  /// 批量写入多只鸟的阶段（查窝批量更新场景）。
  Future<void> setStages(
    Map<int, String> updates, {
    String source = StageSource.breeding,
  }) async {
    if (updates.isEmpty) return;
    await batch((b) {
      for (final entry in updates.entries) {
        b.insert(
          birdStages,
          BirdStagesCompanion.insert(
            birdId: entry.key,
            stage: entry.value,
            source: Value(source),
            updatedAt: Value(AppClock.now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    _cache.putAll(updates);
  }

  /// 清除单只鸟的阶段缓存（例如繁殖完结后回退到年龄推断）。
  Future<void> clearStage(int birdId) async {
    await (delete(birdStages)..where((t) => t.birdId.equals(birdId))).go();
    _cache.remove(birdId);
  }

  /// 重新推断单只鸟的阶段。
  ///
  /// 推断规则：
  /// - 若 bird.stageOverride 非空 → 写入 manual 覆盖值
  /// - 否则按年龄推断写入，source=auto
  /// - **不会覆盖 source=breeding 的记录**（繁殖阶段由 breeding 插件管理），
  ///   除非存在 manual 覆盖（手动覆盖优先级最高）。
  Future<void> recomputeStage(int birdId) async {
    final birdRow = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
    ])
          ..where(birds.id.equals(birdId)))
        .getSingleOrNull();
    if (birdRow == null) return;

    final bird = birdRow.readTable(birds);
    final sp = birdRow.readTable(species);

    // 缓存鸟信息（供同步年龄推断）
    final ageDays0 = AppClock.now.difference(bird.birthDate).inDays;
    _birdInfoCache[birdId] = (ageDays0 < 0 ? 0 : ageDays0, sp, bird.weaningOverride);

    // 0) 手动覆盖优先
    if (bird.stageOverride != null &&
        RecipeStage.all.contains(bird.stageOverride)) {
      await setStage(birdId, bird.stageOverride!, source: StageSource.manual);
      return;
    }

    // 检查是否已有 breeding 来源的记录 —— 有则不覆盖
    final existing = await (select(birdStages)
          ..where((t) => t.birdId.equals(birdId)))
        .getSingleOrNull();
    if (existing != null && existing.source == StageSource.breeding) {
      return; // 繁殖阶段由 breeding 插件管理，不重算
    }

    // 1) 年龄推断
    final ageDays = AppClock.now.difference(bird.birthDate).inDays;
    final stage = _inferFromAge(ageDays, sp, bird.weaningOverride);
    await setStage(birdId, stage, source: StageSource.auto);
  }

  /// 为所有鸟重新推断阶段（app 启动或批量修复时调用）。
  Future<void> recomputeAllStages() async {
    final allBirds = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
    ])).get();

    for (final row in allBirds) {
      final bird = row.readTable(birds);
      final sp = row.readTable(species);

      // 缓存鸟信息（供同步年龄推断）
      final ageDays0 = AppClock.now.difference(bird.birthDate).inDays;
      _birdInfoCache[bird.id] = (ageDays0 < 0 ? 0 : ageDays0, sp, bird.weaningOverride);

      // 手动覆盖优先
      if (bird.stageOverride != null &&
          RecipeStage.all.contains(bird.stageOverride)) {
        await setStage(bird.id, bird.stageOverride!,
            source: StageSource.manual);
        continue;
      }

      // 检查是否已有 breeding 记录
      final existing = await (select(birdStages)
            ..where((t) => t.birdId.equals(bird.id)))
          .getSingleOrNull();
      if (existing != null && existing.source == StageSource.breeding) {
        _cache.put(bird.id, existing.stage);
        continue;
      }

      final ageDays = AppClock.now.difference(bird.birthDate).inDays;
      final stage = _inferFromAge(ageDays, sp, bird.weaningOverride);
      await setStage(bird.id, stage, source: StageSource.auto);
    }
  }

  // ── 内部工具 ──

  /// 异步预加载单只鸟的阶段 + 鸟信息到缓存（fire-and-forget）。
  void _prefetchStage(int birdId) {
    // 预加载鸟信息（供后续同步年龄推断）
    _ensureBirdInfoCached(birdId);
    // 预加载阶段缓存
    (select(birdStages)..where((t) => t.birdId.equals(birdId)))
        .getSingleOrNull()
        .then((row) {
      if (row != null) _cache.put(birdId, row.stage);
    });
  }

  /// 异步批量预加载阶段 + 鸟信息（fire-and-forget）。
  void _prefetchStages(List<int> birdIds) {
    // 预加载鸟信息
    for (final id in birdIds) {
      _ensureBirdInfoCached(id);
    }
    // 预加载阶段缓存
    (select(birdStages)..where((t) => t.birdId.isIn(birdIds)))
        .get()
        .then((rows) {
      for (final r in rows) {
        _cache.put(r.birdId, r.stage);
      }
    });
  }

  /// 异步查鸟 + 物种信息，结果缓存到内存供同步读取。
  /// 在 `_initBirdInfoCache` 中批量预加载。
  Future<void> _ensureBirdInfoCached(int birdId) async {
    if (_birdInfoCache.containsKey(birdId)) return;
    final row = await (select(birds).join([
      innerJoin(species, species.id.equalsExp(birds.speciesId)),
    ])
          ..where(birds.id.equals(birdId)))
        .getSingleOrNull();
    if (row != null) {
      final bird = row.readTable(birds);
      final sp = row.readTable(species);
      _birdInfoCache[birdId] = (
        AppClock.now.difference(bird.birthDate).inDays,
        sp,
        bird.weaningOverride,
      );
    }
  }

  /// 同步查鸟 + 物种信息（从内存缓存，无缓存返回 null）。
  (int, Specy, bool?)? _getBirdWithSpeciesSync(int birdId) {
    return _birdInfoCache[birdId];
  }

  /// 纯年龄推断（不涉及繁殖状态）。
  String _inferFromAge(int ageDays, Specy species, bool? weaningOverride) {
    final nestlingEnd = species.nestlingEndDays;
    final juvenileEnd = species.juvenileEndDays;

    if (weaningOverride == true) {
      if (ageDays < juvenileEnd) return RecipeStage.weaning;
    }

    if (ageDays < nestlingEnd) return RecipeStage.nestling;

    if (weaningOverride == false) {
      if (ageDays < juvenileEnd) return RecipeStage.juvenile;
      return RecipeStage.adult;
    }

    final weaningWindow = (juvenileEnd - nestlingEnd) ~/ 3;
    if (ageDays < nestlingEnd + weaningWindow) return RecipeStage.weaning;
    if (ageDays < juvenileEnd) return RecipeStage.juvenile;
    return RecipeStage.adult;
  }
}
