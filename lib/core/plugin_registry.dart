import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../database/database.dart';
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

  /// Enable or disable a plugin by ID.
  void setEnabled(String id, bool enabled) {
    for (final p in _plugins) {
      if (p.id == id) { p.enabled = enabled; return; }
    }
  }

  /// Only enabled plugins.
  List<FeaturePlugin> get enabledPlugins =>
      _plugins.where((p) => p.enabled).toList();

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

  /// All server routes for enabled plugins, mounted at /api/<plugin.id>/
  void mountServerRoutes(AppDatabase db, shelf.Router router) {
    for (final p in enabledPlugins) {
      final pluginRouter = p.serverRoutes(db);
      if (pluginRouter != null) {
        router.mount('/api/${p.id}/', pluginRouter.call);
      }
    }
  }
}
