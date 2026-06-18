import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database.dart';
import '../../utils/uuid.dart';

extension MedicationRepository on AppDatabase {
  // ── 喂药方案 CRUD ──

  Future<Medication> addMedication({
    required int birdId,
    required String drugName,
    required String dosage,
    int timesPerDay = 1,
    String drugType = '其他',
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    List<TimeOfDay>? customTimes,
  }) async {
    final start = startDate ?? DateTime.now();
    final med = await into(medications).insertReturning(
      MedicationsCompanion.insert(
        uuid: genUuid(),
        birdId: birdId,
        drugName: drugName,
        drugType: Value(drugType),
        dosage: dosage,
        timesPerDay: Value(timesPerDay),
        startDate: start,
        endDate: Value(endDate),
        notes: Value(notes),
      ),
    );
    // 方案创建后触发任务生成（由 generateTodayTasks 统一调度）
    return med;
  }

  Future<List<Medication>> getMedicationsByBird(int birdId) =>
      (select(medications)
            ..where((t) => t.birdId.equals(birdId) & t.active.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<void> deactivateMedication(int id) async {
    await (update(medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(active: const Value(false), updatedAt: Value(DateTime.now())));
  }

  // ── 今日喂药任务（从 tasks 表统一查询） ──

  /// 获取今天某只鸟的喂药任务（按时间排序）
  Future<List<MedTaskInfo>> getTodayMedTasks(int birdId) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await (select(tasks)
          ..where((t) => t.taskType.equals('medication')))
        .get();

    return rows
        .where((t) =>
            t.birdId == birdId &&
            !t.dueDate.isBefore(dayStart) &&
            t.dueDate.isBefore(dayEnd))
        .map((t) => MedTaskInfo.fromTask(t))
        .toList()
      ..sort((a, b) => a.task.dueDate.compareTo(b.task.dueDate));
  }

  /// 获取今天所有的喂药任务（跨所有鸟）
  Future<List<MedTaskInfo>> getAllTodayMedTasks() async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await (select(tasks)
          ..where((t) => t.taskType.equals('medication')))
        .get();

    final result = rows
        .where((t) =>
            !t.dueDate.isBefore(dayStart) &&
            t.dueDate.isBefore(dayEnd))
        .map((t) => MedTaskInfo.fromTask(t))
        .toList();
    result.sort((a, b) => a.task.dueDate.compareTo(b.task.dueDate));
    return result;
  }

  /// 获取今日某鸟的喂药任务（别名，兼容旧调用）
  Future<List<MedTaskInfo>> getTodayLogs(int birdId) => getTodayMedTasks(birdId);

  /// 获取今日全部喂药任务（别名，兼容旧调用）
  Future<List<MedTaskInfo>> getAllTodayLogs() => getAllTodayMedTasks();

  /// 标记喂药完成（通过 taskId）
  Future<void> giveMedication(int taskId, {int? userId}) async {
    await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
      status: const Value('已完成'),
      completedAt: Value(DateTime.now()),
      completedBy: Value(userId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 跳过本次喂药（通过 taskId）
  Future<void> skipMedication(int taskId) async {
    await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
      status: const Value('已跳过'),
      updatedAt: Value(DateTime.now()),
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
  final window = endMin <= startMin ? (24 * 60 - startMin) + endMin : endMin - startMin;
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
    if (task.dueDate.isBefore(DateTime.now())) return '逾期';
    return '待喂';
  }
}
