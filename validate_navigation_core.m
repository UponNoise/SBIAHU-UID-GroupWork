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

roadPoint = validationPxToMeters(1000, 404, mapHeightPx, scaleM);
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
segPx = [];

segPx = validationAppendH(segPx, 162, [0 100 160 290 392 450 500 617 803 900 1090 1200 mapWidthPx], 18);
segPx = validationAppendH(segPx, 298, [0 100 160 300 392 450 500 617 700 803 900 1090 1200 mapWidthPx], 18);
segPx = validationAppendH(segPx, 404, [0 100 160 300 392 450 500 617 700 803 900 1000 1090 1200 mapWidthPx], 20);
segPx = validationAppendH(segPx, 500, [0 100 160 300 392 450 500 617 700 803 900 1000 1090 1200 mapWidthPx], 16);
segPx = validationAppendH(segPx, 686, [0 100 160 300 392 450 500 617 700 803 900 1000 1090 1200 mapWidthPx], 18);

segPx = validationAppendV(segPx, 100, [0 162 298 404 500 686 mapHeightPx], 18);
segPx = validationAppendV(segPx, 160, [0 162 298 404 500 686 mapHeightPx], 16);
segPx = validationAppendV(segPx, 300, [162 298 404 500 686], 14);
segPx = validationAppendV(segPx, 392, [0 162 298 404 500 686 mapHeightPx], 18);
segPx = validationAppendV(segPx, 450, [0 162 298 404 500 686 mapHeightPx], 24);
segPx = validationAppendV(segPx, 500, [0 162 298 404 500 686 mapHeightPx], 14);
segPx = validationAppendV(segPx, 617, [0 162 298 404 500 686 mapHeightPx], 18);
segPx = validationAppendV(segPx, 700, [298 404 500 686 mapHeightPx], 18);
segPx = validationAppendV(segPx, 803, [0 162 298 404 500 686 mapHeightPx], 18);
segPx = validationAppendV(segPx, 900, [162 298 404 500 686], 14);
segPx = validationAppendV(segPx, 1000, [298 404 500 686], 14);
segPx = validationAppendV(segPx, 1090, [0 162 298 404 500 686 mapHeightPx], 18);
segPx = validationAppendV(segPx, 1200, [162 298 404 500 686 mapHeightPx], 18);

segPx = validationAppendPolyline(segPx, [160 230 300 392], [404 470 500 686], 14);
segPx = validationAppendPolyline(segPx, [392 300 230 160], [404 470 500 686], 14);
segPx = validationAppendPolyline(segPx, [500 560 617], [686 610 500], 14);
segPx = validationAppendPolyline(segPx, [617 660 700], [298 350 404], 14);
segPx = validationAppendPolyline(segPx, [803 850 900], [298 350 404], 14);
segPx = validationAppendPolyline(segPx, [900 1000 1090], [500 590 686], 14);
segPx = validationAppendPolyline(segPx, [900 1000 1090], [298 230 162], 14);
segPx = validationAppendPolyline(segPx, [1090 1200 mapWidthPx], [162 298 404], 18);
segPx = validationAppendPolyline(segPx, [1090 1200 mapWidthPx], [686 500 404], 18);

centerX = 1090;
centerY = 404;
radius = 145;
angles = 0:30:360;
xs = centerX + radius * cos(angles * pi / 180);
ys = centerY + radius * sin(angles * pi / 180);
segPx = validationAppendPolyline(segPx, xs, ys, 16);
segPx = validationAppendPolyline(segPx, [centerX centerX], [centerY centerY - radius], 18);
segPx = validationAppendPolyline(segPx, [centerX centerX], [centerY centerY + radius], 18);
segPx = validationAppendPolyline(segPx, [centerX centerX - radius], [centerY centerY], 18);
segPx = validationAppendPolyline(segPx, [centerX centerX + radius], [centerY centerY], 18);
segPx = validationAppendPolyline(segPx, [centerX centerX - 105], [centerY centerY - 105], 16);
segPx = validationAppendPolyline(segPx, [centerX centerX + 105], [centerY centerY - 105], 16);
segPx = validationAppendPolyline(segPx, [centerX centerX - 105], [centerY centerY + 105], 16);
segPx = validationAppendPolyline(segPx, [centerX centerX + 105], [centerY centerY + 105], 16);

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

nBase = size(network.nodes, 1);
startNode = nBase + 1;
endNode = nBase + 2;
nodes = [network.nodes; snappedStart; snappedEnd];
n = size(nodes, 1);
adj = inf(n, n);
for i = 1:n
    adj(i, i) = 0;
end

for i = 1:size(network.edges, 1)
    a = network.edges(i, 1);
    b = network.edges(i, 2);
    d = network.edges(i, 3);
    adj(a, b) = min(adj(a, b), d);
    adj(b, a) = min(adj(b, a), d);
end

adj = validationConnectProjection(adj, network, startNode, snappedStart, startSegIdx);
adj = validationConnectProjection(adj, network, endNode, snappedEnd, endSegIdx);
if startSegIdx == endSegIdx
    d = validationDistance(snappedStart, snappedEnd);
    adj(startNode, endNode) = min(adj(startNode, endNode), d);
    adj(endNode, startNode) = min(adj(endNode, startNode), d);
end

[dist, prev] = validationDijkstra(adj, startNode);
if isinf(dist(endNode))
    return;
end

idxPath = endNode;
current = endNode;
while current ~= startNode
    current = prev(current);
    if current == 0
        return;
    end
    idxPath = [current idxPath];
end
route = nodes(idxPath, :);
totalLength = dist(endNode);
ok = true;
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
