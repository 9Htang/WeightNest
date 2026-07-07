# Coverage Baseline（覆盖率基线）

**采集日期：** 2026-06-30
**测试总数：** 364（从 230 起步，本次新增 134）
**采集命令：** `flutter test --coverage`

## 当前状态

| 指标 | 值 | 说明 |
|---|---|---|
| 测试用例数 | 364 | 全部通过 |
| lib/ 线覆盖率 | **待修复** | lcov.info 命中数据不完整（见下） |
| 已覆盖源文件 | 33 / ~90 | lcov 仅记录了部分文件 |

## 已知问题：覆盖率追踪不完整

运行 `flutter test --coverage` 后，`coverage/lcov.info` 中绝大部分 `DA:行号,0` 命中次数为 0，
即使对应的代码已被测试明确覆盖（例如 `providers.dart` 的 `databaseProvider` 被 provider 测试 override，
但 lcov 仍记录为 0 命中）。仅末尾 2 个文件有非零命中。

**可能原因：**
- Windows + Flutter 3.27.0 (Dart 3.6.0) 的 `--coverage` 工具链在该环境下覆盖率聚合不完整
- `concurrency: 4`（dart_test.yaml）并发执行可能导致 coverage 数据竞争/丢失

**建议排查方向：**
1. 尝试 `flutter test --coverage --concurrency=1` 重新采集
2. 升级 Flutter SDK 后重新采集
3. 在 CI（Linux/macOS）环境采集对比

## 门禁策略（渐进式）

鉴于本地 lcov 数据不可靠，**当前 CI 门禁阶段设为"仅采集不阻断"**：
- `codemagic.yaml` 已配置 `flutter test --coverage` 产出 lcov.info
- 待覆盖率工具链修复、基线可靠后，再启用阈值门禁（目标 60%）

排除规则（CI 后处理时应用）：
- `*.g.dart`（drift 生成代码）
- `lib/main.dart`（入口胶水）
- `test/**`（测试本身）

## 覆盖率计算工具

`tools/compute_coverage.dart` —— 解析 lcov.info 计算 lib/ 线覆盖率（排除生成代码与入口）。
用法：`dart run tools/compute_coverage.dart coverage/lcov.info`
