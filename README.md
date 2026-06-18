# SBIAHU-UID-GroupWork

## Stony Brook University ISE333 Course Project: Intelligent Navigation UI

Course: ISE333 / CSE333 User Interface Development  
Term: Spring 2026  
Instructor: Hao Li  
School: Anhui University  
Group leader: You Shengxuan 
Group members: …… 

This repository contains the MATLAB course project for an intelligent vehicle navigation UI over the provided campus map `MapForUI.jpg`.

Official course reference: [Stony Brook University ISE333 / CSE333 User Interface Development](https://www.stonybrook.edu/sb/bulletin/current/courses/ise/)

## Repository Contents

- `main.m`: required main script. Run this file to launch the UI.
- `RunIntelligentNavigationUI.m`: programmatic UI implementation and callbacks.
- `RoadModelDataPx.m`: road-corridor data extracted from the green width-marked map in pixel coordinates.
- `MapForUI.jpg`: required course map asset.
- `validate_navigation_core.m`: non-GUI validation of map scale, road legality, 3 px road grid, snapping, shortest path, and local circular masking.
- `validate_ui_smoke.m`: fast UI launch smoke test.
- `RunProject_OctaveGUI.cmd`: Windows Octave visible-window launcher for this workstation.
- `RunValidation_Octave.cmd`: Windows Octave one-command validation launcher.
- `README_CN.md`: Chinese project guide for group members.
- `docs/`: technical report, design assets, Chinese audit notes, and development log.
- `tools/extract_road_model_from_marked_map.py`: offline helper that converts the green width-marked road image into `RoadModelDataPx.m`.
- `submission/`: files prepared for course email submission.
- `validation/logs/`: Octave validation summary and smoke-test markers.

## Run the UI

Open MATLAB, set the current folder to this repository, and run:

```matlab
main
```

After launch, all project operations are available through the UI:

- Load and visualize the map.
- Click map points to display real-world coordinates.
- Load one or multiple IVs on valid roads.
- Adjust IV orientation manually or align it automatically with the road.
- Remove selected IVs.
- Report real-world IV positions.
- Measure two-point distance and trajectory length.
- Rotate the map by a user-entered degree.
- Extract and visualize a manual road skeleton.
- Adjust IV visualization scale and local circular map range.
- Generate a perspective-based virtual street view.
- Plan and visualize a shortest road path between two arbitrary map points.

Path planning uses a road corridor model extracted from the `#00FF00` width-marked map plus a dense 3 px navigable grid. The grid is searched with a custom A* implementation, avoiding MATLAB `graph` and `shortestpath`.

## Octave Validation

GNU Octave 11.1.0 portable was used for local acceptance because MATLAB was not available on this machine. If Octave is installed elsewhere, replace the example path below; if `octave-cli` is in PATH, call `octave-cli` directly.

Non-GUI core validation:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

Expected output:

```text
CORE_VALIDATION_OK
exit=0
```

UI smoke validation:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

Expected output and marker file:

```text
UI_SMOKE_OK
exit=0
validation/logs/ui_smoke.ok
```

The smoke script runs figures invisibly and deletes them before exit, so the current Octave check returns `exit=0` on this machine. MATLAB should still be used for final interactive UI acceptance when available.

This workstation also provides:

```powershell
.\RunValidation_Octave.cmd
.\RunProject_OctaveGUI.cmd
```

`octave-gui.exe` fails fast on this workstation, so the visible launcher uses `octave-cli --persist` to open the figure UI without starting the Octave IDE.

## Optional Requirement Assignment

| Optional item | Scope | Assigned member |
|---|---|---|
| OR 1 | Road skeleton extraction | TBD Member 2 |
| OR 2 | Scale and local visualization | TBD Member 3 |
| OR 3 | Automatic IV orientation and IV-up view | TBD Member 4 |
| OR 4 | Virtual street view generation | TBD Member 5 |
| OR 5 | Path planning and integration | You Shengxuan (R32314015), group leader |

## Submission Files

Use files in `submission/` for the course email:

- `IntelligentNavigationUI_MatlabScripts.zip`
- `Technical_Report_Intelligent_Navigation_UI.docx`
- `Technical_Report_Intelligent_Navigation_UI.pdf`

Before final email submission, replace TBD members with actual group member names and student IDs.
