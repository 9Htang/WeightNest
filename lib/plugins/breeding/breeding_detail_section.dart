import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weight_nest/core/plugin_registry.dart';
import 'package:weight_nest/database/database.dart';
import 'package:weight_nest/plugins/breeding/breeding_repository.dart';
import 'package:weight_nest/repositories/bird_repository.dart';
import 'package:weight_nest/screens/birds/bird_detail_screen.dart';
import 'package:weight_nest/widgets/feather_icon.dart';
import 'breeding_record_screen.dart';

/// 嵌入鹦鹉详情页的繁育插件摘要卡片
class BreedingDetailSection extends StatefulWidget {
  final int birdId;

  const BreedingDetailSection({super.key, required this.birdId});

  @override
  State<BreedingDetailSection> createState() => _BreedingDetailSectionState();
}

class _BreedingDetailSectionState extends State<BreedingDetailSection> {
  late final Future<_BreedingDetailData?> _dataFuture;

  @override
  void initState() {
    super.initState();
    final db = pluginRegistry.db;
    // Cache the future once so parent rebuilds don't re-issue the whole query
    // chain. When the DB isn't available, resolve to null (renders nothing).
    _dataFuture =
        db == null ? Future.value(null) : _loadBreedingDetail(db);
  }

  /// Kick off all lineage/breeding queries concurrently. Each future starts
  /// immediately; awaiting them in sequence yields as soon as the slowest one
  /// resolves, so the section waits for one round-trip instead of five.
  Future<_BreedingDetailData?> _loadBreedingDetail(AppDatabase db) async {
    final pairFuture = db.getActivePairForBird(widget.birdId);
    final recordFuture = db.getActiveRecordForBird(widget.birdId);
    final parentsFuture = db.getBirdParents(widget.birdId);
    final offspringFuture = db.getBirdOffspring(widget.birdId);
    final siblingsFuture = db.getBirdSiblings(widget.birdId);

    return _BreedingDetailData(
      pair: await pairFuture,
      record: await recordFuture,
      parents: await parentsFuture,
      offspring: await offspringFuture,
      siblings: await siblingsFuture,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = pluginRegistry.db;
    if (db == null) return const SizedBox.shrink();

    return FutureBuilder<_BreedingDetailData?>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        final hasBreedingInfo = data.pair != null;
        final hasLineage = data.parents != null ||
            data.offspring.isNotEmpty ||
            data.siblings.isNotEmpty;

        if (!hasBreedingInfo && !hasLineage) {
          return _buildEmpty(context);
        }

        return Column(
          children: [
            if (hasBreedingInfo)
              _buildBreedingInfo(context, data.pair!, data.record),
            if (hasBreedingInfo && hasLineage) const SizedBox(height: 8),
            if (hasLineage)
              _buildLineageCard(
                  context, data.parents, data.offspring, data.siblings),
          ],
        );
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
              FeatherIcon(size: 36, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('该鸟暂无繁育记录', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  /// Lineage card showing parents, offspring, and siblings.
  Widget _buildLineageCard(
    BuildContext context,
    ({Bird father, Bird mother})? parents,
    List<({Bird chick, Bird father, Bird mother})> offspring,
    List<Bird> siblings,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('族谱',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),

            // ── 父母 ──
            if (parents != null) ...[
              _lineageRow(
                context,
                icon: Icons.arrow_upward,
                color: Colors.blue,
                label: '亲鸟',
                children: [
                  _LineageBirdChip(
                    bird: parents.father,
                    relation: '父',
                    color: Colors.blue,
                    onTap: () => _navigateToBird(context, parents.father.id),
                  ),
                  const SizedBox(width: 8),
                  _LineageBirdChip(
                    bird: parents.mother,
                    relation: '母',
                    color: Colors.pink,
                    onTap: () => _navigateToBird(context, parents.mother.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // ── 后代 ──
            if (offspring.isNotEmpty) ...[
              _lineageRow(
                context,
                icon: Icons.arrow_downward,
                color: Colors.green,
                label: '后代 (${offspring.length})',
                children: offspring
                    .map((o) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _LineageBirdChip(
                            bird: o.chick,
                            relation: '后代',
                            color: Colors.green,
                            onTap: () => _navigateToBird(context, o.chick.id),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            // ── 兄弟姐妹 ──
            if (siblings.isNotEmpty) ...[
              _lineageRow(
                context,
                icon: Icons.people_outline,
                color: Colors.orange,
                label: '同胞 (${siblings.length})',
                children: siblings
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _LineageBirdChip(
                            bird: s,
                            relation: '同胞',
                            color: Colors.orange,
                            onTap: () => _navigateToBird(context, s.id),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lineageRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: children,
        ),
      ],
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
    final isMale = pair.maleBirdId == widget.birdId;
    final partnerBirdId = isMale ? pair.femaleBirdId : pair.maleBirdId;
    final partnerBirdName =
        record != null ? (isMale ? record.$4.name : record.$3.name) : null;

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
                Text('配对伙伴: ',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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

                  final incubating =
                      eggs.where((e) => e.status == '孵化中').length;
                  final hatched = eggs.where((e) => e.status == '已出壳').length;
                  final unfertilized =
                      eggs.where((e) => e.status == '未受精').length;
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
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BreedingRecordDetailScreen(pairId: pair.id),
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
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BirdDetailScreen(
            bird: birdWithDetails,
            initialPluginId: 'breeding',
          ),
        ));
  }
}

/// Data holder for breeding detail async queries.
class _BreedingDetailData {
  final BreedingPair? pair;
  final (BreedingRecord, BreedingPair, Bird male, Bird female)? record;
  final ({Bird father, Bird mother})? parents;
  final List<({Bird chick, Bird father, Bird mother})> offspring;
  final List<Bird> siblings;

  _BreedingDetailData({
    this.pair,
    this.record,
    this.parents,
    this.offspring = const [],
    this.siblings = const [],
  });
}

/// A chip displaying a bird's name and relation, used in lineage display.
class _LineageBirdChip extends StatelessWidget {
  final Bird bird;
  final String relation;
  final Color color;
  final VoidCallback onTap;

  const _LineageBirdChip({
    required this.bird,
    required this.relation,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withAlpha(20),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeatherIcon(size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              bird.name,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: color.withAlpha(40),
              ),
              child: Text(
                relation,
                style: TextStyle(
                    fontSize: 9, color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
