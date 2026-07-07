import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import 'nutrition_math.dart';
import 'nutrition_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 营养插件导出服务
//
// 三种导出方式：
// 1. .wnnutrition —— 专用格式（WNNR magic + ZIP 内含 data.json）
//    用于微信/QQ 分享 + 点击文件自动用本应用打开导入
// 2. JSON —— 纯 JSON 文件，便于程序处理
// 3. CSV —— foods.csv + blends.csv，便于 Excel 查看
//
// JSON 结构 version 2：foods + blends + feedingPlans
// ═══════════════════════════════════════════════════════════════════════════════

/// 营养导出文件扩展名
const nutritionExtension = 'wnnutrition';

/// 文件头 magic（4 字节 ASCII）：W N N R
const _nutritionMagic = [0x57, 0x4E, 0x4E, 0x52];

class NutritionExportService {
  AppDatabase get _db => pluginRegistry.db!;

  /// 导出为 .wnnutrition 专用格式并分享（推荐，支持一键打开导入）。
  ///
  /// 格式：[4 字节 WNNR magic] + [ZIP(data.json)]
  Future<void> exportWnnutrition() async {
    final data = await _collectAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    // 构建 ZIP（内存操作，营养数据无大文件）
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
    final zipBytes = ZipEncoder().encode(archive)!;

    // 组装：magic + ZIP
    final output = BytesBuilder()
      ..add(_nutritionMagic)
      ..add(zipBytes);

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/nutrition_export_${_timestamp()}.$nutritionExtension');
    await file.writeAsBytes(output.toBytes());

    await Share.shareXFiles([XFile(file.path)],
        text: '鹦鹉营养数据导出');
  }

  /// 导出为 JSON 文件并分享。
  Future<void> exportJson() async {
    final data = await _collectAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/nutrition_export_${_timestamp()}.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles([XFile(file.path)],
        text: '鹦鹉营养数据导出');
  }

  /// 导出为 CSV 文件并分享（foods.csv + blends.csv）。
  Future<void> exportCsv() async {
    final dir = await getTemporaryDirectory();
    final foodsCsv = await _buildFoodsCsv();
    final blendsCsv = await _buildBlendsCsv();

    final foodsFile = File('${dir.path}/foods_${_timestamp()}.csv');
    await foodsFile.writeAsString('\uFEFF$foodsCsv'); // BOM for Excel UTF-8

    final blendsFile = File('${dir.path}/blends_${_timestamp()}.csv');
    await blendsFile.writeAsString('\uFEFF$blendsCsv');

    await Share.shareXFiles(
      [XFile(foodsFile.path), XFile(blendsFile.path)],
      text: '鹦鹉营养数据导出',
    );
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// 收集全部数据为 JSON Map 结构（version 2 格式）
  Future<Map<String, dynamic>> _collectAllData() async {
    final foods = await _db.getAllFoods();
    final blends = await _db.getAllBlends();
    final plans = await _db.getAllFeedingPlans();

    final foodsJson = <Map<String, dynamic>>[];
    for (final f in foods) {
      foodsJson.add(_foodToJson(f));
    }

    final blendsJson = <Map<String, dynamic>>[];
    for (final b in blends) {
      final details = await _db.getBlendWithDetails(b.id);
      if (details == null) continue;
      blendsJson.add(_blendWithDetailsToJson(details));
    }

    final plansJson = <Map<String, dynamic>>[];
    for (final p in plans) {
      final details = await _db.getFeedingPlanWithDetails(p.id);
      if (details == null) continue;
      plansJson.add(_feedingPlanWithDetailsToJson(details));
    }

    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'foods': foodsJson,
      'blends': blendsJson,
      'feedingPlans': plansJson,
    };
  }

  Map<String, dynamic> _foodToJson(Food f) => {
        'uuid': f.uuid,
        'name': f.name,
        'category': f.category,
        'isHulled': f.isHulled,
        'basis': f.basis,
        'dataSource': f.dataSource,
        'dataConfidence': f.dataConfidence,
        // L1
        'moisture': f.moisture,
        'crudeProtein': f.crudeProtein,
        'crudeFat': f.crudeFat,
        'crudeFiber': f.crudeFiber,
        'crudeAsh': f.crudeAsh,
        'metabolizableEnergy': f.metabolizableEnergy,
        // L2 矿物质
        'calcium': f.calcium,
        'phosphorus': f.phosphorus,
        'magnesium': f.magnesium,
        'potassium': f.potassium,
        'sodium': f.sodium,
        // L2 脂肪酸
        'omega3': f.omega3,
        'omega6': f.omega6,
        'linoleicAcid': f.linoleicAcid,
        'ala': f.ala,
        // L2 氨基酸
        'lysine': f.lysine,
        'methionine': f.methionine,
        'cystine': f.cystine,
        'threonine': f.threonine,
        'tryptophan': f.tryptophan,
        'arginine': f.arginine,
        'valine': f.valine,
        'isoleucine': f.isoleucine,
        'leucine': f.leucine,
        // L2 微量元素
        'zinc': f.zinc,
        'copper': f.copper,
        'iron': f.iron,
        'manganese': f.manganese,
        'selenium': f.selenium,
        'iodine': f.iodine,
        // L2 维生素
        'vitA': f.vitA,
        'vitD3': f.vitD3,
        'vitE': f.vitE,
        'vitK': f.vitK,
        'vitB1': f.vitB1,
        'vitB2': f.vitB2,
        'vitB6': f.vitB6,
        'vitB12': f.vitB12,
        'niacin': f.niacin,
        'pantothenicAcid': f.pantothenicAcid,
        'biotin': f.biotin,
        'folicAcid': f.folicAcid,
        // 业务规则
        'recommendedStages': f.recommendedStages,
        'maxRatioPercent': f.maxRatioPercent,
        'minRatioPercent': f.minRatioPercent,
        'needsSoaking': f.needsSoaking,
        'canSprout': f.canSprout,
        'notes': f.notes,
      };

  Map<String, dynamic> _blendWithDetailsToJson(BlendWithDetails b) => {
        'uuid': b.blend.uuid,
        'name': b.blend.name,
        'description': b.blend.description,
        'isActive': b.blend.isActive,
        'bindings': b.bindings
            .map((bd) => {
                  'stage': bd.stage,
                  'speciesUuid': bd.speciesId,
                })
            .toList(),
        'items': b.items
            .map((i) => {
                  'foodName': i.food.name,
                  'percent': i.item.percent,
                })
            .toList(),
      };

  Map<String, dynamic> _feedingPlanWithDetailsToJson(FeedingPlanWithDetails p) {
    // 解析鸟/物种引用为 uuid（用于跨设备导入）
    return {
      'uuid': p.plan.uuid,
      'birdId': p.plan.birdId,
      'speciesId': p.plan.speciesId,
      'stage': p.plan.stage,
      'isActive': p.plan.isActive,
      'notes': p.plan.notes,
      'meals': p.meals
          .map((m) => {
                'mealName': m.meal.mealName,
                'timeOfDay': m.meal.timeOfDay,
                'grams': m.meal.grams,
                'sortOrder': m.meal.sortOrder,
                'recipes': m.recipes
                    .map((r) => {
                          'blendName': r.blend.name,
                          'percent': r.item.percent,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  // ── CSV 构建 ──────────────────────────────────────────────────────────────

  Future<String> _buildFoodsCsv() async {
    final foods = await _db.getAllFoods();
    final headers = [
      '名称', '分类', '是否去壳', '数据基准', '数据来源', '数据质量',
      '水分', '粗蛋白', '粗脂肪', '粗纤维', '粗灰分', '代谢能',
      '钙', '磷', '镁', '钾', '钠',
      'Omega3', 'Omega6', '亚油酸', 'ALA',
      '赖氨酸', '蛋氨酸', '胱氨酸', '苏氨酸', '色氨酸', '精氨酸', '缬氨酸', '异亮氨酸', '亮氨酸',
      '锌', '铜', '铁', '锰', '硒', '碘',
      'VA', 'VD3', 'VE', 'VK', 'B1', 'B2', 'B6', 'B12', '烟酸', '泛酸', '生物素', '叶酸',
      '最大比例', '最小比例', '备注',
    ];
    final sb = StringBuffer();
    sb.writeln(headers.map(_csvEscape).join(','));
    for (final f in foods) {
      sb.writeln([
        f.name, f.category, f.isHulled ? '是' : '否', f.basis, f.dataSource,
        f.dataConfidence ?? '',
        f.moisture, f.crudeProtein, f.crudeFat, f.crudeFiber,
        f.crudeAsh ?? '', f.metabolizableEnergy ?? '',
        f.calcium ?? '', f.phosphorus ?? '', f.magnesium ?? '',
        f.potassium ?? '', f.sodium ?? '',
        f.omega3 ?? '', f.omega6 ?? '', f.linoleicAcid ?? '', f.ala ?? '',
        f.lysine ?? '', f.methionine ?? '', f.cystine ?? '',
        f.threonine ?? '', f.tryptophan ?? '', f.arginine ?? '',
        f.valine ?? '', f.isoleucine ?? '', f.leucine ?? '',
        f.zinc ?? '', f.copper ?? '', f.iron ?? '',
        f.manganese ?? '', f.selenium ?? '', f.iodine ?? '',
        f.vitA ?? '', f.vitD3 ?? '', f.vitE ?? '', f.vitK ?? '',
        f.vitB1 ?? '', f.vitB2 ?? '', f.vitB6 ?? '', f.vitB12 ?? '',
        f.niacin ?? '', f.pantothenicAcid ?? '', f.biotin ?? '', f.folicAcid ?? '',
        f.maxRatioPercent, f.minRatioPercent ?? '',
        f.notes ?? '',
      ].map(_csvEscape).join(','));
    }
    return sb.toString();
  }

  Future<String> _buildBlendsCsv() async {
    final blends = await _db.getAllBlends();
    final headers = ['配方名称', '描述', '启用', '绑定物种/阶段', '食材', '占比%'];
    final sb = StringBuffer();
    sb.writeln(headers.map(_csvEscape).join(','));

    for (final b in blends) {
      final details = await _db.getBlendWithDetails(b.id);
      if (details == null) continue;

      final bindingStr = details.bindings
          .map((bd) => '物种${bd.speciesId ?? "通用"}/${bd.stage}')
          .join('; ');

      if (details.items.isEmpty) {
        sb.writeln([
          b.name, b.description ?? '', b.isActive ? '是' : '否',
          bindingStr, '', '',
        ].map(_csvEscape).join(','));
        continue;
      }

      for (final item in details.items) {
        sb.writeln([
          b.name, b.description ?? '', b.isActive ? '是' : '否',
          bindingStr, item.food.name, item.item.percent,
        ].map(_csvEscape).join(','));
      }
    }
    return sb.toString();
  }

  /// CSV 字段转义：含逗号/引号/换行的字段用双引号包裹，内部引号双写
  String _csvEscape(dynamic value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
