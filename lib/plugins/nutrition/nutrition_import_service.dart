import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'nutrition_export_service.dart' show nutritionExtension;
import 'nutrition_repository.dart';

/// 文件头 magic（4 字节 ASCII）：W N N R
const _nutritionMagicCheck = [0x57, 0x4E, 0x4E, 0x52];

// ═══════════════════════════════════════════════════════════════════════════════
// 营养插件导入服务 —— JSON / CSV
//
// 同名匹配逻辑：
// 1. 导入前扫描所有同名食材/食谱，收集冲突列表
// 2. 弹窗让用户选择：跳过 / 全部覆盖 / 逐项确认
// ═══════════════════════════════════════════════════════════════════════════════

/// 导入结果摘要
class NutritionImportResult {
  final int foodsCreated;
  final int foodsUpdated;
  final int foodsSkipped;
  final int blendsCreated;
  final int blendsUpdated;
  final int blendsSkipped;
  final int plansCreated;
  final int plansUpdated;
  final int plansSkipped;
  final List<String> errors;

  NutritionImportResult({
    this.foodsCreated = 0,
    this.foodsUpdated = 0,
    this.foodsSkipped = 0,
    this.blendsCreated = 0,
    this.blendsUpdated = 0,
    this.blendsSkipped = 0,
    this.plansCreated = 0,
    this.plansUpdated = 0,
    this.plansSkipped = 0,
    this.errors = const [],
  });

  int get totalCreated => foodsCreated + blendsCreated + plansCreated;
  int get totalUpdated => foodsUpdated + blendsUpdated + plansUpdated;
  int get totalSkipped => foodsSkipped + blendsSkipped + plansSkipped;
  bool get hasNoChanges =>
      totalCreated == 0 && totalUpdated == 0 && totalSkipped == 0;
}

/// 同名冲突处理策略
enum ConflictResolution {
  skip, // 跳过同名项
  overwrite, // 覆盖同名项
}

class NutritionImportService {
  AppDatabase get _db => pluginRegistry.db!;

  /// 选择文件并导入。
  /// 返回导入结果；用户取消选文件时返回 null。
  Future<NutritionImportResult?> pickAndImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.first.path!);
    final bytes = await file.readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);

    final ext = result.files.first.extension?.toLowerCase();
    if (ext == 'json') {
      return _importJson(context, content);
    } else if (ext == 'csv') {
      return _importCsv(context, content);
    } else if (ext == nutritionExtension) {
      final jsonStr = _parseWnnutrition(file);
      if (jsonStr == null) {
        return NutritionImportResult(errors: ['文件格式无效或已损坏']);
      }
      return _importJson(context, jsonStr);
    }
    return null;
  }

  /// 校验 .wnnutrition 文件并解出 JSON 字符串。
  /// 校验失败（magic 不匹配、解压失败）返回 null。
  String? _parseWnnutrition(File file) {
    try {
      final bytes = file.readAsBytesSync();
      if (bytes.length < 4) return null;
      // 校验 magic
      if (bytes[0] != _nutritionMagicCheck[0] ||
          bytes[1] != _nutritionMagicCheck[1] ||
          bytes[2] != _nutritionMagicCheck[2] ||
          bytes[3] != _nutritionMagicCheck[3]) {
        return null;
      }
      // 解 ZIP
      final zipBytes = bytes.sublist(4);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) return null;
      return utf8.decode(dataFile.content as List<int>);
    } catch (e) {
      return null;
    }
  }

  /// 从 .wnnutrition 文件导入（含冲突确认弹窗）。
  /// 供 app.dart 的外部文件接收流程调用。
  ///
  /// 返回导入结果；文件无效或用户取消时返回 null。
  Future<NutritionImportResult?> importFromFileWithConfirm(
      File file, BuildContext context) async {
    final jsonStr = _parseWnnutrition(file);
    if (jsonStr == null) {
      return null; // 文件无效，由调用方提示
    }
    // _importJson 内部已包含冲突检测 + 确认弹窗
    return _importJson(context, jsonStr);
  }

  // ── JSON 导入 ──────────────────────────────────────────────────────────────

  Future<NutritionImportResult> _importJson(
      BuildContext context, String content) async {
    int foodsCreated = 0, foodsUpdated = 0, foodsSkipped = 0;
    int blendsCreated = 0, blendsUpdated = 0, blendsSkipped = 0;
    int plansCreated = 0, plansUpdated = 0, plansSkipped = 0;
    final errors = <String>[];

    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 1;
      final foodsJson = (data['foods'] as List?) ?? [];
      final blendsJson = (data['blends'] as List?) ?? [];
      final plansJson = (data['feedingPlans'] as List?) ?? [];

      // 食材冲突检测
      final foodConflicts = <_ConflictItem>[];
      for (final fj in foodsJson.cast<Map<String, dynamic>>()) {
        final name = fj['name'] as String? ?? '';
        if (name.isEmpty) continue;
        final existing = await _db.getFoodByName(name);
        if (existing != null) {
          foodConflicts.add(_ConflictItem(name: name, type: '食材'));
        }
      }

      // 配方冲突检测
      final blendConflicts = <_ConflictItem>[];
      for (final bj in blendsJson.cast<Map<String, dynamic>>()) {
        final name = bj['name'] as String? ?? '';
        if (name.isEmpty) continue;
        final existing = await _db.getBlendByName(name);
        if (existing != null) {
          blendConflicts.add(_ConflictItem(name: name, type: '配方'));
        }
      }

      // 冲突确认弹窗
      final allConflicts = [...foodConflicts, ...blendConflicts];
      ConflictResolution? resolution;
      if (allConflicts.isNotEmpty) {
        resolution = await _showConflictDialog(context, allConflicts);
        if (resolution == null) {
          // 用户取消整个导入
          return NutritionImportResult(
            foodsSkipped: foodsJson.length,
            blendsSkipped: blendsJson.length,
            plansSkipped: plansJson.length,
            errors: ['用户取消导入'],
          );
        }
      }

      // 导入食材
      final foodIdMap = <String, int>{}; // name → id（配方引用用）
      for (final fj in foodsJson.cast<Map<String, dynamic>>()) {
        try {
          final name = fj['name'] as String? ?? '';
          if (name.isEmpty) continue;
          final existing = await _db.getFoodByName(name);

          if (existing != null) {
            if (resolution == ConflictResolution.skip) {
              foodsSkipped++;
              foodIdMap[name] = existing.id;
              continue;
            }
            // 覆盖
            await _updateFoodFromJson(existing.id, fj);
            foodsUpdated++;
            foodIdMap[name] = existing.id;
          } else {
            final food = await _addFoodFromJson(fj);
            foodsCreated++;
            foodIdMap[name] = food.id;
          }
        } catch (e) {
          errors.add('食材 "${fj['name']}": $e');
        }
      }

      // 导入配方
      final blendIdMap = <String, int>{}; // name → id（方案引用用）
      for (final bj in blendsJson.cast<Map<String, dynamic>>()) {
        try {
          final name = bj['name'] as String? ?? '';
          if (name.isEmpty) continue;
          final existing = await _db.getBlendByName(name);

          int blendId;
          if (existing != null) {
            if (resolution == ConflictResolution.skip) {
              blendsSkipped++;
              blendIdMap[name] = existing.id;
              continue;
            }
            await _db.updateBlend(existing.id,
                name: name,
                description: bj['description'] as String?,
                isActive: bj['isActive'] as bool? ?? true);
            // 清空旧食材项再重建
            final oldDetails = await _db.getBlendWithDetails(existing.id);
            if (oldDetails != null) {
              for (final item in oldDetails.items) {
                await _db.deleteBlendItem(item.item.id);
              }
              for (final bd in oldDetails.bindings) {
                await _db.unbindBlend(
                    blendId: existing.id,
                    speciesId: bd.speciesId,
                    stage: bd.stage);
              }
            }
            blendId = existing.id;
            blendsUpdated++;
          } else {
            final blend = await _db.addBlend(
              name: name,
              description: bj['description'] as String?,
              isActive: bj['isActive'] as bool? ?? true,
            );
            blendId = blend.id;
            blendsCreated++;
          }
          blendIdMap[name] = blendId;

          // 导入食材项
          final itemsJson = (bj['items'] as List?) ?? [];
          for (final ij in itemsJson.cast<Map<String, dynamic>>()) {
            final foodName = ij['foodName'] as String? ?? '';
            final percent = (ij['percent'] as num?)?.toDouble() ?? 0;
            final foodId = foodIdMap[foodName];
            if (foodId != null) {
              await _db.addBlendItem(
                  blendId: blendId, foodId: foodId, percent: percent);
            }
          }

          // 导入绑定
          final bindingsJson = (bj['bindings'] as List?) ?? [];
          for (final bdj in bindingsJson.cast<Map<String, dynamic>>()) {
            final stage = bdj['stage'] as String? ?? '成鸟维护期';
            final speciesId = bdj['speciesUuid'] as int?;
            await _db.bindBlend(
                blendId: blendId, speciesId: speciesId, stage: stage);
          }
        } catch (e) {
          errors.add('配方 "${bj['name']}": $e');
        }
      }

      // 导入喂养方案
      for (final pj in plansJson.cast<Map<String, dynamic>>()) {
        try {
          final stage = pj['stage'] as String? ?? '成鸟维护期';
          final birdId = pj['birdId'] as int?;
          final speciesId = pj['speciesId'] as int?;

          final existing = await _db.getFeedingPlanByBirdAndStage(birdId, stage);
          int planId;
          if (existing != null) {
            if (resolution == ConflictResolution.skip) {
              plansSkipped++;
              continue;
            }
            // 清空旧餐次再重建
            final oldDetails = await _db.getFeedingPlanWithDetails(existing.id);
            if (oldDetails != null) {
              for (final m in oldDetails.meals) {
                await _db.deleteFeedingPlanMeal(m.meal.id);
              }
            }
            planId = existing.id;
            plansUpdated++;
          } else {
            final plan = await _db.addFeedingPlan(
              birdId: birdId,
              speciesId: speciesId,
              stage: stage,
              isActive: pj['isActive'] as bool? ?? true,
              notes: pj['notes'] as String?,
            );
            planId = plan.id;
            plansCreated++;
          }

          // 导入餐次
          final mealsJson = (pj['meals'] as List?) ?? [];
          int sortOrder = 0;
          for (final mj in mealsJson.cast<Map<String, dynamic>>()) {
            final meal = await _db.addFeedingPlanMeal(
              planId: planId,
              mealName: mj['mealName'] as String? ?? '餐次',
              timeOfDay: mj['timeOfDay'] as String?,
              grams: (mj['grams'] as num?)?.toDouble() ?? 0,
              sortOrder: mj['sortOrder'] as int? ?? sortOrder++,
            );
            // 导入配方组合
            final recipesJson = (mj['recipes'] as List?) ?? [];
            for (final rj in recipesJson.cast<Map<String, dynamic>>()) {
              final blendName = rj['blendName'] as String? ?? '';
              final percent = (rj['percent'] as num?)?.toDouble() ?? 0;
              final blendId = blendIdMap[blendName];
              if (blendId != null) {
                await _db.addFeedingPlanMealRecipe(
                    planMealId: meal.id, blendId: blendId, percent: percent);
              }
            }
          }
        } catch (e) {
          errors.add('喂养方案: $e');
        }
      }
    } catch (e) {
      errors.add('解析失败: $e');
    }

    return NutritionImportResult(
      foodsCreated: foodsCreated,
      foodsUpdated: foodsUpdated,
      foodsSkipped: foodsSkipped,
      blendsCreated: blendsCreated,
      blendsUpdated: blendsUpdated,
      blendsSkipped: blendsSkipped,
      plansCreated: plansCreated,
      plansUpdated: plansUpdated,
      plansSkipped: plansSkipped,
      errors: errors,
    );
  }

  // ── CSV 导入（仅食材，食谱 CSV 结构复杂不适合导入）──────────────────────────

  Future<NutritionImportResult> _importCsv(
      BuildContext context, String content) async {
    int foodsCreated = 0, foodsUpdated = 0, foodsSkipped = 0;
    final errors = <String>[];

    try {
      final lines = const LineSplitter().convert(content);
      if (lines.length < 2) {
        return NutritionImportResult(errors: ['CSV 文件为空']);
      }

      // 跳过 BOM
      final headerLine = lines[0].replaceFirst('\uFEFF', '');
      // 解析表头找到各列索引
      final headers = _parseCsvLine(headerLine);
      final nameIdx = headers.indexOf('名称');
      if (nameIdx < 0) {
        return NutritionImportResult(errors: ['CSV 格式不正确：缺少"名称"列']);
      }

      // 冲突检测
      final conflicts = <_ConflictItem>[];
      final dataLines = lines.sublist(1).where((l) => l.trim().isNotEmpty);
      for (final line in dataLines) {
        final cells = _parseCsvLine(line);
        final name = nameIdx < cells.length ? cells[nameIdx] : '';
        if (name.isEmpty) continue;
        final existing = await _db.getFoodByName(name);
        if (existing != null) {
          conflicts.add(_ConflictItem(name: name, type: '食材'));
        }
      }

      ConflictResolution? resolution;
      if (conflicts.isNotEmpty) {
        resolution = await _showConflictDialog(context, conflicts);
        if (resolution == null) {
          return NutritionImportResult(
            foodsSkipped: dataLines.length,
            errors: ['用户取消导入'],
          );
        }
      }

      // 导入
      for (final line in dataLines) {
        try {
          final cells = _parseCsvLine(line);
          final name = nameIdx < cells.length ? cells[nameIdx] : '';
          if (name.isEmpty) continue;

          final existing = await _db.getFoodByName(name);
          if (existing != null && resolution == ConflictResolution.skip) {
            foodsSkipped++;
            continue;
          }

          final category = _cellAt(headers, cells, '分类', '其他');
          final isHulled = _cellAt(headers, cells, '是否去壳', '否') == '是';
          final basis = _cellAt(headers, cells, '数据基准', 'As Fed');
          final dataSource = _cellAt(headers, cells, '数据来源', '未知');

          if (existing != null) {
            await _db.updateFood(existing.id,
                name: name,
                category: category,
                isHulled: isHulled,
                basis: basis,
                dataSource: dataSource,
                moisture: _dblAt(headers, cells, '水分', 0),
                crudeProtein: _dblAt(headers, cells, '粗蛋白', 0),
                crudeFat: _dblAt(headers, cells, '粗脂肪', 0),
                crudeFiber: _dblAt(headers, cells, '粗纤维', 0));
            foodsUpdated++;
          } else {
            await _db.addFood(
                name: name,
                category: category,
                isHulled: isHulled,
                basis: basis,
                dataSource: dataSource,
                moisture: _dblAt(headers, cells, '水分', 0),
                crudeProtein: _dblAt(headers, cells, '粗蛋白', 0),
                crudeFat: _dblAt(headers, cells, '粗脂肪', 0),
                crudeFiber: _dblAt(headers, cells, '粗纤维', 0));
            foodsCreated++;
          }
        } catch (e) {
          errors.add('行解析失败: $e');
        }
      }
    } catch (e) {
      errors.add('CSV 解析失败: $e');
    }

    return NutritionImportResult(
      foodsCreated: foodsCreated,
      foodsUpdated: foodsUpdated,
      foodsSkipped: foodsSkipped,
      errors: errors,
    );
  }

  // ── 冲突确认弹窗 ──────────────────────────────────────────────────────────

  Future<ConflictResolution?> _showConflictDialog(
      BuildContext context, List<_ConflictItem> conflicts) {
    return showDialog<ConflictResolution>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('检测到同名数据'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('以下 ${conflicts.length} 项与现有数据同名：',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ...conflicts.take(10).map((c) => Text('· ${c.type}：${c.name}',
                  style: Theme.of(context).textTheme.labelSmall)),
              if (conflicts.length > 10)
                Text('...及其他 ${conflicts.length - 10} 项',
                    style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // 取消
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, ConflictResolution.skip),
            child: const Text('全部跳过'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, ConflictResolution.overwrite),
            child: const Text('全部覆盖'),
          ),
        ],
      ),
    );
  }

  // ── JSON → Food 映射辅助 ──────────────────────────────────────────────────

  Future<Food> _addFoodFromJson(Map<String, dynamic> j) {
    return _db.addFood(
      name: j['name'] as String,
      category: j['category'] as String? ?? '其他',
      isHulled: j['isHulled'] as bool? ?? false,
      basis: j['basis'] as String? ?? 'As Fed',
      dataSource: j['dataSource'] as String? ?? '未知',
      dataConfidence: j['dataConfidence'] as String?,
      moisture: _dbl(j['moisture']),
      crudeProtein: _dbl(j['crudeProtein']),
      crudeFat: _dbl(j['crudeFat']),
      crudeFiber: _dbl(j['crudeFiber']),
      crudeAsh: _dblOrNull(j['crudeAsh']),
      metabolizableEnergy: _dblOrNull(j['metabolizableEnergy']),
      calcium: _dblOrNull(j['calcium']),
      phosphorus: _dblOrNull(j['phosphorus']),
      magnesium: _dblOrNull(j['magnesium']),
      potassium: _dblOrNull(j['potassium']),
      sodium: _dblOrNull(j['sodium']),
      omega3: _dblOrNull(j['omega3']),
      omega6: _dblOrNull(j['omega6']),
      linoleicAcid: _dblOrNull(j['linoleicAcid']),
      ala: _dblOrNull(j['ala']),
      lysine: _dblOrNull(j['lysine']),
      methionine: _dblOrNull(j['methionine']),
      cystine: _dblOrNull(j['cystine']),
      threonine: _dblOrNull(j['threonine']),
      tryptophan: _dblOrNull(j['tryptophan']),
      arginine: _dblOrNull(j['arginine']),
      valine: _dblOrNull(j['valine']),
      isoleucine: _dblOrNull(j['isoleucine']),
      leucine: _dblOrNull(j['leucine']),
      zinc: _dblOrNull(j['zinc']),
      copper: _dblOrNull(j['copper']),
      iron: _dblOrNull(j['iron']),
      manganese: _dblOrNull(j['manganese']),
      selenium: _dblOrNull(j['selenium']),
      iodine: _dblOrNull(j['iodine']),
      vitA: _dblOrNull(j['vitA']),
      vitD3: _dblOrNull(j['vitD3']),
      vitE: _dblOrNull(j['vitE']),
      vitK: _dblOrNull(j['vitK']),
      vitB1: _dblOrNull(j['vitB1']),
      vitB2: _dblOrNull(j['vitB2']),
      vitB6: _dblOrNull(j['vitB6']),
      vitB12: _dblOrNull(j['vitB12']),
      niacin: _dblOrNull(j['niacin']),
      pantothenicAcid: _dblOrNull(j['pantothenicAcid']),
      biotin: _dblOrNull(j['biotin']),
      folicAcid: _dblOrNull(j['folicAcid']),
      maxRatioPercent: _dbl(j['maxRatioPercent'], 100),
      minRatioPercent: _dblOrNull(j['minRatioPercent']),
      notes: j['notes'] as String?,
    );
  }

  Future<void> _updateFoodFromJson(int id, Map<String, dynamic> j) {
    return _db.updateFood(
      id,
      name: j['name'] as String,
      category: j['category'] as String?,
      isHulled: j['isHulled'] as bool?,
      basis: j['basis'] as String?,
      dataSource: j['dataSource'] as String?,
      dataConfidence: j['dataConfidence'] as String?,
      moisture: _dbl(j['moisture']),
      crudeProtein: _dbl(j['crudeProtein']),
      crudeFat: _dbl(j['crudeFat']),
      crudeFiber: _dbl(j['crudeFiber']),
      crudeAsh: _dblOrNull(j['crudeAsh']),
      metabolizableEnergy: _dblOrNull(j['metabolizableEnergy']),
      calcium: _dblOrNull(j['calcium']),
      phosphorus: _dblOrNull(j['phosphorus']),
      notes: j['notes'] as String?,
    );
  }

  // ── CSV 解析辅助 ──────────────────────────────────────────────────────────

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  String _cellAt(List<String> headers, List<String> cells, String header,
      String def) {
    final idx = headers.indexOf(header);
    if (idx < 0 || idx >= cells.length) return def;
    final v = cells[idx].trim();
    return v.isEmpty ? def : v;
  }

  double _dblAt(List<String> headers, List<String> cells, String header,
      double def) {
    final idx = headers.indexOf(header);
    if (idx < 0 || idx >= cells.length) return def;
    return double.tryParse(cells[idx].trim()) ?? def;
  }

  // ── 类型转换辅助 ──────────────────────────────────────────────────────────

  double _dbl(dynamic v, [double def = 0]) =>
      v == null ? def : (v is num ? v.toDouble() : (double.tryParse('$v') ?? def));

  double? _dblOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}

class _ConflictItem {
  final String name;
  final String type;
  const _ConflictItem({required this.name, required this.type});
}
