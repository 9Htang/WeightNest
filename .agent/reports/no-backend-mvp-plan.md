# WeightNest 无后端 MVP 实施方案（修订版）

> 日期：2026-06-13  
> 分支：`feature/offline-mvp`（从 `feature/plugin-architecture` 创建）  
> 目标：手机端独立运行，单用户，纯本地 SQLite，无服务器依赖

---

## 一、关键发现（重新评估后）

### 实际架构比预想的更简单

经过深入代码探索，发现一个重要事实：

**手机端的所有业务页面已经直接使用本地 SQLite**。它们通过 Riverpod providers 读取 Drift 数据库，写入时走 `syncQueue.enqueue()` 模式（先写本地 DB，再排队同步）。

`AuthenticatedHttpClient` 只被桌面端使用，手机端从未直接调用 HTTP API。

这意味着：

| 原先估计 | 实际情况 |
|----------|----------|
| ❌ 手机端 CRUD 走 HTTP | ✅ 手机端已经直连本地 DB |
| ❌ 需要重写所有业务页面 | ✅ 业务页面无需改动 |
| ❌ 阶段 2 需要 4-8 小时 | ✅ 阶段 2 几乎不需要改动 |

### 实际瓶颈只有两个

1. **SplashScreen 启动流程** — 强制要求 mDNS 发现 + 服务器 PIN 认证
2. **SyncEngine** — 连接后启动，但离线时无需运行

---

## 二、精简实施步骤

### 步骤 1：创建分支

```bash
git checkout feature/plugin-architecture
git checkout -b feature/offline-mvp
```

### 步骤 2：改造启动流程（核心改动）

**文件：`lib/screens/splash/splash_screen.dart`**

当前流程：
```
init → mDNS发现 → 子网扫描 → HTTP认证 → SyncEngine.connect() → MobileShell
```

目标流程：
```
init → 检查本地用户 → 有用户? → MobileShell
                    → 无用户? → 本地创建用户 → MobileShell
```

具体改动：
- 移除 `_doDiscovery()` 中的 mDNS、子网扫描、HTTP 认证步骤
- 改为直接检查本地数据库是否有用户
- 有用户 → 直接进入 MobileShell
- 无用户 → 进入简化的本地用户创建流程

### 步骤 3：简化用户系统（单用户）

**文件：`lib/screens/login/login_screen.dart`**

- 移除多用户选择界面
- 改为：首次启动自动创建唯一的本地用户（displayName 可编辑）
- 移除密码验证（单用户不需要登录）
- 移除"连接服务器"和"二维码登录"按钮

**文件：`lib/database/tables.dart`**

- `Users` 表保留但简化：只保留 `uuid`, `displayName`，移除 `passwordHash`, `role`

### 步骤 4：禁用同步引擎

**文件：`lib/providers.dart`**

- `syncEngineProvider` 改为不执行任何操作（或直接返回 null）
- `syncConnectedProvider` 固定为 `false`

**文件：`lib/services/sync_engine.dart`**

- 保留文件但不启动（后续如果要恢复同步能力，代码还在）

### 步骤 5：移除 SyncQueue 写入

**文件：涉及 `syncQueueProvider.enqueue()` 的所有页面（6个文件）**

- 移除 `enqueue()` 调用，只保留直接的数据库写入
- 涉及的页面：weigh_provider, bird_detail_screen, birds_screen, rooms_screen, species_screen, tasks_screen

### 步骤 6：移除不需要的 UI 和服务

| 文件 | 操作 |
|------|------|
| `lib/screens/connect/connect_screen.dart` | 移除或隐藏 |
| `lib/services/discovery_client.dart` | 移除 |
| `lib/services/network_service.dart` | 移除（移动端不用） |
| `lib/services/auth_manager.dart` | 移除 |
| `lib/services/http/authenticated_client.dart` | 移除（移动端不用） |
| `lib/services/bird_archive_service.dart` | 移除 |
| `lib/services/audit_log_service.dart` | 移除 |
| `lib/services/staff_service.dart` | 移除 |
| `lib/services/sync_engine.dart` | 移除 |
| ConnectionStatusBar (`lib/app.dart`) | 移除 |

### 步骤 7：清理依赖

从 `pubspec.yaml` 移除：
- `multicast_dns`（mDNS 发现）
- `mobile_scanner`（QR 扫码，后续可能需要但 MVP 不用）
- `qr`（QR 生成）
- `shelf` / `shelf_router`（嵌入式 HTTP 服务器）

### 步骤 8：数据库迁移

- 从 `lib/database/tables.dart` 移除 `SyncQueue` 表
- 简化 `Users` 表
- 生成新的数据库 schema（bump schema version）

### 步骤 9：测试验证

1. 冷启动：首次安装 → 创建用户 → 进入主界面
2. 热启动：已有数据 → 直接进入主界面
3. CRUD：添加鸟类、记录体重、创建用药计划
4. 飞行模式：关闭网络 → 所有功能正常工作
5. 数据持久化：杀掉应用 → 重新打开 → 数据完整

---

## 三、不改动的部分

以下代码保持不变：

- ✅ `lib/repositories/` — Repository 层已经是 DB 直连
- ✅ `lib/screens/shell/mobile_shell.dart` — 主界面使用本地 providers
- ✅ `lib/screens/weigh/`, `birds/`, `rooms/`, `species/`, `tasks/` — 所有业务页面
- ✅ `lib/core/` — 插件架构（EventBus, PluginRegistry, PluginPageManager）
- ✅ `lib/plugins/` — WeightPlugin, MedicationPlugin
- ✅ `lib/database/database.dart` — AppDatabase（Drift）
- ✅ `lib/screens/settings/` — 设置页面（移除连接相关项）

---

## 四、最终架构

```
┌────────────── 手机 (Android/iOS) ──────────────┐
│  Flutter App                                    │
│  ┌──────────────────────────────────────┐      │
│  │  main.dart → app.dart                 │      │
│  │  → SplashScreen (检查本地用户)        │      │
│  │  → 首次? 创建用户 : 直接进入          │      │
│  └──────────────────────────────────────┘      │
│  ┌──────────────────────────────────────┐      │
│  │  MobileShell (底部导航)               │      │
│  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ │      │
│  │  │首页│ │任务│ │称重│ │鹦鹉│ │设置│ │      │
│  │  └────┘ └────┘ └────┘ └────┘ └────┘ │      │
│  └──────────────────────────────────────┘      │
│  ┌──────────────────────────────────────┐      │
│  │  Plugin 层                            │      │
│  │  - WeightPlugin (体重记录+图表)       │      │
│  │  - MedicationPlugin (用药管理+日历)   │      │
│  └──────────────────────────────────────┘      │
│  ┌──────────────────────────────────────┐      │
│  │  Drift DB (本地 SQLite)               │      │
│  │  Species / Birds / Weights / Tasks    │      │
│  │  Rooms / Users / Medications          │      │
│  │  AlertRecords                         │      │
│  └──────────────────────────────────────┘      │
└────────────────────────────────────────────────┘
```

---

## 五、工作量估算（修订）

| 步骤 | 内容 | 预估时间 |
|------|------|----------|
| 步骤 1 | 创建分支 | 1 分钟 |
| 步骤 2 | 改造 SplashScreen | 1-2 小时 |
| 步骤 3 | 简化用户系统 | 1 小时 |
| 步骤 4 | 禁用同步引擎 | 30 分钟 |
| 步骤 5 | 移除 SyncQueue 调用 | 1-2 小时 |
| 步骤 6 | 移除不需要的服务/UI | 1-2 小时 |
| 步骤 7 | 清理 pubspec.yaml | 15 分钟 |
| 步骤 8 | 数据库迁移 | 1 小时 |
| 步骤 9 | 测试验证 | 1-2 小时 |
| **合计** | | **6-12 小时** |

---

## 六、风险与注意事项

| 风险 | 说明 | 缓解 |
|------|------|------|
| 数据库迁移丢失数据 | 简化 Users 表、移除 SyncQueue 需要迁移 | 先备份 `weight_nest.db` |
| 桌面端编译失败 | 移除共享服务可能影响桌面端 | 用条件导入或在 `app.dart` 中隔离 |
| 插件 serverRoutes 未被调用 | 手机端不启动服务器，但插件仍注册 serverRoutes | 不影响功能，后续清理 |

---

## 七、决策记录

| 决策 | 结论 |
|------|------|
| 目标平台 | 仅 Android/iOS |
| 用户模式 | 单用户（无登录，无密码） |
| 数据导入 | 不保留从桌面端导入的能力 |
| 分支名 | `feature/offline-mvp` |
| 桌面端 | 不改动（保留现有桌面端功能） |
| SyncEngine | 移除（不保留，后续需要可恢复） |
