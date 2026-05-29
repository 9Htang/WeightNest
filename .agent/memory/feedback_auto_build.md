---
name: auto-build-after-changes
description: After code changes, first flutter run both platforms for immediate debugging, then release build APK+Desktop
metadata:
  type: feedback
---

After every code change, the workflow order is:

1. **First — `flutter run -d <device>` for both platforms** (debug mode, compiles + launches immediately)
   - Desktop: `flutter run -d windows`
   - Android: `flutter run -d PKG110` (wireless debugging at 192.168.10.168:5555)
2. **Then — release build**: `build.ps1 -Mobile` + `build.ps1 -Desktop`

**Why:** `flutter run` already compiles, so the user can debug immediately. Release APK/exe builds take longer and are done after confirming the debug session works.

**Version bump rule:** Before building, bump the build number (+1) and patch version. Current format: `X.Y.Z+BB`. Example: 1.7.10+27 → 1.7.11+28.

**How to apply:** After each Edit/Write to Dart files, bump version → kill stale processes → `flutter run` both devices in background → then `build.ps1 -Mobile -Desktop` in background. If changes are trivial (comments only, formatting), skip. If the user is making rapid successive edits, wait until they confirm they're done.
