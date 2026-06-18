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
  - `$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64`
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
- Generated `RoadModelDataPx.m` from `#00FF00` green width road markings after allowing color tolerance for WeChat JPEG compression: 283 skeleton polylines and 408 road segments.
- Estimated each road segment width from the green road area's distance transform; the extracted width range is 7.0-26.2 px.
- Changed the navigable grid to 3 px; the resulting road grid has 24069 nodes.
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

### 2026-06-17 Design Review

- Conducted a comprehensive project design review covering all code, documentation, validation, and submission artifacts.
- Identified 14 TODO items: 4 high-priority (team-member TBD names, submission package rebuild, missing log details, MATLAB acceptance), 6 medium-priority (A* efficiency, validation assertion thresholds, hardcoded paths, OR3 interaction, street-view lifecycle, node-merging tolerance), and 4 low-priority items.
- Created `docs/DESIGN_REVIEW_TODO_CN.md` as the tracking document and linked it from `docs/PROJECT_AUDIT_CN.md`.

### 2026-06-17 Chinese UI Merge and Road Source Refresh

- Merged the latest remote `main` changes before editing, preserving the high-precision vectorized road model workflow and perspective street-view logic.
- Replaced the road extraction input with the latest green road-width annotation image, including the newly added small road on the left side, then reran `tools/extract_road_model_from_marked_map.py`.
- Regenerated `RoadModelDataPx.m` from the updated green annotation source: 283 skeleton polylines, 408 road segments, 3 px navigable road grid, and 24069 validation grid nodes.
- Converted the main MATLAB UI visible labels, status text, report list, log messages, dialog text, axes labels, and virtual street-view text to Chinese.
- Fixed MATLAB UI readability by forcing right-panel buttons to use a light background with dark bold text, and by using dark foreground colors for text, list boxes, edit boxes, and map title text.
- Rebuilt `submission/IntelligentNavigationUI_MatlabScripts.zip` after the merge.
- Octave validation on this machine passed:
  - `validate_navigation_core`: `CORE_VALIDATION_OK`
  - `validate_ui_smoke`: `UI_SMOKE_OK`

### 2026-06-18 TODO Optimization Iteration

- Confirmed local `main` was already aligned with `origin/main` after the remote merge; `gh pr list` reported no open pull requests.
- Replaced the A* open-set linear minimum scan with a binary min-heap in both `RunIntelligentNavigationUI.m` and `validate_navigation_core.m`.
- Used DeepSeek only as an advisory reviewer for the MATLAB/Octave diff; the accepted follow-up was adding a deterministic min-heap pop-order self-test to `validate_navigation_core.m`.
- Tightened validation assertions to match the current high-precision road model: more than 350 road segments, more than 100 network nodes, 3 px grid, and more than 20000 grid nodes.
- Adjusted road-network endpoint de-duplication tolerance from 0.01 m to 0.5 m to better match the 1.7 m/px map scale.
- Added IV Up log messages explaining whether `Auto align road` is currently enabled.
- Reworked Street View window lifecycle so repeated street-view clicks reuse the existing window and closing the window clears the saved handle.
- Added a Skeleton Road guard: if fewer than 2 skeleton points exist, the checkbox is reset and the UI logs a clear prompt.
- Generalized Octave command documentation to avoid hardcoding the group leader's absolute Windows user path.
- Added `validation/logs/manual_test_checklist.md` for MATLAB manual interaction acceptance.
- Rebuilt `submission/IntelligentNavigationUI_MatlabScripts.zip` with the updated MATLAB files.
- Re-ran local Octave validation:
  - `validate_navigation_core`: `CORE_VALIDATION_OK`
  - `validate_ui_smoke`: `UI_SMOKE_OK`

### 2026-06-18 Local Runtime and Plugin Diagnostics

- Confirmed full MATLAB is not installed on this machine; `winget` only offers MATLAB Runtime/Connector, which cannot run or debug this `.m` GUI source as a MATLAB IDE replacement.
- Created `C:\Tools\matlab-lite` command shims for the existing GNU Octave 11.1.0 portable install.
- Detected that `octave-gui.exe` fails fast on this workstation; changed the local visible launcher to use `octave-cli.exe --persist`, which successfully opens the project figure window.
- Added `RunProject_OctaveGUI.cmd`, `RunValidation_Octave.cmd`, and `docs/LOCAL_ENVIRONMENT_CN.md`.
- Re-ran `RunValidation_Octave.cmd`: `CORE_VALIDATION_OK` and `UI_SMOKE_OK`.
- Verified a visible `ISE 333 智能导航界面` window starts through the new launcher.
- Checked Browser/ComputerUse: local runtime files and native pipes exist, but the current Codex session does not expose callable Browser or Computer Use tools, and no exact install candidate is available through the plugin installer.
- Installed Playwright Chromium for the `node_repl` fallback and verified headless browser automation works.
