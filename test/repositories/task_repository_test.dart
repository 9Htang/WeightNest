import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/plugin_registry.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/weight_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/repositories/task_repository.dart';
import '../test_helpers/test_factories.dart';
import '../test_helpers/test_clock.dart';

/// Fixed clock: 10:00 AM Jun 15, 2025.
/// Default WorkHoursConfig.taskReadyTime = 7:30 AM (8:00 - 30min),
/// so the time gate passes (10:00 ≥ 7:30).
final _fakeNow = DateTime(2025, 6, 15, 10, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int speciesId;

  setUp(() async {
    await setTestClockWithPrefs(_fakeNow);
    db = await setUpTestDb();
    speciesId = (await db.createSpecies('虎皮鹦鹉')).id;
    // Reset throttle so every test starts clean.
    TaskRepository.resetThrottleForTest();
    // Ensure WeightPlugin is enabled — a previous test may have disabled it
    // and the singleton plugin state survives pluginRegistry.reset() in some
    // concurrency scenarios with static extension fields.
    pluginRegistry.setEnabled('weights', true);
  });

  tearDown(() async {
    await tearDownTestDb(db);
    TaskRepository.resetThrottleForTest();
    // Restore plugin state so subsequent tests aren't affected.
    pluginRegistry.setEnabled('weights', true);
    await resetTestClock();
  });

  /// Helper: create a bird born [daysAgo] days before _fakeNow.
  Future<Bird> _bird({int daysAgo = 200, String name = 'Test'}) async {
    return db.createBird(
      name: name,
      speciesId: speciesId,
      birthDate: _fakeNow.subtract(Duration(days: daysAgo)),
    );
  }

  /// Helper: add a weight on a specific date.
  Future<void> _weigh(int birdId, DateTime when, double grams) async {
    await db.addWeight(birdId: birdId, weightG: grams, recordedAt: when);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // getTodayTasks
  // ═════════════════════════════════════════════════════════════════════════

  group('getTodayTasks', () {
    test('Returns tasks whose dueDate falls on today', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'task-today',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 15, 8, 0), // same day as _fakeNow
            deadline: Value(DateTime(2025, 6, 16, 8, 0)),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      final tasks = await db.getTodayTasks(null);
      expect(tasks.length, 1);
      expect(tasks.first.task.uuid, 'task-today');
    });

    test('Does NOT return tasks from yesterday or tomorrow', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'task-yesterday',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 14, 8, 0),
            deadline: Value(DateTime(2025, 6, 15, 8, 0)),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'task-tomorrow',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 16, 8, 0),
            deadline: Value(DateTime(2025, 6, 17, 8, 0)),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      final tasks = await db.getTodayTasks(null);
      expect(tasks, isEmpty);
    });

    test('Empty DB → returns []', () async {
      final tasks = await db.getTodayTasks(null);
      expect(tasks, isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // getOverdueTasks
  // ═════════════════════════════════════════════════════════════════════════

  group('getOverdueTasks', () {
    test('Task with deadline < fakeNow, status=pending → included', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'overdue',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 14, 8, 0),
            deadline: Value(DateTime(2025, 6, 15, 7, 0)), // < _fakeNow (10:00)
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      final tasks = await db.getOverdueTasks();
      expect(tasks.length, 1);
      expect(tasks.first.task.uuid, 'overdue');
    });

    test('Task with deadline < fakeNow, status=completed → NOT included',
        () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'completed-overdue',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 14, 8, 0),
            deadline: Value(DateTime(2025, 6, 15, 7, 0)),
            status: const Value('已完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      final tasks = await db.getOverdueTasks();
      expect(tasks, isEmpty);
    });

    test('Task with deadline > fakeNow → NOT included', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'future',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: _fakeNow,
            deadline: Value(_fakeNow.add(const Duration(hours: 2))),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      final tasks = await db.getOverdueTasks();
      expect(tasks, isEmpty);
    });

    test('Empty DB → returns []', () async {
      final tasks = await db.getOverdueTasks();
      expect(tasks, isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // generateTodayTasks — basic generation
  // ═════════════════════════════════════════════════════════════════════════

  group('generateTodayTasks — basic generation', () {
    test(
        'Bird last weighed more than effectiveInterval days ago → task created',
        () async {
      final bird = await _bird(daysAgo: 200); // adult, interval=7 days
      await _weigh(bird.id, _fakeNow.subtract(const Duration(days: 10)), 100);

      final count = await db.generateTodayTasks();
      expect(count, 1);

      final tasks = await db.getTodayTasks(null);
      expect(tasks.length, 1);
      expect(tasks.first.task.birdId, bird.id);
      expect(tasks.first.task.taskType, 'weigh');
    });

    test('Bird weighed within effectiveInterval → NO task created', () async {
      final bird = await _bird(daysAgo: 200); // adult, interval=7 days
      await _weigh(bird.id, _fakeNow.subtract(const Duration(days: 2)), 100);

      final count = await db.generateTodayTasks();
      expect(count, 0);

      final tasks = await db.getTodayTasks(null);
      expect(tasks, isEmpty);
    });

    test('Bird with no weight history → task created', () async {
      await _bird(daysAgo: 200); // no weights

      final count = await db.generateTodayTasks();
      expect(count, 1);
    });

    test('Disabled plugin → its tasks are NOT generated', () async {
      await _bird(daysAgo: 200); // no weights, would normally get a task

      // Disable weight plugin and verify it's actually disabled
      pluginRegistry.setEnabled('weights', false);
      expect(
        pluginRegistry.enabledPlugins.where((p) => p.id == 'weights').length,
        0,
        reason:
            'WeightPlugin should not appear in enabledPlugins after setEnabled(false)',
      );

      final count = await db.generateTodayTasks();
      expect(count, 0);

      // Re-enable for subsequent tests
      pluginRegistry.setEnabled('weights', true);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // generateTodayTasks — deduplication
  // ═════════════════════════════════════════════════════════════════════════

  group('generateTodayTasks — deduplication', () {
    test('Call generate twice for same bird → only ONE task exists', () async {
      await _bird(daysAgo: 200); // no weights

      // First call — generates 1 task
      final count1 = await db.generateTodayTasks();
      expect(count1, 1);

      // Reset throttle (without reset, second call within 60s returns 0 via
      // throttle, not via dedup — we want to test the actual dedup logic).
      TaskRepository.resetThrottleForTest();

      // Second call — existing today task blocks generation
      final count2 = await db.generateTodayTasks();
      expect(count2, 0);

      final all = await (db.select(db.tasks)).get();
      expect(all.length, 1);
    });

    test('cleanupDuplicateTasks: older (lower id) survives, newer deleted',
        () async {
      final bird = await _bird();
      // Insert two tasks with same key (birdId + taskType + dueDate)
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'dup-1',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: _fakeNow,
            deadline: Value(_fakeNow.add(const Duration(days: 1))),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'dup-2',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: _fakeNow,
            deadline: Value(_fakeNow.add(const Duration(days: 1))),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      await db.cleanupDuplicateTasks();

      final remaining = await (db.select(db.tasks)).get();
      expect(remaining.length, 1);
      expect(remaining.first.uuid, 'dup-1'); // lower id survives
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // generateTodayTasks — overdue marking
  // ═════════════════════════════════════════════════════════════════════════

  group('generateTodayTasks — overdue marking', () {
    test('dueDate yesterday, status=pending → marked 逾期', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'yesterday-pending',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 14, 8, 0), // yesterday
            deadline: Value(DateTime(2025, 6, 15, 8, 0)), // < _fakeNow
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      // generateTodayTasks marks it overdue
      await db.generateTodayTasks();

      final updated = await (db.select(db.tasks)
            ..where((t) => t.uuid.equals('yesterday-pending')))
          .getSingleOrNull();
      expect(updated!.status, '逾期');
    });

    test('dueDate yesterday, status=completed → NOT marked overdue', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'yesterday-done',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: DateTime(2025, 6, 14, 8, 0),
            deadline: Value(DateTime(2025, 6, 15, 8, 0)),
            status: const Value('已完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      await db.generateTodayTasks();

      final updated = await (db.select(db.tasks)
            ..where((t) => t.uuid.equals('yesterday-done')))
          .getSingleOrNull();
      expect(updated!.status, '已完成'); // unchanged
    });

    test('dueDate today → NOT marked overdue', () async {
      final bird = await _bird();
      await db.into(db.tasks).insert(TasksCompanion.insert(
            uuid: 'today-pending',
            birdId: bird.id,
            taskType: const Value('weigh'),
            dueDate: _fakeNow, // today
            deadline: Value(_fakeNow.add(const Duration(days: 1))),
            status: const Value('待完成'),
            createdAt: Value(_fakeNow),
            updatedAt: Value(_fakeNow),
          ));

      await db.generateTodayTasks();

      final updated = await (db.select(db.tasks)
            ..where((t) => t.uuid.equals('today-pending')))
          .getSingleOrNull();
      expect(updated!.status, '待完成'); // not overdue
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // generateTodayTasks — throttle (static fields _lastRun / _generating)
  // ═════════════════════════════════════════════════════════════════════════

  group('generateTodayTasks — throttle', () {
    test('First call generates tasks', () async {
      await _bird(daysAgo: 200); // no weights
      final count = await db.generateTodayTasks();
      expect(count, 1);
    });

    test('Second call within 60s with same clock → throttled', () async {
      await _bird(daysAgo: 200);
      // First call
      await db.generateTodayTasks();

      // Second call — same clock, throttle should block
      final count2 = await db.generateTodayTasks();
      expect(count2, 0); // throttled
    });

    test('After resetThrottleForTest + clock advance ≥ 61s → re-generates',
        () async {
      await _bird(daysAgo: 200);
      await db.generateTodayTasks();

      // Add a second bird so we can see new generation
      await _bird(daysAgo: 200, name: 'Bird2');

      // Jump clock 61s forward and reset throttle
      await setTestClock(_fakeNow.add(const Duration(seconds: 61)));
      TaskRepository.resetThrottleForTest();

      final count = await db.generateTodayTasks();
      expect(count, 1); // new task for Bird2

      // Restore clock for subsequent tests
      await setTestClock(_fakeNow);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // generateTasksForBird — single-bird scope
  // ═════════════════════════════════════════════════════════════════════════

  group('generateTasksForBird — single-bird scope', () {
    test('With 3 birds, only the specified bird gets a task', () async {
      final bird1 = await _bird(daysAgo: 200, name: 'A');
      final bird2 = await _bird(daysAgo: 200, name: 'B');
      final bird3 = await _bird(daysAgo: 200, name: 'C');
      // None have weights → all would be due

      final count = await db.generateTasksForBird(bird2.id);
      expect(count, 1);

      final all = await (db.select(db.tasks)).get();
      expect(all.length, 1);
      expect(all.first.birdId, bird2.id);
    });

    test('Non-existent birdId → does NOT throw, returns normally', () async {
      int count;
      count = await db.generateTasksForBird(99999);
      expect(count, 0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // completeTask
  // ═════════════════════════════════════════════════════════════════════════

  group('completeTask', () {
    test('Sets status=completed and completedAt=fakeNow', () async {
      final bird = await _bird();
      final task = await db.into(db.tasks).insertReturning(
            TasksCompanion.insert(
              uuid: 'complete-me',
              birdId: bird.id,
              taskType: const Value('weigh'),
              dueDate: _fakeNow,
              deadline: Value(_fakeNow.add(const Duration(days: 1))),
              status: const Value('待完成'),
              createdAt: Value(_fakeNow),
              updatedAt: Value(_fakeNow),
            ),
          );

      await db.completeTask(task.id, 1);

      final updated = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      expect(updated!.status, '已完成');
      expect(updated.completedAt, isNotNull);
      expect(updated.completedBy, 1);
    });

    test('Calling again on an already-completed task → idempotent', () async {
      final bird = await _bird();
      final task = await db.into(db.tasks).insertReturning(
            TasksCompanion.insert(
              uuid: 'idempotent',
              birdId: bird.id,
              taskType: const Value('weigh'),
              dueDate: _fakeNow,
              deadline: Value(_fakeNow.add(const Duration(days: 1))),
              status: const Value('待完成'),
              createdAt: Value(_fakeNow),
              updatedAt: Value(_fakeNow),
            ),
          );

      await db.completeTask(task.id, 1);
      // Second call
      await db.completeTask(task.id, 2);

      final updated = await (db.select(db.tasks)
            ..where((t) => t.id.equals(task.id)))
          .getSingleOrNull();
      expect(updated!.status, '已完成');
    });

    test('Non-existent taskId → does NOT throw', () async {
      // Must not throw
      await db.completeTask(99999, 1);
    });
  });
}
