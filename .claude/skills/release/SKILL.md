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

Always build the APK **before** committing. Clean first to avoid Gradle caching stale assets, then manually copy to releases directory and **verify the embedded version**:

```powershell
flutter clean
flutter build apk --release
```

Copy the APK to the releases directory (Gradle no longer does this automatically):

```powershell
$ver = "X.Y.Z"  # new version
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" `
    "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_v$ver.apk" -Force
```

**Verify the embedded pubspec.yaml version matches $ver** — if not, stop and investigate:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$apk = "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_v$ver.apk"
$zip = [System.IO.Compression.ZipFile]::OpenRead($apk)
$entry = $zip.Entries | Where-Object { $_.FullName -eq 'assets/flutter_assets/pubspec.yaml' }
$stream = $entry.Open(); $reader = New-Object System.IO.StreamReader($stream)
$embedded = ($reader.ReadToEnd() | Select-String '^version:\s*(.+)$').Matches.Groups[1].Value
$reader.Close(); $stream.Close(); $zip.Dispose()
if ($embedded -ne "$ver+$build") { throw "APK version mismatch: expected $ver+$build, got $embedded" }
```

Also verify the APK exists and its size:

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

Create tag and release on `feature/offline-mvp`. **Use a temp ASCII filename** for upload — Chinese characters in paths get stripped by `gh`:

```powershell
$ver = "X.Y.Z"
$apkSrc = "C:\Users\Cwb\.openclaw\workspace\releases\鹦鹉体重记录_v$ver.apk"
$apkTmp = "$env:TEMP\WeightNest-v$ver.apk"
Copy-Item $apkSrc $apkTmp -Force
git tag -a "v$ver" -m "v$ver: <summary>"
git push origin "v$ver"
gh release create "v$ver" `
  --title "v$ver 鹦鹉体重记录" `
  --notes "<release notes>" `
  $apkTmp
Remove-Item $apkTmp
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
