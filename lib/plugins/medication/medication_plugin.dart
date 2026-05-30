import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../../core/plugin.dart';
import '../../core/event_bus.dart';
import 'medication_screen.dart';
import 'medication_routes.dart';

class MedicationPlugin extends FeaturePlugin {
  @override
  String get id => 'medication';

  @override
  String get displayName => '喂药';

  @override
  IconData get icon => Icons.medication_outlined;

  @override
  IconData get selectedIcon => Icons.medication;

  @override
  List<dynamic> get tables => const [];

  @override
  Map<String, WidgetBuilder> get routes => {
        '/medication': (_) => const MedicationScreen(),
      };

  @override
  shelf.Router get serverRoutes => createMedicationRoutes();

  @override
  void registerEvents(EventBus bus) {
    // 示例：当称重记录后，如果体重下降 >5% 自动标记需要检查喂药
    // bus.on<WeightRecorded>((e) {
    //   if (e.previousWeight != null && e.weightG < e.previousWeight! * 0.95) {
    //     // trigger medication review alert
    //   }
    // });
  }
}
