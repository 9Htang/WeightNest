import 'package:flutter/material.dart';
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

  /// Optional settings page for this plugin.
  /// When non-null, the plugin management UI shows a settings button.
  WidgetBuilder? get settingsBuilder => null;

  // ── Slot E: 首页快捷操作 ──

  /// Quick-action buttons contributed to the home screen.
  List<QuickAction> get quickActions => [];

  // ── Slot G: 容器称重操作 ──

  /// Quick weigh action shown on enclosure cards.
  /// When non-null, enclosure cards show a weigh button (top-right).
  EnclosureWeighAction? get enclosureWeighAction => null;

  // ── Slot H: 房间称重操作 ──

  /// Quick weigh action shown on room cards.
  /// When non-null, room cards show a weigh button.
  RoomWeighAction? get roomWeighAction => null;

  // ── Slot F: 告警检测 ──

  /// Detect anomalies contributed by this plugin.
  /// Called by AlertService.detectAll() — aggregated across all enabled plugins.
  /// [birdId] optionally limits detection to a single bird; null = scan all.
  Future<List<PluginAlert>> detectAlerts(AppDatabase db, {int? birdId}) async => [];

  // ── Slot G: 任务派发 ──

  /// Detect tasks contributed by this plugin.
  /// Called by TaskRepository.generateTodayTasks() — aggregated across all enabled plugins.
  ///
  /// A plugin may return multiple descriptors per bird (e.g. medication 3× daily).
  /// Deduplication is handled by TaskRepository using (birdId, taskType, dueDate).
  ///
  /// If [birdId] is provided, only return descriptors for that bird (used for
  /// event-driven task generation, e.g. after a new bird is created).
  /// If null, scan all birds (used for daily batch generation).
  Future<List<PluginTaskDescriptor>> detectTasks(AppDatabase db, {int? birdId}) async => [];

  /// Register event handlers — subscribe to domain events from other plugins.
  void registerEvents(EventBus bus) {}

  // ── Task card navigation ──

  /// Called when a task card owned by this plugin is tapped.
  /// Return a widget to navigate to (typically [BirdDetailScreen]), or null
  /// to prevent navigation. Default returns null (no navigation).
  Widget? onTaskCardTap(BuildContext context, int birdId) => null;
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

// ── Quick actions ──

/// A quick-action button contributed by a plugin to the home screen.
class QuickAction {
  final String label;
  final IconData icon;
  final Widget Function() builder;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.builder,
  });
}

// ── Enclosure weigh action ──

/// A weigh button shown on enclosure cards.
/// Plugins that can weigh birds by enclosure implement this.
class EnclosureWeighAction {
  final IconData icon;
  final String tooltip;
  /// builder receives enclosureId, returns the weigh page widget.
  final Widget Function(int enclosureId) builder;

  const EnclosureWeighAction({
    required this.icon,
    required this.tooltip,
    required this.builder,
  });
}

// ── Room weigh action ──

/// A weigh button shown on room cards.
/// Plugins that can weigh birds by room implement this.
class RoomWeighAction {
  final IconData icon;
  final String tooltip;
  /// builder receives roomId, returns the weigh page widget.
  final Widget Function(int roomId) builder;

  const RoomWeighAction({
    required this.icon,
    required this.tooltip,
    required this.builder,
  });
}

// ── Alert severity ──

enum AlertSeverity { warning, danger }

/// An anomaly alert contributed by a plugin's [FeaturePlugin.detectAlerts].
class PluginAlert {
  final int birdId;
  final String type;
  final String description;
  final AlertSeverity severity;

  const PluginAlert({
    required this.birdId,
    required this.type,
    required this.description,
    this.severity = AlertSeverity.warning,
  });
}

// ── Task descriptors ──

/// A task descriptor contributed by a plugin's [FeaturePlugin.detectTasks].
///
/// Multiple descriptors with the same [birdId] and [taskType] are allowed
/// (e.g. medication 3× daily with different [dueDate] times).
/// Deduplication is by (birdId, taskType, dueDate).
class PluginTaskDescriptor {
  final int birdId;
  final String taskType;
  final DateTime dueDate;
  final DateTime? deadline;
  final String label;
  final Map<String, String>? metadata;

  const PluginTaskDescriptor({
    required this.birdId,
    required this.taskType,
    required this.dueDate,
    this.deadline,
    required this.label,
    this.metadata,
  });
}
