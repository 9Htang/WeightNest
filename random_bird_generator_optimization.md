# 随机生成鸟数据 — 算法优化方案

## 一、当前代码及局限

**文件**：`lib/plugins/debug/debug_dashboard_screen.dart:206-378`

```dart
// 当前 _generate() 核心逻辑
// 1. 所有鸟塞进同一个房间+同一个容器
// 2. 年龄 60~760 天，无雏鸟、无极端老龄
// 3. 体重以基准值 ±6% 均匀随机 — 不会触发任何异常告警
// 4. 没有喂药方案 → missed_medication 永远不触发
```

---

## 二、全部告警类型及触发条件

### WeightPlugin（称重插件）

| 告警类型 | 严重度 | 触发条件 | 需要的数据特征 |
|---|---|---|---|
| `超期未称重` | warning | `daysSince > interval × 1.5` | 末次称重距今 > 称重周期 × 1.5 |
| `超期未称重` | danger | `daysSince > interval × 3.0` | 末次称重距今 > 称重周期 × 3 |
| `体重下降` | danger | 48h 窗口内下降超 15% | 雏鸟 48h 内体重骤降 |
| `体重下降` | warning | 最近一对下降 5%+ | 雏鸟最近两次称重下降 |
| `连续下降` | warning | 连续 ≥3 次下降 | 雏鸟连续多天体重降 |
| `连续下降` | danger | 连续 ≥4 次下降 | 雏鸟连续多天体重降 |
| `生长缓慢` | warning | 生长率 < 品种基准 × 0.5 | 雏鸟体重增长显著低于同龄 |
| `体重异常偏高/偏低` | warning | 偏离基线 10~15% | 成鸟最近体重偏离基线 |
| `体重异常偏高/偏低` | danger | 偏离基线 > 15% | 成鸟最近体重偏离基线 |
| `断奶体重骤降` | warning | 断奶期下降 10~15% | 断奶期鸟体重下降 |
| `断奶体重骤降` | danger | 断奶期下降 > 15% | 断奶期鸟体重骤降 |
| `长期无数据` | danger | 90 天内无体重记录 | 创建了但从未称重的鸟 |

**称重周期**（取决于生命阶段，`weight_plugin.dart _effectiveInterval`）：
- 雏鸟：`species.nestlingWeighIntervalDays`（默认 1 天）
- 幼鸟：`species.juvenileWeighIntervalDays`（默认 3 天）
- 成鸟：`species.adultWeighIntervalDays`（默认 7 天）

### MedicationPlugin（喂药插件）

| 告警类型 | 严重度 | 触发条件 | 需要的数据特征 |
|---|---|---|---|
| `missed_medication` | warning | 今日有待完成的喂药任务，且 dueDate 已过 | 有活跃喂药方案的鸟 |

---

## 三、优化算法设计

### 3.1 房间/容器自动布局

```
规则：count ≤ 3 → 1 房间 1 容器
      3 < count ≤ 10 → 3 房间，每房间 2 容器
      count > 10 → 5 房间，每房间 3 容器
鸟均匀分配到各容器的各房间
```

### 3.2 生命阶段分布

```
雏鸟 (0 ~ nestlingEnd 天)：    20% 的鸟  → 测 chick_growth / 体重下降
幼鸟 (nestlingEnd ~ juvenileEnd)：25%  → 测断奶异常
成年 (juvenileEnd ~ 2年)：        40%  → 测基线偏离 / 超期未称重
老年 (> 2年，无近期数据)：        15%  → 测 90 天无数据 / 超期未称重
```

### 3.3 体重数据策略（触发异常）

按鸟的角色分类生成不同体重模式：

**A. 正常成年鸟（40%）**：最近一次称重 12 天前（周期 7 天 → overdue warning）
**B. 严重超期成年鸟（15%）**：最近一次称重 25 天前（周期 7 天 → overdue danger）
**C. 正常雏鸟（10%）**：每天称重，体重稳定增长
**D. 体重下降雏鸟（5%）**：连续 4 天体重下降 → 触发连续下降 danger
**E. 生长缓慢雏鸟（5%）**：增长率仅为基准 30% → 触发生长缓慢 warning
**F. 断奶幼鸟（10%）**：体重从峰值骤降 18% → 触发断奶 danger
**G. 基线偏离成鸟（10%）**：最近体重偏离基线 18% → 触发基线偏离 danger
**H. 无数据鸟（5%）**：不生成体重记录 → 触发 90 天无数据 danger

### 3.4 喂药方案

为 20% 的成年鸟创建活跃喂药方案（timesPerDay=1，startDate 在今天之前），配合 `generateTodayTasks` 即可生成到期未完成的喂药任务 → 触发 missed_medication。

---

## 四、完整优化代码

替换 `lib/plugins/debug/debug_dashboard_screen.dart` 中第 206-378 行的 `_RandomBirdSheet` 类：

```dart
// ── Random bird data generator ──

const _randomNames = [
  '小蓝', '绿豆', '黄豆', '花花', '阿宝',
  '皮皮', '球球', '小白', '大头', '妞妞',
  '萌萌', '豆豆', '乐乐', '欢欢', '圆圆',
  '雪儿', '金金', '大宝', '灰灰', '翠花',
];

const _drugNames = ['阿莫西林', '益生菌', '钙磷粉', '维生素B', '驱虫药'];
const _drugTypes = ['抗生素', '益生菌', '营养补充', '维他命', '驱虫'];

enum _BirdRole {
  normalAdult,      // 正常成年 — 超期 warning
  severeOverdue,    // 严重超期 — 超期 danger
  normalChick,      // 正常雏鸟 — 无告警
  decliningChick,   // 体重下降雏鸟 — 连续下降 danger
  slowGrowthChick,  // 生长缓慢雏鸟 — 生长缓慢 warning
  weaningDrop,      // 断奶骤降 — 断奶 danger
  baselineOutlier,  // 基线偏离 — 基线偏离 danger
  noData,           // 无数据 — 90 天无数据 danger
}

class _RandomBirdSheet extends StatefulWidget {
  const _RandomBirdSheet();
  @override
  State<_RandomBirdSheet> createState() => _RandomBirdSheetState();
}

class _RandomBirdSheetState extends State<_RandomBirdSheet> {
  final _countCtl = TextEditingController(text: '20');
  bool _generating = false;

  @override
  void dispose() {
    _countCtl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final db = pluginRegistry.db;
    if (db == null) return;
    final count = int.tryParse(_countCtl.text.trim()) ?? 20;
    final clamped = count.clamp(1, 100);

    setState(() => _generating = true);
    try {
      final rng = Random();
      final now = AppClock.now;

      // ── 1. 确保品种 ──
      var speciesList = await db.getAllSpecies();
      if (speciesList.length < 3) {
        final defaults = [
          ('虎皮鹦鹉', 30, 90, 1, 3, 7),
          ('玄凤鹦鹉', 45, 120, 1, 3, 7),
          ('牡丹鹦鹉', 35, 100, 1, 3, 7),
          ('金太阳', 50, 130, 1, 3, 5),
          ('金刚鹦鹉', 60, 180, 1, 5, 10),
        ];
        for (final (name, ne, je, ni, ji, ai) in defaults) {
          final exists = speciesList.any((s) => s.name == name);
          if (!exists) {
            await db.createSpecies(name,
              nestlingEndDays: ne, juvenileEndDays: je,
              nestlingWeighIntervalDays: ni,
              juvenileWeighIntervalDays: ji,
              adultWeighIntervalDays: ai);
          }
        }
        speciesList = await db.getAllSpecies();
      }

      // ── 2. 自动布局房间和容器 ──
      final roomCount = clamped <= 3 ? 1 : (clamped <= 10 ? 3 : 5);
      final enclPerRoom = clamped <= 3 ? 1 : (clamped <= 10 ? 2 : 3);

      var rooms = await db.getAllRooms();
      while (rooms.length < roomCount) {
        await db.createRoom('繁殖舍${rooms.length + 1}');
        rooms = await db.getAllRooms();
      }
      rooms = rooms.take(roomCount).toList();

      final enclosures = <Enclosure>[];
      for (final room in rooms) {
        var roomEncs = await db.getEnclosuresByRoom(room.id);
        while (roomEncs.length < enclPerRoom) {
          final label = String.fromCharCode(65 + roomEncs.length); // A, B, C...
          await db.createEnclosure('${label}区', room.id);
          roomEncs = await db.getEnclosuresByRoom(room.id);
        }
        enclosures.addAll(roomEncs.take(enclPerRoom));
      }

      // ── 3. 分配角色 ──
      final roleWeights = {
        _BirdRole.normalAdult: 0.35,
        _BirdRole.severeOverdue: 0.10,
        _BirdRole.normalChick: 0.10,
        _BirdRole.decliningChick: 0.05,
        _BirdRole.slowGrowthChick: 0.05,
        _BirdRole.weaningDrop: 0.15,
        _BirdRole.baselineOutlier: 0.10,
        _BirdRole.noData: 0.10,
      };
      final roleList = <_BirdRole>[];
      for (final entry in roleWeights.entries) {
        final n = (clamped * entry.value).round();
        roleList.addAll(List.filled(n, entry.key));
      }
      roleList.shuffle(rng);
      while (roleList.length < clamped) {
        roleList.add(_BirdRole.normalAdult);
      }

      // ── 4. 生成鸟和体重 ──
      final genders = ['公', '母', '未知'];
      int generatedWithMeds = 0;
      final targetMeds = (clamped * 0.2).ceil();

      for (int i = 0; i < clamped; i++) {
        final role = roleList[i];
        final enclosure = enclosures[i % enclosures.length];
        final species = speciesList[rng.nextInt(speciesList.length)];
        final name = '${_randomNames[rng.nextInt(_randomNames.length)]}${rng.nextInt(100)}';
        final gender = genders[rng.nextInt(genders.length)];

        // 根据角色计算出生日期
        final birth = _birthForRole(role, species, now, rng);

        final bird = await db.createBird(
          name: name,
          speciesId: species.id,
          birthDate: birth,
          roomId: enclosure.roomId,
          enclosureId: enclosure.id,
          gender: gender,
        );

        // 根据角色生成体重历史
        await _generateWeights(db, bird, species, role, now, rng);

        // 20% 的成年鸟创建喂药方案
        if (generatedWithMeds < targetMeds &&
            (role == _BirdRole.normalAdult || role == _BirdRole.severeOverdue)) {
          await _createMedication(db, bird, now, rng);
          generatedWithMeds++;
        }
      }

      // ── 5. 为所有鸟生成今日任务（触发 overdue 标记和 missed_medication 检测） ──
      await db.generateTodayTasks(force: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '已生成 $clamped 只鸟\n'
            '房间: $roomCount × 容器: $enclPerRoom/间\n'
            '角色分布: ${_roleSummary(roleList)}\n'
            '喂药方案: $generatedWithMeds',
          )),
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      debugPrint('RandomBird error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ── Helpers ──

  DateTime _birthForRole(_BirdRole role, Specy species, DateTime now, Random rng) {
    final ne = species.nestlingEndDays;
    final je = species.juvenileEndDays;
    return switch (role) {
      _BirdRole.normalChick ||
      _BirdRole.decliningChick ||
      _BirdRole.slowGrowthChick => now.subtract(Duration(days: rng.nextInt(ne ~/ 2) + 5)),
      _BirdRole.weaningDrop => now.subtract(Duration(days: ne + rng.nextInt((je - ne) ~/ 2))),
      _BirdRole.normalAdult ||
      _BirdRole.baselineOutlier => now.subtract(Duration(days: je + 60 + rng.nextInt(500))),
      _BirdRole.severeOverdue ||
      _BirdRole.noData => now.subtract(Duration(days: je + 400 + rng.nextInt(600))),
    };
  }

  Future<void> _generateWeights(
    AppDatabase db, Bird bird, Specy species,
    _BirdRole role, DateTime now, Random rng,
  ) async {
    final ne = species.nestlingEndDays;
    final je = species.juvenileEndDays;
    final ageDays = now.difference(bird.birthDate).inDays;
    final interval = ageDays < ne ? 1 : (ageDays < je ? 3 : 7);
    final baseWeight = _baseWeight(species.name);

    switch (role) {
      case _BirdRole.normalAdult:
        // 稳定基线，末次 12 天前 → overdue warning（周期 7 天）
        for (int d = 60; d >= 0; d -= interval) {
          if (d < interval && d > 0) continue; // skip to create gap
          final day = now.subtract(Duration(days: d));
          if (d > 12) {
            await _insertWeight(db, bird.id, baseWeight + (rng.nextDouble() - 0.5) * baseWeight * 0.04, day, rng);
          }
        }
        // 最后一笔是 12 天前

      case _BirdRole.severeOverdue:
        // 末次 25 天前 → overdue danger
        for (int d = 80; d >= 0; d -= interval) {
          final day = now.subtract(Duration(days: d));
          if (d > 25) {
            await _insertWeight(db, bird.id, baseWeight + (rng.nextDouble() - 0.5) * baseWeight * 0.04, day, rng);
          }
        }

      case _BirdRole.normalChick:
        // 每天称重，稳定增长
        double w = baseWeight * 0.3; // 初生体重约成体 30%
        final totalDays = ageDays.clamp(1, 60);
        for (int d = totalDays; d >= 0; d--) {
          final day = now.subtract(Duration(days: d));
          final growRatio = 1.0 - (d / totalDays) * 0.7;
          w = baseWeight * (0.3 + growRatio * 0.4) + (rng.nextDouble() - 0.5) * baseWeight * 0.03;
          await _insertWeight(db, bird.id, w, day, rng);
        }

      case _BirdRole.decliningChick:
        // 前 5 天正常增长，后 4 天连续下降
        double w = baseWeight * 0.35;
        final totalDays = ageDays.clamp(5, 30);
        for (int d = totalDays; d >= 5; d--) {
          final day = now.subtract(Duration(days: d));
          w = baseWeight * 0.5 + (rng.nextDouble() - 0.5) * baseWeight * 0.03;
          await _insertWeight(db, bird.id, w, day, rng);
        }
        // 连续 4 天下降
        for (int d = 4; d >= 0; d--) {
          w -= baseWeight * 0.04; // 每天降 4%
          final day = now.subtract(Duration(days: d));
          await _insertWeight(db, bird.id, w.clamp(1, 2000), day, rng);
        }

      case _BirdRole.slowGrowthChick:
        // 增长率仅为基准 30%
        double w = baseWeight * 0.3;
        final totalDays = ageDays.clamp(5, 45);
        for (int d = totalDays; d >= 0; d--) {
          final day = now.subtract(Duration(days: d));
          w += baseWeight * 0.005; // 极慢增长
          await _insertWeight(db, bird.id, w.clamp(1, 2000), day, rng);
        }

      case _BirdRole.weaningDrop:
        // 生长到峰值后骤降 18%
        double w = baseWeight * 0.3;
        final totalDays = ageDays.clamp(10, 60);
        final peakDay = totalDays - 7;
        for (int d = totalDays; d >= 0; d--) {
          final day = now.subtract(Duration(days: d));
          if (d > peakDay) {
            w += baseWeight * (0.7 / peakDay);
          } else {
            w -= baseWeight * (0.18 / 7); // 7 天内降 18%
          }
          await _insertWeight(db, bird.id, w.clamp(1, 2000), day, rng);
        }

      case _BirdRole.baselineOutlier:
        // 先建立 60 天稳定基线，最近一笔偏离 18%
        for (int d = 60; d >= 0; d -= interval) {
          final day = now.subtract(Duration(days: d));
          final v = d == 0
              ? baseWeight * 1.18 // 最近一笔偏高 18% → danger
              : baseWeight + (rng.nextDouble() - 0.5) * baseWeight * 0.03;
          await _insertWeight(db, bird.id, v, day, rng);
        }

      case _BirdRole.noData:
        // 不生成体重 → 触发 90 天无数据
        break;
    }
  }

  Future<void> _insertWeight(AppDatabase db, int birdId, double weightG, DateTime day, Random rng) async {
    await db.into(db.weights).insert(WeightsCompanion.insert(
      uuid: genUuid(),
      birdId: birdId,
      weightG: double.parse(weightG.toStringAsFixed(1)),
      recordedAt: DateTime(day.year, day.month, day.day, 8 + rng.nextInt(10), rng.nextInt(60)),
      recordedBy: const Value(0),
    ));
  }

  Future<void> _createMedication(AppDatabase db, Bird bird, DateTime now, Random rng) async {
    try {
      final drugIdx = rng.nextInt(_drugNames.length);
      await db.addMedication(
        birdId: bird.id,
        drugName: _drugNames[drugIdx],
        drugType: _drugTypes[drugIdx],
        dosage: '${(0.1 + rng.nextDouble() * 0.5).toStringAsFixed(1)}ml',
        timesPerDay: 1,
        startDate: now.subtract(const Duration(days: 3)),
      );
    } catch (_) {
      // 方案创建失败不影响主流程
    }
  }

  double _baseWeight(String speciesName) => switch (speciesName) {
    '虎皮鹦鹉' => 35.0,
    '玄凤鹦鹉' => 95.0,
    '牡丹鹦鹉' => 50.0,
    '金太阳' => 130.0,
    '金刚鹦鹉' => 1100.0,
    _ => 80.0,
  };

  String _roleSummary(List<_BirdRole> roles) {
    final counts = <_BirdRole, int>{};
    for (final r in roles) { counts[r] = (counts[r] ?? 0) + 1; }
    return counts.entries.map((e) => '${_roleLabel(e.key)}:${e.value}').join(' ');
  }

  String _roleLabel(_BirdRole r) => switch (r) {
    _BirdRole.normalAdult => '正常成鸟',
    _BirdRole.severeOverdue => '严重超期',
    _BirdRole.normalChick => '正常雏鸟',
    _BirdRole.decliningChick => '下降雏鸟',
    _BirdRole.slowGrowthChick => '慢长雏鸟',
    _BirdRole.weaningDrop => '断奶骤降',
    _BirdRole.baselineOutlier => '基线偏离',
    _BirdRole.noData => '无数据',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('随机生成鸟数据',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('涵盖 8 种角色，触发全部异常类型',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
            const SizedBox(height: 12),
            TextField(
              controller: _countCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '生成数量（推荐 ≥20）',
                helperText: '自动布局房间容器，按角色分配，生成体重 + 喂药方案',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.casino, size: 18),
              label: Text(_generating ? '生成中…' : '生成'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
```

### 需要的额外 import

在 `debug_dashboard_screen.dart` 顶部已有 `dart:math` 和 `database.dart`。需确认包含：

```dart
import '../../plugins/medication/medication_repository.dart';
```

因为 `db.addMedication(...)` 是 `MedicationRepository` extension。

---

## 五、优化后的提示词（发给更好的模型）

将以下内容直接粘贴给模型：

```
你是一个 Flutter/Dart 专家。请在 WeightNest 项目的调试插件中优化随机鸟数据生成器。
文件位置：lib/plugins/debug/debug_dashboard_screen.dart 的 _RandomBirdSheet 类。

目标：生成 N 只鸟（N 可配置），覆盖所有生命阶段，自动触发全部 7 种异常告警。

## 异常告警触发条件速查

1. 超期未称重 warning：末次称重距今 > 称重周期 × 1.5
2. 超期未称重 danger：末次称重距今 > 称重周期 × 3.0
3. 体重下降 danger：雏鸟 48h 窗口下降 15%+
4. 连续下降 danger：雏鸟连续 4 次下降
5. 生长缓慢 warning：雏鸟增长率 < 品种基准 50%
6. 断奶体重骤降 danger：断奶期下降 15%+
7. 体重异常偏高/偏低 danger/warning：成鸟偏离基线 15%/10%
8. 长期无数据 danger：90 天无体重记录
9. 漏喂药物 warning：有待完成喂药任务且 dueDate 已过

称重周期按生命阶段：雏鸟 1 天，幼鸟 3 天，成鸟 7 天。

## 角色分配（建议比例）

- 正常成年鸟 35% — 末次称重 12 天前 → 触发超期 warning
- 严重超期 10% — 末次称重 25 天前 → 触发超期 danger
- 正常雏鸟 10% — 每天称重，稳定增长
- 体重下降雏鸟 5% — 前 5 天增长，后 4 天持续下降 → 连续下降 danger
- 生长缓慢雏鸟 5% — 增长率仅为基准 30%
- 断奶骤降 15% — 生长到峰值后骤降 18% → 断奶 danger
- 基线偏离 10% — 60 天稳定基线，最近偏离 18% → 偏离 danger
- 无数据 10% — 不生成体重 → 长期无数据 danger

## 房间/容器布局

count ≤ 3：1 房间 1 容器
3 < count ≤ 10：3 房间，每间 2 容器
count > 10：5 房间，每间 3 容器
鸟均匀分配到各容器。

## 喂药方案

为 20% 的成年鸟创建活跃喂药方案（addMedication，timesPerDay=1，startDate=3天前）。
生成完成后调用 db.generateTodayTasks(force: true) 触发逾期标记。

## 已有基础代码

项目使用 Riverpod + Drift 数据库。可用的 extension 方法：
- db.getAllSpecies() / db.createSpecies(...) — species_repository.dart
- db.getAllRooms() / db.createRoom(...) — room_repository.dart
- db.getEnclosuresByRoom(roomId) / db.createEnclosure(...) — enclosure_repository.dart
- db.createBird(...) — bird_repository.dart
- db.addMedication(...) — medication_repository.dart
- db.generateTodayTasks(force: true) — task_repository.dart
- db.into(db.weights).insert(WeightsCompanion.insert(...)) — 体重插入

当前代码见 debug_dashboard_screen.dart 第 206-378 行。请基于此优化。
```

---

## 六、相关文件清单

| 文件 | 作用 |
|---|---|
| `lib/plugins/debug/debug_dashboard_screen.dart` | **主改文件** — `_RandomBirdSheet` 类 |
| `lib/plugins/weight/weight_plugin.dart` | 告警检测逻辑 — 称重逾期、雏鸟生长、断奶、基线偏离 |
| `lib/plugins/medication/medication_plugin.dart` | 告警检测逻辑 — 漏喂药物 |
| `lib/plugins/medication/medication_repository.dart` | `addMedication()` API |
| `lib/repositories/bird_repository.dart` | `createBird()` API |
| `lib/repositories/species_repository.dart` | `getAllSpecies()` / `createSpecies()` |
| `lib/repositories/room_repository.dart` | `getAllRooms()` / `createRoom()` |
| `lib/repositories/enclosure_repository.dart` | `getEnclosuresByRoom()` / `createEnclosure()` |
| `lib/repositories/task_repository.dart` | `generateTodayTasks()` |
