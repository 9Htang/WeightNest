import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

/// 数据库实例（单例）
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 数据库是否已初始化（有数据）
final databaseReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final count = await db.birds.count().getSingle();
  return count > 0;
});
