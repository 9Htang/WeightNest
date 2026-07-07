---
name: development-sop
description: WeightNest MVP 开发工作流 SOP — 必读操作规范
metadata:
  type: project
---

# WeightNest 开发 SOP

## 1. 分支结构

- `main` — 稳定版本，不直接提交
- `feature/offline-mvp` — 当前 MVP 开发分支（从 `feature/plugin-architecture` 创建）
- `feature/plugin-architecture` — 插件架构基线（已完成，不再修改）

## 2. 测试运行

MVP 在 Windows 桌面端以移动 UI 模式测试：

```bash
flutter run -d windows
```

**关键**：`lib/app.dart` 中 `isDesktop` 已临时设为 `false`，使桌面端运行移动 UI。合入前恢复。

## 3. 热重载规则

**每次修改代码后必须自动热重载**，流程如下：

1. 代码修改完成
2. 检查是否有运行中的 `flutter run` 会话（`Get-Process weight_nest`）
3. 如果有 → 通过 Flutter VM Service 触发热重载：
   ```
   Invoke-RestMethod -Uri "http://127.0.0.1:<port>/<token>/" # 获取 isolate
   Invoke-RestMethod -Uri "http://127.0.0.1:<port>/<token>/<isolateId>/reloadSources" -Method Post -Body '{}'
   ```
4. 如果没有 → 重新 `flutter run -d windows`
5. 修改涉及 `tables.dart` 或 `database.dart`（Drift schema）→ 先 `dart run build_runner build --delete-conflicting-outputs` 再 Full Restart

## 4. 数据库变更

- 不要删除 `SyncQueue` 表（保留以兼容旧数据库）
- 改了 Drift schema → 必须执行 `dart run build_runner build --delete-conflicting-outputs`
- 当前数据库名：`weight_nest_mvp.db`（避免与旧版本冲突）
- 数据库路径：`%APPDATA%\com.weightnest\weight_nest_mvp.db`

## 5. 代码风格

- 移动端页面放 `lib/screens/` 下
- 删除文件时直接 `Remove-Item`，不保留注释或隐藏
- 不修改桌面端代码（`lib/desktop/`）
- 新增功能优先在现有页面加入口，不新增独立屏幕

## 6. 验证标准

- `flutter analyze lib/` — 0 errors（warnings 允许但尽量修复新引入的）
- 每次改动后在桌面端验证 UI 能正常显示

## 7. 当前状态

- 单用户模式，无需登录/密码
- 移动端 5 tab：首页 / 任务 / 称重 / 鹦鹉 / 设置
- 房间创建：首页「我的房间」区域（管理按钮 + 空态创建按钮）
- 数据库：本地 SQLite，无后端依赖
