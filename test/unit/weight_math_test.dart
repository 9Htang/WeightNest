import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/plugins/weight/weight_math.dart';
import '../test_helpers/test_clock.dart';

// Non-const defaults for optional parameters.
final _defaultBirthDate = DateTime(2025, 1, 1); // ageDays ≈ 165 at _testNow
final _defaultCreatedAt = DateTime(2025, 1, 1);

@Tags(['smoke'])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final _testNow = DateTime(2025, 6, 15, 12, 0, 0);

  setUp(() => setTestClock(_testNow));

  tearDown(() => resetTestClock());

  // ═════════════════════════════════════════════════════════════════════════
  // Data factories (no DB — construct drift data classes directly)
  // ═════════════════════════════════════════════════════════════════════════

  Specy _testSpecies({
    int nestlingEndDays = 45,
    int juvenileEndDays = 120,
  }) =>
      Specy(
        id: 1,
        uuid: 'species-1',
        name: '测试品种',
        nestlingEndDays: nestlingEndDays,
        juvenileEndDays: juvenileEndDays,
        nestlingWeighIntervalDays: 1,
        juvenileWeighIntervalDays: 3,
        adultWeighIntervalDays: 7,
        minWeightG: null,
        maxWeightG: null,
        createdAt: _defaultCreatedAt,
        updatedAt: _defaultCreatedAt,
        deletedAt: null,
      );

  Bird _testBird({
    int? id,
    DateTime? birthDate,
    double? manualBaselineG,
    bool? weaningOverride,
  }) =>
      Bird(
        id: id ?? 1,
        uuid: 'bird-${id ?? 1}',
        name: '测试鹦鹉',
        speciesId: 1,
        ringNumber: null,
        roomId: null,
        enclosureId: null,
        birthDate: birthDate ?? _defaultBirthDate,
        gender: '未知',
        notes: null,
        sortOrder: 1,
        weighIntervalDays: null,
        manualBaselineG: manualBaselineG,
        weaningOverride: weaningOverride,
        status: 'active',
        createdAt: _defaultCreatedAt,
        updatedAt: _defaultCreatedAt,
        deletedAt: null,
      );

  Weight _testWeight({
    int id = 1,
    required double weightG,
    required DateTime recordedAt,
    int birdId = 1,
  }) =>
      Weight(
        id: id,
        uuid: 'w-$id',
        birdId: birdId,
        weightG: weightG,
        recordedAt: recordedAt,
        recordedBy: null,
        isFasting: false,
        notes: null,
        createdAt: recordedAt,
        updatedAt: recordedAt,
      );

  BirdWithDetails _bwd({
    Bird? bird,
    Specy? species,
    int nestlingEndDays = 45,
    int juvenileEndDays = 120,
    DateTime? birthDate,
    double? manualBaselineG,
    bool? weaningOverride,
  }) =>
      BirdWithDetails(
        bird: bird ??
            _testBird(
              manualBaselineG: manualBaselineG,
              weaningOverride: weaningOverride,
              birthDate: birthDate,
            ),
        species: species ??
            _testSpecies(
              nestlingEndDays: nestlingEndDays,
              juvenileEndDays: juvenileEndDays,
            ),
      );

  // ═════════════════════════════════════════════════════════════════════════
  // logGrowth
  // ═════════════════════════════════════════════════════════════════════════

  group('logGrowth', () {
    test('normal increase: ln(110/100) ≈ 0.0953', () {
      expect(logGrowth(100, 110), closeTo(0.09531, 0.0001));
    });

    test('no change returns 0', () {
      expect(logGrowth(100, 100), 0.0);
    });

    test('weight loss returns negative value', () {
      expect(logGrowth(100, 90), lessThan(0));
    });

    test('prev=0 returns 0 safely', () {
      expect(logGrowth(0, 100), 0.0);
    });

    test('curr=0 returns 0 safely', () {
      expect(logGrowth(100, 0), 0.0);
    });

    test('both zero returns 0', () {
      expect(logGrowth(0, 0), 0.0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // normalize24h
  // ═════════════════════════════════════════════════════════════════════════

  group('normalize24h', () {
    test('exact 24h returns rate unchanged', () {
      expect(normalize24h(0.1, 24), closeTo(0.1, 0.001));
    });

    test('12h doubles the rate', () {
      expect(normalize24h(0.1, 12), closeTo(0.2, 0.001));
    });

    test('48h halves the rate', () {
      expect(normalize24h(0.2, 48), closeTo(0.1, 0.001));
    });

    test('0h returns rate unchanged (safe, no extrapolation)', () {
      expect(normalize24h(0.1, 0), 0.1);
    });

    test('negative hours returns rate unchanged (safe)', () {
      expect(normalize24h(0.1, -5), 0.1);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // hoursBetween
  // ═════════════════════════════════════════════════════════════════════════

  group('hoursBetween', () {
    test('same time returns 0', () {
      final t = DateTime(2025, 1, 1, 12, 0);
      expect(hoursBetween(t, t), 0.0);
    });

    test('exactly 1 hour apart', () {
      expect(
        hoursBetween(
          DateTime(2025, 1, 1, 12, 0),
          DateTime(2025, 1, 1, 13, 0),
        ),
        1.0,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // avg
  // ═════════════════════════════════════════════════════════════════════════

  group('avg', () {
    test('normal average of [1, 2, 3] = 2', () {
      expect(avg([1, 2, 3]), 2.0);
    });

    test('single element returns itself', () {
      expect(avg([5.0]), 5.0);
    });

    // ponytail: empty list throws StateError (reduce on empty iterable).
    // Documented behavior — callers (isWeaningPhase, _chickGrowth) guard
    // against empty input. No separate test needed.
  });

  // ═════════════════════════════════════════════════════════════════════════
  // ewma
  // ═════════════════════════════════════════════════════════════════════════

  group('ewma', () {
    test('empty list returns empty', () {
      expect(ewma([]), isEmpty);
    });

    test('single element returns list with that element', () {
      expect(ewma([5.0]), [5.0]);
    });

    test('known 3-step sequence alpha=0.2', () {
      // ema[0] = 100
      // ema[1] = 110 * 0.2 + 100 * 0.8 = 22 + 80 = 102
      // ema[2] = 90 * 0.2 + 102 * 0.8 = 18 + 81.6 = 99.6
      final result = ewma([100, 110, 90], alpha: 0.2);
      expect(result.length, 3);
      expect(result[0], 100.0);
      expect(result[1], closeTo(102.0, 0.01));
      expect(result[2], closeTo(99.6, 0.01));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // effectiveInterval
  // ═════════════════════════════════════════════════════════════════════════

  group('effectiveInterval', () {
    test('delegates to BirdWithDetails.effectiveWeighIntervalDays', () {
      final b = _bwd();
      expect(effectiveInterval(b), b.effectiveWeighIntervalDays);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // isWeaningPhase — all 9 branches
  // ═════════════════════════════════════════════════════════════════════════

  group('isWeaningPhase', () {
    // ── Override branches ──

    test('weaningOverride=true → always true, no other checks', () {
      final bird = _bwd(weaningOverride: true);
      // Only 1 weight — would normally fail weight count check, but override wins
      final weights = [
        _testWeight(
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isTrue);
    });

    test('weaningOverride=false → always false', () {
      final bird = _bwd(weaningOverride: false);
      // Weights suggest weaning but override blocks it
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 2,
            weightG: 90,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 3,
            weightG: 85,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Age window branches ──

    test('age < (nestlingEndDays - 5) → too young, false', () {
      // birthDate 5 days ago, nestlingEndDays=45 → age=5 < 40
      final bird = _bwd(
        nestlingEndDays: 45,
        birthDate: _testNow.subtract(const Duration(days: 5)),
      );
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 2,
            weightG: 90,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 3,
            weightG: 85,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    test('age > juvenileEndDays → too old, false', () {
      // birthDate 200 days ago, juvenileEndDays=120 → age=200 > 120
      final bird = _bwd(
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 200)),
      );
      // peak at 100, now 85 → drop ≥5%, 2+ drops → but too old
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 2,
            weightG: 93,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 3,
            weightG: 85,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Weight count branch ──

    test('fewer than 3 weights → false', () {
      // age in window: birth 50 days ago, nestlingEndDays=60, juvenile=120
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Peak drop < 5% branch ──

    test('peak drop < 5% → false', () {
      // age in window
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      // peak=100, latest=96 → drop 4% (< 5%)
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 2,
            weightG: 97,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 3,
            weightG: 96,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Fewer than 2 consecutive drops branch ──

    test('peak drop ≥5% but fewer than 2 consecutive drops → false', () {
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      // peak=100, latest=92, but only 1 drop in last 3
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
        _testWeight(
            id: 2,
            weightG: 101,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 3,
            weightG: 102,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 4,
            weightG: 92,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Auto-enter branch ──

    test('auto-enter: peak drop ≥5% + ≥2 consecutive drops in last 3 → true',
        () {
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      // peak=100, latest=88, drops: 99→95→88 (2 consecutive)
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 2,
            weightG: 99,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 3,
            weightG: 95,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
        _testWeight(
            id: 4,
            weightG: 88,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
      ];
      expect(isWeaningPhase(bird, weights), isTrue);
    });

    // ── Auto-exit: overage ──

    test('auto-exit: age > juvenileEndDays + 10 → false', () {
      // juvenileEndDays=120, age=131 > 130
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 131)),
      );
      // Weights suggest weaning but age forces exit
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 2,
            weightG: 95,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 3,
            weightG: 88,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Auto-exit: last 3 stable ──

    test('auto-exit: last 3 stable <3% range and last ≥ first → false', () {
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      // Weight stabilized around 80: peak drop >5% from 100 but last 3 stable
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
        _testWeight(
            id: 2,
            weightG: 95,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 3,
            weightG: 80.5,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 4,
            weightG: 80.0,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
        _testWeight(
            id: 5,
            weightG: 80.8,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });

    // ── Auto-exit: weight recovery > 1.05 × weaning minimum ──

    test('auto-exit: weight recovered above 1.05 × weaning minimum → false',
        () {
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      // Fell to 80, recovered to 90 (90 > 80*1.05=84)
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 120))),
        _testWeight(
            id: 2,
            weightG: 90,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
        _testWeight(
            id: 3,
            weightG: 80,
            recordedAt: _testNow.subtract(const Duration(hours: 72))),
        _testWeight(
            id: 4,
            weightG: 82,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 5,
            weightG: 85,
            recordedAt: _testNow.subtract(const Duration(hours: 24))),
        _testWeight(
            id: 6,
            weightG: 90,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
      ];
      expect(isWeaningPhase(bird, weights), isFalse);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // isLatestAbnormalDirection — all 6 outcome categories
  // ═════════════════════════════════════════════════════════════════════════

  group('isLatestAbnormalDirection', () {
    // ── Insufficient data ──

    test('fewer than 2 weights → none (insufficient data)', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)), // adult
      );
      final weights = [
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.none);
    });

    // ── Normal: adult stable ──

    test('adult, deviation within ±10% → none (normal)', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)), // adult
      );
      // 3 weights around 100 — baseline ≈ 100, deviation < 10%
      final weights = [
        _testWeight(
            id: 3,
            weightG: 105,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 97,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.none);
    });

    // ── High: danger zone (deviation > +15%) ──

    test('adult, deviation > +15% → high', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)),
      );
      // baseline ≈ 100, latest=118, deviation +18% > 15%
      final weights = [
        _testWeight(
            id: 3,
            weightG: 118,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 97,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.high);
    });

    // ── Low: danger zone (deviation < -15%) ──

    test('adult, deviation < -15% → low (danger zone)', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)),
      );
      // baseline ≈ 100, latest=82, deviation -18% < -15%
      final weights = [
        _testWeight(
            id: 3,
            weightG: 82,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 102,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.low);
    });

    // ── Low: warning zone (-15% < deviation ≤ -10%) ──

    test('adult, deviation between -10% and -15% → low (warning)', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)),
      );
      // baseline ≈ 100, latest=88, deviation -12%
      final weights = [
        _testWeight(
            id: 3,
            weightG: 88,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 102,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.low);
    });

    // ── High: warning zone (+10% < deviation ≤ +15%) ──

    test('adult, deviation between +10% and +15% → high (warning)', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)),
      );
      // baseline ≈ 100, latest=112, deviation +12%
      final weights = [
        _testWeight(
            id: 3,
            weightG: 112,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 98,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.high);
    });

    // ── Manual baseline ──

    test('adult with manualBaselineG uses it instead of EMA', () {
      final bird = _bwd(
        birthDate: _testNow.subtract(const Duration(days: 200)),
        manualBaselineG: 80.0, // manual baseline lower than actual weights
      );
      // latest=105, baseline=80, deviation +31% > 15% → high
      final weights = [
        _testWeight(
            id: 2,
            weightG: 105,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.high);
    });

    // ── Chicks: growth rate insufficient → low ──

    test('chick with slow growth (< chickGrowthSlowRate) → low', () {
      // bird is 10 days old, nestlingEndDays=45 → chick
      final bird = _bwd(
        nestlingEndDays: 45,
        birthDate: _testNow.subtract(const Duration(days: 10)),
      );
      // 2 weights 24h apart, growth from 10→10.1 = 1%
      // logGrowth ≈ 0.00995, normalize24h to 24h = same ≈ 0.00995
      // 0.00995 < 0.03 (chickGrowthSlowRate) → low
      final weights = [
        _testWeight(
            id: 2,
            weightG: 10.1,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 1,
            weightG: 10.0,
            recordedAt: _testNow.subtract(const Duration(hours: 25))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.low);
    });

    // ── Chicks: healthy growth → normal ──

    test('chick with healthy growth (≥ chickGrowthSlowRate) → none', () {
      final bird = _bwd(
        nestlingEndDays: 45,
        birthDate: _testNow.subtract(const Duration(days: 10)),
      );
      // 24h growth from 10→11 = 10%, logGrowth ≈ 0.0953
      // 0.0953 > 0.08 (chickGrowthHealthyRate) → normal
      final weights = [
        _testWeight(
            id: 2,
            weightG: 11.0,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 1,
            weightG: 10.0,
            recordedAt: _testNow.subtract(const Duration(hours: 25))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.none);
    });

    // ── Weaning chick → low ──

    test('chick in weaning phase with drop > weaningWarningDropPct → low', () {
      // Auto-enter weaning: age 50, nestlingEndDays=60, juvenile=120
      final bird = _bwd(
        nestlingEndDays: 60,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 70)),
      );
      // Weights DESC (newest first): 80, 90, 100
      // isWeaningPhase gets ASC [100, 90, 80] → 100→90 drop, 90→80 drop,
      // 2 consecutive drops, peak drop 20% → weaning true
      // drop = (100-80)/100 = 20% > weaningWarningDropPct(10%) → low
      final weightsDesc = [
        _testWeight(
            id: 3,
            weightG: 80,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 90,
            recordedAt: _testNow.subtract(const Duration(hours: 25))),
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 49))),
      ];
      expect(
          isLatestAbnormalDirection(bird, weightsDesc), AbnormalDirection.low);
    });

    // ── Juvenile: uses same path as adult ──

    test('juvenile with deviation beyond threshold → low', () {
      // birth 80 days ago, nestlingEndDays=45, juvenileEndDays=120 → juvenile
      final bird = _bwd(
        nestlingEndDays: 45,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 80)),
      );
      // baseline ≈ 100, latest=82, deviation -18% → low
      final weights = [
        _testWeight(
            id: 3,
            weightG: 82,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 102,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.low);
    });

    // ── Juvenile, fewer than 3 weights → none (insufficient for EMA) ──

    test('juvenile with < 3 weights and no manual baseline → none', () {
      final bird = _bwd(
        nestlingEndDays: 45,
        juvenileEndDays: 120,
        birthDate: _testNow.subtract(const Duration(days: 80)),
      );
      final weights = [
        _testWeight(
            id: 2,
            weightG: 80,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 1,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
      ];
      expect(isLatestAbnormalDirection(bird, weights), AbnormalDirection.none);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // isLatestAbnormal (backward-compat wrapper)
  // ═════════════════════════════════════════════════════════════════════════

  group('isLatestAbnormal', () {
    test('returns true when direction is low', () {
      final bird =
          _bwd(birthDate: _testNow.subtract(const Duration(days: 200)));
      final weights = [
        _testWeight(
            id: 3,
            weightG: 82,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 102,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormal(bird, weights), isTrue);
    });

    test('returns false when direction is none', () {
      final bird =
          _bwd(birthDate: _testNow.subtract(const Duration(days: 200)));
      final weights = [
        _testWeight(
            id: 3,
            weightG: 102,
            recordedAt: _testNow.subtract(const Duration(hours: 1))),
        _testWeight(
            id: 2,
            weightG: 100,
            recordedAt: _testNow.subtract(const Duration(hours: 48))),
        _testWeight(
            id: 1,
            weightG: 98,
            recordedAt: _testNow.subtract(const Duration(hours: 96))),
      ];
      expect(isLatestAbnormal(bird, weights), isFalse);
    });
  });
}
