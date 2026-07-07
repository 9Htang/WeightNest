import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart'; // superset of archive.dart; adds ZipFileEncoder
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';
import '../plugins/gallery/gallery_storage_service.dart';
import '../repositories/bird_repository.dart';

class BirdExportService {
  static final BirdExportService _instance = BirdExportService._();
  factory BirdExportService() => _instance;
  BirdExportService._();

  final _storage = GalleryStorageService();

  Future<File?> exportBirds(List<int> birdIds, AppDatabase db) async {
    if (birdIds.isEmpty) return null;
    final sw = Stopwatch()..start();
    try {
      debugPrint('[ExportSvc] ===== 开始导出 ${birdIds.length} 只鸟: $birdIds =====');

      debugPrint('[ExportSvc] ensureInitialized...');
      await _storage.ensureInitialized();
      debugPrint(
          '[ExportSvc] ensureInitialized 完成 (${sw.elapsedMilliseconds}ms)');

      // ── 1. 并行收集数据 ──
      debugPrint('[ExportSvc] 并行收集鸟详情...');
      final birdsWithDetails = (await Future.wait(
        birdIds.map((id) => db.getWithDetails(id)),
      ))
          .whereType<BirdWithDetails>()
          .toList();
      if (birdsWithDetails.isEmpty) {
        debugPrint('[ExportSvc] 没有找到鸟，返回 null');
        return null;
      }
      debugPrint(
          '[ExportSvc] 鸟详情收集完成: ${birdsWithDetails.length} 只 (${sw.elapsedMilliseconds}ms)');

      final birdIdSet = birdIds.toSet();

      // 7 个关联表查询并行发出
      debugPrint('[ExportSvc] 并行查询关联数据...');
      final results = await Future.wait([
        (db.select(db.weights)..where((t) => t.birdId.isIn(birdIds))).get(),
        (db.select(db.medications)..where((t) => t.birdId.isIn(birdIds))).get(),
        (db.select(db.tasks)..where((t) => t.birdId.isIn(birdIds))).get(),
        (db.select(db.activityLogs)..where((t) => t.birdId.isIn(birdIds)))
            .get(),
        (db.select(db.alertRecords)..where((t) => t.birdId.isIn(birdIds)))
            .get(),
        (db.select(db.birdPhotos)..where((t) => t.birdId.isIn(birdIds))).get(),
        (db.select(db.birdAvatars)..where((t) => t.birdId.isIn(birdIds))).get(),
      ]);
      final allWeights = results[0] as List<Weight>;
      final allMedications = results[1] as List<Medication>;
      final allTasks = results[2] as List<Task>;
      final allActivityLogs = results[3] as List<ActivityLog>;
      final allAlertRecords = results[4] as List<AlertRecord>;
      final allPhotos = results[5] as List<BirdPhoto>;
      final allAvatars = results[6] as List<BirdAvatar>;
      debugPrint(
          '[ExportSvc] 关联数据查询完成: weights=${allWeights.length}, meds=${allMedications.length}, tasks=${allTasks.length}, logs=${allActivityLogs.length}, alerts=${allAlertRecords.length}, photos=${allPhotos.length}, avatars=${allAvatars.length} (${sw.elapsedMilliseconds}ms)');

      debugPrint('[ExportSvc] 查询 breedingPairs...');
      final allPairs = await (db.select(db.breedingPairs)).get();
      final exportPairs = allPairs
          .where((p) =>
              birdIdSet.contains(p.maleBirdId) &&
              birdIdSet.contains(p.femaleBirdId))
          .toList();
      debugPrint(
          '[ExportSvc] breedingPairs: ${allPairs.length} total, ${exportPairs.length} exported');

      final pairIds = exportPairs.map((p) => p.id).toSet();
      final allBreedingRecords = pairIds.isNotEmpty
          ? await (db.select(db.breedingRecords)
                ..where((t) => t.pairId.isIn(pairIds)))
              .get()
          : <BreedingRecord>[];
      final recordIds = allBreedingRecords.map((r) => r.id).toSet();
      final allEggs = recordIds.isNotEmpty
          ? await (db.select(db.eggs)
                ..where((t) => t.breedingRecordId.isIn(recordIds)))
              .get()
          : <Egg>[];
      final allMatingEvents = recordIds.isNotEmpty
          ? await (db.select(db.matingEvents)
                ..where((t) => t.breedingRecordId.isIn(recordIds)))
              .get()
          : <MatingEvent>[];
      debugPrint(
          '[ExportSvc] breedingRecords: ${allBreedingRecords.length}, eggs: ${allEggs.length}, matingEvents: ${allMatingEvents.length}');

      final birdIdToUuid = {
        for (final b in birdsWithDetails) b.bird.id: b.bird.uuid
      };
      final pairIdToUuid = {for (final p in exportPairs) p.id: p.uuid};
      final recordIdToUuid = {for (final r in allBreedingRecords) r.id: r.uuid};

      // ── 预构建 Map: birdId → List<T>，O(1) 查找替代 O(n) 扫描 ──
      debugPrint('[ExportSvc] 预分组关联数据...');
      final weightsByBird = _groupById(allWeights, (w) => w.birdId);
      final medsByBird = _groupById(allMedications, (m) => m.birdId);
      final tasksByBird = _groupById(allTasks, (t) => t.birdId);
      final logsByBird = _groupById(allActivityLogs, (a) => a.birdId);
      final alertsByBird = _groupById(allAlertRecords, (a) => a.birdId);
      final photosByBird = _groupById(allPhotos, (p) => p.birdId);
      final avatarsByBird = _groupById(allAvatars, (a) => a.birdId);

      debugPrint('[ExportSvc] 构建 dataJson... (${sw.elapsedMilliseconds}ms)');
      final dataJson = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'birds': birdsWithDetails.map((BirdWithDetails bwd) {
          final bid = bwd.bird.id;
          return {
            'bird': _birdToJson(bwd.bird),
            'species': _speciesToJson(bwd.species),
            'roomUuid': bwd.room?.uuid,
            'enclosureUuid': bwd.enclosure?.uuid,
            'weights': (weightsByBird[bid] ?? []).map(_weightToJson).toList(),
            'medications':
                (medsByBird[bid] ?? []).map(_medicationToJson).toList(),
            'tasks': (tasksByBird[bid] ?? []).map(_taskToJson).toList(),
            'activityLogs':
                (logsByBird[bid] ?? []).map(_activityLogToJson).toList(),
            'alertRecords':
                (alertsByBird[bid] ?? []).map(_alertRecordToJson).toList(),
            'galleryPhotos':
                (photosByBird[bid] ?? []).map(_birdPhotoToJson).toList(),
            'avatar':
                (avatarsByBird[bid] ?? []).map(_birdAvatarToJson).firstOrNull,
          };
        }).toList(),
        'breedingPairs': exportPairs
            .map((bp) => _breedingPairToJson(bp, birdIdToUuid))
            .toList(),
        'breedingRecords': allBreedingRecords
            .map((br) => _breedingRecordToJson(br, pairIdToUuid))
            .toList(),
        'eggs': allEggs
            .map((e) => _eggToJson(e, recordIdToUuid, birdIdToUuid))
            .toList(),
        'matingEvents': allMatingEvents
            .map((me) => _matingEventToJson(me, recordIdToUuid))
            .toList(),
      };
      debugPrint('[ExportSvc] dataJson 构建完成 (${sw.elapsedMilliseconds}ms)');

      // 收集照片源路径（O(1) map lookup）
      final photoSrcPaths = <String>[];
      final photoBirdUuids = <String>[];
      for (final bwd in birdsWithDetails) {
        final birdUuid = bwd.bird.uuid;
        final birdPhotos = photosByBird[bwd.bird.id] ?? [];
        for (final photo in birdPhotos) {
          photoSrcPaths.add(photo.filePath);
          photoBirdUuids.add(birdUuid);
          if (photo.videoFilePath != null) {
            photoSrcPaths.add(photo.videoFilePath!);
            photoBirdUuids.add(birdUuid);
          }
        }
        final avatar = (avatarsByBird[bwd.bird.id] ?? []).firstOrNull;
        if (avatar != null) {
          photoSrcPaths.add(avatar.filePath);
          photoBirdUuids.add(birdUuid);
        }
      }
      debugPrint('[ExportSvc] 照片路径收集: ${photoSrcPaths.length} 个文件');

      final storageBaseDir = _storage.baseDir;

      // ── 2. jsonEncode + isolate ──
      debugPrint('[ExportSvc] jsonEncode dataJson...');
      final dataJsonStr = jsonEncode(dataJson);
      debugPrint(
          '[ExportSvc] jsonEncode 完成: ${dataJsonStr.length} 字符 (${sw.elapsedMilliseconds}ms)');

      debugPrint('[ExportSvc] 启动 Isolate.run()...');
      final exportPath = await _runPackZip(
        dataJsonStr,
        photoSrcPaths,
        photoBirdUuids,
        storageBaseDir,
      );
      debugPrint(
          '[ExportSvc] Isolate.run() 返回: ${exportPath ?? "null"} (${sw.elapsedMilliseconds}ms)');

      if (exportPath == null) {
        debugPrint('[ExportSvc] 导出失败，isolate 返回 null');
        return null;
      }
      debugPrint(
          '[ExportSvc] ===== 导出完成: $exportPath (${sw.elapsedMilliseconds}ms) =====');
      return File(exportPath);
    } catch (e, st) {
      debugPrint('[ExportSvc] 异常: $e');
      debugPrint('[ExportSvc] 堆栈: $st');
      return null;
    }
  }

  // ── O(n+m) 分组辅助 ──
  static Map<int, List<T>> _groupById<T>(
      List<T> items, int? Function(T) getId) {
    final map = <int, List<T>>{};
    for (final item in items) {
      final id = getId(item);
      if (id != null) (map[id] ??= []).add(item);
    }
    return map;
  }

  /// Narrow-scope trampoline: only 4 sendable params in lexical scope,
  /// so the Isolate.run closure won't capture [db] or other locals.
  static Future<String?> _runPackZip(
    String dataJsonStr,
    List<String> photoSrcPaths,
    List<String> photoBirdUuids,
    String storageBaseDir,
  ) {
    return Isolate.run(() => _packZip(
          dataJsonStr,
          photoSrcPaths,
          photoBirdUuids,
          storageBaseDir,
        ));
  }

  // ── 序列化 helpers ──

  Map<String, dynamic> _birdToJson(Bird b) => {
        'uuid': b.uuid,
        'name': b.name,
        'ringNumber': b.ringNumber,
        'birthDate': b.birthDate.toIso8601String(),
        'gender': b.gender,
        'sortOrder': b.sortOrder,
        'weighIntervalDays': b.weighIntervalDays,
        'manualBaselineG': b.manualBaselineG,
        'weaningOverride': b.weaningOverride,
        'status': b.status,
        'notes': b.notes,
        'createdAt': b.createdAt.toIso8601String(),
        'updatedAt': b.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _speciesToJson(Specy s) => {
        'uuid': s.uuid,
        'name': s.name,
        'nestlingEndDays': s.nestlingEndDays,
        'juvenileEndDays': s.juvenileEndDays,
        'nestlingWeighIntervalDays': s.nestlingWeighIntervalDays,
        'juvenileWeighIntervalDays': s.juvenileWeighIntervalDays,
        'adultWeighIntervalDays': s.adultWeighIntervalDays,
      };

  Map<String, dynamic> _weightToJson(Weight w) => {
        'uuid': w.uuid,
        'weightG': w.weightG,
        'recordedAt': w.recordedAt.toIso8601String(),
        'recordedBy': w.recordedBy,
        'isFasting': w.isFasting,
        'notes': w.notes,
        'createdAt': w.createdAt.toIso8601String(),
        'updatedAt': w.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _medicationToJson(Medication m) => {
        'uuid': m.uuid,
        'drugLibraryId': m.drugLibraryId,
        'formulationId': m.formulationId,
        'diseaseCatalogId': m.diseaseCatalogId,
        'calculatedDosage': m.calculatedDosage,
        'manualDosage': m.manualDosage,
        'timesPerDay': m.timesPerDay,
        'startDate': m.startDate.toIso8601String(),
        'endDate': m.endDate?.toIso8601String(),
        'notes': m.notes,
        'active': m.active,
        'stopReason': m.stopReason,
        'actualStopDate': m.actualStopDate?.toIso8601String(),
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _taskToJson(Task t) => {
        'uuid': t.uuid,
        'roomId': t.roomId,
        'assignedUserId': t.assignedUserId,
        'taskType': t.taskType,
        'dueDate': t.dueDate.toIso8601String(),
        'deadline': t.deadline?.toIso8601String(),
        'status': t.status,
        'completedAt': t.completedAt?.toIso8601String(),
        'completedBy': t.completedBy,
        'metadata': t.metadata,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _activityLogToJson(ActivityLog a) => {
        'uuid': a.uuid,
        'pluginId': a.pluginId,
        'actionType': a.actionType,
        'summary': a.summary,
        'details': a.details,
        'relatedTaskId': a.relatedTaskId,
        'operatedBy': a.operatedBy,
        'operatedAt': a.operatedAt.toIso8601String(),
        'createdAt': a.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _alertRecordToJson(AlertRecord a) => {
        'uuid': a.uuid,
        'alertType': a.alertType,
        'description': a.description,
        'severity': a.severity,
        'isRead': a.isRead,
        'isResolved': a.isResolved,
        'resolvedAt': a.resolvedAt?.toIso8601String(),
        'createdAt': a.createdAt.toIso8601String(),
        'updatedAt': a.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _birdPhotoToJson(BirdPhoto ph) => {
        'fileName': p.basename(ph.filePath),
        'relativePath': ph.filePath,
        'sortOrder': ph.sortOrder,
        'mediaType': ph.mediaType,
        'videoFileName':
            ph.videoFilePath != null ? p.basename(ph.videoFilePath!) : null,
        'createdAt': ph.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _birdAvatarToJson(BirdAvatar a) => {
        'fileName': p.basename(a.filePath),
        'relativePath': a.filePath,
        'updatedAt': a.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _breedingPairToJson(
          BreedingPair bp, Map<int, String> birdIdToUuid) =>
      {
        'uuid': bp.uuid,
        'maleBirdUuid': birdIdToUuid[bp.maleBirdId],
        'femaleBirdUuid': birdIdToUuid[bp.femaleBirdId],
        'pairName': bp.pairName,
        'status': bp.status,
        'pairedDate': bp.pairedDate.toIso8601String(),
        'separatedDate': bp.separatedDate?.toIso8601String(),
        'notes': bp.notes,
        'createdAt': bp.createdAt.toIso8601String(),
        'updatedAt': bp.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _breedingRecordToJson(
          BreedingRecord br, Map<int, String> pairIdToUuid) =>
      {
        'uuid': br.uuid,
        'pairUuid': pairIdToUuid[br.pairId],
        'stage': br.stage,
        'startDate': br.startDate.toIso8601String(),
        'endDate': br.endDate?.toIso8601String(),
        'endReason': br.endReason,
        'notes': br.notes,
        'createdAt': br.createdAt.toIso8601String(),
        'updatedAt': br.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _eggToJson(Egg e, Map<int, String> recordIdToUuid,
          Map<int, String> birdIdToUuid) =>
      {
        'uuid': e.uuid,
        'breedingRecordUuid': recordIdToUuid[e.breedingRecordId],
        'laidDate': e.laidDate.toIso8601String(),
        'hatchDate': e.hatchDate?.toIso8601String(),
        'status': e.status,
        'chickBirdUuid':
            e.chickBirdId != null ? birdIdToUuid[e.chickBirdId] : null,
        'notes': e.notes,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _matingEventToJson(
          MatingEvent me, Map<int, String> recordIdToUuid) =>
      {
        'uuid': me.uuid,
        'breedingRecordUuid': recordIdToUuid[me.breedingRecordId],
        'observedDate': me.observedDate.toIso8601String(),
        'notes': me.notes,
        'createdAt': me.createdAt.toIso8601String(),
      };
}

// ── 后台 isolate：只接受基本类型 ──

/// 单文件处理结果（在 isolate 内使用，不可跨 isolate 传递）。
class _FileEntry {
  final String relPath;
  final String sha256;
  final ArchiveFile archiveFile;
  _FileEntry(this.relPath, this.sha256, this.archiveFile);
}

/// 处理单个文件：读取 → 算 SHA256 + 构建 ArchiveFile。无冗余磁盘写入。
Future<_FileEntry?> _processOneFile(
  String srcPath,
  String birdUuid,
  String storageBaseDir,
) async {
  try {
    final srcFile = File('$storageBaseDir/$srcPath');
    if (!await srcFile.exists()) {
      print('[Isolate]   跳过不存在的文件: $srcPath');
      return null;
    }
    final bytes = await srcFile.readAsBytes();
    final relPath = 'gallery/$birdUuid/${p.basename(srcPath)}';
    return _FileEntry(relPath, sha256.convert(bytes).toString(),
        ArchiveFile(relPath, bytes.length, bytes));
  } catch (e) {
    print('[Isolate]   处理失败: $srcPath — $e');
    return null;
  }
}

Future<String?> _packZip(
  String dataJsonStr,
  List<String> photoSrcPaths,
  List<String> photoBirdUuids,
  String storageBaseDir,
) async {
  // ── Memory budget (old vs new) ─────────────────────────────────────────────
  // OLD: Archive (all photos ~200MB) + ZipEncoder.encode output (~193MB)
  //      + spread-copy into output List<int> (~193MB) = ~600MB peak → OOM
  // NEW: One batch of photos in memory at a time (~56MB for batchSize=8),
  //      ZIP streamed to disk via ZipFileEncoder, final file assembled with
  //      IOSink.addStream — never loading the full ZIP into memory.
  //      Peak ≈ one batch + small metadata ≈ ~60MB.
  // ──────────────────────────────────────────────────────────────────────────
  try {
    print('[Isolate] _packZip 开始');
    print('[Isolate] dataJsonStr: ${dataJsonStr.length} 字符');
    print('[Isolate] photoSrcPaths: ${photoSrcPaths.length} 个文件');
    print('[Isolate] storageBaseDir: $storageBaseDir');

    final tempDir = await Directory.systemTemp.createTemp('wnbirds_export_');
    print('[Isolate] tempDir: ${tempDir.path}');
    try {
      final sw = Stopwatch()..start();

      final ts = DateTime.now().millisecondsSinceEpoch;
      // exportPath lives outside tempDir so it survives the finally cleanup.
      final exportPath =
          p.join(tempDir.parent.path, 'weightnest_birds_$ts.wnbirds');
      // tempZipPath lives inside tempDir — auto-deleted by finally.
      final tempZipPath = p.join(tempDir.path, 'wnbirds_zip.tmp');

      // ── Stream ZIP entries directly to disk ──
      // ZipFileEncoder compresses and flushes each entry to disk synchronously,
      // so photo bytes from the previous batch are eligible for GC before the
      // next batch is read.
      final encoder = ZipFileEncoder();
      encoder.create(tempZipPath);

      // data.json
      print('[Isolate] 写入 data.json...');
      final dataJsonBytes = utf8.encode(dataJsonStr);
      final manifest = <String, String>{};
      manifest['data.json'] = sha256.convert(dataJsonBytes).toString();
      encoder.addArchiveFile(
          ArchiveFile('data.json', dataJsonBytes.length, dataJsonBytes));

      // Photos — one batch at a time; each batch is compressed and on-disk
      // before the next batch's bytes are read into memory.
      print('[Isolate] 开始并行处理 ${photoSrcPaths.length} 个文件 (batchSize=8)...');
      const batchSize = 8;
      for (int i = 0; i < photoSrcPaths.length; i += batchSize) {
        final end = min(i + batchSize, photoSrcPaths.length);
        final batchFutures = <Future<_FileEntry?>>[];
        for (int j = i; j < end; j++) {
          batchFutures.add(_processOneFile(
            photoSrcPaths[j],
            photoBirdUuids[j],
            storageBaseDir,
          ));
        }
        final results = await Future.wait(batchFutures);
        for (final r in results) {
          if (r == null) continue;
          manifest[r.relPath] = r.sha256;
          // Compressed bytes written to disk; original photo bytes (r.archiveFile.content)
          // are eligible for GC once `results` goes out of scope after this loop.
          encoder.addArchiveFile(r.archiveFile);
        }
        // `results` reassigned on next iteration → previous batch's bytes freed.
      }
      print('[Isolate] 文件处理完成 (${sw.elapsedMilliseconds}ms)');

      // manifest.json
      print('[Isolate] 生成 manifest...');
      final manifestJson = jsonEncode({
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'files': manifest,
      });
      final manifestJsonBytes = utf8.encode(manifestJson);
      encoder.addArchiveFile(ArchiveFile(
          'manifest.json', manifestJsonBytes.length, manifestJsonBytes));
      // Finalise ZIP on disk (writes central directory — tiny, O(file count) not O(file size)).
      encoder.close();
      print(
          '[Isolate] manifest 完成: ${manifest.length} 个文件 (${sw.elapsedMilliseconds}ms)');

      final zipSize = await File(tempZipPath).length();
      print('[Isolate] ZIP 完成: $zipSize bytes (${sw.elapsedMilliseconds}ms)');

      // ── Assemble final file: 4-byte magic prefix + ZIP content ──
      // IOSink.addStream pipes chunks from disk without loading the full ZIP
      // into memory — peak cost here is one read chunk (~64KB), not 193MB.
      print('[Isolate] 写入输出文件: $exportPath');
      final exportFile = File(exportPath);
      await exportFile.writeAsBytes('WNBD'.codeUnits); // magic prefix (4 bytes)
      final sink = exportFile.openWrite(mode: FileMode.append);
      await sink.addStream(
          File(tempZipPath).openRead()); // stream, never fully in RAM
      await sink.flush();
      await sink.close();
      print('[Isolate] 写入输出文件完成 (${sw.elapsedMilliseconds}ms)');

      print('[Isolate] 完成!');
      return exportPath;
    } finally {
      // Deletes tempDir and everything inside it, including tempZipPath.
      await tempDir.delete(recursive: true);
      print('[Isolate] tempDir 已清理');
    }
  } catch (e, st) {
    print('[Isolate] 异常: $e');
    print('[Isolate] 堆栈: $st');
    return null;
  }
}
