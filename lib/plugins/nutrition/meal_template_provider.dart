import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 默认餐次模板 —— SharedPreferences + StateNotifier
//
// 用户可自定义默认餐次模板，食谱编辑时一键填充。
// 复用 grid_color_config.dart 的 SharedPreferences 持久化模式。
// ═══════════════════════════════════════════════════════════════════════════════

/// 餐次预设项
class MealPreset {
  final String name;
  final String? timeOfDay;

  const MealPreset({required this.name, this.timeOfDay});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (timeOfDay != null) 'timeOfDay': timeOfDay,
      };

  factory MealPreset.fromJson(Map<String, dynamic> json) => MealPreset(
        name: json['name'] as String? ?? '',
        timeOfDay: json['timeOfDay'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPreset &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          timeOfDay == other.timeOfDay;

  @override
  int get hashCode => name.hashCode ^ (timeOfDay?.hashCode ?? 0);
}

/// 默认餐次模板
class MealTemplate {
  final List<MealPreset> presets;

  const MealTemplate({this.presets = const []});

  /// 默认模板：早餐 / 午餐 / 晚餐
  factory MealTemplate.defaults() => const MealTemplate(
        presets: [
          MealPreset(name: '早餐', timeOfDay: '07:00'),
          MealPreset(name: '午餐', timeOfDay: '12:00'),
          MealPreset(name: '晚餐', timeOfDay: '18:00'),
        ],
      );

  MealTemplate copyWith({List<MealPreset>? presets}) =>
      MealTemplate(presets: presets ?? this.presets);

  Map<String, dynamic> toJson() => {
        'presets': presets.map((p) => p.toJson()).toList(),
      };

  factory MealTemplate.fromJson(Map<String, dynamic> json) => MealTemplate(
        presets: (json['presets'] as List?)
                ?.map((e) => MealPreset.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static const _key = 'nutrition_meal_template';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  static Future<MealTemplate> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return MealTemplate.defaults();
    try {
      return MealTemplate.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return MealTemplate.defaults();
    }
  }
}

/// 餐次模板 StateNotifier
class MealTemplateNotifier extends StateNotifier<MealTemplate> {
  MealTemplateNotifier() : super(MealTemplate.defaults()) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await MealTemplate.load();
    if (mounted) state = loaded;
  }

  Future<void> update(MealTemplate template) async {
    state = template;
    await template.save();
  }
}

final mealTemplateProvider =
    StateNotifierProvider<MealTemplateNotifier, MealTemplate>(
      (ref) => MealTemplateNotifier(),
    );
