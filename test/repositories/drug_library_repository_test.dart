import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/plugins/medication/drug_library_repository.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../../lib/repositories/weight_repository.dart';
import '../test_helpers/test_clock.dart';
import '../test_helpers/test_factories.dart';

/// ── DrugLibraryRepository 测试 ───────────────────────────────────────────
///
/// 验证药品库 CRUD、剂型、剂量规则优先级、剂量计算引擎。

final _fakeNow = DateTime(2025, 6, 15, 12, 0, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    await setTestClock(_fakeNow);
    db = await setUpTestDb();
  });

  tearDown(() async {
    await tearDownTestDb(db);
    await resetTestClock();
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Drug CRUD
  // ═════════════════════════════════════════════════════════════════════════

  group('drug CRUD', () {
    test('addDrug + getDrugById', () async {
      final drug = await db.addDrug(drugName: '泰乐菌素', drugCategory: '抗生素');
      expect(drug.id, greaterThan(0));
      final fetched = await db.getDrugById(drug.id);
      expect(fetched, isNotNull);
      expect(fetched!.drugName, '泰乐菌素');
      expect(fetched.drugCategory, '抗生素');
    });

    test('getAllDrugs 返回全部', () async {
      await db.addDrug(drugName: '锌');
      await db.addDrug(drugName: '阿莫西林');
      final all = await db.getAllDrugs();
      expect(all.length, 2);
      // 排序由 SQLite COLLATE 决定（中文按字节序），不假定具体顺序
      final names = all.map((d) => d.drugName).toSet();
      expect(names, containsAll(['锌', '阿莫西林']));
    });

    test('updateDrug 修改字段', () async {
      final drug = await db.addDrug(drugName: '旧名');
      final updated = await db.updateDrug(drug.id, drugName: '新名', notes: '备注');
      expect(updated.drugName, '新名');
      expect(updated.notes, '备注');
    });

    test('removeDrug 后查询为 null', () async {
      final drug = await db.addDrug(drugName: '待删');
      await db.removeDrug(drug.id);
      expect(await db.getDrugById(drug.id), isNull);
    });

    test('searchDrugs 按名称模糊匹配', () async {
      await db.addDrug(drugName: '泰乐菌素', activeIngredient: 'tylosin');
      await db.addDrug(drugName: '阿莫西林', activeIngredient: 'amoxicillin');
      final results = await db.searchDrugs('泰乐');
      expect(results.length, 1);
      expect(results.first.drugName, '泰乐菌素');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Formulation CRUD
  // ═════════════════════════════════════════════════════════════════════════

  group('formulation CRUD', () {
    test('addFormulation + getFormulationsByDrug', () async {
      final drug = await db.addDrug(drugName: '泰乐菌素');
      await db.addFormulation(
          drugId: drug.id, concentration: 50, isDefault: true);
      await db.addFormulation(drugId: drug.id, concentration: 100);
      final forms = await db.getFormulationsByDrug(drug.id);
      expect(forms.length, 2);
      // 按浓度升序
      expect(forms.first.concentration, 50);
      expect(forms.first.isDefault, isTrue);
    });

    test('removeFormulation 后查询不到', () async {
      final drug = await db.addDrug(drugName: '泰乐菌素');
      final form = await db.addFormulation(drugId: drug.id, concentration: 50);
      await db.removeFormulation(form.id);
      expect((await db.getFormulationsByDrug(drug.id)), isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // findBestDoseRule — 优先级测试
  // ═════════════════════════════════════════════════════════════════════════

  group('findBestDoseRule 优先级', () {
    late int drugId;
    late int diseaseId;
    late int speciesId;
    late int specificRuleId;
    late int generalRuleId;

    setUp(() async {
      drugId = (await db.addDrug(drugName: '泰乐菌素')).id;
      diseaseId = (await db.addDisease(diseaseName: '呼吸道感染')).id;
      final species = await db.createSpecies('虎皮鹦鹉');
      speciesId = species.id;

      // 通用规则（species=null）
      final general = await db.addDoseRule(
        drugId: drugId,
        diseaseId: diseaseId,
        speciesId: null,
        mgKgDose: 10,
        timesPerDay: 2,
        durationDays: 5,
      );
      generalRuleId = general.id;

      // 品种专属规则
      final specific = await db.addDoseRule(
        drugId: drugId,
        diseaseId: diseaseId,
        speciesId: speciesId,
        mgKgDose: 15,
        timesPerDay: 3,
        durationDays: 7,
      );
      specificRuleId = specific.id;
    });

    test('有品种专属规则 → 返回专属（优先级最高）', () async {
      final best = await db.findBestDoseRule(drugId, diseaseId, speciesId);
      expect(best, isNotNull);
      expect(best!.rule.id, specificRuleId);
      expect(best.isSpeciesSpecific, isTrue);
    });

    test('无品种专属规则 → 回退通用规则', () async {
      final otherSpecies = (await db.createSpecies('玄凤鹦鹉')).id;
      final best = await db.findBestDoseRule(drugId, diseaseId, otherSpecies);
      expect(best, isNotNull);
      expect(best!.rule.id, generalRuleId);
      expect(best.isSpeciesSpecific, isFalse);
    });

    test('都无规则 → null', () async {
      final otherDisease = (await db.addDisease(diseaseName: '其他病')).id;
      final best = await db.findBestDoseRule(drugId, otherDisease, speciesId);
      expect(best, isNull);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // calculateDosage / calculateManualDosage
  // ═════════════════════════════════════════════════════════════════════════

  group('calculateManualDosage', () {
    late int birdId;
    late int formulationId;

    setUp(() async {
      final species = await db.createSpecies('虎皮鹦鹉');
      final bird = await db.createBird(
        name: '小蓝',
        speciesId: species.id,
        birthDate: _fakeNow.subtract(const Duration(days: 200)),
      );
      birdId = bird.id;
      await db.addWeight(birdId: birdId, weightG: 50.0, recordedAt: _fakeNow);

      final drug = await db.addDrug(drugName: '泰乐菌素');
      final form = await db.addFormulation(
        drugId: drug.id,
        concentration: 25,
        isDefault: true,
      );
      formulationId = form.id;
    });

    test('完整参数 → 计算体积', () async {
      // 50g × 10mg/kg = 0.5mg；0.5mg ÷ 25mg/mL = 0.02mL
      final result = await db.calculateManualDosage(
        birdId: birdId,
        formulationId: formulationId,
        mgKgDose: 10,
        timesPerDay: 2,
        durationDays: 5,
      );
      expect(result.hasError, isFalse);
      expect(result.volumeMl, closeTo(0.02, 0.0001));
      expect(result.weightG, 50.0);
      expect(result.doseMgKg, 10);
      expect(result.timesPerDay, 2);
      expect(result.durationDays, 5);
    });

    test('无体重记录 → 返回错误', () async {
      final species = await db.createSpecies('玄凤');
      final noWeightBird = await db.createBird(
        name: '无体重',
        speciesId: species.id,
        birthDate: _fakeNow.subtract(const Duration(days: 200)),
      );
      final result = await db.calculateManualDosage(
        birdId: noWeightBird.id,
        formulationId: formulationId,
        mgKgDose: 10,
        timesPerDay: 1,
        durationDays: 3,
      );
      expect(result.hasError, isTrue);
      expect(result.error, contains('体重'));
    });

    test('不存在的剂型 → 返回错误', () async {
      final result = await db.calculateManualDosage(
        birdId: birdId,
        formulationId: 99999,
        mgKgDose: 10,
        timesPerDay: 1,
        durationDays: 3,
      );
      expect(result.hasError, isTrue);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // DoseCalculationResult.volumeDisplay 精度分级
  // ═════════════════════════════════════════════════════════════════════════

  group('DoseCalculationResult.volumeDisplay', () {
    DoseCalculationResult _result(double? vol) =>
        DoseCalculationResult(volumeMl: vol);

    test('null → "-"', () {
      expect(_result(null).volumeDisplay, '-');
    });

    test('< 0.01 → 4 位小数', () {
      expect(_result(0.005).volumeDisplay, '0.0050');
    });

    test('0.01 ≤ vol < 1.0 → 3 位小数', () {
      expect(_result(0.02).volumeDisplay, '0.020');
      expect(_result(0.5).volumeDisplay, '0.500');
    });

    test('≥ 1.0 → 2 位小数', () {
      expect(_result(1.5).volumeDisplay, '1.50');
      expect(_result(10.0).volumeDisplay, '10.00');
    });
  });
}
