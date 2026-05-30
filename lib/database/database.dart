import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Species, Users, Rooms, Birds, Weights, Tasks, AlertRecords, SyncQueue, Medications, MedicationLogs],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造器——内存数据库
  AppDatabase.test() : super(DatabaseConnection(NativeDatabase.memory()));

  @override
  int get schemaVersion => 5;

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
            await m.createTable(medicationLogs);
          }
        },
      );

  Future<void> _createIndexes(Migrator m) async {
    await m.createIndex(Index('weights',
        'CREATE INDEX IF NOT EXISTS idx_weights_bird_date ON weights(bird_id, recorded_at DESC)'));
    await m.createIndex(Index('tasks',
        'CREATE INDEX IF NOT EXISTS idx_tasks_due_status ON tasks(due_date, status)'));
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'weight_nest.db');
  }
}
