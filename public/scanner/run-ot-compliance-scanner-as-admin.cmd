@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "SCANNER_PS1=%SCRIPT_DIR%ot-compliance-scanner.ps1"

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting administrator privileges...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

title OT Compliance Scanner Launcher
color 0A
echo ============================================================
echo OT Compliance Scanner Launcher
echo ============================================================
echo.
echo Running from:
echo %SCRIPT_DIR%
echo.

if not exist "%SCANNER_PS1%" (
    color 0C
    echo Scanner script not found:
    echo %SCANNER_PS1%
    echo.
    echo Please keep this launcher and ot-compliance-scanner.ps1 in the same folder.
    echo.
    pause
    exit /b 1
)

echo Starting read-only compliance scan...
echo This may take a minute. Please wait for the completion message.
echo.

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCANNER_PS1%"
set "SCAN_EXIT=%errorlevel%"

echo.
if not "%SCAN_EXIT%"=="0" (
    color 0C
    echo Scanner finished with exit code %SCAN_EXIT%.
    echo Please read any errors shown above.
    echo.
    pause
    exit /b %SCAN_EXIT%
)

color 0A
echo ============================================================
echo Scan completed successfully.
echo compliance-results.json should now be on your Desktop.
echo Return to the portal and upload that file.
echo ============================================================
echo.
pause