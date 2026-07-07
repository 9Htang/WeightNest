import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meal_template_provider.dart';

/// 营养插件设置页 —— 默认餐次模板配置。
class NutritionConfigScreen extends ConsumerStatefulWidget {
  const NutritionConfigScreen({super.key});

  @override
  ConsumerState<NutritionConfigScreen> createState() =>
      _NutritionConfigScreenState();
}

class _NutritionConfigScreenState extends ConsumerState<NutritionConfigScreen> {
  @override
  Widget build(BuildContext context) {
    final template = ref.watch(mealTemplateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('营养设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('默认餐次模板',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(mealTemplateProvider.notifier)
                              .update(MealTemplate.defaults());
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('恢复默认'),
                      ),
                    ],
                  ),
                  Text(
                    '新建喂养方案时一键填充的餐次。可在方案编辑中继续增删改。',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 12),
                  ...template.presets.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final preset = entry.value;
                    return _MealPresetRow(
                      index: idx,
                      preset: preset,
                      canDelete: template.presets.length > 1,
                      onChanged: (newPreset) {
                        final newPresets =
                            List<MealPreset>.from(template.presets);
                        newPresets[idx] = newPreset;
                        ref
                            .read(mealTemplateProvider.notifier)
                            .update(MealTemplate(presets: newPresets));
                      },
                      onDelete: () {
                        final newPresets =
                            List<MealPreset>.from(template.presets);
                        newPresets.removeAt(idx);
                        ref
                            .read(mealTemplateProvider.notifier)
                            .update(MealTemplate(presets: newPresets));
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        final newPresets =
                            List<MealPreset>.from(template.presets);
                        newPresets.add(const MealPreset(name: '新餐次'));
                        ref
                            .read(mealTemplateProvider.notifier)
                            .update(MealTemplate(presets: newPresets));
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加餐次'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 功能说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关于营养插件',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '• 食材库：管理食材及其营养成分（L1 核心 + L2 繁殖营养）\n'
                    '• 配方库：创建%比例混合粮配方，绑定物种与生理阶段\n'
                    '• 喂养方案：per-bird 餐饮管理，每餐由多配方按比例组合\n'
                    '• 营养分析：自动计算蛋白、脂肪、钙磷比等关键指标\n'
                    '• 数据基准：支持 As Fed / Dry Matter 切换',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个餐次预设编辑行
class _MealPresetRow extends StatelessWidget {
  final int index;
  final MealPreset preset;
  final bool canDelete;
  final ValueChanged<MealPreset> onChanged;
  final VoidCallback onDelete;

  const _MealPresetRow({
    required this.index,
    required this.preset,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 序号
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          // 餐次名
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: preset.name,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) => onChanged(MealPreset(
                name: v.trim().isEmpty ? '餐次' : v.trim(),
                timeOfDay: preset.timeOfDay,
              )),
            ),
          ),
          const SizedBox(width: 8),
          // 时间
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: preset.timeOfDay ?? '',
              decoration: const InputDecoration(
                hintText: '时间',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final t = v.trim();
                onChanged(MealPreset(
                  name: preset.name,
                  timeOfDay: t.isEmpty ? null : t,
                ));
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: canDelete ? onDelete : null,
            color: theme.colorScheme.error,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
