@echo off
set "PROJECT_DIR=%~dp0"
set "OCTAVE_GUI=C:\Tools\matlab-lite\octave-gui.cmd"
if not exist "%OCTAVE_GUI%" (
  echo Missing %OCTAVE_GUI%
  echo Run Codex setup or update the Octave path first.
  pause
  exit /b 1
)
cd /d "%PROJECT_DIR%"
call "%OCTAVE_GUI%" --path . --eval "main;"
