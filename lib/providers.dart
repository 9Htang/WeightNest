import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
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
import 'services/work_hours_config.dart';
import 'plugins/medication/medication_repository.dart';
import 'screens/worker/worker_screen.dart';
import 'theme/theme_notifier.dart';

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
  final worker = ref.watch(workerProvider);
  ref.watch(weightSavedProvider); // 体重保存后自动刷新
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
      // 小型鹦鹉 — 生长周期较短
      await db.createSpecies('虎皮鹦鹉', nestlingEndDays: 30, juvenileEndDays: 90);
      await db.createSpecies('牡丹鹦鹉', nestlingEndDays: 35, juvenileEndDays: 100);
      // 中型鹦鹉 — 生长周期中等
      await db.createSpecies('玄凤鹦鹉', nestlingEndDays: 45, juvenileEndDays: 120);
      await db.createSpecies('金太阳', nestlingEndDays: 50, juvenileEndDays: 130);
      // 大型鹦鹉 — 生长周期较长
      await db.createSpecies('金刚鹦鹉', nestlingEndDays: 60, juvenileEndDays: 180);
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

/// 异常提醒确认版本号 — 确认后 +1 触发 alertListProvider 刷新
final alertConfirmedVersionProvider = StateProvider<int>((ref) => 0);

/// 原始告警检测结果（共享，避免 alertListProvider 和 allAlertsProvider 重复执行 detectAll）
final _rawAlertsProvider = FutureProvider<List<AnomalyAlert>>((ref) async {
  ref.watch(weightSavedProvider); // 体重保存后自动刷新
  ref.watch(alertConfirmedVersionProvider); // 确认后刷新
  final db = ref.watch(databaseProvider);
  final service = AlertService(db);
  final alerts = await service.detectAll();
  // 持久化未读异常 → 首页轻量查询可感知
  await db.upsertUnreadAlerts(alerts);
  // 持久化完成后才触发首页查询，避免竞态
  ref.invalidate(hasRecentAlertRecordsProvider);
  return alerts;
});

/// 异常提醒详细列表（用于异常页面展示）。
///
/// 从 alert_records 表读取 30 天内未确认的记录，而非实时 detectAll()，
/// 确保异常消除后未确认的历史记录仍可查看。
final alertListProvider = FutureProvider<List<AnomalyAlert>>((ref) async {
  ref.watch(_rawAlertsProvider); // 保持监听以触发刷新，数据从 DB 读取
  final db = ref.watch(databaseProvider);
  return db.getUnconfirmedAlerts(30);
});

/// 全部告警列表（含已确认 + 未确认，近 30 天）— 供快捷操作「异常提醒」使用
final allAlertsProvider = FutureProvider<List<AlertWithStatus>>((ref) async {
  ref.watch(_rawAlertsProvider); // 保持监听以触发刷新，数据从 DB 读取
  final db = ref.watch(databaseProvider);
  return db.getAllAlertRecordsWithStatus(30);
});

/// 异常提醒数量 — 从 alertListProvider 派生，避免重复计算
final alertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertListProvider).valueOrNull;
  return alerts?.length ?? 0;
});

/// 首页轻量检查：近 30 天是否有已检测但未确认的异常（不触发 detectAll）
/// 注意：不直接监听 weightSavedProvider，否则会与 _rawAlertsProvider 竞态 —
/// _rawAlertsProvider 持久化未读记录之前本 provider 已查询到空结果。
/// 改为由 _rawAlertsProvider 在 upsertUnreadAlerts 完成后主动 invalidate 本 provider。
final hasRecentAlertRecordsProvider = FutureProvider<bool>((ref) async {
  ref.watch(alertConfirmedVersionProvider); // 确认后重新检查
  final db = ref.watch(databaseProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  final rows = await (db.select(db.alertRecords)
    ..where((t) => t.isRead.equals(false) & t.createdAt.isBiggerOrEqualValue(cutoff)))
    .get();
  return rows.isNotEmpty;
});

/// 某房间的鹦鹉列表 — 依赖 allBirdsProvider，鸟变更时自动刷新
final roomBirdsProvider = FutureProvider.family<List<BirdWithDetails>, int>((ref, roomId) async {
  final birds = await ref.watch(allBirdsProvider.future);
  return birds.where((b) => b.bird.roomId == roomId).toList();
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

/// 用户工作时间配置（多插件共享）
final workHoursProvider = FutureProvider<WorkHoursConfig>((ref) async {
  return WorkHoursConfig.load();
});

/// 某只鹦鹉的操作日志（ActivityLogs 统一时间轴）
final activityLogsProvider =
    FutureProvider.family<List<ActivityLog>, int>((ref, birdId) async {
  ref.watch(weightSavedProvider); // 操作后触发刷新
  final db = ref.watch(databaseProvider);
  return (db.select(db.activityLogs)
        ..where((t) => t.birdId.equals(birdId))
        ..orderBy([(t) => OrderingTerm.desc(t.operatedAt)]))
      .get();
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

/// 主题模式（SharedPreferences 持久化）
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

