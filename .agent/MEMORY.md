# WeightNest 项目记忆

## 项目做什么
鹦鹉体重记录 App。双端架构：手机端负责称重记录，Windows 桌面端负责管理与数据分析。

## 当前进度（2026-05-28）

### 移动端 ✅
- Phase 1-8 全部完成
- 数据层：uuid, sync_queue, device_id, 软删除, updated_at
- SyncQueueService + SyncEngine 5秒定时推送/拉取
- 扫码连接 (mobile_scanner 5.2.3)
- Excel 导出 (临时目录 + 分享按钮)
- 首页强制员工登录拦截
- LoginScreen：扫码登录入口始终显示 + 空密码直通
- WorkerNotifier：admin 自动清除登录

### 桌面端 ✅
- **操作日志审计** — 分页表格，按人/类型/时间筛选，变更明细汉化
- **鹦鹉全息档案** — 搜索、体重趋势、病史时间轴
- **人员管理** — 创建/编辑/启停账号（Admin/Keeper/Viewer）
- 侧边栏导航，3秒轮询 data-version 自动刷新
- QR 扫码登录弹窗（CustomPaint 手绘二维码，全平台通用）
- LAN IP 自动检测（跳过虚拟网卡，优先 WLAN）

### 服务端 ✅
- Docker Compose 部署 (shelf + PostgreSQL)
- API：/health, /auth/connect, /sync, /changes, /data-version
- /birds, /birds/:id, /birds/:id/weights
- /users, POST /users, PATCH /users/:id
- /audit-log（分页+筛选+JOIN）
- /auth/qr-session, /auth/qr-login（扫码免密）
- /qr?session=XXX&host=XXX（浏览器二维码页）
- 创建/更新用户时写入 change_log
- SERVER_HOST 可选配置（桌面端自动检测传入）

### APK
- 版本 v1.7.8+25
- 构建：`build.ps1 -Mobile`（读取 pubspec 版本号）
- arm64 单一架构（全架构 OOM）

### 一键部署
- `deploy.ps1` — 防火墙放行 + Docker Compose + 桌面端启动
- 防火墙规则：`netsh advfirewall firewall add rule name="WeightNest" dir=in action=allow protocol=TCP localport=8080`

## 待开发
- [ ] UDP 广播自动发现（手机端发广播 → 桌面端应答 IP）
- [ ] 数据报表导出模块（桌面端第四模块）
- [ ] 全架构 APK（x86 兼容）

## 已知问题
- Excel 导出 Android scoped storage → 改用临时目录 + 分享
- AP 隔离 → 手机和电脑直连不通，需路由器设置
- qr_flutter 在 Windows 上有渲染问题 → 手绘 CustomPaint 替代
- Flutter Windows Authorization header 被拦截 → 改用 X-Token

- [Auto-build after changes](memory/feedback_auto_build.md) — code changes trigger build.ps1 -Mobile + -Desktop + deploy.ps1

## 修复记录
- excel 4.0.6 delete() 在单 sheet 无效 → 改用 rename()
- mobile_scanner ^6.0 需 SDK36 → 降至 ^5.2.3
- PostgreSQL 需 WSL2/Docker → Docker 化部署
- LAN IP 检测被 WSL/VMware 虚拟网卡抢占 → 跳过虚拟卡 + 优先 WLAN
- qr_flutter Windows 界面变灰 → 移除，用 qr 包 CustomPaint 手绘
