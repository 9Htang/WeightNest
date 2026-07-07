---
name: release-workflow
description: 每次版本号更新后自动构建全部产物并推送
metadata:
  type: feedback
---

版本号更新（bump version）后必须执行以下完整流程，不能仅改版本号：

1. `.\build.ps1 -All` — 构建 Desktop zip + APK + 中文APK
2. 更新 `build/standalone/` 下的 exe + data 文件夹（从 Release 目录复制最新构建）
3. 创建 `WeightNest_Standalone_v{version}.zip`（包含 server.exe + weight_nest.exe + start.bat + 所有 dll）
4. `git add pubspec.yaml` + `git commit -m "chore: bump version to X.Y.Z"` + `git push`

**Why:** 用户每次更新版本号时期望得到包含新版本的 zip/apk 产物。之前只改了版本号没构建，产物还是旧版本号，需要补做。
**How to apply:** 当修改 pubspec.yaml 的 version 字段后，自动执行上述流程。

---

Release 构建只需生成 APK 文件（`flutter build apk --release`），不需要 AAB、iOS IPA、macOS、Windows 等其他平台产物。

**Why:** 用户明确指示 release 只需要 apk 文件 (2025-06-14)。
**How to apply:** Release 构建时使用 `flutter build apk --release`，忽略其他平台。
