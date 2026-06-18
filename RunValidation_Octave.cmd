@echo off
set "PROJECT_DIR=%~dp0"
set "OCTAVE_CLI=C:\Tools\matlab-lite\octave-cli.cmd"
if not exist "%OCTAVE_CLI%" (
  echo Missing %OCTAVE_CLI%
  echo Run Codex setup or update the Octave path first.
  pause
  exit /b 1
)
cd /d "%PROJECT_DIR%"
call "%OCTAVE_CLI%" --no-gui --quiet --path . --eval "validate_navigation_core; validate_ui_smoke; exit(0);"
