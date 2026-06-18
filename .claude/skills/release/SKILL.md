---
name: release
description: This skill should be used when the user asks to "release", "push release", "create a release", "bump version and release", "publish to GitHub", or "ship it". Automates version bump, commit, push, and GitHub release creation for the WeightNest Flutter project.
---

# WeightNest Release Workflow

Automated release pipeline: bump version → commit → push → GitHub release.
**Important:** Keep all commands simple and avoid complex PowerShell scripts (like .NET Zip manipulation) to ensure they pass Auto Mode security checks.

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

Read the current version line from `pubspec.yaml`:

```powershell
Select-String -Path pubspec.yaml -Pattern '^version:'
```

Edit `pubspec.yaml` with the new version (e.g., `1.9.3+51`). Verify the edit was successful by reading the line again.

### Step 4: Build Release APK

Clean first to avoid Gradle caching stale assets, then build:

```powershell
flutter clean
flutter build apk --release
```

**Copy the APK to the releases directory** (replace X.Y.Z with the new version):

```powershell
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_vX.Y.Z.apk" -Force
```

**Verify the APK exists and is reasonably sized** (do NOT attempt to unzip it, just check file info):

```powershell
Get-ChildItem "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_vX.Y.Z.apk" | Select-Object Name, Length
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

Use a temp ASCII filename for upload — Chinese characters in paths get stripped by `gh`. Run these commands step-by-step:

1. **Copy to a safe temp path:**
   ```powershell
   Copy-Item "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_vX.Y.Z.apk" "$env:TEMP\WeightNest-vX.Y.Z.apk" -Force
   ```

2. **Create and push the tag:**
   ```powershell
   git tag -a "vX.Y.Z" -m "vX.Y.Z: <summary>"
   git push origin "vX.Y.Z"
   ```

3. **Create the release with the APK attached:**
   ```powershell
   gh release create "vX.Y.Z" --title "vX.Y.Z 鹦鹉体重记录" --notes "<release notes>" "$env:TEMP\WeightNest-vX.Y.Z.apk"
   ```

4. **Clean up the temp file:**
   ```powershell
   Remove-Item "$env:TEMP\WeightNest-vX.Y.Z.apk"
   ```

## APK Output

```
C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_vX.Y.Z.apk
```

## Example

User says `/release`:

1. `git checkout feature/offline-mvp`
2. Version `1.7.25+42` → bump to `1.7.26+43`
3. `flutter build apk --release` → Copy to `鹦鹉体重记录_v1.7.26.apk`
4. `git add -A`
5. `git commit -m "feat: add contact line to settings"`
6. `git push origin feature/offline-mvp`
7. `git tag -a "v1.7.26"` + push tag
8. `gh release create "v1.7.26"` + attach APK
