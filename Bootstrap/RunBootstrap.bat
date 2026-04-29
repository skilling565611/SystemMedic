@echo off
setlocal

rem SystemMedic Workstation Bootstrap launcher.
rem Keeps execution local to this folder and does not modify global PATH.

set "BOOTSTRAP_DIR=%~dp0"
set "SCRIPT=%BOOTSTRAP_DIR%Bootstrap.ps1"

if not exist "%SCRIPT%" (
    echo Bootstrap.ps1 was not found next to this launcher.
    echo Expected: %SCRIPT%
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo Bootstrap finished.
) else (
    echo Bootstrap finished with exit code %EXIT_CODE%.
)
pause
exit /b %EXIT_CODE%
