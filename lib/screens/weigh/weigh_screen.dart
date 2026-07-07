import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/bird_repository.dart';
import '../../widgets/feather_icon.dart';
import '../worker/worker_screen.dart';
import 'weigh_provider.dart';
import 'weigh_input_widgets.dart';
import 'weigh_input_config.dart';

class WeighScreen extends ConsumerStatefulWidget {
  final int? roomId;
  final int? birdId;
  final int? enclosureId;

  const WeighScreen({super.key, this.roomId, this.birdId, this.enclosureId});

  @override
  ConsumerState<WeighScreen> createState() => _WeighScreenState();
}

class _WeighScreenState extends ConsumerState<WeighScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final workerId = ref.read(workerProvider).userId;
      final notifier = ref.read(weighProvider.notifier);
      notifier.setUserId(workerId);
      await notifier.loadBirds(
        roomId: widget.roomId,
        enclosureId: widget.enclosureId,
        birdId: widget.birdId,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weighProvider);
    final theme = Theme.of(context);
    final bird = state.currentBird;
    final inputConfig = ref.watch(weighInputConfigProvider);
    final notifier = ref.read(weighProvider.notifier);

    if (state.birds.isEmpty) {
      final location = state.enclosureName ?? state.roomName ?? '';
      return Scaffold(
        appBar: AppBar(title: const Text('称重记录')),
        body: Center(
          child: Text(
            location.isNotEmpty ? '$location 暂无鹦鹉' : '暂无鹦鹉数据，请先添加鹦鹉',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildBreadcrumb(state, theme),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              size: 22,
            ),
            tooltip: '脚环号查找',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  ref.read(weighProvider.notifier).setSearchQuery('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 脚环搜索栏 ──
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '输入脚环号前几位快速查找...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(weighProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) {
                  ref.read(weighProvider.notifier).setSearchQuery(v);
                },
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 顶部鸟信息卡片 ──
                  if (bird != null)
                    _BirdInfoHeader(bird: bird, state: state, theme: theme),

                  // ── 输入区域：Stack+Offstage 双分支保活，切换零卡顿 ──
                  Stack(
                    children: [
                      // 键盘模式 — 始终保活
                      Offstage(
                        offstage: inputConfig.mode != WeighInputMode.keypad,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: WeighDisplay(
                                weightText: state.weightText,
                                message: state.message,
                                theme: theme,
                                showUnit: true,
                                onMinus1: () => notifier.adjustWeight(-1),
                                onMinus10: () => notifier.adjustWeight(-10),
                                onPlus1: () => notifier.adjustWeight(1),
                                onPlus10: () => notifier.adjustWeight(10),
                                isFasting: state.isFasting,
                                onToggleFasting: () =>
                                    notifier.setFasting(!state.isFasting),
                              ),
                            ),
                            const SizedBox(height: 4),
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
                        offstage: inputConfig.mode != WeighInputMode.dial,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            height: 260,
                            child: WeighDial(
                              side: inputConfig.dialSide,
                              weightText: state.weightText,
                              message: state.message,
                              isFasting: state.isFasting,
                              onToggleFasting: () =>
                                  notifier.setFasting(!state.isFasting),
                              lastWeightG: state
                                  .latestWeights[state.currentBird?.bird.id]
                                  ?.weightG,
                              growthStage:
                                  state.currentBird?.growthStage ?? '成鸟',
                              sensitivity: inputConfig.sensitivity,
                              speedThreshold: inputConfig.speedThreshold,
                              windowSize: inputConfig.windowSize,
                              fastStep: inputConfig.fastStep,
                              screenWidth: MediaQuery.of(context).size.width,
                              screenHeight: MediaQuery.of(context).size.height,
                              dialWidthPercent: inputConfig.dialWidthPercent,
                              arcRadiusPercent: inputConfig.arcRadiusPercent,
                              strokeWidth: inputConfig.strokeWidth,
                              onDelta: (delta) => notifier.adjustWeight(delta),
                              theme: theme,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── 底部操作栏（含三层导航） ──
          _BottomActions(notifier: notifier, state: state, theme: theme),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(WeighState state, ThemeData theme) {
    final parts = <Widget>[];
    if (state.roomName != null) {
      parts.add(Text(state.roomName!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
    }
    if (state.enclosureName != null) {
      parts.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('/',
            style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(100))),
      ));
      parts.add(Text(state.enclosureName!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
    }
    if (parts.isNotEmpty) {
      parts.insert(
          0,
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text('${state.currentIndex + 1}/${state.birds.length}',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(140))),
          ));
    }
    if (parts.isEmpty) {
      return Text('称重记录 ${state.currentIndex + 1}/${state.birds.length}');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: parts,
    );
  }
}

/// 鹦鹉信息头部
class _BirdInfoHeader extends StatelessWidget {
  final BirdWithDetails bird;
  final WeighState state;
  final ThemeData theme;

  const _BirdInfoHeader(
      {required this.bird, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final lastWeight = state.latestWeights[bird.bird.id];
    final weighed = state.latestWeights.containsKey(bird.bird.id);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: weighed
              ? scheme.primary.withAlpha(60)
              : scheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: weighed
                    ? scheme.primary.withAlpha(30)
                    : scheme.secondary.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FeatherIcon(
                color: weighed ? scheme.primary : scheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bird.bird.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (bird.bird.ringNumber != null) ...[
                        const SizedBox(width: 6),
                        Text('#${bird.bird.ringNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bird.species.name} · ${bird.growthStage} · ${bird.ageDays}天',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(140)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastWeight != null
                      ? '${lastWeight.weightG.toStringAsFixed(1)}g'
                      : '-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text('上次', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作栏 — 三层导航（鸟 ⊂ 容器 ⊂ 房间）
class _BottomActions extends ConsumerWidget {
  final WeighNotifier notifier;
  final WeighState state;
  final ThemeData theme;

  const _BottomActions(
      {required this.notifier, required this.state, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withAlpha(40)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 外层：房间 + 容器导航 ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 上一房间
                if (state.hasPrevRoom)
                  _NavBtn(
                    icon: Icons.arrow_back_ios,
                    doubleIcon: true,
                    label: '上一房间',
                    onTap: notifier.prevRoom,
                    disabled: state.isSaving,
                  )
                else
                  const SizedBox(width: 48),

                // 上一容器
                if (state.hasPrevEnclosure)
                  _NavBtn(
                    icon: Icons.arrow_back_ios,
                    label: '上一容器',
                    onTap: notifier.prevEnclosure,
                    disabled: state.isSaving,
                  )
                else
                  const SizedBox(width: 48),

                const Spacer(),

                // 下一容器
                if (state.hasNextEnclosure)
                  _NavBtn(
                    icon: Icons.arrow_forward_ios,
                    label: '下一容器',
                    onTap: notifier.nextEnclosure,
                    disabled: state.isSaving,
                    trailing: true,
                  )
                else
                  const SizedBox(width: 48),

                // 下一房间
                if (state.hasNextRoom)
                  _NavBtn(
                    icon: Icons.arrow_forward_ios,
                    doubleIcon: true,
                    label: '下一房间',
                    onTap: notifier.nextRoom,
                    disabled: state.isSaving,
                    trailing: true,
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 4),

            // ── 内层：鸟导航 + 保存（现有逻辑） ──
            Row(
              children: [
                // 上一只
                IconButton(
                  onPressed: state.hasPrev && !state.isSaving
                      ? notifier.prevBird
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),

                // 模式切换
                TextButton(
                  onPressed: () {
                    final cfg = ref.read(weighInputConfigProvider);
                    final notifier =
                        ref.read(weighInputConfigProvider.notifier);
                    notifier.setMode(
                      cfg.mode == WeighInputMode.dial
                          ? WeighInputMode.keypad
                          : WeighInputMode.dial,
                    );
                  },
                  child: Text(
                    ref.watch(weighInputConfigProvider).mode ==
                            WeighInputMode.dial
                        ? '键盘'
                        : '转盘',
                  ),
                ),

                const Spacer(),

                // 保存按钮
                FilledButton(
                  onPressed: state.isSaving ? null : notifier.saveWeight,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('保存', style: TextStyle(fontSize: 18)),
                ),

                const Spacer(),

                // 跳过
                if (state.hasNext)
                  TextButton(
                    onPressed: () => notifier.nextBird(),
                    child: const Text('跳过'),
                  ),

                const SizedBox(width: 4),
                // 下一只
                IconButton(
                  onPressed: state.hasNext && !state.isSaving
                      ? notifier.nextBird
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 导航按钮（容器/房间级别）
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool doubleIcon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final bool trailing;

  const _NavBtn({
    required this.icon,
    this.doubleIcon = false,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 100,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                trailing ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!trailing) ...[
                Icon(icon, size: 12, color: scheme.primary),
                if (doubleIcon) Icon(icon, size: 12, color: scheme.primary),
                const SizedBox(width: 2),
              ],
              Text(label,
                  style: TextStyle(fontSize: 11, color: scheme.primary)),
              if (trailing) ...[
                const SizedBox(width: 2),
                if (doubleIcon) Icon(icon, size: 12, color: scheme.primary),
                Icon(icon, size: 12, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
