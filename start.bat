@echo off
REM 自动检测局域网 IP 并启动 WeightNest 服务端
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /c:"192.168"') do set HOST_IP=%%a
set HOST_IP=%HOST_IP: =%
echo 检测到局域网 IP: %HOST_IP%
set SERVER_HOST=%HOST_IP%
docker compose up -d --build
echo.
echo WeightNest 已启动！
echo 二维码页面: http://%HOST_IP%:8080/qr
echo.
pause
