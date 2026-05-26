import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';

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
            ? const Center(child: Text('暂无品种'))
            : ListView.builder(
                itemCount: spList.length,
                itemBuilder: (context, i) {
                  final s = spList[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: ListTile(
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '雏鸟${s.nestlingEndDays}天 · 幼鸟${s.juvenileEndDays}天 · 成鸟每${s.adultWeighIntervalDays}天称重',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showEditDialog(context, s);
                          if (v == 'delete') _confirmDelete(context, s);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Specy? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final nestlingCtrl = TextEditingController(text: '${existing?.nestlingEndDays ?? 45}');
    final juvenileCtrl = TextEditingController(text: '${existing?.juvenileEndDays ?? 120}');
    final adultCtrl = TextEditingController(text: '${existing?.adultWeighIntervalDays ?? 7}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑品种' : '新增品种'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称')),
              const SizedBox(height: 8),
              TextField(controller: nestlingCtrl, decoration: const InputDecoration(labelText: '雏鸟结束天数'),
                keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: juvenileCtrl, decoration: const InputDecoration(labelText: '幼鸟结束天数'),
                keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: adultCtrl, decoration: const InputDecoration(labelText: '成鸟称重周期(天)'),
                keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final db = ref.read(databaseProvider);
            if (existing != null) {
              await db.updateSpecies(existing.id, name: name,
                  nestlingEndDays: int.tryParse(nestlingCtrl.text),
                  juvenileEndDays: int.tryParse(juvenileCtrl.text),
                  adultWeighIntervalDays: int.tryParse(adultCtrl.text));
            } else {
              await db.createSpecies(name,
                  nestlingEndDays: int.tryParse(nestlingCtrl.text) ?? 45,
                  juvenileEndDays: int.tryParse(juvenileCtrl.text) ?? 120,
                  adultWeighIntervalDays: int.tryParse(adultCtrl.text) ?? 7);
            }
            ref.invalidate(allSpeciesProvider);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('保存')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Specy s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除品种「${s.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(databaseProvider).removeSpecies(s.id);
              ref.invalidate(allSpeciesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
