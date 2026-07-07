import 'package:flutter/foundation.dart' show kDebugMode;
import '../core/plugin_registry.dart';
export '../core/plugin_registry.dart' show pluginRegistry;
import 'breeding/breeding_plugin.dart';
import 'debug/debug_plugin.dart';
import 'gallery/gallery_plugin.dart';
import 'medication/medication_plugin.dart';
import 'nutrition/nutrition_plugin.dart';
import 'stage/stage_plugin.dart';
import 'weight/weight_plugin.dart';

/// Register all plugins on the global registry.
/// Adding a new feature = importing its plugin + one line below.
void registerPlugins() {
  pluginRegistry
    // stage 必须最先注册：它是其他插件读取生理阶段的基础设施。
    ..register(StagePlugin())
    ..register(WeightPlugin())
    ..register(MedicationPlugin())
    ..register(BreedingPlugin())
    ..register(GalleryPlugin())
    ..register(NutritionPlugin());

  if (kDebugMode) {
    pluginRegistry.register(DebugPlugin());
  }
}
