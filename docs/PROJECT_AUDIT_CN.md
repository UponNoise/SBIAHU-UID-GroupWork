# 项目任务覆盖审计

审计日期：2026-06-07
项目：Stony Brook University ISE333 User Interface Development Course Project
仓库：SBIAHU-UID-GroupWork
组长：尤晟喧，R32314015

## 硬性要求检查

| 要求 | 当前状态 | 证据 |
|---|---|---|
| 只能使用 MATLAB | 已满足 | 主程序为 `.m` 文件；未使用 App Designer 或其他语言实现 UI |
| 需要主脚本启动 UI | 已满足 | `main.m` 位于根目录，调用 `RunIntelligentNavigationUI()` |
| 启动后不依赖命令行操作 | 已满足 | 控件覆盖地图加载、IV、测量、旋转、骨架、街景、路径规划 |
| 可加载地图 | 已满足 | `MapForUI.jpg` 由 `imread` 读取并显示 |
| 点击地图显示真实世界坐标 | 已满足 | 点击事件会反向旋转坐标并显示米制坐标 |
| IV 加载必须检查道路合法性 | 已满足 | 点击点投影到绿色宽道路标注图提取的道路走廊，距离超出道路宽度则报错 |
| IV 可多辆加载、删除、报告位置 | 已满足 | `app.vehicles` 管理多辆 IV；支持删除和报告 |
| IV 方向可调 | 已满足 | 支持手动角度和自动道路对齐 |
| 两点距离和轨迹长度 | 已满足 | `addDistancePoint` 和 `finishTrajectory` |
| 地图旋转 | 已满足 | `mapRotation` 控制地图与覆盖物整体旋转 |

## Optional Requirement 覆盖

| Optional Requirement | 状态 | 当前实现 |
|---|---|---|
| OR1 Road skeleton extraction | 已补齐 | `Extract Skeleton` 模式手动点击道路点；`Skeleton Road` 可只显示骨架附近粗略道路区域 |
| OR2 Scale and local visualization | 已补齐 | `IV scale` 控制 IV 显示比例；`Local r(m)` 严格按半径显示局部圆形地图 |
| OR3 Auto aligned orientation | 已补齐 | `Auto align road` 根据最近道路段方向设置 IV；`IV Up` 旋转地图使 IV 朝上 |
| OR4 Virtual street view | 已补齐 | `Street View` 对道路点生成简化街景窗口，显示道路点坐标和朝向 |
| OR5 Path planning | 已补齐 | 两个任意地图点先吸附到最近道路点，再用 3 px 可通行道路网格和自写 A* 规划最短路 |

## 已完成的薄弱项修正

1. OR1 原先只显示骨架线和道路带叠加，现在改为 `Skeleton Road` 模式下对地图做骨架道路带遮罩，骨架带外区域空白化，更接近“只显示附着于骨架的道路部分”。
2. OR2 局部视图加入等比例显示和半径边界锁定，避免坐标轴自动缩放破坏指定半径。
3. OR5 路径规划按要求接受任意地图点，不再要求起终点本身位于道路上。
4. 道路规划已从旧版稀疏中心线方案改为 `RoadModelDataPx.m` 绿色宽道路标注图提取道路走廊 + 3 px 高精度可通行网格 + 自写 A*，减少弯路和交叉口附近的路径偏离。
5. 增加 `validate_navigation_core.m`，覆盖地图尺寸、坐标换算、道路合法性、3 px 网格、吸附、路径规划和局部遮罩。
6. 增加 `validate_ui_smoke.m`，用于快速检查 UI 创建阶段是否抛出异常。

## 已知限制

- 道路模型是人工标注的道路走廊，不是从图片自动精确分割道路边界。
- 虚拟街景是简化生成视图，不是实际校园街景图片。
- 本机没有 MATLAB，最终交互体验仍建议由有 MATLAB 的组员运行 `main.m` 复核。
- 本机 Octave UI smoke 已返回 `exit=0`，但 Octave 图形后端和 MATLAB 不完全一致。

## 当前结论

除组员真实姓名和学号待填写外，课程 PDF 中的基础要求和五个 optional requirement 均已有对应实现、说明和可复核证据。

## 设计审查 TODO

2026-06-17 进行了全项目设计审查，共发现 14 项待改进问题（4 项高优先级、6 项中优先级、4 项低优先级），详见 [`DESIGN_REVIEW_TODO_CN.md`](./DESIGN_REVIEW_TODO_CN.md)。
