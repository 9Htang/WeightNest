---
name: release
description: This skill should be used when the user asks to "release", "push release", "create a release", "bump version and release", "publish to GitHub", or "ship it". Automates version bump, commit, push, and GitHub release creation for the WeightNest Flutter project.
---

# WeightNest Release Workflow

Automated release pipeline: bump version → commit → push → GitHub release.

## Version Bump Convention

WeightNest uses `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`:

```yaml
version: 1.7.25+42
```

Increment rules:
- **PATCH** (1.7.25 → 1.7.26): bug fixes, small tweaks
- **MINOR** (1.7 → 1.8): features, non-trivial changes
- **MAJOR** (1 → 2): breaking changes (rare)
- **BUILD** (+42 → +43): always increment alongside version bump

Ask the user which level to bump when ambiguous. For a single commit with multiple changes, default to PATCH.

## Fixed Branch

**This MVP always releases to `feature/offline-mvp`.** Never push to `main` or `master`.

Target: https://github.com/9Htang/WeightNest/tree/feature/offline-mvp

## Release Steps

### Step 1: Ensure on Correct Branch

```powershell
git checkout feature/offline-mvp
```

### Step 2: Verify Changes

```powershell
git status --short
```

If nothing to commit, inform the user and stop.

### Step 3: Bump Version

Read the current version line from `pubspec.yaml`, compute the new version, and apply:

```powershell
Select-String -Path pubspec.yaml -Pattern '^version:'
```

Edit `pubspec.yaml` with the new version.

### Step 4: Build Release APK

Always build the APK **before** committing:

```powershell
flutter build apk --release
```

The `assembleRelease` task copies the APK to:

```
C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_vX.Y.Z.apk
```

Verify:

```powershell
Get-ChildItem "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_v*.apk" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

### Step 5: Stage All Changes

```powershell
git add -A
```

### Step 6: Commit

```
<type>: <English summary>

<Chinese or English bullet points>

chore: bump version to X.Y.Z+N
```

Types: `feat:` / `fix:` / `chore:` / `perf:`

### Step 7: Push to feature/offline-mvp

```powershell
git push origin feature/offline-mvp
```

### Step 8: Create GitHub Release

Create tag and release on `feature/offline-mvp`:

```powershell
git tag -a "v$VERSION" -m "v$VERSION: <summary>"
git push origin "v$VERSION"
gh release create "v$VERSION" `
  --title "v$VERSION 鹦鹉体重记录" `
  --notes "<release notes>" `
  "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_v$VERSION.apk"
```

## APK Output

```
C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_vX.Y.Z.apk
```

## Example

User says `/release`:

1. `git checkout feature/offline-mvp`
2. Version `1.7.25+42` → bump to `1.7.26+43`
3. `flutter build apk --release` → `鹦鹉体重记录_v1.7.26.apk`
4. `git add -A`
5. `git commit -m "feat: add contact line to settings"`
6. `git push origin feature/offline-mvp`
7. `git tag -a "v1.7.26"` + push tag
8. `gh release create "v1.7.26"` + attach APK
