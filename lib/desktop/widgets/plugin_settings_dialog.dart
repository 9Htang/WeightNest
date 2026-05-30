import 'package:flutter/material.dart';
import '../../plugins/plugins.dart';

class PluginSettingsDialog extends StatelessWidget {
  const PluginSettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const PluginSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plugins = pluginRegistry.plugins;
    return StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.extension_outlined, size: 22),
          SizedBox(width: 8),
          Text('插件管理'),
        ]),
        content: SizedBox(
          width: 480,
          child: plugins.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('暂无注册插件', style: TextStyle(color: Colors.grey)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: plugins.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = plugins[i];
                    return ListTile(
                      leading: Icon(p.icon, color: p.enabled ? Colors.teal : Colors.grey),
                      title: Row(children: [
                        Text(p.displayName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: p.enabled ? null : Colors.grey)),
                        const SizedBox(width: 8),
                        Text(p.id,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                      subtitle: p.description.isNotEmpty
                          ? Text(p.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                          : null,
                      trailing: Switch(
                        value: p.enabled,
                        onChanged: (v) {
                          pluginRegistry.setEnabled(p.id, v);
                          setDlg(() {});
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }
}
