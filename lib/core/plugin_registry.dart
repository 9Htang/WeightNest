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

  List<FeaturePlugin> get plugins => List.unmodifiable(_plugins);

  /// Register a plugin — call once per plugin at startup.
  void register(FeaturePlugin plugin) {
    _plugins.add(plugin);
    plugin.registerEvents(eventBus);
  }

  /// Set the database reference — call once after DB is initialized.
  void setDatabase(AppDatabase database) {
    db = database;
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
      if (p.id == id) { p.enabled = enabled; return; }
    }
  }

  /// Only enabled plugins.
  List<FeaturePlugin> get enabledPlugins =>
      _plugins.where((p) => p.enabled).toList();

  /// Plugins that have a settings page.
  Iterable<FeaturePlugin> get configurablePlugins =>
      _plugins.where((p) => p.enabled && p.settingsBuilder != null);

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
