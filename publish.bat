@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ============================================
echo   3D モデル公開ツール
echo ============================================
echo.

if "%~1"=="" (
    set /p GLBPATH="公開する .glb ファイルのフルパスを入力してください: "
) else (
    set "GLBPATH=%~1"
    echo 対象ファイル: %~1
)

if "!GLBPATH!"=="" (
    echo ファイルが指定されていません。終了します。
    pause
    exit /b 1
)

set /p TITLE="表示名を入力してください(空欄でファイル名を使用): "

echo.
echo 公開処理を実行しています...
echo.

if "%TITLE%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -GlbPath "!GLBPATH!"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -GlbPath "!GLBPATH!" -Title "%TITLE%"
)

echo.
echo ============================================
echo   処理が完了しました
echo ============================================
pause
