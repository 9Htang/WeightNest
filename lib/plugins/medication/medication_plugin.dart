import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../../core/plugin.dart';
import '../../core/event_bus.dart';
import '../../database/database.dart';
import 'medication_screen.dart';
import 'medication_routes.dart';

class MedicationPlugin extends FeaturePlugin {
  @override
  String get id => 'medication';

  @override
  String get displayName => '喂药';

  @override
  String get description => '药品类型、剂量、频率管理，自动生成定时喂药任务';

  @override
  IconData get icon => Icons.medication_outlined;

  @override
  IconData get selectedIcon => Icons.medication;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> routes(AppDatabase db) => {
        '/medication': (_) => MedicationScreen(db: db),
      };

  @override
  shelf.Router? serverRoutes(AppDatabase db) => createMedicationRoutes(db);

  @override
  void registerEvents(EventBus bus) {
    // 未来：体重骤降 → 自动提示检查喂药计划
    // bus.on<WeightRecorded>((e) { ... });
  }
}
