@echo off
setlocal

rem Check if Go binary exists
if not exist "server.exe" (
    echo [ERROR] server.exe not found! Run build_app.bat first.
    pause
    exit /b 1
)

rem Check if cloudflared exists
if not exist "cloudflared.exe" (
    echo [ERROR] cloudflared.exe not found! Run install_tools.bat first.
    pause
    exit /b 1
)

echo [INFO] Starting HomeCloud Server...
start "HomeCloud Server" server.exe

echo [INFO] Starting Cloudflare Tunnel (Assuming you will authenticate or use a flag)...
echo       If this is your first time, run 'cloudflared.exe tunnel login' manually.
echo.
echo [INFO] Attempting to expose local port 8080...
start "Cloudflare Tunnel" cloudflared.exe tunnel --url http://localhost:8080

echo [SUCCESS] Services started!
pause
