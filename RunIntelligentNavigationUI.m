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
app.streetViewFig = [];
app.streetViewAx = [];

createUi();
addLog('界面已启动。请通过地图点击和右侧控件进行操作。');
redraw();

    function createUi()
        app.fig = figure( ...
            'Name', 'ISE 333 智能导航界面', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Color', [0.88 0.93 0.96], ...
            'Position', [40 30 1360 820], ...
            'WindowButtonDownFcn', @onFigureClick);

        app.header = uipanel('Parent', app.fig, ...
            'Units', 'pixels', ...
            'Position', [0 755 1360 65], ...
            'BorderType', 'none', ...
            'BackgroundColor', [0.02 0.34 0.62]);

        uicontrol(app.header, 'Style', 'text', ...
            'Position', [24 14 300 38], ...
            'String', 'ISE 333 校园智能导航', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.02 0.34 0.62], ...
            'ForegroundColor', [1 1 1], ...
            'FontWeight', 'bold', ...
            'FontSize', 15);

        uicontrol(app.header, 'Style', 'text', ...
            'Position', [340 18 420 30], ...
            'String', '地图 | 智能车 | 道路模型 | 路径 | 虚拟街景', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.02 0.34 0.62], ...
            'ForegroundColor', [0.86 0.94 1], ...
            'FontWeight', 'bold');

        uicontrol(app.header, 'Style', 'text', ...
            'Position', [1075 18 250 30], ...
            'String', '智能导航课程项目  ISE333', ...
            'HorizontalAlignment', 'right', ...
            'BackgroundColor', [0.02 0.34 0.62], ...
            'ForegroundColor', [0.86 0.94 1]);

        app.ax = axes('Parent', app.fig, ...
            'Units', 'pixels', ...
            'Position', [25 55 965 675], ...
            'Box', 'on', ...
            'XColor', [0.2 0.2 0.2], ...
            'YColor', [0.2 0.2 0.2], ...
            'Color', [1 1 1]);

        app.panel = uipanel('Parent', app.fig, ...
            'Units', 'pixels', ...
            'Position', [1010 20 330 720], ...
            'Title', '导航控制', ...
            'BackgroundColor', [0.97 0.99 1.00], ...
            'ForegroundColor', [0.02 0.34 0.62], ...
            'FontWeight', 'bold');

        x = 15;
        w = 300;
        y = 665;
        h = 26;
        gap = 8;

        app.h.coordText = uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y w 36], ...
            'String', '当前位置：--', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.97 0.99 1.00], ...
            'ForegroundColor', [0.02 0.22 0.35], ...
            'FontWeight', 'bold');
        y = y - 39;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 90 h], ...
            'String', '加载地图', ...
            'Callback', @onLoadMap);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 100 y 90 h], ...
            'String', '查看', ...
            'Callback', @(~, ~) setMode('inspect'));
        app.h.showRoad = uicontrol(app.panel, 'Style', 'checkbox', ...
            'Position', [x + 200 y 90 h], ...
            'String', '道路模型', ...
            'Value', 0, ...
            'BackgroundColor', [0.97 0.99 1.00], ...
            'Callback', @(~, ~) redraw());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', '车辆角度', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.97 0.99 1.00]);
        app.h.angleEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '0', ...
            'BackgroundColor', [1 1 1]);
        app.h.autoAlign = uicontrol(app.panel, 'Style', 'checkbox', ...
            'Position', [x + 143 y 122 h], ...
            'String', '自动贴合道路', ...
            'Value', 1, ...
            'BackgroundColor', [0.97 0.99 1.00]);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', '点击添加车辆', ...
            'Callback', @(~, ~) setMode('addIV'));
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '删除车辆', ...
            'Callback', @onRemoveVehicle);
        y = y - h - gap;

        app.h.vehiclePopup = uicontrol(app.panel, 'Style', 'popupmenu', ...
            'Position', [x y 140 h], ...
            'String', {'无车辆'}, ...
            'BackgroundColor', [1 1 1], ...
            'Callback', @(~, ~) refreshVehicleFields());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '车辆位置', ...
            'Callback', @onReportVehicles);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', '车辆缩放', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.97 0.99 1.00]);
        app.h.scaleEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '1.0', ...
            'BackgroundColor', [1 1 1]);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 143 y 122 h], ...
            'String', '应用缩放', ...
            'Callback', @onApplyScale);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', '局部半径(m)', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.97 0.99 1.00]);
        app.h.localRadiusEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '120', ...
            'BackgroundColor', [1 1 1]);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 143 y 58 h], ...
            'String', '局部', ...
            'Callback', @onLocalView);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 207 y 58 h], ...
            'String', '全图', ...
            'Callback', @onFullView);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', '两点距离', ...
            'Callback', @(~, ~) startDistance());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '开始轨迹', ...
            'Callback', @(~, ~) startTrajectory());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', '结束轨迹', ...
            'Callback', @(~, ~) finishTrajectory());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '清除测量', ...
            'Callback', @(~, ~) clearMeasures());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y + 2 75 h], ...
            'String', '旋转角度', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.97 0.99 1.00]);
        app.h.rotationEdit = uicontrol(app.panel, 'Style', 'edit', ...
            'Position', [x + 78 y 55 h], ...
            'String', '0', ...
            'BackgroundColor', [1 1 1]);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 143 y 58 h], ...
            'String', '应用', ...
            'Callback', @onApplyRotation);
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 207 y 58 h], ...
            'String', '车头向上', ...
            'Callback', @onRotateIvUp);
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', '提取骨架', ...
            'Callback', @(~, ~) startSkeleton());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '清除骨架', ...
            'Callback', @(~, ~) clearSkeleton());
        y = y - h - gap;

        app.h.skeletonBand = uicontrol(app.panel, 'Style', 'checkbox', ...
            'Position', [x y 140 h], ...
            'String', '骨架道路', ...
            'Value', 0, ...
            'BackgroundColor', [0.97 0.99 1.00], ...
            'Callback', @(~, ~) onSkeletonBand());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '路径规划', ...
            'Callback', @(~, ~) startPathPlan());
        y = y - h - gap;

        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x y 140 h], ...
            'String', '虚拟街景', ...
            'Callback', @(~, ~) startStreetView());
        uicontrol(app.panel, 'Style', 'pushbutton', ...
            'Position', [x + 150 y 140 h], ...
            'String', '重置视图', ...
            'Callback', @onResetView);
        y = y - h - gap;

        app.h.statusText = uicontrol(app.panel, 'Style', 'text', ...
            'Position', [x y - 2 w 34], ...
            'String', '模式：查看', ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.97 0.99 1.00], ...
            'ForegroundColor', [0.02 0.22 0.35], ...
            'FontWeight', 'bold');
        y = y - 118;

        app.h.reportList = uicontrol(app.panel, 'Style', 'listbox', ...
            'Position', [x y w 108], ...
            'String', {'车辆信息显示在这里'}, ...
            'BackgroundColor', [1 1 1]);
        y = y - 150;

        app.h.logList = uicontrol(app.panel, 'Style', 'listbox', ...
            'Position', [x 15 w 140], ...
            'String', {'日志'});
        applyUiTextStyle();
    end

    function applyUiTextStyle()
        panelControls = findall(app.panel, 'Type', 'uicontrol');
        for k = 1:length(panelControls)
            hControl = panelControls(k);
            style = get(hControl, 'Style');
            set(hControl, 'ForegroundColor', [0.02 0.08 0.12]);
            if strcmp(style, 'pushbutton')
                set(hControl, ...
                    'BackgroundColor', [0.88 0.91 0.94], ...
                    'ForegroundColor', [0.01 0.05 0.08], ...
                    'FontWeight', 'bold');
            elseif strcmp(style, 'edit') || strcmp(style, 'popupmenu') || strcmp(style, 'listbox')
                set(hControl, ...
                    'BackgroundColor', [1 1 1], ...
                    'ForegroundColor', [0 0 0]);
            else
                set(hControl, 'BackgroundColor', [0.97 0.99 1.00]);
            end
        end
    end

    function onLoadMap(~, ~)
        app.mapImage = imread(app.mapFile);
        addLog('已从 MapForUI.jpg 加载地图。');
        redraw();
    end

    function setMode(newMode)
        app.mode = newMode;
        if strcmp(newMode, 'inspect')
            app.distancePoints = [];
            app.pathClickPoints = [];
        end
        set(app.h.statusText, 'String', ['模式：' modeLabel()]);
        addLog(['模式已切换为：' modeLabel() '。']);
    end

    function label = modeLabel()
        label = app.mode;
        if strcmp(app.mode, 'addIV')
            label = '添加车辆';
        elseif strcmp(app.mode, 'distance')
            label = '两点距离';
        elseif strcmp(app.mode, 'trajectory')
            label = '轨迹测量';
        elseif strcmp(app.mode, 'skeleton')
            label = '道路骨架';
        elseif strcmp(app.mode, 'path')
            label = '路径规划';
        elseif strcmp(app.mode, 'street')
            label = '虚拟街景';
        elseif strcmp(app.mode, 'inspect')
            label = '查看';
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
            s = sprintf('当前位置：X %.1f m，Y %.1f m', pt(1), pt(2));
        else
            s = sprintf('当前位置：地图外 (%.1f, %.1f)', pt(1), pt(2));
        end
        set(app.h.coordText, 'String', s);
    end

    function addVehicleAt(pt)
        [valid, snapped, segIdx, distM] = nearestRoad(app.network, pt);
        if ~valid
            addLog(sprintf('车辆位置无效，距离最近道路 %.1f m。', distM));
            errordlg('所选点不在可通行道路上。', '无效车辆位置');
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
        addLog(sprintf('车辆 %d 已加载到 (%.1f, %.1f)，方向角 %.1f 度。', ...
            v.id, v.pos(1), v.pos(2), v.theta));
        setMode('inspect');
        redraw();
    end

    function onRemoveVehicle(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('未选择要删除的车辆。');
            return;
        end
        removedId = app.vehicles(idx).id;
        app.vehicles(idx) = [];
        if isequal(app.localVehicleId, removedId)
            app.localMode = false;
            app.localVehicleId = [];
        end
        updateVehiclePopup([]);
        addLog(sprintf('车辆 %d 已删除。', removedId));
        redraw();
    end

    function onApplyScale(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('未选择要缩放的车辆。');
            return;
        end
        scaleValue = readNumber(app.h.scaleEdit, app.vehicles(idx).scale);
        if scaleValue <= 0
            addLog('缩放比例必须为正数。');
            return;
        end
        app.vehicles(idx).scale = scaleValue;
        addLog(sprintf('车辆 %d 显示缩放已设为 %.2f。', ...
            app.vehicles(idx).id, scaleValue));
        redraw();
    end

    function onLocalView(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('未选择用于局部视图的车辆。');
            return;
        end
        radius = readNumber(app.h.localRadiusEdit, 120);
        if radius <= 0
            addLog('局部半径必须为正数。');
            return;
        end
        app.localMode = true;
        app.localVehicleId = app.vehicles(idx).id;
        addLog(sprintf('局部圆形地图以车辆 %d 为中心，半径 %.1f m。', ...
            app.localVehicleId, radius));
        redraw();
    end

    function onFullView(~, ~)
        app.localMode = false;
        app.localVehicleId = [];
        addLog('已恢复全图视图。');
        redraw();
    end

    function startDistance()
        app.distancePoints = [];
        app.mode = 'distance';
        set(app.h.statusText, 'String', '模式：两点距离');
        addLog('请在地图上点击两个点以测量实际距离。');
        redraw();
    end

    function addDistancePoint(pt)
        app.distancePoints(end + 1, :) = pt;
        if size(app.distancePoints, 1) == 1
            addLog(sprintf('距离测量点 A：(%.1f, %.1f)。', pt(1), pt(2)));
        else
            a = app.distancePoints(1, :);
            b = app.distancePoints(2, :);
            d = euclideanDistance(a, b);
            addLog(sprintf('A-B 距离 = %.1f m。', d));
            app.mode = 'inspect';
            set(app.h.statusText, 'String', '模式：查看');
        end
        redraw();
    end

    function startTrajectory()
        app.trajectoryPoints = [];
        app.mode = 'trajectory';
        set(app.h.statusText, 'String', '模式：轨迹测量');
        addLog('轨迹测量已开始。请按顺序点击点位，然后点击“结束轨迹”。');
        redraw();
    end

    function addTrajectoryPoint(pt)
        app.trajectoryPoints(end + 1, :) = pt;
        addLog(sprintf('轨迹点 %d：(%.1f, %.1f)。', ...
            size(app.trajectoryPoints, 1), pt(1), pt(2)));
        redraw();
    end

    function finishTrajectory()
        if size(app.trajectoryPoints, 1) < 2
            addLog('轨迹至少需要两个点击点。');
        else
            total = polylineLength(app.trajectoryPoints);
            addLog(sprintf('轨迹长度 = %.1f m，共 %d 个点。', ...
                total, size(app.trajectoryPoints, 1)));
        end
        app.mode = 'inspect';
        set(app.h.statusText, 'String', '模式：查看');
        redraw();
    end

    function clearMeasures()
        app.distancePoints = [];
        app.trajectoryPoints = [];
        app.pathClickPoints = [];
        app.pathResult = [];
        addLog('已清除距离、轨迹和路径绘制。');
        redraw();
    end

    function onApplyRotation(~, ~)
        deg = readNumber(app.h.rotationEdit, 0);
        app.mapRotation = normalizeAngle(deg);
        set(app.h.rotationEdit, 'String', sprintf('%.1f', app.mapRotation));
        addLog(sprintf('地图旋转角度已设为 %.1f 度。', app.mapRotation));
        redraw();
    end

    function onRotateIvUp(~, ~)
        idx = selectedVehicleIndex();
        if idx == 0
            addLog('使用“车头向上”前请先选择车辆。');
            return;
        end
        app.mapRotation = normalizeAngle(90 - app.vehicles(idx).theta);
        set(app.h.rotationEdit, 'String', sprintf('%.1f', app.mapRotation));
        addLog(sprintf('地图已旋转，使车辆 %d 的车头朝上。', app.vehicles(idx).id));
        if get(app.h.autoAlign, 'Value') == 1
            addLog('提示：自动道路对齐已开启；车头向上只旋转视图，不改变后续车辆的自动朝向。');
        else
            addLog('提示：自动道路对齐已关闭；车头向上只旋转视图，不改变车辆自身朝向。');
        end
        redraw();
    end

    function onResetView(~, ~)
        app.mapRotation = 0;
        app.localMode = false;
        app.localVehicleId = [];
        set(app.h.rotationEdit, 'String', '0');
        addLog('已重置旋转和局部视图。');
        redraw();
    end

    function startSkeleton()
        app.mode = 'skeleton';
        set(app.h.statusText, 'String', '模式：道路骨架');
        addLog('请点击有效道路点以手动提取道路骨架。');
        redraw();
    end

    function addSkeletonPoint(pt)
        [valid, snapped, ~, distM] = nearestRoad(app.network, pt);
        if ~valid
            addLog(sprintf('骨架点被拒绝，距离最近道路 %.1f m。', distM));
            return;
        end
        app.skeletonPoints(end + 1, :) = snapped;
        addLog(sprintf('骨架点 %d 已添加到 (%.1f, %.1f)。', ...
            size(app.skeletonPoints, 1), snapped(1), snapped(2)));
        redraw();
    end

    function clearSkeleton()
        app.skeletonPoints = [];
        app.showSkeletonBand = false;
        set(app.h.skeletonBand, 'Value', 0);
        addLog('已清除手动道路骨架。');
        redraw();
    end

    function onSkeletonBand()
        app.showSkeletonBand = get(app.h.skeletonBand, 'Value') == 1;
        if app.showSkeletonBand && size(app.skeletonPoints, 1) < 2
            app.showSkeletonBand = false;
            set(app.h.skeletonBand, 'Value', 0);
            addLog('骨架道路显示至少需要 2 个骨架点。');
            redraw();
            return;
        end
        redraw();
    end

    function startPathPlan()
        app.pathClickPoints = [];
        app.pathResult = [];
        app.mode = 'path';
        set(app.h.statusText, 'String', '模式：路径规划');
        addLog('请点击起点和终点，系统会自动吸附到最近道路。');
        redraw();
    end

    function addPathPoint(pt)
        app.pathClickPoints(end + 1, :) = pt;
        if size(app.pathClickPoints, 1) == 1
            addLog(sprintf('路径起点已选择：(%.1f, %.1f)。', pt(1), pt(2)));
        else
            startPt = app.pathClickPoints(1, :);
            endPt = app.pathClickPoints(2, :);
            [route, len, ok, snappedStart, snappedEnd] = planShortestPath(app.network, startPt, endPt);
            if ok
                app.pathResult = route;
                addLog(sprintf('最短道路路径 = %.1f m。起点吸附 (%.1f, %.1f)，终点吸附 (%.1f, %.1f)。', ...
                    len, snappedStart(1), snappedStart(2), snappedEnd(1), snappedEnd(2)));
            else
                app.pathResult = [];
                addLog('路径规划失败：所选点距离道路模型过远。');
            end
            app.mode = 'inspect';
            set(app.h.statusText, 'String', '模式：查看');
        end
        redraw();
    end

    function startStreetView()
        app.mode = 'street';
        set(app.h.statusText, 'String', '模式：虚拟街景');
        addLog('请点击道路点以生成虚拟街景。');
    end

    function createStreetView(pt)
        [valid, snapped, segIdx, distM] = nearestRoad(app.network, pt);
        if ~valid
            addLog(sprintf('街景点被拒绝，距离最近道路 %.1f m。', distM));
            return;
        end
        theta = segmentAngle(app.network.segments(segIdx, :));
        roadWidth = min(max(app.network.segments(segIdx, 5), 10), 24);
        heading = normalizeAngle(theta);
        if ~isempty(app.streetViewFig) && ishandle(app.streetViewFig)
            f = app.streetViewFig;
            figure(f);
            clf(f);
            set(f, 'Name', '虚拟街景', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Color', [0.90 0.94 0.97], ...
                'CloseRequestFcn', @onStreetViewClose);
        else
            f = figure('Name', '虚拟街景', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Color', [0.90 0.94 0.97], ...
                'Position', [180 120 760 460], ...
                'CloseRequestFcn', @onStreetViewClose);
            app.streetViewFig = f;
        end
        ax = axes('Parent', f, 'Units', 'normalized', 'Position', [0.06 0.08 0.88 0.84]);
        app.streetViewAx = ax;
        hold(ax, 'on');
        axis(ax, [0 100 0 64]);
        axis(ax, 'off');

        horizonY = 37;
        patch('Parent', ax, 'XData', [0 100 100 0], 'YData', [horizonY horizonY 64 64], ...
            'FaceColor', [0.50 0.74 0.93], 'EdgeColor', 'none');
        patch('Parent', ax, 'XData', [0 100 100 0], 'YData', [0 0 horizonY horizonY], ...
            'FaceColor', [0.36 0.60 0.39], 'EdgeColor', 'none');
        plot(ax, [0 100], [horizonY horizonY], 'Color', [0.82 0.90 0.96], 'LineWidth', 1.2);

        [leftNearX, leftNearY] = projectStreetPoint(-roadWidth / 2, 0);
        [rightNearX, rightNearY] = projectStreetPoint(roadWidth / 2, 0);
        [leftFarX, leftFarY] = projectStreetPoint(-roadWidth / 2, 180);
        [rightFarX, rightFarY] = projectStreetPoint(roadWidth / 2, 180);
        patch('Parent', ax, ...
            'XData', [leftNearX rightNearX rightFarX leftFarX], ...
            'YData', [leftNearY rightNearY rightFarY leftFarY], ...
            'FaceColor', [0.23 0.25 0.27], ...
            'EdgeColor', [0.12 0.13 0.14], ...
            'LineWidth', 1.2);
        plotPerspectiveLine(-roadWidth / 2, 0, -roadWidth / 2, 180, [0.92 0.92 0.86], 1.4, '-');
        plotPerspectiveLine(roadWidth / 2, 0, roadWidth / 2, 180, [0.92 0.92 0.86], 1.4, '-');
        for z = 8:28:145
            plotPerspectiveLine(0, z, 0, z + 14, [1.00 0.90 0.18], 2.4, '-');
        end

        for k = 1:7
            z = 24 + (k - 1) * 22;
            side = -1;
            drawStreetObject(side * (roadWidth / 2 + 10), z, [0.72 0.76 0.70], [0.35 0.39 0.35]);
            side = 1;
            drawStreetObject(side * (roadWidth / 2 + 12), z + 9, [0.78 0.72 0.64], [0.42 0.36 0.30]);
            drawTree(-side * (roadWidth / 2 + 20), z + 4);
        end

        drawCompassInset(heading);
        text(50, 60, '虚拟街景', 'Parent', ax, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14, ...
            'Color', [0.04 0.20 0.32]);
        text(50, 56, sprintf('X %.1f m，Y %.1f m | 航向 %.1f 度 | 道路宽度 %.1f m', ...
            snapped(1), snapped(2), heading, roadWidth), ...
            'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 9, ...
            'Color', [0.04 0.20 0.32]);
        app.mode = 'inspect';
        set(app.h.statusText, 'String', '模式：查看');
        addLog(sprintf('已在 (%.1f, %.1f) 生成虚拟街景。', snapped(1), snapped(2)));
        redraw();

        function [sx, sy] = projectStreetPoint(lateral, forward)
            near = 26;
            lateralScale = 66;
            groundBottom = 4;
            sx = 50 + lateral * lateralScale / (forward + near);
            sy = horizonY - (horizonY - groundBottom) * near / (forward + near);
        end

        function plotPerspectiveLine(lat1, z1, lat2, z2, color, width, style)
            [x1, y1] = projectStreetPoint(lat1, z1);
            [x2, y2] = projectStreetPoint(lat2, z2);
            plot(ax, [x1 x2], [y1 y2], 'Color', color, 'LineWidth', width, 'LineStyle', style);
        end

        function drawStreetObject(lateral, forward, faceColor, edgeColor)
            [x, y] = projectStreetPoint(lateral, forward);
            scale = 85 / (forward + 34);
            halfW = 3.2 * scale;
            height = 11 * scale;
            patch('Parent', ax, ...
                'XData', [x - halfW x + halfW x + halfW * 0.72 x - halfW * 0.72], ...
                'YData', [y y y + height y + height], ...
                'FaceColor', faceColor, ...
                'EdgeColor', edgeColor, ...
                'LineWidth', 0.8);
        end

        function drawTree(lateral, forward)
            [x, y] = projectStreetPoint(lateral, forward);
            scale = 82 / (forward + 35);
            trunkH = 3.6 * scale;
            crown = 3.2 * scale;
            plot(ax, [x x], [y y + trunkH], 'Color', [0.34 0.22 0.12], 'LineWidth', max(0.5, scale));
            rectangle('Parent', ax, 'Position', [x - crown, y + trunkH, crown * 2, crown * 1.5], ...
                'Curvature', [1 1], 'FaceColor', [0.13 0.45 0.23], 'EdgeColor', [0.08 0.32 0.16]);
        end

        function drawCompassInset(angleDeg)
            cx = 90;
            cy = 54;
            r = 5.0;
            rectangle('Parent', ax, 'Position', [cx - r, cy - r, 2 * r, 2 * r], ...
                'Curvature', [1 1], 'FaceColor', [1 1 1], 'EdgeColor', [0.12 0.30 0.44], 'LineWidth', 1.0);
            a = angleDeg * pi / 180;
            plot(ax, [cx cx + cos(a) * 3.4], [cy cy + sin(a) * 3.4], ...
                'Color', [0.85 0.10 0.08], 'LineWidth', 1.8);
            text(cx, cy - 7.2, '航向', 'Parent', ax, 'HorizontalAlignment', 'center', ...
                'FontSize', 7, 'Color', [0.04 0.20 0.32]);
        end
    end

    function onStreetViewClose(src, ~)
        if ishandle(src)
            delete(src);
        end
        app.streetViewFig = [];
        app.streetViewAx = [];
        addLog('虚拟街景窗口已关闭。');
    end

    function onReportVehicles(~, ~)
        lines = composeVehicleReport();
        set(app.h.reportList, 'String', lines);
        set(app.h.reportList, 'Value', 1);
        addLog('已输出车辆实际坐标。');
    end

    function lines = composeVehicleReport()
        if isempty(app.vehicles)
            lines = {'当前无车辆。'};
            return;
        end
        lines = cell(1, length(app.vehicles));
        for i = 1:length(app.vehicles)
            v = app.vehicles(i);
            lines{i} = sprintf('车辆 %d | X %.1f m | Y %.1f m | 方向角 %.1f | 缩放 %.2f', ...
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

        xlabel(app.ax, 'X 坐标（米）');
        ylabel(app.ax, 'Y 坐标（米）');
        title(app.ax, sprintf('地图旋转 %.1f 度 | 1 像素 = %.1f 米', ...
            app.mapRotation, app.scaleM), ...
            'Color', [0.05 0.12 0.16], ...
            'FontWeight', 'bold');
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
            text(labelPos(1), labelPos(2), sprintf('车 %d', v.id), ...
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
            set(app.h.vehiclePopup, 'String', {'无车辆'}, 'Value', 1);
            set(app.h.reportList, 'String', {'当前无车辆。'}, 'Value', 1);
            return;
        end

        labels = cell(1, length(app.vehicles));
        value = 1;
        for i = 1:length(app.vehicles)
            labels{i} = sprintf('车辆 %d', app.vehicles(i).id);
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
gridStepPx = 3;

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
    if euclideanDistance(nodes(j, :), pt) <= 0.5
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
[openNodes, openScores] = pushMinHeap([], [], startNode, fScore(startNode));
ok = false;
totalLength = inf;
idxPath = [];
dirs = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
while ~isempty(openNodes)
    [openNodes, openScores, u, currentScore] = popMinHeap(openNodes, openScores);
    if closedSet(u)
        continue;
    end
    if currentScore > fScore(u) + 1e-9
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
        [openNodes, openScores] = pushMinHeap(openNodes, openScores, v, fScore(v));
    end
end
end

function [nodes, scores] = pushMinHeap(nodes, scores, node, score)
nodes(end + 1) = node;
scores(end + 1) = score;
idx = length(nodes);
while idx > 1
    parent = floor(idx / 2);
    if scores(parent) <= scores(idx)
        break;
    end
    tmpNode = nodes(parent);
    tmpScore = scores(parent);
    nodes(parent) = nodes(idx);
    scores(parent) = scores(idx);
    nodes(idx) = tmpNode;
    scores(idx) = tmpScore;
    idx = parent;
end
end

function [nodes, scores, node, score] = popMinHeap(nodes, scores)
node = nodes(1);
score = scores(1);
lastNode = nodes(end);
lastScore = scores(end);
nodes(end) = [];
scores(end) = [];
if isempty(nodes)
    return;
end
nodes(1) = lastNode;
scores(1) = lastScore;
idx = 1;
count = length(nodes);
while true
    left = idx * 2;
    right = left + 1;
    smallest = idx;
    if left <= count && scores(left) < scores(smallest)
        smallest = left;
    end
    if right <= count && scores(right) < scores(smallest)
        smallest = right;
    end
    if smallest == idx
        break;
    end
    tmpNode = nodes(idx);
    tmpScore = scores(idx);
    nodes(idx) = nodes(smallest);
    scores(idx) = scores(smallest);
    nodes(smallest) = tmpNode;
    scores(smallest) = tmpScore;
    idx = smallest;
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
