import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';

import '../worker/worker_screen.dart';

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
                        '雏鸟每${s.nestlingWeighIntervalDays}天 · 幼鸟每${s.juvenileWeighIntervalDays}天 · 成鸟每${s.adultWeighIntervalDays}天',
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

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final c in controllers) { c.dispose(); }
  }

  void _showEditDialog(BuildContext context, Specy? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final nestlingEndCtrl = TextEditingController(text: '${existing?.nestlingEndDays ?? 45}');
    final juvenileEndCtrl = TextEditingController(text: '${existing?.juvenileEndDays ?? 120}');
    final nestlingWICtrl = TextEditingController(text: '${existing?.nestlingWeighIntervalDays ?? 1}');
    final juvenileWICtrl = TextEditingController(text: '${existing?.juvenileWeighIntervalDays ?? 3}');
    final adultWICtrl = TextEditingController(text: '${existing?.adultWeighIntervalDays ?? 7}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑品种' : '新增品种'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称')),
              const SizedBox(height: 12),
              const Text('生长阶段划分', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: TextField(controller: nestlingEndCtrl, decoration: const InputDecoration(labelText: '雏鸟结束(天)', isDense: true), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: juvenileEndCtrl, decoration: const InputDecoration(labelText: '幼鸟结束(天)', isDense: true), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              const Text('称重间隔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: TextField(controller: nestlingWICtrl, decoration: const InputDecoration(labelText: '雏鸟(天)', isDense: true), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: juvenileWICtrl, decoration: const InputDecoration(labelText: '幼鸟(天)', isDense: true), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: adultWICtrl, decoration: const InputDecoration(labelText: '成鸟(天)', isDense: true), keyboardType: TextInputType.number)),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _disposeControllers([nameCtrl, nestlingEndCtrl, juvenileEndCtrl, nestlingWICtrl, juvenileWICtrl, adultWICtrl]);
              Navigator.pop(ctx);
            },
            child: const Text('取消')),
          FilledButton(onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final db = ref.read(databaseProvider);
            if (existing != null) {
              final sp = await db.updateSpecies(existing.id, name: name,
                  nestlingEndDays: int.tryParse(nestlingEndCtrl.text),
                  juvenileEndDays: int.tryParse(juvenileEndCtrl.text),
                  nestlingWeighIntervalDays: int.tryParse(nestlingWICtrl.text),
                  juvenileWeighIntervalDays: int.tryParse(juvenileWICtrl.text),
                  adultWeighIntervalDays: int.tryParse(adultWICtrl.text));
              final userId = ref.read(workerProvider).userId;
              if (userId != null) {
                await ref.read(syncQueueProvider).enqueue(
                  userId: userId,
                  action: 'update_species',
                  entityType: 'species',
                  entityUuid: sp.uuid,
                  payload: {
                    'name': name,
                    'nestlingEndDays': sp.nestlingEndDays,
                    'juvenileEndDays': sp.juvenileEndDays,
                    'nestlingWeighIntervalDays': sp.nestlingWeighIntervalDays,
                    'juvenileWeighIntervalDays': sp.juvenileWeighIntervalDays,
                    'adultWeighIntervalDays': sp.adultWeighIntervalDays,
                  },
                );
              }
            } else {
              final sp = await db.createSpecies(name,
                  nestlingEndDays: int.tryParse(nestlingEndCtrl.text) ?? 45,
                  juvenileEndDays: int.tryParse(juvenileEndCtrl.text) ?? 120,
                  nestlingWeighIntervalDays: int.tryParse(nestlingWICtrl.text) ?? 1,
                  juvenileWeighIntervalDays: int.tryParse(juvenileWICtrl.text) ?? 3,
                  adultWeighIntervalDays: int.tryParse(adultWICtrl.text) ?? 7);
              final userId = ref.read(workerProvider).userId;
              if (userId != null) {
                await ref.read(syncQueueProvider).enqueue(
                  userId: userId,
                  action: 'create_species',
                  entityType: 'species',
                  entityUuid: sp.uuid,
                  payload: {
                    'name': name,
                    'nestlingEndDays': sp.nestlingEndDays,
                    'juvenileEndDays': sp.juvenileEndDays,
                    'nestlingWeighIntervalDays': sp.nestlingWeighIntervalDays,
                    'juvenileWeighIntervalDays': sp.juvenileWeighIntervalDays,
                    'adultWeighIntervalDays': sp.adultWeighIntervalDays,
                  },
                );
              }
            }
            _disposeControllers([nameCtrl, nestlingEndCtrl, juvenileEndCtrl, nestlingWICtrl, juvenileWICtrl, adultWICtrl]);
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
              final userId = ref.read(workerProvider).userId;
              if (userId != null) {
                await ref.read(syncQueueProvider).enqueue(
                  userId: userId,
                  action: 'delete_species',
                  entityType: 'species',
                  entityUuid: s.uuid,
                  payload: {'id': s.id, 'name': s.name},
                );
              }
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
