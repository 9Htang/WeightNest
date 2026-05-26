# WeightNest 版本管理规则

## 版本号规范

格式：`MAJOR.MINOR.PATCH+BUILD`（语义化版本）

| 变更类型 | 递增位 | 示例 |
|----------|--------|------|
| 新功能模块 | MINOR | 1.0.0 → 1.1.0 |
| Bug 修复 / UI 微调 | PATCH | 1.0.0 → 1.0.1 |
| 破坏性变更 / 大版本 | MAJOR | 1.x.x → 2.0.0 |
| 仅重新打包 | BUILD | 1.0.0+1 → 1.0.0+2 |

## 发版 Checklist

每次修改代码后，如果**改变了安装包内容**：

1. **更新 `pubspec.yaml` 版本号**
   ```yaml
   version: 1.0.1+2  # version+code
   ```

2. **提交并打 tag**
   ```bash
   git add -A
   git commit -m "version bump to 1.0.1"
   git tag v1.0.1
   git push --tags
   ```

3. **重新构建 APK**
   ```bash
   flutter clean && flutter pub get && flutter build apk --release
   ```

4. **输出包位置**：`build/app/outputs/flutter-apk/app-release.apk`

## 当前版本

- **v1.0.0+1** — 初始版本（全部 8 阶段完成）
- **v1.0.1+2** — 新增鸟类 FAB + 服务器状态栏（2026-05-26）

## Codemagic

- Android 构建：推送到 main 分支 → Codemagic 自动触发 `android-build`
- iOS 构建：手动触发 `ios-build` 或 `ios-signed` workflow
