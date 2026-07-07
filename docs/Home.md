# WeightNest 🦜

> 鹦鹉体重记录系统 — 离线单机版 MVP

WeightNest 是一款面向鹦鹉繁育者的移动端管理应用，以**体重追踪**为核心，通过插件式架构扩展至用药管理、繁育记录、照片相册等功能。完全离线运行，数据存储在本地 SQLite 数据库中。

---

## ✨ 核心特性

- **📊 体重追踪** — 智能称重记录，EWMA 基线分析，多维度异常告警
- **💊 用药管理** — 药品库、剂量计算（mg/kg→ml）、喂药排程、副作用追踪
- **🥚 繁育管理** — 配对、产蛋、孵化、育雏全流程管理
- **📸 照片相册** — 鹦鹉照片管理、头像设置、实况照片支持
- **🔔 智能提醒** — 根据称重间隔和用药计划自动生成待办任务
- **⚡ 告警系统** — 体重下降、增长停滞、超期未称重等异常自动检测
- **💾 数据备份** — WNBK 格式完整备份/恢复，SHA256 完整性校验
- **📤 数据导出** — Excel 月度体重报表、WNBD 鸟只导入导出

---

## 🛠 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x (Dart 3.6+) |
| 数据库 | Drift (SQLite) |
| 状态管理 | flutter_riverpod |
| 图表 | fl_chart |
| 本地通知 | flutter_local_notifications |
| Excel 导出 | excel |
| 备份格式 | archive (ZIP) + crypto (SHA256) |
| CI/CD | Codemagic (Android APK/AAB, iOS IPA) |

---

## 📖 文档目录

| 文档 | 说明 |
|------|------|
| [架构设计](architecture.md) | 整体架构、分层说明、启动流程、核心设计决策 |
| [插件系统](plugin-system.md) | FeaturePlugin 接口、Slot 扩展点、EventBus、如何添加新插件 |
| [数据库设计](database.md) | 25 张表 Schema、17 版迁移历史、Repository 模式 |
| [服务层](services.md) | 各服务职责说明、Riverpod Provider 全景 |
| [内置插件详解](plugins-guide.md) | Weight / Medication / Breeding / Gallery 插件详解 |
| [开发指南](development.md) | 环境搭建、代码生成、调试工具、测试策略、CI/CD |
| [变更日志](changelog.md) | 数据库 Schema 演进、主要功能里程碑 |

---

## 📁 项目结构概览

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # MaterialApp + ProviderScope
├── core/                     # 核心框架层
│   ├── plugin.dart           # FeaturePlugin 抽象接口
│   ├── plugin_registry.dart # 插件注册中心
│   ├── plugin_page_manager.dart # 页面实例管理
│   ├── event_bus.dart        # 类型化事件总线
│   ├── events.dart           # 领域事件定义
│   └── app_clock.dart        # 可注入时钟（测试用）
├── database/                 # 数据库层
│   ├── tables.dart           # 核心表定义（14 张）
│   └── database.dart         # Drift 数据库 + 17 版迁移
├── repositories/             # 数据访问层（Drift Extension 模式）
├── services/                 # 业务服务层
├── providers.dart            # Riverpod Provider 集中定义
├── plugins/                  # 插件目录
│   ├── plugins.dart          # 插件注册入口
│   ├── weight/               # 体重追踪插件
│   ├── medication/           # 用药管理插件
│   ├── breeding/             # 繁育管理插件
│   ├── gallery/              # 照片相册插件
│   └── debug/                # 调试工具插件（仅 debug）
├── screens/                  # UI 页面
├── widgets/                  # 通用组件
├── theme/                    # 主题（明/暗）
└── utils/                    # 工具函数
```

---

## 🏗 架构概览

```
┌─────────────────────────────────────────┐
│              MobileShell                │
│         (底部导航 · 4 个 Tab)            │
├─────────────────────────────────────────┤
│              Screens                    │
│   首页 · 任务 · 鸟只列表 · 设置            │
├─────────────────────────────────────────┤
│         Plugin Page Manager             │
│     (Slot A: 插件页面实例管理)            │
├─────────────────────────────────────────┤
│           Feature Plugins               │
│  WeightPlugin · MedicationPlugin         │
│  BreedingPlugin · GalleryPlugin          │
├─────────────────────────────────────────┤
│    PluginRegistry + EventBus            │
│  (Slot 聚合 · 跨插件通信 · 统一写入)       │
├─────────────────────────────────────────┤
│    Riverpod Providers (providers.dart)  │
├──────────┬──────────────────────────────┤
│ Services │        Repositories          │
│ Operation│  Bird · Weight · Task · Room  │
│ Alert    │  Species · Enclosure · User    │
│ Backup   │                              │
├──────────┴──────────────────────────────┤
│         AppDatabase (Drift/SQLite)       │
│            25 张表 · v17 Schema          │
└─────────────────────────────────────────┘
```

> 详细架构说明请阅读 [架构设计](architecture.md) 和 [插件系统](plugin-system.md)。

---

## 🚀 快速开始

```bash
# 克隆仓库
git clone <repo-url>
cd WeightNest

# 安装依赖
flutter pub get

# 代码生成（Drift ORM）
dart run build_runner build --delete-conflicting-outputs

# 运行
flutter run
```

> 完整开发指南请阅读 [开发指南](development.md)。
