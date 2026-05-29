import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Species, Users, Rooms, Birds, Weights, Tasks, AlertRecords, SyncQueue],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造器——内存数据库
  AppDatabase.test() : super(DatabaseConnection.fromExecutor(
    NativeDatabase.memory(),
  ));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 3) {
            // v2 → v3: add weigh interval columns
            await m.addColumn(species, species.nestlingWeighIntervalDays);
            await m.addColumn(species, species.juvenileWeighIntervalDays);
            await m.addColumn(birds, birds.weighIntervalDays);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'weight_nest.db');
  }
}
