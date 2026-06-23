import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/plugin.dart';
import '../../services/work_hours_config.dart';
import '../../providers.dart';
import '../../plugins/plugins.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workHoursAsync = ref.watch(workHoursProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 联系信息 ──
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '如有优化意见 请微信联系cWV9822',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                ),
              ),
            ),
          ),

          // ── 通用设置 ──
          _SectionHeader(icon: Icons.tune, title: '通用设置'),
          Text('应用外观与工作时段配置',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),

          // 主题设置
          const _ThemeCard(),

          const SizedBox(height: 16),

          // 工作时间
          workHoursAsync.when(
            loading: () => const Card(
              child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            ),
            error: (e, _) => const SizedBox.shrink(),
            data: (wh) => _WorkHoursCard(
              config: wh,
              onStartPick: () => _pickWorkTime(wh, true),
              onEndPick: () => _pickWorkTime(wh, false),
            ),
          ),
          const SizedBox(height: 16),

          // ── 插件管理 ──
          _PluginList(),
        ],
      ),
    );
  }

  Future<void> _pickWorkTime(WorkHoursConfig current, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? current.workStart : current.workEnd,
      cancelText: '取消',
      confirmText: '确定',
      helpText: isStart ? '工作起始时间' : '工作结束时间',
    );
    if (picked != null) {
      final updated = isStart
          ? current.copyWith(workStart: picked)
          : current.copyWith(workEnd: picked);
      await updated.save();
      ref.invalidate(workHoursProvider);
    }
  }

}

/// 主题设置卡片（与插件卡片宽度一致）
class _ThemeCard extends ConsumerWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.primaryContainer.withAlpha(120),
                  ),
                  child: Icon(Icons.palette_outlined, size: 22, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('主题设置', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('切换应用外观，即时生效并自动保存',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                  label: Text('浅色'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                  label: Text('深色'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.phone_android, size: 18),
                  label: Text('跟随系统'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (v) {
                ref.read(themeModeProvider.notifier).setTheme(v.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 工作时间卡片（与插件卡片宽度一致）
class _WorkHoursCard extends StatelessWidget {
  final WorkHoursConfig config;
  final VoidCallback onStartPick;
  final VoidCallback onEndPick;

  const _WorkHoursCard({
    required this.config,
    required this.onStartPick,
    required this.onEndPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.primaryContainer.withAlpha(120),
                  ),
                  child: Icon(Icons.schedule, size: 22, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('工作时间', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('设定每日工作时段，各插件将基于此安排任务',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 时间选择器
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    label: '起始时间',
                    time: config.formatTime(config.workStart),
                    onTap: onStartPick,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('~', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ),
                Expanded(
                  child: _TimeCard(
                    label: '结束时间',
                    time: config.formatTime(config.workEnd),
                    onTap: onEndPick,
                  ),
                ),
              ],
            ),
            if (config.crossesMidnight) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.nightlight_round, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text('跨午夜模式，凌晨时间归入次日', style: TextStyle(fontSize: 12, color: Colors.blue))),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // 说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '称重任务将于起始时间前 30 分钟自动生成',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// 时间选择卡片（复用模式）
class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeCard({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time, style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
                const SizedBox(width: 4),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PluginList extends ConsumerStatefulWidget {
  const _PluginList();
  @override
  ConsumerState<_PluginList> createState() => _PluginListState();
}

class _PluginListState extends ConsumerState<_PluginList> {
  @override
  Widget build(BuildContext context) {
    final plugins = pluginRegistry.plugins;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(children: [
          Icon(Icons.extension_outlined, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('插件管理', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('管理各功能模块的启用状态和设置',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        if (plugins.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('暂无注册插件',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          )
        else
          ...plugins.map((p) => _PluginCard(
                plugin: p,
                onToggle: (v) {
                  pluginRegistry.setEnabled(p.id, v);
                  ref.read(pluginToggleVersionProvider.notifier).update((s) => s + 1);
                  setState(() {});
                },
              )),
      ],
    );
  }
}

class _PluginCard extends StatelessWidget {
  final FeaturePlugin plugin;
  final ValueChanged<bool> onToggle;

  const _PluginCard({required this.plugin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = plugin.enabled;
    final hasSettings = plugin.settingsBuilder != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 头部行 ──
            Row(
              children: [
                // 图标容器
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: enabled ? scheme.primaryContainer.withAlpha(120) : Colors.grey.shade100,
                  ),
                  child: Icon(
                    plugin.icon,
                    size: 22,
                    color: enabled ? scheme.primary : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                // 名称 + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            plugin.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: enabled ? null : Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.shade200,
                          ),
                          child: Text(plugin.id,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ),
                      ]),
                    ],
                  ),
                ),
                // 设置齿轮
                if (hasSettings)
                  IconButton(
                    icon: Icon(Icons.settings,
                        size: 20,
                        color: enabled ? scheme.primary.withAlpha(180) : Colors.grey.shade400),
                    tooltip: '${plugin.displayName}设置',
                    onPressed: enabled
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: plugin.settingsBuilder!),
                            )
                        : null,
                    visualDensity: VisualDensity.compact,
                  ),
                // 开关
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            // ── 描述 ──
            if (plugin.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(plugin.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
              ),
            ],
            // ── 功能标签 ──
            if (plugin.pages.isNotEmpty || plugin.quickActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...plugin.pages.where((p) => p.showInSidebar).map((p) => _FeatureChip(
                          icon: p.icon, label: p.title, enabled: enabled,
                        )),
                    ...plugin.quickActions.map((a) => _FeatureChip(
                          icon: a.icon, label: a.label, enabled: enabled, isAction: true,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isAction;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.enabled,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = enabled
        ? (isAction ? scheme.tertiary : scheme.primary)
        : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withAlpha(enabled ? 25 : 15),
        border: Border.all(color: color.withAlpha(enabled ? 80 : 40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// 通用 section 标题，与插件管理标题风格一致
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 22, color: theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}
