import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';

/// Task-related queries and time-slot utilities.
/// Medication CRUD operations are now in drug_library_repository.dart.
extension MedicationRepository on AppDatabase {
  // ── 今日喂药任务（从 tasks 表统一查询） ──

  /// 获取今天某只鸟的喂药任务（按时间排序）
  Future<List<MedTaskInfo>> getTodayMedTasks(int birdId) async {
    final today = AppClock.now;
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // 直接用 SQL WHERE 过滤 birdId + taskType + dueDate，避免查出全表再在 Dart 过滤。
    final rows = await (select(tasks)
          ..where((t) =>
              t.birdId.equals(birdId) &
              t.taskType.equals('medication') &
              t.dueDate.isBiggerOrEqualValue(dayStart) &
              t.dueDate.isSmallerThanValue(dayEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();

    return rows.map((t) => MedTaskInfo.fromTask(t)).toList();
  }

  /// 获取今天所有的喂药任务（跨所有鸟）
  Future<List<MedTaskInfo>> getAllTodayMedTasks() async {
    final today = AppClock.now;
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // 直接用 SQL WHERE 过滤 taskType + dueDate，避免查出全表再在 Dart 过滤。
    final rows = await (select(tasks)
          ..where((t) =>
              t.taskType.equals('medication') &
              t.dueDate.isBiggerOrEqualValue(dayStart) &
              t.dueDate.isSmallerThanValue(dayEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();

    return rows.map((t) => MedTaskInfo.fromTask(t)).toList();
  }

  /// 获取今日某鸟的喂药任务（别名，兼容旧调用）
  Future<List<MedTaskInfo>> getTodayLogs(int birdId) =>
      getTodayMedTasks(birdId);

  /// 获取今日全部喂药任务（别名，兼容旧调用）
  Future<List<MedTaskInfo>> getAllTodayLogs() => getAllTodayMedTasks();

  /// 标记喂药完成（通过 taskId）
  Future<void> giveMedication(int taskId, {int? userId}) async {
    await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
      status: const Value('已完成'),
      completedAt: Value(AppClock.now),
      completedBy: Value(userId),
      updatedAt: Value(AppClock.now),
    ));
  }

  /// 跳过本次喂药（通过 taskId）
  Future<void> skipMedication(int taskId) async {
    await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
      status: const Value('已跳过'),
      updatedAt: Value(AppClock.now),
    ));
  }
}

// ── 时间槽计算（供 detectTasks 和旧版 _generateLogs 共用） ──

class _TimeSlot {
  final int hour;
  final int minute;
  const _TimeSlot(this.hour, this.minute);
}

/// 从 SharedPreferences 读取时间窗口并计算均分时间点。
/// 优先使用喂药插件自己的设置，未设时回退到全局工作时间。
Future<List<_TimeSlot>> distributedTimeSlots(int timesPerDay) async {
  if (timesPerDay <= 0) return [_TimeSlot(8, 0)];

  final prefs = await SharedPreferences.getInstance();

  // 优先喂药插件自身时间窗口
  final sh = prefs.getInt('medication_work_start_hour');
  int startH, startM, endH, endM;

  if (sh != null) {
    startH = sh;
    startM = prefs.getInt('medication_work_start_min') ?? 0;
    endH = prefs.getInt('medication_work_end_hour') ?? 22;
    endM = prefs.getInt('medication_work_end_min') ?? 0;
  } else {
    // 回退到全局工作时间
    startH = prefs.getInt('work_start_hour') ?? 8;
    startM = prefs.getInt('work_start_min') ?? 0;
    endH = prefs.getInt('work_end_hour') ?? 22;
    endM = prefs.getInt('work_end_min') ?? 0;
  }

  final startMin = startH * 60 + startM;
  final endMin = endH * 60 + endM;
  final window =
      endMin <= startMin ? (24 * 60 - startMin) + endMin : endMin - startMin;
  if (window <= 0) return [_TimeSlot(startH, startM)];

  if (timesPerDay == 1) {
    final mid = (startMin + window ~/ 2) % (24 * 60);
    return [_TimeSlot(mid ~/ 60, mid % 60)];
  }

  final interval = window / (timesPerDay - 1);
  return List.generate(timesPerDay, (i) {
    final m = (startMin + (interval * i).round()) % (24 * 60);
    return _TimeSlot(m ~/ 60, m % 60);
  });
}

// ── 喂药任务信息（从 tasks 表 metadata 解析） ──

class MedTaskInfo {
  final Task task;
  final String drugName;
  final String dosage;
  final int medicationId;

  MedTaskInfo({
    required this.task,
    required this.drugName,
    required this.dosage,
    required this.medicationId,
  });

  factory MedTaskInfo.fromTask(Task t) {
    final md = t.metadata != null && t.metadata!.isNotEmpty
        ? jsonDecode(t.metadata!) as Map<String, dynamic>
        : <String, dynamic>{};
    return MedTaskInfo(
      task: t,
      drugName: (md['drugName'] as String?) ?? '未知',
      dosage: (md['dosage'] as String?) ?? '',
      medicationId: int.tryParse((md['medicationId'] as String?) ?? '') ?? 0,
    );
  }

  String get timeLabel =>
      '${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}';

  bool get isDone => task.status == '已完成';
  bool get isSkipped => task.status == '已跳过';

  String get statusLabel {
    if (isDone) return '已喂';
    if (isSkipped) return '已跳过';
    final threshold = task.deadline ?? task.dueDate;
    if (threshold.isBefore(AppClock.now)) return '逾期';
    return '待喂';
  }
}
