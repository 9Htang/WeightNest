import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/plugin.dart';
import '../../services/work_hours_config.dart';
import '../../services/backup_service.dart';
import '../../providers.dart';
import '../../plugins/plugins.dart';

import 'bird_import_preview_dialog.dart';


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

          // ── Pro 备份恢复 ──
          const _PremiumCard(),
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

/// Pro 备份恢复卡片
class _PremiumCard extends ConsumerWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = ref.watch(premiumStatusProvider);
    final isPro = status == PremiumStatus.pro;

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isPro
                        ? Colors.amber.shade100
                        : scheme.primaryContainer.withAlpha(120),
                  ),
                  child: Icon(
                    isPro ? Icons.verified : Icons.lock_outline,
                    size: 22,
                    color: isPro ? Colors.amber.shade700 : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'Pro 版' : '免费版',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPro ? Colors.amber.shade700 : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro ? '数据备份与恢复已解锁' : '升级 Pro 解锁数据备份与恢复',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isPro) ...[
              // Pro 功能按钮 — 备份恢复
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _createBackup(context, ref),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('备份数据'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreBackup(context, ref),
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('恢复数据'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 导入鹦鹉数据
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _importBirds(context, ref),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('导入鹦鹉数据'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ]
            else
              // 升级按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showActivateDialog(context, ref),
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('升级到 Pro'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    // 显示进度
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final backupFile = await BackupService().createBackup();

    // 关闭进度
    if (context.mounted) Navigator.of(context).pop();

    if (backupFile != null && context.mounted) {
      // 通过 share_plus 分享
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'WeightNest 数据备份',
      );
      // 分享后删除临时文件
      try { await backupFile.delete(); } catch (_) {}
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份失败，请重试')),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    // 确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text(
          '即将覆盖当前所有数据（包括体重记录、鹦鹉信息、照片等），此操作不可撤销。\n\n请确认已选择正确的备份文件。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    // 选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // .wnbak 不是已知类型
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    // 执行恢复
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ok = await BackupService().restoreFrom(File(filePath));

    if (context.mounted) Navigator.of(context).pop();

    if (ok) {
      // 强制刷新数据库连接，无需重启
      ref.invalidate(databaseProvider);
    }

    if (ok && context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('恢复成功'),
          content: const Text('数据已恢复。'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复失败，请检查备份文件是否有效')),
      );
    }
  }


  Future<void> _importBirds(BuildContext context, WidgetRef ref) async {
    // 确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入鹦鹉数据'),
        content: const Text(
          '将创建文件中新的鹦鹉及其全部数据（体重、喂药、照片等）。\n'
          '已存在的鹦鹉（UUID 匹配）将被跳过。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    // 选择文件
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty || !context.mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    // 显示预览
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => BirdImportPreviewDialog(file: File(filePath)),
    );
  }
}

/// 激活码输入对话框
Future<void> _showActivateDialog(BuildContext context, WidgetRef ref) async {
  final code = await showDialog<String>(
    context: context,
    builder: (_) => const _ActivateDialog(),
  );

  if (code != null && context.mounted) {
    // 显示进度
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ref.read(premiumStatusProvider.notifier).activate(code);

      // 关闭进度对话框
      if (context.mounted) Navigator.of(context).pop();

      // Dialog 关闭动画约 200ms，等待动画彻底完成后 widget tree 稳定，
      // 再调 setPro() 触发 notifyListeners
      if (success) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          ref.read(premiumStatusProvider.notifier).setPro();
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '激活成功！Pro 功能已解锁' : '激活码无效'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('激活出错：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 激活码输入对话框（自管理 TextEditingController 生命周期）
class _ActivateDialog extends StatefulWidget {
  const _ActivateDialog();

  @override
  State<_ActivateDialog> createState() => _ActivateDialogState();
}

class _ActivateDialogState extends State<_ActivateDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('升级到 Pro'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请输入激活码（格式：WNPRO-XXXX-XXXX-XXXX）',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'WNPRO-XXXX-XXXX-XXXX',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入激活码';
                if (!v.trim().toUpperCase().startsWith('WNPRO-')) {
                  return '激活码格式不正确';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final code = _controller.text.trim().toUpperCase();
              Navigator.pop(context, code);
            }
          },
          child: const Text('激活'),
        ),
      ],
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
