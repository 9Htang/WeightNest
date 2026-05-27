# WeightNest Build Script
# Usage: .\build.ps1 [-Mobile] [-Desktop] [-Server] [-All] [-Clean]

param(
    [switch]$Mobile,
    [switch]$Desktop,
    [switch]$Server,
    [switch]$All,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = "$PSScriptRoot"
$releaseDir = "C:\Users\Cwb\.openclaw\workspace\releases"

$pubspec = Get-Content "$projectRoot\pubspec.yaml" | Select-String "^version:"
$version = ($pubspec -split ":\s*")[2].Split("+")[0]

Write-Host "==== WeightNest Build Tool v$version ====" -ForegroundColor Cyan

if ($All) { $Mobile = $true; $Desktop = $true }

if (-not ($Mobile -or $Desktop -or $Server)) {
    Write-Host ""
    Write-Host "Usage: .\build.ps1 [-Mobile] [-Desktop] [-Server] [-All] [-Clean]"
    Write-Host "  -Mobile   Build Android APK"
    Write-Host "  -Desktop  Build Windows desktop"
    Write-Host "  -Server   Rebuild Docker server"
    Write-Host "  -All      Build everything"
    Write-Host "  -Clean    Clean before build"
    exit 0
}

# ---- Clean ----
if ($Clean) {
    Write-Host "[CLEAN] flutter clean..." -ForegroundColor Yellow
    Push-Location $projectRoot
    flutter clean 2>&1 | Out-Null
    Pop-Location
    Write-Host "[CLEAN] done" -ForegroundColor Green
}

# ---- Check ----
Push-Location $projectRoot
try {
    Write-Host "[CHECK] flutter analyze..." -ForegroundColor Yellow
    $analyze = flutter analyze lib/ 2>&1 | Out-String
    $errors = ($analyze | Select-String " error - " | Measure-Object).Count
    if ($errors -gt 0) {
        Write-Host "[!] $errors compile errors found, aborting" -ForegroundColor Red
        Write-Host $analyze
        exit 1
    }
    Write-Host "[CHECK] passed" -ForegroundColor Green
}
finally {
    Pop-Location
}

# ---- Android APK ----
if ($Mobile) {
    Write-Host "[APK] Building Android..." -ForegroundColor Magenta
    Push-Location $projectRoot
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        flutter build apk --release --target-platform android-arm64 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            flutter build apk --release --target-platform android-arm64 2>&1 | Select-String -Pattern "error|Error|FAIL"
            throw "APK build failed"
        }
        $sw.Stop()
        $apkSize = [math]::Round((Get-Item "$projectRoot\build\app\outputs\flutter-apk\app-release.apk").Length / 1MB, 1)
        Write-Host "[APK] OK (${apkSize}MB, $([math]::Round($sw.Elapsed.TotalSeconds, 0))s)" -ForegroundColor Green

        $dest = "$releaseDir\WeightNest_v${version}.apk"
        Copy-Item "$projectRoot\build\app\outputs\flutter-apk\app-release.apk" $dest -Force
        Write-Host "[APK] -> $dest" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] APK failed: $_" -ForegroundColor Red
        Pop-Location; exit 1
    }
    Pop-Location
}

# ---- Windows Desktop ----
if ($Desktop) {
    Write-Host "[WIN] Building Windows..." -ForegroundColor Magenta
    Push-Location $projectRoot
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        flutter build windows --release 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            flutter build windows --release 2>&1 | Select-String -Pattern "error|Error|FAIL"
            throw "Windows build failed"
        }
        $sw.Stop()
        Write-Host "[WIN] OK ($([math]::Round($sw.Elapsed.TotalSeconds, 0))s)" -ForegroundColor Green

        $buildDir = "$projectRoot\build\windows\x64\runner\Release"
        $releaseZip = "$releaseDir\WeightNest_Desktop_v${version}.zip"
        if (Test-Path $releaseZip) { Remove-Item $releaseZip -Force }
        Compress-Archive -Path "$buildDir\*" -DestinationPath $releaseZip -Force

        $zipSize = [math]::Round((Get-Item $releaseZip).Length / 1MB, 1)
        Write-Host "[WIN] -> $releaseZip (${zipSize}MB)" -ForegroundColor Green
        Write-Host "[WIN] Run weight_nest.exe after unzip" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[!] Windows failed: $_" -ForegroundColor Red
        Pop-Location; exit 1
    }
    Pop-Location
}

# ---- Docker Server ----
if ($Server) {
    Write-Host "[DOCKER] Rebuilding server..." -ForegroundColor Magenta
    Push-Location "$projectRoot\server"
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        docker stop weightnest 2>$null
        docker build -t weightnest-server . 2>&1 | Select-String -Pattern "Step|Success|error|Error"
        if ($LASTEXITCODE -ne 0) { throw "Docker build failed" }

        docker rm weightnest 2>$null
        docker run -d --name weightnest -p 8080:8080 weightnest-server 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Docker run failed" }

        $sw.Stop()
        Write-Host "[DOCKER] OK ($([math]::Round($sw.Elapsed.TotalSeconds, 0))s)" -ForegroundColor Green

        Start-Sleep 2
        try {
            $health = (Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 3).Content
            if ($health -match "ok") { Write-Host "[DOCKER] health: OK" -ForegroundColor Green }
            else { Write-Host "[!] health: $health" -ForegroundColor Red }
        }
        catch { Write-Host "[!] health check failed" -ForegroundColor Red }
    }
    catch {
        Write-Host "[!] Docker failed: $_" -ForegroundColor Red
        Pop-Location; exit 1
    }
    Pop-Location
}

# ---- Done ----
Write-Host "==== Build Complete! ====" -ForegroundColor Green
Get-ChildItem $releaseDir | Where-Object { $_.Name -match "v$version" } | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 1)
    Write-Host "  $($_.Name)  (${size}MB)"
}
