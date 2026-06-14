function segPx = RoadModelDataPx()
%ROADMODELDATAPX Manual road centerline model for MapForUI.jpg.
% Each row is [x1 y1 x2 y2 widthPx] in image pixel coordinates.
segPx = [];
segPx = appendRoadPolyline(segPx, [455 455], [0 803], 28); % west_expressway_vertical
segPx = appendRoadPolyline(segPx, [1088 1088 1088 1088 1088 1088 1088], [0 166 300 435 630 710 803], 28); % main_north_south_avenue
segPx = appendRoadPolyline(segPx, [94 160 300 392 455 520 610 850 960 1040 1088], [166 166 166 166 166 166 166 166 166 166 166], 16); % north_cross_road
segPx = appendRoadPolyline(segPx, [0 95 160 300 392 455 520 610 705 805 850 980 1088 1190 1290 1404], [435 435 435 435 435 435 435 435 435 435 435 435 435 435 435 435], 16); % middle_cross_road
segPx = appendRoadPolyline(segPx, [455 520 610 705 805 850 980 1088 1190 1290], [710 710 710 710 710 710 710 710 710 710], 16); % south_cross_road
segPx = appendRoadPolyline(segPx, [100 100 100 100], [166 205 260 300], 14); % west_vertical_100
segPx = appendRoadPolyline(segPx, [160 160 160 160 160 160 160], [0 80 166 260 300 390 435], 16); % west_vertical_160
segPx = appendRoadPolyline(segPx, [300 300 300 300 300 300], [166 230 300 330 390 435], 14); % west_vertical_300
segPx = appendRoadPolyline(segPx, [392 392 392 392 392 392 392], [166 260 300 435 560 690 760], 16); % west_vertical_392
segPx = appendRoadPolyline(segPx, [0 100 160 300 392], [300 300 300 300 300], 14); % west_horizontal_300
segPx = appendRoadPolyline(segPx, [0 95 160 245 300 392], [390 390 390 390 390 390], 14); % west_horizontal_390
segPx = appendRoadPolyline(segPx, [160 165 195 245 300 392], [435 395 365 345 330 330], 14); % west_north_curve
segPx = appendRoadPolyline(segPx, [300 310 305 295 320 392], [435 500 570 645 690 690], 14); % west_lake_east_curve
segPx = appendRoadPolyline(segPx, [0 100 200 300 392 455], [760 760 760 760 760 760], 14); % west_south_perimeter
segPx = appendRoadPolyline(segPx, [70 70 70 150 250 392], [435 550 685 690 690 690], 14); % west_stadium_loop
segPx = appendRoadPolyline(segPx, [520 520 520 520 520], [166 300 435 555 710], 14); % mid_vertical_520
segPx = appendRoadPolyline(segPx, [610 610 610 610 610], [166 300 435 555 710], 14); % mid_vertical_610
segPx = appendRoadPolyline(segPx, [705 705 705 705 705 705], [300 435 555 630 710 803], 16); % mid_vertical_705
segPx = appendRoadPolyline(segPx, [805 805 805 805], [300 435 630 710], 16); % mid_vertical_805
segPx = appendRoadPolyline(segPx, [850 850 850 850 850], [166 300 435 630 710], 14); % river_west_road_850
segPx = appendRoadPolyline(segPx, [455 520 610 705 805 850 900 980 1088], [300 300 300 300 300 300 300 300 300], 14); % middle_north_cross
segPx = appendRoadPolyline(segPx, [705 805 850 980 1088], [630 630 630 630 630], 16); % middle_south_cross
segPx = appendRoadPolyline(segPx, [610 680 750 805 850], [166 180 205 260 300], 12); % middle_north_curve
segPx = appendRoadPolyline(segPx, [1143 1141.1 1135.6 1126.9 1115.5 1102.2 1088 1073.8 1060.5 1049.1 1040.4 1034.9 1033 1034.9 1040.4 1049.1 1060.5 1073.8 1088 1102.2 1115.5 1126.9 1135.6 1141.1 1143], [435 449.2 462.5 473.9 482.6 488.1 490 488.1 482.6 473.9 462.5 449.2 435 420.8 407.5 396.1 387.4 381.9 380 381.9 387.4 396.1 407.5 420.8 435], 14); % central_roundabout
segPx = appendRoadPolyline(segPx, [1088 1130 1175 1215 1220 1200 1190 1190], [166 190 245 330 435 540 630 710], 14); % east_outer_curve
segPx = appendRoadPolyline(segPx, [1290 1290 1290 1290 1290], [250 300 435 560 710], 16); % east_inner_vertical
segPx = appendRoadPolyline(segPx, [1185 1230 1270 1290 1290 1290 1290], [335 360 405 435 500 630 710], 14); % east_inner_curve
segPx = appendRoadPolyline(segPx, [1225 1290 1345 1404], [250 250 250 250], 12); % east_horizontal_250
segPx = appendRoadPolyline(segPx, [1088 1180 1225 1290 1345 1404], [300 300 300 300 300 300], 14); % east_horizontal_300
segPx = appendRoadPolyline(segPx, [1190 1240 1290 1345], [560 560 560 560], 12); % east_horizontal_560
segPx = appendRoadPolyline(segPx, [1088 1190 1290], [710 710 710], 16); % east_horizontal_710
segPx = appendRoadPolyline(segPx, [1345 1345 1345 1345], [250 300 360 435], 12); % east_small_vertical
segPx = appendRoadPolyline(segPx, [1380 1377.9 1371.8 1362.5 1351.1 1338.9 1327.5 1318.2 1312.1 1310 1312.1 1318.2 1327.5 1338.9 1351.1 1362.5 1371.8 1377.9 1380], [250 262 272.5 280.3 284.5 284.5 280.3 272.5 262 250 238 227.5 219.7 215.5 215.5 219.7 227.5 238 250], 10); % east_small_roundabout
end

function segPx = appendRoadPolyline(segPx, xs, ys, widthPx)
for k = 1:(length(xs) - 1)
    segPx(end + 1, :) = [xs(k) ys(k) xs(k + 1) ys(k + 1) widthPx];
end
end
