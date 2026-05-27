# WeightNest 自动构建脚本
# 用法: .\build.ps1 [-Mobile] [-Desktop] [-Server] [-All] [-Clean]
# 示例: .\build.ps1 -Mobile                    # 只打 APK
#       .\build.ps1 -Mobile -Desktop           # 手机 + 电脑
#       .\build.ps1 -All                       # 全部

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

# 读取版本号
$pubspec = Get-Content "$projectRoot\pubspec.yaml" | Select-String "^version:"
$version = ($pubspec -split ":\s*")[2].Split("+")[0]
$versionName = "鹦鹉体重记录_v$version"

Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  WeightNest 构建工具 v$version" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($All) { $Mobile = $true; $Desktop = $true }

# ─── 校验 ───
if (-not ($Mobile -or $Desktop -or $Server)) {
    Write-Host "用法: .\build.ps1 [-Mobile] [-Desktop] [-Server] [-All] [-Clean]"
    Write-Host ""
    Write-Host "  -Mobile   构建 Android APK"
    Write-Host "  -Desktop  构建 Windows 桌面端"
    Write-Host "  -Server   重建 Docker 服务端"
    Write-Host "  -All      全部构建"
    Write-Host "  -Clean    构建前清理"
    exit 0
}

# ─── 清理 ───
if ($Clean) {
    Write-Host "[清理] flutter clean..." -ForegroundColor Yellow
    Push-Location $projectRoot
    flutter clean 2>&1 | Out-Null
    Pop-Location
    Write-Host "[清理] 完成" -ForegroundColor Green
}

# ─── 前置检查 ───
Push-Location $projectRoot
try {
    Write-Host "[检查] flutter analyze..." -ForegroundColor Yellow
    $analyze = flutter analyze lib/ 2>&1 | Out-String
    $errors = ($analyze | Select-String " error - " | Measure-Object).Count
    if ($errors -gt 0) {
        Write-Host "[!] 发现 $errors 个编译错误，中断构建" -ForegroundColor Red
        Write-Host $analyze
        exit 1
    }
    Write-Host "[检查] 通过" -ForegroundColor Green
} finally {
    Pop-Location
}

# ═══════════════════════════════════════
#  构建 Android APK
# ═══════════════════════════════════════
if ($Mobile) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  📱 构建 Android APK" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta

    Push-Location $projectRoot
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        Write-Host "[APK] flutter build..." -ForegroundColor Yellow
        flutter build apk --release --target-platform android-arm64 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            # 单独再试一次看看错误
            Write-Host "[!] 构建失败，查看错误..." -ForegroundColor Red
            flutter build apk --release --target-platform android-arm64 2>&1 | Select-String -Pattern "error|Error|FAIL"
            throw "APK 构建失败"
        }

        $sw.Stop()
        $apkSize = [math]::Round((Get-Item "$projectRoot\build\app\outputs\flutter-apk\app-release.apk").Length / 1MB, 1)
        Write-Host "[APK] 构建成功 (${apkSize}MB, $([math]::Round($sw.Elapsed.TotalSeconds, 0))s)" -ForegroundColor Green

        # 复制到 releases
        $dest = "$releaseDir\${versionName}.apk"
        Copy-Item "$projectRoot\build\app\outputs\flutter-apk\app-release.apk" $dest -Force
        Write-Host "[APK] → $dest" -ForegroundColor Green

    } catch {
        Write-Host "[!] APK 构建失败: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# ═══════════════════════════════════════
#  构建 Windows 桌面端
# ═══════════════════════════════════════
if ($Desktop) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  🖥 构建 Windows 桌面端" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta

    Push-Location $projectRoot
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        Write-Host "[Win] flutter build windows..." -ForegroundColor Yellow
        flutter build windows --release 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[!] 构建失败，查看错误..." -ForegroundColor Red
            flutter build windows --release 2>&1 | Select-String -Pattern "error|Error|FAIL"
            throw "Windows 构建失败"
        }

        $sw.Stop()
        Write-Host "[Win] 构建成功 ($([math]::Round($sw.Elapsed.TotalSeconds, 0))s)" -ForegroundColor Green

        # 打包发布文件夹
        $buildDir = "$projectRoot\build\windows\x64\runner\Release"
        $releaseZip = "$releaseDir\WeightNest-桌面端_v$version.zip"

        if (Test-Path $releaseZip) { Remove-Item $releaseZip -Force }
        Compress-Archive -Path "$buildDir\*" -DestinationPath $releaseZip -Force

        $zipSize = [math]::Round((Get-Item $releaseZip).Length / 1MB, 1)
        Write-Host "[Win] → $releaseZip (${zipSize}MB)" -ForegroundColor Green
        Write-Host "[Win] 注意: 解压后运行 weight_nest.exe" -ForegroundColor Yellow

    } catch {
        Write-Host "[!] Windows 构建失败: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# ═══════════════════════════════════════
#  重建 Docker 服务端
# ═══════════════════════════════════════
if ($Server) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  🐳 重建 Docker 服务端" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta

    Push-Location "$projectRoot\server"
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        Write-Host "[Docker] 停止旧容器..." -ForegroundColor Yellow
        docker stop weightnest 2>$null

        Write-Host "[Docker] 构建镜像..." -ForegroundColor Yellow
        docker build -t weightnest-server . 2>&1 | Select-String -Pattern "Step|Success|error|Error"

        if ($LASTEXITCODE -ne 0) { throw "Docker build 失败" }

        Write-Host "[Docker] 移除旧容器..." -ForegroundColor Yellow
        docker rm weightnest 2>$null

        Write-Host "[Docker] 启动新容器..." -ForegroundColor Yellow
        docker run -d --name weightnest -p 8080:8080 weightnest-server 2>&1

        if ($LASTEXITCODE -ne 0) { throw "Docker run 失败" }

        $sw.Stop()
        Write-Host "[Docker] 服务端已启动 ($([math]::Round($sw.Elapsed.TotalSeconds, 0))s)" -ForegroundColor Green

        # 等2秒验证
        Start-Sleep -Seconds 2
        $health = try { (Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 3).Content } catch { "offline" }
        if ($health -match "ok") {
            Write-Host "[Docker] 健康检查: OK" -ForegroundColor Green
        } else {
            Write-Host "[!] 健康检查失败: $health" -ForegroundColor Red
        }

    } catch {
        Write-Host "[!] Docker 构建失败: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

# ─── 完成 ───
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ 构建完成!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host ""

Get-ChildItem $releaseDir | Where-Object {
    $_.Name -match "v$version"
} | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 1)
    $time = $_.LastWriteTime.ToString("HH:mm")
    Write-Host "  $($_.Name)  (${size}MB, $time)" -ForegroundColor White
}

Write-Host ""

# 提交版本号变动
Push-Location $projectRoot
$changed = git status --porcelain 2>$null
if ($changed) {
    Write-Host "[Git] 有未提交变更，是否需要提交并推送? (y/n)" -ForegroundColor Yellow
    # 非交互模式下跳过
}
Pop-Location
