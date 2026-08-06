@echo off
setlocal
cd /d "%~dp0"
title Clash for Windows Meta Core Patch v1.5.4.1

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Installation failed. Error code: %RC%
if "%RC%"=="0" echo Installation completed.
echo See install.log in this folder for details.
pause
exit /b %RC%
