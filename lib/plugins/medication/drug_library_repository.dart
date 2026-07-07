import 'package:drift/drift.dart';
import '../../core/app_clock.dart';
import '../../database/database.dart';
import '../../repositories/bird_repository.dart';
import '../../repositories/weight_repository.dart';
import 'dose_math.dart';
import '../../utils/uuid.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Drug Library, Disease Catalog, Dose Rules, Feeding Records, Side Effects, Stop Conditions
// ═══════════════════════════════════════════════════════════════════════════════

extension DrugLibraryRepository on AppDatabase {
  // ────────────────────────────────────────────────────────────────────────────
  // Drug Library CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<DrugLibraryData> addDrug({
    required String drugName,
    String? brandName,
    String? activeIngredient,
    String drugCategory = '其他',
    String formulationType = '滴剂',
    String? storageInstructions,
    int? openedExpiryDays,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    return into(drugLibrary).insertReturning(
      DrugLibraryCompanion.insert(
        uuid: genUuid(),
        drugName: drugName,
        brandName: Value(brandName),
        activeIngredient: Value(activeIngredient),
        drugCategory: Value(drugCategory),
        formulationType: Value(formulationType),
        storageInstructions: Value(storageInstructions),
        openedExpiryDays: Value(openedExpiryDays),
        notes: Value(notes),
        createdAt: Value(createdAt ?? AppClock.now),
        updatedAt: Value(updatedAt ?? AppClock.now),
      ),
    );
  }

  Future<DrugLibraryData> updateDrug(
    int id, {
    String? drugName,
    String? brandName,
    String? activeIngredient,
    String? drugCategory,
    String? formulationType,
    String? storageInstructions,
    int? openedExpiryDays,
    String? notes,
  }) async {
    final list = await (update(drugLibrary)..where((t) => t.id.equals(id)))
        .writeReturning(DrugLibraryCompanion(
      drugName: drugName != null ? Value(drugName) : const Value.absent(),
      brandName: brandName != null ? Value(brandName) : const Value.absent(),
      activeIngredient: activeIngredient != null
          ? Value(activeIngredient)
          : const Value.absent(),
      drugCategory:
          drugCategory != null ? Value(drugCategory) : const Value.absent(),
      formulationType: formulationType != null
          ? Value(formulationType)
          : const Value.absent(),
      storageInstructions: storageInstructions != null
          ? Value(storageInstructions)
          : const Value.absent(),
      openedExpiryDays: openedExpiryDays != null
          ? Value(openedExpiryDays)
          : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  Future<List<DrugLibraryData>> getAllDrugs() =>
      (select(drugLibrary)..orderBy([(t) => OrderingTerm.asc(t.drugName)]))
          .get();

  Future<List<DrugLibraryData>> searchDrugs(String query) {
    final q = '%$query%';
    return (select(drugLibrary)
          ..where((t) =>
              t.drugName.like(q) |
              t.activeIngredient.like(q) |
              t.brandName.like(q))
          ..orderBy([(t) => OrderingTerm.asc(t.drugName)]))
        .get();
  }

  Future<DrugLibraryData?> getDrugById(int id) =>
      (select(drugLibrary)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> removeDrug(int id) async {
    // Cascade deletes formulations and dose rules via FK
    await (delete(drugLibrary)..where((t) => t.id.equals(id))).go();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Drug Formulations CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<DrugFormulation> addFormulation({
    required int drugId,
    required double concentration,
    String unit = 'mg/mL',
    bool isDefault = false,
    String? label,
  }) async {
    return into(drugFormulations).insertReturning(
      DrugFormulationsCompanion.insert(
        drugId: drugId,
        concentration: concentration,
        unit: Value(unit),
        isDefault: Value(isDefault),
        label: Value(label),
        createdAt: Value(AppClock.now),
      ),
    );
  }

  Future<List<DrugFormulation>> getFormulationsByDrug(int drugId) =>
      (select(drugFormulations)
            ..where((t) => t.drugId.equals(drugId))
            ..orderBy([(t) => OrderingTerm.asc(t.concentration)]))
          .get();

  Future<void> updateFormulation(
    int id, {
    double? concentration,
    String? unit,
    bool? isDefault,
    String? label,
  }) async {
    await (update(drugFormulations)..where((t) => t.id.equals(id)))
        .write(DrugFormulationsCompanion(
      concentration:
          concentration != null ? Value(concentration) : const Value.absent(),
      unit: unit != null ? Value(unit) : const Value.absent(),
      isDefault: isDefault != null ? Value(isDefault) : const Value.absent(),
      label: label != null ? Value(label) : const Value.absent(),
    ));
  }

  Future<void> removeFormulation(int id) async {
    await (delete(drugFormulations)..where((t) => t.id.equals(id))).go();
  }

  /// Batch-replace formulations for a drug.
  Future<void> replaceFormulations(
      int drugId, List<FormulationInput> inputs) async {
    await transaction(() async {
      await (delete(drugFormulations)..where((t) => t.drugId.equals(drugId)))
          .go();
      for (final f in inputs) {
        await addFormulation(
          drugId: drugId,
          concentration: f.concentration,
          unit: f.unit,
          isDefault: f.isDefault,
          label: f.label,
        );
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Disease Catalog CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<DiseaseCatalogData> addDisease({
    required String diseaseName,
    String? description,
  }) async {
    return into(diseaseCatalog).insertReturning(
      DiseaseCatalogCompanion.insert(
        uuid: genUuid(),
        diseaseName: diseaseName,
        description: Value(description),
        createdAt: Value(AppClock.now),
        updatedAt: Value(AppClock.now),
      ),
    );
  }

  Future<DiseaseCatalogData> updateDisease(
    int id, {
    String? diseaseName,
    String? description,
  }) async {
    final list = await (update(diseaseCatalog)..where((t) => t.id.equals(id)))
        .writeReturning(DiseaseCatalogCompanion(
      diseaseName:
          diseaseName != null ? Value(diseaseName) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  Future<List<DiseaseCatalogData>> getAllDiseases() => (select(diseaseCatalog)
        ..orderBy([(t) => OrderingTerm.asc(t.diseaseName)]))
      .get();

  Future<List<DiseaseCatalogData>> searchDiseases(String query) {
    final q = '%$query%';
    return (select(diseaseCatalog)
          ..where((t) => t.diseaseName.like(q))
          ..orderBy([(t) => OrderingTerm.asc(t.diseaseName)]))
        .get();
  }

  Future<DiseaseCatalogData?> getDiseaseById(int id) =>
      (select(diseaseCatalog)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> removeDisease(int id) async {
    await (delete(diseaseCatalog)..where((t) => t.id.equals(id))).go();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Dose Rules CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<DoseRule> addDoseRule({
    required int drugId,
    required int diseaseId,
    int? speciesId,
    required double mgKgDose,
    required int timesPerDay,
    required int durationDays,
    String administrationRoute = '口服',
    String? notes,
  }) async {
    return into(doseRules).insertReturning(
      DoseRulesCompanion.insert(
        drugId: drugId,
        diseaseId: diseaseId,
        speciesId: Value(speciesId),
        mgKgDose: mgKgDose,
        timesPerDay: timesPerDay,
        durationDays: durationDays,
        administrationRoute: Value(administrationRoute),
        notes: Value(notes),
        createdAt: Value(AppClock.now),
        updatedAt: Value(AppClock.now),
      ),
    );
  }

  Future<DoseRule> updateDoseRule(
    int id, {
    double? mgKgDose,
    int? timesPerDay,
    int? durationDays,
    String? administrationRoute,
    String? notes,
  }) async {
    final list = await (update(doseRules)..where((t) => t.id.equals(id)))
        .writeReturning(DoseRulesCompanion(
      mgKgDose: mgKgDose != null ? Value(mgKgDose) : const Value.absent(),
      timesPerDay:
          timesPerDay != null ? Value(timesPerDay) : const Value.absent(),
      durationDays:
          durationDays != null ? Value(durationDays) : const Value.absent(),
      administrationRoute: administrationRoute != null
          ? Value(administrationRoute)
          : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(AppClock.now),
    ));
    return list.first;
  }

  /// Get all dose rules for a drug, joined with disease and species names.
  Future<List<DoseRuleWithNames>> getRulesByDrug(int drugId) async {
    final query = select(doseRules).join([
      innerJoin(
          diseaseCatalog, diseaseCatalog.id.equalsExp(doseRules.diseaseId)),
      leftOuterJoin(species, species.id.equalsExp(doseRules.speciesId)),
    ])
      ..where(doseRules.drugId.equals(drugId))
      ..orderBy([OrderingTerm.asc(diseaseCatalog.diseaseName)]);
    final rows = await query.get();
    return rows.map((r) {
      final rule = r.readTable(doseRules);
      final disease = r.readTable(diseaseCatalog);
      final sp = r.readTableOrNull(species);
      return DoseRuleWithNames(
        rule: rule,
        diseaseName: disease.diseaseName,
        speciesName: sp?.name,
      );
    }).toList();
  }

  /// Get all dose rules across all drugs (for export).
  Future<List<DoseRuleWithNames>> getAllDoseRules() async {
    final query = select(doseRules).join([
      innerJoin(drugLibrary, drugLibrary.id.equalsExp(doseRules.drugId)),
      innerJoin(
          diseaseCatalog, diseaseCatalog.id.equalsExp(doseRules.diseaseId)),
      leftOuterJoin(species, species.id.equalsExp(doseRules.speciesId)),
    ])
      ..orderBy([OrderingTerm.asc(drugLibrary.drugName)]);
    final rows = await query.get();
    return rows.map((r) {
      final rule = r.readTable(doseRules);
      final drug = r.readTable(drugLibrary);
      final disease = r.readTable(diseaseCatalog);
      final sp = r.readTableOrNull(species);
      return DoseRuleWithNames(
        rule: rule,
        drugName: drug.drugName,
        diseaseName: disease.diseaseName,
        speciesName: sp?.name,
      );
    }).toList();
  }

  /// Find the best dose rule for a drug-disease-species combination.
  /// Priority: species-specific > general (species=null) > null.
  Future<DoseRuleWithNames?> findBestDoseRule(
      int drugId, int diseaseId, int speciesId) async {
    // Try species-specific first
    var query = select(doseRules).join([
      innerJoin(
          diseaseCatalog, diseaseCatalog.id.equalsExp(doseRules.diseaseId)),
      leftOuterJoin(species, species.id.equalsExp(doseRules.speciesId)),
    ])
      ..where(doseRules.drugId.equals(drugId) &
          doseRules.diseaseId.equals(diseaseId) &
          doseRules.speciesId.equals(speciesId))
      ..limit(1);
    var rows = await query.get();
    if (rows.isNotEmpty) {
      final r = rows.first;
      return DoseRuleWithNames(
        rule: r.readTable(doseRules),
        diseaseName: r.readTable(diseaseCatalog).diseaseName,
        speciesName: r.readTableOrNull(species)?.name,
      );
    }

    // Fall back to general rule (species = null)
    query = select(doseRules).join([
      innerJoin(
          diseaseCatalog, diseaseCatalog.id.equalsExp(doseRules.diseaseId)),
      leftOuterJoin(species, species.id.equalsExp(doseRules.speciesId)),
    ])
      ..where(doseRules.drugId.equals(drugId) &
          doseRules.diseaseId.equals(diseaseId) &
          doseRules.speciesId.isNull())
      ..limit(1);
    rows = await query.get();
    if (rows.isNotEmpty) {
      final r = rows.first;
      return DoseRuleWithNames(
        rule: r.readTable(doseRules),
        diseaseName: r.readTable(diseaseCatalog).diseaseName,
        speciesName: null,
        sourceLabel: '通用',
      );
    }

    return null;
  }

  /// Get all dose rules for a drug-disease pair (both specific and general).
  Future<List<DoseRuleWithNames>> getRulesByDrugAndDisease(
      int drugId, int diseaseId) async {
    final query = select(doseRules).join([
      innerJoin(
          diseaseCatalog, diseaseCatalog.id.equalsExp(doseRules.diseaseId)),
      leftOuterJoin(species, species.id.equalsExp(doseRules.speciesId)),
    ])
      ..where(doseRules.drugId.equals(drugId) &
          doseRules.diseaseId.equals(diseaseId));
    final rows = await query.get();
    return rows.map((r) {
      final rule = r.readTable(doseRules);
      final disease = r.readTable(diseaseCatalog);
      final sp = r.readTableOrNull(species);
      return DoseRuleWithNames(
        rule: rule,
        diseaseName: disease.diseaseName,
        speciesName: sp?.name,
      );
    }).toList();
  }

  Future<void> removeDoseRule(int id) async {
    await (delete(doseRules)..where((t) => t.id.equals(id))).go();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Dose Calculation Engine
  // ────────────────────────────────────────────────────────────────────────────

  Future<DoseCalculationResult> calculateDosage({
    required int birdId,
    required int formulationId,
    required int doseRuleId,
  }) async {
    // Get bird latest weight
    final weight = await getLatestByBird(birdId);
    if (weight == null) {
      return DoseCalculationResult(error: '没有找到体重记录，请先称重');
    }

    // Get formulation
    final formulation = await (select(drugFormulations)
          ..where((t) => t.id.equals(formulationId)))
        .getSingleOrNull();
    if (formulation == null) {
      return DoseCalculationResult(error: '药品规格不存在');
    }

    // Get dose rule with disease name
    final ruleQuery = select(doseRules).join([
      innerJoin(
          diseaseCatalog, diseaseCatalog.id.equalsExp(doseRules.diseaseId)),
    ])
      ..where(doseRules.id.equals(doseRuleId))
      ..limit(1);
    final ruleRows = await ruleQuery.get();
    if (ruleRows.isEmpty) {
      return DoseCalculationResult(error: '剂量规则不存在');
    }
    final rule = ruleRows.first.readTable(doseRules);
    final disease = ruleRows.first.readTable(diseaseCatalog);

    // Get bird with species for weight range validation
    final bird = await getWithDetails(birdId);

    final mgDose = mgPerKgToDose(weight.weightG, rule.mgKgDose);
    final volumeMl = doseToVolume(mgDose, formulation.concentration);

    // Weight range validation
    bool isWeightOutOfRange = false;
    double? speciesMinWeight;
    double? speciesMaxWeight;

    if (bird != null &&
        bird.species.minWeightG != null &&
        bird.species.maxWeightG != null) {
      speciesMinWeight = bird.species.minWeightG;
      speciesMaxWeight = bird.species.maxWeightG;
      isWeightOutOfRange = weight.weightG < speciesMinWeight! ||
          weight.weightG > speciesMaxWeight!;
    }

    return DoseCalculationResult(
      volumeMl: volumeMl,
      weightG: weight.weightG,
      concentration: formulation.concentration,
      concentrationUnit: formulation.unit,
      doseMgKg: rule.mgKgDose,
      timesPerDay: rule.timesPerDay,
      durationDays: rule.durationDays,
      administrationRoute: rule.administrationRoute,
      diseaseName: disease.diseaseName,
      isWeightOutOfRange: isWeightOutOfRange,
      speciesMinWeight: speciesMinWeight,
      speciesMaxWeight: speciesMaxWeight,
    );
  }

  /// Compute dose without a pre-existing dose rule — user enters mg/kg manually.
  Future<DoseCalculationResult> calculateManualDosage({
    required int birdId,
    required int formulationId,
    required double mgKgDose,
    required int timesPerDay,
    required int durationDays,
    String administrationRoute = '口服',
  }) async {
    final weight = await getLatestByBird(birdId);
    if (weight == null) {
      return DoseCalculationResult(error: '没有找到体重记录，请先称重');
    }

    final formulation = await (select(drugFormulations)
          ..where((t) => t.id.equals(formulationId)))
        .getSingleOrNull();
    if (formulation == null) {
      return DoseCalculationResult(error: '药品规格不存在');
    }

    final mgDose = mgPerKgToDose(weight.weightG, mgKgDose);
    final volumeMl = doseToVolume(mgDose, formulation.concentration);

    return DoseCalculationResult(
      volumeMl: volumeMl,
      weightG: weight.weightG,
      concentration: formulation.concentration,
      concentrationUnit: formulation.unit,
      doseMgKg: mgKgDose,
      timesPerDay: timesPerDay,
      durationDays: durationDays,
      administrationRoute: administrationRoute,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Feeding Records CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<FeedingRecord> addFeedingRecord({
    required int medicationId,
    required int birdId,
    int? taskId,
    required String feedingStatus,
    DateTime? fedAt,
    int? fedBy,
    String? notes,
  }) async {
    return into(feedingRecords).insertReturning(
      FeedingRecordsCompanion.insert(
        medicationId: medicationId,
        birdId: birdId,
        taskId: Value(taskId),
        feedingStatus: feedingStatus,
        fedAt: fedAt ?? AppClock.now,
        fedBy: Value(fedBy),
        notes: Value(notes),
        createdAt: Value(AppClock.now),
      ),
    );
  }

  Future<List<FeedingRecord>> getFeedingRecordsByMedication(int medicationId) =>
      (select(feedingRecords)
            ..where((t) => t.medicationId.equals(medicationId))
            ..orderBy([(t) => OrderingTerm.desc(t.fedAt)]))
          .get();

  Future<List<FeedingRecord>> getFeedingRecordsByBird(int birdId) =>
      (select(feedingRecords)
            ..where((t) => t.birdId.equals(birdId))
            ..orderBy([(t) => OrderingTerm.desc(t.fedAt)]))
          .get();

  // ────────────────────────────────────────────────────────────────────────────
  // Side Effect Records CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<SideEffectRecord> addSideEffect({
    required int medicationId,
    required int birdId,
    required String sideEffectCategory,
    String? description,
    String severity = '轻度',
    DateTime? observedAt,
  }) async {
    return into(sideEffectRecords).insertReturning(
      SideEffectRecordsCompanion.insert(
        medicationId: medicationId,
        birdId: birdId,
        sideEffectCategory: sideEffectCategory,
        description: Value(description),
        severity: Value(severity),
        observedAt: observedAt ?? AppClock.now,
        resolvedAt: const Value.absent(),
        createdAt: Value(AppClock.now),
      ),
    );
  }

  Future<List<SideEffectRecord>> getSideEffectsByMedication(int medicationId) =>
      (select(sideEffectRecords)
            ..where((t) => t.medicationId.equals(medicationId))
            ..orderBy([(t) => OrderingTerm.desc(t.observedAt)]))
          .get();

  Future<List<SideEffectRecord>> getSideEffectsByBird(int birdId) =>
      (select(sideEffectRecords)
            ..where((t) => t.birdId.equals(birdId))
            ..orderBy([(t) => OrderingTerm.desc(t.observedAt)]))
          .get();

  Future<void> resolveSideEffect(int id, {DateTime? resolvedAt}) async {
    await (update(sideEffectRecords)..where((t) => t.id.equals(id)))
        .write(SideEffectRecordsCompanion(
      resolvedAt: Value(resolvedAt ?? AppClock.now),
    ));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Stop Conditions CRUD
  // ────────────────────────────────────────────────────────────────────────────

  Future<StopCondition> setStopCondition({
    required int medicationId,
    required String reason,
    required DateTime actualStopDate,
    String? notes,
  }) async {
    return into(stopConditions).insertReturning(
      StopConditionsCompanion.insert(
        medicationId: medicationId,
        reason: reason,
        actualStopDate: actualStopDate,
        notes: Value(notes),
        createdAt: Value(AppClock.now),
      ),
    );
  }

  Future<StopCondition?> getStopCondition(int medicationId) =>
      (select(stopConditions)
            ..where((t) => t.medicationId.equals(medicationId)))
          .getSingleOrNull();

  // ────────────────────────────────────────────────────────────────────────────
  // Medication Plan CRUD (new structured version)
  // ────────────────────────────────────────────────────────────────────────────

  Future<Medication> addMedicationFromLibrary({
    required int birdId,
    required int drugLibraryId,
    required int formulationId,
    required int diseaseCatalogId,
    int? doseRuleId,
    required String calculatedDosage,
    String? manualDosage,
    int timesPerDay = 1,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    final start = startDate ?? AppClock.now;
    return into(medications).insertReturning(
      MedicationsCompanion.insert(
        uuid: genUuid(),
        birdId: birdId,
        drugLibraryId: drugLibraryId,
        formulationId: formulationId,
        diseaseCatalogId: diseaseCatalogId,
        doseRuleId: Value(doseRuleId),
        calculatedDosage: calculatedDosage,
        manualDosage: Value(manualDosage),
        timesPerDay: Value(timesPerDay),
        startDate: start,
        endDate: Value(endDate),
        notes: Value(notes),
        createdAt: Value(AppClock.now),
        updatedAt: Value(AppClock.now),
      ),
    );
  }

  /// Get active medication plans for a bird, joined with drug library and disease.
  Future<List<MedicationWithDetails>> getMedicationsByBird(int birdId) async {
    final query = select(medications).join([
      innerJoin(
          drugLibrary, drugLibrary.id.equalsExp(medications.drugLibraryId)),
      innerJoin(drugFormulations,
          drugFormulations.id.equalsExp(medications.formulationId)),
      innerJoin(diseaseCatalog,
          diseaseCatalog.id.equalsExp(medications.diseaseCatalogId)),
      leftOuterJoin(doseRules, doseRules.id.equalsExp(medications.doseRuleId)),
    ])
      ..where(
          medications.birdId.equals(birdId) & medications.active.equals(true))
      ..orderBy([OrderingTerm.desc(medications.createdAt)]);
    final rows = await query.get();
    return rows.map((r) {
      final med = r.readTable(medications);
      final drug = r.readTable(drugLibrary);
      final form = r.readTable(drugFormulations);
      final disease = r.readTable(diseaseCatalog);
      final rule = r.readTableOrNull(doseRules);
      return MedicationWithDetails(
        medication: med,
        drugName: drug.drugName,
        drugCategory: drug.drugCategory,
        formulation: '${form.concentration}${form.unit}',
        diseaseName: disease.diseaseName,
        doseRule: rule,
      );
    }).toList();
  }

  Future<void> deactivateMedication(int id,
      {String? stopReason, DateTime? actualStopDate}) async {
    await (update(medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      active: const Value(false),
      stopReason: Value(stopReason),
      actualStopDate: Value(actualStopDate),
      updatedAt: Value(AppClock.now),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper types
// ═══════════════════════════════════════════════════════════════════════════════

class FormulationInput {
  final double concentration;
  final String unit;
  final bool isDefault;
  final String? label;
  const FormulationInput({
    required this.concentration,
    this.unit = 'mg/mL',
    this.isDefault = false,
    this.label,
  });
}

class DoseRuleWithNames {
  final DoseRule rule;
  final String diseaseName;
  final String? speciesName;
  final String? drugName;
  final String? sourceLabel;

  DoseRuleWithNames({
    required this.rule,
    required this.diseaseName,
    this.speciesName,
    this.drugName,
    this.sourceLabel,
  });

  String get speciesLabel => speciesName ?? '通用';

  bool get isSpeciesSpecific => speciesName != null;
}

class DoseCalculationResult {
  final double? volumeMl;
  final double? weightG;
  final double? concentration;
  final String? concentrationUnit;
  final double? doseMgKg;
  final int? timesPerDay;
  final int? durationDays;
  final String? administrationRoute;
  final String? diseaseName;
  final bool isWeightOutOfRange;
  final double? speciesMinWeight;
  final double? speciesMaxWeight;
  final String? error;

  DoseCalculationResult({
    this.volumeMl,
    this.weightG,
    this.concentration,
    this.concentrationUnit,
    this.doseMgKg,
    this.timesPerDay,
    this.durationDays,
    this.administrationRoute,
    this.diseaseName,
    this.isWeightOutOfRange = false,
    this.speciesMinWeight,
    this.speciesMaxWeight,
    this.error,
  });

  bool get hasError => error != null;

  String get volumeDisplay {
    if (volumeMl == null) return '-';
    if (volumeMl! < 0.01) return volumeMl!.toStringAsFixed(4);
    if (volumeMl! < 1.0) return volumeMl!.toStringAsFixed(3);
    return volumeMl!.toStringAsFixed(2);
  }
}

class MedicationWithDetails {
  final Medication medication;
  final String drugName;
  final String drugCategory;
  final String formulation;
  final String diseaseName;
  final DoseRule? doseRule;

  MedicationWithDetails({
    required this.medication,
    required this.drugName,
    required this.drugCategory,
    required this.formulation,
    required this.diseaseName,
    this.doseRule,
  });

  String get dosageDisplay =>
      medication.manualDosage ?? medication.calculatedDosage;
}
