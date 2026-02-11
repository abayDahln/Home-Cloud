@echo off
setlocal

echo [INFO] Checking for Go installation...
go version >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Go is not installed. Attempting to install via Winget...
    winget install -e --id GoLang.Go
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install Go. Please install it manually from https://go.dev/dl/
        pause
        exit /b 1
    )
    echo [INFO] Go installed successfully. You may need to restart your terminal.
) else (
    echo [INFO] Go is already installed.
)

echo [INFO] Setting up Cloudflared...
if not exist "cloudflared.exe" (
    echo [INFO] Downloading Cloudflared...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile 'cloudflared.exe'"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to download Cloudflared.
        pause
        exit /b 1
    )
    echo [INFO] Cloudflared downloaded successfully.
) else (
    echo [INFO] Cloudflared already exists.
)

echo [SUCCESS] Tools setup complete!
pause
