# MATLAB 人工交互验收清单

项目：SBIAHU-UID-GroupWork / Intelligent Navigation UI  
课程：Stony Brook University ISE333 User Interface Development  
组长：尤晟喧，R32314015  
最后更新：2026-06-18

## 验收状态

本机当前仅完成 Octave 自动验证，尚未完成 MATLAB 人工交互验收。  
有 MATLAB 的组员运行 `main.m` 后，应在本文件中补充测试人、MATLAB 版本、系统环境和每项结果。

## 环境记录

| 项目 | 内容 |
|---|---|
| 测试人 | TBD |
| 学号 | TBD |
| MATLAB 版本 | TBD |
| 操作系统 | TBD |
| 测试日期 | TBD |
| 仓库 commit | TBD |

## 交互测试项

| 序号 | 测试项 | 期望结果 | 状态 | 备注 |
|---|---|---|---|---|
| 1 | 运行 `main.m` | 打开“ISE 333 校园智能导航”窗口，无启动异常 | 待测 |  |
| 2 | 点击地图 Inspect | 显示点击点真实米制坐标 | 待测 |  |
| 3 | 勾选 Road Model | 蓝色道路中心线和 3 px 网格点贴合道路 | 待测 |  |
| 4 | Auto align road + Add IV by Click | 道路点可加载 IV，非道路点被拒绝，IV 方向贴合道路 | 待测 |  |
| 5 | Report IVs | 右侧列表输出车辆 ID、坐标、方向角、缩放 | 待测 |  |
| 6 | 2-Point Distance | 两次点击后输出两点距离 | 待测 |  |
| 7 | Trajectory Start / Finish | 多点轨迹绘制并输出总长度 | 待测 |  |
| 8 | Apply Rotation / IV Up / Reset View | 地图与覆盖物同步旋转；IV Up 只旋转视图并记录 auto-align 状态 | 待测 |  |
| 9 | Extract Skeleton + Skeleton Road | 至少 2 个骨架点后显示骨架道路带；单点时给出提示并取消勾选 | 待测 |  |
| 10 | Local r(m) + Local | 只显示选中 IV 周围指定半径的圆形局部地图 | 待测 |  |
| 11 | Street View | 点击道路点后生成街景；连续点击复用同一街景窗口，关闭时记录日志 | 待测 |  |
| 12 | Path Plan | 任意两点吸附到道路并生成不穿越建筑、湖面、草地的道路路径 | 待测 |  |
| 13 | Delete IV / Clear | 可删除车辆并清除测量、轨迹、路径等临时结果 | 待测 |  |

## 自动验证证据

最近一次本机 Octave 验证：

```text
validate_navigation_core: CORE_VALIDATION_OK
validate_ui_smoke: UI_SMOKE_OK
```

注意：Octave 图形后端和 MATLAB 不完全一致，以上不能替代 MATLAB 人工交互验收。
