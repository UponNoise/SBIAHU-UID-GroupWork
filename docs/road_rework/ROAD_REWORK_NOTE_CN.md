# 道路模型重做说明

## 问题

旧版道路模型使用少量人工中心线和长线段连接，局部会穿过建筑、湖面、草地或广场，导致：

- IV 合法性判断不够可信。
- 自动朝向可能参考错误路段。
- 路径规划在弯路和交叉口附近明显偏离真实道路。

## 当前方案

当前版本采用：

- `RoadModelDataPx.m`：按 `MapForUI.jpg` 像素坐标人工标注道路走廊。
- 6 px 可通行道路网格：根据道路走廊宽度生成密集可通行点。
- 自写 A*：在 6 px 网格上搜索最短路径，避免使用 MATLAB `graph` 或 `shortestpath`。

这样保留了课程要求的可观察实现过程，同时比稀疏中心线更贴近地图道路。

## 核验方法

- 勾选 UI 中的 `Road Model`，检查红色道路线和蓝色网格点是否贴合真实道路。
- 使用 `Path Plan` 点击两个任意地图点，检查红色路径是否沿道路区域行进。
- 参考 `grid_path_example.png` 查看当前路径规划效果。

## 后续微调方式

若发现某段道路仍偏离，不需要修改 A* 算法，只需修改 `RoadModelDataPx.m` 中对应道路折线的像素点或宽度，然后重新运行：

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```
