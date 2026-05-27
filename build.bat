@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo ========================================
echo   WeightNest Build Tool
echo ========================================
echo.
echo   1. Build Android APK only
echo   2. Build Windows Desktop only
echo   3. Build APK + Desktop
echo   4. Build All (APK + Desktop + Docker)
echo   5. Build Docker Server only
echo.
set /p choice="Select (1-5): "

if "%choice%"=="1" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Mobile
if "%choice%"=="2" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Desktop
if "%choice%"=="3" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Mobile -Desktop
if "%choice%"=="4" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -All
if "%choice%"=="5" powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Server

echo.
pause
