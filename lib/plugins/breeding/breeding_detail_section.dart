import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weight_nest/core/plugin_registry.dart';
import 'package:weight_nest/database/database.dart';
import 'package:weight_nest/plugins/breeding/breeding_repository.dart';
import 'package:weight_nest/repositories/bird_repository.dart';
import 'package:weight_nest/screens/birds/bird_detail_screen.dart';
import 'breeding_record_screen.dart';

/// 嵌入鹦鹉详情页的繁育插件摘要卡片
class BreedingDetailSection extends StatelessWidget {
  final int birdId;

  const BreedingDetailSection({super.key, required this.birdId});

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) return const SizedBox.shrink();

    return FutureBuilder<({BreedingPair? pair, (BreedingRecord, BreedingPair, Bird male, Bird female)? record})>(
      future: () async {
        final pair = await db.getActivePairForBird(birdId);
        (BreedingRecord, BreedingPair, Bird male, Bird female)? record;
        if (pair != null) {
          record = await db.getActiveRecordForBird(birdId);
        }
        return (pair: pair, record: record);
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        final pair = data?.pair;
        final record = data?.record;

        if (pair == null) {
          return _buildEmpty(context);
        }

        return _buildBreedingInfo(context, pair, record);
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_outlined, size: 36, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('该鸟暂无繁育记录',
                  style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreedingInfo(
    BuildContext context,
    BreedingPair pair,
    (BreedingRecord, BreedingPair, Bird male, Bird female)? record,
  ) {
    final theme = Theme.of(context);
    final db = pluginRegistry.db!;

    // Determine partner bird
    final isMale = pair.maleBirdId == birdId;
    final partnerBirdId = isMale ? pair.femaleBirdId : pair.maleBirdId;
    final partnerBirdName = record != null
        ? (isMale ? record.$4.name : record.$3.name)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 配对伙伴
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.pink.shade300),
                const SizedBox(width: 6),
                Text('配对伙伴: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (partnerBirdName != null)
                  GestureDetector(
                    onTap: () => _navigateToBird(context, partnerBirdId),
                    child: Text(
                      partnerBirdName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(isMale ? '母鸟' : '公鸟',
                      style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),

            if (record != null) ...[
              const SizedBox(height: 8),
              // 当前阶段
              Row(
                children: [
                  const Text('当前阶段: ', style: TextStyle(fontSize: 13)),
                  _stageChip(record.$1.stage),
                ],
              ),

              // 最新踩背日期
              _asyncMatingDate(db, record.$1.id),

              // 蛋摘要
              const SizedBox(height: 6),
              FutureBuilder<List<Egg>>(
                future: db.getEggsByRecord(record.$1.id),
                builder: (context, eggsSnapshot) {
                  final eggs = eggsSnapshot.data ?? [];
                  if (eggs.isEmpty) return const SizedBox.shrink();

                  final incubating = eggs.where((e) => e.status == '孵化中').length;
                  final hatched = eggs.where((e) => e.status == '已出壳').length;
                  final unfertilized = eggs.where((e) => e.status == '未受精').length;
                  final damaged = eggs.where((e) => e.status == '损坏').length;

                  final parts = <String>[];
                  if (incubating > 0) parts.add('$incubating 孵化中');
                  if (hatched > 0) parts.add('$hatched 已出壳');
                  if (unfertilized > 0) parts.add('$unfertilized 未受精');
                  if (damaged > 0) parts.add('$damaged 损坏');

                  return Row(
                    children: [
                      const Text('蛋: ', style: TextStyle(fontSize: 13)),
                      Text(
                        '${eggs.length} 颗 · ${parts.join(" ")}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 12),
            // 查看详情按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('查看详情'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BreedingRecordDetailScreen(pairId: pair.id),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _asyncMatingDate(AppDatabase db, int recordId) {
    return FutureBuilder<List<MatingEvent>>(
      future: db.getMatingEventsByRecord(recordId),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const SizedBox.shrink();

        final latest = events.first;
        return Row(
          children: [
            Icon(Icons.favorite, size: 12, color: Colors.pink.shade200),
            const SizedBox(width: 4),
            Text(
              '最近踩背: ${DateFormat('MM-dd').format(latest.observedDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }

  Widget _stageChip(String stage) {
    final color = _stageColor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withAlpha(30),
      ),
      child: Text(stage,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case '配对':
        return Colors.blue;
      case '产蛋':
        return Colors.orange;
      case '孵化':
        return Colors.purple;
      case '育雏':
        return Colors.teal;
      case '已完结':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _navigateToBird(BuildContext context, int birdId) async {
    final db = pluginRegistry.db;
    if (db == null) return;
    final birdWithDetails = await db.getWithDetails(birdId);
    if (!context.mounted || birdWithDetails == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BirdDetailScreen(
        bird: birdWithDetails,
        initialPluginId: 'breeding',
      ),
    ));
  }
}
