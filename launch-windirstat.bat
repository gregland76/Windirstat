@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%windirstat.ps1"

if not exist "%PS_SCRIPT%" (
  echo [ERROR] Impossible de trouver le script : %PS_SCRIPT%
  pause
  exit /b 1
)

where pwsh >nul 2>&1
if %errorlevel%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -STA -File "%PS_SCRIPT%"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%PS_SCRIPT%"
)

set "EXITCODE=%ERRORLEVEL%"
if not "%EXITCODE%"=="0" (
  echo.
  echo [INFO] Le script PowerShell s'est termine avec le code %EXITCODE%.
  pause
)

endlocal
exit /b %EXITCODE%
