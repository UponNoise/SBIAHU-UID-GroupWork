# Development Log

## 2026-06-07

### Requirements Interpreted

- Source specification: `GUI开发/CourseProject/UID_CourseProject.pdf`.
- Project topic: An Intelligent Navigation UI.
- Required implementation language: MATLAB only.
- Required startup: run `main.m`; all later operations happen through the UI.
- Required asset: `MapForUI.jpg`, 1404 x 803 pixels, 1 pixel = 1.7 meters.
- Coordinate system: real-world origin at the lower-left map corner.
- Navigation constraint: only roads are navigable.
- IV model: 8 meters by 3 meters rectangle, scalable visualization size.

### Delivered Implementation

- Built `main.m` as the required startup script.
- Built `RunIntelligentNavigationUI.m` as the programmatic MATLAB UI.
- Modeled campus roads as a manual centerline network with explicit segment widths.
- Implemented IV loading, road validity checking, orientation, removal, reports, distance, trajectory length, map rotation, road skeleton, local circular view, automatic road alignment, IV-up view, virtual street view, and path planning.
- Implemented custom Dijkstra shortest path logic instead of MATLAB `graph` or `shortestpath`.
- Avoided App Designer, `uifigure`, advanced image-processing built-ins, and advanced graph built-ins.

### Group Information

- Group leader: You Shengxuan, R32314015.
- Members 2-5: TBD.
- Optional assignment currently uses TBD placeholders for OR1-OR4 and assigns OR5/integration to the group leader.

### Validation Environment

- MATLAB was not found on this machine.
- GNU Octave 11.1.0 portable was configured under:
  - `C:\Users\canana\Tools\Octave\octave-11.1.0-w64`
- LibreOffice export was avoided after confirmation that it triggers administrator confirmation on this machine.
- Microsoft Word COM was available and used for PDF export.

### Validation Commands

Non-GUI core validation:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

Observed output:

```text
CORE_VALIDATION_OK
exit=0
```

UI smoke validation:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

Observed output:

```text
UI_SMOKE_OK
validation/logs/ui_smoke.ok written
exit=0
```

Current UI smoke behavior:

- `validate_ui_smoke.m` starts figures invisibly and deletes them before process exit.
- The latest Windows Octave run returned `exit=0` and wrote `validation/logs/ui_smoke.ok`.

### Structure and Review Update

- Moved report files and report images under `docs/report/`.
- Moved final submission attachments under `submission/`.
- Moved validation records under `validation/logs/`.
- Added Chinese project README, requirement audit, and group review guide.
- Rebuilt `submission/IntelligentNavigationUI_MatlabScripts.zip` after the UI smoke script update.

### Optimization and Risk Notes

- Road detection is manually modeled rather than automatically extracted from image color. This is more controllable for the course requirement and avoids using image-processing built-ins.
- The road model is approximate; if the instructor expects exact road boundary recognition, the best upgrade is to add a UI-assisted road editing mode.
- Virtual street view is a simplified generated scene rather than photorealistic rendering, because the project map has no real street-view imagery.
- UI runtime should be finally checked in MATLAB when available, because Octave graphics behavior is not identical to MATLAB.

### Next Steps

- Replace TBD Member 2-5 with actual names and student IDs.
- Ask each member to run `main.m` and `validate_navigation_core.m`.
- If MATLAB is available on a teammate machine, run `main.m` in MATLAB for final UI interaction QA.
- Confirm who sends the final email to Prof. Li and watch for acknowledgement of reception.
