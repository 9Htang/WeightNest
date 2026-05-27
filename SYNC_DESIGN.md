# WeightNest 数据同步方案 — 当前状态

## 当前架构

### 服务端（嵌入在 App 内）
- **文件**: `lib/server/server_service.dart` — shelf HTTP 服务器，端口 8080
- **路由**: `lib/server/routes.dart` — REST API，挂载在 `/api/` 下
- **路由表**:
  - `GET /api/health` — 健康检查
  - `GET /api/species` — 所有品种
  - `POST /api/species` — 新增品种
  - `GET /api/rooms`, `POST /api/rooms`, `PUT /api/rooms/<id>`, `DELETE /api/rooms/<id>`
  - `GET /api/birds`, `GET /api/birds/<id>`, `POST /api/birds`, `PUT /api/birds/<id>`, `DELETE /api/birds/<id>`
  - `GET /api/weights/<birdId>`, `GET /api/weights/<birdId>/latest`, `POST /api/weights`
  - `GET /api/tasks/today`, `GET /api/tasks/overdue`, `POST /api/tasks/<id>/complete`, `POST /api/tasks/generate`
  - `GET /api/users`
- **启动/停止**: `NetworkNotifier.startServer()` / `stopServer()` in `lib/services/network_service.dart`
- **数据库表**: Species, Users, Rooms, Birds, Weights, Tasks, AlertRecords, SyncLog
- **数据库表定义**: `lib/database/tables.dart`

### 客户端
- **文件**: `lib/services/sync_service.dart` — HTTP 拉取 + 去重写入
- **触发**: 设置页手动点「同步数据」按钮
- **流程**: `syncAll()` → 依次调用 `_syncSpecies` / `_syncRooms` / `_syncUsers` / `_syncBirds` / `_syncWeights`
- **去重策略**:
  - 物种: 按 name
  - 房间: 按 name
  - 用户: 按 username
  - 鹦鹉: 按 name + birthDate
  - 体重: 按 birdId + minute 精度时间戳

### 网络发现
- **文件**: `lib/services/discovery_service.dart`
- **方式**: UDP 广播 8082 + 组播 239.255.0.1
- **当前问题**: 路由器 AP 隔离导致发现失败，只能用手动输入 IP

### 模式切换
- **文件**: `lib/services/network_service.dart`
- `NetworkNotifier` 管理 `ConnectionMode.standalone | server | client`
- UI 在 `lib/screens/settings/settings_screen.dart` 设置页

## 当前方案局限
1. **单向拉取** — 只能客户端从服务端拉数据，客户端写入不同步回服务端
2. **全量拉取** — 每次都拉全部数据，没有增量机制
3. **被动触发** — 用户手动点「同步数据」才会同步
4. **UDP 发现不可靠** — AP 隔离环境下必须手动 IP
5. **无冲突处理** — 两端同时改同一条记录无冲突解决
6. **SyncLog 表闲置** — 数据库有 SyncLog 表但未使用

## 已修复的同步 bug
- `lib/server/server_service.dart`: 加 `/api` 路由前缀 mount（原来 router 挂根路径导致 `/api/health` 404）
- `lib/server/routes.dart`: `/api/birds` 列表补 speciesId/roomId/notes 字段（原来客户端解析 null→int 崩溃）
- `lib/services/sync_service.dart`: 
  - `_syncBirds` 加去重 `getBirdByNameAndBirth`
  - `syncAll` 每表独立 try-catch，单表失败不中断
  - 空值保护 `speciesId ?? 1`, `roomId as int?`
- `lib/repositories/bird_repository.dart`: 新增 `getBirdByNameAndBirth()` 方法
- `lib/screens/settings/settings_screen.dart`: 同步成功后补 invalidate species/tasks/alerts provider
- `lib/services/network_service.dart`: stopServer 加 try-catch 容错

## 关键 Provider
- `lib/providers.dart`:
  - `allBirdsProvider`, `allRoomsProvider`, `allSpeciesProvider`
  - `todayTasksProvider`, `overdueTasksProvider`
  - `alertCountProvider`, `birdWeightsProvider`, `latestWeightProvider`
  - `weightSavedProvider` (StateProvider 触发器)
  - `networkProvider`

## 其他相关
- **Excel 导出**: `lib/services/excel_export_service.dart` — 纵轴日期横轴鸟，三行表头，WrapText，非空腹标 `*`
- **称重**: `lib/screens/weigh/weigh_screen.dart` + `weigh_provider.dart` — isFasting 默认 true
- **数据库 ORM**: drift 2.28.2，表定义 `lib/database/tables.dart`
- **项目根**: `C:\Users\Cwb\.openclaw\workspace\projects\WeightNest`
- **Git**: github.com/9Htang/WeightNest，已全部 commit+push
