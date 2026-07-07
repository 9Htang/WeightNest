import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/plugin_registry.dart';
import '../../database/database.dart';
import '../../repositories/species_repository.dart';
import 'drug_library_repository.dart';

/// Import result summary.
class DrugLibraryImportResult {
  final int drugsCreated;
  final int drugsUpdated;
  final int doseRulesCreated;
  final int doseRulesUpdated;
  final List<String> errors;

  DrugLibraryImportResult({
    this.drugsCreated = 0,
    this.drugsUpdated = 0,
    this.doseRulesCreated = 0,
    this.doseRulesUpdated = 0,
    this.errors = const [],
  });

  int get totalCreated => drugsCreated + doseRulesCreated;
  int get totalUpdated => drugsUpdated + doseRulesUpdated;
  bool get hasNoChanges => totalCreated == 0 && totalUpdated == 0;
}

/// Excel import for drug library and dose rules.
/// Parses Excel sheets and merges into the local database.
class DrugLibraryImportService {
  final AppDatabase _db;

  DrugLibraryImportService() : _db = pluginRegistry.db!;

  /// Pick an Excel file and import it.
  Future<DrugLibraryImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.first.path!);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    return await _importExcel(excel);
  }

  /// Import from decoded Excel.
  Future<DrugLibraryImportResult> _importExcel(Excel excel) async {
    int drugsCreated = 0, drugsUpdated = 0;
    int rulesCreated = 0, rulesUpdated = 0;
    final errors = <String>[];

    try {
      final drugSheet = excel.sheets['药品库'] ?? excel.sheets.values.first;

      // Phase 1: Parse drug library rows
      final drugRows = <_DrugImportRow>[];
      for (int r = 1; r < drugSheet.maxRows; r++) {
        final cells = drugSheet.row(r);
        final name = _cellText(cells, 0);
        if (name.isEmpty) continue;

        drugRows.add(_DrugImportRow(
          drugName: name,
          brandName: _cellText(cells, 1),
          activeIngredient: _cellText(cells, 2),
          drugCategory: _cellText(cells, 3),
          formulationType: _cellText(cells, 4),
          storageInstructions: _cellText(cells, 5),
          openedExpiryDays: int.tryParse(_cellText(cells, 6)),
          formulationsStr: _cellText(cells, 7),
          notes: _cellText(cells, 8),
        ));
      }

      // Process each drug
      for (final row in drugRows) {
        try {
          final existing = await _db.searchDrugs(row.drugName);
          final exactMatch = existing.where((d) => d.drugName == row.drugName);
          int drugId;

          if (exactMatch.isNotEmpty) {
            drugId = exactMatch.first.id;
            await _db.updateDrug(
              drugId,
              drugName: row.drugName,
              brandName: row.brandName?.isEmpty == true ? null : row.brandName,
              activeIngredient: row.activeIngredient?.isEmpty == true
                  ? null
                  : row.activeIngredient,
              drugCategory:
                  row.drugCategory.isNotEmpty ? row.drugCategory : '其他',
              formulationType:
                  row.formulationType.isNotEmpty ? row.formulationType : '滴剂',
              storageInstructions: row.storageInstructions?.isEmpty == true
                  ? null
                  : row.storageInstructions,
              openedExpiryDays: row.openedExpiryDays,
              notes: row.notes?.isEmpty == true ? null : row.notes,
            );
            drugsUpdated++;
          } else {
            final drug = await _db.addDrug(
              drugName: row.drugName,
              brandName: row.brandName?.isEmpty == true ? null : row.brandName,
              activeIngredient: row.activeIngredient?.isEmpty == true
                  ? null
                  : row.activeIngredient,
              drugCategory:
                  row.drugCategory.isNotEmpty ? row.drugCategory : '其他',
              formulationType:
                  row.formulationType.isNotEmpty ? row.formulationType : '滴剂',
              storageInstructions: row.storageInstructions?.isEmpty == true
                  ? null
                  : row.storageInstructions,
              openedExpiryDays: row.openedExpiryDays,
              notes: row.notes?.isEmpty == true ? null : row.notes,
            );
            drugId = drug.id;
            drugsCreated++;
          }

          // Parse and add formulations from text
          if (row.formulationsStr != null && row.formulationsStr!.isNotEmpty) {
            await _parseAndAddFormulations(drugId, row.formulationsStr!);
          }
        } catch (e) {
          errors.add('药品 "${row.drugName}": $e');
        }
      }

      // Phase 2: Parse dose rules (Sheet 2)
      if (excel.sheets.containsKey('剂量规则')) {
        final ruleSheet = excel.sheets['剂量规则']!;
        for (int r = 1; r < ruleSheet.maxRows; r++) {
          final cells = ruleSheet.row(r);
          final drugName = _cellText(cells, 0);
          final diseaseName = _cellText(cells, 1);
          if (drugName.isEmpty || diseaseName.isEmpty) continue;

          try {
            final speciesName = _cellText(cells, 2);
            final mgKg = double.tryParse(_cellText(cells, 3));
            final times = int.tryParse(_cellText(cells, 4));
            final days = int.tryParse(_cellText(cells, 5));
            final route = _cellText(cells, 6);
            final notes = _cellText(cells, 7);

            if (mgKg == null || times == null || days == null) {
              errors.add('剂量规则 "$drugName / $diseaseName": 数据不完整');
              continue;
            }

            // Find drug and disease IDs
            final drugs = await _db.searchDrugs(drugName);
            final drug = drugs.where((d) => d.drugName == drugName);

            int? speciesId;
            if (speciesName.isNotEmpty && speciesName != '通用') {
              final sp = await _db.getSpeciesByNameSafe(speciesName);
              speciesId = sp?.id;
            }

            // Find or create disease
            final diseases = await _db.searchDiseases(diseaseName);
            int diseaseId;
            final exactDisease =
                diseases.where((d) => d.diseaseName == diseaseName);
            if (exactDisease.isNotEmpty) {
              diseaseId = exactDisease.first.id;
            } else {
              final newDisease = await _db.addDisease(diseaseName: diseaseName);
              diseaseId = newDisease.id;
            }

            if (drug.isNotEmpty) {
              // Check if rule already exists
              final existingRules =
                  await _db.getRulesByDrugAndDisease(drug.first.id, diseaseId);
              final exactRule =
                  existingRules.where((r) => r.rule.speciesId == speciesId);

              if (exactRule.isNotEmpty) {
                await _db.updateDoseRule(
                  exactRule.first.rule.id,
                  mgKgDose: mgKg,
                  timesPerDay: times,
                  durationDays: days,
                  administrationRoute: route.isNotEmpty ? route : '口服',
                  notes: notes.isEmpty ? null : notes,
                );
                rulesUpdated++;
              } else {
                await _db.addDoseRule(
                  drugId: drug.first.id,
                  diseaseId: diseaseId,
                  speciesId: speciesId,
                  mgKgDose: mgKg,
                  timesPerDay: times,
                  durationDays: days,
                  administrationRoute: route.isNotEmpty ? route : '口服',
                  notes: notes.isEmpty ? null : notes,
                );
                rulesCreated++;
              }
            }
          } catch (e) {
            errors.add('剂量规则 "$drugName / $diseaseName": $e');
          }
        }
      }
    } catch (e) {
      errors.add('解析失败: $e');
    }

    return DrugLibraryImportResult(
      drugsCreated: drugsCreated,
      drugsUpdated: drugsUpdated,
      doseRulesCreated: rulesCreated,
      doseRulesUpdated: rulesUpdated,
      errors: errors,
    );
  }

  Future<void> _parseAndAddFormulations(int drugId, String text) async {
    // Format: "25.0mg/mL (默认), 50.0mg/mL, 100.0mg/mL"
    final parts = text.split(',');
    final existing = await _db.getFormulationsByDrug(drugId);

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      final isDefault = trimmed.contains('(默认)') || trimmed.contains('（默认）');
      final clean =
          trimmed.replaceAll('(默认)', '').replaceAll('（默认）', '').trim();

      // Extract concentration number and unit
      final numMatch = RegExp(r'^([\d.]+)').firstMatch(clean);
      if (numMatch == null) continue;

      final concentration = double.tryParse(numMatch.group(1)!);
      if (concentration == null) continue;

      final unit = clean.substring(numMatch.end).trim();

      // Check if this formulation already exists
      final exists = existing
          .where((f) => f.concentration == concentration && f.unit == unit);
      if (exists.isEmpty) {
        await _db.addFormulation(
          drugId: drugId,
          concentration: concentration,
          unit: unit.isNotEmpty ? unit : 'mg/mL',
          isDefault: isDefault,
          label: '$concentration${unit.isNotEmpty ? unit : "mg/mL"}',
        );
      }
    }
  }

  String _cellText(List<Data?> cells, int index) {
    if (index >= cells.length) return '';
    final cell = cells[index];
    if (cell?.value == null) return '';
    return cell!.value.toString().trim();
  }
}

class _DrugImportRow {
  final String drugName;
  final String? brandName;
  final String? activeIngredient;
  final String drugCategory;
  final String formulationType;
  final String? storageInstructions;
  final int? openedExpiryDays;
  final String? formulationsStr;
  final String? notes;

  _DrugImportRow({
    required this.drugName,
    this.brandName,
    this.activeIngredient,
    this.drugCategory = '其他',
    this.formulationType = '滴剂',
    this.storageInstructions,
    this.openedExpiryDays,
    this.formulationsStr,
    this.notes,
  });
}
