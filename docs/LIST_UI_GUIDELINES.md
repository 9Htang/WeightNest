# 列表 UI 组件规范

本文档定义了 WeightNest 项目中业务列表页的统一 UI 规范，确保视觉一致性和可维护性。

## 通用组件一览

| 组件 | 路径 | 用途 |
|------|------|------|
| `AppListCard` | `lib/widgets/list/app_list_card.dart` | 列表项卡片（3 种变体） |
| `AppListScaffold` | `lib/widgets/list/app_list_scaffold.dart` | 列表页骨架（loading/error/empty/list 四态） |
| `EmptyState` | `lib/widgets/list/empty_state.dart` | 统一空状态视图 |
| `FilterChipBar` | `lib/widgets/list/filter_chip_bar.dart` | 横向单选筛选行 |
| `CategoryColors` | `lib/theme/category_colors.dart` | 业务分类色 → ColorScheme 映射 |

---

## AppListCard — 列表项卡片

### 视觉规范

| 属性 | 值（带 leading） | 值（无 leading） | Token |
|------|------------------|-----------------|-------|
| borderRadius | **0（直角）** | **0（直角）** | — |
| 容器 | `Card`（shape 直角） | 同左 | `surfaceContainerLow + outlineVariant描边` |
| margin | `h:12, v:4` | 同左 | `sp.cardMargin` |
| 左侧色块 | **80px 宽，高度撑满卡片** | 无 | — |
| 内容区 padding | `l:12, t:8, r:8, b:8` | `all:8` | `sp.paddingSm` |
| subtitle 间距 | `4` | `4` | `sp.xs` |

### 布局示意（带 leading）

```
┌────────────────────────────────┐
│ ████████████████████ │ 标题     │
│ ████████ 图标 ██████ │ 副标题   │
│ ████████████████████ │          │
└────────────────────────────────┘
  ← 80px 宽 →  ← 内容区 →
  直角（borderRadius: 0）
```

### 圆角控制

- `AppListCard(...)` 和 `AppListCard.icon(...)` 默认 `sharp: true`（直角）
- `AppListCard.tile(...)` 默认 `sharp: false`（保持全局 cardTheme 圆角 16）
- 全局 CardTheme 不受影响（对话框、输入框等仍为圆角）

### 三种用法

```dart
// 1. 通用 slot — 自由组合（带 leading → 左侧 80px 撑满）
AppListCard(
  leading: myAvatar,  // 80px 宽 widget，高度撑满卡片
  title: Text(name),
  subtitle: Text(desc),
  trailing: Icon(Icons.chevron_right),
  onTap: () => ...,
);

// 2. 图标头部 — 自动 80px 分类色背景，图标居中，高度撑满
final (fg, bg) = CategoryColors.forCategory(scheme, '疾病');
AppListCard.icon(
  icon: Icons.coronavirus,
  iconTint: fg,
  iconBg: bg,
  title: Text(diseaseName),
  subtitle: Text(description),
  trailing: IconButton(...),
  onTap: () => ...,
);

// 3. ListTile 风格 — 简单行（sharp: false 保持圆角）
AppListCard.tile(
  leading: Icon(Icons.meeting_room),
  title: Text(roomName),
  subtitle: Text('点击查看'),
  trailing: PopupMenuButton(...),
  onTap: () => ...,
);
```

### badge 参数

标题右侧可附带徽章（与 title 同行）：

```dart
AppListCard(
  title: Text(drugName),
  badge: Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: scheme.tertiaryContainer,
      borderRadius: r.bXs,
    ),
    child: Text('抗生素', style: labelSmall),
  ),
);
```

---

## AppListScaffold — 列表页骨架

自动组装 loading → error → empty → list 四种状态。

```dart
AppListScaffold<MyModel>(
  title: '页面标题',
  appBarActions: [PopupMenuButton(...)],
  searchField: TextField(...),        // 可选：AppBar.bottom 内嵌搜索
  filterBar: FilterChipBar<String?>(  // 可选：顶部筛选行
    options: [(value: null, label: '全部'), ...],
    selected: _filter,
    onSelected: (v) => ...,
  ),
  loading: _loading,
  items: _data,
  onRefresh: _load,                   // 提供则启用 RefreshIndicator
  emptyState: EmptyState(
    icon: Icons.inbox_outlined,
    message: '暂无数据',
    hint: '点击右下角 + 添加',
  ),
  fab: FloatingActionButton(...),
  itemBuilder: (_, item) => AppListCard(...),
);
```

### 限制

- 内部使用 `ListView.separated`，不支持 `ReorderableListView`。
- 拖拽列表（rooms、enclosures）请直接用 `Scaffold` + `ReorderableListView`，
  仅复用 `AppListCard` / `EmptyState`。

---

## EmptyState — 空状态

```dart
EmptyState(
  icon: Icons.coronavirus_outlined,  // 必填，建议 56px 以下 outline 图标
  message: '疾病库为空',              // 必填主文案
  hint: '点击右下角 + 添加疾病',      // 可选副文案
)
```

---

## FilterChipBar — 筛选行

```dart
FilterChipBar<String?>(
  options: [
    const (value: null, label: '全部'),
    ...categories.map((c) => (value: c as String?, label: c)),
  ],
  selected: _filter,
  onSelected: (v) => setState(() => _filter = v),
)
```

- 44 高、水平滚动、`sp.md` padding
- 点击已选项自动切回 null（全部）
- 使用全局 `chipTheme`

---

## CategoryColors — 分类色

把 `Colors.orange/green/blue/red` 等硬编码收口到 ColorScheme 语义槽位。

```dart
final (fg, bg) = CategoryColors.forCategory(scheme, '疾病');
// fg → 图标/文字颜色
// bg → 容器背景色（已是 Container 色，无需叠 alpha）
```

### 已映射分类

| 分类 | 前景 | 背景 |
|------|------|------|
| 主食 / 幼鸟 / 配对 / 孵化 / 抗生素 | `primary` | `primaryContainer` |
| 蔬果 / 成鸟 / 驱虫 / 育雏 / 维生素 | `secondary` | `secondaryContainer` |
| 补充剂 / 雏鸟 / 产蛋 / 抗真菌 / 疾病 | `tertiary` | `tertiaryContainer` |
| 其他 / 已完结 / 益生菌 | `onSurfaceVariant` | `surfaceContainerHighest` |

新分类在 `lib/theme/category_colors.dart` 的 `forCategory` switch 中添加。

---

## 搜索栏规范

统一为 **AppBar.bottom 内嵌 TextField**（不使用 `showSearch` 全屏跳转）。

```dart
AppListScaffold<>(
  searchField: TextField(
    controller: _searchCtrl,
    decoration: InputDecoration(
      hintText: '搜索关键词',
      prefixIcon: const Icon(Icons.search, size: 20),
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: EdgeInsets.zero,
      border: OutlineInputBorder(borderRadius: context.r.bLg),
    ),
    onChanged: (v) { _query = v.trim(); _load(); },
  ),
  ...
)
```

---

## 下拉刷新规范

所有业务列表页统一使用 `RefreshIndicator`。通过 `AppListScaffold` 的
`onRefresh` 参数启用，列表底部默认 80px padding 防 FAB 遮挡。

---

## 新页面检查清单

创建新的业务列表页时，请确认：

- [ ] 使用 `AppListCard`（或 `.icon` / `.tile` 变体）构建列表项
- [ ] 使用 `AppListScaffold` 组装页面（或手动使用 `EmptyState`）
- [ ] 筛选使用 `FilterChipBar`
- [ ] 颜色使用 `CategoryColors.forCategory`，禁止 `Colors.xxx`
- [ ] 搜索栏为 AppBar.bottom 内嵌式
- [ ] 有 `RefreshIndicator` 下拉刷新
- [ ] 无硬编码 margin/padding（全部使用 `sp.*` / `r.*` token）
