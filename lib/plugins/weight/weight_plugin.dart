import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../../core/plugin.dart';
import '../../database/database.dart';
import 'weight_routes.dart';

class WeightPlugin extends FeaturePlugin {
  @override
  String get id => 'weights';

  @override
  String get displayName => '称重';

  @override
  String get description => '体重记录、趋势图表、AI 预警分析';

  @override
  IconData get icon => Icons.monitor_weight_outlined;

  @override
  IconData get selectedIcon => Icons.monitor_weight;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {};

  @override
  shelf.Router? serverRoutes(AppDatabase db) => createWeightRoutes(db);
}
