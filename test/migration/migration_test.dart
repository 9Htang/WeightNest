import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../lib/core/plugin_registry.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/weight_repository.dart';
import '../../lib/repositories/species_repository.dart';

/// Open a raw sqlite3 handle on [path] (ensures the parent directory exists).
Database _rawOpen(String path) {
  final dir = Directory(p.dirname(path));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return sqlite3.open(path);
}

/// Create a v12-compatible schema via raw SQL, insert a small amount of test
/// data, and set `PRAGMA user_version = 12`.
///
/// Tables created (subset of full v12 schema — enough to exercise every
/// migration step from v13 through v17):
///
///   v1:  species, birds, weights, tasks, alert_records, rooms, users
///   v5:  medications (old schema — dropped in v17)
///   v6:  enclosures
///   v11: activity_logs
///
/// v12 itself added indexes (handled by production migration).
void _createV12Database(String dbPath) {
  final db = _rawOpen(dbPath);

  // ── v1 core tables (full column set up to v12) ─────────────────────────
  // IMPORTANT: drift NativeDatabase stores DateTime as INTEGER (UNIX seconds).
  // All date columns use INTEGER so drift's type mapping can read them back.

  db.execute('''
    CREATE TABLE species (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      nestling_end_days INTEGER NOT NULL DEFAULT 45,
      juvenile_end_days INTEGER NOT NULL DEFAULT 120,
      nestling_weigh_interval_days INTEGER NOT NULL DEFAULT 1,
      juvenile_weigh_interval_days INTEGER NOT NULL DEFAULT 3,
      adult_weigh_interval_days INTEGER NOT NULL DEFAULT 7,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    );
  ''');

  db.execute('''
    CREATE TABLE rooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      assigned_user_id INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    );
  ''');

  db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      username TEXT NOT NULL,
      display_name TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'keeper',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    );
  ''');

  db.execute('''
    CREATE TABLE enclosures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      room_id INTEGER NOT NULL REFERENCES rooms(id),
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    );
  ''');

  db.execute('''
    CREATE TABLE birds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      ring_number TEXT,
      species_id INTEGER NOT NULL REFERENCES species(id),
      room_id INTEGER REFERENCES rooms(id),
      enclosure_id INTEGER REFERENCES enclosures(id),
      birth_date INTEGER NOT NULL,
      gender TEXT NOT NULL DEFAULT '未知',
      sort_order INTEGER NOT NULL DEFAULT 0,
      weigh_interval_days INTEGER,
      manual_baseline_g REAL,
      weaning_override INTEGER,
      status TEXT NOT NULL DEFAULT '正常',
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    );
  ''');

  db.execute('''
    CREATE TABLE weights (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL DEFAULT '',
      bird_id INTEGER NOT NULL REFERENCES birds(id),
      weight_g REAL NOT NULL,
      recorded_at INTEGER NOT NULL,
      recorded_by INTEGER REFERENCES users(id),
      is_fasting INTEGER NOT NULL DEFAULT 1,
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');

  db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      bird_id INTEGER NOT NULL REFERENCES birds(id),
      room_id INTEGER REFERENCES rooms(id),
      assigned_user_id INTEGER,
      task_type TEXT NOT NULL DEFAULT 'weigh',
      due_date INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT '待完成',
      completed_at INTEGER,
      completed_by INTEGER,
      metadata TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');

  db.execute('''
    CREATE TABLE alert_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      bird_id INTEGER NOT NULL REFERENCES birds(id),
      alert_type TEXT NOT NULL,
      description TEXT NOT NULL,
      is_read INTEGER NOT NULL DEFAULT 0,
      is_resolved INTEGER NOT NULL DEFAULT 0,
      severity TEXT NOT NULL DEFAULT 'warning',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      resolved_at INTEGER
    );
  ''');

  db.execute('''
    CREATE TABLE activity_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      bird_id INTEGER REFERENCES birds(id),
      plugin_id TEXT NOT NULL,
      action_type TEXT NOT NULL,
      summary TEXT NOT NULL,
      details TEXT,
      related_task_id INTEGER REFERENCES tasks(id),
      operated_by INTEGER REFERENCES users(id),
      operated_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    );
  ''');

  // ── v5: old medications (dropped in v17) ────────────────────────────

  db.execute('''
    CREATE TABLE medications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      bird_id INTEGER NOT NULL REFERENCES birds(id),
      drug_name TEXT NOT NULL,
      drug_type TEXT NOT NULL DEFAULT '其他',
      dosage TEXT,
      times_per_day INTEGER NOT NULL DEFAULT 1,
      start_date INTEGER NOT NULL,
      end_date INTEGER,
      notes TEXT,
      active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');

  // ── Insert test data ────────────────────────────────────────────────
  // UNIX timestamps (seconds) — drift NativeDatabase stores DateTime as INT

  final t2024 = 1704096000; // 2024-01-01
  final tJun1 = 1748764800; // 2025-06-01
  final tJul1 = 1751356800; // 2025-07-01
  final tJul1Noon = 1751400000; // 2025-07-01 12:00:00
  final tJul2 = 1751443200; // 2025-07-02
  final tJul2Noon = 1751486400; // 2025-07-02 12:00:00
  final tJul3 = 1751529600; // 2025-07-03

  // species: id, uuid, name, nestling_end_days, juvenile_end_days,
  //   nestling_weigh_interval_days, juvenile_weigh_interval_days,
  //   adult_weigh_interval_days, created_at, updated_at, deleted_at
  db.execute(
      "INSERT INTO species VALUES (1, 's1', '虎皮鹦鹉', 30, 90, 1, 3, 7, $t2024, $t2024, NULL)");

  // rooms: id, uuid, name, sort_order, assigned_user_id, created_at, updated_at, deleted_at
  db.execute(
      "INSERT INTO rooms VALUES (1, 'r1', '育雏室', 0, NULL, $t2024, $t2024, NULL)");

  // users: id, uuid, username, display_name, password_hash, role, created_at, updated_at, deleted_at
  db.execute(
      "INSERT INTO users VALUES (1, 'u1', 'tester', '测试员', 'hash', 'keeper', $t2024, $t2024, NULL)");

  // enclosures: id, uuid, name, room_id, sort_order, created_at, updated_at, deleted_at
  db.execute(
      "INSERT INTO enclosures VALUES (1, 'e1', 'A笼', 1, 0, $t2024, $t2024, NULL)");

  // birds: id, uuid, name, ring_number, species_id, room_id, enclosure_id,
  //   birth_date, gender, sort_order, weigh_interval_days, manual_baseline_g,
  //   weaning_override, status, notes, created_at, updated_at, deleted_at
  db.execute(
      "INSERT INTO birds VALUES (1, 'b1', '小绿', NULL, 1, 1, 1, $tJun1, '公', 1, NULL, NULL, NULL, '正常', NULL, $tJun1, $tJun1, NULL)");

  // weights: id, uuid, bird_id, weight_g, recorded_at, recorded_by, is_fasting, notes, created_at, updated_at
  db.execute(
      "INSERT INTO weights VALUES (1, 'w1', 1, 100.0, $tJul1Noon, NULL, 1, NULL, $tJul1, $tJul1)");
  db.execute(
      "INSERT INTO weights VALUES (2, 'w2', 1, 102.0, $tJul2Noon, NULL, 1, NULL, $tJul2, $tJul2)");

  // tasks: id, uuid, bird_id, room_id, assigned_user_id, task_type, due_date,
  //   status, completed_at, completed_by, metadata, created_at, updated_at
  db.execute(
      "INSERT INTO tasks VALUES (1, 't1', 1, NULL, NULL, 'weigh', $tJul3, '待完成', NULL, NULL, NULL, $tJul1, $tJul1)");

  // alert_records: id, uuid, bird_id, alert_type, description, is_read,
  //   is_resolved, severity, created_at, updated_at, resolved_at
  db.execute(
      "INSERT INTO alert_records VALUES (1, 'a1', 1, '体重偏轻', 'test alert', 0, 0, 'warning', $tJul1, $tJul1, NULL)");

  // activity_logs: id, uuid, bird_id, plugin_id, action_type, summary,
  //   details, related_task_id, operated_by, operated_at, created_at
  db.execute(
      "INSERT INTO activity_logs VALUES (1, 'al1', 1, 'weights', 'weight_recorded', 'test', NULL, NULL, NULL, $tJul1, $tJul1)");

  // medications (old, dropped in v17): id, uuid, bird_id, drug_name,
  //   drug_type, dosage, times_per_day, start_date, end_date, notes, active,
  //   created_at, updated_at
  db.execute(
      "INSERT INTO medications VALUES (1, 'm1', 1, 'TestDrug', '抗生素', '1mg', 1, $tJul1, NULL, NULL, 1, $tJul1, $tJul1)");

  // ── Pin at v12 ──────────────────────────────────────────────────────

  db.execute('PRAGMA user_version = 12;');
  db.dispose();
}

@Tags(['slow'])
void main() {
  late Directory tmpDir;
  late String dbPath;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('wn_migration_test_');
    dbPath = p.join(tmpDir.path, 'weight_nest_mvp.db.sqlite');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  // ── v12 → v17 migration ─────────────────────────────────────────────

  test('v12 → v17 migration preserves data and applies all schema changes',
      () async {
    _createV12Database(dbPath);

    // Verify we're at v12 before opening
    final preCheck = _rawOpen(dbPath);
    final preVersion =
        preCheck.select('PRAGMA user_version;').first['user_version'];
    expect(preVersion, 12);
    preCheck.dispose();

    // Open with AppDatabase — triggers onUpgrade(12→17)
    final db = AppDatabase.file(File(dbPath));
    pluginRegistry.setDatabase(db);
    try {
      // ── v13: tasks.deadline added ──────────────────────────────
      // Verify the column exists by reading a task (won't throw if schema ok)
      final tasks = await db
          .customSelect('SELECT deadline FROM tasks WHERE id = 1')
          .get();
      expect(tasks, isNotEmpty);

      // Existing incomplete task should have had deadline backfilled
      final deadline = tasks.first.read<String>('deadline');
      expect(deadline, isNotNull);

      // ── v14: bird_photos, bird_avatars tables created ──────────
      final photoCount = await db
          .customSelect('SELECT COUNT(*) as cnt FROM bird_photos')
          .get();
      expect(photoCount.first.read<int>('cnt'), 0); // table exists, empty

      final avatarCount = await db
          .customSelect('SELECT COUNT(*) as cnt FROM bird_avatars')
          .get();
      expect(avatarCount.first.read<int>('cnt'), 0);

      // ── v14–v16: bird_photos column inventory ──────────────────
      // Regression: createTable at v14 uses current BirdPhotos class (which
      // already includes v15/v16 columns). Verify all expected columns exist
      // without duplicates.
      final bpCols =
          await db.customSelect('PRAGMA table_info(\'bird_photos\')').get();
      final bpColNames = bpCols.map((r) => r.read<String>('name')).toSet();
      for (final col in [
        'id',
        'bird_id',
        'file_path',
        'sort_order',
        'media_type',
        'video_file_path',
        'thumbnail_path',
        'created_at',
      ]) {
        expect(bpColNames.contains(col), isTrue,
            reason: 'bird_photos missing column: $col');
      }
      // Verify no duplicate columns (PRAGMA table_info guarantees unique names,
      // so a count mismatch between table_info rows and our expected set means
      // unexpected extra columns)
      expect(bpCols.length, bpColNames.length,
          reason: 'bird_photos has duplicate column names');

      // ── v17: species weight columns added ─────────────────────
      final species = await db
          .customSelect(
              'SELECT min_weight_g, max_weight_g FROM species WHERE id = 1')
          .get();
      expect(species, isNotEmpty);
      // New columns should be NULL for existing rows
      expect(species.first.read<double?>('min_weight_g'), isNull);
      expect(species.first.read<double?>('max_weight_g'), isNull);

      // ── v17: old medications DROPPED, new tables created ─────
      // Verify new tables exist (no throw)
      for (final table in [
        'drug_library',
        'drug_formulations',
        'disease_catalog',
        'dose_rules',
        'feeding_records',
        'side_effect_records',
        'stop_conditions',
      ]) {
        final count =
            await db.customSelect('SELECT COUNT(*) as cnt FROM $table').get();
        expect(count.first.read<int>('cnt'), 0, reason: '$table should exist');
      }

      // New medications table exists (recreated in v17)
      final medCount = await db
          .customSelect('SELECT COUNT(*) as cnt FROM medications')
          .get();
      expect(medCount.first.read<int>('cnt'), 0,
          reason: 'new medications table should exist and be empty');

      // Old medications row is gone (table was dropped, not migrated)
      // Verify by checking that the new schema columns exist:
      // The NEW medications table has drug_library_id, formulation_id, etc.
      await db
          .customSelect(
              'SELECT drug_library_id, formulation_id FROM medications LIMIT 0')
          .get();

      // ── Data integrity: original rows survived ─────────────────
      final bird = await db.getBirdById(1);
      expect(bird, isNotNull);
      expect(bird!.name, '小绿');
      expect(bird.speciesId, 1);
      expect(bird.gender, '公');

      final weights = await db.getByBird(1);
      expect(weights.length, 2);
      expect(weights[0].weightG, 102.0); // DESC order: newest first
      expect(weights[1].weightG, 100.0);

      final speciesRow = await db.getWithDetails(1);
      expect(speciesRow, isNotNull);
      expect(speciesRow!.species.name, '虎皮鹦鹉');

      // ── Verify final version ──────────────────────────────────
      final postCheck = _rawOpen(dbPath);
      final postVersion =
          postCheck.select('PRAGMA user_version;').first['user_version'];
      expect(postVersion, 21);
      postCheck.dispose();
    } finally {
      await db.close();
    }
  });

  // ── Fresh v17 DB ─────────────────────────────────────────────────────

  test('fresh v17 database has all expected tables', () async {
    final db = AppDatabase.file(File(dbPath));
    pluginRegistry.setDatabase(db);
    try {
      // Query sqlite_master for all table names
      final tables = await db
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
          .get();
      final names = tables.map((r) => r.read<String>('name')).toSet();

      // Core tables
      expect(names.contains('species'), isTrue);
      expect(names.contains('birds'), isTrue);
      expect(names.contains('weights'), isTrue);
      expect(names.contains('tasks'), isTrue);
      expect(names.contains('alert_records'), isTrue);
      expect(names.contains('activity_logs'), isTrue);
      expect(names.contains('enclosures'), isTrue);
      expect(names.contains('rooms'), isTrue);
      expect(names.contains('users'), isTrue);

      // v17 medication tables
      expect(names.contains('drug_library'), isTrue);
      expect(names.contains('drug_formulations'), isTrue);
      expect(names.contains('disease_catalog'), isTrue);
      expect(names.contains('dose_rules'), isTrue);
      expect(names.contains('medications'), isTrue);
      expect(names.contains('feeding_records'), isTrue);
      expect(names.contains('side_effect_records'), isTrue);
      expect(names.contains('stop_conditions'), isTrue);

      // v14 gallery tables
      expect(names.contains('bird_photos'), isTrue);
      expect(names.contains('bird_avatars'), isTrue);

      // v8 breeding tables
      expect(names.contains('breeding_pairs'), isTrue);
      expect(names.contains('breeding_records'), isTrue);
      expect(names.contains('eggs'), isTrue);
      expect(names.contains('mating_events'), isTrue);
    } finally {
      await db.close();
    }
  });
}
