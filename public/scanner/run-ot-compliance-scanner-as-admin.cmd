@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "SCANNER_PS1=%SCRIPT_DIR%ot-compliance-scanner.ps1"

if not exist "%SCANNER_PS1%" (
  echo Scanner script not found:
  echo %SCANNER_PS1%
  echo.
  echo Please keep this launcher and ot-compliance-scanner.ps1 in the same folder.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoExit -ExecutionPolicy Bypass -File ""%SCANNER_PS1%""'"

echo If prompted by Windows, approve the administrator request to run the scanner.
timeout /t 3 >nul