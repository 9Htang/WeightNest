import 'package:flutter/material.dart';
import '../../../core/plugin_registry.dart';
import '../../../database/database.dart';
import '../nutrition_repository.dart';

/// 食物选择器对话框 —— 从食材库中搜索并选择一个食物。
class FoodPickerDialog extends StatefulWidget {
  const FoodPickerDialog({super.key});

  @override
  State<FoodPickerDialog> createState() => _FoodPickerDialogState();
}

class _FoodPickerDialogState extends State<FoodPickerDialog> {
  List<Food> _foods = [];
  final _searchCtrl = TextEditingController();
  String _query = '';

  AppDatabase get _db => pluginRegistry.db!;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    final foods = _query.isEmpty
        ? await _db.getAllFoods()
        : await _db.searchFoods(_query);
    if (mounted) setState(() => _foods = foods);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择食物'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '搜索食物',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _query = v.trim();
                _loadFoods();
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _foods.length,
                itemBuilder: (_, i) {
                  final food = _foods[i];
                  return ListTile(
                    title: Text(food.name),
                    subtitle: Text(
                        '${food.category} · 蛋白${food.crudeProtein.toStringAsFixed(1)}%'),
                    onTap: () => Navigator.pop(context, food),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
      ],
    );
  }
}
