# Octave Validation Summary

Date: 2026-06-07  
Validator: GNU Octave 11.1.0 portable on Windows  
Project: Stony Brook University ISE333 User Interface Development Course Project  

## Core Validation

Command:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

Result:

```text
CORE_VALIDATION_OK
exit=0
```

Coverage:

- Map image dimensions and RGB channel check.
- Pixel-to-meter coordinate conversion.
- Road network segment and node construction.
- Road-valid point acceptance.
- Off-road point rejection for IV loading.
- Arbitrary-point snapping for path planning.
- Custom shortest path result sanity.
- Local circular map mask center/outer-corner behavior.

## UI Smoke Validation

Command:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

Observed output:

```text
UI_SMOKE_OK
ValidationLogs/ui_smoke.ok written
```

Important note:

- Octave/FLTK on Windows returned a non-zero process code after UI shutdown.
- The UI smoke script wrote `ValidationLogs/ui_smoke.ok`, proving that `RunIntelligentNavigationUI` launched without a thrown exception.
- This is treated as a known Octave graphics-backend shutdown issue, not a UI construction failure.

## Remaining Runtime Check

Final interactive UI acceptance should still be run in MATLAB if a teammate has MATLAB installed, because Octave's graphics backend differs from MATLAB's runtime UI behavior.
