@echo off
setlocal

echo [INFO] Building backend for Windows...
cd ..
set CGO_ENABLED=0
set GOOS=windows
set GOARCH=amd64
go build -o windows/server.exe -ldflags "-s -w"
if %errorlevel% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo [SUCCESS] Backend built successfully! The executable is located at 'windows/server.exe'.
pause
