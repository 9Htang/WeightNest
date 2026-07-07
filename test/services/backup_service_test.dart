import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../lib/core/plugin_registry.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/weight_repository.dart';
import '../../lib/repositories/species_repository.dart';

/// Fake [PathProviderPlatform] that returns a controlled app documents path.
class FakePathProviderPlatform extends PathProviderPlatform {
  final String appPath;

  FakePathProviderPlatform(this.appPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => appPath;
}

@Tags(['slow'])
void main() {
  late Directory fakeAppDir;
  late BackupService backupService;
  late FakePathProviderPlatform fakePlatform;
  late PathProviderPlatform _originalPlatform;

  /// Create a file-based DB with one bird and a few weight records, then close.
  Future<void> createPopulatedDb(Directory appDir) async {
    final dbFile = File(p.join(appDir.path, 'weight_nest_mvp.db.sqlite'));
    final db = AppDatabase.file(dbFile);
    pluginRegistry.setDatabase(db);
    try {
      final species = await db.createSpecies('TestBudgie',
          nestlingEndDays: 30, juvenileEndDays: 90);
      final bird = await db.createBird(
        name: 'TestBird',
        speciesId: species.id,
        birthDate: DateTime(2025, 6, 1),
      );
      await db.addWeight(
        birdId: bird.id,
        weightG: 100.0,
        recordedAt: DateTime(2026, 1, 1, 12, 0),
      );
      await db.addWeight(
        birdId: bird.id,
        weightG: 102.0,
        recordedAt: DateTime(2026, 1, 2, 12, 0),
      );
      await db.addWeight(
        birdId: bird.id,
        weightG: 101.0,
        recordedAt: DateTime(2026, 1, 3, 12, 0),
      );
    } finally {
      await db.close();
    }
  }

  /// Return the count of weight rows in a restored DB.
  Future<int> readWeightCount(Directory appDir) async {
    final dbFile = File(p.join(appDir.path, 'weight_nest_mvp.db.sqlite'));
    if (!await dbFile.exists()) return 0;
    final db = AppDatabase.file(dbFile);
    pluginRegistry.setDatabase(db);
    try {
      final birds = await db.getAllWithDetails();
      if (birds.isEmpty) return 0;
      final weights = await db.getByBird(birds.first.bird.id);
      return weights.length;
    } finally {
      await db.close();
    }
  }

  setUp(() async {
    fakeAppDir = Directory.systemTemp.createTempSync('wn_test_appdir_');
    fakePlatform = FakePathProviderPlatform(fakeAppDir.path);
    _originalPlatform = PathProviderPlatform.instance;
    PathProviderPlatform.instance = fakePlatform;
    backupService = BackupService();
  });

  tearDown(() async {
    PathProviderPlatform.instance = _originalPlatform;
    if (fakeAppDir.existsSync()) {
      fakeAppDir.deleteSync(recursive: true);
    }
  });

  // ── Round-trip ──────────────────────────────────────────────────────────

  group('round trip', () {
    test('createBackup → restoreFrom preserves all data', () async {
      // 1. Create a populated file-based DB
      await createPopulatedDb(fakeAppDir);

      // Verify there are 3 weights before backup
      expect(await readWeightCount(fakeAppDir), 3);

      // 2. Create backup
      final backupFile = await backupService.createBackup();
      expect(backupFile, isNotNull);
      expect(await backupFile!.exists(), isTrue);

      // 3. Verify the backup
      final valid = await backupService.verifyBackup(backupFile);
      expect(valid, isTrue);

      // 4. Delete the original DB files
      final dbFiles = [
        'weight_nest_mvp.db.sqlite',
        'weight_nest_mvp.db.sqlite-wal',
        'weight_nest_mvp.db.sqlite-shm',
      ];
      for (final f in dbFiles) {
        final file = File(p.join(fakeAppDir.path, f));
        if (await file.exists()) await file.delete();
      }
      // Also clean gallery if exists
      final galleryDir = Directory(p.join(fakeAppDir.path, 'gallery'));
      if (await galleryDir.exists()) {
        await galleryDir.delete(recursive: true);
      }

      // 5. Restore
      final restored = await backupService.restoreFrom(backupFile);
      expect(restored, isTrue);

      // 6. Verify data survived
      expect(await readWeightCount(fakeAppDir), 3);

      // 7. Clean up backup file
      if (await backupFile.exists()) await backupFile.delete();
    });

    test('empty app dir → backup succeeds → restore works', () async {
      // No DB files at all — only gallery dir (which is empty)
      // createBackup should still produce a valid backup
      final backupFile = await backupService.createBackup();
      // May be null if no files to back up (depends on implementation)
      // If it succeeds, verify and restore should work
      if (backupFile != null) {
        expect(await backupService.verifyBackup(backupFile), isTrue);
        final restored = await backupService.restoreFrom(backupFile);
        expect(restored, isTrue);
        if (await backupFile.exists()) await backupFile.delete();
      }
    });
  });

  // ── Corrupt / tampered backups ───────────────────────────────────────────

  group('corrupt backup', () {
    test('bad magic → verifyBackup returns false', () async {
      final badFile = File(p.join(fakeAppDir.path, 'bad.wnbak'));
      await badFile.writeAsBytes([0xBA, 0xDB, 0xEE, 0xF0, 0x00]);
      expect(await backupService.verifyBackup(badFile), isFalse);
    });

    test('wrong magic → restoreFrom returns false', () async {
      final badFile = File(p.join(fakeAppDir.path, 'bad.wnbak'));
      await badFile.writeAsBytes([0xBA, 0xDB, 0xEE, 0xF0, 0x00]);
      expect(await backupService.restoreFrom(badFile), isFalse);
    });

    test('too-small file → verifyBackup returns false', () async {
      final tinyFile = File(p.join(fakeAppDir.path, 'tiny.wnbak'));
      await tinyFile.writeAsBytes([0x57, 0x4E]); // "WN" — too short
      expect(await backupService.verifyBackup(tinyFile), isFalse);
    });

    test('empty file → verifyBackup returns false', () async {
      final emptyFile = File(p.join(fakeAppDir.path, 'empty.wnbak'));
      await emptyFile.writeAsBytes([]);
      expect(await backupService.verifyBackup(emptyFile), isFalse);
    });

    test('garbage ZIP data after magic → restoreFrom returns false', () async {
      final badZip = File(p.join(fakeAppDir.path, 'badzip.wnbak'));
      final bytes = <int>[...'WNBK'.codeUnits, ...List.filled(100, 0xFF)];
      await badZip.writeAsBytes(bytes);
      // Should not crash; should return false gracefully
      final result = await backupService.restoreFrom(badZip);
      expect(result, isFalse);
    });
  });

  // ── Manifest tampering ───────────────────────────────────────────────────

  group('manifest integrity', () {
    test('restored data matches original after round-trip', () async {
      await createPopulatedDb(fakeAppDir);

      // Also create a gallery file to test multi-file backup
      final galleryDir = Directory(p.join(fakeAppDir.path, 'gallery'));
      await galleryDir.create(recursive: true);
      await File(p.join(galleryDir.path, 'test.jpg'))
          .writeAsBytes(List.filled(1024, 0xAB));

      final backupFile = await backupService.createBackup();
      expect(backupFile, isNotNull);

      // Nuke everything
      if (await galleryDir.exists()) await galleryDir.delete(recursive: true);
      final dbFile = File(p.join(fakeAppDir.path, 'weight_nest_mvp.db.sqlite'));
      if (await dbFile.exists()) await dbFile.delete();

      final restored = await backupService.restoreFrom(backupFile!);
      expect(restored, isTrue);

      // Gallery file should be back with correct content
      final restoredJpg = File(p.join(galleryDir.path, 'test.jpg'));
      expect(await restoredJpg.exists(), isTrue);
      expect(await restoredJpg.length(), 1024);
      expect(await restoredJpg.readAsBytes(), List.filled(1024, 0xAB));

      // DB data should be back
      expect(await readWeightCount(fakeAppDir), 3);

      if (await backupFile.exists()) await backupFile.delete();
    });
  });

  // ── Backup file format ───────────────────────────────────────────────────

  group('backup file format', () {
    test('backup file has .wnbak extension', () async {
      await createPopulatedDb(fakeAppDir);
      final backupFile = await backupService.createBackup();
      expect(backupFile, isNotNull);
      expect(p.extension(backupFile!.path), '.wnbak');
      if (await backupFile.exists()) await backupFile.delete();
    });

    test('backup file starts with WNBK magic', () async {
      await createPopulatedDb(fakeAppDir);
      final backupFile = await backupService.createBackup();
      expect(backupFile, isNotNull);
      final bytes = await backupFile!.readAsBytes();
      expect(bytes.length, greaterThanOrEqualTo(4));
      expect(String.fromCharCodes(bytes.take(4)), 'WNBK');
      if (await backupFile.exists()) await backupFile.delete();
    });

    test('backup file > 4 bytes (has ZIP payload)', () async {
      await createPopulatedDb(fakeAppDir);
      final backupFile = await backupService.createBackup();
      expect(backupFile, isNotNull);
      final bytes = await backupFile!.readAsBytes();
      expect(bytes.length, greaterThan(4));
      if (await backupFile.exists()) await backupFile.delete();
    });
  });

  // ── Multiple round-trips (idempotency) ───────────────────────────────────

  group('multiple round-trips', () {
    test('backup → restore → backup → restore works', () async {
      await createPopulatedDb(fakeAppDir);

      // First round-trip
      final backup1 = await backupService.createBackup();
      expect(backup1, isNotNull);

      // Delete DB
      final dbFile = File(p.join(fakeAppDir.path, 'weight_nest_mvp.db.sqlite'));
      if (await dbFile.exists()) await dbFile.delete();

      await backupService.restoreFrom(backup1!);
      expect(await readWeightCount(fakeAppDir), 3);
      if (await backup1.exists()) await backup1.delete();

      // Second round-trip
      final backup2 = await backupService.createBackup();
      expect(backup2, isNotNull);

      if (await dbFile.exists()) await dbFile.delete();
      await backupService.restoreFrom(backup2!);
      expect(await readWeightCount(fakeAppDir), 3);
      if (await backup2.exists()) await backup2.delete();
    });
  });
}
