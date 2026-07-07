import 'package:flutter/material.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../theme/app_tokens.dart';
import '../../theme/category_colors.dart';
import '../../widgets/list/app_list_scaffold.dart';
import '../../widgets/list/empty_state.dart';
import '../../widgets/list/app_list_card.dart';
import 'drug_library_repository.dart';

/// Disease catalog management screen — list, add, edit, search diseases.
class DiseaseCatalogScreen extends StatefulWidget {
  const DiseaseCatalogScreen({super.key});

  @override
  State<DiseaseCatalogScreen> createState() => _DiseaseCatalogScreenState();
}

class _DiseaseCatalogScreenState extends State<DiseaseCatalogScreen> {
  List<DiseaseCatalogData> _diseases = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

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
    final diseases = _query.isEmpty
        ? await _db.getAllDiseases()
        : await _db.searchDiseases(_query);
    if (mounted)
      setState(() {
        _diseases = diseases;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppListScaffold<DiseaseCatalogData>(
      title: '疾病库',
      searchField: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: '搜索疾病名称',
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
      loading: _loading,
      items: _diseases,
      onRefresh: _load,
      emptyState: EmptyState(
        icon: const Icon(Icons.coronavirus_outlined, size: 56),
        message: _query.isNotEmpty ? '未找到匹配疾病' : '疾病库为空',
        hint: _query.isNotEmpty ? '尝试其他关键词搜索' : '点击右下角 + 添加疾病',
      ),
      fab: FloatingActionButton(
        onPressed: () => _showEditDialog(null),
        child: const Icon(Icons.add),
      ),
      itemBuilder: (_, d) {
        final scheme = Theme.of(context).colorScheme;
        final (fg, bg) = CategoryColors.forCategory(scheme, '疾病');
        return AppListCard.icon(
          icon: Icons.coronavirus,
          iconTint: fg,
          iconBg: bg,
          title: Text(d.diseaseName,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: (d.description != null && d.description!.isNotEmpty)
              ? Text(d.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: scheme.error.withAlpha(context.a.low),
            onPressed: () => _confirmDelete(d),
            visualDensity: VisualDensity.compact,
          ),
          onTap: () => _showEditDialog(d),
        );
      },
    );
  }

  void _showEditDialog(DiseaseCatalogData? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _DiseaseEditSheet(
        existing: existing,
        onSaved: _load,
      ),
    );
  }

  void _confirmDelete(DiseaseCatalogData disease) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除疾病「${disease.diseaseName}」？\n如果有关联的剂量规则，删除可能导致规则失效。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              await _db.removeDisease(disease.id);
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Disease Edit Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _DiseaseEditSheet extends StatefulWidget {
  final DiseaseCatalogData? existing;
  final VoidCallback onSaved;

  const _DiseaseEditSheet({this.existing, required this.onSaved});

  @override
  State<_DiseaseEditSheet> createState() => _DiseaseEditSheetState();
}

class _DiseaseEditSheetState extends State<_DiseaseEditSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl.text = e?.diseaseName ?? '';
    _descCtrl.text = e?.description ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Theme.of(context).dividerColor))),
              const SizedBox(height: 16),
              Text(isEdit ? '编辑疾病' : '添加疾病',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Disease name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: '疾病名称 *',
                    hintText: '呼吸道感染',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: '说明 (选填)',
                    hintText: '症状描述、注意事项等',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Save
              FilledButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text('保存'),
                onPressed: _nameCtrl.text.trim().isEmpty ? null : _doSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final db = _db;
    final isEdit = widget.existing != null;

    if (isEdit) {
      await db.updateDisease(
        widget.existing!.id,
        diseaseName: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
    } else {
      await db.addDisease(
        diseaseName: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }
}
