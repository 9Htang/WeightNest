import 'package:flutter/foundation.dart' show kDebugMode;
import '../core/plugin_registry.dart';
export '../core/plugin_registry.dart' show pluginRegistry;
import 'breeding/breeding_plugin.dart';
import 'debug/debug_plugin.dart';
import 'medication/medication_plugin.dart';
import 'weight/weight_plugin.dart';

/// Register all plugins on the global registry.
/// Adding a new feature = importing its plugin + one line below.
void registerPlugins() {
  pluginRegistry
    ..register(WeightPlugin())
    ..register(MedicationPlugin())
    ..register(BreedingPlugin());

  if (kDebugMode) {
    pluginRegistry.register(DebugPlugin());
  }
}
