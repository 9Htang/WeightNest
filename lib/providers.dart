import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/plugin_registry.dart';
import 'database/database.dart';
import 'repositories/bird_repository.dart';
import 'repositories/weight_repository.dart';
import 'repositories/room_repository.dart';
import 'repositories/enclosure_repository.dart';
import 'repositories/species_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/user_repository.dart';
import 'services/alert_service.dart';
import 'plugins/medication/medication_repository.dart';
import 'screens/worker/worker_screen.dart';

/// 数据库单例
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  pluginRegistry.setDatabase(db);
  return db;
});

/// 所有鹦鹉（含品种、房间）
final allBirdsProvider = FutureProvider<List<BirdWithDetails>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllWithDetails();
});

/// 所有鹦鹉的最新体重（批量查询，避免 N+1）
/// 复用 allBirdsProvider 结果，避免重复 JOIN 查询
final allLatestWeightsProvider = FutureProvider<Map<int, Weight?>>((ref) async {
  ref.watch(weightSavedProvider);
  final db = ref.watch(databaseProvider);
  final birds = await ref.watch(allBirdsProvider.future);
  if (birds.isEmpty) return {};
  return db.getLatestByBirds(birds.map((b) => b.bird.id).toList());
});

/// 某只鹦鹉的体重列表
final birdWeightsProvider =
    FutureProvider.family<List<Weight>, int>((ref, birdId) async {
  ref.watch(weightSavedProvider); // 监听保存通知，自动刷新
  final db = ref.watch(databaseProvider);
  return db.getByBird(birdId);
});

/// 某只鹦鹉的最新体重
final latestWeightProvider =
    FutureProvider.family<Weight?, int>((ref, birdId) async {
  ref.watch(weightSavedProvider);
  final db = ref.watch(databaseProvider);
  return db.getLatestByBird(birdId);
});

/// 所有房间
final allRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllRooms();
});

/// 所有品种
final allSpeciesProvider = FutureProvider<List<Specy>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllSpecies();
});

/// 今日任务（仅显示当前用户的任务）
final todayTasksProvider = FutureProvider<List<TaskWithBird>>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.generateTodayTasks();
  final worker = ref.watch(workerProvider);
  return db.getTodayTasks(worker.userId);
});

/// 逾期任务
final overdueTasksProvider = FutureProvider<List<TaskWithBird>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getOverdueTasks();
});

/// 首次启动预置默认品种
final initDefaultsProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);

  try {
    final existing = await db.getAllSpecies();
    if (existing.isEmpty) {
      await db.createSpecies('牡丹鹦鹉', nestlingEndDays: 45, juvenileEndDays: 120);
      await db.createSpecies('金太阳', nestlingEndDays: 45, juvenileEndDays: 120);
      await db.createSpecies('虎皮鹦鹉', nestlingEndDays: 45, juvenileEndDays: 120);
      await db.createSpecies('玄凤鹦鹉', nestlingEndDays: 45, juvenileEndDays: 120);
      await db.createSpecies('金刚鹦鹉', nestlingEndDays: 45, juvenileEndDays: 120);
    }
  } catch (_) {
    // 旧数据库 schema 可能不兼容，忽略
  }

  try {
    final users = await db.getAllUsers();
    if (users.isEmpty) {
      await db.createUser('admin', '管理员', '', role: 'admin');
    }
  } catch (_) {
    // 旧数据库 schema 可能不兼容，忽略
  }
});

/// 异常提醒详细列表（用于异常页面展示）
final alertListProvider = FutureProvider<List<AnomalyAlert>>((ref) async {
  final db = ref.watch(databaseProvider);
  final service = AlertService(db);
  return service.detectAll();
});

/// 异常提醒数量 — 从 alertListProvider 派生，避免重复计算
final alertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertListProvider).valueOrNull;
  return alerts?.length ?? 0;
});

/// 某房间的鹦鹉列表
final roomBirdsProvider = FutureProvider.family<List<BirdWithDetails>, int>((ref, roomId) async {
  final db = ref.watch(databaseProvider);
  return db.getByRoom(roomId);
});

// ── 容器（Enclosure）相关提供者 ──

/// 某房间的所有容器
final roomEnclosuresProvider =
    FutureProvider.family<List<Enclosure>, int>((ref, roomId) async {
  final db = ref.watch(databaseProvider);
  return db.getEnclosuresByRoom(roomId);
});

/// 某房间的所有容器及鸟数
final roomEnclosuresWithCountsProvider = FutureProvider.family<
    List<EnclosureWithCount>, int>((ref, roomId) async {
  final db = ref.watch(databaseProvider);
  return db.getByRoomWithCounts(roomId);
});

/// 某容器的鹦鹉列表
final enclosureBirdsProvider = FutureProvider.family<List<BirdWithDetails>, int>(
    (ref, enclosureId) async {
  final db = ref.watch(databaseProvider);
  return db.getByEnclosure(enclosureId);
});

/// 某房间是否有容器（用于决定点击房间后的行为）
final roomHasEnclosuresProvider =
    FutureProvider.family<bool, int>((ref, roomId) async {
  final enclosures = ref.watch(roomEnclosuresProvider(roomId));
  return enclosures.valueOrNull?.isNotEmpty ?? false;
});

/// 某只鹦鹉的活跃喂药方案
final medicationPlansProvider = FutureProvider.family<List<Medication>, int>((ref, birdId) async {
  final db = ref.watch(databaseProvider);
  return db.getMedicationsByBird(birdId);
});

/// 某只鹦鹉的今日喂药日志
final todayMedicationLogsProvider = FutureProvider.family<List<MedicationLogData>, int>((ref, birdId) async {
  final db = ref.watch(databaseProvider);
  return db.getTodayLogs(birdId);
});

/// 今日所有鸟的喂药日志（用于任务列表）
final todayAllMedicationLogsProvider = FutureProvider<List<MedicationLogData>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllTodayLogs();
});

/// 体重保存通知——用于触发图表刷新
final weightSavedProvider = StateProvider<int>((ref) => 0);

/// 插件开关通知——用于触发 UI 刷新（快捷操作、称重按钮等）
final pluginToggleVersionProvider = StateProvider<int>((ref) => 0);

/// 当前员工的房间（多房间支持）
final myRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final worker = ref.watch(workerProvider);
  final db = ref.watch(databaseProvider);
  if (!worker.isSelected) return [];
  return db.getByUser(worker.userId!);
});

