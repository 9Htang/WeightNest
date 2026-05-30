import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../database/database.dart';
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

  /// Short description shown in plugin settings.
  String get description => '';

  /// Icon for navigation (Material or Cupertino).
  IconData get icon;

  /// Filled variant for selected state.
  IconData? get selectedIcon;

  /// Whether this plugin is currently enabled.
  /// Disabled plugins are hidden from UI and their server routes are skipped.
  bool enabled = true;

  /// Database tables declared by this plugin (for drift schema generation).
  List<dynamic> get tables;

  /// Client-side Flutter routes for this plugin's screens.
  /// Each entry maps a path to a Widget builder.
  /// Use [db] to pass database to screens that need it.
  Map<String, WidgetBuilder> routes(AppDatabase db);

  /// Server-side shelf Router for this plugin's API endpoints.
  /// [db] is the app database instance.
  shelf.Router? serverRoutes(AppDatabase db);

  // ── Slot B: 鹦鹉详情嵌入 ──

  /// Sections this plugin contributes to the bird detail page.
  List<DetailSection> buildDetailSections(int birdId) => [];

  // ── Slot D: 日历视图 ──

  String? get calendarTitle => null;
  Widget? buildDayView(DateTime day, {int? birdId}) => null;

  // ── Pages ──

  /// Pages this plugin can open (shown in sidebar as navigation entries).
  List<PluginPageDescriptor> get pages => [];

  /// Data queries exposed to other plugins via registry.call().
  Map<String, Function> get dataQueries => const {};

  /// Register event handlers — subscribe to domain events from other plugins.
  void registerEvents(EventBus bus) {}
}

// ── Page types ──

/// How uniqueness is enforced when opening a plugin page.
enum PageUniqueness {
  /// Allow multiple instances.
  none,

  /// Only one instance globally (e.g., settings, drug config).
  singleton,

  /// One instance per bird ID (e.g., weigh entry per bird).
  perBird,
}

/// Describes a page type that a plugin can open.
class PluginPageDescriptor {
  final String key;
  final String title;
  final IconData icon;
  final PageUniqueness uniqueness;
  final bool showInSidebar;
  final Widget Function(PluginPageContext ctx) builder;

  const PluginPageDescriptor({
    required this.key,
    required this.title,
    required this.icon,
    this.uniqueness = PageUniqueness.none,
    this.showInSidebar = true,
    required this.builder,
  });
}

/// Context passed to a plugin page builder.
class PluginPageContext {
  final int? birdId;
  final Map<String, dynamic> params;

  const PluginPageContext({this.birdId, this.params = const {}});
}

/// A running page instance with uniqueness tracking.
class PluginPage {
  final String pluginId;
  final String pageKey;
  final int? birdId;
  final PageUniqueness uniqueness;
  final Widget widget;

  PluginPage({
    required this.pluginId,
    required this.pageKey,
    this.birdId,
    required this.uniqueness,
    required this.widget,
  });

  String get id => '$pluginId:$pageKey${birdId != null ? ":$birdId" : ""}';

  bool matches(PluginPageDescriptor d, {int? birdId}) {
    if (pluginId != '') return false; // placeholder check handled by caller
    if (uniqueness == PageUniqueness.singleton) return true;
    if (uniqueness == PageUniqueness.perBird) return this.birdId == birdId;
    return false;
  }
}

/// A content section contributed by a plugin to the bird detail page.
class DetailSection {
  final String title;
  final IconData? icon;
  final int priority;          // lower = higher up
  final bool defaultExpanded;  // open by default?
  final Widget child;

  const DetailSection({
    required this.title,
    this.icon,
    this.priority = 100,
    this.defaultExpanded = true,
    required this.child,
  });
}
