# WeightNest 新同步架构 — 实现路径

> 基于小豆提供的离线优先多人同步方案，对照当前代码的改造计划

## 部署架构

```
                 [Go/Node.js Server]
                 PostgreSQL + Sync API
                 WebSocket Broadcaster
                       ↑↓
              HTTP/WebSocket
                       ↑↓
     ┌──────────┼──────────┬──────────┐
     ↓          ↓          ↓          ↓
  Client A   Client B   Client C   Client D
  (手机)     (手机)     (手机)     (电脑)
  
  各客户端：SQLite 本地库 + sync_queue + Sync Engine
```

## 改造清单

### 阶段 1: 数据层改造

| # | 改动 | 文件 | 说明 |
|---|------|------|------|
| 1.1 | 所有实体加 UUID 主键 | `lib/database/tables.dart` | `id` 从自增 Integer 改为 String UUID |
| 1.2 | 新增 `sync_queue` 表 | `lib/database/tables.dart` | `id, op_id(UUID), action, payload(JSON), created_at, synced, retry_count` |
| 1.3 | 新增 `device_id` 存储 | `lib/database/tables.dart` 或 SharedPreferences | 首次启动生成，持久化 |
| 1.4 | 所有表加 `updated_at` | `lib/database/tables.dart` | 增量同步需要时间戳过滤 |
| 1.5 | 软删除字段 | `lib/database/tables.dart` | `deleted_at INTEGER NULL` |
| 1.6 | 生成 drift 代码 | `dart run build_runner build` | |

### 阶段 2: 写入流程改造（离线优先）

| # | 改动 | 文件 | 说明 |
|---|------|------|------|
| 2.1 | 封装 `SyncQueue` 服务 | `lib/services/sync_queue_service.dart` | 写入操作时顺便写入 sync_queue |
| 2.2 | 改造称重写入 | `lib/screens/weigh/weigh_provider.dart` | `addWeight` → 写本地 + 写 sync_queue |
| 2.3 | 改造鸟/房间/品种 CURD | `lib/repositories/*.dart` | 所有写操作同步入队 |
| 2.4 | 生成 UUID 工具 | `lib/utils/uuid.dart` | 每条记录全局唯一 ID |

### 阶段 3: 同步引擎

| # | 改动 | 文件 | 说明 |
|---|------|------|------|
| 3.1 | SyncEngine 后台定时器 | `lib/services/sync_engine.dart` | 每5秒/网络恢复/回前台时触发 |
| 3.2 | 上传未同步操作 | `lib/services/sync_engine.dart` | `POST /sync` 批量上传 opId 列表 |
| 3.3 | 标记已同步 | `lib/services/sync_engine.dart` | 服务端返回 successOps 后标记 synced=1 |
| 3.4 | 增量拉取 | `lib/services/sync_engine.dart` | `GET /changes?since=lastSyncTime` |
| 3.5 | 合并到本地 | `lib/services/sync_engine.dart` | 远端数据写入本地 SQLite |
| 3.6 | 连接检测 | `connectivity_plus` | pubspec 加依赖 |
| 3.7 | SyncEngine Provider | `lib/providers.dart` | 全局同步状态 |

### 阶段 4: 服务端

| # | 改动 | 文件 | 说明 |
|---|------|------|------|
| 4.1 | op_id 唯一约束 | 服务端 DB | `UNIQUE(op_id)` |
| 4.2 | `POST /sync` 端点 | 服务端 API | 接收操作日志列表，幂等处理 |
| 4.3 | `GET /changes?since=` | 服务端 API | 增量返回变更数据 |
| 4.4 | WebSocket 广播 | 服务端 | 后期实现实时推送 |

### 阶段 5: UI

| # | 改动 | 文件 | 说明 |
|---|------|------|------|
| 5.1 | 同步状态指示器 | 主页面 | 「已同步 / 同步中 / 离线 / 待同步(12)」|
| 5.2 | 移除旧同步 UI | `lib/screens/settings/settings_screen.dart` | 替换手动同步按钮 |
| 5.3 | 设备标识显示 | 设置页 | 显示 device_id 用于排查 |

## 关键原则

- **永远先写本地** — 用户等不起网络
- **同步操作不是对象** — sync_queue 记录的是 action + payload
- **op_id 幂等** — 服务端 UNIQUE，重复直接忽略
- **增量拉取** — 客户端携带 lastSyncTime
- **软删除** — 同步系统不用真删除

## 从当前代码过渡

- **保留**: drift + SQLite（已就绪 ✅）
- **保留**: Riverpod 状态管理 ✅
- **新增**: sync_queue 表 + SyncEngine 服务
- **替换**: 当前 SyncService（全量 HTTP 拉取）→ 操作日志队列同步
- **替换**: 嵌入式 shelf 服务器 → 独立中央服务器
- **废弃**: UDP 广播发现（中央服务器固定 IP）
- **废弃**: 客户端/服务器模式切换（统一客户端连中央服务器）
