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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 → v2: 数据丢弃重来，删除旧表重建
          await m.deleteTable('sync_log');
          await m.createTable(syncQueue);
          // 为全部表加 uuid/updatedAt/deletedAt 列
          // 直接删库重建（数据丢弃）
          final tables = ['species', 'users', 'rooms', 'birds', 'weights', 'tasks', 'alert_records'];
          for (final t in tables) {
            await m.deleteTable(t);
          }
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'weight_nest.db');
  }
}
