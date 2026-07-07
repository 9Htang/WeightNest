import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../../../repositories/species_repository.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/list/app_list_card.dart';
import '../../../widgets/list/app_list_scaffold.dart';
import '../../../widgets/list/empty_state.dart';
import '../../../widgets/list/filter_chip_bar.dart';
import '../nutrition_export_service.dart';
import '../nutrition_import_service.dart';
import '../nutrition_repository.dart';
import '../nutrition_stage.dart';
import 'blend_editor_screen.dart';

/// 配方库 —— 列出所有%比例混合粮配方。
class BlendLibraryScreen extends StatefulWidget {
  const BlendLibraryScreen({super.key});

  @override
  State<BlendLibraryScreen> createState() => _BlendLibraryScreenState();
}

class _BlendLibraryScreenState extends State<BlendLibraryScreen> {
  AppDatabase get _db => pluginRegistry.db!;
  List<Blend> _blends = [];
  /// 所有配方的绑定，按 blendId 分组（一次性批量加载，消除 N+1）。
  Map<int, List<BlendBinding>> _bindingsByBlend = {};
  List<Specy> _species = [];
  String? _stageFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _species = await _db.getAllSpecies();
    final blends = await _db.getAllBlends();
    // 一次性批量加载全部绑定，供阶段过滤与卡片展示共用。
    final allBindings =
        await _db.getBlendBindingsForAll(blends.map((b) => b.id));
    if (_stageFilter != null) {
      // 按阶段过滤：在内存中筛选含该阶段绑定的配方
      _blends = blends.where((b) {
        final bindings = allBindings[b.id] ?? const [];
        return bindings.any((bd) => bd.stage == _stageFilter);
      }).toList();
    } else {
      _blends = blends;
    }
    _bindingsByBlend = allBindings;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold<Blend>(
      title: '配方库',
      appBarActions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) async {
            if (v == 'export') {
              await NutritionExportService().exportJson();
            } else if (v == 'import') {
              final result =
                  await NutritionImportService().pickAndImport(context);
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '新增 ${result.totalCreated}，更新 ${result.totalUpdated}，跳过 ${result.totalSkipped}'),
                  action: result.errors.isNotEmpty
                      ? SnackBarAction(
                          label: '查看错误',
                          onPressed: () => _showErrors(result.errors),
                        )
                      : null,
                ));
                _refresh();
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'export', child: Text('导出 JSON')),
            PopupMenuItem(value: 'import', child: Text('导入')),
          ],
        ),
      ],
      filterBar: FilterChipBar<String?>(
        options: [
          const (value: null, label: '全部'),
          ...RecipeStage.all.map((s) => (value: s as String?, label: s)),
        ],
        selected: _stageFilter,
        onSelected: (v) {
          setState(() => _stageFilter = v);
          _refresh();
        },
      ),
      loading: _loading,
      items: _blends,
      onRefresh: _refresh,
      emptyState: EmptyState(
        icon: const Icon(Icons.blender_outlined, size: 56),
        message: '暂无配方，点击右下角 + 创建',
      ),
      fab: FloatingActionButton(
        onPressed: () => _navigateToEditor(null),
        child: const Icon(Icons.add),
      ),
      itemBuilder: (_, b) => _BlendCard(
        key: ValueKey(b.id),
        blend: b,
        bindings: _bindingsByBlend[b.id] ?? const [],
        species: _species,
        onTap: () => _navigateToEditor(b),
        onDelete: () => _confirmDelete(b),
      ),
    );
  }

  Future<void> _navigateToEditor(Blend? blend) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BlendEditorScreen(blend: blend),
    ));
    if (changed == true) _refresh();
  }

  Future<void> _confirmDelete(Blend blend) async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除配方'),
        content: Text('确定删除「${blend.name}」？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteBlend(blend.id);
      _refresh();
    }
  }

  void _showErrors(List<String> errors) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入错误'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: errors
                .map((e) => Text(e, style: theme.textTheme.bodySmall))
                .toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
      ),
    );
  }
}

/// 配方卡片。绑定由父级批量预加载后传入，避免每张卡各自查询（N+1）。
class _BlendCard extends StatelessWidget {
  final Blend blend;
  final List<BlendBinding> bindings;
  final List<Specy> species;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BlendCard({
    super.key,
    required this.blend,
    required this.bindings,
    required this.species,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sp = context.sp;
    final r = context.r;
    final a = context.a;
    return AppListCard(
      title: Text(blend.name, style: theme.textTheme.titleSmall),
      subtitle: bindings.isEmpty
          ? Text('未绑定物种/阶段', style: theme.textTheme.bodySmall)
          : Padding(
              padding: EdgeInsets.only(top: sp.xs),
              child: Wrap(
                spacing: sp.xs,
                runSpacing: sp.xs,
                children: bindings.take(3).map((b) {
                  final name = b.speciesId == null
                      ? '通用'
                      : species
                          .where((s) => s.id == b.speciesId)
                          .firstOrNull
                          ?.name;
                  return Chip(
                    label: Text('$name / ${b.stage}',
                        style: theme.textTheme.labelSmall),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  );
                }).toList(),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!blend.isActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: sp.xs + 2, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.onSurface.withAlpha(a.faint),
                borderRadius: r.bSm,
              ),
              child: Text('停用', style: theme.textTheme.labelSmall),
            ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: scheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
