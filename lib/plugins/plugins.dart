import '../core/plugin_registry.dart';
import 'medication/medication_plugin.dart';
import 'weight/weight_plugin.dart';

/// Global plugin registry — the single place where all feature plugins
/// are registered. Adding a new feature = importing its plugin + one line below.
final pluginRegistry = PluginRegistry()
  ..register(WeightPlugin())
  ..register(MedicationPlugin());
