# 内置插件详解

WeightNest 包含 4 个生产插件和 1 个调试插件。每个插件实现 `FeaturePlugin` 接口的不同 Slot，声明自己对应用的贡献。

---

## WeightPlugin — 体重追踪插件

> 文件：`lib/plugins/weight/weight_plugin.dart`、`weight_math.dart`、`weight_table.dart`

### 功能概述

以体重记录和分析为核心，提供智能告警和任务生成。

### 使用的 Slot

| Slot | 实现 |
|------|------|
| B — 鸟只详情 | 体重趋势图表（`WeightChart`） |
| E — 首页快捷操作 | 批量称重按钮 |
| G — 容器称重 | 容器卡片称重按钮 |
| H — 房间称重 | 房间卡片称重按钮 |
| F — 告警检测 | 4 种告警检测算法 |
| G — 任务派发 | 按称重间隔生成称重任务 |
| Settings | 体重插件设置页 |
| Task Card Tap | 跳转到鸟只详情 |
| Events | 监听喂药事件 |
| Data Queries | — |
| Routes | — |

### 告警检测算法

`weight_math.dart` 包含核心算法，`weight_plugin.dart` 中的 `detectAlerts()` 调用 4 种检测：

#### 1. 断奶期告警 `_weaningAlerts()`

检测断奶期体重异常下降：

- **Warning**：峰值 → 最新下降 > 10%
- **Danger**：峰值 → 最新下降 > 15%
- 断奶期判定：手动覆盖优先，否则自动检测（峰值后连续 2/3 次下降 > 5%）
- 自动退出条件：超龄、企稳（波动 <3%）、体重回升

#### 2. 雏鸟生长告警 `_chickGrowth()`

基于 **48 小时 log-normalized 增长率**分析：

- 计算最近 48h 内每两个数据点的 ln(curr/prev)，归一化为 24h 增长率
- **Warning**：平均增长率 < 3%（`chickGrowthSlowRate`）
- **Danger**：连续下降点数 ≥ 阈值
- 90 天分析窗口

#### 3. 成鸟/幼鸟基线告警 `_baselineAlerts()`

基于 **EWMA（指数移动平均）基线**：

- EWMA alpha = 0.2，平滑历史体重
- **急性单点偏离**：最近一次偏离基线
  - Warning：> ±10%（`warningDeviationPct`）
  - Danger：> ±15%（`dangerDeviationPct`）
- **慢性趋势偏离**：近期均值偏离基线
  - Warning：> ±7%（`chronicTrendPct`）
- 支持手动基线覆盖（`manualBaselineG`）

#### 4. 超期未称重告警 `_overdue()`

基于称重间隔检查：

- **Warning**：超过间隔 × 1.5 倍
- **Danger**：超过间隔 × 3 倍
- **跳过繁育鸟**：通过跨插件 RPC 查询 BreedingPlugin 的 `getActiveBreedingBirdIds`

### 关键常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `warningDeviationPct` | 10% | 单点偏离 Warning 阈值 |
| `dangerDeviationPct` | 15% | 单点偏离 Danger 阈值 |
| `chronicTrendPct` | 7% | 慢性趋势 Warning 阈值 |
| `chickGrowthHealthyRate` | 8% | 雏鸟健康增长率（24h） |
| `chickGrowthSlowRate` | 3% | 雏鸟增长率 Warning 阈值 |
| `weaningWarningDropPct` | 10% | 断奶期下降 Warning |
| `weaningDangerDropPct` | 15% | 断奶期下降 Danger |
| `analysisWindowDays` | 90 | 分析窗口天数 |
| EWMA alpha | 0.2 | 基线平滑系数 |

### 数学工具函数

```dart
double logGrowth(double prev, double curr)      // ln(curr/prev)
double normalize24h(double rate, double h)       // 归一化为 24h 增长率
double hoursBetween(DateTime a, DateTime b)     // 两时刻间小时数
double avg(List<double> v)                       // 算术平均
List<double> ewma(List<double> values, {alpha})  // EWMA 序列
```

### 任务生成

按每只鸟的称重间隔（`effectiveWeighIntervalDays`）生成 `weigh` 类型任务，任务时间为 `taskReadyTime`（工作开始前 30 分钟）。

---

## MedicationPlugin — 用药管理插件

> 文件：`lib/plugins/medication/`（14 个文件）

### 功能概述

完整的用药管理系统：药品库、剂量计算、喂药方案、喂药记录、副作用追踪、疾病目录。

### 使用的 Slot

| Slot | 实现 |
|------|------|
| B — 鸟只详情 | 用药方案区块、喂药记录区块 |
| D — 日历视图 | 喂药日历（日视图） |
| F — 告警检测 | 检测漏喂（medication 任务逾期） |
| G — 任务派发 | 按方案生成喂药任务 |
| Settings | 用药设置页 |
| Task Card Tap | 跳转到鸟只详情 |
| Data Queries | `getPlans`、`getAllDrugs`、`calculateDosage` |
| Routes | `/medication`、`/medication/drug-library` |

### 数据表（8 张）

| 表 | 说明 |
|------|------|
| DrugLibrary | 药品库 |
| DrugFormulations | 药品规格/浓度 |
| DiseaseCatalog | 疾病目录 |
| DoseRules | 剂量规则 |
| Medications | 喂药方案 |
| FeedingRecords | 喂药记录 |
| SideEffectRecords | 副作用记录 |
| StopConditions | 停药条件 |

### 剂量计算

`dose_math.dart` 实现纯数学剂量计算：

```
mgDose = (weightG / 1000) × mgPerKg
volumeMl = mgDose / concentrationMgPerMl
```

**安全约束：**
- weightG ≤ 0 或 mgPerKg ≤ 0 时返回 0（不产生 NaN）
- concentration ≤ 0 时抛出 ArgumentError（防止除零，视为数据错误）

### 任务生成

根据活跃的喂药方案，在工作窗口内均匀分配喂药时间（通过 `WorkHoursConfig.distributeDoses()`），每次喂药生成一条独立任务。metadata 中包含 drugName、dosage、medicationId。

### 关联屏幕

| 屏幕 | 说明 |
|------|------|
| MedicationScreen | 用药主页面 |
| DrugLibraryScreen | 药品库管理 |
| DiseaseCatalogScreen | 疾病目录 |
| DoseRulesScreen | 剂量规则管理 |
| DoseCalculationScreen | 剂量计算器 |
| FeedingRecordSheet | 喂药记录底部弹窗 |

---

## BreedingPlugin — 繁育管理插件

> 文件：`lib/plugins/breeding/`（5 个文件）

### 功能概述

繁育全流程管理：配对、产蛋、孵化、育雏、完结。

### 使用的 Slot

| Slot | 实现 |
|------|------|
| B — 鸟只详情 | 繁育信息区块 |
| E — 首页快捷操作 | 繁育管理入口 |
| Data Queries | `getActiveBreedingBirdIds`、`isBreeding`、`getActivePair` |
| Pages | 配对管理页面 |
| Settings | — |
| F — 告警检测 | —（返回空列表） |
| G — 任务派发 | —（返回空列表） |

### 数据表（4 张）

| 表 | 说明 |
|------|------|
| BreedingPairs | 配对（公鸟+母鸟，active/separated） |
| BreedingRecords | 繁育周期（配对→产蛋→孵化→育雏→已完结） |
| Eggs | 蛋记录（孵化中/已出壳/未受精/损坏） |
| MatingEvents | 踩背观察记录 |

### 跨插件集成

WeightPlugin 通过 `registry.call('breeding', 'getActiveBreedingBirdIds')` 获取当前处于繁育期的鸟只 ID，跳过这些鸟的超期未称重告警。

---

## GalleryPlugin — 照片相册插件

> 文件：`lib/plugins/gallery/`（6 个文件）

### 功能概述

照片和头像管理，支持静态照片和 Android 实况照片（Motion Photo）。

### 使用的 Slot

| Slot | 实现 |
|------|------|
| B — 鸟只详情 | 照片网格区块 |
| I — 鸟只头像 | 自定义头像组件（支持裁剪） |
| Data Queries | `getAvatarPath`、`getPhotos` |

### 数据表（2 张）

| 表 | 说明 |
|------|------|
| BirdPhotos | 鸦排序的照片列表，支持 photo / motion_photo |
| BirdAvatars | 每鸟一个头像 |

### 实况照片支持

- `mediaType` 字段区分 `photo` 和 `motion_photo`
- `videoFilePath` 存储提取的 MP4 路径
- `thumbnailPath` 存储从视频生成的 animated WebP 缩略图
- `MotionPhotoService` 通过平台通道提取嵌入视频

### 关联屏幕/组件

| 组件 | 说明 |
|------|------|
| GalleryViewerScreen | 全屏照片查看器 |
| AvatarCropScreen | 头像裁剪 |
| GallerySection | 鸟只详情中的照片网格 |
| BirdAvatar | 头像显示组件 |
| AvatarPicker | 头像选择器 |

---

## DebugPlugin — 调试工具插件

> 文件：`lib/plugins/debug/`（6 个文件）

**仅 debug 模式注册**（`kDebugMode` 条件判断）。

### 功能

仅提供 `settingsBuilder`（DebugDashboardScreen），不参与路由、页面、告警或任务。

### 子页面

| 页面 | 说明 |
|------|------|
| DebugDashboardScreen | 调试仪表盘（入口） |
| DBInspectorScreen | 数据库检查器 |
| LogViewerScreen | 日志查看器 |
| PluginStatusScreen | 插件状态总览 |
| TaskEditorScreen | 任务编辑器 |
