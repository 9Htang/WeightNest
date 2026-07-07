# WeightNest 插件化架构可行性报告

> 2026-05-30 · v1.7.20

---

## 一、核心问题

> "之后的功能可不可以以插件的形式加入？"

**答案：可以，但要分场景。不是所有功能都适合插件化。**

---

## 二、当前架构 (Monolith)

```
weight_nest.exe ─── server.exe (IPC via HTTP)
     │
     ├── screens/        # 页面 (紧耦合)
     ├── services/       # 业务逻辑
     ├── repositories/   # 数据库访问
     └── database/       # Drift ORM
```

**优点**：编译期类型安全、单进程调试简单、无跨进程开销
**缺点**：新功能修改主干代码、编译整个 app、无法热插拔

---

## 三、五种插件方案对比

### 方案 A：Dart Package 分包 (推荐)

| 维度 | 评估 |
|------|------|
| 机制 | 将功能模块提取为独立 pub package，通过 interface 解耦 |
| 加载方式 | 编译期静态链接 |
| 适用场景 | 所有新功能 |
| 实现难度 | ⭐⭐ 低 |
| 灵活性 | ⭐⭐⭐ 中 |
| 性能 | ⭐⭐⭐⭐⭐ 无损失 |

**示例**：
```yaml
# pubspec.yaml
dependencies:
  weight_nest_core:        # 核心：database, models, interfaces
    path: packages/core
  weight_nest_birds:       # 鹦鹉管理
    path: packages/birds
  weight_nest_alerts:      # 预警引擎
    path: packages/alerts
  weight_nest_export:      # 导出 (Excel/PDF)
    path: packages/export
```

```dart
// packages/core/lib/plugin.dart
abstract class FeaturePlugin {
  String get id;
  String get displayName;
  Widget buildPage(BuildContext context);
  List<RouteBase> get routes;
  List<ServiceProvider> get services;
}

// packages/alerts/lib/alert_plugin.dart
class AlertPlugin extends FeaturePlugin {
  // 独立开发、独立测试、编译进主程序
}
```

**适合插件化的功能**：
- 新图表类型（体重趋势、健康评分…）
- 新导出格式（PDF、CSV、云同步…）
- 新预警算法（生长速率、异常检测…）
- 第三方集成（微信推送、企业微信、飞书…）

**不太适合插件化的**：
- 核心 CRUD（鹦鹉/体重/任务 — 所有模块依赖它们）
- 数据库 schema（增量 migration 够用）
- 认证体系（改一处影响全局）

---

### 方案 B：动态模块加载 (dart:ffi + dlopen)

| 维度 | 评估 |
|------|------|
| 机制 | 编译 .dart 为 .so/.dll，运行时 `dlopen` 加载 |
| 适用场景 | C/C++/Rust 扩展，高性能计算 |
| 实现难度 | ⭐⭐⭐⭐ 高 |
| 灵活性 | ⭐⭐⭐⭐⭐ 真·热插拔 |
| 性能 | ⭐⭐⭐⭐ 好（native 调用开销） |

**仅适用于**：
- 图像识别插件（鹦鹉品种 AI 识别）
- 音频分析（鹦鹉叫声情绪检测）
- 加密模块（自定义加密协议）

**不适用**：UI 功能 — Flutter 不支持动态加载 Dart 代码。

---

### 方案 C：IPC 子进程

| 维度 | 评估 |
|------|------|
| 机制 | 新功能跑在独立进程，通过 HTTP/gRPC/stdin 通信 |
| 适用场景 | 独立服务，语言无关 |
| 实现难度 | ⭐⭐⭐ 中 |
| 灵活性 | ⭐⭐⭐⭐ 语言无关 |
| 性能 | ⭐⭐ 差（序列化开销） |

**适用于**：
- Python 数据分析插件（pandas/numpy 体重趋势分析）
- Go/Rust 高性能同步引擎
- 已存在的 `server.exe` 就是这种模式

---

### 方案 D：纯配置驱动

| 维度 | 评估 |
|------|------|
| 机制 | JSON/YAML 定义字段、校验规则、展示逻辑 |
| 适用场景 | 表单类功能、CRUD 变体 |
| 实现难度 | ⭐ 很低 |
| 灵活性 | ⭐⭐ 局限于预定义模板 |

**适用于**：
- 自定义字段（鹦鹉增加"羽色"、"性格"字段）
- 自定义报表（拖拽配置报表列）
- 品种的称重间隔配置（已实现）

**本质不是插件**，只是"可配置化"。

---

### 方案 E：事件钩子 (Hook / Event Bus)

| 维度 | 评估 |
|------|------|
| 机制 | 定义事件（`BirdCreated`, `WeightRecorded`），插件订阅 |
| 适用场景 | 横切关注点、通知、审计 |
| 实现难度 | ⭐⭐ 低 |
| 灵活性 | ⭐⭐⭐ 中 |
| 性能 | ⭐⭐⭐⭐ 好 |

**适用于**：
- 体重记录后 → 通知插件（微信推送）
- 鹦鹉创建后 → 审计日志插件
- 预警触发后 → 邮件/短信插件

**当前项目已有雏形**：`SyncQueueService` 监听变更 → 推送到服务器。可以泛化为 EventBus。

---

## 四、推荐路线

```
Phase 1（现在）     Phase 2（下个大版本）   Phase 3（远期）
───────────────    ─────────────────────    ────────────
方案 D: 可配置化    方案 A: Package 分包      方案 E: 事件钩子
+ 方案 E: 事件钩子   + 抽象 FeaturePlugin    + 方案 B: FFI 扩展
                                     └── 第三方开发者可贡献插件
```

### Phase 1 — 立即可做（改动最小）

1. **EventBus**：定义 `AppEvent` 类型，`EventBus.emit()` + `EventBus.on()`
2. **可配置字段**：`Bird` 表加 `extras TEXT`（JSON 列），允许自定义扩展字段
3. **服务注册表**：`ServiceRegistry` 替代当前的硬编码 `providers.dart` 列表

```dart
// lib/core/event_bus.dart
class EventBus {
  final _handlers = <Type, List<Function>>{};
  
  void on<T>(void Function(T) handler) { ... }
  void emit<T>(T event) { ... }
}

// 使用
eventBus.on<WeightRecorded>((e) => wechatPlugin.notify(e));
eventBus.emit(WeightRecorded(birdId: 1, weightG: 45.5));
```

### Phase 2 — 架构收益最大

```yaml
# 目录结构
packages/
  core/               # 数据库 + 模型 + EventBus + 接口
  birds/              # 鹦鹉管理 (screens + services + repositories)
  weights/            # 体重记录 + 图表
  alerts/             # 预警引擎
  tasks/              # 任务管理
  sync/               # 同步引擎 + 发现服务
  server/             # 嵌入式 shelf 服务器
  export/             # Excel/PDF 导出
  plugins/            # 第三方插件目录（预留）
```

每个 package 依赖 `core`，彼此不直接依赖。主 app 只做组装。

### Phase 3 — 生态化

- 开放插件 API 文档
- 社区开发者可写 Dart package 提交到 pub.dev
- FFI 接口给 Python/Rust 开发者

---

## 五、当前代码的插件友好度评分

| 能力 | 评分 | 说明 |
|------|------|------|
| 模块边界清晰度 | ⭐⭐⭐⭐ | Repository→Service→Screen 分层好 |
| 接口抽象 | ⭐⭐ | 无 interface，全是具体类 |
| 依赖注入 | ⭐⭐⭐ | Riverpod provider 天然支持替换 |
| 事件驱动 | ⭐⭐ | SyncQueue 是隐式事件，无显式 EventBus |
| 可扩展数据模型 | ⭐⭐ | 无 JSON 扩展列，改 schema 需 migration |

---

## 六、结论

**可以做，推荐分三步走。**

| 阶段 | 投入 | 收益 | 建议启动条件 |
|------|------|------|------------|
| Phase 1: EventBus + 可配置 | 1-2 天 | 立即可接新通知渠道 | **现在就可做** |
| Phase 2: Package 分包 | 3-5 天 | 多人并行开发，编译加速 | 有 2+ 开发者时 |
| Phase 3: 动态加载 | 1-2 周 | 第三方生态 | 有外部贡献需求时 |

**不建议**为插件而插件 — 当前单体架构对一个饲养员管理系统的规模（1 万行以内）完全够用。插件化的真正收益在于：多人协作、第三方集成、按需加载。在这些需求出现之前，保持简单。

---

*报告基于 `feature/sqlite-standalone` v1.7.20 全量代码扫描*
