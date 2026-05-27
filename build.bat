@echo off
:: WeightNest 构建启动器 — 双击运行，按选项构建
cd /d "%~dp0"

echo.
echo ═══════════════════════════════════════
echo   WeightNest 构建工具
echo ═══════════════════════════════════════
echo.
echo   1. 只构建手机端 (APK)
echo   2. 只构建电脑端 (Windows)
echo   3. 手机端 + 电脑端
echo   4. 全部 (手机 + 电脑 + 服务端)
echo   5. 仅重建服务端 (Docker)
echo.
set /p choice="请选择 (1-5): "

if "%choice%"=="1" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Mobile
if "%choice%"=="2" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Desktop
if "%choice%"=="3" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Mobile -Desktop
if "%choice%"=="4" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -All
if "%choice%"=="5" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Server

echo.
pause
