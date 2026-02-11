@echo off
title HomeCloud Server
echo ================================================
echo             HomeCloud Backend Server
echo ================================================
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Check if .env file exists
if not exist ".env" (
    echo [INFO] Creating default .env file...
    (
        echo PORT=8080
        echo AUTH_TOKEN=change_this_password
        echo WATCH_DIR=./uploads
        echo STORAGE_QUOTA_GB=100
    ) > .env
    echo [OK] .env file created! Please edit it to set your password.
    echo.
)

REM Check if uploads folder exists
if not exist "uploads" (
    mkdir uploads
)

REM Check if executable exists
if exist "HomeCloudServer.exe" (
    echo [INFO] Starting HomeCloud Server...
    echo [INFO] Press Ctrl+C to stop the server
    echo.
    HomeCloudServer.exe
) else (
    echo [ERROR] HomeCloudServer.exe not found!
    echo Please run build.bat first to compile the server.
)
echo.
pause
