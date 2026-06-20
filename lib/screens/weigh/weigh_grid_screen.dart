import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../plugins/weight/weight_plugin.dart';
import '../../plugins/weight/grid_color_config.dart';

import '../worker/worker_screen.dart';
import 'weigh_grid_provider.dart';
import 'weigh_input_widgets.dart';
import '../birds/bird_detail_screen.dart';

class WeighGridScreen extends ConsumerStatefulWidget {
  final int? initialRoomId;
  final int? initialEnclosureId;
  final int? initialBirdId;

  const WeighGridScreen({
    super.key,
    this.initialRoomId,
    this.initialEnclosureId,
    this.initialBirdId,
  });

  @override
  ConsumerState<WeighGridScreen> createState() => _WeighGridScreenState();
}

const _headerHeight = 36.0;

class _WeighGridScreenState extends ConsumerState<WeighGridScreen> {
  final _scrollController = ScrollController();
  double _colWidth = 152.0; // 运行时计算，首帧后被 cfg.minColumnWidth 覆盖

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final workerId = ref.read(workerProvider).userId;
      final notifier = ref.read(weighGridProvider.notifier);
      notifier.setUserId(workerId);
      await notifier.init(
        initialRoomId: widget.initialRoomId,
        initialEnclosureId: widget.initialEnclosureId,
        initialBirdId: widget.initialBirdId,
      );
      // After init completes and state is built, scroll to the selected bird
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedBird());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll horizontally to the column containing the selected bird.
  void _scrollToSelectedBird() {
    final state = ref.read(weighGridProvider);
    final birdId = state.selectedBirdId;
    if (birdId == null) return;
    if (!_scrollController.hasClients) return;

    // Find which non-empty column contains the target bird
    int nonEmptyIdx = -1;
    for (final col in state.columns) {
      if (col.isEmpty) continue;
      nonEmptyIdx++;
      for (final group in col.groups) {
        if (group.birds.any((b) => b.bird.id == birdId)) {
          final viewport = _scrollController.position.viewportDimension;
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetOffset = (nonEmptyIdx * _colWidth) - (viewport / 2) + (_colWidth / 2);
          _scrollController.animateTo(
            targetOffset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 仅订阅选中态 / 断奶标记（按键时不变）→ AppBar、布局比例、图例不随打字重建
    final selected = ref.watch(weighGridProvider.select((s) => s.selectedBirdId));
    final hasWeaning =
        ref.watch(weighGridProvider.select((s) => s.weaningBirdIds.isNotEmpty));
    final cfg = ref.watch(gridColorConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRoomId != null ? '房间称重' : '快速称重'),
        actions: [
          if (selected != null)
            TextButton.icon(
              onPressed: () => ref.read(weighGridProvider.notifier).deselectBird(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('取消'),
            ),
        ],
      ),
      body: Stack(
        children: [
          // z=0: 表格 + 输入面板
          Column(
            children: [
              Expanded(
                flex: selected != null ? 3 : 10,
                child: Consumer(builder: (context, ref, _) {
                  // 表格列：仅订阅结构/选中/异常/断奶/最新体重 → 打字时不重建
                  final s = ref.watch(weighGridProvider.select((s) => (
                        s.columns,
                        s.selectedBirdId,
                        s.abnormalDirections,
                        s.weaningBirdIds,
                        s.latestWeights,
                        s.weighedTodayBirdIds,
                        s.overdueBirdIds,
                      )));
                  final columns = s.$1;
                  if (columns.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final nonEmpty = columns.where((c) => !c.isEmpty).length;
                      final avail = constraints.maxWidth - 16;
                      _colWidth = nonEmpty > 0
                          ? (avail / nonEmpty).clamp(cfg.minColumnWidth, avail)
                          : avail;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          border: Border.all(color: scheme.outlineVariant.withAlpha(50), width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _scrollController,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: columns.map((col) {
                              return _RoomColumnWidget(
                                width: _colWidth,
                                column: col,
                                selectedBirdId: s.$2,
                                abnormalDirections: s.$3,
                                weaningBirdIds: s.$4,
                                latestWeights: s.$5,
                                weighedTodayBirdIds: s.$6,
                                overdueBirdIds: s.$7,
                                colorConfig: cfg,
                                theme: theme,
                                scheme: scheme,
                                onTapBird: (birdId) {
                                  ref.read(weighGridProvider.notifier).selectBird(birdId);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: selected != null
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Consumer(builder: (context, ref, _) {
                  // 输入面板：仅订阅输入态 → 仅面板随打字重建（表格列不受影响）
                  final s = ref.watch(weighGridProvider.select((s) => (
                        s.selectedBirdId,
                        s.weightText,
                        s.isFasting,
                        s.isSaving,
                        s.message,
                        s.lastWeigh,
                        s.birdById,
                      )));
                  return _WeighInputPanel(
                    selectedBirdId: s.$1,
                    weightText: s.$2,
                    isFasting: s.$3,
                    isSaving: s.$4,
                    message: s.$5,
                    lastWeigh: s.$6,
                    birdById: s.$7,
                    theme: theme,
                    notifier: ref.read(weighGridProvider.notifier),
                  );
                }),
              ),
            ],
          ),
          // z=1: 多状态图例 — 屏幕右下角，选中鸟时隐藏
          if (cfg.showLegend && selected == null)
            Positioned(
              bottom: 8,
              right: 12,
              child: _Legend(config: cfg, hasWeaning: hasWeaning),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 房间列
// ═══════════════════════════════════════════════

class _RoomColumnWidget extends StatelessWidget {
  final double width;
  final RoomColumn column;
  final int? selectedBirdId;
  final Map<int, AbnormalDirection> abnormalDirections;
  final Set<int> weaningBirdIds;
  final Map<int, Weight?> latestWeights;
  final Set<int> weighedTodayBirdIds;
  final Set<int> overdueBirdIds;
  final GridColorConfig colorConfig;
  final ThemeData theme;
  final ColorScheme scheme;
  final ValueChanged<int> onTapBird;

  const _RoomColumnWidget({
    required this.width,
    required this.column,
    required this.selectedBirdId,
    required this.abnormalDirections,
    required this.weaningBirdIds,
    required this.latestWeights,
    required this.weighedTodayBirdIds,
    required this.overdueBirdIds,
    required this.colorConfig,
    required this.theme,
    required this.scheme,
    required this.onTapBird,
  });

  @override
  Widget build(BuildContext context) {
    if (column.isEmpty) return const SizedBox.shrink();

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: scheme.outlineVariant.withAlpha(50), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 列标题 — Excel 风格
          Container(
            height: _headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant, width: 1.5),
              ),
            ),
            child: Center(
              child: Text(
                column.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withAlpha(200),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // 容器分组
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: column.groups.map((group) {
                  return _GroupSection(
                    group: group,
                    selectedBirdId: selectedBirdId,
                    abnormalDirections: abnormalDirections,
                    weaningBirdIds: weaningBirdIds,
                    latestWeights: latestWeights,
                    weighedTodayBirdIds: weighedTodayBirdIds,
                    overdueBirdIds: overdueBirdIds,
                    colorConfig: colorConfig,
                    theme: theme,
                    scheme: scheme,
                    onTapBird: onTapBird,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 容器分组
// ═══════════════════════════════════════════════

class _GroupSection extends StatelessWidget {
  final BirdGroup group;
  final int? selectedBirdId;
  final Map<int, AbnormalDirection> abnormalDirections;
  final Set<int> weaningBirdIds;
  final Map<int, Weight?> latestWeights;
  final Set<int> weighedTodayBirdIds;
  final Set<int> overdueBirdIds;
  final GridColorConfig colorConfig;
  final ThemeData theme;
  final ColorScheme scheme;
  final ValueChanged<int> onTapBird;

  const _GroupSection({
    required this.group,
    required this.selectedBirdId,
    required this.abnormalDirections,
    required this.weaningBirdIds,
    required this.latestWeights,
    required this.weighedTodayBirdIds,
    required this.overdueBirdIds,
    required this.colorConfig,
    required this.theme,
    required this.scheme,
    required this.onTapBird,
  });

  @override
  Widget build(BuildContext context) {
    if (group.birds.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 容器分组头 — Excel 风格横条
        if (group.enclosure != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(80),
              border: Border(
                top: BorderSide(color: scheme.outlineVariant.withAlpha(40), width: 0.5),
                bottom: BorderSide(color: scheme.outlineVariant.withAlpha(40), width: 0.5),
              ),
            ),
            child: Text(
              group.label,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurface.withAlpha(140),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // 鸟单元格
        ...group.birds.map((bird) {
          return _BirdCell(
            bird: bird,
            isSelected: bird.bird.id == selectedBirdId,
            abnormalDirection: abnormalDirections[bird.bird.id] ?? AbnormalDirection.none,
            isWeaning: weaningBirdIds.contains(bird.bird.id),
            isWeighedToday: weighedTodayBirdIds.contains(bird.bird.id),
            isOverdue: overdueBirdIds.contains(bird.bird.id),
            latestWeight: latestWeights[bird.bird.id],
            colorConfig: colorConfig,
            theme: theme,
            scheme: scheme,
            onTap: () => onTapBird(bird.bird.id),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// 图例组件
// ═══════════════════════════════════════════════

class _Legend extends StatelessWidget {
  final GridColorConfig config;
  final bool hasWeaning;
  const _Legend({required this.config, required this.hasWeaning});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <(BirdCellState, String)>[
      (BirdCellState.overdue, '超期未称'),
      (BirdCellState.abnormalHigh, '体重偏高'),
      (BirdCellState.abnormalLow, '体重偏低'),
      (BirdCellState.weighedToday, '今日已称'),
      if (hasWeaning) (BirdCellState.weaning, '断奶期'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final color = config.borderColor(item.$1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: config.displayMode == CellDisplayMode.border
                        ? Colors.transparent
                        : color.withValues(alpha: config.fillOpacity * 3),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withAlpha(180),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 鸟单元格 — 多色版本
// ═══════════════════════════════════════════════

/// 按优先级解析命中的所有单元格状态（已排序，第一个即主状态）。
/// 优先级：超期 > 体重偏高 > 体重偏低 > 今日已称 > 断奶期。
List<BirdCellState> _resolveStates({
  required bool isOverdue,
  required AbnormalDirection abnormalDirection,
  required bool isWeighedToday,
  required bool isWeaning,
}) {
  final states = <BirdCellState>[];
  if (isOverdue) states.add(BirdCellState.overdue);
  if (abnormalDirection == AbnormalDirection.high) states.add(BirdCellState.abnormalHigh);
  if (abnormalDirection == AbnormalDirection.low) states.add(BirdCellState.abnormalLow);
  if (isWeighedToday) states.add(BirdCellState.weighedToday);
  if (isWeaning) states.add(BirdCellState.weaning);
  return states;
}

/// 固定在单元格右上角的小角标，展示被主状态"压缩"掉的次要状态。
/// 绝对定位，不参与 Row 布局，尺寸固定。
class _CornerBadge extends StatelessWidget {
  final List<BirdCellState> states;
  final GridColorConfig colorConfig;

  const _CornerBadge({required this.states, required this.colorConfig});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: states.map((s) {
        final c = colorConfig.borderColor(s);
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
          ),
        );
      }).toList(),
    );
  }
}

class _BirdCell extends StatelessWidget {
  final BirdWithDetails bird;
  final bool isSelected;
  final AbnormalDirection abnormalDirection;
  final bool isWeaning;
  final bool isWeighedToday;
  final bool isOverdue;
  final Weight? latestWeight;
  final GridColorConfig colorConfig;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _BirdCell({
    required this.bird,
    required this.isSelected,
    required this.abnormalDirection,
    required this.isWeaning,
    required this.isWeighedToday,
    required this.isOverdue,
    required this.latestWeight,
    required this.colorConfig,
    required this.theme,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeStates = _resolveStates(
      isOverdue: isOverdue,
      abnormalDirection: abnormalDirection,
      isWeighedToday: isWeighedToday,
      isWeaning: isWeaning,
    );
    final cellState = activeStates.isEmpty ? BirdCellState.normal : activeStates.first;
    final secondaryStates = activeStates.length > 1
        ? activeStates.sublist(1, activeStates.length > 3 ? 3 : activeStates.length)
        : const <BirdCellState>[];
    final stateColor = cellState == BirdCellState.normal
        ? null
        : colorConfig.borderColor(cellState);
    final mode = colorConfig.displayMode;

    // 背景色
    Color? bgColor;
    if (isSelected) {
      bgColor = scheme.primaryContainer.withAlpha(60);
    } else if (stateColor != null &&
        (mode == CellDisplayMode.fill || mode == CellDisplayMode.borderAndFill)) {
      bgColor = stateColor.withValues(alpha: colorConfig.fillOpacity);
    }

    // 边框
    BorderSide border(BorderSide fallback) {
      if (isSelected) {
        return BorderSide(color: scheme.primary, width: 2.5);
      }
      if (stateColor != null &&
          (mode == CellDisplayMode.border || mode == CellDisplayMode.borderAndFill)) {
        return BorderSide(color: stateColor, width: colorConfig.borderWidth);
      }
      return fallback;
    }

    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                left: isSelected
                    ? BorderSide(color: scheme.primary, width: 2.5)
                    : (stateColor != null &&
                            (mode == CellDisplayMode.border || mode == CellDisplayMode.borderAndFill))
                        ? BorderSide(color: stateColor, width: colorConfig.borderWidth)
                        : BorderSide.none,
                top: border(BorderSide(color: scheme.outlineVariant.withAlpha(30), width: 0.5)),
                right: border(BorderSide.none),
                bottom: border(BorderSide(color: scheme.outlineVariant.withAlpha(30), width: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  bird.growthStage == '雏鸟' ? '🐣' : bird.growthStage == '幼鸟' ? '🐤' : '🦜',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: bird.bird.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? scheme.primary : scheme.onSurface,
                          ),
                        ),
                        if (bird.bird.ringNumber != null)
                          TextSpan(
                            text: ' #${bird.bird.ringNumber}',
                            style: TextStyle(
                              fontSize: 10,
                              color: (isSelected ? scheme.primary : scheme.onSurface).withAlpha(140),
                            ),
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (latestWeight != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '${latestWeight!.weightG.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (isSelected ? scheme.primary : scheme.onSurface).withAlpha(180),
                      ),
                    ),
                  ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.edit, size: 12, color: scheme.primary),
                  ),
              ],
            ),
          ),
          if (secondaryStates.isNotEmpty)
            Positioned(
              top: 3,
              right: 3,
              child: _CornerBadge(states: secondaryStates, colorConfig: colorConfig),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 填值面板
// ═══════════════════════════════════════════════

class _WeighInputPanel extends StatelessWidget {
  final int? selectedBirdId;
  final String weightText;
  final bool isFasting;
  final bool isSaving;
  final String? message;
  final Weight? lastWeigh;
  final Map<int, BirdWithDetails> birdById;
  final ThemeData theme;
  final WeighGridNotifier notifier;

  const _WeighInputPanel({
    required this.selectedBirdId,
    required this.weightText,
    required this.isFasting,
    required this.isSaving,
    required this.message,
    required this.lastWeigh,
    required this.birdById,
    required this.theme,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final birdId = selectedBirdId;
    if (birdId == null) return const SizedBox.shrink();

    // O(1) 查找选中鸟，替代原遍历全部列/分组的嵌套循环
    final bird = birdById[birdId];
    final scheme = theme.colorScheme;
    final lastWeigh = this.lastWeigh;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withAlpha(40))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 鸟信息栏 + 上次称重
              if (bird != null)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BirdDetailScreen(
                                  bird: bird,
                                  initialPluginId: 'weights',
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bird.bird.name,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (bird.bird.ringNumber != null) ...[
                                    const SizedBox(width: 6),
                                    Text('#${bird.bird.ringNumber}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                  const SizedBox(width: 4),
                                  Icon(Icons.open_in_new, size: 12, color: scheme.onSurface.withAlpha(120)),
                                ],
                              ),
                            ),
                          ),
                          if (lastWeigh != null)
                            Text(
                              '上次: ${_fmtDate(lastWeigh.recordedAt)}  ·  ${lastWeigh.weightG.toStringAsFixed(1)}g',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(130),
                              ),
                            )
                          else
                            Text(
                              '暂无称重记录',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(100),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (weightText.isNotEmpty)
                      TextButton(
                        onPressed: notifier.clearWeight,
                        child: const Text('清空'),
                      ),
                    FilledButton(
                      onPressed: isSaving ? null : notifier.saveWeight,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('保存', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // 体重显示
              WeighDisplay(
                weightText: weightText,
                message: message,
                theme: theme,
              ),
              const SizedBox(height: 8),
              // 快速调整
              QuickAdjustBar(
                isFasting: isFasting,
                theme: theme,
                onMinus1: () => notifier.adjustWeight(-1),
                onMinus10: () => notifier.adjustWeight(-10),
                onPlus1: () => notifier.adjustWeight(1),
                onPlus10: () => notifier.adjustWeight(10),
                onToggleFasting: () => notifier.setFasting(!isFasting),
              ),
              // 数字键盘
              WeighNumPad(
                onDigit: notifier.appendDigit,
                onDelete: notifier.deleteDigit,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
