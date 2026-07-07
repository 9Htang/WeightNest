# WeightNest Testing Strategy

**Version:** 1.0  
**Date:** 2026-06-28  
**App Version:** 1.9.11+59  
**Branch:** feature/offline-mvp

---

## 1. Executive Summary

WeightNest is an offline-first Flutter app for parrot weight tracking and health management. It has **zero automated test execution in CI**, **5 thin test files**, and **no widget, performance, or security tests**. The data-is-local architecture eliminates network-testing surface area but raises the stakes on data integrity, schema migrations, and backup/restore correctness.

**Top risk:** Data loss from migration bugs or backup failures. **Second risk:** Alert/dose calculation errors causing real-world harm to birds.

This document defines the complete testing architecture, prioritized by risk.

---

## 2. Requirement Analysis

### 2.1 Functional Requirements (Testability Assessment)

| Requirement Area | Testable? | Notes |
|---|---|---|
| Bird CRUD | ✓ | In-memory DB |
| Weight recording & dedup | ✓ | Covered in existing tests |
| Weight trend alerts (growth rate, baseline, chronic) | ✓ | Pure math + DB queries |
| Medication dose calculation | ✓ | Pure math, no external deps |
| Drug library import/export | ✓ | File I/O, needs temp dir |
| Task generation (daily, dedup) | ✓ | DB state + clock injection |
| Backup/restore (WNBK format) | ✓ | File I/O, temp dir |
| Bird export/import (WNBD format) | ✓ | ZIP + DB + photos |
| Plugin alert/task aggregation | ✓ | In-memory DB + all plugins |
| Notification scheduling | ✗ | Requires platform; manual test |
| Photo picking / motion photo | ✗ | Platform plugin; manual test |
| File sharing (share_plus) | ✗ | Platform; manual test |
| Local notifications display | ✗ | Platform; manual test |

### 2.2 Non-Functional Requirements

| NFR | Current State | Target |
|---|---|---|
| Offline operation | ✓ (by design) | Must survive airplane mode |
| DB query performance | Unknown | <100ms for any single query |
| App startup time | Unknown | <2s cold start |
| Memory usage | Unknown | <200MB under normal use |
| Schema migration reliability | No tests | Every migration tested |
| Backup file integrity | No tests | Round-trip restore verified |
| Chinese localization | No tests | All user-visible strings covered |

### 2.3 Missing Requirements (Ambiguities)

1. **What is "too slow" for weight chart rendering with 10,000 data points?** No perf target defined.
2. **What happens when the DB file is corrupted mid-write?** No recovery spec.
3. **What is the max number of birds/weights/medications the app must handle?** No scalability target.
4. **How should the app behave when disk is full?** No error-handling spec.
5. **What are the exact precision requirements for dose calculations?** Not specified — `double` used throughout, which has IEEE 754 edge cases.

---

## 3. Testing Architecture

### 3.1 Layer Model

```
┌──────────────────────────────────────────────┐
│  L6: End-to-End (platform-level flows)        │  ~5% of suite
│  L5: Widget/UI (screens, interactions)        │  ~15%
│  L4: Provider/State (Riverpod notifiers)      │  ~15%
│  L3: Service (business logic, aggregation)    │  ~25%
│  L2: Repository (DB queries, CRUD)            │  ~25%
│  L1: Unit (pure functions, algorithms)        │  ~15%
└──────────────────────────────────────────────┘
```

### 3.2 Layer Responsibilities

| Layer | What It Tests | Mock Strategy | DB | Framework |
|---|---|---|---|---|
| **L1: Unit** | Pure functions: alert math, dose calc, data transforms, UUID gen, SHA256 | None needed | None | `flutter_test` (Dart) |
| **L2: Repository** | Every Drift DAO method: CRUD, joins, transactions, error paths | None | `NativeDatabase.memory()` | `flutter_test` |
| **L3: Service** | AlertService, OperationService, BackupService, ExportService, NotificationService | Mock repositories if needed; prefer real in-memory DB | `NativeDatabase.memory()` | `flutter_test` |
| **L4: Provider** | Riverpod providers, StateNotifiers, state transitions | Real repositories via in-memory DB | `NativeDatabase.memory()` | `flutter_test` |
| **L5: Widget** | Screen rendering, user interactions, navigation, form validation | Mock providers via `ProviderContainer.override` | None | `flutter_test` |
| **L6: E2E** | Multi-screen flows: weigh→alert→task, import→view→export | None (real app) | Real file-based DB | `integration_test` |

### 3.3 Isolation Strategy

- **No shared mutable state between tests.**
- Each test creates its own `AppDatabase.test()` (in-memory SQLite).
- `setUp`/`tearDown` pattern: create DB → run test → close DB.
- No test-ordering dependencies.
- AppClock is injectable — tests override it to deterministic timestamps.

### 3.4 Test Environment

```
┌─────────────────────────────────────────────┐
│  CI (Codemagic / GitHub Actions)             │
│  ├── flutter analyze (static, 0 deps)        │
│  ├── dart format --check (style, 0 deps)     │
│  ├── flutter test (L1-L5, in-memory)         │
│  └── flutter test integration_test (L6)      │
│       └── Requires emulator/device            │
│                                              │
│  Developer Machine                           │
│  ├── flutter test --coverage                 │
│  └── flutter test integration_test           │
│       └── Connected device or emulator        │
└─────────────────────────────────────────────┘
```

**Key constraint:** L1-L5 must run headless (no device/emulator needed). L6 requires a device. CI runs L1-L5 on every PR; L6 runs on merge to main.

---

## 4. Test Plan

### 4.1 Phases & Milestones

| Phase | Scope | Exit Criteria | Timeline |
|---|---|---|---|
| **Phase 0: Foundation** | Add test deps (mocktail), test helpers, CI test step | `flutter test` passes in CI; coverage ≥ 5% | Week 1 |
| **Phase 1: Critical Path** | L1 alert math, L2 all repositories, L3 backup round-trip | All repositories tested; backup round-trip passes | Week 2-3 |
| **Phase 2: Business Logic** | L3 services (alert, operation, export), L1 dose calc | All services tested; dose edge cases covered | Week 3-4 |
| **Phase 3: State & UI** | L4 providers, L5 key screens (weigh, tasks, bird detail) | All providers tested; critical screens have widget tests | Week 4-5 |
| **Phase 4: Plugins** | L2-L4 per plugin (medication, breeding, gallery) | Each plugin has repo + service + provider tests | Week 5-6 |
| **Phase 5: E2E & Perf** | L6 integration tests, DB perf benchmarks | 3 key flows automated; perf baselines captured | Week 6-7 |
| **Phase 6: Regression Suite** | Smoke test pack, CI gate enforcement | Block PRs that break tests; coverage ≥ 60% | Ongoing |

### 4.2 Entry/Exit Criteria per Phase

**Entry criteria for every phase:** Previous phase exit criteria met.  
**Exit criteria:** All tests in phase pass. Coverage target met. No skipped tests without documented reason.

### 4.3 Release Criteria

- All L1-L5 tests pass
- L6 smoke tests pass on target platform
- No known severity-1 (data loss) or severity-2 (calculation error) bugs
- Coverage ≥ 60% on `lib/` (excluding generated code)
- Schema migration tested from last 5 versions

---

## 5. Risk Analysis

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | **Data loss from migration bug** | Medium (17 migrations, no tests) | Critical | Migration tests from known DB snapshots |
| R2 | **Backup corrupted, restore fails silently** | Medium (complex ZIP+SHA256) | Critical | Automated round-trip tests with verification |
| R3 | **Dose calculation off by 10x** | Low (straightforward math) | Critical | Boundary tests: 0.001g–100g range, unit conversion |
| R4 | **Alert false negative (sick bird missed)** | Medium (statistical thresholds) | High | Scenario-based tests with known weight series |
| R5 | **Task not generated (care missed)** | Medium (dedup logic complex) | High | Dedup matrix: all combinations tested |
| R6 | **Cross-plugin DB conflict** | Low (Drift handles locking) | High | Concurrent write tests across plugins |
| R7 | **App crash on corrupt DB file** | Low (SQLite resilient) | Medium | Corrupt-DB recovery test |
| R8 | **Disk full during backup** | Low | Medium | Error-path test with simulated full disk |
| R9 | **Riverpod state leak between tests** | Medium (shared containers) | Low | ProviderContainer isolation pattern enforced |
| R10 | **Platform API change breaks notifications** | High (external dep) | Medium | Manual smoke test per release |

### Risk Prioritization

**Must-test first (R1-R5):** Data integrity, dose calc, alert accuracy, task generation.  
**Should-test (R6-R8):** Cross-plugin, corrupt DB, disk full.  
**Nice-to-test (R9-R10):** Provider isolation, platform smoke.

---

## 6. Test Case Design

### 6.1 L1: Unit Tests — Pure Functions

#### alert_algorithm_test.dart (exists, extend)

```
✓ logGrowthRate: normal values, zero weight (edge), negative weight (invalid)
✓ normalizeTo24h: exact 24h, 12h, 48h, 1h, 0h (edge), negative (invalid)
✓ calcEMA: empty series, single point, known sequence, alpha=0 (no smoothing), alpha=1 (instant)
✓ calcStdDev: empty, single, known values, large variance, zero variance
✓ calcGrowthRate: 0g gain, 100g gain, negative gain (weight loss), same-day (zero days)
```

#### dose_calculation_test.dart (new)

```
✓ mgPerKgToDose: standard case, zero weight (edge), zero mgPerKg, very small bird (10g)
✓ doseToVolume: standard, zero concentration (invalid), very small volume (<0.01mL)
✓ roundToSignificantDigits: 0.01234→0.012, 123.456→120, 0→0, negative
✓ validateDoseRange: within range, below minimum, above maximum, at boundary
✓ weightUnits: grams, kilograms, pounds conversions
```

#### data_transform_test.dart (new)

```
✓ UUID v4 format validation
✓ SHA256: known vector, empty input, large input
✓ Date rounding: floor to day, hour, minute
```

### 6.2 L2: Repository Tests — All DAOs

Pattern (follow existing `bird_repository_test.dart` style):

```dart
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test();
  });

  tearDown(() async {
    await db.close();
  });

  group('createXxx', () { /* happy path, required fields, optional fields, duplicate, constraints */ });
  group('getXxx', () { /* exists, not found, empty table, ordering, filtering */ });
  group('updateXxx', () { /* exists, not found, partial update, no-op update */ });
  group('deleteXxx', () { /* exists, not found, cascade effects, orphan cleanup */ });
}
```

**Repositories to test (priority order):**

| Priority | Repository | Key Risks |
|---|---|---|
| P0 | `WeightRepository` | Dedup logic, batch queries, same-minute overwrite |
| P0 | `TaskRepository` | Dedup matrix, overdue marking, cross-day behavior |
| P1 | `BirdRepository` | Species join, sortOrder, room reassignment |
| P1 | `MedicationRepository` | Dose tracking, stop conditions, feeding records |
| P1 | `DrugLibraryRepository` | Formulation lookup, disease catalog |
| P2 | `AlertService` (DB ext) | Dedup by (birdId, type, desc, date), severity |
| P2 | `SpeciesRepository` | Upsert behavior |
| P2 | `RoomRepository` / `EnclosureRepository` | Count queries, bulk operations |
| P2 | `BreedingRepository` | State machine transitions, pair lifecycle |
| P3 | `GalleryRepository` | Photo metadata, avatar assignment |
| P3 | `UserRepository` | Simple CRUD |

### 6.3 L3: Service Tests

#### BackupService (Critical — R2)

```
✓ roundTrip: create DB with all entities → backup → delete DB → restore → verify identical
✓ emptyBackup: backup empty DB, restore, DB still works
✓ corruptBackupFile: restore from garbage data → clean error, no DB damage
✓ versionMismatch: restore from newer schema version → clean error
✓ largeBackup: 100 birds, 10k weights → backup → restore → verify
✓ sha256Mismatch: tampered backup → restore rejected
```

#### AlertService (Critical — R4)

```
✓ detectAll: aggregates from all plugins, deduplicates
✓ persistAndNotify: danger alerts stored individually, warnings aggregated
✓ noDuplicateNotifications: same alert on consecutive days → only one notification
✓ pluginDisabled: disabled plugin's alerts excluded
✓ emptyAlerts: no alerts when all birds healthy
```

#### OperationService

```
✓ record: activity log written, task completed, event emitted
✓ recordInTransaction: respects external transaction
✓ revoke: activity log removed, task un-completed
✓ concurrent: two operations in parallel don't conflict
✓ taskNotFound: operation for non-existent task → logs warning, doesn't crash
```

#### ExcelExportService / BirdExportService

```
✓ exportWeightMatrix: produces valid .xlsx, correct cell values
✓ exportDrugLibrary: all columns present, correct data
✓ birdExport: produces valid ZIP, correct structure
✓ emptyExport: no birds → valid empty export
```

### 6.4 L4: Provider/State Tests

#### WeighNotifier (Critical)

```
✓ initialState: no bird selected, keypad disabled
✓ selectRoom → rooms loaded
✓ selectEnclosure → enclosures loaded
✓ selectBird → keypad enabled
✓ enterWeight → weight saved, next bird auto-selected
✓ enterWeightBelowMin → rejected
✓ enterWeightAboveMax → rejected
✓ completeAllBirds → returns to room selection
✓ navigationBack: room→enclosure, enclosure→birds, bird→values persist
```

#### ThemeNotifier

```
✓ initial: system default
✓ setLight, setDark, setSystem
✓ persistence across restart (mock SharedPreferences)
```

#### PremiumStatusNotifier

```
✓ initial: free tier
✓ activate with valid license → pro
✓ activate with invalid license → rejected, stays free
✓ expiry: pro reverts to free after expiry date
```

### 6.5 L5: Widget Tests — Critical Screens

#### WeighScreen / WeighGridScreen (P0 — most complex interaction)

```
✓ renders keypad with all digits
✓ digit tap updates display
✓ decimal point: single tap, double tap ignored, leading decimal shows "0."
✓ backspace: removes last digit, empty string handled
✓ weight submitted → confirmation UI
✓ loading state while saving
✓ error state if save fails
✓ navigate between birds in grid
✓ color coding reflects weight status (normal/low/high)
```

#### TasksScreen (P0)

```
✓ renders today's tasks grouped by type
✓ overdue tasks shown in separate section
✓ complete task → removed from list
✓ empty state when no tasks
✓ task type filter works
✓ refresh after weigh/medication operation
```

#### BirdDetailScreen

```
✓ renders all plugin sections (weight chart, medication, breeding, gallery)
✓ avatar displays correctly
✓ weight chart renders with data
✓ medication list renders
✓ loading state while fetching bird
✓ error state if bird not found
```

#### SettingsScreen

```
✓ theme toggle works
✓ backup button initiates backup
✓ restore button opens file picker
✓ work hours config saves
```

### 6.6 L6: E2E Tests

```
Flow 1: Full Weigh Flow
  Open app → navigate to Birds → select bird → weigh → enter weight → 
  verify weight appears in chart → verify task auto-completed

Flow 2: Alert Detection
  Add bird → record low weight for 3 days → verify alert appears → 
  confirm alert → verify alert dismissed

Flow 3: Backup & Restore
  Create birds + weights → backup → clear app data → restore → 
  verify all data present

Flow 4: Medication
  Add drug → create medication schedule → record dose → 
  verify next dose time calculated correctly
```

### 6.7 Edge Cases & Negative Testing

```
┌──────────────────────┬────────────────────────────────────────┐
│ Category             │ Examples                               │
├──────────────────────┼────────────────────────────────────────┤
│ Empty data           │ Empty DB, empty bird list, zero weights│
│ Boundary values      │ Bird weight 0g, 10000g, 99999g         │
│ Concurrent writes    │ 2 weigh-ins same second different birds│
│ Rapid navigation     │ Back-button spam during save           │
│ Kill mid-operation   │ App killed during backup → retry       │
│ Migration            │ DB from v12, v13, v14… → upgrade to v17│
│ Disk full            │ Write during backup → clean failure    │
│ Corrupt input        │ Import non-ZIP file as backup           │
│ Locale               │ Chinese vs English date/number formats │
│ Accessibility        │ Large font, screen reader labels       │
│ Timezone             │ Weigh exactly at midnight across days  │
│ Duplicate UUID       │ (Theoretical) collision in UUID v4     │
└──────────────────────┴────────────────────────────────────────┘
```

---

## 7. Automation Strategy

### 7.1 What to Automate

| Automate | Manual Only |
|---|---|
| L1-L5: Unit, Repository, Service, Provider, Widget | Notification tap behavior |
| L6: Key flow smoke tests | Photo picking UX |
| Schema migration tests | Motion photo detection |
| Backup round-trip | File sharing intent |
| Dose calculation boundaries | Platform-specific notification display |
| CI pipeline on every PR | Exploratory testing pre-release |
| Coverage report on every PR | Accessibility audit |

### 7.2 Automation Framework

```
Framework: flutter_test (built-in, zero added deps for L1-L5)
Mocking: mocktail (lightweight, no code generation — add to dev_dependencies)
DB: AppDatabase.test() → NativeDatabase.memory() (already works)
Widget: WidgetTester + pumpWidget with ProviderScope overrides
E2E: integration_test package (built-in)
Coverage: flutter test --coverage + lcov → coverage % gate
```

**Recommendation: Add `mocktail: ^0.3.0` to dev_dependencies.** It's the only new dep needed. No code generation, no build_runner dependency, ~50KB.

### 7.3 Test Data Management

```dart
// Shared test data factories (lib/test_helpers/ or test/test_helpers/)
// 
// Pattern: each factory creates minimal valid entities with sensible defaults.
// Tests override only the fields they care about.

Future<Species> createTestSpecies(AppDatabase db, {String name = 'Budgie'}) async { ... }
Future<Bird> createTestBird(AppDatabase db, {required String speciesId, ...}) async { ... }
Future<void> addWeightSeries(AppDatabase db, String birdId, List<double> grams) async { ... }

// Use shared setup for common scenarios:
Future<AppDatabase> dbWithBirdAndWeights() async {
  final db = AppDatabase.test();
  final species = await createTestSpecies(db);
  final bird = await createTestBird(db, speciesId: species.id);
  await addWeightSeries(db, bird.id, [100, 102, 101, 103, 105]);
  return db;
}
```

### 7.4 CI/CD Integration

```yaml
# codemagic.yaml additions:
scripts:
  - name: Run tests
    script: flutter test --coverage
  - name: Coverage gate
    script: |
      # Fail if coverage drops below threshold
      # (Phase 0: no gate, Phase 3+: 50%, Phase 6+: 60%)
  - name: Run integration tests (main only)
    script: flutter test integration_test/ --device-id emulator-5554
```

### 7.5 Reporting

- `flutter test --coverage` → `coverage/lcov.info`
- Convert to HTML with `genhtml` (lcov package) or use Codemagic's built-in coverage visualization
- Test failure = PR blocked (after Phase 3, once baseline coverage exists)

---

## 8. Performance Testing

### 8.1 Targets

| Metric | Target | Measurement |
|---|---|---|
| Cold start to home screen | < 2s | `flutter run --profile --trace-startup` |
| Weight chart render (1000 pts) | < 200ms | Widget test with `pumpAndSettle` timeout |
| Weight chart render (10000 pts) | < 500ms | Same |
| DB query: getLatestByBirds (100 birds) | < 50ms | Dart `Stopwatch` in test |
| DB query: getAllWeights (100k rows) | < 200ms | Dart `Stopwatch` in test |
| Backup: 100 birds + 10k weights | < 30s | Dart `Stopwatch` in test |
| Memory: idle | < 100MB | `flutter run --profile --trace-memory` |

### 8.2 Performance Test Design

```dart
// DB performance benchmark (test/perf/db_perf_test.dart)
group('WeightRepository performance', () {
  test('getLatestByBirds scales to 100 birds', () async {
    final db = await dbWithManyBirds(100, weightsPerBird: 30);
    final sw = Stopwatch()..start();
    await db.getLatestByBirds(allBirdIds);
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(50));
  });

  test('getByBird handles 10k weights', () async {
    final db = await dbWithSingleBird(weights: 10000);
    final sw = Stopwatch()..start();
    await db.getByBird(birdId);
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(200));
  });
});
```

### 8.3 Startup Performance

- Measure with `flutter run --profile --trace-startup` on a mid-range Android device
- Baseline once, then compare on every major release
- Regression threshold: +20% startup time

---

## 9. Security Testing

### 9.1 Threat Model (Offline App)

| Threat | Severity | Mitigation |
|---|---|---|
| Backup file read by unauthorized person | Medium | Already SHA256 integrity, could add optional encryption |
| SQL injection via user input (search, names) | Low | Drift uses parameterized queries by default — verify |
| Malicious backup file (crafted ZIP bomb) | Medium | Archive library handles this? Test with 10GB decompressed ZIP |
| License bypass | Low | HMAC verification already in place — test key extraction resistance |
| Sensitive data in app sandbox | Low | Standard platform sandboxing |

### 9.2 Security Test Cases

```
✓ SQL injection: bird name with "'; DROP TABLE birds; --" → handled safely
✓ Backup bomb: ZIP that decompresses to 10GB → rejected or handled gracefully
✓ License tampering: modify stored license → detected as invalid
✓ Input sanitization: bird name with emoji, null bytes, RTL override chars
✓ File path traversal: import with "../" in filename → rejected
```

---

## 10. Regression Testing Strategy

### 10.1 Impact Analysis

Given the architecture, these changes have broadest impact:

| Change Area | Regression Scope |
|---|---|
| `database.dart` (schema, migrations) | All repositories + all services |
| `OperationService` | All write operations across all plugins |
| `PluginRegistry` | All plugin registration, routing, alert/task aggregation |
| `WeighNotifier` | Weigh screens (single + grid) |
| `AlertService` | All alerts across all plugins |
| Any table definition | Code generation (`.g.dart`) — verify no drift |

### 10.2 Regression Suites

| Suite | When to Run | Approx. Time |
|---|---|---|
| **Smoke** (10 tests) | Every commit (pre-push hook) | < 10s |
| **Core** (all L1-L2) | Every PR | < 30s |
| **Full** (all L1-L5) | Every PR to main | < 2min |
| **E2E Smoke** (3 flows) | Merge to main | < 5min on device |
| **Migration** (v12→v17) | Schema change PRs | < 30s |
| **Perf Benchmark** | Major release | < 1min |

### 10.3 Pre-Push Hook (Recommended)

```bash
#!/bin/bash
# .git/hooks/pre-push
flutter analyze && flutter test
```

---

## 11. Coverage Analysis

### 11.1 Current State

> **更新（2026-06-30）：** 测试用例从 230 增长到 **364**，全部通过。
> L4 Provider 层从 0 覆盖到有专门测试套件；L1/L2/L3 补全了 medication/breeding/drug_library/user repository
> 与 license/excel/data_transform 单元测试。覆盖率 lcov 数据受限于环境（见 `test/COVERAGE_BASELINE.md`）。

| Metric | Current | Target (Phase 6) |
|---|---|---|
| Test case count | **364** (was 230) | 持续增长 |
| Line coverage | 待修复（lcov 数据不完整） | ≥ 60% |
| Repository coverage | 8/10 已测（bird/weight/task/species/room/enclosure/user/medication/drug_library/breeding） | 100% |
| Service coverage | alert/operation/backup 已测 | 90% |
| Provider coverage | **已建立**（theme/premium/weigh/weigh_grid/providers，46 测试） | 80% |
| Widget coverage | 烟雾占位（App 构造验证） | 50% (critical screens) |
| Plugin coverage | medication/breeding repository 已测 | 60% per plugin |

### 11.2 Coverage Blind Spots

1. **Schema migrations (v1→v17):** No test verifies data survives migration.
2. **Event bus:** No test verifies events are emitted and received.
3. **Notification scheduling:** Platform API, hard to test.
4. **File I/O error paths:** Disk full, permission denied, file locked.
5. **Plugin interaction:** Alert aggregation across plugins.
6. **AppClock injection:** Debug time override not verified in tests.
7. **Chinese locale:** Date formats, number formats, string translations.

### 11.3 Coverage Exclusion

These files should be excluded from coverage metrics:
- `*.g.dart` (generated drift code)
- `*.freezed.dart` (if added)
- Test files themselves
- `main.dart` (entry point, thin wire-up)

---

## 12. Open Questions

1. **Q:** What is the expected max dataset size? (birds, weights per bird, medications)
   **Impact:** Perf test thresholds. Assume 100 birds × 1000 weights = 100k rows until specified.

2. **Q:** Should backup files be encrypted? Currently SHA256 integrity only — no confidentiality.
   **Impact:** Security test scope. If encryption added, need key management tests.

3. **Q:** What is the target platform priority? (Android first, then iOS? All simultaneously?)
   **Impact:** Integration test device matrix. Assume Android primary until specified.

4. **Q:** Are there any regulatory requirements? (Veterinary software, medical device classification?)
   **Impact:** Validation traceability. Assume none until specified.

5. **Q:** What happens when DB file is opened by a newer app version, then the user downgrades?
   **Impact:** Migration rollback tests. Current migrations are forward-only.

6. **Q:** What precision is required for dose calculations? Nearest 0.01mL? 0.001mL?
   **Impact:** Rounding test cases. Assume 0.01mL until specified.

---

## 13. Recommendations

### Immediate (Phase 0, this week)

1. **Add `mocktail` to dev_dependencies** — no codegen, tiny, covers all mocking needs.
2. **Add `flutter test` step to codemagic.yaml** — zero tests is worse than few tests.
3. **Create `test/test_helpers/test_factories.dart`** — shared factory functions to eliminate duplicated setup.

### Short-term (Phase 1-2, next 2 weeks)

4. **Write migration smoke test** — create DB at v12, run migrations to v17, verify key tables exist.
5. **Write backup round-trip test** — highest risk, highest value test.
6. **Complete repository tests for TaskRepository and WeightRepository** — most complex logic.
7. **Write dose calculation unit tests** — finite set of pure functions, high value.

### Medium-term (Phase 3-5, weeks 3-6)

8. **Widget tests for WeighScreen** — most complex UI, highest regression risk.
9. **Provider tests for WeighNotifier** — state machine correctness.
10. **Plugin-level integration tests** — verify each plugin's alert + task generation independently.

### Long-term (Phase 6, ongoing)

11. **Coverage gate at 60%** — enforce in CI.
12. **E2E smoke suite on emulator** — 3 key flows.
13. **Perf regression detection** — compare benchmarks against baseline on each release.

---

## Appendix A: File Structure (Recommended)

> **状态图例（更新于 2026-06-30）：** ✅ 已完成 / 🚧 进行中或部分 / ⬜ 待实现

```
test/
├── test_helpers/
│   ├── test_factories.dart          ✅ createTestBird/Species, setUpTestDb/tearDownTestDb, addWeightSeries
│   ├── test_clock.dart              ✅ setTestClock / resetTestClock / setTestClockWithPrefs
│   ├── test_db.dart                 ✅ dbWithBirdAndWeights 等场景构造器
│   └── test_providers.dart          ✅ (新) createProviderContainer / disposeProviderContainer — L4 基础设施
│
├── unit/                            # L1: Pure function tests
│   ├── weight_math_test.dart        ✅ logGrowth/normalize24h/ewma/isWeaningPhase 等
│   ├── dose_calculation_test.dart   ✅ mgPerKgToDose / doseToVolume
│   ├── data_transform_test.dart     ✅ (新) genUuid / genShortId
│   ├── license_verification_test.dart ✅ (新) verifyCode 格式/HMAC + activate 时间窗口
│   └── excel_format_test.dart       ✅ (新) formatWeightCell 格式规则
│
├── repositories/                    # L2: Repository tests
│   ├── bird_repository_test.dart    ✅
│   ├── weight_repository_test.dart  ✅
│   ├── task_repository_test.dart    ✅
│   ├── species_repository_test.dart ✅
│   ├── room_repository_test.dart    ✅
│   ├── enclosure_repository_test.dart ✅
│   ├── user_repository_test.dart    ✅ (新)
│   ├── medication_repository_test.dart ✅ (新) MedTaskInfo / give/skipMedication
│   ├── drug_library_repository_test.dart ✅ (新) CRUD + findBestDoseRule 优先级 + calculateDosage
│   ├── breeding_repository_test.dart ✅ (新) createPair/advanceStage/isBreeding
│   └── gallery_repository_test.dart ⬜ 待实现（依赖 GalleryRepository）
│
├── services/                        # L3: Service tests
│   ├── alert_service_test.dart      ✅
│   ├── operation_service_test.dart  ✅
│   ├── backup_service_test.dart     ✅ round-trip / 损坏文件 / 版本
│   ├── excel_export_service_test.dart ⬜ formatWeightCell 已单测；端到端导出待补
│   ├── bird_export_service_test.dart ⬜ isolate + 文件 I/O，待补
│   └── notification_service_test.dart ⬜ 平台 API，待补
│
├── providers/                       # L4: Provider/State tests
│   ├── theme_notifier_test.dart     ✅ (新)
│   ├── premium_provider_test.dart   ✅ (新)
│   ├── weigh_provider_test.dart     ✅ (新) 输入规则/导航/saveWeight
│   ├── weigh_grid_provider_test.dart ⬜ 待补（init 计算集合较重）
│   └── providers_test.dart          ✅ (新) allBirds/allSpecies/allRooms FutureProvider
│
├── widgets/                         # L5: Widget tests
│   └── (全部待实现)                  ⬜ widget_test.dart 已升级为 App 构造烟雾测试
│
├── integration/                     # L6: vm 级集成测试（非 device）
│   └── alert_service_integration_test.dart ✅ (重命名自 integration_test.dart)
│
├── perf/                            # Performance benchmarks
│   └── db_perf_test.dart            ⬜ 待实现
│
├── security/                        # Security tests
│   └── input_sanitization_test.dart ⬜ 待实现
│
├── migration/                       # Schema migration tests
│   └── migration_test.dart          ✅ v12→v17
│
├── COVERAGE_BASELINE.md             ✅ (新) 覆盖率基线与门禁策略
└── widget_test.dart                 ✅ App 构造烟雾测试（@Tags(['smoke'])）
```

## Appendix B: Dependency Changes

```yaml
# pubspec.yaml dev_dependencies additions:
dev_dependencies:
  mocktail: ^0.3.0          # Mocking (no code generation)
  # integration_test is built-in via flutter_test SDK
```

**One new dependency.** That's it. `mocktail` is chosen over `mockito` because it requires no code generation and no `build_runner` step.
