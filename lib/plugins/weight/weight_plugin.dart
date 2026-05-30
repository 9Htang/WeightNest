import 'package:flutter/material.dart';
import 'package:shelf_router/shelf_router.dart' as shelf;
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../desktop/widgets/weight_chart.dart';
import '../../repositories/weight_repository.dart';
import 'weight_table.dart';
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
  Map<String, WidgetBuilder> routes(AppDatabase db) => const {
        // Weigh screen is accessed via pages[] sidebar entry, not routes
      };

  @override
  List<PluginPageDescriptor> get pages => [
        PluginPageDescriptor(
          key: 'weigh',
          title: '称重录入',
          icon: Icons.monitor_weight,
          uniqueness: PageUniqueness.perBird,
          showInSidebar: true,
          builder: (ctx) => const Placeholder(), // TODO: wire weigh screen
        ),
      ];

  @override
  shelf.Router? serverRoutes(AppDatabase db) => createWeightRoutes(db);

  @override
  List<DetailSection> buildDetailSections(int birdId) => [
    DetailSection(
      title: '体重趋势与记录',
      icon: Icons.show_chart,
      priority: 10,
      child: _WeightDetailView(birdId: birdId),
    ),
  ];
}

class _WeightDetailView extends StatelessWidget {
  final int birdId;

  const _WeightDetailView({required this.birdId});

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) return const SizedBox.shrink();

    return FutureBuilder<List<Weight>>(
      future: db.getByBird(birdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }
        final weights = snapshot.data ?? [];
        return Column(children: [
          WeightChartWidget(weights: weights, chartHeight: 260),
          const SizedBox(height: 12),
          WeightTable(db: db, birdId: birdId),
        ]);
      },
    );
  }
}
