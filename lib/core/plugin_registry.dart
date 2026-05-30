import 'package:flutter/material.dart';
import 'plugin.dart';
import 'event_bus.dart';

/// Central registry for all feature plugins.
///
/// Plugins declare their tables, routes, server APIs, and event handlers here.
/// The main app, server, and navigation all read from this registry.
class PluginRegistry {
  final List<FeaturePlugin> _plugins = [];
  final EventBus eventBus = EventBus();

  List<FeaturePlugin> get plugins => List.unmodifiable(_plugins);

  /// Register a plugin — call once per plugin at startup.
  void register(FeaturePlugin plugin) {
    _plugins.add(plugin);
    plugin.registerEvents(eventBus);
  }

  /// All database tables from all plugins.
  List<dynamic> get allTables =>
      _plugins.expand((p) => p.tables).toList();

  /// All client routes merged into a single map.
  Map<String, WidgetBuilder> get allRoutes {
    final map = <String, WidgetBuilder>{};
    for (final p in _plugins) {
      map.addAll(p.routes);
    }
    return map;
  }
}
