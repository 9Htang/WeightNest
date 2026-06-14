import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../widgets/weight_chart.dart';
import '../../repositories/weight_repository.dart';
import '../../repositories/bird_repository.dart';
import '../../screens/weigh/weigh_grid_screen.dart';
import '../../screens/birds/bird_detail_screen.dart';
import 'weight_table.dart';
import 'weight_config_screen.dart';

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
          uniqueness: PageUniqueness.none,
          showInSidebar: true,
          builder: (ctx) => WeighGridScreen(
            initialRoomId: ctx.params['roomId'] as int?,
            initialBirdId: ctx.birdId,
          ),
        ),
      ];

  // ── Slot E: 首页快捷操作 ──

  @override
  List<QuickAction> get quickActions => [
        QuickAction(
          label: '快速称重',
          icon: Icons.monitor_weight,
          builder: () => const WeighGridScreen(),
        ),
      ];

  // ── Slot G: 容器称重 ──

  @override
  EnclosureWeighAction? get enclosureWeighAction => EnclosureWeighAction(
        icon: Icons.monitor_weight,
        tooltip: '称重',
        builder: (enclosureId) => WeighGridScreen(initialEnclosureId: enclosureId),
      );

  // ── Slot H: 房间称重 ──

  @override
  RoomWeighAction? get roomWeighAction => RoomWeighAction(
        icon: Icons.monitor_weight,
        tooltip: '称重',
        builder: (roomId) => WeighGridScreen(initialRoomId: roomId),
      );

  // ── Plugin settings ──

  @override
  WidgetBuilder? get settingsBuilder => (_) => const WeightConfigScreen();

  // ── Task card navigation ──

  @override
  Widget? onTaskCardTap(BuildContext context, int birdId) {
    final db = pluginRegistry.db;
    if (db == null) return null;
    return _WeightTaskDetailPage(birdId: birdId, initialPluginId: id);
  }

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

/// Loads bird details and shows [BirdDetailScreen] for task card tap navigation.
class _WeightTaskDetailPage extends StatelessWidget {
  final int birdId;
  final String? initialPluginId;
  const _WeightTaskDetailPage({required this.birdId, this.initialPluginId});

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('详情')),
        body: const Center(child: Text('数据库未初始化')),
      );
    }
    return FutureBuilder<BirdWithDetails?>(
      future: db.getWithDetails(birdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final bird = snapshot.data;
        if (bird == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('详情')),
            body: const Center(child: Text('未找到该鹦鹉')),
          );
        }
        return BirdDetailScreen(bird: bird, initialPluginId: initialPluginId);
      },
    );
  }
}
