# WeightNest 任务系统说明文档

## 目录

1. [架构概览](#1-架构概览)
2. [数据模型](#2-数据模型)
3. [任务生成机制](#3-任务生成机制)
4. [任务生命周期](#4-任务生命周期)
5. [各插件任务详解](#5-各插件任务详解)
6. [通知系统](#6-通知系统)
7. [任务完成路径](#7-任务完成路径)
8. [UI 层](#8-ui-层)
9. [如何扩展新任务类型](#9-如何扩展新任务类型)
10. [关键文件索引](#10-关键文件索引)

---

## 1. 架构概览

任务系统采用**插件驱动 + 集中调度**架构：

```
┌────────────────────────────────────────────┐
│           触发源（Trigger Sources）          │
│  App启动 │ 后台恢复 │ 5分钟定时器 │ 创建新鸟   │
└──────────────────┬─────────────────────────┘
                   ▼
┌─────────────────────────────────────────────┐
│     TaskRepository.generateTodayTasks()      │
│  ① 标记逾期  ② 清理重复  ③ 补丁/升级        │
│  ④ 遍历插件 detectTasks() → 去重 → INSERT    │
└──────────────┬──────────────────────────────┘
               ▼
┌──────────────────────────────┐
│  FeaturePlugin.detectTasks() │  ← 各插件分别实现
│  WeightPlugin  │ MedicationPlugin │ ...
└──────────────────────────────┘
               ▼
┌──────────────────────────────┐
│       Tasks 表（Drift DB）    │
└──────────────────────────────┘
```

核心思想：**任务不是预设的，而是每天动态生成的**。每个插件根据当前数据（称重间隔、喂药计划等）实时判断今天需要做什么，返回 `PluginTaskDescriptor` 列表，由 `TaskRepository` 统一插入数据库并去重。

---

## 2. 数据模型

### 2.1 Tasks 表

定义位置：`lib/database/tables.dart:165-205`（Drift ORM）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `int` | 自增主键 |
| `uuid` | `text` | 全局唯一 ID |
| `birdId` | `int` | 外键 → `Birds.id`，级联删除 |
| `roomId` | `int?` | 冗余外键，方便按房间筛选任务 |
| `assignedUserId` | `int?` | 指派给哪个工人 |
| `taskType` | `text` | 任务类型：`weigh` / `medication` |
| `dueDate` | `datetime` | 任务到期时间 |
| `deadline` | `datetime?` | 硬截止时间（逾期判定线） |
| `status` | `text` | 状态（见下方） |
| `completedAt` | `datetime?` | 完成时间 |
| `completedBy` | `int?` | 完成人 |
| `metadata` | `text?` | 插件私有 JSON 数据 |
| `createdAt` | `datetime` | 创建时间 |
| `updatedAt` | `datetime` | 更新时间 |

### 2.2 状态枚举

| 状态 | 含义 |
|------|------|
| `待完成` | 待处理 |
| `已完成` | 正常完成 |
| `逾期` | 超过 deadline 未完成 |
| `已跳过` | 主动跳过（仅喂药任务使用） |

### 2.3 索引

```sql
CREATE INDEX idx_tasks_due_status ON tasks(due_date, status)
```

### 2.4 关联表

- **`ActivityLogs`**（`tables.dart:343-381`）：通过 `relatedTaskId` 外键关联 Task，记录是谁通过什么操作完成了任务
- **`Birds`**：通过 `birdId` 关联，任务是 per-bird 的

### 2.5 PluginTaskDescriptor

定义位置：`lib/core/plugin.dart:289-305`

```dart
class PluginTaskDescriptor {
  final int birdId;
  final String taskType;       // 'weigh', 'medication', ...
  final DateTime dueDate;
  final DateTime? deadline;
  final String label;          // 显示用，如 '称重'
  final Map<String, String>? metadata;  // 插件私有数据
}
```

这是插件向任务系统"投稿"的数据结构。插件不直接写数据库，只返回描述符列表。

---

## 3. 任务生成机制（发布任务）

### 3.1 入口：`TaskRepository.generateTodayTasks()`

位置：`lib/repositories/task_repository.dart:245-462`

这是整个任务系统的核心调度方法，每次调用执行以下流程：

```
generateTodayTasks(force: false)
│
├─ ① 并发锁检查（_generating 静态 bool）
│     防止多次并发执行
│
├─ ② 标记逾期（_markOverdueTasks，156-171行）
│     将 deadline < now 且 status='待完成' 的任务设为 '逾期'
│     发送本地通知（_notifyOverdue）
│     注：此步骤不受节流影响，每次都执行
│
├─ ③ 节流检查（60秒冷却，264-269行）
│     距离上次执行不足60秒则跳过后续步骤
│
├─ ④ 事务内执行：
│   │
│   ├─ 清理重复任务（cleanupDuplicateTasks，211-237行）
│   │   SQL CTE 去重：weigh 按 (birdId, taskType, day) 去重
│   │                medication 按 (birdId, taskType, 精确dueDate) 去重
│   │
│   ├─ 预加载数据：所有鸟、房间、今日已称重鸟ID
│   │
│   ├─ 补丁/升级（force=false 时）：
│   │   • 补填缺失的 assignedUserId
│   │   • 自动完成：鸟已有今日称重记录但weigh任务仍待完成 → 标记已完成
│   │
│   └─ 插件聚合（403-452行）：
│       遍历 pluginRegistry.enabledPlugins
│       │
│       ├─ WeightPlugin.detectTasks(db)  → 'weigh' 任务
│       ├─ MedicationPlugin.detectTasks(db) → 'medication' 任务
│       └─ 其他插件...
│       │
│       对返回结果：
│       • 去重 key = "{birdId}_{taskType}_{dueDate.iso8601}"
│       • 跨日 weigh 去重：已有未完成 weigh 任务的鸟不再生成新 weigh 任务
│       • INSERT 新任务
│
└─ ⑤ 返回新生成任务数
```

### 3.2 触发时机

| 触发点 | 位置 | 说明 |
|--------|------|------|
| App 首次启动 | `mobile_shell.dart:76` | DB 初始化完成后 |
| 从后台恢复 | `mobile_shell.dart:90` | `didChangeAppLifecycleState(resumed)` |
| 定时器 | `mobile_shell.dart:103-111` | 每 5 分钟执行一次 |
| 创建新鸟 | `birds_screen.dart:430` | 调用 `generateTasksForBird(birdId)` |
| Debug 面板 | `debug_dashboard_screen.dart` | 手动触发，含 `force: true` |

### 3.3 单鸟任务生成：`generateTasksForBird(birdId)`

位置：`lib/repositories/task_repository.dart:469-536`

逻辑与批量生成相同，但 scope 限定为单只鸟。插件 `detectTasks` 会收到 `birdId` 参数。用于新鸟创建后立即生成任务。

### 3.4 去重策略

两重去重保证同一任务不会被重复生成：

1. **SQL 清理**（`cleanupDuplicateTasks`）：删除同一 bird 同日同类型的重复行
2. **内存去重**（生成时）：维护 `existingTodayKeys` 集合，已存在的 `(birdId, taskType, dueDate)` 组合不再插入
3. **跨日 weigh 去重**：如果某鸟已有未完成的 weigh 任务（可能是昨天的），今天不再生成新的，避免积压

---

## 4. 任务生命周期

```
  插件 detectTasks() 返回描述符
         │
         ▼
  TaskRepository INSERT → status = '待完成'
         │
         ├─── 用户完成操作 ───→ status = '已完成'
         │    (称重记录 / 喂药确认)
         │
         ├─── 用户跳过 ───→ status = '已跳过'
         │    (仅喂药，skipMedication)
         │
         ├─── 自动补完 ───→ status = '已完成'
         │    (下次 generateTodayTasks 发现已有称重记录)
         │
         └─── 超时逾期 ───→ status = '逾期'
              (deadline < now，下次 generateTodayTasks 标记)
              
  撤销操作（revokeOperation）: '已完成'/'已跳过' → '待完成'
```

---

## 5. 各插件任务详解

### 5.1 WeightPlugin：称重任务

文件：`lib/plugins/weight/weight_plugin.dart:334-411`

**生成逻辑：**

1. **时间门控**：批量模式下，当前时间早于 `taskReadyTime`（工作开始前30分钟）不生成
2. **遍历所有鸟**，批量查询每只鸟的最新称重记录
3. **计算称重间隔**：`computeEffectiveWeighInterval()`
   - 优先：鸟级别 `weighIntervalDays` 自定义
   - 其次：按物种 × 生理阶段默认值

   | 阶段 | 间隔 |
   |------|------|
   | 雏鸟（nestling） | 1 天 |
   | 幼鸟（juvenile） | 3 天 |
   | 成鸟（adult） | 7 天 |

4. **判断是否需要称重**：`无称重记录 OR daysSinceLast >= intervalDays`
5. **设置时间**：
   - `dueDate` = 今天 `taskReadyTime`（如 07:30）
   - `deadline` = 明天 `taskReadyTime`（次日 07:30）
6. **taskType** = `'weigh'`

### 5.2 MedicationPlugin：喂药任务

文件：`lib/plugins/medication/medication_plugin.dart:131-183`

**生成逻辑：**

1. **查询活跃用药计划**：`active == true`，且当前日期在 `startDate`~`endDate` 范围内
2. **JOIN drugLibrary** 获取药品名称
3. **计算给药时间**：`distributedTimeSlots(timesPerDay)` — 将工作时间窗口均匀分成 N 段

   ```
   例如：timesPerDay=3, 工作时间 08:00-20:00
   → 08:00, 14:00, 20:00 三个时间点
   ```

4. **每个时间点生成一个任务**：
   - `dueDate` = 具体给药时间
   - `deadline` = dueDate + 30 分钟
   - `metadata` 包含 `{medicationId, drugName, dosage, drugLibraryId}`
5. **taskType** = `'medication'`

**注**：一个用药计划 × 3次/天 = 每天 3 个独立任务。

### 5.3 其他插件

| 插件 | 是否生成任务 | 说明 |
|------|-------------|------|
| BreedingPlugin | 否 | 繁育不产生日常任务 |
| NutritionPlugin | 否 | 暂无任务生成 |
| StagePlugin | 否 | 提供生理阶段数据供其他插件使用 |
| DebugPlugin | 否 | 提供调试工具 |

---

## 6. 通知系统

### 6.1 依赖与初始化

- **库**：`flutter_local_notifications: ^18.0.0`
- **Android 权限**（`AndroidManifest.xml`）：
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.VIBRATE"/>
  ```
- **iOS**：运行时通过 `DarwinInitializationSettings(requestAlertPermission: true)` 申请

### 6.2 通知通道

| 通道 ID | 名称 | 优先级 | 用途 |
|---------|------|--------|------|
| `task_overdue` | 任务逾期 | HIGH | 任务逾期通知 |
| `alert` | 异常提醒 | HIGH | 健康异常告警 |

### 6.3 逾期通知

位置：`lib/services/notification_service.dart:78-107`

由 `TaskRepository._notifyOverdue()` 调用。聚合逻辑：
- ≤3 条逾期 → 逐条显示鸟名+任务类型
- >3 条 → 汇总显示 "X 只鸟有逾期任务"

固定通知 ID 1000，后续调用覆盖前一条。

### 6.4 告警通知

位置：`lib/services/notification_service.dart:110-168`

由 `AlertService` 调用：
- **danger 级别**：每条单独通知，ID 由 birdId+alertType 生成
- **warning 级别**：聚合为一条通知（ID 2000）

---

## 7. 任务完成路径

### 路径总览

```
                     用户操作
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                 ▼
   称重记录         喂药确认           直接调用
        │                │                 │
        ▼                ▼                 ▼
 OperationService   MedicationRepo   TaskRepository
   .record()       .giveMedication()  .completeTask()
   (传relatedTaskId)    │                 │
        │                │                 │
        └────────────────┼─────────────────┘
                         ▼
                 UPDATE tasks SET
                 status = '已完成',
                 completedAt = now,
                 completedBy = userId
```

### 7.1 称重完成任务

位置：`lib/screens/weigh/weigh_grid_provider.dart:420`

称重流程：
1. 录称重数据前，查询 `getTodayPendingTask(birdId, 'weigh')`
2. 调用 `operationService.recordInTransaction(relatedTaskId: pendingTask?.id, ...)`
3. `OperationService` 在写 `ActivityLog` 的同时自动将关联任务标记为已完成
4. 发送 `OperationRecordedEvent` 到事件总线

### 7.2 喂药完成任务

位置：`lib/plugins/medication/medication_repository.dart:57-74`

- `giveMedication(taskId)`：直接更新 task status → `已完成`
- `skipMedication(taskId)`：更新 status → `已跳过`

### 7.3 自动补完

位置：`lib/repositories/task_repository.dart:354-397`

`generateTodayTasks()` 中的"升级"逻辑：如果某鸟已有今日称重记录但 weigh 任务仍是 `待完成`（例如称重时未关联任务），自动将任务标记为 `已完成`。

### 7.4 撤销操作

位置：`lib/services/operation_service.dart:176-202`

`revokeOperation(logId)`：删除 ActivityLog，并将关联任务回退到 `待完成`。

---

## 8. UI 层

### 8.1 任务列表页

文件：`lib/screens/tasks/tasks_screen.dart`（706 行）

**双 Tab 布局：**
- **今日任务** — 当天 `待完成` + `已完成` 的任务
- **逾期** — 状态为 `逾期` 的历史任务

**筛选功能：**
- 搜索：按鸟名或环号过滤
- 类型筛选：全部 / 称重 / 喂药

**排序规则：**
- 异常鸟（来自 `alertListProvider`）排在待完成列表最前面，红色高亮

**操作按钮：**
- 称重任务 → "称重"按钮 → 跳转 `WeighGridScreen`
- 喂药任务 → "已喂" / "跳过" 按钮

### 8.2 首页统计卡片

位置：`lib/screens/shell/mobile_shell.dart:324-388`

`_StatsCardWarm` 展示：
- 待完成数 / 已完成数
- 完成百分比
- "查看任务" 按钮（有待完成任务时显示）

### 8.3 底部导航

位置：`lib/screens/shell/mobile_shell.dart:36-41`

任务页是底部导航的第 2 个 Tab（index=1）。

### 8.4 鸟详情页

文件：`lib/screens/birds/bird_detail_screen.dart`

`_PluginDetailTabs` 聚合各插件的 `DetailSection`，包括体重趋势、喂药计划、繁育信息等。任务卡片点击后跳转到对应插件的详情 Tab。

### 8.5 Debug 任务编辑器

文件：`lib/plugins/debug/task_editor_screen.dart`（369 行）

开发调试工具：
- 按日期范围浏览任务
- 修改任务状态
- 删除任务
- **批量种子**：通过修改 `AppClock` 模拟多天时间推进，自动生成历史任务数据

---

## 9. 如何扩展新任务类型

### Step 1：在插件中实现 `detectTasks()`

```dart
// your_plugin.dart
@override
Future<List<PluginTaskDescriptor>> detectTasks(AppDatabase db, {int? birdId}) async {
  final tasks = <PluginTaskDescriptor>[];

  // 查询需要生成任务的鸟
  final birds = birdId != null
      ? [await db.getById(birdId)]
      : await db.getAllBirds();

  for (final bird in birds) {
    if (/* 判断今天需要生成任务 */) {
      tasks.add(PluginTaskDescriptor(
        birdId: bird.id,
        taskType: 'your_type',
        dueDate: dueDate,
        deadline: deadline,
        label: '你的任务名',
        metadata: {'key': 'value'},  // 可选
      ));
    }
  }

  return tasks;
}
```

### Step 2：处理任务完成

在用户完成操作时，关联 `relatedTaskId`：

```dart
await operationService.record(
  pluginId: 'your_plugin',
  actionType: 'your_action',
  birdId: birdId,
  relatedTaskId: taskId,  // ← 自动完成任务
  ...
);
```

### Step 3：处理任务卡片点击（可选）

```dart
@override
Widget? onTaskCardTap(BuildContext context, int birdId) {
  return BirdDetailScreen(birdId: birdId, initialPluginId: 'your_plugin');
}
```

### 无需修改的部分

- `TaskRepository.generateTodayTasks()` 会自动遍历所有 enabled 插件
- 去重、逾期标记、通知都是自动的
- UI 会自动显示新类型的任务

---

## 10. 关键文件索引

| 文件 | 说明 |
|------|------|
| `lib/database/tables.dart:165-205` | Tasks 表定义 |
| `lib/database/database.g.dart:3696-4085` | 生成的 Task 数据类和 TasksCompanion |
| `lib/database/database.dart:237-238` | 任务表索引定义 |
| `lib/repositories/task_repository.dart` | **核心**：任务 CRUD + 生成引擎（559行） |
| `lib/core/plugin.dart:91-113, 289-305` | 插件接口 `detectTasks()` + `PluginTaskDescriptor` |
| `lib/core/plugin_registry.dart` | 插件注册中心，`enabledPlugins` 遍历 |
| `lib/core/event_bus.dart` | 事件总线 |
| `lib/core/events.dart:17-39` | `OperationRecordedEvent` |
| `lib/plugins/weight/weight_plugin.dart:334-411` | 称重任务生成 |
| `lib/plugins/medication/medication_plugin.dart:131-183` | 喂药任务生成 |
| `lib/plugins/medication/medication_repository.dart:87-125, 129-167` | 喂药时间槽计算 + MedTaskInfo |
| `lib/services/operation_service.dart` | 统一写操作 + 任务自动完成 |
| `lib/services/notification_service.dart` | 逾期任务和异常通知 |
| `lib/services/work_hours_config.dart` | 工作时间配置，影响 taskReadyTime |
| `lib/screens/tasks/tasks_screen.dart` | 任务列表 UI |
| `lib/screens/shell/mobile_shell.dart:76, 90, 103-111` | 任务生成触发点 |
| `lib/screens/weigh/weigh_grid_provider.dart:420` | 称重时关联任务 |
| `lib/plugins/debug/task_editor_screen.dart` | Debug 任务编辑器 |
| `lib/core/app_clock.dart` | 可覆盖时钟，用于测试时间推进 |
| `lib/providers.dart:80-91` | `todayTasksProvider` / `overdueTasksProvider` |
| `android/app/src/main/AndroidManifest.xml` | 通知权限声明 |
