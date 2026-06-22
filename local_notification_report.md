# WeightNest 本地通知接入报告

## 一、当前状态

### 已有能力

| 能力 | 实现 | 位置 |
|---|---|---|
| 异常检测引擎 | 插件系统 `detectAlerts()`，聚合为 `AnomalyAlert` | `lib/services/alert_service.dart` |
| 任务逾期标记 | `_markOverdueTasks()` 将过期任务从待完成→逾期 | `lib/repositories/task_repository.dart:96` |
| 告警持久化 | 写入 `alert_records` 表，去重、确认、查询 | `lib/services/alert_service.dart:76-257` |
| 前台定时器 | 5 分钟 `Timer.periodic`，触发任务生成+告警检测 | `lib/screens/shell/mobile_shell.dart:97` |
| 应用恢复 | `AppLifecycleState.resumed` 时触发检测 | `lib/screens/shell/mobile_shell.dart:82` |
| 逾期任务查询 | 逾期 tab 页展示 `deadline < now` 的任务 | `lib/repositories/task_repository.dart:44` |
| 告警 UI | 首页 banner + 异常提醒页面 | `lib/screens/tasks/tasks_screen.dart` |

### 缺失能力

- **没有任何通知相关的依赖包**（`flutter_local_notifications` 等均未引入）
- **没有后台处理机制**（无 `workmanager`、`flutter_background_service`）
- **平台侧零配置**：`AndroidManifest.xml` 无 `POST_NOTIFICATIONS` 权限，iOS `Info.plist` 无 `UIBackgroundModes`
- **没有通知渠道注册、权限请求、通知点击处理等任何代码**

---

## 二、可接入本地通知的位置

按影响面从大到小排列：

### 位置 1：任务逾期 — 即时通知

**触发时机**：`_markOverdueTasks()` 将任务标记为 `'逾期'` 时

**文件**：`lib/repositories/task_repository.dart:96-103`

**现状**：只做了 DB 写入，无任何用户感知。用户必须打开 app 进入逾期 tab 才能看到。

**建议**：标记完成后，对每个刚被标记为逾期的任务发一条本地通知。

```
通知内容示例：
标题: "任务逾期 — 称重"
正文: "虎皮鹦鹉 #3 的称重任务已逾期"
```

**实现要点**：
- `_markOverdueTasks()` 当前用一条 `UPDATE` 批量标记，无法知道具体标记了哪些行
- 需要改为先 `SELECT` 查出即将被标记的任务，再 `UPDATE`，然后对结果集逐条发通知
- 或者标记后查询本轮新增的逾期任务（通过 `updatedAt` 在一定时间窗口内）

**优先级**：🔴 高 — 这是用户最直接的需求

---

### 位置 2：告警检测 — 即时通知

**触发时机**：`AlertService.detectAll()` 检测到新告警时

**文件**：`lib/services/alert_service.dart:33-72`

**现状**：告警写入 `alert_records` 表，UI 通过 provider 刷新展示。无推送。

**涉及插件和告警类型**：

| 插件 | 告警类型 | 严重度 | 触发条件 |
|---|---|---|---|
| `WeightPlugin` | 称重逾期 | warning/danger | 距上次称重超过 1.5×/3× 称重周期 |
| `WeightPlugin` | 体重下降 | danger | 雏鸟体重连续下降 |
| `WeightPlugin` | 生长缓慢 | warning | 雏鸟生长率低于同品种基准 |
| `WeightPlugin` | 断奶异常 | danger | 断奶期体重下降超 15% |
| `WeightPlugin` | 基线偏离 | danger | 成年鸟偏离基线超 3σ |
| `WeightPlugin` | 长期无数据 | danger | 90 天内无体重记录 |
| `MedicationPlugin` | 漏喂药物 | warning | 今日喂药时间已过但未完成 |

**建议**：
- `danger` 级别告警立即推送
- `warning` 级别告警可考虑聚合推送（如每 30 分钟汇总一次）
- `_rawAlertsProvider`（`lib/providers.dart:119`）中 `upsertUnreadAlerts()` 返回后，对比新旧告警，对新出现的发通知

**优先级**：🔴 高 — 告警的核心价值在于"及时"

---

### 位置 3：后台定期检查

**触发时机**：app 在后台或未运行时，定期唤醒检查

**现状**：5 分钟 `Timer.periodic` 只在前台有效。app 进入后台后一切停止。

**建议**：引入 `workmanager` 包，注册一个周期性后台任务（如每 15-30 分钟），执行：
1. `generateTodayTasks()` → 标记逾期 + 生成新任务
2. `AlertService.detectAll()` → 检测新告警
3. 对新增的逾期任务和告警发本地通知

**平台要求**：
- Android：`WorkManager`（`workmanager` 包已封装），最小间隔 15 分钟
- iOS：`BGTaskScheduler`（受系统调度，不保证精确执行），需要 `UIBackgroundModes` 配置

**优先级**：🟡 中 — 前台通知覆盖大部分场景后，后台是自然延伸

---

### 位置 4：喂药提醒 — 定时通知

**触发时机**：喂药任务的 `dueDate` 到达时

**文件**：`lib/plugins/medication/medication_plugin.dart:120-152`

**现状**：喂药任务以 `dueDate` 记录在 tasks 表中，到期后仅在 app 内可见。用户不打开 app 就不会知道该喂药了。

**建议**：
- 在生成每日喂药任务时，为每个 `dueDate` 预约一个本地通知（`flutter_local_notifications` 的 `zonedSchedule` 或 `periodicallyShow`）
- 通知时间 = 喂药时间，内容 = "该给 XX 喂 YY 药了，剂量 ZZ"
- 任务完成时取消对应的预约通知

**实现复杂度**：中 — 需要管理通知 ID 与任务 ID 的映射，处理取消和重新调度

**优先级**：🟡 中 — 对用药场景价值很大，但实现比前两个位置复杂

---

### 位置 5：称重提醒 — 定时通知

**触发时机**：称重任务的 `dueDate` 到达时（次日 taskReadyTime）

**文件**：`lib/plugins/weight/weight_plugin.dart:555-578`

**现状**：称重任务以 `dueDate` 记录，但没有到达时间的即时提醒。

**建议**：在生成每日称重任务时，为每个 `dueDate` 预约通知。

**优先级**：🟢 低 — 称重不像喂药那样有严格的时间窗口要求，且通常在工作时段内进行，用户打开 app 就能看到任务。

---

### 位置 6：繁殖阶段提醒

**触发时机**：繁殖周期进入新阶段时

**文件**：`lib/plugins/breeding/breeding_plugin.dart`

**现状**：BreedingPlugin 的 `detectAlerts()` 返回空列表（未实现告警）。

**建议**：
- 孵化到期提醒
- 雏鸟出壳提醒
- 断奶期提醒

**优先级**：🟢 低 — 需要先实现 BreedingPlugin 的 detectAlerts，再做通知。

---

## 三、推荐实施路线

### 第一阶段：核心通知（位置 1 + 2，前台即时）

1. 引入 `flutter_local_notifications` 依赖
2. 在 `main.dart` 初始化通知插件（渠道注册、权限请求）
3. 实现一个 `NotificationService` 封装通知发送
4. 在 `_markOverdueTasks()` 后发送逾期通知
5. 在 `AlertService.detectAll()` 后发送告警通知（danger 级立即，warning 级聚合）

**这个阶段不需要后台支持，利用现有 5 分钟定时器和应用恢复逻辑即可。**

### 第二阶段：后台检查（位置 3）

1. 引入 `workmanager` 依赖
2. 注册后台任务，每 15-30 分钟执行
3. 后台任务中复用第一阶段的 `NotificationService`

### 第三阶段：定时提醒（位置 4-6，按需）

1. 喂药定时通知
2. 称重定时通知
3. 繁殖提醒

---

## 四、技术选型建议

| 需求 | 推荐方案 |
|---|---|
| 本地通知 | `flutter_local_notifications` — Flutter 生态最成熟的本地通知包 |
| 后台任务（Android） | `workmanager` — 封装 Android WorkManager，稳定可靠 |
| 后台任务（iOS） | `workmanager` 同样支持（底层用 BGTaskScheduler），但 iOS 不保证精确执行 |
| 定时预约通知 | `flutter_local_notifications.zonedSchedule()` — 支持精确到分钟的预约 |

`flutter_local_notifications` + `workmanager` 是标准组合，社区验证充分，不需要额外造轮子。
