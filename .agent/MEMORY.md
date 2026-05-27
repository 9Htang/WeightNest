# WeightNest 项目记忆

## 项目做什么
鹦鹉体重记录 App。双端架构：手机端负责称重记录，Windows 桌面端负责管理与数据分析。

## 当前进度（2026-05-27）

### 已完成
- 移动端 Phase 1-8 全部完成
- 数据层重构：uuid, sync_queue, device_id, 软删除, updated_at
- SyncQueueService + SyncEngine 5秒定时推送/拉取
- Docker 服务端：Dart shelf + PostgreSQL，4 API 全部验证
- 扫码连接：ConnectScreen (mobile_scanner 5.2.3)
- Excel 导出（纵轴日期、横轴鹦鹉、WrapText、非空腹标*）
- 首页强制员工登录拦截
- 版本: 1.7.6+23

### 桌面端（新阶段 — 进行中）
目标：Flutter Windows 管理控制台

**四大模块：**
1. **操作日志审计** — 全量日志表格，按人/类型/时间筛选，变更明细追溯
2. **鹦鹉全息档案** — 全局搜索、体重趋势折线图、病历时间轴
3. **人员管理** — 创建账号（仅桌面端）、分配 Admin/Keeper/Viewer 角色、启停
4. **数据报表导出** — 自定义导出范围、系统保存对话框

**系统约束：**
- 所有写入走 Shelf API（不直连 PG）
- op_id 幂等、Last Write Wins、软删除
- 账号创建仅限桌面端

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
- 桌面端窗口未集成同步架构
- 手机端需要移除账号创建 UI

## 修复记录
- excel 4.0.6 delete() 在单 sheet 时无效 → 改用 rename()
- mobile_scanner ^6.0 需要 SDK36+drift web 冲突 → 降至 ^5.2.3
- PostgreSQL 需要 WSL2/Docker 环境 → Docker 化零安装部署
