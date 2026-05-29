# ==============================
# WeightNest Build Tool (Final Stable CI Version)
# No NativeCommandError Version
# ==============================

param(
    [switch]$Mobile,
    [switch]$Desktop,
    [switch]$Server,
    [switch]$All,
    [switch]$Clean
)

# ---- Critical: prevent PowerShell false errors ----
$ErrorActionPreference = "Continue"
$PSNativeCommandUseErrorActionPreference = $false

# ---- Paths ----
$projectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$releaseDir = "C:\Users\Cwb\.openclaw\workspace\releases"
$logFile = "$projectRoot\build.log"

# ---- Gradle safe memory ----
$env:GRADLE_OPTS = "-Xmx3g"
$env:JAVA_OPTS = "-Xmx3g"

# ---- Version ----
$pubspec = Get-Content "$projectRoot\pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*([^\s]+)') {
    $version = $matches[1].Split("+")[0]
} else {
    throw "Cannot parse version"
}

Write-Host "==== WeightNest Build Tool v$version ====" -ForegroundColor Cyan

if ($All) { $Mobile = $true; $Desktop = $true }

# ================= CLEAN =================
if ($Clean) {
    Write-Host "[CLEAN]" -ForegroundColor Yellow
    & cmd /c "flutter clean" | Out-Null
}

# ================= ANALYZE =================
if ($Mobile -or $Desktop -or $Server) {
    Write-Host "[CHECK] flutter analyze..." -ForegroundColor Yellow

    $analyze = & cmd /c "flutter analyze lib/" 2>&1 | Out-String

    if ($analyze -match "error - ") {
        Write-Host $analyze
        throw "Analyze failed"
    }

    Write-Host "[CHECK] passed" -ForegroundColor Green
}

# ================= APK =================
if ($Mobile) {
    Write-Host "[APK] Building Android..." -ForegroundColor Magenta

    Push-Location $projectRoot
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        & cmd /c "flutter build apk --release --target-platform android-arm64 > build.log 2>&1"

        if ($LASTEXITCODE -ne 0) {
            throw "APK build failed (see build.log)"
        }

        $apkPath = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"

        if (-not (Test-Path $apkPath)) {
            throw "APK not found"
        }

        $sw.Stop()

        $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)

        Write-Host "[APK] OK (${size}MB, $([math]::Round($sw.Elapsed.TotalSeconds,0))s)" -ForegroundColor Green

        Copy-Item $apkPath "$releaseDir\WeightNest_v${version}.apk" -Force
    }
    finally {
        Pop-Location
    }
}

# ================= WINDOWS =================
if ($Desktop) {
    Write-Host "[WIN] Building Windows..." -ForegroundColor Magenta

    Push-Location $projectRoot
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        & cmd /c "flutter build windows --release > build.log 2>&1"

        if ($LASTEXITCODE -ne 0) {
            throw "Windows build failed"
        }

        $sw.Stop()

        $out = "$projectRoot\build\windows\x64\runner\Release"
        $zip = "$releaseDir\WeightNest_Desktop_v${version}.zip"

        if (Test-Path $zip) { Remove-Item $zip -Force }

        Compress-Archive -Path "$out\*" -DestinationPath $zip

        Write-Host "[WIN] OK ($([math]::Round($sw.Elapsed.TotalSeconds,0))s)" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# ================= SERVER =================
if ($Server) {
    Write-Host "[DOCKER] Building server..." -ForegroundColor Magenta

    Push-Location "$projectRoot\server"
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        & cmd /c "docker stop weightnest" | Out-Null

        & cmd /c "docker build -t weightnest-server ." 2>&1 | Tee-Object $logFile

        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed"
        }

        & cmd /c "docker run -d --name weightnest -p 8080:8080 weightnest-server"

        $sw.Stop()

        Write-Host "[DOCKER] OK ($([math]::Round($sw.Elapsed.TotalSeconds,0))s)" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# ================= DONE =================
Write-Host "==== BUILD COMPLETE ====" -ForegroundColor Green

Get-ChildItem $releaseDir | Where-Object { $_.Name -match $version } | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 1)
    Write-Host "  $($_.Name) (${size}MB)"
}