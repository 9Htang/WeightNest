# 变更日志

按数据库 Schema 版本和功能里程碑记录项目演进历史。

---

## 数据库 Schema 版本演进

### v17 — 药品剂量库系统（Breaking Change）

**引入版本**：1.9.x

**重大变更**：
- 删除旧的 `medications` 表（数据丢失）
- 新增 8 张药品系统表：DrugLibrary、DrugFormulations、DiseaseCatalog、DoseRules、Medications、FeedingRecords、SideEffectRecords、StopConditions
- Species 表新增 `minWeightG`、`maxWeightG`（剂量安全校验用）
- 新增性能索引：dose_rules、drug_formulations、feeding_records、medications、side_effect_records

### v16 — 动态缩略图

**引入版本**：1.8.x

- BirdPhotos 新增 `thumbnailPath`（animated WebP 缩略图，从实况照片视频生成）
- 带有 v14 防重复迁移守卫（从 v13 以下升级时跳过 addColumn）

### v15 — 实况照片支持

**引入版本**：1.7.x

- BirdPhotos 新增 `mediaType`（photo / motion_photo）
- BirdPhotos 新增 `videoFilePath`（提取的 MP4 路径）

### v14 — 相册插件

**引入版本**：1.6.x

- 新增 BirdPhotos 表（照片列表）
- 新增 BirdAvatars 表（每鸟一个头像）
- 性能索引：bird_photos(bird_id, sort_order)

### v13 — 任务截止时间

**引入版本**：1.5.x

- Tasks 新增 `deadline`（逾期截止时间，生成时算好写入）
- 存量未完成任务用 `dueDate` 回填 `deadline`

### v12 — 性能索引

**引入版本**：1.4.x

- 新增 4 个性能索引：
  - `idx_birds_room` — 按房间筛选鸟只
  - `idx_birds_enclosure` — 按容器筛选鸟只
  - `idx_alert_records_lookup` — 告警去重与查询
  - `idx_medications_bird` — 按鸟查喂药方案

### v11 — 统一操作日志

**引入版本**：1.3.x

- 新增 ActivityLogs 表（所有插件行为的统一流水账）
- 替代分散的日志机制
- 通过 OperationService 统一写入
- 性能索引：activity_logs(bird_id, operated_at DESC)

### v10 — 告警严重程度

**引入版本**：1.2.x

- AlertRecords 新增 `severity`（warning / danger）

### v9 — 任务类型扩展

**引入版本**：1.1.x

- Tasks 新增 `taskType`（weigh / medication / ...）
- Tasks 新增 `metadata`（JSON，插件私有数据）
- 删除旧 `medication_logs` 表

### v8 — 繁育插件

**引入版本**：1.0.x

- 新增 BreedingPairs、BreedingRecords、Eggs、MatingEvents 4 张表
- 跨插件 RPC 支持（WeightPlugin 查询繁育状态）

### v7 — 基准体重与断奶期

- Birds 新增 `manualBaselineG`（手动基准体重）
- Birds 新增 `weaningOverride`（断奶期覆盖开关）

### v6 — 容器系统

- 新增 Enclosures 表
- Birds 新增 `enclosureId`

### v5 — 初始药品追踪

- 新增 medications 表（后被 v17 替换）

### v4 — 性能索引

- 初始索引：weights(bird_id, recorded_at)、tasks(due_date, status)、activity_logs(bird_id, operated_at)

### v3 — 称重间隔

- Species 新增 `nestlingWeighIntervalDays`、`juvenileWeighIntervalDays`
- Birds 新增 `weighIntervalDays`

### v1–v2 — 初始 Schema

- 初始 7 张核心表：Species、Users、Rooms、Birds、Weights、Tasks、AlertRecords

---

## 功能里程碑

### Phase 1: 核心框架
- [x] 插件系统设计（FeaturePlugin + PluginRegistry）
- [x] EventBus 事件通信
- [x] OperationService 统一写入
- [x] Drift 数据库 + Repository 模式
- [x] Riverpod 状态管理
- [x] MobileShell 底部导航

### Phase 2: 体重追踪
- [x] 单只称重 / 批量称重
- [x] 体重趋势图表（fl_chart）
- [x] EWMA 基线分析
- [x] 多维度告警检测（断奶期 / 雏鸟生长 / 基线偏离 / 超期未称）
- [x] 称重任务自动生成
- [x] 本地通知推送

### Phase 3: 数据管理
- [x] 鸟只导入导出（WNBD 格式）
- [x] 完整备份恢复（WNBK 格式）
- [x] Excel 月度体重报表
- [x] 种子数据自动初始化

### Phase 4: 繁育管理
- [x] 配对管理
- [x] 繁育周期记录（配对→产蛋→孵化→育雏→完结）
- [x] 蛋记录管理
- [x] 跨插件 RPC（繁育状态查询）

### Phase 5: 照片相册
- [x] 照片存储与管理
- [x] 头像设置与裁剪
- [x] 实况照片支持（Android）
- [x] 动态缩略图

### Phase 6: 用药管理
- [x] 药品库管理
- [x] 药品规格/浓度
- [x] 疾病目录
- [x] 剂量规则（品种覆盖 + 通用规则）
- [x] 剂量计算器（mg/kg → ml）
- [x] 喂药方案管理
- [x] 喂药记录（已喂/吐出/漏喂/补喂/拒绝）
- [x] 副作用追踪
- [x] 喂药任务自动生成
- [x] 喂药日历视图

### Phase 7: 基础设施
- [x] Debug 插件（仪表盘/DB检查器/日志查看器）
- [x] AppClock 时间控制
- [x] DebugLogSink 日志拦截
- [x] CI/CD（Codemagic）
- [x] 文件分享（冷启动/热启动）
- [x] Pro 版本激活码机制
- [x] 明暗主题
