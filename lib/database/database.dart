import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import '../plugins/gallery/gallery_tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Species, Users, Rooms, Enclosures, Birds, Weights, Tasks, AlertRecords, SyncQueue, Medications, BreedingPairs, BreedingRecords, Eggs, MatingEvents, ActivityLogs, BirdPhotos, BirdAvatars],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造器——内存数据库
  AppDatabase.test() : super(DatabaseConnection(NativeDatabase.memory()));

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 3) {
            // v2 → v3: add weigh interval columns
            await m.addColumn(species, species.nestlingWeighIntervalDays);
            await m.addColumn(species, species.juvenileWeighIntervalDays);
            await m.addColumn(birds, birds.weighIntervalDays);
          }
          if (from < 4) await _createIndexes(m);
          if (from < 5) {
            // v4 → v5: medication tracking tables
            await m.createTable(medications);
          }
          if (from < 6) {
            // v5 → v6: enclosures (containers within rooms)
            await m.createTable(enclosures);
            await m.addColumn(birds, birds.enclosureId);
          }
          if (from < 7) {
            // v6 → v7: baseline weight + weaning override
            await m.addColumn(birds, birds.manualBaselineG);
            await m.addColumn(birds, birds.weaningOverride);
          }
          if (from < 8) {
            // v7 → v8: breeding plugin tables
            await m.createTable(breedingPairs);
            await m.createTable(breedingRecords);
            await m.createTable(eggs);
            await m.createTable(matingEvents);
          }
          if (from < 9) {
            // v8 → v9: tasks.taskType + metadata; drop medicationLogs
            await m.addColumn(tasks, tasks.taskType);
            await m.addColumn(tasks, tasks.metadata);
            await m.deleteTable('medication_logs');
          }
          if (from < 10) {
            // v9 → v10: alert_records.severity
            await m.addColumn(alertRecords, alertRecords.severity);
          }
          if (from < 11) {
            // v10 → v11: unified activity log table
            await m.createTable(activityLogs);
            await m.createIndex(Index('activity_logs',
                'CREATE INDEX IF NOT EXISTS idx_activity_logs_bird_time ON activity_logs(bird_id, operated_at DESC)'));
          }
          if (from < 12) {
            // v11 → v12: perf indexes for filtered lookups
            await m.createIndex(Index('birds',
                'CREATE INDEX IF NOT EXISTS idx_birds_room ON birds(room_id)'));
            await m.createIndex(Index('birds',
                'CREATE INDEX IF NOT EXISTS idx_birds_enclosure ON birds(enclosure_id)'));
            await m.createIndex(Index('alert_records',
                'CREATE INDEX IF NOT EXISTS idx_alert_records_lookup ON alert_records(bird_id, alert_type, is_read, created_at)'));
            await m.createIndex(Index('medications',
                'CREATE INDEX IF NOT EXISTS idx_medications_bird ON medications(bird_id)'));
          }
          if (from < 13) {
            // v12 → v13: tasks.deadline — 逾期截止时间，生成时算好写入
            await m.addColumn(tasks, tasks.deadline);
            // 存量未完成任务用 dueDate 回填 deadline，防止永久卡在"待完成"
            await customStatement(
              "UPDATE tasks SET deadline = due_date WHERE deadline IS NULL AND status IN ('待完成', '逾期')");
          }
          if (from < 14) {
            // v13 → v14: gallery plugin — bird photos & avatars
            await m.createTable(birdPhotos);
            await m.createTable(birdAvatars);
            await m.createIndex(Index('bird_photos',
                'CREATE INDEX IF NOT EXISTS idx_bird_photos_bird ON bird_photos(bird_id, sort_order ASC)'));
          }
        },
      );

  Future<void> _createIndexes(Migrator m) async {
    await m.createIndex(Index('weights',
        'CREATE INDEX IF NOT EXISTS idx_weights_bird_date ON weights(bird_id, recorded_at DESC)'));
    await m.createIndex(Index('tasks',
        'CREATE INDEX IF NOT EXISTS idx_tasks_due_status ON tasks(due_date, status)'));
    await m.createIndex(Index('activity_logs',
        'CREATE INDEX IF NOT EXISTS idx_activity_logs_bird_time ON activity_logs(bird_id, operated_at DESC)'));
    // v12: perf indexes for filtered lookups (getByRoom / getByEnclosure / alert dedup / medication)
    await m.createIndex(Index('birds',
        'CREATE INDEX IF NOT EXISTS idx_birds_room ON birds(room_id)'));
    await m.createIndex(Index('birds',
        'CREATE INDEX IF NOT EXISTS idx_birds_enclosure ON birds(enclosure_id)'));
    await m.createIndex(Index('alert_records',
        'CREATE INDEX IF NOT EXISTS idx_alert_records_lookup ON alert_records(bird_id, alert_type, is_read, created_at)'));
    await m.createIndex(Index('medications',
        'CREATE INDEX IF NOT EXISTS idx_medications_bird ON medications(bird_id)'));
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'weight_nest_mvp.db');
  }
}
