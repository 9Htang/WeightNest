import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/category_colors.dart';
import '../../../theme/theme.dart';
import '../../../widgets/list/app_list_card.dart';
import '../../../widgets/list/app_list_scaffold.dart';
import '../../../widgets/list/empty_state.dart';
import '../../../widgets/list/filter_chip_bar.dart';
import '../nutrition_export_service.dart';
import '../nutrition_import_service.dart';
import '../nutrition_math.dart';
import '../nutrition_repository.dart';
import 'food_editor_screen.dart';

/// 食材库列表页 —— 搜索、分类筛选、增删改。
class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  List<Food> _foods = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _categoryFilter; // null = 全部分类

  /// 食物分类列表（与 Foods 表 category 默认值一致）
  static const _categories = ['主食', '蔬果', '补充剂', '其他'];

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<Food> foods;
    if (_query.isNotEmpty) {
      foods = await _db.searchFoods(_query);
    } else {
      foods = await _db.getAllFoods(category: _categoryFilter);
    }
    if (mounted) {
      setState(() {
        _foods = foods;
        _loading = false;
      });
    }
  }

  Future<void> _navigateToEditor([Food? food]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodEditorScreen(food: food),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _export() async {
    try {
      await NutritionExportService().exportCsv();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _import() async {
    try {
      final result = await NutritionImportService().pickAndImport(context);
      if (result == null) return; // 用户取消选文件
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导入完成：新增 ${result.foodsCreated}，更新 ${result.foodsUpdated}'
              '${result.foodsSkipped > 0 ? "，跳过 ${result.foodsSkipped}" : ""}',
            ),
            action: result.errors.isNotEmpty
                ? SnackBarAction(
                    label: '查看错误',
                    onPressed: () => _showErrors(result.errors),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  void _showErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入错误'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: errors
                .map((e) => Text(e, style: const TextStyle(fontSize: 13)))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Food food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除食材'),
        content: Text('确定要删除「${food.name}」吗？\n关联的食谱食物项将保留但不再显示食材名。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteFood(food.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除「${food.name}」')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppListScaffold<Food>(
      title: '食材库',
      appBarActions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'export') _export();
            if (v == 'import') _import();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('导出'),
                  dense: true),
            ),
            PopupMenuItem(
              value: 'import',
              child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('导入'),
                  dense: true),
            ),
          ],
        ),
      ],
      searchField: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: '搜索食材名称',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: context.r.bLg,
          ),
        ),
        onChanged: (v) {
          _query = v.trim();
          _load();
        },
      ),
      filterBar: FilterChipBar<String?>(
        options: [
          const (value: null, label: '全部'),
          ..._categories.map((c) => (value: c as String?, label: c)),
        ],
        selected: _categoryFilter,
        onSelected: (v) {
          setState(() {
            _categoryFilter = v;
            _loading = true;
          });
          _load();
        },
      ),
      loading: _loading,
      items: _foods,
      onRefresh: _load,
      emptyState: EmptyState(
        icon: const Icon(Icons.restaurant, size: 56),
        message: '暂无食材，点击右下角 + 添加',
      ),
      fab: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
      ),
      itemBuilder: (_, f) {
        final completeness = computeFoodCompleteness(f);
        return _FoodCard(
          food: f,
          completeness: completeness,
          onTap: () => _navigateToEditor(f),
          onDelete: () => _confirmDelete(f),
        );
      },
    );
  }
}

/// 单个食材卡片：名称、分类徽章、数据质量、营养完整度进度条。
class _FoodCard extends StatelessWidget {
  final Food food;
  final int completeness;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FoodCard({
    required this.food,
    required this.completeness,
    required this.onTap,
    required this.onDelete,
  });

  Color _completenessColor(ThemeData theme, int value) {
    final sc = AppTheme.statusColors(theme.colorScheme);
    if (value >= 70) return sc.success;
    if (value >= 40) return sc.warning;
    return sc.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sp = context.sp;
    final r = context.r;
    final (catFg, catBg) = CategoryColors.forCategory(scheme, food.category);
    final cColor = _completenessColor(theme, completeness);

    // 数据质量徽章（标题右侧）
    final badge = (food.dataConfidence != null && food.dataConfidence!.isNotEmpty)
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: sp.xs + 2, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: r.bXs,
            ),
            child: Text(food.dataConfidence!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          )
        : null;

    return AppListCard(
      title: Text(food.name,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      badge: badge,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: sp.xs + 2,
            runSpacing: sp.xs,
            children: [
              // 分类
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: sp.xs + 2, vertical: 2),
                decoration: BoxDecoration(
                  color: catBg,
                  borderRadius: r.bXs,
                ),
                child: Text(food.category,
                    style: theme.textTheme.labelSmall?.copyWith(color: catFg)),
              ),
              if (food.isHulled)
                Text('去壳', style: theme.textTheme.labelSmall),
              Text(food.basis, style: theme.textTheme.labelSmall),
            ],
          ),
          SizedBox(height: sp.xs + 2),
          // 营养完整度进度条
          Row(
            children: [
              Text('营养完整度',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
              SizedBox(width: sp.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: r.bXs,
                  child: LinearProgressIndicator(
                    value: completeness / 100,
                    backgroundColor: theme.dividerColor,
                    color: cColor,
                    minHeight: 6,
                  ),
                ),
              ),
              SizedBox(width: sp.xs + 2),
              Text('$completeness%',
                  style: theme.textTheme.labelSmall?.copyWith(color: cColor)),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: onDelete,
        color: scheme.error,
      ),
      onTap: onTap,
    );
  }
}
