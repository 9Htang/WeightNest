/// Pure dose calculation functions extracted from [DrugLibraryRepository].
///
/// Contract (see tests for edge cases):
///   mgDose = (weightG / 1000) × mgPerKg
///   volumeMl = mgDose / concentrationMgPerMl

/// Convert bird weight (g) + dose rate (mg/kg) to required drug mass (mg).
///
/// Returns 0 when [weightG] ≤ 0 or [mgPerKg] ≤ 0 (no NaN, no throw).
double mgPerKgToDose(double weightG, double mgPerKg) {
  if (weightG <= 0 || mgPerKg <= 0) return 0;
  return (weightG / 1000) * mgPerKg;
}

/// Convert drug mass (mg) + formulation concentration (mg/mL) to volume (mL).
///
/// Throws [ArgumentError] when [concentrationMgPerMl] ≤ 0 to prevent
/// division-by-zero in medication contexts where a zero/null concentration
/// is a data error that should be caught upstream.
double doseToVolume(double mg, double concentrationMgPerMl) {
  if (concentrationMgPerMl <= 0) {
    throw ArgumentError.value(
      concentrationMgPerMl,
      'concentrationMgPerMl',
      'Must be > 0',
    );
  }
  return mg / concentrationMgPerMl;
}
