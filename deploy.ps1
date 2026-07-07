# ==============================
# WeightNest 一键部署
# 独立模式（默认）：server.exe + 桌面端，零依赖
# Docker 模式：docker compose up
# ==============================
param(
    [switch]$Docker,
    [switch]$SkipFirewall,
    [switch]$ServerOnly
)

$ErrorActionPreference = "Continue"
$projectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

Write-Host "==== WeightNest 部署 ====" -ForegroundColor Cyan

# 1. 放行防火墙
if (-not $SkipFirewall) {
    Write-Host "[防火墙] 放行 8080 端口..." -ForegroundColor Yellow
    $existing = netsh advfirewall firewall show rule name="WeightNest" 2>$null
    if ($LASTEXITCODE -ne 0 -or $existing -notmatch "WeightNest") {
        netsh advfirewall firewall add rule name="WeightNest" dir=in action=allow protocol=TCP localport=8080
        Write-Host "[防火墙] 已添加规则" -ForegroundColor Green
    } else {
        Write-Host "[防火墙] 规则已存在" -ForegroundColor Green
    }
}

# 2. 显示本机 IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -match "^192\.168\." -and $_.InterfaceAlias -notmatch "VMware|vEthernet|VirtualBox|Hyper-V"
} | Select-Object -First 1).IPAddress
if (-not $ip) {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.IPAddress -match "^192\.168\.|^10\." -and $_.InterfaceAlias -notmatch "VMware|vEthernet"
    } | Select-Object -First 1).IPAddress
}

if ($Docker) {
    # ─── Docker 模式 ───
    Write-Host "[Docker] 启动服务..." -ForegroundColor Yellow
    Push-Location $projectRoot
    try {
        docker compose up -d --build 2>&1 | Select-String "Started|Running|Healthy"
        Write-Host "[Docker] 服务已启动" -ForegroundColor Green
    } catch {
        Write-Host "[Docker] 启动失败: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    # ─── 独立模式：直接启动 server.exe ───
    $serverExe = Join-Path $projectRoot "server\server.exe"
    if (Test-Path $serverExe) {
        Write-Host "[Server] 启动独立服务器..." -ForegroundColor Yellow
        Start-Process $serverExe -WindowStyle Hidden
        Write-Host "[Server] server.exe 已启动（后台）" -ForegroundColor Green
    } else {
        Write-Host "[Server] server.exe 未找到，请先编译: dart compile exe server/lib/server.dart -o server/server.exe" -ForegroundColor Red
        Write-Host "[Server] 或使用 -Docker 参数以 Docker 模式启动" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "本机 IP: $ip" -ForegroundColor Cyan
Write-Host "手机扫码地址: $ip`:8080" -ForegroundColor Cyan

# 3. 启动桌面端
if (-not $ServerOnly) {
    Write-Host ""
    Write-Host "[桌面] 启动..." -ForegroundColor Yellow
    Push-Location $projectRoot
    flutter run -d windows
    Pop-Location
}

Write-Host "==== 完成 ====" -ForegroundColor Green
