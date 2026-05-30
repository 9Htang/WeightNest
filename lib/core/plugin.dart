import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import 'event_bus.dart';

/// A feature plugin that can add database tables, client UI, server API
/// routes, and event handlers — all in one package, zero changes to main app.
///
/// To add a new feature (e.g. medication tracking):
/// 1. Implement this interface
/// 2. Register in [PluginRegistry]
/// 3. Done — navigation, server routes, and schema are all automatic
abstract class FeaturePlugin {
  /// Unique identifier, e.g. 'weight', 'medication'.
  String get id;

  /// Human-readable name shown in navigation.
  String get displayName;

  /// Icon for navigation (Material or Cupertino).
  IconData get icon;

  /// Filled variant for selected state.
  IconData? get selectedIcon;

  /// Database tables declared by this plugin (for drift schema generation).
  /// Return empty if no custom tables.
  List<dynamic> get tables;

  /// Client-side Flutter routes for this plugin's screens.
  /// Each entry maps a path to a Widget builder.
  Map<String, WidgetBuilder> get routes;

  /// Server-side shelf Router for this plugin's API endpoints.
  /// Return null if this plugin has no server API.
  shelf.Router? get serverRoutes;

  /// Register event handlers — subscribe to domain events from other plugins.
  /// Called once at app startup.
  void registerEvents(EventBus bus) {}
}
