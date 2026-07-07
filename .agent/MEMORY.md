# WeightNest 项目记忆

## 项目做什么
鹦鹉体重记录 App。MVP 阶段：纯本地单用户，手机端独立运行。

## 当前进度（2026-06-13）

### 离线 MVP（feature/offline-mvp）✅
- 移除全部后端依赖（Shelf 服务器、SyncEngine、SyncQueue、mDNS 发现、扫码连接）
- 单用户模式：输入昵称即进入，无密码无登录
- 移动端 5 tab：首页 / 任务 / 称重 / 鹦鹉 / 设置
- 数据全部本地 SQLite（Drift），数据库名 `weight_nest_mvp.db`
- 房间管理：首页「我的房间」区域可创建/管理房间
- 物种管理：设置页可管理鸟类品种
- 插件架构保留：WeightPlugin + MedicationPlugin
- 桌面端代码未改动，`app.dart` 中 `isDesktop` 临时设为 `false` 用于测试

### 分支
- `feature/offline-mvp` — 当前 MVP 开发分支
- `feature/plugin-architecture` — 插件架构基线（已完成）
- `feature/sqlite-standalone` — 独立服务端（已完成）
- `main` — 稳定版本

## 开发规范

- [Development SOP](memory/development_sop.md) — 热重载、数据库变更、代码风格规范
- [Auto-build after changes](memory/feedback_auto_build.md) — code changes trigger build.ps1 -Mobile + -Desktop + deploy.ps1
- [Release workflow](memory/feedback_release_workflow.md) — bump version → build all artifacts + commit + push

## 待开发
- [ ] 首页房间列表增加鸟类预览
- [ ] 数据备份/恢复（SQLite 文件导出导入）
- [ ] APK 构建验证

## 已知问题
- Windows 桌面端以移动 UI 模式运行（临时绕过），需恢复 `isDesktop` 判断
- `lib/app.dart:40` 已修复 unnecessary `!` assertion
- 桌面端代码中部分 unused field 警告（非本次修改引入，不影响移动端）
