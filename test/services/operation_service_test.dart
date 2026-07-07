import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/plugin_registry.dart';
import '../../lib/core/events.dart';
import '../../lib/database/database.dart';
import '../test_helpers/test_factories.dart';
import '../test_helpers/test_clock.dart';

/// Fixed clock for all tests — noon on Jun 15, 2025.
final _fakeNow = DateTime(2025, 6, 15, 12, 0, 0);

@Tags(['smoke'])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  void Function()? _cancelListener;

  setUp(() async {
    await setTestClock(_fakeNow);
    db = await setUpTestDb();
  });

  tearDown(() async {
    _cancelListener?.call();
    _cancelListener = null;
    await tearDownTestDb(db);
    await resetTestClock();
  });

  /// Helper: insert a pending task and return it.
  Future<Task> _insertPendingTask({String status = '待完成'}) async {
    return db.into(db.tasks).insertReturning(
          TasksCompanion.insert(
            uuid: 'task-${DateTime.now().microsecondsSinceEpoch}',
            birdId: 1,
            taskType: const Value('weigh'),
            dueDate: _fakeNow,
            deadline: Value(_fakeNow.add(const Duration(days: 1))),
            status: Value(status),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ),
        );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // record — ActivityLog persistence
  // ═════════════════════════════════════════════════════════════════════════

  group('record — ActivityLog persistence', () {
    test('Stores correct birdId, pluginId, actionType, summary', () async {
      final log = await pluginRegistry.operationService.record(
        pluginId: 'test_plugin',
        actionType: 'test_action',
        summary: 'test summary',
        birdId: 42,
        operatedAt: _fakeNow,
      );

      expect(log.birdId, 42);
      expect(log.pluginId, 'test_plugin');
      expect(log.actionType, 'test_action');
      expect(log.summary, 'test summary');
    });

    test('operatedAt matches the passed timestamp', () async {
      final customTime = DateTime(2025, 3, 1, 9, 30);
      final log = await pluginRegistry.operationService.record(
        pluginId: 'p',
        actionType: 'a',
        summary: 's',
        operatedAt: customTime,
      );

      expect(log.operatedAt, customTime);
      expect(log.operatedAt, isNot(_fakeNow));
    });

    test('ActivityLog row is retrievable by uuid after record()', () async {
      final log = await pluginRegistry.operationService.record(
        pluginId: 'p',
        actionType: 'a',
        summary: 'retrievable',
      );

      final fetched = await (db.select(db.activityLogs)
            ..where((t) => t.uuid.equals(log.uuid)))
          .getSingleOrNull();
      expect(fetched, isNotNull);
      expect(fetched!.summary, 'retrievable');
    });

    test('Two sequential records produce two distinct rows', () async {
      final log1 = await pluginRegistry.operationService.record(
        pluginId: 'p',
        actionType: 'a',
        summary: 'first',
      );
      final log2 = await pluginRegistry.operationService.record(
        pluginId: 'p',
        actionType: 'a',
        summary: 'second',
      );

      expect(log1.id, isNot(log2.id));
      expect(log1.uuid, isNot(log2.uuid));

      final all = await (db.select(db.activityLogs)).get();
      expect(all.length, 2);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // record — task auto-complete
  // ═════════════════════════════════════════════════════════════════════════

  group('record — task auto-complete', () {
    test('relatedTaskId provided + task exists → task completed', () async {
      final task = await _insertPendingTask();

      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'weighed',
        birdId: 1,
        relatedTaskId: task.id,
        operatedBy: 1,
        operatedAt: _fakeNow,
      );

      final updated = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      expect(updated, isNotNull);
      expect(updated!.status, '已完成');
      expect(updated.completedAt, isNotNull);
      expect(updated.completedBy, 1);
    });

    test('relatedTaskId=null → no task row is modified', () async {
      final task = await _insertPendingTask();

      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'weighed',
        birdId: 1,
        relatedTaskId: null,
        operatedAt: _fakeNow,
      );

      final unchanged = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      expect(unchanged!.status, '待完成');
    });

    test('relatedTaskId to non-existent task → does NOT throw, record succeeds',
        () async {
      ActivityLog? log;
      log = await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'weighed',
        birdId: 1,
        relatedTaskId: 99999,
        operatedAt: _fakeNow,
      );

      expect(log, isNotNull);
      final fetched = await (db.select(db.activityLogs)
            ..where((t) => t.id.equals(log!.id)))
          .getSingleOrNull();
      expect(fetched, isNotNull);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // record — EventBus emission
  // ═════════════════════════════════════════════════════════════════════════

  group('record — EventBus emission', () {
    test('Listener registered BEFORE record() receives exactly one event',
        () async {
      final events = <OperationRecordedEvent>[];
      _cancelListener = pluginRegistry.eventBus.on<OperationRecordedEvent>((e) {
        events.add(e);
      });

      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'first weigh',
        birdId: 1,
        operatedAt: _fakeNow,
      );

      expect(events.length, 1);
    });

    test('Event carries the correct birdId and pluginId', () async {
      OperationRecordedEvent? received;
      _cancelListener = pluginRegistry.eventBus.on<OperationRecordedEvent>((e) {
        received = e;
      });

      await pluginRegistry.operationService.record(
        pluginId: 'medication',
        actionType: 'medication_given',
        summary: 'gave drug',
        birdId: 7,
        operatedAt: _fakeNow,
      );

      expect(received, isNotNull);
      expect(received!.pluginId, 'medication');
      expect(received!.birdId, 7);
    });

    test('Listener registered AFTER record() receives nothing (no replay)',
        () async {
      // Record first with no listener
      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'before listener',
        birdId: 1,
        operatedAt: _fakeNow,
      );

      // Now register listener
      final events = <OperationRecordedEvent>[];
      _cancelListener = pluginRegistry.eventBus.on<OperationRecordedEvent>((e) {
        events.add(e);
      });

      expect(events, isEmpty);
    });

    test('Two record() calls emit two distinct events in order', () async {
      final events = <OperationRecordedEvent>[];
      _cancelListener = pluginRegistry.eventBus.on<OperationRecordedEvent>((e) {
        events.add(e);
      });

      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'first',
        birdId: 1,
        operatedAt: _fakeNow,
      );
      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'second',
        birdId: 2,
        operatedAt: _fakeNow,
      );

      expect(events.length, 2);
      expect(events[0].summary, 'first');
      expect(events[1].summary, 'second');
      expect(events[0].birdId, 1);
      expect(events[1].birdId, 2);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // revokeOperation
  // ═════════════════════════════════════════════════════════════════════════

  group('revokeOperation', () {
    test('ActivityLog row deleted by id — no longer retrievable', () async {
      final log = await pluginRegistry.operationService.record(
        pluginId: 'p',
        actionType: 'a',
        summary: 'to be revoked',
        operatedAt: _fakeNow,
      );

      final revoked =
          await pluginRegistry.operationService.revokeOperation(log.id);

      expect(revoked, isNotNull);
      expect(revoked!.id, log.id);

      final fetched = await (db.select(db.activityLogs)
            ..where((t) => t.id.equals(log.id)))
          .getSingleOrNull();
      expect(fetched, isNull);
    });

    test('Revoking reverts related task to pending with null completedAt',
        () async {
      final task = await _insertPendingTask();

      // Complete it via record
      await pluginRegistry.operationService.record(
        pluginId: 'weights',
        actionType: 'weight_recorded',
        summary: 'weighed',
        birdId: 1,
        relatedTaskId: task.id,
        operatedBy: 1,
        operatedAt: _fakeNow,
      );

      // Verify completed
      var check = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      expect(check!.status, '已完成');

      // Find the activity log
      final logs = await (db.select(db.activityLogs)
            ..where((t) => t.relatedTaskId.equals(task.id)))
          .get();
      expect(logs.length, 1);

      // Revoke
      await pluginRegistry.operationService.revokeOperation(logs.first.id);

      final reverted = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      expect(reverted!.status, '待完成');
      expect(reverted.completedAt, isNull);
      expect(reverted.completedBy, isNull);
    });

    test('Revoking a uuid that does not exist → does NOT throw', () async {
      final result =
          await pluginRegistry.operationService.revokeOperation(99999);
      expect(result, isNull);
    });

    test('Revoking an already-revoked uuid → idempotent, no error', () async {
      final log = await pluginRegistry.operationService.record(
        pluginId: 'p',
        actionType: 'a',
        summary: 'double revoke test',
        operatedAt: _fakeNow,
      );

      await pluginRegistry.operationService.revokeOperation(log.id);
      final result =
          await pluginRegistry.operationService.revokeOperation(log.id);
      expect(result, isNull);
    });
  });
}
