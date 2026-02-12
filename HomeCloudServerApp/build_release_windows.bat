@echo off
setlocal enableextensions
echo ===========================================
echo Building Home Cloud Server App (Windows)
echo ===========================================

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH.
    pause
    exit /b 1
)

REM Check if Go is installed
where go >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Go is not installed or not in PATH.
    pause
    exit /b 1
)

REM 1. Build Flutter Application
echo.
echo [1/3] Building Flutter Application...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter build failed.
    pause
    exit /b %errorlevel%
)

REM 2. Build Go Backend
echo.
echo [2/3] Building Go Backend...
cd backend 
if not exist "go.mod" (
    echo [ERROR] go.mod not found in backend directory.
    cd ..
    pause
    exit /b 1
)

REM Download dependencies
echo Downloading Go dependencies...
call go mod tidy
if %errorlevel% neq 0 (
    echo [ERROR] Failed to download Go dependencies.
    cd ..
    pause
    exit /b %errorlevel%
)

REM Build server executable
echo Compiling server executable...
call go build -ldflags="-s -w" -o server.exe .
if %errorlevel% neq 0 (
    echo [ERROR] Go build failed.
    cd ..
    pause
    exit /b %errorlevel%
)

REM Return to project root
cd ..

REM 3. Organize Files for Installer
echo.
echo [3/3] Preparing files for Installer...
set "RELEASE_DIR=build\windows\x64\runner\Release"
set "SERVER_DEST=%RELEASE_DIR%\server"

if not exist "%RELEASE_DIR%" (
    echo [ERROR] Release directory not found: %RELEASE_DIR%
    pause
    exit /b 1
)

if not exist "%SERVER_DEST%" mkdir "%SERVER_DEST%"

echo Copying backend files to %SERVER_DEST%...
copy "backend\server.exe" "%SERVER_DEST%\" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy server.exe
    pause
    exit /b 1
)

if exist "backend\.env" (
    copy "backend\.env" "%SERVER_DEST%\" >nul
    echo Copied .env
) else (
    echo [WARNING] .env not found, using .env.example
    copy "backend\.env.example" "%SERVER_DEST%\.env" >nul
)

if exist "backend\cloudflared.exe" (
    copy "backend\cloudflared.exe" "%SERVER_DEST%\" >nul
    echo Copied cloudflared.exe
)

if exist "backend\config.yml" (
    copy "backend\config.yml" "%SERVER_DEST%\" >nul
    echo Copied config.yml
)

echo.
echo ===========================================
echo Build Complete!
echo.
echo The backend files have been copied to:
echo %SERVER_DEST%
echo.
echo You can now run the Inno Setup Compiler on:
echo installer\HomeCloudServerSetupScript.iss
echo ===========================================
pause
