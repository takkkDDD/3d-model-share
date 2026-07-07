@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ============================================
echo   3D Model Publish Tool
echo ============================================
echo.

if "%~1"=="" (
    set /p GLBPATH="Enter full path to the .glb file: "
) else (
    set "GLBPATH=%~1"
    echo Target file: %~1
)

if "!GLBPATH!"=="" (
    echo No file specified. Exiting.
    pause
    exit /b 1
)

set /p TITLE="Enter display title (leave blank to use filename): "

echo.
echo Publishing...
echo.

if "%TITLE%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -GlbPath "!GLBPATH!"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -GlbPath "!GLBPATH!" -Title "%TITLE%"
)

echo.
echo ============================================
echo   Done
echo ============================================
pause
