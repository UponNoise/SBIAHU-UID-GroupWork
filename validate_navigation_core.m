function validate_navigation_core()
%VALIDATE_NAVIGATION_CORE Non-GUI checks for map, road, and path logic.

baseDir = fileparts(mfilename('fullpath'));
mapFile = fullfile(baseDir, 'MapForUI.jpg');
img = imread(mapFile);
[mapHeightPx, mapWidthPx, channels] = size(img);
scaleM = 1.7;

must(mapWidthPx == 1404, 'map width must be 1404 pixels');
must(mapHeightPx == 803, 'map height must be 803 pixels');
must(channels == 3, 'map must be an RGB image');

network = validationBuildRoadNetwork(mapWidthPx, mapHeightPx, scaleM);
must(size(network.segments, 1) > 60, 'road network should contain modeled road segments');
must(size(network.nodes, 1) > 40, 'road network should contain network nodes');
must(network.grid.stepPx == 6, 'road grid step should be 6 pixels for high precision');
must(size(network.grid.nodes, 1) > 8000, 'road grid should contain dense navigable nodes');

roadPoint = validationPxToMeters(1088, 435, mapHeightPx, scaleM);
[validRoad, snappedRoad, roadSegIdx, roadDist] = validationNearestRoad(network, roadPoint);
must(validRoad, 'known road point should be accepted');
must(roadSegIdx > 0, 'known road point should find a road segment');
must(roadDist < 0.001, 'known road point should be on a road centerline');
must(validationDistance(roadPoint, snappedRoad) < 0.001, 'known road point should not move when snapped');

offRoadPoint = validationPxToMeters(25, 25, mapHeightPx, scaleM);
[validOffRoad, ~, ~, ~] = validationNearestRoad(network, offRoadPoint);
must(~validOffRoad, 'off-road point should be rejected for IV loading');

startPoint = validationPxToMeters(60, 60, mapHeightPx, scaleM);
endPoint = validationPxToMeters(1300, 650, mapHeightPx, scaleM);
[route, routeLength, okPath, snappedStart, snappedEnd] = validationPlanShortestPath(network, startPoint, endPoint);
must(okPath, 'path planning should snap arbitrary map points to nearest roads');
must(size(route, 1) >= 2, 'planned route should contain at least two route points');
must(routeLength > 0, 'planned route length should be positive');
must(validationPointInMap(snappedStart, mapWidthPx * scaleM, mapHeightPx * scaleM), 'snapped start should be inside map');
must(validationPointInMap(snappedEnd, mapWidthPx * scaleM, mapHeightPx * scaleM), 'snapped end should be inside map');

masked = validationBuildLocalMaskedImage(img, roadPoint, 120, scaleM);
centerCol = max(1, min(mapWidthPx, round(roadPoint(1) / scaleM)));
centerRow = max(1, min(mapHeightPx, round(mapHeightPx - roadPoint(2) / scaleM)));
must(any(masked(centerRow, centerCol, :) ~= 245), 'local mask should keep the center pixel');
must(all(masked(1, 1, :) == 245), 'local mask should blank a distant corner pixel');

disp('CORE_VALIDATION_OK');
end

function must(condition, message)
if ~condition
    error(message);
end
end

function network = validationBuildRoadNetwork(mapWidthPx, mapHeightPx, scaleM)
segPx = RoadModelDataPx();
gridStepPx = 6;

segments = zeros(size(segPx));
for i = 1:size(segPx, 1)
    p1 = validationPxToMeters(segPx(i, 1), segPx(i, 2), mapHeightPx, scaleM);
    p2 = validationPxToMeters(segPx(i, 3), segPx(i, 4), mapHeightPx, scaleM);
    segments(i, :) = [p1 p2 segPx(i, 5) * scaleM];
end

nodes = [];
edges = zeros(size(segments, 1), 3);
for i = 1:size(segments, 1)
    [nodes, n1] = validationAppendUniqueNode(nodes, segments(i, 1:2));
    [nodes, n2] = validationAppendUniqueNode(nodes, segments(i, 3:4));
    edges(i, :) = [n1 n2 validationDistance(segments(i, 1:2), segments(i, 3:4))];
end

network.nodes = nodes;
network.edges = edges;
network.segments = segments;
network.grid = validationBuildRoadGrid(segPx, mapWidthPx, mapHeightPx, scaleM, gridStepPx);
end

function grid = validationBuildRoadGrid(segPx, mapWidthPx, mapHeightPx, scaleM, stepPx)
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
    nodesM(i, :) = validationPxToMeters(nodesPx(i, 1), nodesPx(i, 2), mapHeightPx, scaleM);
end

grid.nodes = nodesM;
grid.indexMap = indexMap;
grid.nodeRows = nodeRows;
grid.nodeCols = nodeCols;
grid.xs = xs;
grid.ys = ys;
grid.stepPx = stepPx;
end

function valid = validationIsRoadPointPx(pt, segPx, tolerancePx)
valid = false;
for i = 1:size(segPx, 1)
    [~, d] = validationProjectPointToSegmentPx(pt, segPx(i, 1:2), segPx(i, 3:4));
    if d <= segPx(i, 5) / 2 + tolerancePx
        valid = true;
        return;
    end
end
end

function [q, d] = validationProjectPointToSegmentPx(p, a, b)
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
d = validationDistance(p, q);
end

function segPx = validationAppendH(segPx, y, xs, widthPx)
for k = 1:(length(xs) - 1)
    segPx = validationAppendSeg(segPx, xs(k), y, xs(k + 1), y, widthPx);
end
end

function segPx = validationAppendV(segPx, x, ys, widthPx)
for k = 1:(length(ys) - 1)
    segPx = validationAppendSeg(segPx, x, ys(k), x, ys(k + 1), widthPx);
end
end

function segPx = validationAppendPolyline(segPx, xs, ys, widthPx)
for k = 1:(length(xs) - 1)
    segPx = validationAppendSeg(segPx, xs(k), ys(k), xs(k + 1), ys(k + 1), widthPx);
end
end

function segPx = validationAppendSeg(segPx, x1, y1, x2, y2, widthPx)
segPx(end + 1, :) = [x1 y1 x2 y2 widthPx];
end

function [nodes, idx] = validationAppendUniqueNode(nodes, pt)
idx = 0;
for j = 1:size(nodes, 1)
    if validationDistance(nodes(j, :), pt) < 0.01
        idx = j;
        return;
    end
end
nodes(end + 1, :) = pt;
idx = size(nodes, 1);
end

function pt = validationPxToMeters(xPx, yTopPx, mapHeightPx, scaleM)
pt = [xPx * scaleM, (mapHeightPx - yTopPx) * scaleM];
end

function [valid, snapped, segIdx, minDist] = validationNearestRoad(network, pt)
minDist = inf;
snapped = [NaN NaN];
segIdx = 0;
valid = false;
for i = 1:size(network.segments, 1)
    s = network.segments(i, :);
    [q, d] = validationProjectPointToSegment(pt, s(1:2), s(3:4));
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

function [q, d] = validationProjectPointToSegment(p, a, b)
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
d = validationDistance(p, q);
end

function [route, totalLength, ok, snappedStart, snappedEnd] = validationPlanShortestPath(network, startPt, endPt)
route = [];
totalLength = inf;
ok = false;
[~, snappedStart, startSegIdx, ~] = validationNearestRoad(network, startPt);
[~, snappedEnd, endSegIdx, ~] = validationNearestRoad(network, endPt);
if startSegIdx == 0 || endSegIdx == 0
    return;
end

startNode = validationNearestGridNode(network, snappedStart);
endNode = validationNearestGridNode(network, snappedEnd);
if startNode == 0 || endNode == 0
    return;
end
[idxPath, gridLength, gridOk] = validationAstarRoadGrid(network, startNode, endNode);
if ~gridOk
    return;
end
gridRoute = network.grid.nodes(idxPath, :);
route = [snappedStart; gridRoute; snappedEnd];
totalLength = gridLength + validationDistance(snappedStart, gridRoute(1, :)) + validationDistance(snappedEnd, gridRoute(end, :));
ok = true;
end

function idx = validationNearestGridNode(network, pt)
idx = 0;
best = inf;
for i = 1:size(network.grid.nodes, 1)
    d = validationDistance(network.grid.nodes(i, :), pt);
    if d < best
        best = d;
        idx = i;
    end
end
end

function [idxPath, totalLength, ok] = validationAstarRoadGrid(network, startNode, endNode)
n = size(network.grid.nodes, 1);
gScore = inf(1, n);
fScore = inf(1, n);
prev = zeros(1, n);
closedSet = false(1, n);
gScore(startNode) = 0;
fScore(startNode) = validationDistance(network.grid.nodes(startNode, :), network.grid.nodes(endNode, :));
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
        tentative = gScore(u) + validationDistance(network.grid.nodes(u, :), network.grid.nodes(v, :));
        if tentative >= gScore(v)
            continue;
        end
        prev(v) = u;
        gScore(v) = tentative;
        fScore(v) = tentative + validationDistance(network.grid.nodes(v, :), network.grid.nodes(endNode, :));
        openNodes(end + 1) = v;
        openScores(end + 1) = fScore(v);
    end
end
end

function adj = validationConnectProjection(adj, network, nodeIdx, pt, segmentIdx)
s = network.segments(segmentIdx, :);
n1 = validationFindNodeIndex(network.nodes, s(1:2));
n2 = validationFindNodeIndex(network.nodes, s(3:4));
d1 = validationDistance(pt, s(1:2));
d2 = validationDistance(pt, s(3:4));
adj(nodeIdx, n1) = min(adj(nodeIdx, n1), d1);
adj(n1, nodeIdx) = min(adj(n1, nodeIdx), d1);
adj(nodeIdx, n2) = min(adj(nodeIdx, n2), d2);
adj(n2, nodeIdx) = min(adj(n2, nodeIdx), d2);
end

function idx = validationFindNodeIndex(nodes, pt)
idx = 1;
best = inf;
for i = 1:size(nodes, 1)
    d = validationDistance(nodes(i, :), pt);
    if d < best
        best = d;
        idx = i;
    end
end
end

function [dist, prev] = validationDijkstra(adj, startNode)
n = size(adj, 1);
dist = inf(1, n);
prev = zeros(1, n);
visited = false(1, n);
dist(startNode) = 0;
for step = 1:n
    best = inf;
    u = 0;
    for i = 1:n
        if ~visited(i) && dist(i) < best
            best = dist(i);
            u = i;
        end
    end
    if u == 0
        break;
    end
    visited(u) = true;
    for v = 1:n
        if ~visited(v) && ~isinf(adj(u, v))
            alt = dist(u) + adj(u, v);
            if alt < dist(v)
                dist(v) = alt;
                prev(v) = u;
            end
        end
    end
end
end

function img = validationBuildLocalMaskedImage(src, center, radius, scaleM)
img = src;
[hImg, wImg, ~] = size(src);
xs = ((1:wImg) - 0.5) * scaleM;
keep = false(hImg, wImg);
r2 = radius * radius;
for row = 1:hImg
    yReal = (hImg - row + 0.5) * scaleM;
    keep(row, :) = (xs - center(1)).^2 + (yReal - center(2)).^2 <= r2;
end
for k = 1:3
    plane = img(:, :, k);
    plane(~keep) = 245;
    img(:, :, k) = plane;
end
end

function inside = validationPointInMap(pt, widthM, heightM)
inside = pt(1) >= 0 && pt(1) <= widthM && pt(2) >= 0 && pt(2) <= heightM;
end

function d = validationDistance(a, b)
dx = a(1) - b(1);
dy = a(2) - b(2);
d = sqrt(dx * dx + dy * dy);
end
