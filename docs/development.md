# 开发指南

本文档涵盖 WeightNest 的开发环境搭建、代码规范、调试工具、测试策略和 CI/CD 流水线。

---

## 环境搭建

### 前置要求

- Flutter SDK 3.x（Dart 3.6+）
- Android Studio / VS Code
- Android SDK（Android 开发）
- Xcode（iOS 开发，仅 macOS）

### 安装步骤

```bash
# 1. 克隆仓库
git clone <repo-url>
cd WeightNest

# 2. 安装依赖
flutter pub get

# 3. 代码生成（Drift ORM 生成 database.g.dart）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run
```

### 持续监听代码生成

开发中修改了 `tables.dart` 后需要重新生成：

```bash
# 监听模式（推荐）
dart run build_runner watch --delete-conflicting-outputs

# 一次性构建
dart run build_runner build --delete-conflicting-outputs
```

---

## 项目结构

```
lib/
├── main.dart                  # 入口（注册插件 → 初始化服务 → 启动 App）
├── app.dart                   # MaterialApp + ProviderScope + 文件分享处理
├── core/                      # 🔧 核心框架（插件接口、事件总线、注册中心）
│   ├── plugin.dart            # FeaturePlugin 抽象类 + 支持类型
│   ├── plugin_registry.dart   # 全局插件注册中心
│   ├── plugin_page_manager.dart
│   ├── event_bus.dart
│   ├── events.dart
│   ├── app_clock.dart
│   └── debug_log_sink.dart
├── database/                  # 🗄️ 数据库层
│   ├── tables.dart            # 14 张核心表定义
│   └── database.dart          # Drift 数据库 + 17 版迁移
├── repositories/               # 📦 数据访问层（Drift Extension）
│   ├── bird_repository.dart
│   ├── weight_repository.dart
│   ├── task_repository.dart
│   ├── species_repository.dart
│   ├── room_repository.dart
│   ├── enclosure_repository.dart
│   └── user_repository.dart
├── services/                  # ⚙️ 服务层
│   ├── operation_service.dart
│   ├── alert_service.dart
│   ├── backup_service.dart
│   ├── bird_import_service.dart
│   ├── bird_export_service.dart
│   ├── excel_export_service.dart
│   ├── license_service.dart
│   ├── notification_service.dart
│   ├── motion_photo_service.dart
│   ├── work_hours_config.dart
│   └── log/app_logger.dart
├── providers.dart             # 📡 Riverpod Provider 集中定义
├── plugins/                   # 🧩 插件目录
│   ├── plugins.dart           # registerPlugins() 入口
│   ├── weight/                # 体重追踪（3 文件）
│   ├── medication/            # 用药管理（14 文件）
│   ├── breeding/              # 繁育管理（5 文件）
│   ├── gallery/               # 照片相册（6 文件）
│   └── debug/                  # 调试工具（6 文件）
├── screens/                   # 📱 UI 页面
│   ├── shell/                  # MobileShell（底部导航）
│   ├── birds/                  # 鸟只列表 / 详情
│   ├── weigh/                  # 称重（单只 / 批量）
│   ├── tasks/                  # 今日任务
│   ├── rooms/                  # 房间管理
│   ├── enclosures/             # 容器管理
│   ├── species/                # 品种管理
│   ├── alerts/                 # 告警列表
│   ├── settings/               # 设置 / 导入导出
│   └── worker/                 # 饲养员选择
├── widgets/                   # 🧱 通用组件
│   ├── weight_chart.dart       # 体重趋势图（fl_chart）
│   ├── section_header.dart
│   ├── empty_state.dart
│   ├── stat_number.dart
│   └── warm_card.dart
├── theme/                      # 🎨 主题（明/暗）
│   ├── theme.dart
│   └── theme_notifier.dart
└── utils/                      # 🔧 工具函数
    ├── app_version.dart
    ├── device_id.dart
    └── uuid.dart
```

---

## 代码规范

### 命名约定

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | snake_case | `weight_plugin.dart` |
| 类名 | PascalCase | `WeightPlugin` |
| Provider | camelCase + Provider 后缀 | `allBirdsProvider` |
| 数据库表 | PascalCase | `Weights`, `Birds` |
| 表字段 | camelCase | `weightG`, `recordedAt` |
| 插件 ID | kebab-case | `'weight'`, `'medication'` |
| 事件类型 | kebab-case | `'weight_recorded'` |

### 注释风格

- 核心表和字段使用中文注释（面向中文用户/开发者）
- 代码逻辑注释使用英文或中文
- 公共 API 使用 `///` 文档注释

### 软删除模式

所有核心表遵循：
```dart
DateTimeColumn get deletedAt => dateTime().nullable(); // 软删除
```
查询时需要过滤 `deletedAt IS NULL`。

### UUID 模式

所有表有 `uuid` 字段用于导入导出时的唯一标识：
```dart
TextColumn get uuid => text().unique()();
```

---

## 调试工具

### AppClock — 时间控制

`lib/core/app_clock.dart` 提供 debug 模式下的时间偏移功能：

```dart
// Debug 模式
AppClock.override(DateTime(2025, 1, 15));  // 设置时间
AppClock.advance(Duration(days: 1));        // 前进一天
AppClock.reset();                            // 恢复真实时间

// Release 模式
AppClock.now == DateTime.now();              // 直接返回真实时间（零开销）
```

- 时间偏移持久化到 SharedPreferences（重启后保留）
- Release 模式通过 `assert(kDebugMode, ...)` tree-shaking，零运行时开销

### DebugLogSink — 日志拦截

```dart
// 在 main() 最开始安装（必须在 WidgetsFlutterBinding 之前）
if (kDebugMode) {
  DebugLogSink.install();
}

// 环形缓冲区（1000 条，FIFO）
DebugLogSink.entries;           // 最新在前
DebugLogSink.filter(tag, query); // 按标签/关键词过滤
```

### DebugPlugin — 调试仪表盘

Debug 模式下自动注册，提供：

| 页面 | 功能 |
|------|------|
| DebugDashboardScreen | 总览（插件状态、数据库信息） |
| DBInspectorScreen | 浏览数据库表内容 |
| LogViewerScreen | 查看应用日志 |
| PluginStatusScreen | 插件启用状态、Slot 贡献一览 |
| TaskEditorScreen | 手动创建/编辑任务（调试用） |

---

## 测试策略

> 完整测试策略文档：[testing-strategy.md](testing-strategy.md)

### 测试分层

| 层级 | 类型 | 说明 |
|------|------|------|
| L1 | Unit | 纯函数测试（weight_math、dose_math） |
| L2 | Repository | 数据库 CRUD 测试（内存 DB） |
| L3 | Service | 服务层集成测试 |
| L4 | Plugin | 插件告警/任务检测测试 |
| L5 | Widget | UI 组件测试 |
| L6 | E2E | 端到端测试 |

### 测试基础设施

**Test Helpers**（`test/test_helpers/test_factories.dart`）：

```dart
// 创建测试用内存数据库（自动注入 PluginRegistry）
final db = setUpTestDb();

// 工厂方法
final species = await createTestSpecies(db);
final bird = await createTestBird(db, speciesId: species.id, daysAgo: 30);
await addWeightSeries(db, bird.id, [
  (hoursAgo: 72, weightG: 30.0),
  (hoursAgo: 48, weightG: 33.0),
  (hoursAgo: 24, weightG: 35.0),
]);

// 清理
await tearDownTestDb(db);
```

### 运行测试

```bash
# 全部测试
flutter test

# 指定文件
flutter test test/unit/weight_math_test.dart

# 指定目录
flutter test test/repositories/

# 集成测试
flutter test test/integration_test.dart
```

### 测试文件结构

```
test/
├── test_helpers/
│   └── test_factories.dart          # 共享测试工具
├── unit/
│   ├── weight_math_test.dart        # 体重算法单元测试
│   └── dose_calculation_test.dart  # 剂量计算单元测试
├── repositories/
│   ├── bird_repository_test.dart
│   ├── weight_repository_test.dart
│   └── task_repository_test.dart
├── services/
│   ├── operation_service_test.dart
│   └── backup_service_test.dart
├── migration/
│   └── migration_test.dart          # Schema 迁移测试
├── integration_test.dart            # 集成测试（66 个用例）
├── alert_algorithm_test.dart        # 告警算法测试
└── alert_algorithm_test_tool.html   # 浏览器端算法测试工具
```

---

## CI/CD 流水线

> 配置文件：`codemagic.yaml`

### Android 构建

```yaml
workflow: android-build
触发: push/PR
步骤:
  1. flutter pub get
  2. flutter analyze
  3. flutter test
  4. flutter build apk --release
  5. flutter build appbundle --release
产物: APK + AAB
```

### iOS 构建（无签名）

```yaml
workflow: ios-build
步骤:
  1-3. 同 Android
  4. flutter build ios --no-codesign
产物: Runner.app + Xcode 日志
```

### iOS 构建（签名）

```yaml
workflow: ios-signed
额外步骤:
  - 安装证书
  - flutter build ipa --export-options-plist $CM_EXPORT_OPTIONS
产物: IPA
```

> 所有工作流超时 60 分钟。邮件通知需在 Codemagic UI 中配置收件人。

---

## 添加新的数据库迁移

当修改 `tables.dart` 后：

### 1. 更新 Schema 版本

```dart
// lib/database/database.dart
@override
int get schemaVersion => 18;  // 递增

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 18) {
      // 迁移逻辑
    }
  },
);
```

### 2. 编写迁移代码

```dart
if (from < 18) {
  // 添加新列
  await m.addColumn(birds, birds.newColumn);
  // 或创建新表
  await m.createTable(newTable);
  // 或添加索引
  await m.createIndex(Index('new_table', 'CREATE INDEX ...'));
}
```

### 3. 重新生成代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. 编写迁移测试

```dart
// test/migration/migration_test.dart
test('v17 → v18 migration', () async {
  final file = File('test/fixtures/v17.db');
  file.parent.createSync(recursive: true);
  // 复制 v17 数据库到测试目录
  // ...
  final db = AppDatabase.file(file);
  expect(db.schemaVersion, 18);
  // 验证迁移后的数据
  await db.close();
});
```

---

## 常用开发命令

```bash
# 代码分析
flutter analyze

# 代码格式化
dart format lib/ test/

# 运行测试
flutter test

# 清理构建缓存
flutter clean && flutter pub get

# Drift 代码生成
dart run build_runner build --delete-conflicting-outputs

# 查看依赖树
flutter pub deps

# 查看设备列表
flutter devices
```
