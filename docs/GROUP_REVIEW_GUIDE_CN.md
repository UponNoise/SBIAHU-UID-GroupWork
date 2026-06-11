# 组员下载与核验指南

## 1. 下载仓库

```powershell
git clone https://github.com/UponNoise/SBIAHU-UID-GroupWork.git
cd SBIAHU-UID-GroupWork
```

如果仓库权限不可见，联系组长尤晟喧添加 GitHub 访问权限。

## 2. MATLAB 运行核验

在 MATLAB 中打开项目根目录，运行：

```matlab
main
```

建议每位组员至少核验以下流程：

1. 点击 `Load Map`，确认地图显示。
2. 在 `Inspect` 模式点击地图，确认坐标更新。
3. 勾选 `Road Model`，观察道路中心线和蓝色道路网格点是否贴合真实道路。
4. 勾选 `Auto align road`，点击 `Add IV by Click`，在道路上加载 IV。
5. 选择 IV 后点击 `Report IVs`。
6. 使用 `2-Point Distance` 点击两点，查看距离日志。
7. 使用 `Trajectory Start` 连续点击后点击 `Trajectory Finish`。
8. 输入角度并点击 `Apply`，确认地图和覆盖物一起旋转。
9. 使用 `Extract Skeleton` 点击道路点，再勾选 `Skeleton Road`。
10. 输入 `Local r(m)` 并点击 `Local`，确认只显示选中 IV 周围圆形地图。
11. 点击 `Street View` 后点击道路点，确认生成街景窗口。
12. 点击 `Path Plan` 后点击两个地图点，确认最短路径沿道路网格显示，不穿过建筑、湖面或草地。

## 3. Octave 快速验收

如果没有 MATLAB，可以先用 Octave 做非 GUI 验收：

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

通过结果：

```text
CORE_VALIDATION_OK
exit=0
```

UI smoke：

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

通过证据：

```text
UI_SMOKE_OK
exit=0
validation/logs/ui_smoke.ok
```

## 4. 分工认领建议

- Member 2：重点检查 OR1，道路骨架提取和骨架道路局部显示。
- Member 3：重点检查 OR2，IV 缩放和局部圆形地图。
- Member 4：重点检查 OR3，自动道路对齐和 IV Up 旋转视图。
- Member 5：重点检查 OR4，虚拟街景生成。
- 尤晟喧：重点检查 OR5、整体集成、最终报告和提交包。

## 5. 提交前检查

正式发邮件前确认：

- `submission/IntelligentNavigationUI_MatlabScripts.zip` 可解压运行。
- `submission/Technical_Report_Intelligent_Navigation_UI.docx` 中已替换真实组员姓名和学号。
- `submission/Technical_Report_Intelligent_Navigation_UI.pdf` 与 DOCX 一致。
- README 和中文说明中的 TBD Member 已按实际名单更新。
- 邮件中列出完整组员名单，并等待 Prof. Li 确认收到。
