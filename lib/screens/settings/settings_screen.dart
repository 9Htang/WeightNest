import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/excel_export_service.dart';
import '../../providers.dart';
import '../../plugins/plugins.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _exportPath;
  int? _selectedYear;
  int? _selectedMonth;
  String? _exportLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 数据导出 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, size: 22),
                      const SizedBox(width: 8),
                      Text('数据导出', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('按月份导出所有鹦鹉体重记录为 Excel', style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickMonth(),
                          child: Text(_exportLabel ?? '选择月份'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: (_selectedYear != null && _selectedMonth != null)
                            ? () => _exportData()
                            : null,
                        icon: const Icon(Icons.download),
                        label: const Text('导出 Excel'),
                      ),
                    ],
                  ),
                  if (_exportPath != null && _exportPath != '正在导出...' && !_exportPath!.startsWith('导出失败')) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Share.shareXFiles([XFile(_exportPath!)]),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('分享文件'),
                      ),
                    ),
                  ],
                  if (_exportPath != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _exportPath!.startsWith('导出失败') ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_exportPath!, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 插件管理 ──
          _PluginList(),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month),
      helpText: '选择导出月份',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
        _exportLabel = '${picked.year}年${picked.month}月';
        _exportPath = null;
      });
    }
  }

  Future<void> _exportData() async {
    if (_selectedYear == null || _selectedMonth == null) return;
    setState(() => _exportPath = '正在导出...');
    try {
      final db = ref.read(databaseProvider);
      final service = ExcelExportService(db);
      final file = await service.exportMonthly(_selectedYear!, _selectedMonth!);
      if (file != null) {
        setState(() => _exportPath = file.path);
      } else {
        setState(() => _exportPath = '导出失败：无数据');
      }
    } catch (e) {
      setState(() => _exportPath = '导出失败: $e');
    }
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.extension_outlined, size: 22),
              SizedBox(width: 8),
              Text('插件管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            if (plugins.isEmpty)
              const Text('暂无注册插件', style: TextStyle(color: Colors.grey))
            else
              ...plugins.map((p) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                secondary: Icon(p.icon, color: p.enabled ? Colors.teal : Colors.grey, size: 22),
                title: Row(children: [
                  Text(p.displayName, style: TextStyle(fontWeight: FontWeight.w600, color: p.enabled ? null : Colors.grey)),
                  const SizedBox(width: 8),
                  Text(p.id, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
                subtitle: p.description.isNotEmpty ? Text(p.description, style: const TextStyle(fontSize: 12)) : null,
                value: p.enabled,
                onChanged: (v) {
                  pluginRegistry.setEnabled(p.id, v);
                  ref.read(pluginToggleVersionProvider.notifier).update((s) => s + 1);
                  setState(() {});
                },
              )),
              // 设置按钮 — 仅可配置的插件显示
              ...pluginRegistry.configurablePlugins.map((p) => Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('插件设置', style: TextStyle(fontSize: 13)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: p.settingsBuilder!),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
