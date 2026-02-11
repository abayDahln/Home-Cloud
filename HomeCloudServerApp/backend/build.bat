@echo off
title HomeCloud - Build Server
echo ================================================
echo         HomeCloud Backend Server Builder
echo ================================================
echo.

REM Check if Go is installed
where go >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Go is not installed or not in PATH!
    echo Please download and install Go from: https://go.dev/dl/
    pause
    exit /b 1
)

cd /d "%~dp0"

echo [INFO] Downloading dependencies...
go mod tidy
echo.

echo [INFO] Building server executable...
go build -ldflags="-s -w" -o server.exe .

if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Build completed!
    echo Executable created: HomeCloudServer.exe
    echo.
    echo You can now distribute the following files:
    echo   - HomeCloudServer.exe
    echo   - .env (example configuration)
    echo   - run.bat (to start the server)
) else (
    echo [ERROR] Build failed!
)
echo.
pause
