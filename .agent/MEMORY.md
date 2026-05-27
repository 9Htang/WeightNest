# WeightNest 项目记忆

## 项目做什么
鹦鹉体重记录 App。核心能力：离线记录体重 → 后台自动同步到中央服务器 → 多设备数据统一。

## 当前进度（2026-05-27）
- 数据层重构完成：uuid, sync_queue, device_id, 软删除, updated_at
- SyncQueueService：称重后自动入队
- SyncEngine：5秒定时推送/拉取，操作日志幂等
- Docker 服务端：Dart shelf + PostgreSQL，4 API 全部验证通过
- 扫码连接：ConnectScreen（mobile_scanner 5.2.3）
- 设置页简化：只保留连接服务器 + Excel 导出
- 版本: 1.7.5+22

## 已完成功能
- 快速称重（大键盘、自动下一只、空腹默认勾选）
- 鹦鹉/房间/品种/用户 CRUD
- 局域网联机（旧架构 → 已废弃，新架构扫码连接）
- Excel 导出（纵轴日期、横轴鹦鹉、WrapText、非空腹标*）
- 异常检测（体重下降/增长停滞/超期未称重）
- 任务自动生成
- Codemagic 构建配置

## 技术选型
- Flutter 3.27 / Dart 3.6
- Drift 2.28 (SQLite)
- Riverpod (状态管理)
- shelf (服务端 HTTP)
- PostgreSQL 16 via Docker
- mobile_scanner 5.2.3 (扫码)
- share_plus, excel 4.0.6, uuid

## 已知问题
- AP 隔离 → 手机和电脑直连不通，需要路由器设置或 adb reverse
- 旧 SettingsScreen 代码（server/client mode）已移除，旧 UI 链路需清理
- 桌面端 WeightNest 窗口未集成新同步架构
- SyncEngine 未显示同步状态到 UI

## 修复记录
- excel 4.0.6 delete() 在单 sheet 时无效 → 改用 rename()
- mobile_scanner ^6.0 需要 SDK36+drift web 冲突 → 降至 ^5.2.3
- PostgreSQL 需要 WSL2/Docker 环境 → Docker 化零安装部署
