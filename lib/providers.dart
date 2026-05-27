import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database.dart';
import 'repositories/bird_repository.dart';
import 'repositories/weight_repository.dart';
import 'repositories/room_repository.dart';
import 'repositories/species_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/user_repository.dart';
import 'services/alert_service.dart';
import 'screens/worker/worker_screen.dart';

/// 数据库单例
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 所有鹦鹉（含品种、房间）
final allBirdsProvider = FutureProvider<List<BirdWithDetails>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllWithDetails();
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

/// 今日任务
final todayTasksProvider = FutureProvider<List<TaskWithBird>>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.generateTodayTasks();
  return db.getTodayTasks(null);
});

/// 逾期任务
final overdueTasksProvider = FutureProvider<List<TaskWithBird>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getOverdueTasks();
});

/// 首次启动预置默认品种 + 管理员账号
final initDefaultsProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);

  // 品种
  final existing = await db.getAllSpecies();
  if (existing.isEmpty) {
    await db.createSpecies('牡丹鹦鹉', nestlingEndDays: 45, juvenileEndDays: 120);
    await db.createSpecies('金太阳', nestlingEndDays: 60, juvenileEndDays: 180);
    await db.createSpecies('虎皮鹦鹉', nestlingEndDays: 30, juvenileEndDays: 90);
    await db.createSpecies('玄凤鹦鹉', nestlingEndDays: 45, juvenileEndDays: 150);
    await db.createSpecies('金刚鹦鹉', nestlingEndDays: 90, juvenileEndDays: 365);
  }

  // 默认管理员
  final users = await db.getAllUsers();
  if (users.isEmpty) {
    await db.createUser('admin', '管理员', '', role: 'admin');
  }
});

/// 异常提醒数量
final alertCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final service = AlertService(db);
  final alerts = await service.detectAll();
  return alerts.length;
});

/// 某房间的鹦鹉列表
final roomBirdsProvider = FutureProvider.family<List<BirdWithDetails>, int>((ref, roomId) async {
  final db = ref.watch(databaseProvider);
  return db.getByRoom(roomId);
});

/// 体重保存通知——用于触发图表刷新
final weightSavedProvider = StateProvider<int>((ref) => 0);

/// 当前员工的房间（多房间支持）
final myRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final worker = ref.watch(workerProvider);
  final db = ref.watch(databaseProvider);
  if (!worker.isSelected) return [];
  return db.getByUser(worker.userId!);
});
