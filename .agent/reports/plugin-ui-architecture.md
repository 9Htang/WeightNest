# 插件 UI 架构设计报告

> 2026-05-30 · branch: feature/plugin-architecture

---

## 一、核心问题

不同插件需要**完全不同**的 UI 形态，不能一刀切：

| 插件 | 需要什么 UI | 典型交互 |
|------|------------|---------|
| 称重 | 趋势折线图 + 记录列表 + 录入表单 | 选中鸟 → 看图 → 录入 |
| 喂药 | **类日历视图**（每天几次、是否完成） | 日历选天 → 勾选完成/跳过 |
| 驱虫 | 一次性记录 + 下次提醒 | 日期选择 → 备注 → 设置提醒 |
| 体检 | 表单 + 历史对照 + 指标异常标红 | 填数值 → 看趋势 → 标异常 |
| 繁殖 | 配对记录 + 产蛋/孵化时间线 | 时间线 → 状态流转 |

**结论：插件必须决定自己的 UI，主 app 只提供"插槽"。**

---

## 二、四种 UI 插槽（Slots）

```
┌─ 主 App ─────────────────────────────────────┐
│                                                │
│  ┌ 导航区 ──────────────────────────┐          │
│  │ Slot A: 主 Tab / 独立页面        │          │
│  └─────────────────────────────────┘          │
│                                                │
│  ┌ 详情页 ──────────────────────────┐         │
│  │ 基本信息（主 app 负责）          │          │
│  │ ┌ Slot B ───────────────────┐   │          │
│  │ │ 插件贡献的卡片/图表/组件   │   │          │
│  │ └───────────────────────────┘   │          │
│  └─────────────────────────────────┘          │
│                                                │
│  ┌ 首页仪表盘 ────────────────────┐           │
│  │ ┌ Slot C ──────────┐           │           │
│  │ │ 插件贡献的概览卡  │           │           │
│  │ └─────────────────┘           │           │
│  └───────────────────────────────┘            │
│                                                │
│  ┌ Slot D: 独立日历/时间线视图 ────┐          │
│  │ 喂药、驱虫、体检等时间驱动插件  │          │
│  └─────────────────────────────────┘          │
└────────────────────────────────────────────────┘
```

### Slot A: 独立页面
- 插件提供一个完整的 `Widget`
- 主 app 在导航中挂载
- 适用：称重录入页、喂药管理页

### Slot B: 详情嵌入
- 插件提供 `Widget Function(int birdId)` — 传入鸟 ID，返回组件
- 主 app 在鹦鹉详情页中渲染
- 适用：体重图表嵌入详情、喂药今日任务嵌入详情

### Slot C: 首页概览卡片
- 插件提供 `Widget` — 无参数，展示全局概览
- 主 app 在仪表盘中渲染
- 适用："今日待喂药 3 只"、"本周体重异常 2 只"

### Slot D: 日历/时间线视图
- 插件提供 `Widget Function(DateTime day)` — 按天查询
- 主 app 提供日历选择器框架，插件只负责**某一天的内容**
- 适用：喂药日历（哪天喂了几次，是否完成）

---

## 三、喂药日历 UI 设计

这是最复杂也最有代表性的插件 UI。

### 交互原型

```
┌─ 喂药管理 ────────────────────────────────┐
│                                            │
│  ← 2026年 5月 →                            │
│  ┌─ 日历 ────────────────────────────┐    │
│  │ 一  二  三  四  五  六  日        │    │
│  │             1   2   3   4          │    │
│  │ 5   6   7   8   9   10  11         │    │
│  │         ●8  ●14 ●20               │    │
│  │12  13  14  15  16  17  18         │    │
│  │     ✅8  ✅14 ⚠️20                 │    │
│  │                                    │    │
│  │ ✅=已完成  ⚠️=待完成  ●=计划时间   │    │
│  └────────────────────────────────────┘    │
│                                            │
│  ┌─ 5月14日 喂药详情 ───────────────┐     │
│  │ 🐦 小绿                             │    │
│  │ 💊 伊维菌素 0.2ml  每天 3 次       │    │
│  │                                    │    │
│  │ 8:00   ✅ 已完成  张师傅 08:05    │    │
│  │ 14:00  ✅ 已完成  张师傅 14:02    │    │
│  │ 20:00  ⚠️ 待完成                  │    │
│  └────────────────────────────────────┘    │
└────────────────────────────────────────────┘
```

### 实现方式

主 app 提供一个**日历框架**，插件只需要实现"某一天的内容"：

```dart
// plugin.dart — Slot D 接口
abstract class FeaturePlugin {
  // ...existing...

  /// Slot D: 日历视图。返回某一天的内容组件。
  /// [day] — 选中的日期
  /// [birdId] — 可选，限定某只鸟
  /// 返回 null 表示该插件不使用日历视图
  Widget? buildDayView(AppDatabase db, DateTime day, {int? birdId});

  /// Slot D 日历的标题
  String? get calendarTitle => null;
}

// medication_plugin.dart
class MedicationPlugin extends FeaturePlugin {
  @override
  Widget? buildDayView(AppDatabase db, DateTime day, {int? birdId}) {
    return MedicationDayView(db: db, day: day, birdId: birdId);
  }

  @override
  String get calendarTitle => '喂药记录';
}
```

`MedicationDayView` 是插件自己完全控制的 Widget — 表格、图表、按钮，想怎么画就怎么画。主 app 只提供日期选择器和切换插件下拉框。

---

## 四、所有 Slot 的接口设计

```dart
abstract class FeaturePlugin {
  String get id;
  String get displayName;
  String get description;
  bool enabled;

  // === Slot A: 独立页面 ===
  Map<String, WidgetBuilder> routes(AppDatabase db);

  // === Slot B: 详情嵌入（鹦鹉详情页内的卡片） ===
  /// 返回 null 表示不嵌入详情
  Widget? buildDetailCard(AppDatabase db, int birdId) => null;

  // === Slot C: 首页概览卡片 ===
  Widget? buildDashboardCard(AppDatabase db) => null;

  // === Slot D: 日历视图 ===
  Widget? buildDayView(AppDatabase db, DateTime day, {int? birdId}) => null;
  String? get calendarTitle => null;

  // === Server ===
  shelf.Router? serverRoutes(AppDatabase db);

  // === 事件 ===
  void registerEvents(EventBus bus) {}
}
```

### 各插件实现情况

| Plugin | Slot A (独立页) | Slot B (嵌入详情) | Slot C (首页卡片) | Slot D (日历) |
|--------|:---:|:---:|:---:|:---:|
| Weight | 称重录入页 | 体重趋势图 ✅ 已实现 | "本周异常 3 只" | — |
| Medication | 方案管理页 | "今日待喂 2 次" | "今日待喂 3 只" | **喂药日历** |
| Deworming (未来) | 驱虫记录页 | 最近驱虫时间 | 下次驱虫提醒 | 驱虫历史日历 |
| HealthCheck (未来) | 体检录入表单 | 体检指标变化 | 本周需体检 | 体检历史日历 |

---

## 五、鹦鹉档案页改造方案

当前 `bird_archive_screen.dart` 的详情部分是硬编码的：

```
当前:
  基本信息卡片 → _buildInfoCard()
  体重趋势图   → WeightChartWidget
  体重记录表   → _buildWeightTable()

改造后:
  基本信息卡片 → 主 app 负责
  ┌─ 插件插槽 ──────────────────────┐
  │ WeightPlugin.buildDetailCard()   │ ← 体重趋势图
  │ MedicationPlugin.buildDetailCard()│ ← 今日喂药
  │ DewormingPlugin.buildDetailCard()│ ← 最近驱虫
  │ ...更多插件自动出现...           │
  └─────────────────────────────────┘
```

代码变化：

```dart
// bird_archive_screen.dart — 改造后
Widget _buildDetail(ThemeData theme) {
  return Column(children: [
    _buildInfoCard(theme, bird),
    const SizedBox(height: 20),
    // 动态渲染所有插件的详情卡片
    ...pluginRegistry.enabledPlugins
        .map((p) => p.buildDetailCard(db, bird.id))
        .whereType<Widget>(),
  ]);
}
```

**加新插件 = 自动出现在每只鸟的详情页，零改动。**

---

## 六、实施计划

| 阶段 | 内容 | 时间 |
|------|------|------|
| **Phase A** | 接口扩展：`buildDetailCard` + `buildDashboardCard` + `buildDayView` | 30 min |
| **Phase B** | WeightPlugin 实现 `buildDetailCard`（把 `WeightChartWidget` 装进去） | 1 h |
| **Phase C** | MedicationPlugin 实现日历视图 + `buildDetailCard` | 2 h |
| **Phase D** | 鹦鹉档案页改造为动态插槽渲染 | 1 h |
| **Phase E** | 首页仪表盘动态卡片 | 1 h |

---

## 七、推荐下一步

1. **先扩展 FeaturePlugin 接口** — 加 Slot B/C/D
2. **把 WeightPlugin 的图表装进 `buildDetailCard`** — 验证详情嵌入可行
3. **做 MedicationPlugin 的日历 UI** — 这是你想要的，也是最复杂的
4. **改造鹦鹉档案页** — 从硬编码变动态插槽

要我开始做 Phase A + B 吗？
