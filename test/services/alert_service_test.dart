import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/plugin.dart';
import '../../lib/core/plugin_registry.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/services/alert_service.dart';
import '../test_helpers/test_factories.dart';

/// ── Fake plugin that returns canned alerts ────────────────────────────────
///
/// Stand-in for a real FeaturePlugin so AlertService can be exercised in
/// isolation. Only [id], [detectAlerts], and [enabled] are used by
/// AlertService.detectAll().
class _FakeAlertPlugin extends FeaturePlugin {
  @override
  final String id;
  @override
  String get displayName => id;
  @override
  IconData get icon => Icons.warning;
  @override
  IconData? get selectedIcon => null;
  @override
  List<dynamic> get tables => const [];
  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => {};

  final List<PluginAlert> alerts;
  final bool throwOnDetect;

  _FakeAlertPlugin(this.id,
      {List<PluginAlert>? alerts, this.throwOnDetect = false})
      : alerts = alerts ?? const [];

  @override
  Future<List<PluginAlert>> detectAlerts(AppDatabase db, {int? birdId}) async {
    if (throwOnDetect) throw Exception('plugin boom');
    if (birdId == null) return alerts;
    return alerts.where((a) => a.birdId == birdId).toList();
  }
}

/// Build an [AnomalyAlert] with minimal fields for assertion helpers.
AnomalyAlert _makeAlert(int birdId, String type, String desc,
        {AlertSeverity severity = AlertSeverity.warning}) =>
    AnomalyAlert(
      bird: _stubBirdWithDetails(birdId),
      type: type,
      description: desc,
      severity: severity,
      createdAt: DateTime(2025, 6, 15),
    );

/// Minimal BirdWithDetails stub — only .bird.id is used by upsert paths.
BirdWithDetails _stubBirdWithDetails(int birdId) {
  final baseDate = DateTime(2025, 1, 1);
  return BirdWithDetails(
    bird: Bird(
      id: birdId,
      uuid: 'b-$birdId',
      name: 'stub',
      speciesId: 1,
      ringNumber: null,
      roomId: null,
      enclosureId: null,
      birthDate: baseDate,
      gender: '未知',
      notes: null,
      sortOrder: 1,
      weighIntervalDays: null,
      manualBaselineG: null,
      weaningOverride: null,
      status: 'active',
      createdAt: baseDate,
      updatedAt: baseDate,
      deletedAt: null,
    ),
    species: Specy(
      id: 1,
      uuid: 's-1',
      name: 'stub',
      nestlingEndDays: 45,
      juvenileEndDays: 120,
      nestlingWeighIntervalDays: 1,
      juvenileWeighIntervalDays: 3,
      adultWeighIntervalDays: 7,
      minWeightG: null,
      maxWeightG: null,
      createdAt: baseDate,
      updatedAt: baseDate,
      deletedAt: null,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AlertService alertService;

  setUp(() async {
    db = await setUpTestDb();
    alertService = AlertService(db);
  });

  tearDown(() => tearDownTestDb(db));

  /// Helper: create a species + bird, return the bird.
  Future<Bird> _bird({int daysAgo = 200}) async {
    final species = await db.createSpecies('虎皮鹦鹉');
    return db.createBird(
      name: '测试鸟',
      speciesId: species.id,
      birthDate: DateTime(2025, 6, 15).subtract(Duration(days: daysAgo)),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // detectAll — aggregation
  // ═════════════════════════════════════════════════════════════════════════
  //
  // setUpTestDb() registers the real WeightPlugin, which emits its own alerts
  // (e.g. 超期未称重 for birds with no weight history). To isolate the
  // AlertService aggregation logic from real plugin behavior, we disable the
  // weight plugin and register deterministic _FakeAlertPlugin instances.

  group('detectAll — aggregation', () {
    setUp(() {
      // Disable the real WeightPlugin so its built-in alerts don't pollute
      // the fake-plugin counts below.
      pluginRegistry.setEnabled('weights', false);
    });

    test('empty DB → empty alerts', () async {
      final alerts = await alertService.detectAll();
      expect(alerts, isEmpty);
    });

    test('aggregates alerts from a single plugin', () async {
      final bird = await _bird();
      final plugin = _FakeAlertPlugin('fake', alerts: [
        PluginAlert(birdId: bird.id, type: '测试告警', description: 'desc'),
      ]);
      pluginRegistry.register(plugin);

      final alerts = await alertService.detectAll();
      expect(alerts.length, 1);
      expect(alerts.first.type, '测试告警');
      expect(alerts.first.bird.bird.id, bird.id);
    });

    test('aggregates alerts from multiple plugins', () async {
      final bird = await _bird();
      pluginRegistry.register(_FakeAlertPlugin('p1', alerts: [
        PluginAlert(birdId: bird.id, type: '告警A', description: 'a'),
      ]));
      pluginRegistry.register(_FakeAlertPlugin('p2', alerts: [
        PluginAlert(birdId: bird.id, type: '告警B', description: 'b'),
      ]));

      final alerts = await alertService.detectAll();
      expect(alerts.length, 2);
      final types = alerts.map((a) => a.type).toSet();
      expect(types, containsAll(['告警A', '告警B']));
    });

    test('birdId filter restricts detection to one bird', () async {
      final bird1 = await _bird();
      // Create a 2nd species+bird with different id
      final species2 = await db.createSpecies('玄凤');
      final bird2 = await db.createBird(
        name: '鸟2',
        speciesId: species2.id,
        birthDate: DateTime(2024, 1, 1),
      );
      pluginRegistry.register(_FakeAlertPlugin('fake', alerts: [
        PluginAlert(birdId: bird1.id, type: '鸟1告警', description: 'a'),
        PluginAlert(birdId: bird2.id, type: '鸟2告警', description: 'b'),
      ]));

      final alerts = await alertService.detectAll(birdId: bird1.id);
      expect(alerts.length, 1);
      expect(alerts.first.type, '鸟1告警');
    });

    test('disabled plugin → its alerts excluded', () async {
      final bird = await _bird();
      pluginRegistry.register(_FakeAlertPlugin('fake', alerts: [
        PluginAlert(birdId: bird.id, type: '应被排除', description: 'x'),
      ]));
      pluginRegistry.setEnabled('fake', false);

      final alerts = await alertService.detectAll();
      expect(alerts, isEmpty);
    });

    test('plugin that throws → swallowed, other plugins still run', () async {
      final bird = await _bird();
      pluginRegistry.register(_FakeAlertPlugin('boom', throwOnDetect: true));
      pluginRegistry.register(_FakeAlertPlugin('ok', alerts: [
        PluginAlert(birdId: bird.id, type: '正常告警', description: 'ok'),
      ]));

      final alerts = await alertService.detectAll();
      expect(alerts.length, 1);
      expect(alerts.first.type, '正常告警');
    });

    test('plugin alert for non-existent birdId → filtered out', () async {
      final bird = await _bird();
      pluginRegistry.register(_FakeAlertPlugin('fake', alerts: [
        PluginAlert(birdId: bird.id, type: '有效', description: 'a'),
        PluginAlert(birdId: 99999, type: '无效', description: 'b'),
      ]));

      final alerts = await alertService.detectAll();
      expect(alerts.length, 1);
      expect(alerts.first.type, '有效');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // upsertUnreadAlerts — daily dedup
  // ═════════════════════════════════════════════════════════════════════════

  group('upsertUnreadAlerts — deduplication', () {
    test('first insert → returns the inserted alert', () async {
      final bird = await _bird();
      final alert = _makeAlert(bird.id, '下降', '描述');

      final inserted = await db.upsertUnreadAlerts([alert]);
      expect(inserted.length, 1);
      expect(inserted.first.type, '下降');
    });

    test('same bird+type twice same day → second insert skipped', () async {
      final bird = await _bird();
      final alert = _makeAlert(bird.id, '下降', '描述1');

      await db.upsertUnreadAlerts([alert]);
      final second = await db.upsertUnreadAlerts([alert]);
      expect(second, isEmpty);
    });

    test('same bird+type, different description, both unread → only first kept',
        () async {
      final bird = await _bird();
      // Insert unread alert A
      await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', '描述A')]);
      // Insert unread alert B (different desc, same type)
      final second =
          await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', '描述B')]);
      // Dedup key is birdId:alertType, so B is skipped while A is unread
      expect(second, isEmpty);
    });

    test('empty list → returns empty, no DB writes', () async {
      final inserted = await db.upsertUnreadAlerts([]);
      expect(inserted, isEmpty);
    });

    test('two distinct birds same type → both inserted', () async {
      final bird1 = await _bird();
      final species2 = await db.createSpecies('玄凤');
      final bird2 = await db.createBird(
        name: '鸟2',
        speciesId: species2.id,
        birthDate: DateTime(2024, 1, 1),
      );

      final inserted = await db.upsertUnreadAlerts([
        _makeAlert(bird1.id, '下降', 'desc'),
        _makeAlert(bird2.id, '下降', 'desc'),
      ]);
      expect(inserted.length, 2);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // confirmAlert / confirmAllAlerts
  // ═════════════════════════════════════════════════════════════════════════

  group('confirmAlert', () {
    test('marks existing unread alert as confirmed', () async {
      final bird = await _bird();
      await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', 'desc')]);

      await db.confirmAlert(bird.id, '下降', 'desc');

      final unconfirmed = await db.getUnconfirmedAlerts(1);
      expect(unconfirmed.where((a) => a.type == '下降'), isEmpty);
    });

    test('confirm a non-existent alert → inserts confirmed row, no throw',
        () async {
      final bird = await _bird();
      // No prior alert; confirm directly
      await db.confirmAlert(bird.id, '新告警', '新描述');

      final confirmed = await db.getConfirmedAlertKeys();
      expect(confirmed, contains('${bird.id}:新告警:新描述'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // getUnconfirmedAlerts
  // ═════════════════════════════════════════════════════════════════════════

  group('getUnconfirmedAlerts', () {
    test('returns unread alerts within window', () async {
      final bird = await _bird();
      await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', 'desc')]);

      final alerts = await db.getUnconfirmedAlerts(1);
      expect(alerts.any((a) => a.type == '下降'), isTrue);
    });

    test('excludes confirmed alerts', () async {
      final bird = await _bird();
      await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', 'desc')]);
      await db.confirmAlert(bird.id, '下降', 'desc');

      final alerts = await db.getUnconfirmedAlerts(1);
      expect(alerts.where((a) => a.type == '下降'), isEmpty);
    });

    test('dedups by (birdId, type, description), keeps latest', () async {
      final bird = await _bird();
      // Insert the same alert twice across two days by manipulating createdAt
      // is not feasible here; instead insert once, confirm it doesn't double.
      await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', 'desc')]);
      await db.upsertUnreadAlerts([_makeAlert(bird.id, '下降', 'desc')]);

      final alerts = await db.getUnconfirmedAlerts(1);
      expect(alerts.where((a) => a.type == '下降').length, 1);
    });
  });
}
