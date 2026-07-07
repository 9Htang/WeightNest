import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';
import '../../widgets/feather_icon.dart';
import '../../widgets/list/app_list_card.dart';
import '../../widgets/list/empty_state.dart';

/// 品种管理页面
class SpeciesScreen extends ConsumerStatefulWidget {
  const SpeciesScreen({super.key});

  @override
  ConsumerState<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends ConsumerState<SpeciesScreen> {
  @override
  Widget build(BuildContext context) {
    final spAsync = ref.watch(allSpeciesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('品种管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: spAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (spList) => spList.isEmpty
            ? EmptyState(
                icon: const FeatherIcon(size: 56),
                message: '暂无品种',
                hint: '点击右下角 + 添加品种',
              )
            : ListView.builder(
                itemCount: spList.length,
                itemBuilder: (context, i) {
                  final s = spList[i];
                  return AppListCard.tile(
                    title: Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '雏鸟每${s.nestlingWeighIntervalDays}天 · 幼鸟每${s.juvenileWeighIntervalDays}天 · 成鸟每${s.adultWeighIntervalDays}天',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('删除',
                                style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') _showEditDialog(context, s);
                        if (v == 'delete') _confirmDelete(context, s);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Specy? existing) {
    // 在 showDialog 之前取出 db —— 异步回调中不能访问 ref
    final db = ref.read(databaseProvider);

    showDialog<bool>(
      context: context,
      builder: (ctx) => _SpeciesEditDialog(existing: existing, db: db),
    ).then((saved) {
      if (saved == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.invalidate(allSpeciesProvider);
        });
      }
    });
  }

  void _confirmDelete(BuildContext context, Specy s) {
    // 在 showDialog 之前取出 db —— 异步回调中不能访问 ref
    final db = ref.read(databaseProvider);

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除品种「${s.name}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.removeSpecies(s.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    ).then((deleted) {
      if (deleted == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.invalidate(allSpeciesProvider);
        });
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 品种编辑弹窗 — 独立 StatefulWidget，控制器生命周期由框架管理
// ═══════════════════════════════════════════════════════════════════════════

class _SpeciesEditDialog extends StatefulWidget {
  final Specy? existing;
  final AppDatabase db;

  const _SpeciesEditDialog({this.existing, required this.db});

  @override
  State<_SpeciesEditDialog> createState() => _SpeciesEditDialogState();
}

class _SpeciesEditDialogState extends State<_SpeciesEditDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController nestlingEndCtrl;
  late final TextEditingController juvenileEndCtrl;
  late final TextEditingController nestlingWICtrl;
  late final TextEditingController juvenileWICtrl;
  late final TextEditingController adultWICtrl;
  late final TextEditingController minWeightGCtrl;
  late final TextEditingController maxWeightGCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nameCtrl = TextEditingController(text: e?.name ?? '');
    nestlingEndCtrl =
        TextEditingController(text: '${e?.nestlingEndDays ?? 45}');
    juvenileEndCtrl =
        TextEditingController(text: '${e?.juvenileEndDays ?? 120}');
    nestlingWICtrl =
        TextEditingController(text: '${e?.nestlingWeighIntervalDays ?? 1}');
    juvenileWICtrl =
        TextEditingController(text: '${e?.juvenileWeighIntervalDays ?? 3}');
    adultWICtrl =
        TextEditingController(text: '${e?.adultWeighIntervalDays ?? 7}');
    minWeightGCtrl =
        TextEditingController(text: e?.minWeightG?.toString() ?? '');
    maxWeightGCtrl =
        TextEditingController(text: e?.maxWeightG?.toString() ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    nestlingEndCtrl.dispose();
    juvenileEndCtrl.dispose();
    nestlingWICtrl.dispose();
    juvenileWICtrl.dispose();
    adultWICtrl.dispose();
    minWeightGCtrl.dispose();
    maxWeightGCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? '编辑品种' : '新增品种'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 12),
            const Text('生长阶段划分',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: nestlingEndCtrl,
                  decoration: const InputDecoration(
                      labelText: '雏鸟结束(天)', isDense: true),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: juvenileEndCtrl,
                  decoration: const InputDecoration(
                      labelText: '幼鸟结束(天)', isDense: true),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('称重间隔',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: nestlingWICtrl,
                  decoration:
                      const InputDecoration(labelText: '雏鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: juvenileWICtrl,
                  decoration:
                      const InputDecoration(labelText: '幼鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: adultWICtrl,
                  decoration:
                      const InputDecoration(labelText: '成鸟(天)', isDense: true),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('正常体重范围 (选填，用于剂量安全校验)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: minWeightGCtrl,
                  decoration: const InputDecoration(
                    labelText: '最低体重(g)',
                    isDense: true,
                    hintText: '如 20',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: maxWeightGCtrl,
                  decoration: const InputDecoration(
                    labelText: '最高体重(g)',
                    isDense: true,
                    hintText: '如 80',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;

            // 在 await 前读完所有值 —— db 由外层传入，不碰 ref
            final nestlingEnd = int.tryParse(nestlingEndCtrl.text);
            final juvenileEnd = int.tryParse(juvenileEndCtrl.text);
            final nestlingWI = int.tryParse(nestlingWICtrl.text);
            final juvenileWI = int.tryParse(juvenileWICtrl.text);
            final adultWI = int.tryParse(adultWICtrl.text);
            final minW = double.tryParse(minWeightGCtrl.text);
            final maxW = double.tryParse(maxWeightGCtrl.text);
            final existing = widget.existing;
            final db = widget.db;

            if (existing != null) {
              await db.updateSpecies(existing.id,
                  name: name,
                  nestlingEndDays: nestlingEnd,
                  juvenileEndDays: juvenileEnd,
                  nestlingWeighIntervalDays: nestlingWI,
                  juvenileWeighIntervalDays: juvenileWI,
                  adultWeighIntervalDays: adultWI,
                  minWeightG: minW,
                  maxWeightG: maxW);
            } else {
              await db.createSpecies(name,
                  nestlingEndDays: nestlingEnd ?? 45,
                  juvenileEndDays: juvenileEnd ?? 120,
                  nestlingWeighIntervalDays: nestlingWI ?? 1,
                  juvenileWeighIntervalDays: juvenileWI ?? 3,
                  adultWeighIntervalDays: adultWI ?? 7,
                  minWeightG: minW,
                  maxWeightG: maxW);
            }

            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
