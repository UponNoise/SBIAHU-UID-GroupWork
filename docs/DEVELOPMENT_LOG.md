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
- Modeled campus roads as explicit road corridors with segment widths.
- Implemented IV loading, road validity checking, orientation, removal, reports, distance, trajectory length, map rotation, road skeleton, local circular view, automatic road alignment, IV-up view, virtual street view, and path planning.
- Replaced sparse centerline path planning with a dense 3 px navigable road grid and custom A* search instead of MATLAB `graph` or `shortestpath`.
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

### 2026-06-11 Road Model Rework

- Re-read `UID_CourseProject.pdf` and confirmed that only roads in `MapForUI.jpg` are navigable.
- Reviewed `practice/Practice03`, `practice/Practice04`, and `practice/Practice05` as references. Practice05 supports the current programmatic `figure`/`axes`/`uicontrol` implementation style; Practice03/04 support the coordinate geometry and simplified camera/street-view reasoning.
- Removed the previous sparse grid-like road model because it visibly crossed buildings, green areas, and water.
- Added `RoadModelDataPx.m` as a single shared road-corridor data source in map pixel coordinates.
- Switched path planning from the sparse centerline path model to a 3 px road-grid A* search.
- Updated `Road Model` visualization to show both traced road centerlines and sampled navigable grid nodes.
- Regenerated `docs/report/assets/RoadModelOverlay.png` with the corrected road corridor/grid overlay.
- Re-ran Octave validation: `validate_navigation_core` and `validate_ui_smoke` both returned `exit=0`.

### 2026-06-14 Road Annotation Review

- Rechecked the road overlay against the campus map and removed four suspect internal/courtyard shortcut polylines from `RoadModelDataPx.m`.
- Reduced the navigable road-grid step to 4 px for higher route fidelity where curves and intersections are close together.
- Regenerated `RoadModelOverlay.png`, `grid_path_example.png`, the technical report DOCX/PDF, and the MATLAB scripts zip.
- Re-ran validation after the revision: 201 road segments, 18472 grid nodes, `CORE_VALIDATION_OK`, and `UI_SMOKE_OK`.

### 2026-06-17 High-Precision Road Extraction and UI Revision

- Synchronized the repository with remote `main`; no open GitHub PRs were found.
- Used the newly added path-marked map image as the road-model source and added `tools/extract_road_model_from_marked_map.py` to reproduce the extraction.
- Generated `RoadModelDataPx.m` from `#00FF00` green width road markings after allowing color tolerance for WeChat JPEG compression: 245 skeleton polylines and 370 road segments.
- Estimated each road segment width from the green road area's distance transform; the extracted width range is 7.0-25.5 px.
- Changed the navigable grid to 3 px; the resulting road grid has 23508 nodes.
- Updated the virtual street view from a fixed drawing to a perspective projection based on road heading and road width.
- Refined the main UI with a blue campus-map-service header inspired by the AHU campus map reference page.

### Optimization and Risk Notes

- Road detection is extracted offline from the path-marked map; the MATLAB runtime still uses only the generated `.m` road data and basic mathematical procedures.
- The 3 px road grid improves path fidelity, but the model still depends on the quality of the marked road reference. If a specific road segment is judged off, update the marked map or `RoadModelDataPx.m`, then rerun extraction and validation.
- Virtual street view is a generated perspective scene rather than photorealistic rendering, because the project map has no real street-view imagery.
- UI runtime should be finally checked in MATLAB when available, because Octave graphics behavior is not identical to MATLAB.

### Next Steps

- Replace TBD Member 2-5 with actual names and student IDs.
- Ask each member to run `main.m` and `validate_navigation_core.m`.
- If MATLAB is available on a teammate machine, run `main.m` in MATLAB for final UI interaction QA.
- Confirm who sends the final email to Prof. Li and watch for acknowledgement of reception.
