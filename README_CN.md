# SBIAHU-UID-GroupWork 中文说明

## 项目信息

- 学校：Stony Brook University
- 课程：ISE333 / CSE333 User Interface Development
- 学期：Spring 2026
- 项目：An Intelligent Navigation UI
- 仓库：SBIAHU-UID-GroupWork
- 组长：尤晟喧，R32314015
- 组员：Member 2-5 待定

本项目实现一个基于课程提供地图 `MapForUI.jpg` 的智能车辆导航 UI。课程硬要求是 MATLAB 实现，并且运行 `main.m` 后，后续操作都通过图形界面完成。

## 目录结构

```text
.
├── main.m                              # 课程要求的启动脚本
├── RunIntelligentNavigationUI.m         # UI 和核心功能实现
├── RoadModelDataPx.m                    # 从绿色宽道路标注图提取的道路走廊数据
├── MapForUI.jpg                         # 课程地图素材
├── validate_navigation_core.m           # 非 GUI 核心算法验收
├── validate_ui_smoke.m                  # UI 快速启动验收
├── RunProject_OctaveGUI.cmd             # 本机 Octave 可见窗口启动入口
├── RunValidation_Octave.cmd             # 本机 Octave 一键验证入口
├── README.md                            # 英文说明
├── README_CN.md                         # 中文说明
├── docs/
│   ├── DEVELOPMENT_LOG.md               # 开发日志
│   ├── PROJECT_AUDIT_CN.md              # 中文任务覆盖审计
│   ├── GROUP_REVIEW_GUIDE_CN.md         # 组员核验指南
│   ├── LOCAL_ENVIRONMENT_CN.md          # 本机 MATLAB/Octave 与插件状态
│   ├── road_rework/                     # 道路网格重做说明和路径示例
│   └── report/                          # 技术报告和报告素材
├── tools/                               # 绿色宽道路标注图离线提取工具
├── submission/                          # 最终提交附件
└── validation/logs/                     # Octave 验收记录
```

根目录保留 `main.m`、核心 `.m` 文件和地图，是为了保证老师或组员下载仓库后可以直接运行，不需要手动配置路径。

## 运行方式

在 MATLAB 中进入项目根目录，运行：

```matlab
main
```

打开 UI 后可以完成：

- 加载并显示地图
- 点击地图显示真实世界坐标
- 加载多个 IV，并检查是否位于可通行道路
- 设置 IV 手动方向或自动道路对齐方向
- 删除指定 IV
- 报告所有 IV 的真实世界位置
- 测量两点距离
- 测量连续点击轨迹长度
- 按角度旋转地图
- 手动提取道路骨架
- 只显示附着于骨架的粗略道路区域
- 调整 IV 显示比例
- 按指定半径显示 IV 局部圆形地图
- 生成基于透视投影的虚拟街景
- 在两个任意地图点之间规划最短道路路径

路径规划已经改为“#00FF00 绿色宽道路标注图提取道路走廊 + 3 px 高精度可通行网格 + 自写 A*”。旧版稀疏中心线路径方案已移除，因为它会在弯路和交叉口附近产生明显偏离。

## Octave 验收

本机没有 MATLAB，所以用 GNU Octave 11.1.0 portable 做了验收。示例路径如下，其他组员按自己的安装位置替换；如果 `octave-cli` 已加入 PATH，也可以直接使用 `octave-cli`。

```text
$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64
```

核心算法验收命令：

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_navigation_core; exit(0);"
```

通过标志：

```text
CORE_VALIDATION_OK
exit=0
```

UI 快速启动验收命令：

```powershell
& "$env:USERPROFILE\Tools\Octave\octave-11.1.0-w64\mingw64\bin\octave-cli.exe" --no-gui --quiet --path . --eval "validate_ui_smoke; exit(0);"
```

通过标志：

```text
UI_SMOKE_OK
exit=0
validation/logs/ui_smoke.ok
```

说明：当前 `validate_ui_smoke.m` 会以不可见窗口启动 UI，并在退出前强制清理 figure。本机复验结果为 `exit=0`。由于 Octave 图形后端和 MATLAB 不完全一致，最终交互体验仍建议由有 MATLAB 的组员复核。

本机也提供两个 Windows 入口：

```powershell
.\RunValidation_Octave.cmd
.\RunProject_OctaveGUI.cmd
```

注意：本机 `octave-gui.exe` 会触发 Fail Fast Exception，因此 GUI 启动入口实际使用 `octave-cli --persist` 打开 figure 窗口。

## 分工状态

| 项目 | 负责范围 | 当前负责人 |
|---|---|---|
| OR1 | 道路骨架提取和骨架道路局部显示 | TBD Member 2 |
| OR2 | IV 缩放和局部圆形地图 | TBD Member 3 |
| OR3 | IV 自动道路对齐和 IV 向上旋转视图 | TBD Member 4 |
| OR4 | 虚拟街景生成 | TBD Member 5 |
| OR5 | 路径规划和整体集成 | 尤晟喧，R32314015 |

虽然 Member 2-5 尚未填写姓名，但 OR1-OR4 的代码功能已经补齐，可由后续实际组员认领、核验和修改。

## 最终提交文件

最终附件位于：

```text
submission/
```

包含：

- `IntelligentNavigationUI_MatlabScripts.zip`
- `Technical_Report_Intelligent_Navigation_UI.docx`
- `Technical_Report_Intelligent_Navigation_UI.pdf`

正式提交前需要把 TBD Member 2-5 替换为真实姓名和学号。
