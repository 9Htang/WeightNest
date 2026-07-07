# 插件页面系统 — 需求分析及架构设计

> 2026-05-30 · branch: feature/plugin-architecture

---

## 一、场景清单

### 场景 1：药品配置页面（唯一性）

```
用户双击侧边栏 → 打开"药品配置"页面
用户再次双击侧边栏 → 不创建新页面，激活已有页面
```

**特性**：全局唯一实例。类似 VS Code 的 Settings 页 —— 永远只有一个。

### 场景 2：按体重自动计算剂量（跨插件协作）

```
鹦鹉体重 100g → 伊维菌素 0.1ml
鹦鹉体重 150g → 伊维菌素 0.15ml

公式: 剂量 = 体重 × 系数
      系数来自药品配置页面
      体重来自 WeightPlugin
```

**特性**：MedicationPlugin 需要读取 WeightPlugin 的数据。插件间不能互相 import，需要中介。

### 场景 3：称重录入页面（允许多实例）

```
用户打开鹦鹉 A 的称重页 → 一个 Tab
同时打开鹦鹉 B 的称重页 → 第二个 Tab
```

**特性**：可多实例。每个实例绑定了不同的 `birdId` 参数。

### 场景 4：喂药日历（可嵌入详情 + 可独立打开）

```
方式 1: 在鹦鹉详情页内嵌入（Slot D）
方式 2: 侧边栏点击 → 独立日历页面
```

**特性**：同一个组件可以嵌入也可以独立。需要路由参数区分模式。

### 场景 5：首页仪表盘卡片（可排序）

```
┌─ 首页 ────────────────────────┐
│  [本周异常 3 只] (Alert)       │
│  [今日待喂 2 只] (Medication)  │
│  [最近驱虫 5天前] (Deworming)  │
└───────────────────────────────┘
```

**特性**：多个插件贡献卡片，用户可拖拽排序。

---

## 二、页面类型分析

| 类型 | 唯一性 | 参数 | 示例 |
|------|:---:|------|------|
| **Singleton** | 全局唯一 | 无 | 药品配置、全局设置 |
| **SingletonPerBird** | 每只鸟一个 | birdId | 体重趋势（嵌入详情） |
| **Multi** | 允许多个 | 任意 | 称重录入（每只鸟独立） |
| **GlobalCalendar** | 全局唯一 | 日期 | 喂药日历 |
| **DashboardCard** | 嵌入首页 | 无 | 概览卡片 |

```dart
enum PageUniqueness {
  none,           // 允许多实例：称重录入
  singleton,      // 全局唯一：药品配置
  perBird,        // 每只鸟唯一（同一 birdId 不重复打开）
}
```

---

## 三、跨插件数据访问

### 问题

`MedicationPlugin` 需要读取某只鸟的最新体重：

```dart
// ❌ 不能 import weight_plugin.dart（循环依赖、紧耦合）
// ✅ 应该通过 PluginRegistry 中介
```

### 方案：共享数据总线

```dart
// plugin_registry.dart
class PluginRegistry {
  // Store shared data by key
  final _sharedData = <String, dynamic>{};

  /// Plugin A writes data
  void put<T>(String key, T data) => _sharedData[key] = data;

  /// Plugin B reads data
  T? get<T>(String key) => _sharedData[key] as T?;
}
```

```dart
// WeightPlugin — 每次称重后发布体重数据
class WeightPlugin {
  void onWeightAdded(int birdId, double weightG) {
    pluginRegistry.put('latestWeight:$birdId', weightG);
    eventBus.emit(WeightUpdated(birdId, weightG));
  }
}

// MedicationPlugin — 读取体重计算剂量
class MedicationPlugin {
  double? _calculateDosage(int birdId, double coefficient) {
    final weight = pluginRegistry.get<double>('latestWeight:$birdId');
    if (weight == null) return null;
    return (weight * coefficient).roundToDouble() / 10;
  }
}
```

### 更深层：插件数据查询接口

```dart
/// 插件可以注册查询接口供其他插件使用
abstract class FeaturePlugin {
  /// 暴露给其他插件的数据查询接口
  /// Key: 查询名称, Value: 查询函数
  Map<String, Function> get dataQueries => {};
}

// WeightPlugin
Map<String, Function> get dataQueries => {
  'getLatestWeight': (int birdId) async {
    return await pluginRegistry.db?.getLatestByBird(birdId);
  },
};

// MedicationPlugin — 通过 ID 调用
final weight = await pluginRegistry
    .getPlugin('weights')
    ?.dataQueries['getLatestWeight']?.call(birdId);
```

---

## 四、页面管理器设计

### 现状

桌面端用自建 `TabController` 体系管理页面，全部硬编码在 `desktop_layout.dart`。

### 目标

```
PluginPageManager
├── 管理所有插件的页面生命周期
├── 处理唯一性冲突
├── 支持 singleton / perBird / multi 三种模式
└── 提供: openPage / closePage / focusPage / listOpenPages
```

### 核心模型

```dart
/// A page instance contributed by a plugin
class PluginPage {
  final String id;           // unique instance id: "medication:drug-config"
  final String pluginId;     // "medication"
  final String pageKey;      // "drug-config" (the page type within the plugin)
  final int? birdId;         // optional bird context
  final PageUniqueness uniqueness;
  final Widget widget;

  PluginPage({
    required this.pluginId,
    required this.pageKey,
    this.birdId,
    required this.uniqueness,
    required this.widget,
  }) : id = '$pluginId:$pageKey${birdId != null ? ":$birdId" : ""}';
}
```

### 页面管理器

```dart
class PluginPageManager extends ChangeNotifier {
  final List<PluginPage> _pages = [];
  int _activeIndex = 0;

  List<PluginPage> get pages => List.unmodifiable(_pages);
  PluginPage? get activePage => _pages.isEmpty ? null : _pages[_activeIndex];

  /// Open a plugin page. Returns existing page if singleton/perBird conflict.
  PluginPage? openPage(PluginPage page) {
    // Check uniqueness
    if (page.uniqueness == PageUniqueness.singleton) {
      final existing = _pages.indexWhere(
        (p) => p.pluginId == page.pluginId && p.pageKey == page.pageKey);
      if (existing >= 0) {
        _activeIndex = existing;
        notifyListeners();
        return _pages[existing]; // return existing, don't create new
      }
    }
    if (page.uniqueness == PageUniqueness.perBird && page.birdId != null) {
      final existing = _pages.indexWhere(
        (p) => p.pluginId == page.pluginId && p.pageKey == page.pageKey 
            && p.birdId == page.birdId);
      if (existing >= 0) {
        _activeIndex = existing;
        notifyListeners();
        return _pages[existing];
      }
    }
    // Create new
    _pages.add(page);
    _activeIndex = _pages.length - 1;
    notifyListeners();
    return page;
  }

  void closePage(int index) {
    _pages.removeAt(index);
    if (_activeIndex >= _pages.length) _activeIndex = _pages.length - 1;
    notifyListeners();
  }

  void focusPage(int index) {
    _activeIndex = index;
    notifyListeners();
  }
}
```

---

## 五、插件页面声明

```dart
/// Describes a page type that a plugin can open
class PluginPageDescriptor {
  final String key;               // "drug-config", "weigh-enter"
  final String title;             // "药品配置", "称重录入"
  final IconData icon;
  final PageUniqueness uniqueness;
  final bool showInSidebar;       // show in desktop sidebar?
  final Widget Function(PluginPageContext ctx) builder;

  const PluginPageDescriptor({
    required this.key,
    required this.title,
    required this.icon,
    this.uniqueness = PageUniqueness.none,
    this.showInSidebar = true,
    required this.builder,
  });
}

class PluginPageContext {
  final int? birdId;
  final Map<String, dynamic> params;

  const PluginPageContext({this.birdId, this.params = const {}});
}
```

```dart
abstract class FeaturePlugin {
  // ...existing...

  /// Pages this plugin can open (sidebar / navigation entries)
  List<PluginPageDescriptor> get pages => [];

  /// Data queries exposed to other plugins
  Map<String, Function> get dataQueries => {};
}
```

---

## 六、药品配置页面 — 完整示例

### 声明

```dart
class MedicationPlugin extends FeaturePlugin {
  @override
  List<PluginPageDescriptor> get pages => [
    PluginPageDescriptor(
      key: 'drug-config',
      title: '药品配置',
      icon: Icons.medical_services,
      uniqueness: PageUniqueness.singleton,  // ← 全局唯一
      showInSidebar: true,
      builder: (ctx) => DrugConfigPage(),
    ),
    PluginPageDescriptor(
      key: 'calendar',
      title: '喂药日历',
      icon: Icons.calendar_month,
      uniqueness: PageUniqueness.none,       // ← 不限制
      showInSidebar: true,
      builder: (ctx) => MedicationCalendarView(birdId: ctx.birdId),
    ),
  ];

  @override
  Map<String, Function> get dataQueries => {
    'calculateDosage': (int birdId, String drugId) async {
      // 从 WeightPlugin 拿体重
      final weightQuery = pluginRegistry.getPlugin('weights')?.dataQueries['getLatestWeight'];
      final weight = await weightQuery?.call(birdId) as double?;
      if (weight == null) return null;
      // 查药品系数
      final drug = await pluginRegistry.db?.getDrugConfig(drugId);
      return weight * (drug?.coefficient ?? 0.001);
    },
  };
}
```

### 药品配置页面

```
┌─ 药品配置 (全局唯一) ──────────────────┐
│                                          │
│  ┌─ 药品列表 ──────────────────────┐    │
│  │ 伊维菌素  系数 0.001  每天3次   │    │
│  │ 益生菌    系数 0.01   每天1次   │    │
│  │ ＋ 添加药品                     │    │
│  └─────────────────────────────────┘    │
│                                          │
│  公式: 剂量 = 体重(g) × 系数            │
│  例: 100g × 0.001 = 0.1ml              │
│                                          │
│  添加喂药方案时自动计算建议剂量          │
└──────────────────────────────────────────┘
```

### 唯一性行为

```
用户双击侧边栏"药品配置"：
  → pluginPageManager.openPage(drugConfigPage)
  → 已存在同 pluginId + pageKey → focusPage(0)
  → 不创建新页面

用户点击鹦鹉 A 的"称重"：
  → openPage(weighPage, birdId: 1)
  → 检查 perBird(1) 不存在 → 创建新页面

用户再次点击鹦鹉 A 的"称重"：
  → openPage(weighPage, birdId: 1)
  → 已存在 perBird(1) → focusPage(existing)
```

---

## 七、侧边栏改造

```
当前（硬编码）:
  [概览] [操作日志] [鹦鹉档案] [人员管理] [房间管理] [品种配置]
  ──────── 底部操作区 ────────
  [插件管理] [扫码登录] [刷新] [收起]

改造后:
  ┌─ 主菜单（固定）────────────┐
  │ [仪表盘] [鹦鹉档案]         │
  ├─ 插件页面（动态）──────────┤
  │ [药品配置] 🅂 ← singleton   │
  │ [喂药日历]                  │
  │ [称重录入]                  │
  ├─ 设置（固定）──────────────┤
  │ [人员管理] [房间管理]        │
  │ [品种配置]                  │
  └────────────────────────────┘
  ──────── 底部操作区 ────────
  [插件管理] [扫码登录] [刷新] [收起]
```

`🅂` = singleton 标识（页面上方有一个小点表示已打开）

---

## 八、实施计划

| 阶段 | 内容 | 时间 |
|------|------|------|
| **I** | `PluginPageDescriptor` + `PluginPageManager` + `PageUniqueness` 数据模型 | 30 min |
| **II** | 改造 `desktop_layout.dart`：TabController → PluginPageManager | 2 h |
| **III** | 跨插件数据查询接口 `dataQueries` | 30 min |
| **IV** | MedicationPlugin 实现 `DrugConfigPage` + 按体重自动计算 | 2 h |
| **V** | WeightPlugin 暴露 `getLatestWeight` 查询 | 15 min |
| **VI** | 侧边栏动态渲染插件页面 | 1 h |

---

## 九、结论

```
药品配置页面 (singleton):
  双击 → 打开 (首次) / 聚焦 (已存在) — 永远只有一个

剂量自动计算 (跨插件):
  WeightPlugin 暴露 getLatestWeight
  MedicationPlugin 调用 → 体重 × 系数 → 建议剂量
  中间通过 PluginRegistry 解耦

称重页面 (perBird):
  每只鸟独立的称重页面 — 同一只鸟不重复打开
```

要我开始实施 Phase I（数据模型 + 页面管理器）吗？
