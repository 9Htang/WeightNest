import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../database/database.dart';
import 'debug_dashboard_screen.dart';

class DebugPlugin extends FeaturePlugin {
  @override
  String get id => 'debug';

  @override
  String get displayName => '调试';

  @override
  String get description => '数据库检查、日志查看、插件状态、任务编辑、时间注入';

  @override
  IconData get icon => Icons.bug_report_outlined;

  @override
  IconData get selectedIcon => Icons.bug_report;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  @override
  List<PluginPageDescriptor> get pages => const [];

  @override
  WidgetBuilder? get settingsBuilder => (_) => const DebugDashboardScreen();
}
