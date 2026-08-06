@echo off
setlocal
cd /d "%~dp0"
echo Restore original Clash for Windows files and remove the patch service
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Restore failed. Error code: %RC%
if "%RC%"=="0" echo Restore completed.
echo See uninstall.log in this folder for details.
pause
exit /b %RC%
