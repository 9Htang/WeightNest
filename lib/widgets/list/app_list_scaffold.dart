import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'empty_state.dart';

/// 列表页骨架 —— 自动组装 loading / error / empty / list 四种状态。
///
/// 收口历史上 3 种状态分支写法（`if (_loading) ...` 嵌套 vs
/// `AsyncValue.when` vs `FutureBuilder`），让页面只关心数据与 item 渲染。
///
/// 提供 [onRefresh] 时自动包 [RefreshIndicator]；提供 [searchField] /
/// [filterBar] 时插入 AppBar.bottom / body 顶部；提供 [fab] 时挂到 Scaffold。
///
/// 注意：[ReorderableListView] 不能用本组件的内部 [ListView.separated]，
/// 拖拽列表请直接用 [Scaffold] + [ReorderableListView]，仅复用 [AppListCard]。
///
/// 用法：
/// ```dart
/// AppListScaffold<Disease>(
///   title: '疾病库',
///   loading: _loading,
///   items: _diseases,
///   emptyState: EmptyState(icon: Icons.coronavirus_outlined, message: '疾病库为空', hint: '点击右下角 + 添加疾病'),
///   searchField: TextField(...),
///   onRefresh: _load,
///   itemBuilder: (_, d) => AppListCard.icon(...),
///   fab: FloatingActionButton(onPressed: ..., child: Icon(Icons.add)),
/// );
/// ```
class AppListScaffold<T> extends StatelessWidget {
  /// AppBar 标题。
  final String title;

  /// AppBar 右侧操作。
  final List<Widget>? appBarActions;

  /// AppBar.bottom 内嵌的搜索框（可选）。
  /// 调用方提供完整的 TextField，本组件负责插入 AppBar。
  final Widget? searchField;

  /// 顶部筛选行（可选），放在 AppBar 下方、列表上方。
  final Widget? filterBar;

  /// 是否处于加载中。
  final bool loading;

  /// 错误信息。非 null 则展示错误态。
  final String? error;

  /// 列表数据。
  final List<T> items;

  /// 列表项构造器。
  final Widget Function(BuildContext, T) itemBuilder;

  /// 列表项之间的分隔（ListView.separated）。
  /// 默认 `SizedBox.shrink()`。
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// 列表 padding。默认 horizontal [AppSpacing.md]、vertical [AppSpacing.xs]、bottom 80（FAB 留白）。
  final EdgeInsets? listPadding;

  /// 空状态视图。默认通用 [EmptyState]（无图标，调用方建议提供）。
  final Widget? emptyState;

  /// 下拉刷新回调。提供则启用 [RefreshIndicator]。
  final Future<void> Function()? onRefresh;

  /// 右下角 FAB。
  final Widget? fab;

  const AppListScaffold({
    super.key,
    required this.title,
    this.appBarActions,
    this.searchField,
    this.filterBar,
    this.loading = false,
    this.error,
    required this.items,
    required this.itemBuilder,
    this.separatorBuilder,
    this.listPadding,
    this.emptyState,
    this.onRefresh,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final theme = Theme.of(context);

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(
        child: Padding(
          padding: sp.paddingLg,
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      );
    } else if (items.isEmpty) {
      body = emptyState ??
          EmptyState(
            icon: const Icon(Icons.inbox_outlined, size: 56),
            message: '暂无数据',
          );
    } else {
      // QQ 式无缝列表：垂直 padding 0，靠分隔线区分行；底部留白给 FAB。
      final effectivePadding = listPadding ??
          EdgeInsets.fromLTRB(0, 0, 0, sp.xxl * 2.5 // 80
              );
      Widget list = ListView.separated(
        padding: effectivePadding,
        itemCount: items.length,
        // 默认分隔线：indent 80 对齐内容区（跳过左侧头像/图标列）。
        separatorBuilder: separatorBuilder ??
            (context, _) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 80,
                  endIndent: 12,
                  color: theme.dividerColor,
                ),
        itemBuilder: (ctx, i) => itemBuilder(ctx, items[i]),
      );
      if (onRefresh != null) {
        list = RefreshIndicator(onRefresh: onRefresh!, child: list);
      }
      body = filterBar != null
          ? Column(
              children: [
                filterBar!,
                Expanded(child: list),
              ],
            )
          : list;
    }

    // 加载/错误/空状态下也保留 filterBar（如搜索结果为空时仍显示筛选）。
    if (filterBar != null && (loading || items.isEmpty || error != null)) {
      body = Column(
        children: [
          filterBar!,
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: searchField != null
          ? AppBar(
              title: Text(title),
              actions: appBarActions,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sp.md, 0, sp.md, sp.sm),
                  child: searchField!,
                ),
              ),
            )
          : AppBar(
              title: Text(title),
              actions: appBarActions,
            ),
      body: body,
      floatingActionButton: fab,
    );
  }
}
