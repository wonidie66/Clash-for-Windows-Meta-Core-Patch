@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build-full-package.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Full package build failed. Error code: %RC%
if "%RC%"=="0" echo Full package build completed.
pause
exit /b %RC%
