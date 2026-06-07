# Stony Brook University ISE333 Course Project

## Intelligent Navigation UI

Course: ISE333 / CSE333 User Interface Development  
Term: Spring 2026  
Instructor: Hao Li  
School: Stony Brook University  
Group leader: You Shengxuan, R32314015  
Group members: TBD Member 2, TBD Member 3, TBD Member 4, TBD Member 5  

This repository contains the MATLAB course project for an intelligent vehicle navigation UI over the provided campus map `MapForUI.jpg`.

Official course reference: [Stony Brook University ISE333 / CSE333 User Interface Development](https://www.stonybrook.edu/sb/bulletin/current/courses/ise/)

## Repository Contents

- `main.m`: required main script. Run this file to launch the UI.
- `RunIntelligentNavigationUI.m`: programmatic UI implementation and callbacks.
- `MapForUI.jpg`: required course map asset.
- `validate_navigation_core.m`: non-GUI validation of map scale, road legality, snapping, shortest path, and local circular masking.
- `validate_ui_smoke.m`: fast UI launch smoke test.
- `Technical_Report_Intelligent_Navigation_UI.docx`: technical report.
- `Technical_Report_Intelligent_Navigation_UI.pdf`: exported report PDF.
- `Final_Submission_Attachments/`: files prepared for course email submission.
- `DEVELOPMENT_LOG.md`: development and validation log.

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
- Generate a simplified virtual street view.
- Plan and visualize a shortest road path between two arbitrary map points.

## Octave Validation

GNU Octave 11.1.0 portable was used for local acceptance because MATLAB was not available on this machine.

Non-GUI core validation:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

Expected output:

```text
CORE_VALIDATION_OK
```

UI smoke validation:

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

Expected marker file:

```text
ValidationLogs/ui_smoke.ok
```

Octave on Windows may return a non-zero process code after FLTK graphics shutdown even when the UI launched successfully. For this reason, the smoke check uses the marker file plus console output `UI_SMOKE_OK` as the acceptance signal.

## Optional Requirement Assignment

| Optional item | Scope | Assigned member |
|---|---|---|
| OR 1 | Road skeleton extraction | TBD Member 2 |
| OR 2 | Scale and local visualization | TBD Member 3 |
| OR 3 | Automatic IV orientation and IV-up view | TBD Member 4 |
| OR 4 | Virtual street view generation | TBD Member 5 |
| OR 5 | Path planning and integration | You Shengxuan (R32314015), group leader |

## Submission Files

Use files in `Final_Submission_Attachments/` for the course email:

- `IntelligentNavigationUI_MatlabScripts.zip`
- `Technical_Report_Intelligent_Navigation_UI.docx`
- `Technical_Report_Intelligent_Navigation_UI.pdf`

Before final email submission, replace TBD members with actual group member names and student IDs.
