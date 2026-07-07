import 'package:flutter/material.dart';
import '../database/database.dart';
import '../services/operation_service.dart';
import 'plugin.dart';
import 'event_bus.dart';

/// Global plugin registry singleton — plugins access this to get the database.
PluginRegistry get pluginRegistry => _instance;
final _instance = PluginRegistry();

/// Central registry for all feature plugins.
///
/// Plugins declare their tables, routes, server APIs, and event handlers here.
/// The main app, server, and navigation all read from this registry.
class PluginRegistry {
  final List<FeaturePlugin> _plugins = [];
  final EventBus eventBus = EventBus();

  /// 统一操作服务 —— 所有插件写操作的唯一入口。
  /// 在 [setDatabase] 之后才可用（db 非 null）。
  late final OperationService operationService = OperationService(
    () => db,
    eventBus,
  );

  AppDatabase? db;

  // ── enabled-plugins cache ──
  // `enabledPlugins` is read on every bird list tile build and in many other
  // hot paths. Recomputing `_plugins.where(...).toList()` each call allocates a
  // fresh list and iterates the full plugin set. Instead we cache the result
  // and invalidate it whenever plugin state can change (register / setEnabled /
  // reset). Callers must go through those methods to toggle plugins — there is
  // no other public path that mutates `FeaturePlugin.enabled`.
  List<FeaturePlugin> _enabledCache = const [];
  bool _enabledDirty = true;

  List<FeaturePlugin> get plugins => List.unmodifiable(_plugins);

  /// Register a plugin — call once per plugin at startup.
  void register(FeaturePlugin plugin) {
    _plugins.add(plugin);
    plugin.registerEvents(eventBus);
    _enabledDirty = true;
  }

  /// Set the database reference — call once after DB is initialized.
  void setDatabase(AppDatabase database) {
    db = database;
  }

  /// Reset to a clean state — clears all plugins, event handlers, and DB ref.
  /// For testing only; not called in production.
  void reset() {
    _plugins.clear();
    eventBus.clearAll();
    db = null;
    _enabledDirty = true;
    _enabledCache = const [];
  }

  /// Get a plugin by ID.
  FeaturePlugin? getPlugin(String id) {
    for (final p in enabledPlugins) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Call a data query exposed by a plugin.
  /// Plugin A: `registry.call('weights', 'getLatestWeight', birdId)`
  dynamic call(String pluginId, String query, [dynamic arg]) {
    return getPlugin(pluginId)?.dataQueries[query]?.call(arg);
  }

  /// Enable or disable a plugin by ID.
  void setEnabled(String id, bool enabled) {
    for (final p in _plugins) {
      if (p.id == id) {
        if (p.isInternal) return; // internal plugins can't be toggled
        p.enabled = enabled;
        _enabledDirty = true;
        return;
      }
    }
  }

  /// Only enabled plugins.
  ///
  /// Returns a cached unmodifiable list; recomputed only when plugin enable
  /// state changes via [register], [setEnabled], or [reset]. The returned list
  /// is safe to iterate and will not be mutated in place.
  List<FeaturePlugin> get enabledPlugins {
    if (_enabledDirty) {
      _enabledCache = List.unmodifiable(
        _plugins.where((p) => p.enabled),
      );
      _enabledDirty = false;
    }
    return _enabledCache;
  }

  /// Plugins that have a settings page.
  Iterable<FeaturePlugin> get configurablePlugins =>
      enabledPlugins.where((p) => p.settingsBuilder != null);

  /// All database tables from enabled plugins.
  List<dynamic> get allTables =>
      enabledPlugins.expand((p) => p.tables).toList();

  /// All client routes from enabled plugins.
  Map<String, WidgetBuilder> allRoutes(AppDatabase db) {
    final map = <String, WidgetBuilder>{};
    for (final p in enabledPlugins) {
      map.addAll(p.routes(db));
    }
    return map;
  }
}
