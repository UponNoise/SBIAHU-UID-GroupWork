# Octave Validation Summary

Date: 2026-06-11
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
- Manual road-corridor segment construction from `RoadModelDataPx.m`.
- Dense 4 px navigable road-grid construction; current grid has 18472 navigable nodes.
- Road-valid point acceptance.
- Off-road point rejection for IV loading.
- Arbitrary-point snapping for path planning.
- Custom A* shortest path result sanity on the road grid.
- Local circular map mask center/outer-corner behavior.

## UI Smoke Validation

Command:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

Observed output:

```text
UI_SMOKE_OK
validation/logs/ui_smoke.ok written
exit=0
```

Important note:

- `validate_ui_smoke.m` now starts figures invisibly and deletes all figures before exit.
- The current Windows Octave run returned `exit=0` and wrote `validation/logs/ui_smoke.ok`.
- This proves that `RunIntelligentNavigationUI` launched without a thrown exception in the smoke environment.

## Remaining Runtime Check

Final interactive UI acceptance should still be run in MATLAB if a teammate has MATLAB installed, because Octave's graphics backend differs from MATLAB's runtime UI behavior.
