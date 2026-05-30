import 'package:flutter/material.dart';
import '../../core/plugin.dart';
import '../../plugins/plugins.dart';
import 'widgets/plugin_settings_dialog.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const _navItems = [
  SidebarItem(label: '概览', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
  SidebarItem(label: '操作日志', icon: Icons.history_outlined, selectedIcon: Icons.history),
  SidebarItem(label: '鹦鹉档案', icon: Icons.pets_outlined, selectedIcon: Icons.pets),
  SidebarItem(label: '人员管理', icon: Icons.people_outlined, selectedIcon: Icons.people),
  SidebarItem(label: '房间管理', icon: Icons.meeting_room_outlined, selectedIcon: Icons.meeting_room),
  SidebarItem(label: '品种配置', icon: Icons.science_outlined, selectedIcon: Icons.science),
];

class CollapsibleSidebar extends StatelessWidget {
  final bool collapsed;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  final VoidCallback onQrLogin;
  final VoidCallback onRefresh;
  final VoidCallback? onToggleTheme;
  final void Function(FeaturePlugin plugin, PluginPageDescriptor page)? onPluginPage;

  const CollapsibleSidebar({
    super.key,
    required this.collapsed,
    required this.selectedIndex,
    required this.onSelect,
    required this.onToggle,
    required this.onQrLogin,
    required this.onRefresh,
    this.onToggleTheme,
    this.onPluginPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = collapsed ? 56.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withAlpha(50),
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Logo area ──
          _SidebarHeader(
            collapsed: collapsed,
            scheme: scheme,
          ),
          const SizedBox(height: 8),
          // ── Nav items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = i == selectedIndex;
                return _SidebarTile(
                  item: item,
                  selected: selected,
                  collapsed: collapsed,
                  onTap: () => onSelect(i),
                );
              }),
            ),
          ),
          // ── Plugin pages (dynamic) ──
          if (onPluginPage != null) ...[
            const SizedBox(height: 4),
            Divider(height: 1, color: scheme.outlineVariant.withAlpha(40)),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 0, 2),
                child: Text('插件', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1)),
              ),
            for (final plugin in pluginRegistry.enabledPlugins)
              for (final page in plugin.pages.where((p) => p.showInSidebar))
                _SidebarAction(
                  icon: page.icon,
                  label: page.title,
                  collapsed: collapsed,
                  onTap: () => onPluginPage!(plugin, page),
                ),
          ],

          // ── Bottom actions ──
          Divider(height: 1, color: scheme.outlineVariant.withAlpha(40)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onToggleTheme != null)
                  _SidebarAction(
                    icon: Icons.dark_mode_outlined,
                    label: '切换主题',
                    collapsed: collapsed,
                    onTap: onToggleTheme!,
                  ),
                _SidebarAction(
                  icon: Icons.qr_code,
                  label: '扫码登录',
                  collapsed: collapsed,
                  onTap: onQrLogin,
                ),
                _SidebarAction(
                  icon: Icons.extension_outlined,
                  label: '插件管理',
                  collapsed: collapsed,
                  onTap: () => PluginSettingsDialog.show(context),
                ),
                _SidebarAction(
                  icon: Icons.refresh,
                  label: '刷新数据',
                  collapsed: collapsed,
                  onTap: onRefresh,
                ),
                const SizedBox(height: 4),
                _SidebarAction(
                  icon: collapsed ? Icons.chevron_right : Icons.chevron_left,
                  label: collapsed ? '展开' : '收起',
                  collapsed: collapsed,
                  onTap: onToggle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final ColorScheme scheme;

  const _SidebarHeader({required this.collapsed, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 12 : 16,
        vertical: 10,
      ),
      child: collapsed
          ? Center(
              child: Icon(Icons.pets, size: 24, color: scheme.primary),
            )
          : Row(
              children: [
                Icon(Icons.pets, size: 22, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'WeightNest',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withAlpha(80)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 42,
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border(
                      left: BorderSide(
                        color: scheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: collapsed
                ? Tooltip(
                    message: item.label,
                    child: Center(
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 22,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(160),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 2),
                      Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(160),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurface.withAlpha(200),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: collapsed
          ? Tooltip(
              message: label,
              child: IconButton(
                icon: Icon(icon, size: 18),
                onPressed: onTap,
                splashRadius: 16,
                color: scheme.onSurface.withAlpha(160),
              ),
            )
          : InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 16,
                        color: scheme.onSurface.withAlpha(160)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withAlpha(180),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
