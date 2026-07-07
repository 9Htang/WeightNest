import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';
import '../../plugins/weight/weight_plugin.dart';
import '../../plugins/weight/grid_color_config.dart';
import '../../theme/app_tokens.dart';

import '../../core/plugin_registry.dart';
import '../../providers.dart'; // weightSavedBirdsProvider
import '../../widgets/weight_chart.dart';

import '../worker/worker_screen.dart';
import 'weigh_grid_provider.dart';
import 'weigh_input_widgets.dart';
import 'weigh_input_config.dart';
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

// ════════════════════════════════════════════════════════════════
// 网格局部常量 —— 这些是快速称重网格特有的布局参数，不进入全局 token。
// 通用间距/圆角/透明度请用 context.sp / context.r / context.a。
// ════════════════════════════════════════════════════════════════
class _WeighGridMetrics {
  _WeighGridMetrics._();

  /// 列标题栏高度（Excel 风格表头）。
  static const double headerHeight = 30.0;

  /// 选中鸟时主状态边框宽度。
  static const double selectedBorderWidth = 2.5;

  /// 单元格内 emoji 字号。
  static const double emojiFontSize = 11;

  /// 单元格内 padding（紧凑）。
  static const EdgeInsets cellPadding =
      EdgeInsets.symmetric(vertical: 3, horizontal: 6);

  /// 单元格内元素间距（emoji↔名字、名字↔体重）。
  static const double cellGap = 5;

  /// 图例项纵向间距。
  static const double legendItemGap = 2;

  /// 图例色块尺寸。
  static const double legendSwatch = 12;

  /// 角标小圆点尺寸与间距。
  static const double cornerBadgeSize = 5;
  static const double cornerBadgeGap = 2;

  /// 拨盘几何公式常量（见 _WeighInputPanel）。
  static const double dialArcPad = 32; // 弧高预留余量
  static const double dialWidthPad = 70; // 转盘宽度预留
  static const double dialHeightMin = 180;
  static const double dialHeightMax = 600;
  static const double dialWidthMin = 120;
  static const double dialWidthMax = 300;

  /// 转盘与趋势图的间距。
  static const double dialChartGap = 4;

  /// 输入面板滑入动画时长。
  /// 亦作为 [_WeightTrendInline] 延迟挂载的依据——动画结束后才订阅 provider、
  /// 构建 [WeightChartWidget]，避免动画帧被 DB 查询与图表首次布局抢占。
  static const Duration panelAnimDuration = Duration(milliseconds: 250);
}

/// 面板滑入动画时长，供 [_WeightTrendInline] 与 [AnimatedSlide] 引用。
const _panelAnimDuration = _WeighGridMetrics.panelAnimDuration;

/// 计算输入面板的自然高度，与 [_WeighInputPanel.build] 实际布局对齐。
///
/// 面板作为 [Stack] 浮层覆盖在网格上方，网格底部需按面板高度预留占位，否则面板
/// 会遮挡表格底部内容。面板高度随 [WeighInputMode] 与拨盘偏好（宽度%/弧半径%/
/// 描边）变化，故必须动态计算而非用固定常量。
///
/// 拨盘模式高度由 [_WeighInputPanel] 内的拨盘几何公式主导（闭式精确，趋势图与
/// 拨盘同高、`Row` 取 `CrossAxisAlignment.start` 后以拨盘高度为准）；键盘模式的
/// [WeighDisplay] 含 `FittedBox` 缩放文本，取保守上界 + 末尾安全余量吸收字体
/// 度量误差（多预留只会多滚一点空白，少预留才会遮挡）。
double computePanelHeight({
  required WeighInputMode mode,
  required double dialWidthPercent,
  required double arcRadiusPercent,
  required double strokeWidth,
  required double screenWidth,
  required double screenHeight,
  required double bottomInset,
}) {
  // 顶部固定区：纵向 padding(sp.md 12 + sp.xs 4) + 鸟信息行(~52，FilledButton 主导)
  //   + 其下间距 SizedBox(sp.sm 8)。
  const header = 12 + 4 + 52 + 8;

  final double content;
  if (mode == WeighInputMode.dial) {
    // 与 _WeighInputPanel.build 内 Builder 的拨盘几何公式完全一致。
    final wPx = screenWidth * dialWidthPercent;
    final rPx =
        (screenHeight * arcRadiusPercent).clamp(wPx, double.infinity);
    final disc = wPx * (2 * rPx - wPx);
    final arcH = disc > 0 ? 2 * sqrt(disc) : 2 * wPx;
    final dialHeight = (arcH + strokeWidth + _WeighGridMetrics.dialArcPad)
        .clamp(_WeighGridMetrics.dialHeightMin, _WeighGridMetrics.dialHeightMax);
    // 拨盘分支顶部 Padding(sp.sm 8) 近似为 dialArcPad 已含的余量；趋势图同高。
    content = dialHeight;
  } else {
    // 键盘模式：WeighDisplay(~80，含大字+单位行+消息余量) + dialChartGap(4) + numpad(192)。
    content = 80 + _WeighGridMetrics.dialChartGap + 192;
  }
  // 末尾 +8 安全余量吸收 WeighDisplay / 鸟信息行的字体度量误差；
  // +bottomInset 对齐面板内 SafeArea 的底部留白。
  return header + content + bottomInset + 8;
}

/// 粗粒度生长阶段（雏鸟/幼鸟/成鸟）→ emoji。
/// 与 BirdWithDetails.growthStage 的 3 阶段标签对齐。
String _growthStageEmoji(String growthStage) {
  switch (growthStage) {
    case '雏鸟':
      return '🐣';
    case '幼鸟':
      return '🐤';
    default:
      return '🦜';
  }
}

/// 状态显示优先级（与 _resolveStates 的判定顺序一致），驱动图例顺序。
const _stateDisplayOrder = <BirdCellState>[
  BirdCellState.overdue,
  BirdCellState.abnormalHigh,
  BirdCellState.abnormalLow,
  BirdCellState.weighedToday,
  BirdCellState.weaning,
];

class _WeighGridScreenState extends ConsumerState<WeighGridScreen> {
  final _scrollController = ScrollController();
  // 复用 grid_color_config 的列宽下限作为初值，避免两处定义同一常量。
  double _colWidth = GridColorConfig.minColumnWidthFloor;

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSelectedBird());
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
          final targetOffset =
              (nonEmptyIdx * _colWidth) - (viewport / 2) + (_colWidth / 2);
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
    final selected =
        ref.watch(weighGridProvider.select((s) => s.selectedBirdId));
    final hasWeaning =
        ref.watch(weighGridProvider.select((s) => s.weaningBirdIds.isNotEmpty));
    final cfg = ref.watch(gridColorConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRoomId != null ? '房间称重' : '快速称重'),
        actions: [
          if (selected != null)
            TextButton.icon(
              onPressed: () =>
                  ref.read(weighGridProvider.notifier).deselectBird(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('取消'),
            ),
        ],
      ),
      body: Stack(
        children: [
          // z=0: 表格（永远占满全屏高度，不随面板收起/展开而重排）
          // RepaintBoundary 把网格绘制域与下方浮层面板隔离——面板滑入动画期间
          // 网格子树零重排、零重绘（消除原 AnimatedCrossFade 高度动画导致的卡顿）。
          RepaintBoundary(
            child: Column(
              children: [
                Expanded(
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
                          s.isInitialized,
                        )));
                    final columns = s.$1;
                    final isInitialized = s.$8;
                    // 订阅输入偏好：面板高度随 inputMode/拨盘参数变化，需动态重算
                    // 底部预留高度，否则面板会遮挡表格底部内容。
                    final inputConfig = ref.watch(weighInputConfigProvider);
                    final mediaQuery = MediaQuery.of(context);
                    final panelHeight = computePanelHeight(
                      mode: inputConfig.mode,
                      dialWidthPercent: inputConfig.dialWidthPercent,
                      arcRadiusPercent: inputConfig.arcRadiusPercent,
                      strokeWidth: inputConfig.strokeWidth,
                      screenWidth: mediaQuery.size.width,
                      screenHeight: mediaQuery.size.height,
                      bottomInset: mediaQuery.viewPadding.bottom,
                    );
                    // 未初始化完成 → 显示加载
                    if (!isInitialized) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // 初始化完成但所有列均为空 → 无鹦鹉数据
                    final nonEmpty = columns.where((c) => !c.isEmpty).length;
                    if (nonEmpty == 0) {
                      final a = context.a;
                      return Center(
                        child: Text(
                          '暂无鹦鹉数据，请先添加鹦鹉',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onSurface.withAlpha(a.medium)),
                        ),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final sp = context.sp;
                        final r = context.r;
                        final a = context.a;
                        final avail = constraints.maxWidth - sp.lg;
                        _colWidth =
                            (avail / nonEmpty).clamp(cfg.minColumnWidth, avail);
                        return Container(
                          margin: EdgeInsets.fromLTRB(sp.sm, sp.sm, sp.sm, 0),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(r.md)),
                            border: Border.all(
                                color: scheme.outlineVariant.withAlpha(a.low),
                                width: 0.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            // 选中鸟时底部按面板实际高度预留占位，避免浮层面板盖住
                            // 选中行。panelHeight 随 inputMode/拨盘偏好动态计算，
                            // 保证无论用户如何调整输入偏好都不遮挡。
                            padding: EdgeInsets.only(
                              bottom: selected != null ? panelHeight : 0,
                            ),
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
                                    ref
                                        .read(weighGridProvider.notifier)
                                        .selectBird(birdId);
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
              ],
            ),
          ),
          // z=1: 输入面板浮层 —— 仅 transform 动画，不改变布局盒，不触发网格重排
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: _panelAnimDuration,
              curve: Curves.easeOutCubic,
              // 选中时偏移 0（滑入原位）；未选中时下移一个自身高度（藏到屏幕外）。
              offset: selected != null ? Offset.zero : const Offset(0, 1),
              child: RepaintBoundary(
                child: Consumer(builder: (context, ref, _) {
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
                  final inputConfig = ref.watch(weighInputConfigProvider);
                  // 未选中时也保留面板自然高度（透明占位），使 [AnimatedSlide] 的
                  // 下移偏移（=1×自身高度）能真正把面板藏到屏幕外、选中时再滑入。
                  // 否则从 SizedBox.shrink()（高 0）直接出现，会失去滑入过渡。
                  // 占位高度与网格预留用同一函数，保证滑入前后高度基准一致、无跳变。
                  if (s.$1 == null) {
                    final mediaQuery = MediaQuery.of(context);
                    return SizedBox(
                      height: computePanelHeight(
                        mode: inputConfig.mode,
                        dialWidthPercent: inputConfig.dialWidthPercent,
                        arcRadiusPercent: inputConfig.arcRadiusPercent,
                        strokeWidth: inputConfig.strokeWidth,
                        screenWidth: mediaQuery.size.width,
                        screenHeight: mediaQuery.size.height,
                        bottomInset: mediaQuery.viewPadding.bottom,
                      ),
                    );
                  }
                  return _WeighInputPanel(
                    selectedBirdId: s.$1,
                    weightText: s.$2,
                    isFasting: s.$3,
                    isSaving: s.$4,
                    message: s.$5,
                    lastWeigh: s.$6,
                    birdById: s.$7,
                    inputMode: inputConfig.mode,
                    dialSide: inputConfig.dialSide,
                    dialSensitivity: inputConfig.sensitivity,
                    speedThreshold: inputConfig.speedThreshold,
                    windowSize: inputConfig.windowSize,
                    fastStep: inputConfig.fastStep,
                    dialWidthPercent: inputConfig.dialWidthPercent,
                    arcRadiusPercent: inputConfig.arcRadiusPercent,
                    strokeWidth: inputConfig.strokeWidth,
                    screenWidth: MediaQuery.of(context).size.width,
                    screenHeight: MediaQuery.of(context).size.height,
                    theme: theme,
                    notifier: ref.read(weighGridProvider.notifier),
                    onSwitchMode: () {
                      final cfg = ref.read(weighInputConfigProvider);
                      ref.read(weighInputConfigProvider.notifier).setMode(
                            cfg.mode == WeighInputMode.dial
                                ? WeighInputMode.keypad
                                : WeighInputMode.dial,
                          );
                    },
                  );
                }),
              ),
            ),
          ),
          // z=2: 多状态图例 — 屏幕右下角，选中鸟时隐藏
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

    final a = context.a;
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: scheme.outlineVariant.withAlpha(a.low), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 列标题 — Excel 风格
          Container(
            height: _WeighGridMetrics.headerHeight,
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
                  color: scheme.onSurface.withAlpha(a.heavy),
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

    final a = context.a;
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
              color: scheme.surfaceContainerHighest.withAlpha(a.medium),
              border: Border(
                top: BorderSide(
                    color: scheme.outlineVariant.withAlpha(a.faint),
                    width: 0.5),
                bottom: BorderSide(
                    color: scheme.outlineVariant.withAlpha(a.faint),
                    width: 0.5),
              ),
            ),
            child: Text(
              group.label,
              // 分组头是极小字，复用 labelMedium 的尺寸 + 斜体弱化。
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(a.high),
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
            abnormalDirection:
                abnormalDirections[bird.bird.id] ?? AbnormalDirection.none,
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
    final a = context.a;
    final r = context.r;
    // 复用统一的顺序常量 + 标签映射，避免与 _resolveStates 的优先级漂移。
    final items = _stateDisplayOrder
        .where((s) => s != BirdCellState.weaning || hasWeaning)
        .map((s) => (s, _stateLegendLabel(s)))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(r.md),
        border: Border.all(color: scheme.outlineVariant.withAlpha(a.low)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(a.subtle),
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
            padding:
                EdgeInsets.symmetric(vertical: _WeighGridMetrics.legendItemGap),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _WeighGridMetrics.legendSwatch,
                  height: _WeighGridMetrics.legendSwatch,
                  decoration: BoxDecoration(
                    color: config.displayMode == CellDisplayMode.border
                        ? Colors.transparent
                        : color.withValues(alpha: config.fillOpacity * 3),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(r.xs),
                  ),
                ),
                SizedBox(width: _WeighGridMetrics.cellGap),
                Text(
                  item.$2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withAlpha(a.heavy),
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

/// 状态 → 图例标签。与 [_resolveStates] 优先级、[_stateDisplayOrder] 顺序保持一致。
String _stateLegendLabel(BirdCellState s) {
  switch (s) {
    case BirdCellState.overdue:
      return '超期未称';
    case BirdCellState.abnormalHigh:
      return '体重偏高';
    case BirdCellState.abnormalLow:
      return '体重偏低';
    case BirdCellState.weighedToday:
      return '今日已称';
    case BirdCellState.weaning:
      return '断奶期';
    case BirdCellState.normal:
      return '';
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
  if (abnormalDirection == AbnormalDirection.high)
    states.add(BirdCellState.abnormalHigh);
  if (abnormalDirection == AbnormalDirection.low)
    states.add(BirdCellState.abnormalLow);
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
          width: _WeighGridMetrics.cornerBadgeSize,
          height: _WeighGridMetrics.cornerBadgeSize,
          margin:
              const EdgeInsets.only(bottom: _WeighGridMetrics.cornerBadgeGap),
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
    final a = context.a;
    final activeStates = _resolveStates(
      isOverdue: isOverdue,
      abnormalDirection: abnormalDirection,
      isWeighedToday: isWeighedToday,
      isWeaning: isWeaning,
    );
    final cellState =
        activeStates.isEmpty ? BirdCellState.normal : activeStates.first;
    final secondaryStates = activeStates.length > 1
        ? activeStates.sublist(
            1, activeStates.length > 3 ? 3 : activeStates.length)
        : const <BirdCellState>[];
    final stateColor = cellState == BirdCellState.normal
        ? null
        : colorConfig.borderColor(cellState);
    final mode = colorConfig.displayMode;

    // 背景色
    Color? bgColor;
    if (isSelected) {
      bgColor = scheme.primaryContainer.withAlpha(a.low);
    } else if (stateColor != null &&
        (mode == CellDisplayMode.fill ||
            mode == CellDisplayMode.borderAndFill)) {
      bgColor = stateColor.withValues(alpha: colorConfig.fillOpacity);
    }

    // 边框
    BorderSide border(BorderSide fallback) {
      if (isSelected) {
        return BorderSide(
            color: scheme.primary, width: _WeighGridMetrics.selectedBorderWidth);
      }
      if (stateColor != null &&
          (mode == CellDisplayMode.border ||
              mode == CellDisplayMode.borderAndFill)) {
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
            padding: _WeighGridMetrics.cellPadding,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                left: isSelected
                    ? BorderSide(
                        color: scheme.primary,
                        width: _WeighGridMetrics.selectedBorderWidth)
                    : (stateColor != null &&
                            (mode == CellDisplayMode.border ||
                                mode == CellDisplayMode.borderAndFill))
                        ? BorderSide(
                            color: stateColor, width: colorConfig.borderWidth)
                        : BorderSide.none,
                top: border(BorderSide(
                    color: scheme.outlineVariant.withAlpha(a.faint),
                    width: 0.5)),
                right: border(BorderSide.none),
                bottom: border(BorderSide(
                    color: scheme.outlineVariant.withAlpha(a.faint),
                    width: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _growthStageEmoji(bird.growthStage),
                  style: const TextStyle(
                      fontSize: _WeighGridMetrics.emojiFontSize),
                ),
                SizedBox(width: _WeighGridMetrics.cellGap),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: bird.bird.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? scheme.primary : scheme.onSurface,
                          ),
                        ),
                        if (bird.bird.ringNumber != null)
                          TextSpan(
                            text: ' #${bird.bird.ringNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: (isSelected
                                      ? scheme.primary
                                      : scheme.onSurface)
                                  .withAlpha(a.high),
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
                        color: (isSelected ? scheme.primary : scheme.onSurface)
                            .withAlpha(a.heavy),
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
              child: _CornerBadge(
                  states: secondaryStates, colorConfig: colorConfig),
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
  final WeighInputMode inputMode;
  final DialSide dialSide;
  final double dialSensitivity;
  final double speedThreshold;
  final int windowSize;
  final double fastStep;
  final double dialWidthPercent;
  final double arcRadiusPercent;
  final double strokeWidth;
  final double screenWidth;
  final double screenHeight;
  final ThemeData theme;
  final WeighGridNotifier notifier;
  final VoidCallback onSwitchMode;

  const _WeighInputPanel({
    required this.selectedBirdId,
    required this.weightText,
    required this.isFasting,
    required this.isSaving,
    required this.message,
    required this.lastWeigh,
    required this.birdById,
    required this.inputMode,
    required this.dialSide,
    required this.dialSensitivity,
    required this.speedThreshold,
    required this.windowSize,
    required this.fastStep,
    required this.dialWidthPercent,
    required this.arcRadiusPercent,
    required this.strokeWidth,
    required this.screenWidth,
    required this.screenHeight,
    required this.theme,
    required this.notifier,
    required this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    final birdId = selectedBirdId;
    if (birdId == null) return const SizedBox.shrink();

    // O(1) 查找选中鸟，替代原遍历全部列/分组的嵌套循环
    final bird = birdById[birdId];
    final scheme = theme.colorScheme;
    final lastWeigh = this.lastWeigh;
    final sp = context.sp;
    final r = context.r;
    final a = context.a;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
            top: BorderSide(color: scheme.outlineVariant.withAlpha(a.faint))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(a.subtle),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(sp.lg, sp.md, sp.lg, sp.xs),
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
                            borderRadius: BorderRadius.circular(r.sm),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bird.bird.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (bird.bird.ringNumber != null) ...[
                                    SizedBox(width: sp.xs + 2),
                                    Text('#${bird.bird.ringNumber}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w500)),
                                  ],
                                  SizedBox(width: sp.xs),
                                  Icon(Icons.open_in_new,
                                      size: 12,
                                      color: scheme.onSurface.withAlpha(a.high)),
                                ],
                              ),
                            ),
                          ),
                          if (lastWeigh != null)
                            Text(
                              '上次: ${_fmtDate(lastWeigh.recordedAt)}  ·  ${lastWeigh.weightG.toStringAsFixed(1)}g',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(a.high),
                              ),
                            )
                          else
                            Text(
                              '暂无称重记录',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(a.medium),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 模式切换
                    TextButton(
                      onPressed: onSwitchMode,
                      child: Text(
                        inputMode == WeighInputMode.dial ? '键盘' : '转盘',
                      ),
                    ),
                    FilledButton(
                      onPressed: isSaving ? null : notifier.saveWeight,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('保存',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              SizedBox(height: sp.sm),
              // ── 输入区域：Stack+Offstage 双分支保活，切换零卡顿 ──
              Builder(builder: (ctx) {
                final wPx = screenWidth * dialWidthPercent;
                final rPx = (screenHeight * arcRadiusPercent)
                    .clamp(wPx, double.infinity);
                final disc = wPx * (2 * rPx - wPx);
                final arcH = disc > 0 ? 2 * sqrt(disc) : 2 * wPx;
                // 拨盘几何：弧高 + 描边余量 + 上下留白，再夹取到 [min,max]。
                final dialHeight = (arcH + strokeWidth + _WeighGridMetrics.dialArcPad)
                    .clamp(_WeighGridMetrics.dialHeightMin,
                        _WeighGridMetrics.dialHeightMax);
                final dialWidth = (wPx + _WeighGridMetrics.dialWidthPad)
                    .clamp(_WeighGridMetrics.dialWidthMin,
                        _WeighGridMetrics.dialWidthMax);

                return Stack(
                  children: [
                    // 键盘模式 — 始终保活
                    Offstage(
                      offstage: inputMode != WeighInputMode.keypad,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WeighDisplay(
                            weightText: weightText,
                            message: message,
                            theme: theme,
                            showUnit: true,
                            onMinus1: () => notifier.adjustWeight(-1),
                            onMinus10: () => notifier.adjustWeight(-10),
                            onPlus1: () => notifier.adjustWeight(1),
                            onPlus10: () => notifier.adjustWeight(10),
                            isFasting: isFasting,
                            onToggleFasting: () =>
                                notifier.setFasting(!isFasting),
                          ),
                          SizedBox(height: _WeighGridMetrics.dialChartGap),
                          WeighNumPad(
                            onDigit: notifier.appendDigit,
                            onDelete: notifier.deleteDigit,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                    // 转盘模式 — 始终保活
                    Offstage(
                      offstage: inputMode != WeighInputMode.dial,
                      child: Padding(
                        padding: EdgeInsets.only(top: sp.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dialSide == DialSide.left
                              ? [
                                  SizedBox(
                                    width: dialWidth,
                                    height: dialHeight,
                                    child: WeighDial(
                                      side: dialSide,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      weightText: weightText,
                                      message: message,
                                      isFasting: isFasting,
                                      onToggleFasting: () =>
                                          notifier.setFasting(!isFasting),
                                      lastWeightG: lastWeigh?.weightG,
                                      growthStage: birdById[selectedBirdId]
                                              ?.growthStage ??
                                          '成鸟',
                                      sensitivity: dialSensitivity,
                                      speedThreshold: speedThreshold,
                                      windowSize: windowSize,
                                      fastStep: fastStep,
                                      dialWidthPercent: dialWidthPercent,
                                      arcRadiusPercent: arcRadiusPercent,
                                      strokeWidth: strokeWidth,
                                      onDelta: (delta) =>
                                          notifier.adjustWeight(delta),
                                      theme: theme,
                                    ),
                                  ),
                                  SizedBox(width: _WeighGridMetrics.dialChartGap),
                                  Expanded(
                                      child: _WeightTrendInline(
                                          birdId: birdId,
                                          chartHeight: dialHeight)),
                                ]
                              : [
                                  Expanded(
                                      child: _WeightTrendInline(
                                          birdId: birdId,
                                          chartHeight: dialHeight)),
                                  SizedBox(width: _WeighGridMetrics.dialChartGap),
                                  SizedBox(
                                    width: dialWidth,
                                    height: dialHeight,
                                    child: WeighDial(
                                      side: dialSide,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      weightText: weightText,
                                      message: message,
                                      isFasting: isFasting,
                                      onToggleFasting: () =>
                                          notifier.setFasting(!isFasting),
                                      lastWeightG: lastWeigh?.weightG,
                                      growthStage: birdById[selectedBirdId]
                                              ?.growthStage ??
                                          '成鸟',
                                      sensitivity: dialSensitivity,
                                      speedThreshold: speedThreshold,
                                      windowSize: windowSize,
                                      fastStep: fastStep,
                                      dialWidthPercent: dialWidthPercent,
                                      arcRadiusPercent: arcRadiusPercent,
                                      strokeWidth: strokeWidth,
                                      onDelta: (delta) =>
                                          notifier.adjustWeight(delta),
                                      theme: theme,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
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

/// 内联趋势图最多取近 N 条记录。
///
/// 取全量历史会让长寿鸟（>200 条）的解码 + 图表布局成本随时间线性膨胀，
/// 而内联小图仅需近期走势即可。90 条 ≈ 3 个月每日一条。
const _inlineTrendLimit = 90;

/// 按鸟缓存体重记录的 family provider。
///
/// [_WeightTrendInline] 用此 provider 替代直接 `FutureBuilder(db.getByBird(...))`，
/// 这样选中鸟切换或面板随打字重建时不会重复触发 DB 查询（Riverpod 自动缓存）。
/// 仅取最近 [_inlineTrendLimit] 条，避免全量历史导致图表布局开销过大。
final _birdWeightsProvider =
    FutureProvider.family<List<Weight>, int>((ref, birdId) async {
  // 该鸟体重保存后失效缓存，避免切回时图表显示陈旧数据（对齐 providers.dart 同类 provider）
  ref.watch(weightSavedBirdsProvider.select((s) => s.contains(birdId)));
  final db = pluginRegistry.db;
  if (db == null) return const [];
  return db.getRecentByBird(birdId, limit: _inlineTrendLimit);
});

/// 选中鸟的体重趋势内联图表，复用 [WeightChartWidget]。
///
/// 使用 [StatefulWidget] 包裹以实现"延迟挂载"：选中鸟后面板展开动画期间不订阅
/// provider、不构建图表，待动画结束（[_panelAnimDuration]）后才挂载，从而让动画
/// 帧不被 DB 查询与 [WeightChartWidget] 首次布局抢占。组件本身只依赖 `birdId`，
/// 不订阅 `weightText`，因此按键时不会重建。
class _WeightTrendInline extends ConsumerStatefulWidget {
  final int birdId;
  final double chartHeight;
  const _WeightTrendInline({required this.birdId, this.chartHeight = 160});

  @override
  ConsumerState<_WeightTrendInline> createState() => _WeightTrendInlineState();
}

class _WeightTrendInlineState extends ConsumerState<_WeightTrendInline> {
  /// 是否已度过面板展开动画、允许订阅 provider 与构建图表。
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    // 等面板交叉淡入（_panelAnimDuration）结束后再挂载，避免动画期间触发查询。
    Future.delayed(_panelAnimDuration, () {
      if (mounted) setState(() => _mounted = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_mounted) return const SizedBox.shrink();
    final weights = ref.watch(_birdWeightsProvider(widget.birdId));
    return weights.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return WeightChartWidget(
          key: ValueKey(widget.birdId),
          weights: list,
          chartHeight: widget.chartHeight,
          compact: true,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
