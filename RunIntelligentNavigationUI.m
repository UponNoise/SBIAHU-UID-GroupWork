function RunIntelligentNavigationUI()
%RUNINTELLIGENTNAVIGATIONUI Launches the course project navigation UI.
%
% The implementation intentionally uses programmatic MATLAB UI controls,
% basic graphics, imread, and explicit mathematical procedures.

app = struct();
app.scaleM = 1.7;
app.baseDir = fileparts(mfilename('fullpath'));
app.mapFile = fullfile(app.baseDir, 'MapForUI.jpg');
app.mapImage = imread(app.mapFile);
[app.mapHeightPx, app.mapWidthPx, ~] = size(app.mapImage);
app.mapWidthM = app.mapWidthPx * app.scaleM;
app.mapHeightM = app.mapHeightPx * app.scaleM;
app.mapCenter = [app.mapWidthM / 2, app.mapHeightM / 2];
app.network = buildRoadNetwork(app.mapWidthPx, app.mapHeightPx, app.scaleM);
app.vehicles = struct('id', {}, 'pos', {}, 'theta', {}, 'scale', {});
app.nextVehicleId = 1;
app.mode = 'inspect';
app.distancePoints = [];
app.trajectoryPoints = [];
app.skeletonPoints = [];
app.pathClickPoints = [];
app.pathResult = [];
app.mapRotation = 0;
app.localMode = false;
app.localVehicleId = [];
app.showSkeletonBand = false;
app.logLines = {};
app.lastPoint = [];

createUi();
addLog('UI launched. Use map clicks and controls only after this point.');
redraw();

    function createUi()
        app.fig = figure( ...
            'Name', 'ISE 333 Intelligent Navigation UI', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Color', [0.94 0.95 0.95], ...
            'Position', [60 40 1320 760], ...
            'WindowButtonDownFcn', @onFigureClick);

        app.ax = axes('Parent', app.fig, ...
            'Units', 'pixels', ...
            'Position', [25 45 930 690], ...
            'Box', 'on', ...
            'XColor', [0.2 0.2 0.2], ...
            'YColor', [0.2 0.2 0.2], ...
            'Color', [1 1 1]);

        app.panel = uipanel('Parent', app.fig, ...
            'Units', 'pixels', ...
            'Position', [975 20 320 720], ...
            'Title', 'Navigation Controls', ...
            'BackgroundColor', [0.96 0.97 0.97], ...
            'FontWeight', 'bold');

        x = 15;
        w = 290;
        y = 665;
        h = 26;
        gap = 8;

        app.h.coordText = uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y w 36], ...
            'String', 'Position: --', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.96 0.97 0.97], ...
            'FontWeight', 'bold');
        y = y - 39;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 90 h], ...
            'String', 'Load Map', ...
            'Callback', @onLoadMap);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 100 y 90 h], ...
            'String', 'Inspect', ...
            'Callback', @(~, ~) setMode('inspect'));
        app.h.showRoad = uicontrol(app.panel, 'Style', 'checkbox', ...
            'Position', [x + 200 y 90 h], ...
            'String', 'Road Model', ...
            'Value', 0, ...
            'BackgroundColor', [0.96 0.97 0.97], ...
            'Callback', @(~, ~) redraw());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', 'IV angle', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.96 0.97 0.97]);
        app.h.angleEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '0', ...
            'BackgroundColor', [1 1 1]);
        app.h.autoAlign = uicontrol(app.panel, 'Style', 'checkbox', ...
            'Position', [x + 143 y 122 h], ...
            'String', 'Auto align road', ...
            'Value', 1, ...
            'BackgroundColor', [0.96 0.97 0.97]);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', 'Add IV by Click', ...
            'Callback', @(~, ~) setMode('addIV'));
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Remove IV', ...
            'Callback', @onRemoveVehicle);
        y = y - h - gap;

        app.h.vehiclePopup = uicontrol(app.panel, 'Style', 'popupmenu', ...
            'Position', [x y 140 h], ...
            'String', {'No IV'}, ...
            'BackgroundColor', [1 1 1], ...
            'Callback', @(~, ~) refreshVehicleFields());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Report IVs', ...
            'Callback', @onReportVehicles);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', 'IV scale', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.96 0.97 0.97]);
        app.h.scaleEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '1.0', ...
            'BackgroundColor', [1 1 1]);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 143 y 122 h], ...
            'String', 'Apply Scale', ...
            'Callback', @onApplyScale);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', 'Local r(m)', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.96 0.97 0.97]);
        app.h.localRadiusEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '120', ...
            'BackgroundColor', [1 1 1]);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 143 y 58 h], ...
            'String', 'Local', ...
            'Callback', @onLocalView);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 207 y 58 h], ...
            'String', 'Full', ...
            'Callback', @onFullView);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', '2-Point Distance', ...
            'Callback', @(~, ~) startDistance());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Trajectory Start', ...
            'Callback', @(~, ~) startTrajectory());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', 'Trajectory Finish', ...
            'Callback', @(~, ~) finishTrajectory());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Clear Measures', ...
            'Callback', @(~, ~) clearMeasures());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', 'Rotate deg', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.96 0.97 0.97]);
        app.h.rotationEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '0', ...
            'BackgroundColor', [1 1 1]);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 143 y 58 h], ...
            'String', 'Apply', ...
            'Callback', @onApplyRotation);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 207 y 58 h], ...
            'String', 'IV Up', ...
            'Callback', @onRotateIvUp);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', 'Extract Skeleton', ...
            'Callback', @(~, ~) startSkeleton());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Clear Skeleton', ...
            'Callback', @(~, ~) clearSkeleton());
        y = y - h - gap;

        app.h.skeletonBand = uicontrol(app.panel, 'Style', 'checkbox', ...
            'Position', [x y 140 h], ...
            'String', 'Skeleton Road', ...
            'Value', 0, ...
            'BackgroundColor', [0.96 0.97 0.97], ...
            'Callback', @(~, ~) onSkeletonBand());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Path Plan', ...
            'Callback', @(~, ~) startPathPlan());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', 'Street View', ...
            'Callback', @(~, ~) startStreetView());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', 'Reset View', ...
            'Callback', @onResetView);
        y = y - h - gap;

        app.h.statusText = uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y - 2 w 34], ...
            'String', 'Mode: inspect', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.96 0.97 0.97], ...
            'FontWeight', 'bold');
        y = y - 118;

        app.h.reportList = uicontrol(app.panel, 'Style', 'listbox', ...
            'Position', [x y w 108], ...
            'String', {'IV report appears here'}, ...
            'BackgroundColor', [1 1 1]);
        y = y - 150;

        app.h.logList = uicontrol(app.panel, 'Style', 'listbox', ...
            'Position', [x 15 w 140], ...
            'String', {'Log'}, ...
            'BackgroundColor', [1 1 1]);
    end

    function onLoadMap(~, ~)
        app.mapImage = imread(app.mapFile);
        addLog('Map loaded from MapForUI.jpg.');
        redraw();
    end

    function setMode(newMode)
        app.mode = newMode;
        if strcmp(newMode, 'inspect')
            app.distancePoints = [];
            app.pathClickPoints = [];
        end
        set(app.h.statusText, 'String', ['Mode: ' modeLabel()]);
        addLog(['Mode set to ' modeLabel() '.']);
    end

    function label = modeLabel()
        label = app.mode;
        if strcmp(app.mode, 'addIV')
            label = 'add IV';
        elseif strcmp(app.mode, 'distance')
            label = '2-point distance';
        elseif strcmp(app.mode, 'trajectory')
            label = 'trajectory';
        elseif strcmp(app.mode, 'skeleton')
            label = 'road skeleton';
        elseif strcmp(app.mode, 'path')
            label = 'path planning';
        elseif strcmp(app.mode, 'street')
            label = 'street view';
        end
    end

    function onFigureClick(~, ~)
        clicked = hittest(app.fig);
        clickedAxes = ancestor(clicked, 'axes');
        if isempty(clickedAxes) || clickedAxes ~= app.ax
            return;
        end

        cp = get(app.ax, 'CurrentPoint');
        displayPoint = [cp(1, 1), cp(1, 2)];
        mapPoint = inverseDisplayPoint(displayPoint);
        if ~pointInsideMap(mapPoint)
            setCoordinateText(mapPoint, false);
            return;
        end

        app.lastPoint = mapPoint;
        setCoordinateText(mapPoint, true);

        if strcmp(app.mode, 'inspect')
            return;
        elseif strcmp(app.mode, 'addIV')
            addVehicleAt(mapPoint);
        elseif strcmp(app.mode, 'distance')
            addDistancePoint(mapPoint);
        elseif strcmp(app.mode, 'trajectory')
            addTrajectoryPoint(mapPoint);
        elseif strcmp(app.mode, 'skeleton')
            addSkeletonPoint(mapPoint);
        elseif strcmp(app.mode, 'path')
            addPathPoint(mapPoint);
        elseif strcmp(app.mode, 'street')
            createStreetView(mapPoint);
        end
    end

    function setCoordinateText(pt, inside)
        if inside
            s = sprintf('Position: X %.1f m, Y %.1f m', pt(1), pt(2));
        else
            s = sprintf('Position: outside map (%.1f, %.1f)', pt(1), pt(2));
        end
        set(app.h.coordText, 'String', s);
    end

    function addVehicleAt(pt)
        [valid, snapped, segIdx, distM] = nearestRoad(app.network, pt);
        if ~valid
            addLog(sprintf('Invalid IV point. Nearest road distance %.1f m.', distM));
            errordlg('The selected point is not on a navigable road.', 'Invalid IV Point');
            return;
        end

        if get(app.h.autoAlign, 'Value') == 1
            theta = segmentAngle(app.network.segments(segIdx, :));
        else
            theta = readNumber(app.h.angleEdit, 0);
        end

        scaleValue = readNumber(app.h.scaleEdit, 1.0);
        if scaleValue <= 0
            scaleValue = 1.0;
        end

        v = struct();
        v.id = app.nextVehicleId;
        v.pos = snapped;
        v.theta = normalizeAngle(theta);
        v.scale = scaleValue;
        app.vehicles(end + 1) = v;
        app.nextVehicleId = app.nextVehicleId + 1;

        updateVehiclePopup(v.id);
        addLog(sprintf('IV %d loaded at (%.1f, %.1f), theta %.1f deg.', ...
            v.id, v.pos(1), v.pos(2), v.theta));
        setMode('inspect');
        redraw();
    end

    function onRemoveVehicle(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('No IV selected for removal.');
            return;
        end
        removedId = app.vehicles(idx).id;
        app.vehicles(idx) = [];
        if isequal(app.localVehicleId, removedId)
            app.localMode = false;
            app.localVehicleId = [];
        end
        updateVehiclePopup([]);
        addLog(sprintf('IV %d removed.', removedId));
        redraw();
    end

    function onApplyScale(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('No IV selected for scaling.');
            return;
        end
        scaleValue = readNumber(app.h.scaleEdit, app.vehicles(idx).scale);
        if scaleValue <= 0
            addLog('Scale must be positive.');
            return;
        end
        app.vehicles(idx).scale = scaleValue;
        addLog(sprintf('IV %d visualization scale set to %.2f.', ...
            app.vehicles(idx).id, scaleValue));
        redraw();
    end

    function onLocalView(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('No IV selected for local view.');
            return;
        end
        radius = readNumber(app.h.localRadiusEdit, 120);
        if radius <= 0
            addLog('Local radius must be positive.');
            return;
        end
        app.localMode = true;
        app.localVehicleId = app.vehicles(idx).id;
        addLog(sprintf('Local circular map centered on IV %d, radius %.1f m.', ...
            app.localVehicleId, radius));
        redraw();
    end

    function onFullView(~, ~)
        app.localMode = false;
        app.localVehicleId = [];
        addLog('Full map view restored.');
        redraw();
    end

    function startDistance()
        app.distancePoints = [];
        app.mode = 'distance';
        set(app.h.statusText, 'String', 'Mode: 2-point distance');
        addLog('Click two map points to measure real-world distance.');
        redraw();
    end

    function addDistancePoint(pt)
        app.distancePoints(end + 1, :) = pt;
        if size(app.distancePoints, 1) == 1
            addLog(sprintf('Distance point A: (%.1f, %.1f).', pt(1), pt(2)));
        else
            a = app.distancePoints(1, :);
            b = app.distancePoints(2, :);
            d = euclideanDistance(a, b);
            addLog(sprintf('Distance A-B = %.1f m.', d));
            app.mode = 'inspect';
            set(app.h.statusText, 'String', 'Mode: inspect');
        end
        redraw();
    end

    function startTrajectory()
        app.trajectoryPoints = [];
        app.mode = 'trajectory';
        set(app.h.statusText, 'String', 'Mode: trajectory');
        addLog('Trajectory started. Click points in order, then press Trajectory Finish.');
        redraw();
    end

    function addTrajectoryPoint(pt)
        app.trajectoryPoints(end + 1, :) = pt;
        addLog(sprintf('Trajectory point %d: (%.1f, %.1f).', ...
            size(app.trajectoryPoints, 1), pt(1), pt(2)));
        redraw();
    end

    function finishTrajectory()
        if size(app.trajectoryPoints, 1) < 2
            addLog('Trajectory needs at least two clicked points.');
        else
            total = polylineLength(app.trajectoryPoints);
            addLog(sprintf('Trajectory length = %.1f m over %d points.', ...
                total, size(app.trajectoryPoints, 1)));
        end
        app.mode = 'inspect';
        set(app.h.statusText, 'String', 'Mode: inspect');
        redraw();
    end

    function clearMeasures()
        app.distancePoints = [];
        app.trajectoryPoints = [];
        app.pathClickPoints = [];
        app.pathResult = [];
        addLog('Distance, trajectory, and path drawings cleared.');
        redraw();
    end

    function onApplyRotation(~, ~)
        deg = readNumber(app.h.rotationEdit, 0);
        app.mapRotation = normalizeAngle(deg);
        set(app.h.rotationEdit, 'String', sprintf('%.1f', app.mapRotation));
        addLog(sprintf('Map rotation set to %.1f degrees.', app.mapRotation));
        redraw();
    end

    function onRotateIvUp(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('Select an IV before using IV Up.');
            return;
        end
        app.mapRotation = normalizeAngle(90 - app.vehicles(idx).theta);
        set(app.h.rotationEdit, 'String', sprintf('%.1f', app.mapRotation));
        addLog(sprintf('Map rotated so IV %d heads upward.', app.vehicles(idx).id));
        redraw();
    end

    function onResetView(~, ~)
        app.mapRotation = 0;
        app.localMode = false;
        app.localVehicleId = [];
        set(app.h.rotationEdit, 'String', '0');
        addLog('Rotation and local view reset.');
        redraw();
    end

    function startSkeleton()
        app.mode = 'skeleton';
        set(app.h.statusText, 'String', 'Mode: road skeleton');
        addLog('Click valid road points to manually extract the road skeleton.');
        redraw();
    end

    function addSkeletonPoint(pt)
        [valid, snapped, ~, distM] = nearestRoad(app.network, pt);
        if ~valid
            addLog(sprintf('Skeleton point rejected. Nearest road distance %.1f m.', distM));
            return;
        end
        app.skeletonPoints(end + 1, :) = snapped;
        addLog(sprintf('Skeleton point %d added at (%.1f, %.1f).', ...
            size(app.skeletonPoints, 1), snapped(1), snapped(2)));
        redraw();
    end

    function clearSkeleton()
        app.skeletonPoints = [];
        app.showSkeletonBand = false;
        set(app.h.skeletonBand, 'Value', 0);
        addLog('Manual road skeleton cleared.');
        redraw();
    end

    function onSkeletonBand()
        app.showSkeletonBand = get(app.h.skeletonBand, 'Value') == 1;
        redraw();
    end

    function startPathPlan()
        app.pathClickPoints = [];
        app.pathResult = [];
        app.mode = 'path';
        set(app.h.statusText, 'String', 'Mode: path planning');
        addLog('Click start and destination points. They will snap to closest roads.');
        redraw();
    end

    function addPathPoint(pt)
        app.pathClickPoints(end + 1, :) = pt;
        if size(app.pathClickPoints, 1) == 1
            addLog(sprintf('Path start selected at (%.1f, %.1f).', pt(1), pt(2)));
        else
            startPt = app.pathClickPoints(1, :);
            endPt = app.pathClickPoints(2, :);
            [route, len, ok, snappedStart, snappedEnd] = planShortestPath(app.network, startPt, endPt);
            if ok
                app.pathResult = route;
                addLog(sprintf('Shortest road path = %.1f m. Start snap (%.1f, %.1f), end snap (%.1f, %.1f).', ...
                    len, snappedStart(1), snappedStart(2), snappedEnd(1), snappedEnd(2)));
            else
                app.pathResult = [];
                addLog('Path planning failed: selected points are too far from the road model.');
            end
            app.mode = 'inspect';
            set(app.h.statusText, 'String', 'Mode: inspect');
        end
        redraw();
    end

    function startStreetView()
        app.mode = 'street';
        set(app.h.statusText, 'String', 'Mode: street view');
        addLog('Click a road point to generate virtual street view.');
    end

    function createStreetView(pt)
        [valid, snapped, segIdx, distM] = nearestRoad(app.network, pt);
        if ~valid
            addLog(sprintf('Street view point rejected. Nearest road distance %.1f m.', distM));
            return;
        end
        theta = segmentAngle(app.network.segments(segIdx, :));
        f = figure('Name', 'Virtual Street View', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Color', [0.92 0.94 0.96], ...
            'Position', [180 120 720 420]);
        ax = axes('Parent', f, 'Units', 'normalized', 'Position', [0.06 0.08 0.88 0.84]);
        hold(ax, 'on');
        axis(ax, [0 100 0 60]);
        axis(ax, 'off');
        patch('Parent', ax, 'XData', [0 100 100 0], 'YData', [28 28 60 60], ...
            'FaceColor', [0.55 0.78 0.95], 'EdgeColor', 'none');
        patch('Parent', ax, 'XData', [0 100 100 0], 'YData', [0 0 28 28], ...
            'FaceColor', [0.42 0.62 0.42], 'EdgeColor', 'none');
        patch('Parent', ax, 'XData', [16 84 56 44], 'YData', [0 0 28 28], ...
            'FaceColor', [0.24 0.24 0.24], 'EdgeColor', [0.12 0.12 0.12], 'LineWidth', 1);
        plot(ax, [50 50], [2 26], 'Color', [1 0.9 0.2], 'LineWidth', 3, 'LineStyle', '--');
        for k = 1:4
            bx = 5 + (k - 1) * 8;
            patch('Parent', ax, 'XData', [bx bx + 5 bx + 5 bx], 'YData', [28 28 38 + k 38 + k], ...
                'FaceColor', [0.75 0.77 0.74], 'EdgeColor', [0.45 0.45 0.45]);
            bx2 = 92 - (k - 1) * 8;
            patch('Parent', ax, 'XData', [bx2 bx2 + 5 bx2 + 5 bx2], 'YData', [28 28 42 - k 42 - k], ...
                'FaceColor', [0.78 0.73 0.68], 'EdgeColor', [0.45 0.45 0.45]);
        end
        text(50, 55, 'Virtual Street View', 'Parent', ax, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14);
        text(50, 50, sprintf('Road point: X %.1f m, Y %.1f m, heading %.1f deg', ...
            snapped(1), snapped(2), normalizeAngle(theta)), ...
            'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 10);
        app.mode = 'inspect';
        set(app.h.statusText, 'String', 'Mode: inspect');
        addLog(sprintf('Virtual street view generated at (%.1f, %.1f).', snapped(1), snapped(2)));
        redraw();
    end

    function onReportVehicles(~, ~)
        lines = composeVehicleReport();
        set(app.h.reportList, 'String', lines);
        set(app.h.reportList, 'Value', 1);
        addLog('IV real-world positions reported.');
    end

    function lines = composeVehicleReport()
        if isempty(app.vehicles)
            lines = {'No IV loaded.'};
            return;
        end
        lines = cell(1, length(app.vehicles));
        for i = 1:length(app.vehicles)
            v = app.vehicles(i);
            lines{i} = sprintf('IV %d | X %.1f m | Y %.1f m | theta %.1f | scale %.2f', ...
                v.id, v.pos(1), v.pos(2), v.theta, v.scale);
        end
    end

    function redraw()
        cla(app.ax);
        hold(app.ax, 'on');
        set(app.ax, 'YDir', 'normal');

        displayImage = app.mapImage;
        localCenter = [];
        localRadius = readNumber(app.h.localRadiusEdit, 120);
        if app.localMode
            idx = vehicleIndexById(app.localVehicleId);
            if idx > 0
                localCenter = app.vehicles(idx).pos;
                displayImage = buildLocalMaskedImage(app.mapImage, localCenter, localRadius);
            else
                app.localMode = false;
                app.localVehicleId = [];
            end
        end
        if app.showSkeletonBand && size(app.skeletonPoints, 1) >= 2
            displayImage = buildSkeletonMaskedImage(displayImage, app.skeletonPoints, 14);
        end

        drawMapImage(displayImage);

        if get(app.h.showRoad, 'Value') == 1
            drawRoadModel();
        end

        if app.showSkeletonBand
            drawSkeletonRoadBand();
        end

        drawPathResult();
        drawMeasures();
        drawSkeleton();
        drawVehicles();
        daspect(app.ax, [1 1 1]);

        if app.localMode && ~isempty(localCenter)
            drawCircle(localCenter, localRadius, [0.0 0.35 0.75], 1.5);
            c = displayPoint(localCenter);
            xlim(app.ax, [c(1) - localRadius, c(1) + localRadius]);
            ylim(app.ax, [c(2) - localRadius, c(2) + localRadius]);
        else
            setFullMapLimits();
        end

        xlabel(app.ax, 'X coordinate (meters)');
        ylabel(app.ax, 'Y coordinate (meters)');
        title(app.ax, sprintf('Map rotation %.1f deg | 1 pixel = %.1f m', ...
            app.mapRotation, app.scaleM));
        hold(app.ax, 'off');
        drawnow;
    end

    function drawMapImage(img)
        x = [0 app.mapWidthM; 0 app.mapWidthM];
        y = [0 0; app.mapHeightM app.mapHeightM];
        [xr, yr] = rotatePoints(x, y, app.mapCenter, app.mapRotation);
        surface('Parent', app.ax, ...
            'XData', xr, ...
            'YData', yr, ...
            'ZData', zeros(2), ...
            'CData', flipud(img), ...
            'FaceColor', 'texturemap', ...
            'EdgeColor', 'none', ...
            'HitTest', 'on');
    end

    function drawRoadModel()
        gridPts = app.network.grid.nodes(1:3:end, :);
        gridPts = rotatePolyline(gridPts);
        plot(app.ax, gridPts(:, 1), gridPts(:, 2), '.', ...
            'Color', [0.1 0.25 0.9], 'MarkerSize', 2);
        for i = 1:size(app.network.segments, 1)
            s = app.network.segments(i, :);
            p1 = displayPoint([s(1), s(2)]);
            p2 = displayPoint([s(3), s(4)]);
            plot(app.ax, [p1(1) p2(1)], [p1(2) p2(2)], ...
                'Color', [0 0.35 0.95], 'LineStyle', ':', 'LineWidth', 1.2);
        end
    end

    function drawVehicles()
        for i = 1:length(app.vehicles)
            v = app.vehicles(i);
            corners = vehicleCorners(v);
            corners = rotatePolyline(corners);
            patch('Parent', app.ax, ...
                'XData', corners(:, 1), ...
                'YData', corners(:, 2), ...
                'FaceColor', [0.95 0.18 0.12], ...
                'EdgeColor', [0.12 0.12 0.12], ...
                'LineWidth', 1.2);
            nose = vehicleNose(v);
            nose = rotatePolyline(nose);
            plot(app.ax, nose(:, 1), nose(:, 2), 'Color', [1 1 1], 'LineWidth', 1.4);
            labelPos = displayPoint(v.pos + [0, 6 * v.scale]);
            text(labelPos(1), labelPos(2), sprintf('IV %d', v.id), ...
                'Parent', app.ax, ...
                'Color', [0.05 0.05 0.05], ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
        end
    end

    function corners = vehicleCorners(v)
        lengthM = 8 * v.scale;
        widthM = 3 * v.scale;
        local = [ lengthM / 2,  widthM / 2; ...
                  lengthM / 2, -widthM / 2; ...
                 -lengthM / 2, -widthM / 2; ...
                 -lengthM / 2,  widthM / 2];
        corners = rotateLocal(local, v.theta) + v.pos;
    end

    function nose = vehicleNose(v)
        lengthM = 8 * v.scale;
        widthM = 3 * v.scale;
        local = [ lengthM / 2, 0; ...
                  lengthM / 2 - 2 * v.scale, widthM / 2; ...
                  lengthM / 2 - 2 * v.scale, -widthM / 2; ...
                  lengthM / 2, 0];
        nose = rotateLocal(local, v.theta) + v.pos;
    end

    function drawMeasures()
        if ~isempty(app.distancePoints)
            pts = rotatePolyline(app.distancePoints);
            plot(app.ax, pts(:, 1), pts(:, 2), 'yo', 'MarkerFaceColor', 'y', 'MarkerSize', 6);
            if size(pts, 1) == 2
                plot(app.ax, pts(:, 1), pts(:, 2), 'y-', 'LineWidth', 1.8);
            end
        end

        if ~isempty(app.trajectoryPoints)
            pts = rotatePolyline(app.trajectoryPoints);
            plot(app.ax, pts(:, 1), pts(:, 2), 'Color', [1.0 0.55 0.05], ...
                'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', [1.0 0.8 0.2]);
        end

        if ~isempty(app.pathClickPoints)
            pts = rotatePolyline(app.pathClickPoints);
            plot(app.ax, pts(:, 1), pts(:, 2), 'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 7);
        end
    end

    function drawSkeleton()
        if isempty(app.skeletonPoints)
            return;
        end
        pts = rotatePolyline(app.skeletonPoints);
        plot(app.ax, pts(:, 1), pts(:, 2), 'Color', [0.55 0 0.8], ...
            'LineWidth', 2.0, 'Marker', '.', 'MarkerSize', 16);
    end

    function drawSkeletonRoadBand()
        if size(app.skeletonPoints, 1) < 2
            return;
        end
        pts = rotatePolyline(app.skeletonPoints);
        plot(app.ax, pts(:, 1), pts(:, 2), 'Color', [0.90 0.72 1.0], ...
            'LineWidth', 16);
        plot(app.ax, pts(:, 1), pts(:, 2), 'Color', [0.45 0 0.65], ...
            'LineWidth', 2);
    end

    function drawPathResult()
        if isempty(app.pathResult)
            return;
        end
        pts = rotatePolyline(app.pathResult);
        plot(app.ax, pts(:, 1), pts(:, 2), 'Color', [1 0 0], 'LineWidth', 3);
        plot(app.ax, pts(:, 1), pts(:, 2), 'ro', 'MarkerFaceColor', [1 0.8 0.8], 'MarkerSize', 5);
    end

    function drawCircle(center, radius, colorValue, lineW)
        t = linspace(0, 2 * pi, 160);
        pts = [center(1) + radius * cos(t(:)), center(2) + radius * sin(t(:))];
        pts = rotatePolyline(pts);
        plot(app.ax, pts(:, 1), pts(:, 2), 'Color', colorValue, 'LineWidth', lineW);
    end

    function setFullMapLimits()
        corners = [0 0; app.mapWidthM 0; app.mapWidthM app.mapHeightM; 0 app.mapHeightM];
        c = rotatePolyline(corners);
        pad = 25;
        xlim(app.ax, [min(c(:, 1)) - pad, max(c(:, 1)) + pad]);
        ylim(app.ax, [min(c(:, 2)) - pad, max(c(:, 2)) + pad]);
    end

    function img = buildLocalMaskedImage(src, center, radius)
        img = src;
        [hImg, wImg, ~] = size(src);
        xs = ((1:wImg) - 0.5) * app.scaleM;
        keep = false(hImg, wImg);
        r2 = radius * radius;
        for row = 1:hImg
            yReal = (hImg - row + 0.5) * app.scaleM;
            keep(row, :) = (xs - center(1)).^2 + (yReal - center(2)).^2 <= r2;
        end
        for k = 1:3
            plane = img(:, :, k);
            plane(~keep) = 245;
            img(:, :, k) = plane;
        end
    end

    function img = buildSkeletonMaskedImage(src, skeletonPoints, halfWidthM)
        img = src;
        [hImg, wImg, ~] = size(src);
        keep = false(hImg, wImg);
        halfWidthSq = halfWidthM * halfWidthM;
        xs = ((1:wImg) - 0.5) * app.scaleM;
        for sIdx = 1:(size(skeletonPoints, 1) - 1)
            a = skeletonPoints(sIdx, :);
            b = skeletonPoints(sIdx + 1, :);
            minX = min(a(1), b(1)) - halfWidthM;
            maxX = max(a(1), b(1)) + halfWidthM;
            minY = min(a(2), b(2)) - halfWidthM;
            maxY = max(a(2), b(2)) + halfWidthM;
            cols = find(xs >= minX & xs <= maxX);
            if isempty(cols)
                continue;
            end
            ab = b - a;
            den = ab(1) * ab(1) + ab(2) * ab(2);
            for row = 1:hImg
                yReal = (hImg - row + 0.5) * app.scaleM;
                if yReal < minY || yReal > maxY
                    continue;
                end
                px = xs(cols);
                py = yReal * ones(size(px));
                if den == 0
                    qx = a(1) * ones(size(px));
                    qy = a(2) * ones(size(px));
                else
                    t = ((px - a(1)) * ab(1) + (py - a(2)) * ab(2)) / den;
                    t(t < 0) = 0;
                    t(t > 1) = 1;
                    qx = a(1) + t * ab(1);
                    qy = a(2) + t * ab(2);
                end
                distSq = (px - qx).^2 + (py - qy).^2;
                keep(row, cols(distSq <= halfWidthSq)) = true;
            end
        end
        for k = 1:3
            plane = img(:, :, k);
            plane(~keep) = 245;
            img(:, :, k) = plane;
        end
    end

    function pt = inverseDisplayPoint(displayPt)
        pt = rotateOne(displayPt, app.mapCenter, -app.mapRotation);
    end

    function pt = displayPoint(mapPt)
        pt = rotateOne(mapPt, app.mapCenter, app.mapRotation);
    end

    function pts = rotatePolyline(pts)
        if isempty(pts)
            return;
        end
        [x, y] = rotatePoints(pts(:, 1), pts(:, 2), app.mapCenter, app.mapRotation);
        pts = [x, y];
    end

    function inside = pointInsideMap(pt)
        inside = pt(1) >= 0 && pt(1) <= app.mapWidthM && pt(2) >= 0 && pt(2) <= app.mapHeightM;
    end

    function updateVehiclePopup(preferId)
        if isempty(app.vehicles)
            set(app.h.vehiclePopup, 'String', {'No IV'}, 'Value', 1);
            set(app.h.reportList, 'String', {'No IV loaded.'}, 'Value', 1);
            return;
        end

        labels = cell(1, length(app.vehicles));
        value = 1;
        for i = 1:length(app.vehicles)
            labels{i} = sprintf('IV %d', app.vehicles(i).id);
            if ~isempty(preferId) && app.vehicles(i).id == preferId
                value = i;
            end
        end
        set(app.h.vehiclePopup, 'String', labels, 'Value', value);
        refreshVehicleFields();
        set(app.h.reportList, 'String', composeVehicleReport(), 'Value', 1);
    end

    function refreshVehicleFields()
        idx = selectedVehicleIndex();
        if idx == 0
            return;
        end
        set(app.h.scaleEdit, 'String', sprintf('%.2f', app.vehicles(idx).scale));
    end

    function idx = selectedVehicleIndex()
        if isempty(app.vehicles)
            idx = 0;
            return;
        end
        idx = get(app.h.vehiclePopup, 'Value');
        if idx < 1 || idx > length(app.vehicles)
            idx = 1;
        end
    end

    function idx = vehicleIndexById(id)
        idx = 0;
        for i = 1:length(app.vehicles)
            if app.vehicles(i).id == id
                idx = i;
                return;
            end
        end
    end

    function addLog(line)
        stamp = datestr(now, 'HH:MM:SS');
        app.logLines{end + 1} = [stamp '  ' line];
        if length(app.logLines) > 80
            app.logLines = app.logLines(end - 79:end);
        end
        if isfield(app, 'h') && isfield(app.h, 'logList')
            set(app.h.logList, 'String', app.logLines, 'Value', length(app.logLines));
        end
    end
end

function network = buildRoadNetwork(mapWidthPx, mapHeightPx, scaleM)
segPx = RoadModelDataPx();
gridStepPx = 4;

segments = zeros(size(segPx));
for i = 1:size(segPx, 1)
    p1 = pxToMeters(segPx(i, 1), segPx(i, 2), mapHeightPx, scaleM);
    p2 = pxToMeters(segPx(i, 3), segPx(i, 4), mapHeightPx, scaleM);
    segments(i, :) = [p1 p2 segPx(i, 5) * scaleM];
end

nodes = [];
edges = zeros(size(segments, 1), 3);
for i = 1:size(segments, 1)
    [nodes, n1] = appendUniqueNode(nodes, segments(i, 1:2));
    [nodes, n2] = appendUniqueNode(nodes, segments(i, 3:4));
    edges(i, :) = [n1 n2 euclideanDistance(segments(i, 1:2), segments(i, 3:4))];
end

network.nodes = nodes;
network.edges = edges;
network.segments = segments;
network.grid = buildRoadGrid(segPx, mapWidthPx, mapHeightPx, scaleM, gridStepPx);
end

function grid = buildRoadGrid(segPx, mapWidthPx, mapHeightPx, scaleM, stepPx)
xs = 0:stepPx:mapWidthPx;
if xs(end) ~= mapWidthPx
    xs = [xs mapWidthPx];
end
ys = 0:stepPx:mapHeightPx;
if ys(end) ~= mapHeightPx
    ys = [ys mapHeightPx];
end
indexMap = zeros(length(ys), length(xs));
tolerancePx = stepPx * 0.65;
validMap = false(length(ys), length(xs));
for sIdx = 1:size(segPx, 1)
    a = segPx(sIdx, 1:2);
    b = segPx(sIdx, 3:4);
    halfWidth = segPx(sIdx, 5) / 2 + tolerancePx;
    minX = max(0, min(a(1), b(1)) - halfWidth);
    maxX = min(mapWidthPx, max(a(1), b(1)) + halfWidth);
    minY = max(0, min(a(2), b(2)) - halfWidth);
    maxY = min(mapHeightPx, max(a(2), b(2)) + halfWidth);
    cols = find(xs >= minX & xs <= maxX);
    rows = find(ys >= minY & ys <= maxY);
    if isempty(cols) || isempty(rows)
        continue;
    end
    ab = b - a;
    den = ab(1) * ab(1) + ab(2) * ab(2);
    for rIdx = 1:length(rows)
        row = rows(rIdx);
        px = xs(cols);
        py = ys(row) * ones(size(px));
        if den == 0
            qx = a(1) * ones(size(px));
            qy = a(2) * ones(size(px));
        else
            t = ((px - a(1)) * ab(1) + (py - a(2)) * ab(2)) / den;
            t(t < 0) = 0;
            t(t > 1) = 1;
            qx = a(1) + t * ab(1);
            qy = a(2) + t * ab(2);
        end
        distSq = (px - qx).^2 + (py - qy).^2;
        validMap(row, cols(distSq <= halfWidth * halfWidth)) = true;
    end
end

nodesPx = [];
nodeRows = [];
nodeCols = [];
for row = 1:length(ys)
    for col = 1:length(xs)
        if validMap(row, col)
            nodesPx(end + 1, :) = [xs(col) ys(row)];
            nodeRows(end + 1) = row;
            nodeCols(end + 1) = col;
            indexMap(row, col) = size(nodesPx, 1);
        end
    end
end

nodesM = zeros(size(nodesPx));
for i = 1:size(nodesPx, 1)
    nodesM(i, :) = pxToMeters(nodesPx(i, 1), nodesPx(i, 2), mapHeightPx, scaleM);
end

grid.nodes = nodesM;
grid.indexMap = indexMap;
grid.nodeRows = nodeRows;
grid.nodeCols = nodeCols;
grid.xs = xs;
grid.ys = ys;
grid.stepPx = stepPx;
end

function valid = isRoadPointPx(pt, segPx, tolerancePx)
valid = false;
for i = 1:size(segPx, 1)
    [~, d] = projectPointToSegmentPx(pt, segPx(i, 1:2), segPx(i, 3:4));
    if d <= segPx(i, 5) / 2 + tolerancePx
        valid = true;
        return;
    end
end
end

function [q, d] = projectPointToSegmentPx(p, a, b)
ab = b - a;
den = ab(1) * ab(1) + ab(2) * ab(2);
if den == 0
    q = a;
else
    t = ((p(1) - a(1)) * ab(1) + (p(2) - a(2)) * ab(2)) / den;
    if t < 0
        t = 0;
    elseif t > 1
        t = 1;
    end
    q = a + t * ab;
end
d = euclideanDistance(p, q);
end

function [nodes, idx] = appendUniqueNode(nodes, pt)
idx = 0;
for j = 1:size(nodes, 1)
    if euclideanDistance(nodes(j, :), pt) < 0.01
        idx = j;
        return;
    end
end
nodes(end + 1, :) = pt;
idx = size(nodes, 1);
end

function pt = pxToMeters(xPx, yTopPx, mapHeightPx, scaleM)
pt = [xPx * scaleM, (mapHeightPx - yTopPx) * scaleM];
end

function [valid, snapped, segIdx, minDist] = nearestRoad(network, pt)
minDist = inf;
snapped = [NaN NaN];
segIdx = 0;
valid = false;
for i = 1:size(network.segments, 1)
    s = network.segments(i, :);
    [q, d] = projectPointToSegment(pt, s(1:2), s(3:4));
    if d < minDist
        minDist = d;
        snapped = q;
        segIdx = i;
    end
end
if segIdx > 0
    valid = minDist <= network.segments(segIdx, 5) / 2;
end
end

function [q, d] = projectPointToSegment(p, a, b)
ab = b - a;
den = ab(1) * ab(1) + ab(2) * ab(2);
if den == 0
    q = a;
else
    t = ((p(1) - a(1)) * ab(1) + (p(2) - a(2)) * ab(2)) / den;
    if t < 0
        t = 0;
    elseif t > 1
        t = 1;
    end
    q = a + t * ab;
end
d = euclideanDistance(p, q);
end

function [route, totalLength, ok, snappedStart, snappedEnd] = planShortestPath(network, startPt, endPt)
route = [];
totalLength = inf;
ok = false;
[~, snappedStart, startSegIdx, ~] = nearestRoad(network, startPt);
[~, snappedEnd, endSegIdx, ~] = nearestRoad(network, endPt);
if startSegIdx == 0 || endSegIdx == 0
    return;
end

startNode = nearestGridNode(network, snappedStart);
endNode = nearestGridNode(network, snappedEnd);
if startNode == 0 || endNode == 0
    return;
end
[idxPath, gridLength, gridOk] = astarRoadGrid(network, startNode, endNode);
if ~gridOk
    return;
end
gridRoute = network.grid.nodes(idxPath, :);
route = [snappedStart; gridRoute; snappedEnd];
totalLength = gridLength + euclideanDistance(snappedStart, gridRoute(1, :)) + euclideanDistance(snappedEnd, gridRoute(end, :));
ok = true;
end

function idx = nearestGridNode(network, pt)
idx = 0;
best = inf;
for i = 1:size(network.grid.nodes, 1)
    d = euclideanDistance(network.grid.nodes(i, :), pt);
    if d < best
        best = d;
        idx = i;
    end
end
end

function [idxPath, totalLength, ok] = astarRoadGrid(network, startNode, endNode)
n = size(network.grid.nodes, 1);
gScore = inf(1, n);
fScore = inf(1, n);
prev = zeros(1, n);
closedSet = false(1, n);
gScore(startNode) = 0;
fScore(startNode) = euclideanDistance(network.grid.nodes(startNode, :), network.grid.nodes(endNode, :));
openNodes = startNode;
openScores = fScore(startNode);
ok = false;
totalLength = inf;
idxPath = [];
dirs = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
while ~isempty(openNodes)
    [~, pos] = min(openScores);
    u = openNodes(pos);
    openNodes(pos) = [];
    openScores(pos) = [];
    if closedSet(u)
        continue;
    end
    if u == endNode
        idxPath = endNode;
        current = endNode;
        while current ~= startNode
            current = prev(current);
            if current == 0
                idxPath = [];
                return;
            end
            idxPath = [current idxPath];
        end
        totalLength = gScore(endNode);
        ok = true;
        return;
    end
    closedSet(u) = true;
    row = network.grid.nodeRows(u);
    col = network.grid.nodeCols(u);
    for k = 1:size(dirs, 1)
        rr = row + dirs(k, 1);
        cc = col + dirs(k, 2);
        if rr < 1 || rr > length(network.grid.ys) || cc < 1 || cc > length(network.grid.xs)
            continue;
        end
        v = network.grid.indexMap(rr, cc);
        if v == 0
            continue;
        end
        if closedSet(v)
            continue;
        end
        tentative = gScore(u) + euclideanDistance(network.grid.nodes(u, :), network.grid.nodes(v, :));
        if tentative >= gScore(v)
            continue;
        end
        prev(v) = u;
        gScore(v) = tentative;
        fScore(v) = tentative + euclideanDistance(network.grid.nodes(v, :), network.grid.nodes(endNode, :));
        openNodes(end + 1) = v;
        openScores(end + 1) = fScore(v);
    end
end
end

function theta = segmentAngle(segment)
theta = atan2(segment(4) - segment(2), segment(3) - segment(1)) * 180 / pi;
theta = normalizeAngle(theta);
end

function out = rotateLocal(points, thetaDeg)
theta = thetaDeg * pi / 180;
c = cos(theta);
s = sin(theta);
out = [points(:, 1) * c - points(:, 2) * s, ...
       points(:, 1) * s + points(:, 2) * c];
end

function [xr, yr] = rotatePoints(x, y, center, thetaDeg)
theta = thetaDeg * pi / 180;
c = cos(theta);
s = sin(theta);
dx = x - center(1);
dy = y - center(2);
xr = center(1) + dx * c - dy * s;
yr = center(2) + dx * s + dy * c;
end

function pt = rotateOne(pt, center, thetaDeg)
[x, y] = rotatePoints(pt(1), pt(2), center, thetaDeg);
pt = [x, y];
end

function d = euclideanDistance(a, b)
dx = a(1) - b(1);
dy = a(2) - b(2);
d = sqrt(dx * dx + dy * dy);
end

function total = polylineLength(points)
total = 0;
for i = 2:size(points, 1)
    total = total + euclideanDistance(points(i - 1, :), points(i, :));
end
end

function value = readNumber(h, fallback)
value = str2double(get(h, 'String'));
if isnan(value)
    value = fallback;
    set(h, 'String', num2str(fallback));
end
end

function angle = normalizeAngle(angle)
while angle < 0
    angle = angle + 360;
end
while angle >= 360
    angle = angle - 360;
end
end
