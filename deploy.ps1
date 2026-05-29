# ==============================
# WeightNest 一键部署
# 放行防火墙 → 启动服务 → 启动桌面端
# ==============================
param(
    [switch]$SkipFirewall,
    [switch]$ServerOnly  # 只启动服务端，不启动桌面端
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

# 2. 启动 Docker 服务
Write-Host "[Docker] 启动服务..." -ForegroundColor Yellow
Push-Location $projectRoot
try {
    docker compose up -d --build 2>&1 | Select-String "Started|Running|Healthy|Recreated"
    Write-Host "[Docker] 服务已启动" -ForegroundColor Green
} catch {
    Write-Host "[Docker] 启动失败: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# 3. 显示本机 IP
Write-Host ""
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -match "^192\.168\." -and $_.InterfaceAlias -notmatch "VMware|vEthernet|VirtualBox|Hyper-V"
} | Select-Object -First 1).IPAddress
if (-not $ip) {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.IPAddress -match "^192\.168\.|^10\." -and $_.InterfaceAlias -notmatch "VMware|vEthernet"
    } | Select-Object -First 1).IPAddress
}
Write-Host "本机 IP: $ip" -ForegroundColor Cyan
Write-Host "手机扫码地址: $ip`:8080" -ForegroundColor Cyan

# 4. 启动桌面端
if (-not $ServerOnly) {
    Write-Host ""
    Write-Host "[桌面] 启动..." -ForegroundColor Yellow
    Push-Location $projectRoot
    flutter run -d windows
    Pop-Location
}

Write-Host "==== 完成 ====" -ForegroundColor Green
