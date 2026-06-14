import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/bird_repository.dart';

import '../worker/worker_screen.dart';
import 'weigh_grid_provider.dart';
import 'weigh_input_widgets.dart';

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

// Excel 表格布局常量
const _colWidth = 152.0;
const _headerHeight = 36.0;

class _WeighGridScreenState extends ConsumerState<WeighGridScreen> {
  final _scrollController = ScrollController();

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
    final state = ref.watch(weighGridProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = state.selectedBirdId;

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
      body: Column(
        children: [
          // ── 表格区域 ──
          Expanded(
            flex: selected != null ? 3 : 10,
            child: state.columns.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Container(
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
                        children: state.columns.map((col) {
                          return _RoomColumnWidget(
                            column: col,
                            selectedBirdId: selected,
                            theme: theme,
                            scheme: scheme,
                            onTapBird: (birdId) {
                              ref.read(weighGridProvider.notifier).selectBird(birdId);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          // ── 填值面板 ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: selected != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _WeighInputPanel(
              state: state,
              theme: theme,
              notifier: ref.read(weighGridProvider.notifier),
            ),
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
  final RoomColumn column;
  final int? selectedBirdId;
  final ThemeData theme;
  final ColorScheme scheme;
  final ValueChanged<int> onTapBird;

  const _RoomColumnWidget({
    required this.column,
    required this.selectedBirdId,
    required this.theme,
    required this.scheme,
    required this.onTapBird,
  });

  @override
  Widget build(BuildContext context) {
    if (column.isEmpty) return const SizedBox.shrink();

    return Container(
      width: _colWidth,
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
  final ThemeData theme;
  final ColorScheme scheme;
  final ValueChanged<int> onTapBird;

  const _GroupSection({
    required this.group,
    required this.selectedBirdId,
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
          final isSelected = bird.bird.id == selectedBirdId;
          return _BirdCell(
            bird: bird,
            isSelected: isSelected,
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
// 鸟单元格 — Excel 风格
// ═══════════════════════════════════════════════

class _BirdCell extends StatelessWidget {
  final BirdWithDetails bird;
  final bool isSelected;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _BirdCell({
    required this.bird,
    required this.isSelected,
    required this.theme,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primaryContainer.withAlpha(60) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? scheme.primary : Colors.transparent,
              width: 2.5,
            ),
            bottom: BorderSide(
              color: scheme.outlineVariant.withAlpha(30),
              width: 0.5,
            ),
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
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.edit, size: 12, color: scheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 填值面板
// ═══════════════════════════════════════════════

class _WeighInputPanel extends StatelessWidget {
  final WeighGridState state;
  final ThemeData theme;
  final WeighGridNotifier notifier;

  const _WeighInputPanel({
    required this.state,
    required this.theme,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final birdId = state.selectedBirdId;
    if (birdId == null) return const SizedBox.shrink();

    // 查找鸟信息
    BirdWithDetails? bird;
    for (final col in state.columns) {
      for (final g in col.groups) {
        final found = g.birds.cast<BirdWithDetails?>().firstWhere(
              (b) => b?.bird.id == birdId,
              orElse: () => null,
            );
        if (found != null) {
          bird = found;
          break;
        }
      }
      if (bird != null) break;
    }

    final scheme = theme.colorScheme;
    final lastWeigh = state.lastWeigh;

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
                          Row(
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
                            ],
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
                    if (state.weightText.isNotEmpty)
                      TextButton(
                        onPressed: notifier.clearWeight,
                        child: const Text('清空'),
                      ),
                    FilledButton(
                      onPressed: state.isSaving ? null : notifier.saveWeight,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: state.isSaving
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
                weightText: state.weightText,
                message: state.message,
                theme: theme,
              ),
              const SizedBox(height: 8),
              // 快速调整
              QuickAdjustBar(
                isFasting: state.isFasting,
                theme: theme,
                onMinus1: () => notifier.adjustWeight(-1),
                onMinus10: () => notifier.adjustWeight(-10),
                onPlus1: () => notifier.adjustWeight(1),
                onPlus10: () => notifier.adjustWeight(10),
                onToggleFasting: () => notifier.setFasting(!state.isFasting),
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
