import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/bird_repository.dart';
import '../worker/worker_screen.dart';
import 'weigh_provider.dart';

class WeighScreen extends ConsumerStatefulWidget {
  final int? roomId;

  const WeighScreen({super.key, this.roomId});

  @override
  ConsumerState<WeighScreen> createState() => _WeighScreenState();
}

class _WeighScreenState extends ConsumerState<WeighScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final workerId = ref.read(workerProvider).userId;
      ref.read(weighProvider.notifier).setUserId(workerId);
      ref.read(weighProvider.notifier).loadBirds(roomId: widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weighProvider);
    final theme = Theme.of(context);
    final bird = state.currentBird;

    if (state.birds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('称重记录')),
        body: const Center(child: Text('暂无鹦鹉数据，请先添加鹦鹉')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('称重记录 ${state.currentIndex + 1}/${state.birds.length}'),
      ),
      body: Column(
        children: [
          // ── 顶部鸟信息卡片 ──
          if (bird != null) _BirdInfoHeader(bird: bird, state: state, theme: theme),

          // ── 体重显示区 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _WeightDisplay(state: state, theme: theme),
          ),

          // ── 快速调整按钮 ──
          _QuickAdjustBar(state: state, theme: theme, notifier: ref.read(weighProvider.notifier)),

          const Spacer(),

          // ── 数字键盘 ──
          _NumPad(notifier: ref.read(weighProvider.notifier), theme: theme),

          // ── 底部操作栏 ──
          _BottomActions(notifier: ref.read(weighProvider.notifier), state: state, theme: theme),
        ],
      ),
    );
  }
}

/// 鹦鹉信息头部
class _BirdInfoHeader extends StatelessWidget {
  final BirdWithDetails bird;
  final WeighState state;
  final ThemeData theme;

  const _BirdInfoHeader({required this.bird, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final lastWeight = state.latestWeights[bird.bird.id];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.pets, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bird.bird.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bird.species.name} · ${bird.growthStage} · ${bird.ageDays}天',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(140)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastWeight != null ? '${lastWeight.weightG.toStringAsFixed(1)}g' : '-',
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

/// 体重显示区
class _WeightDisplay extends StatelessWidget {
  final WeighState state;
  final ThemeData theme;

  const _WeightDisplay({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final displayText = state.weightText.isEmpty ? '0.0' : state.weightText;
    return Column(
      children: [
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '克 (g)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
        if (state.message != null) ...[
          const SizedBox(height: 4),
          Text(
            state.message!,
            style: TextStyle(
              color: state.message!.startsWith('✅')
                  ? Colors.green
                  : Colors.orange,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

/// 快速调整
class _QuickAdjustBar extends StatelessWidget {
  final WeighState state;
  final ThemeData theme;
  final WeighNotifier notifier;

  const _QuickAdjustBar({required this.state, required this.theme, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _QuickBtn(
            icon: Icons.remove, label: '-1g',
            onTap: () => notifier.adjustWeight(-1),
            onLongPress: () => notifier.adjustWeight(-10),
          ),
          const SizedBox(width: 16),
          _QuickBtn(
            icon: Icons.add, label: '+1g',
            onTap: () => notifier.adjustWeight(1),
            onLongPress: () => notifier.adjustWeight(10),
          ),
          const SizedBox(width: 16),
          ActionChip(
            avatar: Icon(
              state.isFasting ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: state.isFasting ? Colors.white : null,
            ),
            label: const Text('空腹'),
            backgroundColor: state.isFasting
                ? theme.colorScheme.primary
                : null,
            onPressed: () => notifier.setFasting(!state.isFasting),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _QuickBtn({
    required this.icon, required this.label,
    required this.onTap, required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(60)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// 数字键盘
class _NumPad extends StatelessWidget {
  final WeighNotifier notifier;
  final ThemeData theme;

  const _NumPad({required this.notifier, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['.', '0', '⌫'],
          ])
            Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      height: 56,
                      child: Material(
                        color: key == '⌫'
                            ? theme.colorScheme.errorContainer.withAlpha(80)
                            : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (key == '⌫') {
                              notifier.deleteDigit();
                            } else {
                              notifier.appendDigit(key);
                            }
                          },
                          child: Center(
                            child: key == '⌫'
                                ? const Icon(Icons.backspace_outlined, size: 24)
                                : Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      color: key == '.'
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// 底部操作栏
class _BottomActions extends StatelessWidget {
  final WeighNotifier notifier;
  final WeighState state;
  final ThemeData theme;

  const _BottomActions({required this.notifier, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            // 上一只
            IconButton.outlined(
              onPressed: state.hasPrev && !state.isSaving ? notifier.prevBird : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            const SizedBox(width: 8),

            // 清空
            TextButton(
              onPressed: state.weightText.isNotEmpty ? notifier.clearWeight : null,
              child: const Text('清空'),
            ),

            const Spacer(),

            // 保存按钮（大）
            SizedBox(
              height: 48,
              width: 120,
              child: FilledButton(
                onPressed: state.isSaving ? null : notifier.saveWeight,
                child: state.isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('保存', style: TextStyle(fontSize: 18)),
              ),
            ),

            const Spacer(),

            // 跳过
            if (state.hasNext)
              TextButton(
                onPressed: () => notifier.nextBird(),
                child: const Text('跳过'),
              ),

            const SizedBox(width: 8),
            // 下一只
            IconButton.outlined(
              onPressed: state.hasNext && !state.isSaving ? notifier.nextBird : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
