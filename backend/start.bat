@echo off
title HomeCloud Server
echo ================================================
echo             HomeCloud Backend Server
echo ================================================
echo.

REM Check if Go is installed
where go >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Go is not installed or not in PATH!
    echo Please download and install Go from: https://go.dev/dl/
    echo.
    pause
    exit /b 1
)

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
    echo [INFO] Creating uploads folder...
    mkdir uploads
    echo [OK] uploads folder created!
    echo.
)

echo [INFO] Starting HomeCloud Server...
echo [INFO] Press Ctrl+C to stop the server
echo.
echo ------------------------------------------------
go run main.go
echo ------------------------------------------------
echo.
echo [INFO] Server has stopped.
pause
