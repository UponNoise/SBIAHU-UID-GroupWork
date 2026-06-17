# 道路模型重做说明

## 问题

旧版道路模型使用少量人工中心线和长线段连接，局部会穿过建筑、湖面、草地或广场，导致：

- IV 合法性判断不够可信。
- 自动朝向可能参考错误路段。
- 路径规划在弯路和交叉口附近明显偏离真实道路。

## 当前方案

当前版本采用：

- `RoadModelDataPx.m`：从 `MapForUI-road-width-green.jpg` 的 `#00FF00` 绿色宽道路标注离线提取道路走廊；提取时允许微信 JPEG 压缩带来的色差。
- 3 px 可通行道路网格：根据道路走廊宽度生成密集可通行点。
- 自写 A*：在 3 px 网格上搜索最短路径，避免使用 MATLAB `graph` 或 `shortestpath`。

这样保留了课程要求的可观察实现过程，同时比稀疏中心线更贴近地图道路。

## 核验方法

- 勾选 UI 中的 `Road Model`，检查道路中心线和蓝色网格点是否贴合真实道路。
- 使用 `Path Plan` 点击两个任意地图点，检查路径是否沿道路区域行进。
- 参考 `grid_path_example.png` 查看当前路径规划效果。

## 后续微调方式

若发现某段道路仍偏离，不需要修改 A* 算法，优先修订绿色宽道路标注图并重新运行 `tools/extract_road_model_from_marked_map.py`；也可以直接微调 `RoadModelDataPx.m` 中对应道路折线的像素点或宽度，然后重新运行：

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

离线提取脚本使用 Python 图像处理库完成颜色容差、骨架化和距离变换；课程 UI 运行时不依赖 Python，只读取已经提交的 `RoadModelDataPx.m`。
