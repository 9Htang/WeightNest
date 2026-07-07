# 设计 Token 迁移指南

本项目正在统一设计系统。本指南记录 token 层的用法，并给出把硬编码样式迁移到 token 的步骤。

## 背景

历史上间距/圆角/透明度/字号散落为 magic number（53 个文件、约 2132 处）。Phase 1 已建立 token 层并改造 3 个示范页面，后续按批次迁移其余文件。

## Token 层（`lib/theme/app_tokens.dart`）

通过 `ThemeExtension` 注入，明暗模式共用同一组实例（值与亮度无关）。已注入到 `lightTheme` / `darkTheme`，无需额外配置。

### 三个维度

| Token 类 | 访问器 | 梯度（值） |
|----------|--------|-----------|
| `AppSpacing` | `context.sp` | `xs=4` `sm=8` `md=12` `lg=16` `xl=24` `xxl=32` |
| `AppRadius` | `context.r` | `xs=2` `sm=4` `md=6` `lg=8` `xl=12` `xxl=16` `pill=20` |
| `AppAlpha` | `context.a` | `subtle=20` `faint=30` `low=60` `medium=100` `high=140` `heavy=180` |

> 字号不新建 token —— 优先用 `theme.textTheme.*`（已定义 10 档）。
> 颜色不新建 token —— 用 `colorScheme` + `AppAlpha`，或 `StatusColors`（业务语义色）。

### 用法

```dart
import '../theme/app_tokens.dart';

// 在任意 build 方法内：
final sp = context.sp;
final r = context.r;
final a = context.a;

Padding(padding: EdgeInsets.all(sp.md));            // 12
BorderRadius.circular(r.xl);                         // 12
colorScheme.onSurface.withAlpha(a.high);             // 140 替代 Colors.grey
theme.textTheme.titleSmall;                          // 替代 fontSize: 14
```

便捷构造：
```dart
sp.cardMargin     // EdgeInsets：horizontal 12, vertical 4
r.bXl             // BorderRadius.circular(12)
```

## 迁移规则

### 1. alpha 合并表（22 → 6）

| 旧值 | token |
|------|-------|
| 8 / 12 / 15 / 18 / 20 / 25 | `a.subtle` (20) |
| 30 / 40 | `a.faint` (30) |
| 50 / 60 | `a.low` (60) |
| 80 / 100 / 110 | `a.medium` (100) |
| 120 / 130 / 140 | `a.high` (140) |
| 150 / 160 / 180 / 200 / 204 | `a.heavy` (180) |

`withValues(alpha: 0.x)` 的小数 → 乘 255 取整后按上表合并。

### 2. fontSize 映射

| 旧值 | 替代 |
|------|------|
| 10 / 11 | `theme.textTheme.labelSmall` (11) |
| 12 / 13 | `theme.textTheme.bodySmall` (12) / `labelMedium` (12) |
| 14 | `theme.textTheme.titleSmall` / `labelLarge` (14) |
| 16 | `theme.textTheme.titleMedium` / `bodyLarge` (16) |
| 18 | AppBar 标题样式（已配） |
| 20+ | `titleLarge` (20) / `headlineMedium` (24) |

### 3. Colors 映射

| 旧值 | 替代 |
|------|------|
| `Colors.grey`（次要文本） | `colorScheme.onSurface.withAlpha(a.high)` |
| `Colors.red`（错误/删除） | `colorScheme.error` |
| `Colors.green/orange/blue...`（状态色） | `StatusColors`（nestling/juvenile/adult/success/error/info） |
| `Color(0xFF...)` hex 字面量 | 优先映射到 `colorScheme` 角色或 `StatusColors` |

### 4. 圆角合并（15 → 7）

`3→sm(4)`、`5→md(6)`、`14→xxl(16)`，其余 `2/4/6/8/12/16/20` 直接对应。

## 例外：保留为局部常量的情形

网格/特殊 UI 特有的参数（非通用间距）不进全局 token，收纳在文件顶部的私有常量类。范例见 `weigh_grid_screen.dart` 的 `_WeighGridMetrics`：
- 选中态边框宽、单元格 padding、图例色块尺寸、拨盘几何 clamp 边界等

判断标准：**如果只有 1 个文件用，且语义是"该 UI 特有"，留局部常量；如果多个页面共用，进 token。**

## 已完成（Phase 1）

- ✅ `lib/theme/app_tokens.dart` —— token 层
- ✅ `lib/theme/theme.dart` —— 注入 extensions
- ✅ `lib/screens/weigh/weigh_grid_screen.dart` —— 含 `_WeightTrendInline` N+1 修复、emoji 映射、列宽去重
- ✅ `lib/plugins/nutrition/screens/blend_library_screen.dart` —— 含 N+1 修复（`getBlendBindingsForAll`）
- ✅ `lib/plugins/nutrition/nutrition_repository.dart` —— 新增批量方法
- ✅ `lib/screens/birds/birds_screen.dart` + `lib/widgets/bird_list_tile.dart`

## 待迁移（Phase 2+）

按热点文件分批，每批一个 commit：

- **Batch A**：`weight_config_screen.dart`、`weigh_input_widgets.dart`、`dose_calculation_screen.dart`（31 处 hex 集中地，映射到 StatusColors）
- **Batch B**：`settings_screen.dart`、`bird_detail_screen.dart`、`mobile_shell.dart`、`medication_section.dart`、`breeding_record_screen.dart`
- **Batch C**：gallery / debug / 其余 screens
- **Batch D**：全局 grep 确认无残留 `Colors.grey` / `Color(0x` / 裸 magic number
