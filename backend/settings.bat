@echo off
setlocal enabledelayedexpansion
title HomeCloud - Server Settings
color 0B

:MENU
cls
echo ========================================================
echo           HOMECLOUD SERVER SETTINGS
echo ========================================================
echo.

REM Read current values from .env
if exist ".env" (
    for /f "tokens=1,2 delims==" %%a in (.env) do (
        if "%%a"=="PORT" set "CURRENT_PORT=%%b"
        if "%%a"=="AUTH_TOKEN" set "CURRENT_TOKEN=%%b"
        if "%%a"=="STORAGE_QUOTA_GB" set "CURRENT_QUOTA=%%b"
        if "%%a"=="MAX_UPLOAD_SIZE" set "CURRENT_UPLOAD=%%b"
    )
) else (
    set "CURRENT_PORT=8080"
    set "CURRENT_TOKEN=123"
    set "CURRENT_QUOTA=100"
    set "CURRENT_UPLOAD=1073741824"
)

REM Convert upload size to readable format
set /a "UPLOAD_MB=!CURRENT_UPLOAD! / 1048576"
if !UPLOAD_MB! GEQ 1024 (
    set /a "UPLOAD_GB=!UPLOAD_MB! / 1024"
    set "UPLOAD_DISPLAY=!UPLOAD_GB! GB"
) else if !UPLOAD_MB! GEQ 1 (
    set "UPLOAD_DISPLAY=!UPLOAD_MB! MB"
) else (
    set /a "UPLOAD_KB=!CURRENT_UPLOAD! / 1024"
    set "UPLOAD_DISPLAY=!UPLOAD_KB! KB"
)

echo   Current Settings:
echo   -----------------
echo   [1] Port              : !CURRENT_PORT!
echo   [2] Password          : !CURRENT_TOKEN!
echo   [3] Storage Quota     : !CURRENT_QUOTA! GB
echo   [4] Max Upload Size   : !UPLOAD_DISPLAY!
echo.
echo   -----------------
echo   [5] Save and Exit
echo   [6] Exit without Saving
echo.
echo ========================================================
echo.

set /p "CHOICE=Select option (1-6): "

if "%CHOICE%"=="1" goto EDIT_PORT
if "%CHOICE%"=="2" goto EDIT_PASSWORD
if "%CHOICE%"=="3" goto EDIT_QUOTA
if "%CHOICE%"=="4" goto EDIT_UPLOAD
if "%CHOICE%"=="5" goto SAVE_EXIT
if "%CHOICE%"=="6" goto EXIT_NOSAVE

echo Invalid option!
timeout /t 2 >nul
goto MENU

:EDIT_PORT
cls
echo ========================================================
echo                    EDIT PORT
echo ========================================================
echo.
echo   Current Port: !CURRENT_PORT!
echo.
echo   Common ports: 8080, 3000, 9000, 5000
echo   Note: Avoid ports below 1024 (reserved)
echo.
set /p "NEW_PORT=Enter new port (1024-65535): "

if "!NEW_PORT!"=="" goto MENU
if !NEW_PORT! LSS 1024 (
    echo Port must be 1024 or higher!
    timeout /t 2 >nul
    goto EDIT_PORT
)
if !NEW_PORT! GTR 65535 (
    echo Port must be 65535 or lower!
    timeout /t 2 >nul
    goto EDIT_PORT
)

set "CURRENT_PORT=!NEW_PORT!"
echo Port changed to !NEW_PORT!
timeout /t 2 >nul
goto MENU

:EDIT_PASSWORD
cls
echo ========================================================
echo                  EDIT PASSWORD
echo ========================================================
echo.
echo   Current Password: !CURRENT_TOKEN!
echo.
echo   IMPORTANT: Use a strong password!
echo   This password is used to connect from the app.
echo.
set /p "NEW_TOKEN=Enter new password: "

if "!NEW_TOKEN!"=="" goto MENU

set "CURRENT_TOKEN=!NEW_TOKEN!"
echo Password changed successfully!
timeout /t 2 >nul
goto MENU

:EDIT_QUOTA
cls
echo ========================================================
echo                EDIT STORAGE QUOTA
echo ========================================================
echo.
echo   Current Quota: !CURRENT_QUOTA! GB
echo.
echo   This is the "free space" shown to users.
echo   Minimum: 5 GB
echo   Maximum: 1000 GB
echo.
set /p "NEW_QUOTA=Enter new quota in GB (5-1000): "

if "!NEW_QUOTA!"=="" goto MENU
if !NEW_QUOTA! LSS 5 (
    echo Quota must be at least 5 GB!
    timeout /t 2 >nul
    goto EDIT_QUOTA
)
if !NEW_QUOTA! GTR 1000 (
    echo Quota cannot exceed 1000 GB!
    timeout /t 2 >nul
    goto EDIT_QUOTA
)

set "CURRENT_QUOTA=!NEW_QUOTA!"
echo Storage quota changed to !NEW_QUOTA! GB
timeout /t 2 >nul
goto MENU

:EDIT_UPLOAD
cls
echo ========================================================
echo              EDIT MAX UPLOAD SIZE
echo ========================================================
echo.
echo   Current Max Upload: !UPLOAD_DISPLAY!
echo.
echo   This is the maximum size for a single file upload.
echo   Maximum allowed: 5 GB
echo.
echo   Select unit:
echo   [1] KB (Kilobytes)
echo   [2] MB (Megabytes)
echo   [3] GB (Gigabytes)
echo   [0] Back to menu
echo.
set /p "UNIT_CHOICE=Select unit (0-3): "

if "!UNIT_CHOICE!"=="0" goto MENU
if "!UNIT_CHOICE!"=="1" goto UPLOAD_KB
if "!UNIT_CHOICE!"=="2" goto UPLOAD_MB
if "!UNIT_CHOICE!"=="3" goto UPLOAD_GB
goto EDIT_UPLOAD

:UPLOAD_KB
echo.
set /p "SIZE_VALUE=Enter size in KB (1-5242880): "
if "!SIZE_VALUE!"=="" goto MENU
if !SIZE_VALUE! LSS 1 (
    echo Size must be at least 1 KB!
    timeout /t 2 >nul
    goto EDIT_UPLOAD
)
if !SIZE_VALUE! GTR 5242880 (
    echo Size cannot exceed 5 GB (5242880 KB)!
    timeout /t 2 >nul
    goto EDIT_UPLOAD
)
set /a "CURRENT_UPLOAD=!SIZE_VALUE! * 1024"
echo Max upload size changed to !SIZE_VALUE! KB
timeout /t 2 >nul
goto MENU

:UPLOAD_MB
echo.
set /p "SIZE_VALUE=Enter size in MB (1-5120): "
if "!SIZE_VALUE!"=="" goto MENU
if !SIZE_VALUE! LSS 1 (
    echo Size must be at least 1 MB!
    timeout /t 2 >nul
    goto EDIT_UPLOAD
)
if !SIZE_VALUE! GTR 5120 (
    echo Size cannot exceed 5 GB (5120 MB)!
    timeout /t 2 >nul
    goto EDIT_UPLOAD
)
set /a "CURRENT_UPLOAD=!SIZE_VALUE! * 1048576"
echo Max upload size changed to !SIZE_VALUE! MB
timeout /t 2 >nul
goto MENU

:UPLOAD_GB
echo.
set /p "SIZE_VALUE=Enter size in GB (1-5): "
if "!SIZE_VALUE!"=="" goto MENU
if !SIZE_VALUE! LSS 1 (
    echo Size must be at least 1 GB!
    timeout /t 2 >nul
    goto EDIT_UPLOAD
)
if !SIZE_VALUE! GTR 5 (
    echo Size cannot exceed 5 GB!
    timeout /t 2 >nul
    goto EDIT_UPLOAD
)
set /a "CURRENT_UPLOAD=!SIZE_VALUE! * 1073741824"
echo Max upload size changed to !SIZE_VALUE! GB
timeout /t 2 >nul
goto MENU

:SAVE_EXIT
cls
echo ========================================================
echo                   SAVING SETTINGS
echo ========================================================
echo.

(
echo PORT=!CURRENT_PORT!
echo AUTH_TOKEN=!CURRENT_TOKEN!
echo WATCH_DIR=./uploads
echo STORAGE_QUOTA_GB=!CURRENT_QUOTA!
echo MAX_UPLOAD_SIZE=!CURRENT_UPLOAD!
) > .env

echo   Settings saved to .env file!
echo.
echo   New settings:
echo   - Port: !CURRENT_PORT!
echo   - Password: !CURRENT_TOKEN!
echo   - Storage Quota: !CURRENT_QUOTA! GB
echo   - Max Upload Size: !CURRENT_UPLOAD! bytes
echo.
echo   NOTE: Restart the server for changes to take effect.
echo.
pause
goto :EOF

:EXIT_NOSAVE
cls
echo.
echo   Exiting without saving...
echo.
timeout /t 2 >nul
goto :EOF
