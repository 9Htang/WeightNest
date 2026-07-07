import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/plugins/medication/medication_repository.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../test_helpers/test_clock.dart';
import '../test_helpers/test_factories.dart';

/// ── MedicationRepository 测试 ────────────────────────────────────────────
///
/// 验证喂药任务状态流转（giveMedication/skipMedication）与 MedTaskInfo 解析。

final _fakeNow = DateTime(2025, 6, 15, 10, 0, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int speciesId;
  late Bird bird;

  setUp(() async {
    await setTestClockWithPrefs(_fakeNow);
    db = await setUpTestDb();
    speciesId = (await db.createSpecies('虎皮鹦鹉')).id;
    bird = await db.createBird(
      name: '小蓝',
      speciesId: speciesId,
      birthDate: _fakeNow.subtract(const Duration(days: 200)),
    );
  });

  tearDown(() async {
    await tearDownTestDb(db);
    await resetTestClock();
  });

  /// 插入一条喂药任务并返回。
  Future<Task> _insertMedTask({
    String status = '待完成',
    Map<String, dynamic>? metadata,
    DateTime? dueDate,
  }) async {
    return db.into(db.tasks).insertReturning(
          TasksCompanion.insert(
            uuid: 'med-${DateTime.now().microsecondsSinceEpoch}',
            birdId: bird.id,
            taskType: const Value('medication'),
            dueDate: dueDate ?? _fakeNow,
            deadline: Value(_fakeNow.add(const Duration(hours: 2))),
            status: Value(status),
            metadata: metadata != null
                ? Value(jsonEncode(metadata))
                : const Value.absent(),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ),
        );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MedTaskInfo.fromTask
  // ═════════════════════════════════════════════════════════════════════════

  group('MedTaskInfo.fromTask', () {
    test('完整 metadata → 解析 drugName/dosage/medicationId', () {
      final task = Task(
        id: 1,
        uuid: 't1',
        birdId: bird.id,
        taskType: 'medication',
        dueDate: _fakeNow,
        deadline: _fakeNow.add(const Duration(hours: 2)),
        status: '待完成',
        metadata: jsonEncode({
          'drugName': '泰乐菌素',
          'dosage': '0.02mL',
          'medicationId': '42',
        }),
        createdAt: _fakeNow,
        updatedAt: _fakeNow,
      );
      final info = MedTaskInfo.fromTask(task);
      expect(info.drugName, '泰乐菌素');
      expect(info.dosage, '0.02mL');
      expect(info.medicationId, 42);
    });

    test('空 metadata → 默认值', () {
      final task = Task(
        id: 1,
        uuid: 't1',
        birdId: bird.id,
        taskType: 'medication',
        dueDate: _fakeNow,
        deadline: _fakeNow.add(const Duration(hours: 2)),
        status: '待完成',
        metadata: null,
        createdAt: _fakeNow,
        updatedAt: _fakeNow,
      );
      final info = MedTaskInfo.fromTask(task);
      expect(info.drugName, '未知');
      expect(info.dosage, '');
      expect(info.medicationId, 0);
    });

    test('metadata 缺字段 → 默认值', () {
      final task = Task(
        id: 1,
        uuid: 't1',
        birdId: bird.id,
        taskType: 'medication',
        dueDate: _fakeNow,
        deadline: _fakeNow.add(const Duration(hours: 2)),
        status: '待完成',
        metadata: jsonEncode({'drugName': '阿莫西林'}),
        createdAt: _fakeNow,
        updatedAt: _fakeNow,
      );
      final info = MedTaskInfo.fromTask(task);
      expect(info.drugName, '阿莫西林');
      expect(info.dosage, '');
      expect(info.medicationId, 0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // statusLabel
  // ═════════════════════════════════════════════════════════════════════════

  group('MedTaskInfo.statusLabel', () {
    MedTaskInfo _info(String status, {DateTime? deadline}) {
      return MedTaskInfo.fromTask(Task(
        id: 1,
        uuid: 't1',
        birdId: bird.id,
        taskType: 'medication',
        dueDate: _fakeNow,
        deadline: deadline ?? _fakeNow.add(const Duration(hours: 2)),
        status: status,
        metadata: null,
        createdAt: _fakeNow,
        updatedAt: _fakeNow,
      ));
    }

    test('已完成 → "已喂"', () {
      expect(_info('已完成').statusLabel, '已喂');
    });

    test('已跳过 → "已跳过"', () {
      expect(_info('已跳过').statusLabel, '已跳过');
    });

    test('待完成且未逾期 → "待喂"', () {
      expect(_info('待完成').statusLabel, '待喂');
    });

    test('待完成且已逾期（deadline 早于 now）→ "逾期"', () {
      final info =
          _info('待完成', deadline: _fakeNow.subtract(const Duration(hours: 1)));
      expect(info.statusLabel, '逾期');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // giveMedication / skipMedication
  // ═════════════════════════════════════════════════════════════════════════

  group('giveMedication', () {
    test('标记任务为已完成', () async {
      final task = await _insertMedTask();
      await db.giveMedication(task.id, userId: 1);
      final updated = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingle();
      expect(updated.status, '已完成');
      expect(updated.completedAt, isNotNull);
      expect(updated.completedBy, 1);
    });
  });

  group('skipMedication', () {
    test('标记任务为已跳过', () async {
      final task = await _insertMedTask();
      await db.skipMedication(task.id);
      final updated = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingle();
      expect(updated.status, '已跳过');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // getTodayMedTasks
  // ═════════════════════════════════════════════════════════════════════════

  group('getTodayMedTasks', () {
    test('返回今日喂药任务', () async {
      await _insertMedTask(dueDate: _fakeNow);
      final tasks = await db.getTodayMedTasks(bird.id);
      expect(tasks.length, 1);
    });

    test('不返回非今日任务', () async {
      await _insertMedTask(dueDate: _fakeNow.add(const Duration(days: 1)));
      final tasks = await db.getTodayMedTasks(bird.id);
      expect(tasks, isEmpty);
    });

    test('不返回其他鸟的任务', () async {
      await _insertMedTask(dueDate: _fakeNow);
      final otherBird = await db.createBird(
        name: '小绿',
        speciesId: speciesId,
        birthDate: _fakeNow.subtract(const Duration(days: 200)),
      );
      final tasks = await db.getTodayMedTasks(otherBird.id);
      expect(tasks, isEmpty);
    });
  });
}
