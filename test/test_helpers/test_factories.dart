import '../../lib/core/app_clock.dart';
import '../../lib/core/plugin.dart';
import '../../lib/core/plugin_registry.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/weight_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/plugins/weight/weight_plugin.dart';

/// ── Shared test setup/teardown ────────────────────────────────────────────

/// Creates an in-memory test DB, wires it into [pluginRegistry], and registers
/// core plugins needed for alert/task detection. Call in [setUp], capture the
/// returned [AppDatabase], and pass it to [tearDownTestDb] in [tearDown].
Future<AppDatabase> setUpTestDb() async {
  final db = AppDatabase.test();
  pluginRegistry.setDatabase(db);
  _ensurePlugin<WeightPlugin>(WeightPlugin());
  return db;
}

/// Closes the DB and resets the global [pluginRegistry] to a clean state.
/// Must be called in [tearDown] for every test that uses [setUpTestDb].
/// This prevents shared state from leaking between test files.
Future<void> tearDownTestDb(AppDatabase db) async {
  // Flush pending fire-and-forget operationService.record() futures before
  // closing, so they don't race against the next test's setup.
  await db.transaction(() async {});
  await db.close();
  pluginRegistry.reset();
}

/// Register [plugin] only if not already registered (by type).
void _ensurePlugin<T extends FeaturePlugin>(T plugin) {
  for (final p in pluginRegistry.plugins) {
    if (p is T) return;
  }
  pluginRegistry.register(plugin);
}

/// ── Data factories ────────────────────────────────────────────────────────

/// Quick test species with sensible defaults.
Future<Specy> createTestSpecies(
  AppDatabase db, {
  String name = '测试品种',
  int nestlingEndDays = 45,
  int juvenileEndDays = 120,
}) async {
  return db.createSpecies(name,
      nestlingEndDays: nestlingEndDays, juvenileEndDays: juvenileEndDays);
}

/// Quick test bird with [speciesId] and optional age.
Future<Bird> createTestBird(
  AppDatabase db, {
  required int speciesId,
  String name = '测试鹦鹉',
  int daysAgo = 0,
}) async {
  return db.createBird(
    name: name,
    speciesId: speciesId,
    birthDate: AppClock.now.subtract(Duration(days: daysAgo)),
  );
}

/// Add a series of weight records to [birdId] at specified hours-ago offsets.
Future<void> addWeightSeries(
  AppDatabase db,
  int birdId,
  List<({int hoursAgo, double grams})> entries,
) async {
  for (final e in entries) {
    await db.addWeight(
      birdId: birdId,
      weightG: e.grams,
      recordedAt: AppClock.now.subtract(Duration(hours: e.hoursAgo)),
    );
  }
}
