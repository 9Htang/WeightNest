import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/plugin_registry.dart';
import '../../providers.dart';

class PluginStatusScreen extends ConsumerStatefulWidget {
  const PluginStatusScreen({super.key});

  @override
  ConsumerState<PluginStatusScreen> createState() => _PluginStatusScreenState();
}

class _PluginStatusScreenState extends ConsumerState<PluginStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plugins = pluginRegistry.plugins;

    return Scaffold(
      appBar: AppBar(title: const Text('插件状态')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: plugins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final p = plugins[i];
          final pages = p.pages;
          final queries = p.dataQueries;
          final hasSettings = p.settingsBuilder != null;

          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(p.icon, size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.displayName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(p.id, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(120), fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      Switch(
                        value: p.enabled,
                        onChanged: (v) {
                          pluginRegistry.setEnabled(p.id, v);
                          ref.read(pluginToggleVersionProvider.notifier).update((s) => s + 1);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (p.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(p.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160))),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MetaChip(label: '${pages.length} 页面', icon: Icons.pages),
                      _MetaChip(label: '${queries.length} 数据查询', icon: Icons.data_object),
                      if (hasSettings) const _MetaChip(label: '设置页', icon: Icons.settings),
                      if (!p.enabled) const _MetaChip(label: '已禁用', icon: Icons.block, error: true),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool error;

  const _MetaChip({required this.label, required this.icon, this.error = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = error ? scheme.error : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: c.withAlpha(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c)),
        ],
      ),
    );
  }
}
