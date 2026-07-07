import 'package:flutter_test/flutter_test.dart';
import '../../lib/plugins/medication/dose_math.dart';

/// All expected values cross-checked against the anchor formula:
///   volume_mL = (weightG / 1000) × mgPerKg / concentrationMgPerMl
///
/// Every test states the exact arithmetic it verifies.

@Tags(['smoke'])
void main() {
  // ═════════════════════════════════════════════════════════════════════════
  // mgPerKgToDose(weightG, mgPerKg) → mg
  // ═════════════════════════════════════════════════════════════════════════

  group('mgPerKgToDose', () {
    test('standard: 50g bird × 10mg/kg → 0.5mg', () {
      // (50 / 1000) × 10 = 0.05 × 10 = 0.5
      expect(mgPerKgToDose(50, 10), closeTo(0.5, 0.0001));
    });

    test('tiny bird: 10g × 0.1mg/kg → 0.001mg', () {
      // (10 / 1000) × 0.1 = 0.01 × 0.1 = 0.001
      expect(mgPerKgToDose(10, 0.1), closeTo(0.001, 0.00001));
    });

    test('zero weight → 0 (no NaN, no exception)', () {
      expect(mgPerKgToDose(0, 10), 0.0);
    });

    test('zero dose rate → 0', () {
      expect(mgPerKgToDose(50, 0), 0.0);
    });

    test('negative weight → 0 (safe guard)', () {
      expect(mgPerKgToDose(-10, 10), 0.0);
    });

    test('negative dose rate → 0 (safe guard)', () {
      expect(mgPerKgToDose(50, -5), 0.0);
    });

    test('large bird: 5000g × 50mg/kg → 250mg', () {
      // (5000 / 1000) × 50 = 5 × 50 = 250
      expect(mgPerKgToDose(5000, 50), closeTo(250.0, 0.001));
    });

    test('both zero → 0', () {
      expect(mgPerKgToDose(0, 0), 0.0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // doseToVolume(mg, concentrationMgPerMl) → mL
  // ═════════════════════════════════════════════════════════════════════════

  group('doseToVolume', () {
    test('standard: 0.5mg ÷ 25mg/mL → 0.02mL', () {
      // 0.5 / 25 = 0.02
      expect(doseToVolume(0.5, 25), closeTo(0.02, 0.00001));
    });

    test('very small volume: 0.001mg ÷ 25mg/mL → 0.00004mL', () {
      // 0.001 / 25 = 0.00004
      expect(doseToVolume(0.001, 25), closeTo(0.00004, 0.0000001));
    });

    test('large dose: 500mg ÷ 1mg/mL → 500mL (no overflow)', () {
      // 500 / 1 = 500
      expect(doseToVolume(500, 1), closeTo(500.0, 0.001));
    });

    test('zero dose mass → 0mL', () {
      expect(doseToVolume(0, 25), 0.0);
    });

    test('zero concentration → throws ArgumentError', () {
      // Contract: zero concentration is a data error, throw.
      expect(
        () => doseToVolume(0.5, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('negative concentration → throws ArgumentError', () {
      expect(
        () => doseToVolume(0.5, -10),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Chained formula: mgPerKgToDose + doseToVolume = volume_mL
  // ═════════════════════════════════════════════════════════════════════════

  group('chained formula', () {
    test('50g × 10mg/kg ÷ 25mg/mL → 0.02mL (full pipeline)', () {
      final mg = mgPerKgToDose(50, 10);
      expect(mg, closeTo(0.5, 0.0001));
      final vol = doseToVolume(mg, 25);
      expect(vol, closeTo(0.02, 0.00001));
    });

    test('matches anchor: vol = (weight/1000) × mgPerKg / concentration', () {
      // Direct formula for verification.
      double direct(double w, double d, double c) => (w / 1000) * d / c;

      final w = 120.0; // 120g bird
      final d = 15.0; // 15mg/kg
      final c = 50.0; // 50mg/mL

      final viaExtracted = doseToVolume(mgPerKgToDose(w, d), c);
      final viaDirect = direct(w, d, c);

      // Must match within float epsilon.
      expect(viaExtracted, closeTo(viaDirect, 0.0000001),
          reason: 'Extracted functions must match direct formula exactly');
    });
  });
}
