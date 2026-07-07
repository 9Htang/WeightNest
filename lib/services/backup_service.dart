import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 备份文件扩展名
const backupExtension = 'wnbak';

/// 备份服务 — 创建和恢复应用数据备份
///
/// 备份内容：
/// - SQLite 数据库文件 (weight_nest_mvp.db, .db-wal, .db-shm)
/// - Gallery 目录（照片、头像）
///
/// 流程：复制文件 → SHA256 校验 → ZIP 压缩 → .wnbak
class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  /// 创建备份文件，返回文件路径
  ///
  /// 返回 null 表示备份失败
  Future<File?> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      debugPrint('createBackup: appDir=${appDir.path}');
      final tempDir = await Directory.systemTemp.createTemp('wnbackup_');
      debugPrint('createBackup: tempDir=${tempDir.path}');

      // 列出 appDir 中的所有文件（调试）
      final appDirListing = await appDir.list().toList();
      debugPrint(
          'createBackup: appDir contains ${appDirListing.length} entries:');
      for (final e in appDirListing) {
        debugPrint('  ${e.path}');
      }

      // 1. 复制数据库文件
      final dbFiles = <String>[
        'weight_nest_mvp.db.sqlite',
        'weight_nest_mvp.db.sqlite-wal',
        'weight_nest_mvp.db.sqlite-shm',
      ];
      for (final f in dbFiles) {
        final src = File(p.join(appDir.path, f));
        final exists = await src.exists();
        debugPrint('createBackup: $f exists=$exists (${src.path})');
        if (exists) {
          final dst = p.join(tempDir.path, f);
          await src.copy(dst);
          debugPrint(
              'createBackup: copied $f (${await File(dst).length()} bytes)');
        }
      }

      // 2. 复制 gallery 目录（递归）
      final galleryDir = Directory(p.join(appDir.path, 'gallery'));
      if (await galleryDir.exists()) {
        await _copyDirectory(
            galleryDir, Directory(p.join(tempDir.path, 'gallery')));
        debugPrint('createBackup: copied gallery/');
      } else {
        debugPrint('createBackup: gallery/ not found');
      }

      // 3. 生成 manifest（文件清单 + SHA256）
      await _buildManifest(tempDir);

      // 4. 压缩所有文件为 ZIP
      final zipData = await _zipDirectory(tempDir);
      debugPrint('createBackup: ZIP size = ${zipData.length} bytes');

      // 5. 组装备份文件：4 字节 magic + ZIP 数据
      final output = <int>[
        ...'WNBK'.codeUnits,
        ...zipData,
      ];

      // 6. 写入临时文件，供分享
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = p.join(
          tempDir.parent.path, 'weightnest_backup_$timestamp.$backupExtension');
      final backupFile = File(backupPath);
      await backupFile.writeAsBytes(output);

      // 7. 清理临时目录
      await tempDir.delete(recursive: true);

      return backupFile;
    } catch (e) {
      debugPrint('BackupService.createBackup error: $e');
      return null;
    }
  }

  /// 验证备份文件完整性
  Future<bool> verifyBackup(File file) async {
    try {
      debugPrint('verifyBackup: checking ${file.path}');
      final bytes = await file.readAsBytes();
      debugPrint('verifyBackup: read ${bytes.length} bytes');
      if (bytes.length < 5) {
        debugPrint('verifyBackup: too small (${bytes.length} < 5)');
        return false;
      }
      final magic = String.fromCharCodes(bytes.sublist(0, 4));
      debugPrint('verifyBackup: magic=$magic');
      if (magic != 'WNBK') {
        debugPrint('verifyBackup: bad magic');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('verifyBackup error: $e');
      return false;
    }
  }

  /// 从备份文件恢复数据
  ///
  /// 返回 true 表示恢复成功（需重启应用）
  Future<bool> restoreFrom(File backupFile) async {
    try {
      debugPrint('restoreFrom: start, file=${backupFile.path}');

      // 0. 验证 magic
      final valid = await verifyBackup(backupFile);
      if (!valid) {
        debugPrint('restoreFrom: magic check failed');
        return false;
      }
      debugPrint('restoreFrom: magic OK');

      final bytes = await backupFile.readAsBytes();
      debugPrint('restoreFrom: read ${bytes.length} bytes');

      // 1. 解析：4 字节 magic + ZIP 数据
      final zipData = bytes.sublist(4);
      debugPrint('restoreFrom: zipData=${zipData.length} bytes');

      // 2. 解压 ZIP 到临时目录
      final tempDir = await Directory.systemTemp.createTemp('wnrestore_');
      await _unzipToDir(zipData, tempDir);
      debugPrint('restoreFrom: unzipped to ${tempDir.path}');

      // 3. 验证 manifest
      final manifestOk = await _verifyManifest(tempDir);
      if (!manifestOk) {
        debugPrint('restoreFrom: manifest check failed');
        await tempDir.delete(recursive: true);
        return false;
      }
      debugPrint('restoreFrom: manifest OK');

      // 4. 替换文件
      final appDir = await getApplicationDocumentsDirectory();
      debugPrint('restoreFrom: appDir=${appDir.path}');

      // 4a. 替换数据库文件
      final dbFiles = <String>[
        'weight_nest_mvp.db.sqlite',
        'weight_nest_mvp.db.sqlite-wal',
        'weight_nest_mvp.db.sqlite-shm',
      ];
      for (final f in dbFiles) {
        final src = File(p.join(tempDir.path, f));
        final dst = File(p.join(appDir.path, f));
        if (await src.exists()) {
          // 先删除目标再复制，避免文件锁问题
          if (await dst.exists()) {
            try {
              await dst.delete();
            } catch (_) {}
          }
          await src.copy(dst.path);
          debugPrint('restoreFrom: replaced $f');
        } else {
          if (await dst.exists()) {
            await dst.delete();
            debugPrint('restoreFrom: deleted $f (not in backup)');
          }
        }
      }

      // 4b. 替换 gallery 目录
      final srcGallery = Directory(p.join(tempDir.path, 'gallery'));
      final dstGallery = Directory(p.join(appDir.path, 'gallery'));
      if (await dstGallery.exists()) {
        await dstGallery.delete(recursive: true);
        debugPrint('restoreFrom: deleted old gallery');
      }
      if (await srcGallery.exists()) {
        await _copyDirectory(srcGallery, dstGallery);
        debugPrint('restoreFrom: restored gallery');
      }

      // 5. 清理临时目录
      await tempDir.delete(recursive: true);
      debugPrint('restoreFrom: done, success');

      return true;
    } catch (e) {
      debugPrint('BackupService.restoreFrom error: $e');
      return false;
    }
  }

  /// 构建文件清单（相对路径 → SHA256）
  Future<Map<String, String>> _buildManifest(Directory dir) async {
    final manifest = <String, String>{};
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relPath = p.relative(entity.path, from: dir.path);
        final bytes = await entity.readAsBytes();
        final hash = sha256.convert(bytes).toString();
        manifest[relPath] = hash;
      }
    }
    // 写入 manifest.json
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    await manifestFile.writeAsString(jsonEncode({
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'files': manifest,
    }));
    return manifest;
  }

  /// 验证 manifest 中的文件校验和
  Future<bool> _verifyManifest(Directory dir) async {
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    if (!await manifestFile.exists()) return false;

    final manifestJson =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    final files = manifestJson['files'] as Map<String, dynamic>?;
    if (files == null) return false;

    for (final entry in files.entries) {
      final file = File(p.join(dir.path, entry.key));
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      if (hash != entry.value) return false;
    }
    return true;
  }

  /// 递归复制目录
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list()) {
      if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      } else if (entity is Directory) {
        await _copyDirectory(entity,
            Directory(p.join(destination.path, p.basename(entity.path))));
      }
    }
  }

  /// 将目录打包为 ZIP
  Future<List<int>> _zipDirectory(Directory dir) async {
    final archive = Archive();
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relPath = p.relative(entity.path, from: dir.path);
        final fileBytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relPath, fileBytes.length, fileBytes));
      }
    }
    return ZipEncoder().encode(archive) ?? [];
  }

  /// 解压 ZIP 到目录
  Future<void> _unzipToDir(List<int> zipData, Directory dir) async {
    final archive = ZipDecoder().decodeBytes(zipData);
    await dir.create(recursive: true);
    for (final file in archive) {
      if (file.isFile) {
        final content = file.content is List<int>
            ? file.content as List<int>
            : (file.content as dynamic).toList();
        final outFile = File(p.join(dir.path, file.name));
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(content);
      }
    }
  }

  void debugPrint(String message) {
    if (const bool.fromEnvironment('dart.vm.product')) return;
    // ignore: avoid_print
    print(message);
  }
}
