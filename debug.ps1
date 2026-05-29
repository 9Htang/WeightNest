# ==============================
# WeightNest Dual Debug Launcher
# Simultaneous desktop + mobile (wireless) debugging
# ==============================
param(
    [switch]$Build,         # Also do release builds after debug session
    [switch]$BuildOnly,     # Only release builds, no debug launch
    [string]$DeviceIP,      # Wireless ADB IP[:port] (default port 5555)
    [switch]$TcpIp          # Enable TCP/IP on USB-connected device, then connect
)

$ErrorActionPreference = "Continue"
$PSNativeCommandUseErrorActionPreference = $false

$projectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$releaseDir  = "C:\Users\Cwb\.openclaw\workspace\releases"
$adb         = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# ---- banner ----
$pubspec = Get-Content "$projectRoot\pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*([^\s]+)') { $version = $matches[1].Split("+")[0] } else { $version = "?.?.?" }

Write-Host "==== WeightNest Dual Debug v$version ====" -ForegroundColor Cyan
Write-Host ""

# ---- ensure release dir ----
if (-not (Test-Path $releaseDir)) { New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null }

# ======================
# 1. ADB / Wireless Setup
# ======================
if (-not $BuildOnly) {
    if (-not (Test-Path $adb)) {
        Write-Host "[ERROR] adb not found: $adb" -ForegroundColor Red
        exit 1
    }

    # Check currently connected devices
    $adbDevices = & $adb devices 2>$null | Out-String
    Write-Host "[ADB] Connected devices:" -ForegroundColor Yellow
    ($adbDevices -split "`n" | Where-Object { $_ -match '\S' }) | ForEach-Object { Write-Host "  $_" }

    $androidSerial = $null

    # Case 1: User provided an IP to connect
    if ($DeviceIP) {
        if ($DeviceIP -notmatch ":") { $DeviceIP = "${DeviceIP}:5555" }
        Write-Host "[ADB] Connecting to $DeviceIP ..." -ForegroundColor Yellow
        & $adb connect $DeviceIP 2>&1 | ForEach-Object { Write-Host "  $_" }
        $androidSerial = $DeviceIP
    }
    # Case 2: TCPIP mode — enable on USB device then connect
    elseif ($TcpIp) {
        $usbSerial = ($adbDevices -split "`n" | Where-Object { $_ -match '^(\S+)\s+device' } | ForEach-Object { $matches[1] } | Where-Object { $_ -notmatch ":5555" -and $_ -ne "emulator-*" } | Select-Object -First 1)
        if (-not $usbSerial) {
            Write-Host "[ERROR] No USB device found for TCP/IP setup" -ForegroundColor Red
            exit 1
        }
        Write-Host "[ADB] Enabling TCP/IP on $usbSerial ..." -ForegroundColor Yellow
        & $adb -s $usbSerial tcpip 5555 2>&1 | ForEach-Object { Write-Host "  $_" }
        Start-Sleep -Seconds 3

        # Get device Wi-Fi IP — prefer wlan0, fall back to ip route
        $wifiIp = $null
        $ipRaw = & $adb -s $usbSerial shell ip addr show wlan0 2>$null | Out-String
        if ($ipRaw -match 'inet\s+(\d+\.\d+\.\d+\.\d+)') { $wifiIp = $matches[1] }
        if (-not $wifiIp) {
            # wlan0 may not exist on all devices; try ip route, excluding VPN/tunnel
            $ipRaw = & $adb -s $usbSerial shell ip route 2>$null | Out-String
            $lines = $ipRaw -split "`n" | Where-Object { $_ -match 'src\s+(\d+\.\d+\.\d+\.\d+)' -and $_ -notmatch 'tun\d+' }
            if ($lines) { $lines[0] -match 'src\s+(\d+\.\d+\.\d+\.\d+)' | Out-Null; $wifiIp = $matches[1] }
        }
        if (-not $wifiIp) {
            Write-Host "[ADB] Cannot detect device IP. Unplug USB and run: .\debug.ps1 -DeviceIP <phone-ip>" -ForegroundColor Red
            exit 1
        }
        Write-Host "[ADB] Device Wi-Fi IP: $wifiIp" -ForegroundColor Green
        & $adb connect "${wifiIp}:5555" 2>&1 | ForEach-Object { Write-Host "  $_" }
        $androidSerial = "${wifiIp}:5555"
        Write-Host "[ADB] You may now unplug the USB cable." -ForegroundColor Cyan
    }
    # Case 3: Already wirelessly connected
    else {
        $wirelessDevice = ($adbDevices -split "`n" | Where-Object { $_ -match '^(\S+):\d+\s+device' } | ForEach-Object { $matches[1] } | Select-Object -First 1)
        if ($wirelessDevice) {
            $androidSerial = $wirelessDevice
            Write-Host "[ADB] Using existing wireless connection: $androidSerial" -ForegroundColor Green
        } else {
            $usbSerial = ($adbDevices -split "`n" | Where-Object { $_ -match '^(\S+)\s+device' -and $_ -notmatch 'emulator' } | ForEach-Object { $matches[1] } | Select-Object -First 1)
            if ($usbSerial) {
                Write-Host "[ADB] USB device found ($usbSerial), but no wireless connection." -ForegroundColor Yellow
                Write-Host "[ADB] To switch to wireless: unplug USB, then run:" -ForegroundColor Yellow
                Write-Host "       .\debug.ps1 -DeviceIP <phone-ip>" -ForegroundColor White
                Write-Host "[ADB] Or with USB still connected, run:" -ForegroundColor Yellow
                Write-Host "       .\debug.ps1 -TcpIp" -ForegroundColor White
                Write-Host "[ADB] Falling back to USB mode for now." -ForegroundColor Yellow
                $androidSerial = $usbSerial
            } else {
                Write-Host "[WARN] No Android device found. Desktop-only debug." -ForegroundColor Yellow
            }
        }
    }
} else {
    $androidSerial = $null
}

# ======================
# 2. Release Builds
# ======================
function Do-Builds {
    Write-Host ""
    Write-Host "==== Release Builds ====" -ForegroundColor Cyan

    Push-Location $projectRoot
    try {
        # APK
        Write-Host "[APK] Building..." -ForegroundColor Magenta
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cmd /c "flutter build apk --release --target-platform android-arm64 2>&1" | Select-String -Pattern "Built|error|FAILURE" | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) { throw "APK build failed" }
        $apkPath = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $apkPath) {
            Copy-Item $apkPath "$releaseDir\WeightNest_v${version}.apk" -Force
            $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
            Write-Host "[APK] OK ${size}MB ($([math]::Round($sw.Elapsed.TotalSeconds,0))s)" -ForegroundColor Green
        }

        # Windows
        Write-Host "[WIN] Building..." -ForegroundColor Magenta
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & cmd /c "flutter build windows --release 2>&1" | Select-String -Pattern "Built|error|FAILURE" | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) { throw "Windows build failed" }
        $outDir = "$projectRoot\build\windows\x64\runner\Release"
        $zipPath = "$releaseDir\WeightNest_Desktop_v${version}.zip"
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        Compress-Archive -Path "$outDir\*" -DestinationPath $zipPath -Force
        Write-Host "[WIN] OK ($([math]::Round($sw.Elapsed.TotalSeconds,0))s)" -ForegroundColor Green

        Write-Host ""
        Write-Host "Artifacts:" -ForegroundColor Cyan
        Get-ChildItem $releaseDir | Where-Object { $_.Name -match $version } | ForEach-Object {
            $sz = if ($_.Length -gt 1MB) { "$([math]::Round($_.Length/1MB,1))MB" } else { "$([math]::Round($_.Length/1KB,1))KB" }
            Write-Host "  $($_.FullName) ($sz)"
        }
    } finally {
        Pop-Location
    }
}

if ($Build -or $BuildOnly) {
    Do-Builds
}

if ($BuildOnly) {
    Write-Host "==== BUILD DONE ====" -ForegroundColor Green
    exit 0
}

# ======================
# 3. Launch Dual Debug
# ======================
Write-Host ""
Write-Host "==== Launching Debug Sessions ====" -ForegroundColor Cyan

# Determine Android target ID for flutter run
$androidFlutterId = $null
if ($androidSerial) {
    $flutterDevicesRaw = & flutter devices 2>$null | Out-String
    if ($androidSerial -match "^(\d+\.\d+\.\d+\.\d+):\d+") {
        $ipMatch = $matches[1]
        $matchLine = ($flutterDevicesRaw -split "`n" | Where-Object { $_ -match [regex]::Escape($ipMatch) } | Select-Object -First 1)
    } else {
        $matchLine = ($flutterDevicesRaw -split "`n" | Where-Object { $_ -match [regex]::Escape($androidSerial) } | Select-Object -First 1)
    }
    if ($matchLine -match '^\s*(\S+)\s+\(') {
        $androidFlutterId = $matches[1]
    }
    if (-not $androidFlutterId) {
        Write-Host "[WARN] Cannot determine Flutter device ID for Android. Using ADB serial: $androidSerial" -ForegroundColor Yellow
        $androidFlutterId = $androidSerial
    }
    Write-Host "[MOBILE] Target: $androidFlutterId" -ForegroundColor Green
}
Write-Host "[DESKTOP] Target: windows" -ForegroundColor Green

Write-Host ""
Write-Host "Starting in separate windows. Close each window to stop." -ForegroundColor Cyan
Write-Host "Hot reload: press 'r' in the window. Hot restart: press 'R'." -ForegroundColor Cyan
Write-Host ""

# Launch desktop in new window
Write-Host "[DESKTOP] Launching..." -ForegroundColor Blue
Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-Command",
    "Write-Host '==== WeightNest Desktop Debug ====' -ForegroundColor Cyan; Write-Host ''; cd '$projectRoot'; flutter run -d windows --debug"
) -WindowStyle Normal

Start-Sleep -Seconds 2

# Launch mobile in new window (if available)
if ($androidFlutterId) {
    Write-Host "[MOBILE] Launching..." -ForegroundColor Magenta
    Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoExit",
        "-Command",
        "Write-Host '==== WeightNest Mobile Debug ====' -ForegroundColor Magenta; Write-Host ''; cd '$projectRoot'; flutter run -d '$androidFlutterId' --debug"
    ) -WindowStyle Normal
}

Write-Host ""
Write-Host "==== DUAL DEBUG ACTIVE ====" -ForegroundColor Green
Write-Host "Desktop + Mobile debug sessions running in separate windows." -ForegroundColor Green
