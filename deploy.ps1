# WeightNest 一键部署脚本
# 用法: .\deploy.ps1

$ErrorActionPreference = "Stop"
$adb = "C:\Users\Cwb\AppData\Local\Android\Sdk\platform-tools\adb.exe"

Write-Host "🔍 检测设备..." -ForegroundColor Cyan

# 1. 检查 USB 设备
$usb = & $adb devices | Select-String "device$" | Select-String -NotMatch "5555" | ForEach-Object { ($_ -split "\s+")[0] }
if ($usb) {
    Write-Host "  USB: $usb" -ForegroundColor Green
    $deviceId = $usb
} else {
    # 2. 检查无线设备
    $wifi = & $adb devices | Select-String ":5555.*device" | ForEach-Object { ($_ -split "\s+")[0] }
    if ($wifi) {
        Write-Host "  WiFi: $wifi" -ForegroundColor Green
        $deviceId = $wifi
    } else {
        Write-Host "❌ 没有可用设备，请 USB 连接手机后重试" -ForegroundColor Red
        pause
        exit 1
    }
}

# 3. 开启无线模式（如果是 USB）
if ($deviceId -notmatch ":5555") {
    Write-Host "📡 开启无线调试..." -ForegroundColor Yellow
    & $adb -s $deviceId tcpip 5555 | Out-Null
    Start-Sleep 2

    # 获取 WiFi IP
    $ip = & $adb -s $deviceId shell "ip addr show wlan0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1"
    if (-not $ip) { $ip = & $adb -s $deviceId shell "ip route | grep wlan0 | grep -o 'src [0-9.]*' | cut -d' ' -f2" }
    if (-not $ip) {
        Write-Host "❌ 无法获取手机 IP" -ForegroundColor Red
        pause
        exit 1
    }
    Write-Host "  WiFi IP: $ip" -ForegroundColor Green

    # 断开旧无线连接，连新的
    & $adb disconnect | Out-Null
    & $adb connect "${ip}:5555" | Out-Null
    Start-Sleep 1

    $deviceId = "${ip}:5555"
    Write-Host "✅ 无线已连接: $deviceId" -ForegroundColor Green
}

# 4. 设置端口转发
Write-Host "🔀 设置端口转发 8081→8080..." -ForegroundColor Yellow
& $adb -s $deviceId reverse tcp:8081 tcp:8080 | Out-Null
Write-Host "✅ 转发已就绪" -ForegroundColor Green

# 5. 卸载旧版
Write-Host "🗑 卸载旧版..." -ForegroundColor Yellow
& $adb -s $deviceId uninstall com.weightnest.weight_nest 2>&1 | Out-Null

# 6. 部署
Write-Host "🚀 编译部署..." -ForegroundColor Yellow
flutter run -d $deviceId
