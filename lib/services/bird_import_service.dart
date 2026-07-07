import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import '../core/app_clock.dart';
import '../database/database.dart';
import '../plugins/gallery/gallery_storage_service.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/species_repository.dart';
import '../plugins/medication/medication_repository.dart';
import '../plugins/medication/drug_library_repository.dart';
import '../plugins/breeding/breeding_repository.dart';
import '../utils/uuid.dart';

/// 缺失物种信息
class ImportSpeciesInfo {
  final String uuid;
  final String name;
  final int nestlingEndDays;
  final int juvenileEndDays;
  final int nestlingWeighIntervalDays;
  final int juvenileWeighIntervalDays;
  final int adultWeighIntervalDays;
  ImportSpeciesInfo({
    required this.uuid,
    required this.name,
    this.nestlingEndDays = 45,
    this.juvenileEndDays = 120,
    this.nestlingWeighIntervalDays = 1,
    this.juvenileWeighIntervalDays = 3,
    this.adultWeighIntervalDays = 7,
  });
}

/// 导入预览 — 展示将要导入的鹦鹉及其数据概览
class BirdImportPreview {
  final int totalBirds;
  final List<ImportBirdInfo> birds;
  final List<ImportSpeciesInfo> missingSpecies;
  BirdImportPreview({
    required this.totalBirds,
    required this.birds,
    this.missingSpecies = const [],
  });
}

class ImportBirdInfo {
  final String name;
  final String uuid;
  final bool isNew;
  final String speciesName;
  final int weightCount;
  final int medicationCount;
  final int photoCount;
  ImportBirdInfo({
    required this.name,
    required this.uuid,
    required this.isNew,
    required this.speciesName,
    required this.weightCount,
    required this.medicationCount,
    required this.photoCount,
  });
}

/// 导入结果
class BirdImportResult {
  final int importedCount;
  final int skippedCount;
  final List<String> errors;
  BirdImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.errors,
  });
  bool get hasErrors => errors.isNotEmpty;
}

/// 批量鹦鹉导入服务 — 从 .wnbirds 文件恢复鹦鹉数据
class BirdImportService {
  static final BirdImportService _instance = BirdImportService._();
  factory BirdImportService() => _instance;
  BirdImportService._();

  final _storage = GalleryStorageService();

  // ── 预览 ──

  Future<BirdImportPreview?> previewImport(File file, AppDatabase db) async {
    try {
      final data = await _decryptAndParse(file);
      if (data == null) return null;

      final birdsJson = data['birds'] as List<dynamic>;
      final infos = <ImportBirdInfo>[];

      // 批量查询已存在的鸟（一次 SQL，O(n) 扫描 → O(1) lookup）
      final allUuids = birdsJson
          .map((bj) => (bj['bird'] as Map<String, dynamic>)['uuid'] as String)
          .toList();
      final existingSet =
          (await db.getBirdsByUuids(allUuids)).map((b) => b.uuid).toSet();

      // 批量加载所有物种（一次 SQL）
      final allSpecies = await db.getAllSpecies();
      final speciesByUuid = <String, Specy>{};
      final speciesByName = <String, Specy>{};
      for (final s in allSpecies) {
        speciesByUuid[s.uuid] = s;
        speciesByName[s.name] = s;
      }

      final missingSpecies = <ImportSpeciesInfo>[];
      final seenSpeciesUuids = <String>{};

      for (final bj in birdsJson) {
        final birdJson = bj['bird'] as Map<String, dynamic>;
        final uuid = birdJson['uuid'] as String;
        final speciesJson = bj['species'] as Map<String, dynamic>;
        final photos = bj['galleryPhotos'] as List<dynamic>? ?? [];
        final weights = bj['weights'] as List<dynamic>? ?? [];
        final medications = bj['medications'] as List<dynamic>? ?? [];
        infos.add(ImportBirdInfo(
          name: birdJson['name'] as String? ?? '?',
          uuid: uuid,
          isNew: !existingSet.contains(uuid),
          speciesName: speciesJson['name'] as String? ?? '?',
          weightCount: weights.length,
          medicationCount: medications.length,
          photoCount: photos.length,
        ));

        // 检测缺失物种（内存 lookup，无 SQL）
        final speciesUuid = speciesJson['uuid'] as String?;
        final speciesName = speciesJson['name'] as String? ?? '?';
        if (speciesUuid != null && !seenSpeciesUuids.contains(speciesUuid)) {
          seenSpeciesUuids.add(speciesUuid);
          final found = speciesByUuid[speciesUuid] ??
              (speciesName.isNotEmpty ? speciesByName[speciesName] : null);
          if (found == null) {
            missingSpecies.add(ImportSpeciesInfo(
              uuid: speciesUuid,
              name: speciesName,
              nestlingEndDays:
                  (speciesJson['nestlingEndDays'] as num?)?.toInt() ?? 45,
              juvenileEndDays:
                  (speciesJson['juvenileEndDays'] as num?)?.toInt() ?? 120,
              nestlingWeighIntervalDays:
                  (speciesJson['nestlingWeighIntervalDays'] as num?)?.toInt() ??
                      1,
              juvenileWeighIntervalDays:
                  (speciesJson['juvenileWeighIntervalDays'] as num?)?.toInt() ??
                      3,
              adultWeighIntervalDays:
                  (speciesJson['adultWeighIntervalDays'] as num?)?.toInt() ?? 7,
            ));
          }
        }
      }

      return BirdImportPreview(
        totalBirds: infos.length,
        birds: infos,
        missingSpecies: missingSpecies,
      );
    } catch (e) {
      debugPrint('BirdImportService.previewImport error: $e');
      return null;
    }
  }

  // ── 导入执行 ──

  Future<BirdImportResult> importBirds(
    File file,
    AppDatabase db, {
    List<ImportSpeciesInfo> missingSpecies = const [],
  }) async {
    final errors = <String>[];
    int imported = 0;
    int skipped = 0;

    try {
      await _storage.ensureInitialized();

      // 先创建缺失物种
      for (final ms in missingSpecies) {
        try {
          await db.upsertByUuid(
            ms.uuid,
            name: ms.name,
            nestlingEndDays: ms.nestlingEndDays,
            juvenileEndDays: ms.juvenileEndDays,
            nestlingWeighIntervalDays: ms.nestlingWeighIntervalDays,
            juvenileWeighIntervalDays: ms.juvenileWeighIntervalDays,
            adultWeighIntervalDays: ms.adultWeighIntervalDays,
          );
          debugPrint(
              'BirdImportService: created species "${ms.name}" (${ms.uuid})');
        } catch (e) {
          debugPrint(
              'BirdImportService: failed to create species "${ms.name}": $e');
        }
      }

      // 一次解密解压：同时拿到 data.json 和文件目录
      final (:data, :dir) = await _decryptAndUnzipFull(file);
      if (data == null || dir == null) {
        return BirdImportResult(
            importedCount: 0, skippedCount: 0, errors: ['无法解析或解压文件']);
      }

      try {
        final birdsJson = data['birds'] as List<dynamic>;
        // bird export UUID → new DB id
        final uuidToNewId = <String, int>{};

        // 预解析 species：uuid → species id
        final speciesCache = <String, int>{};

        for (final bj in birdsJson) {
          try {
            final birdJson = bj['bird'] as Map<String, dynamic>;
            final speciesJson = bj['species'] as Map<String, dynamic>;
            final uuid = birdJson['uuid'] as String;

            // 检查是否已存在（事务外，避免锁持有时间过长）
            final existing = await db.getBirdByUuid(uuid);
            if (existing != null) {
              skipped++;
              uuidToNewId[uuid] = existing.id;
              continue;
            }

            // 解析物种
            final speciesId =
                await _resolveSpecies(db, speciesJson, speciesCache);
            if (speciesId == null) {
              errors
                  .add('${birdJson['name']}: 无法匹配物种 "${speciesJson['name']}"');
              continue;
            }

            // 一鸟一事务：所有关联 INSERT 在同一事务内完成
            await db.transaction(() async {
              // 创建鸟
              final birthDate = DateTime.parse(birdJson['birthDate'] as String);
              final createdAt = birdJson['createdAt'] != null
                  ? DateTime.parse(birdJson['createdAt'] as String)
                  : AppClock.now;
              final updatedAt = birdJson['updatedAt'] != null
                  ? DateTime.parse(birdJson['updatedAt'] as String)
                  : AppClock.now;

              final newBird = await db.createBird(
                name: birdJson['name'] as String,
                speciesId: speciesId,
                birthDate: birthDate,
                ringNumber: birdJson['ringNumber'] as String?,
                gender: (birdJson['gender'] as String?) ?? '未知',
                notes: birdJson['notes'] as String?,
                uuid: uuid,
                roomId: null, // 环境特定，置空
                enclosureId: null,
                createdAt: createdAt,
                updatedAt: updatedAt,
              );

              final newId = newBird.id;
              uuidToNewId[uuid] = newId;

              // 合并 sortOrder / weighIntervalDays / manualBaselineG / weaningOverride / status 为一次 update
              await db.updateBird(
                newId,
                sortOrder: (birdJson['sortOrder'] as num?)?.toInt(),
                weighIntervalDays: birdJson['weighIntervalDays'] as int?,
                manualBaselineG:
                    (birdJson['manualBaselineG'] as num?)?.toDouble(),
                weaningOverride: birdJson['weaningOverride'] as bool?,
                status: birdJson['status'] as String?,
              );

              // 导入体重
              final weights = bj['weights'] as List<dynamic>? ?? [];
              for (final wj in weights) {
                try {
                  await db.addWeight(
                    birdId: newId,
                    weightG: (wj['weightG'] as num).toDouble(),
                    recordedAt: DateTime.parse(wj['recordedAt'] as String),
                    isFasting: (wj['isFasting'] as bool?) ?? false,
                    notes: wj['notes'] as String?,
                    createdAt: wj['createdAt'] != null
                        ? DateTime.parse(wj['createdAt'] as String)
                        : null,
                    updatedAt: wj['updatedAt'] != null
                        ? DateTime.parse(wj['updatedAt'] as String)
                        : null,
                  );
                } catch (e) {
                  debugPrint('BirdImportService: weight import error: $e');
                }
              }

              // 导入喂药方案
              final medications = bj['medications'] as List<dynamic>? ?? [];
              for (final mj in medications) {
                try {
                  await _insertMedication(
                      db, newId, mj as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('BirdImportService: medication import error: $e');
                }
              }

              // 导入任务
              final tasks = bj['tasks'] as List<dynamic>? ?? [];
              for (final tj in tasks) {
                try {
                  await _insertTask(db, newId, tj as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('BirdImportService: task import error: $e');
                }
              }

              // 导入操作日志
              final logs = bj['activityLogs'] as List<dynamic>? ?? [];
              for (final lj in logs) {
                try {
                  await _insertActivityLog(
                      db, newId, lj as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('BirdImportService: activityLog import error: $e');
                }
              }

              // 导入告警记录
              final alerts = bj['alertRecords'] as List<dynamic>? ?? [];
              for (final aj in alerts) {
                try {
                  await _insertAlertRecord(
                      db, newId, aj as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('BirdImportService: alertRecord import error: $e');
                }
              }

              // 导入照片（顺序处理，避免并发 savePhoto 时时间戳碰撞导致文件覆盖）
              final photos = bj['galleryPhotos'] as List<dynamic>? ?? [];
              for (final pj in photos) {
                try {
                  await _importPhoto(
                      db, dir, newId, uuid, pj as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('BirdImportService: photo import error: $e');
                }
              }

              // 导入头像
              final avatar = bj['avatar'] as Map<String, dynamic>?;
              if (avatar != null) {
                try {
                  await _importAvatar(db, dir, newId, uuid, avatar);
                } catch (e) {
                  debugPrint('BirdImportService: avatar import error: $e');
                }
              }
            }); // end transaction

            imported++;
          } catch (e) {
            errors.add('导入失败: $e');
            debugPrint('BirdImportService: bird import error: $e');
          }
        }

        // 导入繁育数据（在所有鸟创建之后）
        try {
          await _importBreedingData(db, data, uuidToNewId, dir);
        } catch (e) {
          debugPrint('BirdImportService: breeding import error: $e');
          errors.add('繁育数据导入失败: $e');
        }

        return BirdImportResult(
          importedCount: imported,
          skippedCount: skipped,
          errors: errors,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('BirdImportService.importBirds error: $e');
      errors.add('导入失败: $e');
      return BirdImportResult(
          importedCount: imported, skippedCount: skipped, errors: errors);
    }
  }

  // ── 物种解析 ──

  Future<int?> _resolveSpecies(AppDatabase db, Map<String, dynamic> speciesJson,
      Map<String, int> cache) async {
    final uuid = speciesJson['uuid'] as String?;
    final name = speciesJson['name'] as String?;

    // 1. UUID 匹配
    if (uuid != null && cache.containsKey(uuid)) return cache[uuid];
    if (uuid != null) {
      final s = await db.getSpeciesByUuid(uuid);
      if (s != null) {
        cache[uuid] = s.id;
        return s.id;
      }
    }

    // 2. 名称匹配
    if (name != null) {
      final s = await db.getSpeciesByNameSafe(name);
      if (s != null) {
        if (uuid != null) cache[uuid] = s.id;
        return s.id;
      }
    }

    // 3. 回退到第一个物种
    final all = await db.getAllSpecies();
    if (all.isNotEmpty) {
      final fallback = all.first;
      if (uuid != null) cache[uuid] = fallback.id;
      return fallback.id;
    }

    return null;
  }

  // ── 关联数据插入 ──

  Future<void> _insertMedication(
      AppDatabase db, int birdId, Map<String, dynamic> mj) async {
    // Only import new-format medication records (v17+)
    final drugLibraryId = mj['drugLibraryId'] as int?;
    final formulationId = mj['formulationId'] as int?;
    final diseaseCatalogId = mj['diseaseCatalogId'] as int?;
    if (drugLibraryId == null ||
        formulationId == null ||
        diseaseCatalogId == null) {
      return; // Skip old-format medications
    }

    final startDate = DateTime.parse(mj['startDate'] as String);
    final endDate =
        mj['endDate'] != null ? DateTime.parse(mj['endDate'] as String) : null;
    final createdAt = mj['createdAt'] != null
        ? DateTime.parse(mj['createdAt'] as String)
        : AppClock.now;
    final updatedAt = mj['updatedAt'] != null
        ? DateTime.parse(mj['updatedAt'] as String)
        : AppClock.now;

    await db.addMedicationFromLibrary(
      birdId: birdId,
      drugLibraryId: drugLibraryId,
      formulationId: formulationId,
      diseaseCatalogId: diseaseCatalogId,
      doseRuleId: mj['doseRuleId'] as int?,
      calculatedDosage: (mj['calculatedDosage'] as String?) ??
          (mj['manualDosage'] as String?) ??
          '',
      manualDosage: mj['manualDosage'] as String?,
      timesPerDay: (mj['timesPerDay'] as num?)?.toInt() ?? 1,
      startDate: startDate,
      endDate: endDate,
      notes: mj['notes'] as String?,
    );
  }

  Future<void> _insertTask(
      AppDatabase db, int birdId, Map<String, dynamic> tj) async {
    final dueDate = DateTime.parse(tj['dueDate'] as String);
    final deadline = tj['deadline'] != null
        ? DateTime.parse(tj['deadline'] as String)
        : null;
    final completedAt = tj['completedAt'] != null
        ? DateTime.parse(tj['completedAt'] as String)
        : null;
    final createdAt = tj['createdAt'] != null
        ? DateTime.parse(tj['createdAt'] as String)
        : AppClock.now;
    final updatedAt = tj['updatedAt'] != null
        ? DateTime.parse(tj['updatedAt'] as String)
        : AppClock.now;

    await db.into(db.tasks).insert(TasksCompanion.insert(
          uuid: (tj['uuid'] as String?) ?? genUuid(),
          birdId: birdId,
          roomId: Value(null),
          assignedUserId: Value(tj['assignedUserId'] as int?),
          taskType: Value((tj['taskType'] as String?) ?? 'weigh'),
          dueDate: dueDate,
          deadline: Value(deadline),
          status: Value((tj['status'] as String?) ?? '待完成'),
          completedAt: Value(completedAt),
          completedBy: Value(tj['completedBy'] as int?),
          metadata: Value(tj['metadata'] as String?),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
        ));
  }

  Future<void> _insertActivityLog(
      AppDatabase db, int birdId, Map<String, dynamic> lj) async {
    final operatedAt = DateTime.parse(lj['operatedAt'] as String);
    final createdAt = lj['createdAt'] != null
        ? DateTime.parse(lj['createdAt'] as String)
        : AppClock.now;

    await db.into(db.activityLogs).insert(ActivityLogsCompanion.insert(
          uuid: (lj['uuid'] as String?) ?? genUuid(),
          birdId: Value(birdId),
          pluginId: (lj['pluginId'] as String?) ?? '',
          actionType: (lj['actionType'] as String?) ?? '',
          summary: (lj['summary'] as String?) ?? '',
          details: Value(lj['details'] as String?),
          relatedTaskId: Value(lj['relatedTaskId'] as int?),
          operatedBy: Value(lj['operatedBy'] as int?),
          operatedAt: Value(operatedAt),
          createdAt: Value(createdAt),
        ));
  }

  Future<void> _insertAlertRecord(
      AppDatabase db, int birdId, Map<String, dynamic> aj) async {
    final resolvedAt = aj['resolvedAt'] != null
        ? DateTime.parse(aj['resolvedAt'] as String)
        : null;
    final createdAt = aj['createdAt'] != null
        ? DateTime.parse(aj['createdAt'] as String)
        : AppClock.now;
    final updatedAt = aj['updatedAt'] != null
        ? DateTime.parse(aj['updatedAt'] as String)
        : AppClock.now;

    await db.into(db.alertRecords).insert(AlertRecordsCompanion.insert(
          uuid: (aj['uuid'] as String?) ?? genUuid(),
          birdId: birdId,
          alertType: (aj['alertType'] as String?) ?? '',
          description: (aj['description'] as String?) ?? '',
          severity: (aj['severity'] as String?) ?? 'warning',
          isRead: Value((aj['isRead'] as bool?) ?? false),
          isResolved: Value((aj['isResolved'] as bool?) ?? false),
          resolvedAt: Value(resolvedAt),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
        ));
  }

  // ── 照片导入 ──

  Future<void> _importPhoto(AppDatabase db, Directory zipDir, int birdId,
      String birdUuid, Map<String, dynamic> pj) async {
    final fileName = pj['fileName'] as String?;
    if (fileName == null) return;

    final zipPhotoPath = p.join(zipDir.path, 'gallery', birdUuid, fileName);
    final zipPhotoFile = File(zipPhotoPath);
    if (!await zipPhotoFile.exists()) {
      debugPrint('BirdImportService: photo not found in zip: $zipPhotoPath');
      return;
    }

    // 使用 GalleryStorageService 保存照片
    final newRelativePath = await _storage.savePhoto(birdId, zipPhotoPath);

    // 如果有视频文件
    String? newVideoPath;
    final videoFileName = pj['videoFileName'] as String?;
    if (videoFileName != null) {
      final zipVideoPath =
          p.join(zipDir.path, 'gallery', birdUuid, videoFileName);
      final zipVideoFile = File(zipVideoPath);
      if (await zipVideoFile.exists()) {
        newVideoPath = await _storage.saveVideo(birdId, zipVideoPath);
      }
    }

    // 插入 birdPhotos 记录
    final sortOrder = (pj['sortOrder'] as num?)?.toInt() ?? 0;
    final mediaType = (pj['mediaType'] as String?) ?? 'photo';
    final createdAt = pj['createdAt'] != null
        ? DateTime.parse(pj['createdAt'] as String)
        : AppClock.now;
    await db.into(db.birdPhotos).insert(BirdPhotosCompanion.insert(
          birdId: birdId,
          filePath: newRelativePath,
          sortOrder: Value(sortOrder),
          mediaType: Value(mediaType),
          videoFilePath: Value(newVideoPath),
          createdAt: Value(createdAt),
        ));
  }

  Future<void> _importAvatar(AppDatabase db, Directory zipDir, int birdId,
      String birdUuid, Map<String, dynamic> aj) async {
    final fileName = aj['fileName'] as String?;
    if (fileName == null) return;

    final zipAvatarPath = p.join(zipDir.path, 'gallery', birdUuid, fileName);
    final zipAvatarFile = File(zipAvatarPath);
    if (!await zipAvatarFile.exists()) return;

    final newRelativePath = await _storage.saveAvatar(birdId, zipAvatarPath);

    final updatedAt = aj['updatedAt'] != null
        ? DateTime.parse(aj['updatedAt'] as String)
        : AppClock.now;
    // 删除旧头像记录再插入（birdId 有唯一约束）
    await (db.delete(db.birdAvatars)..where((t) => t.birdId.equals(birdId)))
        .go();
    await db.into(db.birdAvatars).insert(BirdAvatarsCompanion.insert(
          birdId: birdId,
          filePath: newRelativePath,
          updatedAt: Value(updatedAt),
        ));
  }

  // ── 繁育数据导入 ──

  Future<void> _importBreedingData(
    AppDatabase db,
    Map<String, dynamic> data,
    Map<String, int> uuidToBirdId,
    Directory zipDir,
  ) async {
    // UUID → new pair id
    final pairUuidToId = <String, int>{};
    // UUID → new record id
    final recordUuidToId = <String, int>{};

    // 导入配对
    final pairs = data['breedingPairs'] as List<dynamic>? ?? [];
    for (final pj in pairs) {
      final pMap = pj as Map<String, dynamic>;
      final maleUuid = pMap['maleBirdUuid'] as String?;
      final femaleUuid = pMap['femaleBirdUuid'] as String?;
      if (maleUuid == null || femaleUuid == null) continue;

      final maleId = uuidToBirdId[maleUuid];
      final femaleId = uuidToBirdId[femaleUuid];
      if (maleId == null || femaleId == null) continue;

      // 检查这只鸟是否已有活跃配对
      final existingMale = await db.getActivePairForBird(maleId);
      if (existingMale != null) continue;
      final existingFemale = await db.getActivePairForBird(femaleId);
      if (existingFemale != null) continue;

      final pairedDate = pMap['pairedDate'] != null
          ? DateTime.parse(pMap['pairedDate'] as String)
          : AppClock.now;
      final separatedDate = pMap['separatedDate'] != null
          ? DateTime.parse(pMap['separatedDate'] as String)
          : null;
      final createdAt = pMap['createdAt'] != null
          ? DateTime.parse(pMap['createdAt'] as String)
          : AppClock.now;
      final updatedAt = pMap['updatedAt'] != null
          ? DateTime.parse(pMap['updatedAt'] as String)
          : AppClock.now;

      final pairId =
          await db.into(db.breedingPairs).insert(BreedingPairsCompanion.insert(
                uuid: (pMap['uuid'] as String?) ?? genUuid(),
                maleBirdId: maleId,
                femaleBirdId: femaleId,
                pairName: Value(pMap['pairName'] as String?),
                status: Value((pMap['status'] as String?) ?? 'active'),
                pairedDate: Value(pairedDate),
                separatedDate: Value(separatedDate),
                notes: Value(pMap['notes'] as String?),
                createdAt: Value(createdAt),
                updatedAt: Value(updatedAt),
              ));
      pairUuidToId[pMap['uuid'] as String] = pairId;
    }

    // 导入繁育记录
    final records = data['breedingRecords'] as List<dynamic>? ?? [];
    for (final rj in records) {
      final rMap = rj as Map<String, dynamic>;
      final pairUuid = rMap['pairUuid'] as String?;
      if (pairUuid == null) continue;
      final pairId = pairUuidToId[pairUuid];
      if (pairId == null) continue;

      final startDate = rMap['startDate'] != null
          ? DateTime.parse(rMap['startDate'] as String)
          : AppClock.now;
      final endDate = rMap['endDate'] != null
          ? DateTime.parse(rMap['endDate'] as String)
          : null;
      final createdAt = rMap['createdAt'] != null
          ? DateTime.parse(rMap['createdAt'] as String)
          : AppClock.now;
      final updatedAt = rMap['updatedAt'] != null
          ? DateTime.parse(rMap['updatedAt'] as String)
          : AppClock.now;

      final recordId = await db
          .into(db.breedingRecords)
          .insert(BreedingRecordsCompanion.insert(
            uuid: (rMap['uuid'] as String?) ?? genUuid(),
            pairId: pairId,
            stage: Value((rMap['stage'] as String?) ?? '配对'),
            startDate: Value(startDate),
            endDate: Value(endDate),
            endReason: Value(rMap['endReason'] as String?),
            notes: Value(rMap['notes'] as String?),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
          ));
      recordUuidToId[rMap['uuid'] as String] = recordId;
    }

    // 导入蛋
    final eggs = data['eggs'] as List<dynamic>? ?? [];
    for (final ej in eggs) {
      final eMap = ej as Map<String, dynamic>;
      final recordUuid = eMap['breedingRecordUuid'] as String?;
      if (recordUuid == null) continue;
      final recordId = recordUuidToId[recordUuid];
      if (recordId == null) continue;

      final laidDate = eMap['laidDate'] != null
          ? DateTime.parse(eMap['laidDate'] as String)
          : AppClock.now;
      final hatchDate = eMap['hatchDate'] != null
          ? DateTime.parse(eMap['hatchDate'] as String)
          : null;
      final chickUuid = eMap['chickBirdUuid'] as String?;
      final chickBirdId = chickUuid != null ? uuidToBirdId[chickUuid] : null;
      final createdAt = eMap['createdAt'] != null
          ? DateTime.parse(eMap['createdAt'] as String)
          : AppClock.now;
      final updatedAt = eMap['updatedAt'] != null
          ? DateTime.parse(eMap['updatedAt'] as String)
          : AppClock.now;

      await db.into(db.eggs).insert(EggsCompanion.insert(
            uuid: (eMap['uuid'] as String?) ?? genUuid(),
            breedingRecordId: recordId,
            laidDate: laidDate,
            hatchDate: Value(hatchDate),
            status: Value((eMap['status'] as String?) ?? '孵化中'),
            chickBirdId: Value(chickBirdId),
            notes: Value(eMap['notes'] as String?),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
          ));
    }

    // 导入踩背记录
    final matingEvents = data['matingEvents'] as List<dynamic>? ?? [];
    for (final mej in matingEvents) {
      final meMap = mej as Map<String, dynamic>;
      final recordUuid = meMap['breedingRecordUuid'] as String?;
      if (recordUuid == null) continue;
      final recordId = recordUuidToId[recordUuid];
      if (recordId == null) continue;

      final observedDate = meMap['observedDate'] != null
          ? DateTime.parse(meMap['observedDate'] as String)
          : AppClock.now;
      final createdAt = meMap['createdAt'] != null
          ? DateTime.parse(meMap['createdAt'] as String)
          : AppClock.now;

      await db.into(db.matingEvents).insert(MatingEventsCompanion.insert(
            uuid: (meMap['uuid'] as String?) ?? genUuid(),
            breedingRecordId: recordId,
            observedDate: observedDate,
            notes: Value(meMap['notes'] as String?),
            createdAt: Value(createdAt),
          ));
    }
  }

  // ── 解密 + 解析 (preview 用: 只需 data.json，不需要解压到磁盘) ──

  /// 解密并解析 data.json，返回 JSON map；失败返回 null
  Future<Map<String, dynamic>?> _decryptAndParse(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 5) return null;

      // 验证 magic
      final magic = String.fromCharCodes(bytes.sublist(0, 4));
      if (magic != 'WNBD') return null;

      // 解压 ZIP（magic 后直接是 ZIP 数据），提取 data.json
      final zipData = bytes.sublist(4);
      final archive = ZipDecoder().decodeBytes(zipData);
      for (final file in archive) {
        if (file.name == 'data.json' && file.isFile) {
          final content = file.content is List<int>
              ? file.content as List<int>
              : (file.content as dynamic).toList();
          final jsonStr = utf8.decode(content);
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('BirdImportService._decryptAndParse error: $e');
      return null;
    }
  }

  // ── 解密 + 解压全量 (导入用: 一次完成) ──

  /// 一次解压：同时提取 data.json 和写出所有文件到临时目录。
  /// 返回 record: (data: 解析后的 JSON, dir: 临时目录)
  Future<({Map<String, dynamic>? data, Directory? dir})> _decryptAndUnzipFull(
      File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 5) return (data: null, dir: null);

      final magic = String.fromCharCodes(bytes.sublist(0, 4));
      if (magic != 'WNBD') return (data: null, dir: null);

      // magic 后直接是 ZIP 数据
      final zipData = bytes.sublist(4);
      final archive = ZipDecoder().decodeBytes(zipData);
      final tempDir = await Directory.systemTemp.createTemp('wnbirds_import_');
      Map<String, dynamic>? parsedData;

      for (final f in archive) {
        if (!f.isFile) continue;
        final content = f.content is List<int>
            ? f.content as List<int>
            : (f.content as dynamic).toList() as List<int>;
        if (f.name == 'data.json') {
          parsedData = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
        }
        final out = File(p.join(tempDir.path, f.name));
        await out.parent.create(recursive: true);
        await out.writeAsBytes(content);
      }
      return (data: parsedData, dir: tempDir);
    } catch (e) {
      debugPrint('BirdImportService._decryptAndUnzipFull error: $e');
      return (data: null, dir: null);
    }
  }

  void debugPrint(String message) {
    if (const bool.fromEnvironment('dart.vm.product')) return;
    // ignore: avoid_print
    print(message);
  }
}
