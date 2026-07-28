@echo off
cd /d "%~dp0"

echo ============================================
echo   3D Model Unpublish Tool
echo ============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0unpublish.ps1"

echo.
echo ============================================
echo   Done
echo ============================================
pause
