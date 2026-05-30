import 'package:drift/drift.dart';
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
    // 自动生成未来 7 天的喂药任务
    await _generateLogs(med.id, birdId, start, endDate, timesPerDay);
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

  // ── 喂药日志 ──

  /// 获取今天某只鸟的喂药任务（按时间排序）
  Future<List<MedicationLogData>> getTodayLogs(int birdId) async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await (select(medicationLogs).join([
      innerJoin(medications, medications.id.equalsExp(medicationLogs.medicationId)),
    ])
      ..where(medicationLogs.birdId.equals(birdId) &
          medicationLogs.scheduledTime.isBiggerOrEqualValue(dayStart) &
          medicationLogs.scheduledTime.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(medicationLogs.scheduledTime)])).get();

    return rows.map((r) => MedicationLogData(
      log: r.readTable(medicationLogs),
      medication: r.readTable(medications),
    )).toList();
  }

  /// 标记喂药完成
  Future<void> giveMedication(int logId, {int? userId}) async {
    await (update(medicationLogs)..where((t) => t.id.equals(logId)))
        .write(MedicationLogsCompanion(
      givenAt: Value(DateTime.now()),
      givenBy: Value(userId),
    ));
  }

  /// 跳过本次喂药
  Future<void> skipMedication(int logId) async {
    await (update(medicationLogs)..where((t) => t.id.equals(logId)))
        .write(const MedicationLogsCompanion(skipped: Value(true)));
  }

  // ── 自动调度 ──

  /// 根据每天次数返回固定时间点
  static List<int> _timeSlots(int timesPerDay) {
    switch (timesPerDay) {
      case 1:
        return [8];
      case 2:
        return [8, 20];
      case 3:
        return [8, 14, 20];
      default:
        return [8];
    }
  }

  /// 自动生成喂药日志
  Future<void> _generateLogs(
    int medicationId,
    int birdId,
    DateTime start,
    DateTime? end,
    int timesPerDay,
  ) async {
    final endDate = end ?? start.add(const Duration(days: 7)); // 默认 7 天
    final hours = _timeSlots(timesPerDay);

    for (var day = start; day.isBefore(endDate) || day == start; day = day.add(const Duration(days: 1))) {
      if (day.isAfter(endDate)) break;
      for (final hour in hours) {
        await into(medicationLogs).insert(
          MedicationLogsCompanion.insert(
            medicationId: medicationId,
            birdId: birdId,
            scheduledTime: DateTime(day.year, day.month, day.day, hour),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }
}

class MedicationLogData {
  final MedicationLog log;
  final Medication medication;

  MedicationLogData({required this.log, required this.medication});

  String get timeLabel =>
      '${log.scheduledTime.hour.toString().padLeft(2, '0')}:${log.scheduledTime.minute.toString().padLeft(2, '0')}';
  bool get isDone => log.givenAt != null;
  bool get isSkipped => log.skipped;
  String get statusLabel {
    if (isDone) return '已喂';
    if (isSkipped) return '已跳过';
    if (log.scheduledTime.isBefore(DateTime.now())) return '逾期';
    return '待喂';
  }
}
