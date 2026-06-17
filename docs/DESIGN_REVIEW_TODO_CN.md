# 设计审查 TODO 清单

审查日期：2026-06-17
审查范围：全项目（代码、文档、验证、提交包）
仓库：SBIAHU-UID-GroupWork

---

## 🔴 高优先级（提交前必须解决）

### TODO-01 组员姓名与学号填写

**位置**: `README.md`, `README_CN.md`, `DEVELOPMENT_LOG.md`, `submission/` 报告  
**现状**: Member 2-5 仍为 TBD；Optional Requirement 1-4 分配为 TBD  
**影响**: 课程要求明确列出全体组员和分工，提交时 TBD 视为未完成  
**建议**:
- 由组长收集组员真实姓名与学号
- 更新所有 README 和报告中的组员信息
- 将 OR1-4 的 Assignee 更新为实际姓名

---

### TODO-02 重新生成 submission 包

**位置**: `submission/IntelligentNavigationUI_MatlabScripts.zip`, `submission/Technical_Report_*.docx/pdf`  
**现状**: 最后一次道路重做（2026-06-17，408 段道路）后未重新打包  
**影响**: 提交的 zip 和报告可能基于旧版道路模型（201 段），与当前代码不一致  
**建议**:
- 确认当前 MATLAB 脚本可运行后重新打包 zip
- 更新报告中的道路段数、网格节点数等统计数据
- 替换组员 TBD 后重新导出 DOCX/PDF

---

### TODO-03 开发日志 2026-06-17 条目补充

**位置**: `docs/DEVELOPMENT_LOG.md`  
**现状**: 最后一条目标题为 "2026-06-17 High-Precision Road Extraction and UI Revision"，但无具体内容  
**影响**: 缺少对当前最新改进的记录追溯  
**建议**:
- 补充以下变更说明：
  - 283 条骨架折线 → 408 条道路段
  - 3 px 网格 → 24069 个可通行节点
  - 虚拟街景从固定绘图改为透视投影
  - UI 标题栏改为蓝色校园地图风格
  - 道路宽度提取范围 7.0-26.2 px

---

### TODO-04 MATLAB 最终交互验收

**位置**: 全程  
**现状**: 所有验证仅在 GNU Octave 11.1.0 下完成（non-GUI 和 smoke），未在 MATLAB 中执行交互式 UI 测试  
**影响**: Octave 图形后端与 MATLAB 不完全一致，课程要求 MATLAB 实现  
**建议**:
- 联系有 MATLAB 的组员运行 `main.m`
- 按 `GROUP_REVIEW_GUIDE_CN.md` 第2节逐项验证
- 记录 MATLAB 版本和测试结果

---

## 🟡 中优先级（建议在提交前改进）

### TODO-05 A* 搜索效率优化

**位置**: `RunIntelligentNavigationUI.m` 中的 `astarRoadGrid` 函数  
**现状**: 使用 `[~, pos] = min(openScores)` 线性搜索 open 集中最小值；24k 节点规模下长距离路径搜索可能明显卡顿  
**影响**: 用户体验：点击 Path Plan 后等待时间过长  
**建议**:
- 使用二叉堆/优先队列替代线性搜索
- 或在 MATLAB 中实测最差路径的搜索耗时，若 < 2 秒可暂不优化
- 记录当前最长路径搜索耗时作为基线

---

### TODO-06 Validation 断言阈值与实际数据对齐

**位置**: `validate_navigation_core.m`  
**现状**:
- `must(size(network.segments, 1) > 60, ...)` — 实际 408 段，阈值偏低
- `must(size(network.nodes, 1) > 40, ...)` — 阈值偏低
- `must(size(network.grid.nodes, 1) > 23000, ...)` — 实际 24069，接近边界  
**影响**: 阈值太宽起不到防护作用；grid 断言太紧可能被小幅删段触发  
**建议**:
- 更新 segments 断言为 `> 350`（预留 15% 余量）
- 更新 nodes 断言为 `> 100` 
- 更新 grid.nodes 断言为 `> 20000`（预留充足余量）
- 同步更新 `PROJECT_AUDIT_CN.md` 中的对应数据

---

### TODO-07 文档中硬编码路径泛化

**位置**: `README.md`, `README_CN.md`, `GROUP_REVIEW_GUIDE_CN.md`  
**现状**: Octave 路径写死为 `C:\Users\canana\Tools\Octave\...`，仅适用于组长机器  
**影响**: 其他组员无法复制验证命令  
**建议**:
- 将绝对路径替换为 `$env:USERPROFILE\Tools\Octave\...`（已部分使用）
- 增加说明：路径取决于 Octave 安装位置
- 添加 `octave-cli` 必须在 PATH 中的替代方案

---

### TODO-08 OR3 IV-Up 旋转与自动对齐交互

**位置**: `RunIntelligentNavigationUI.m` 中的 `onRotateIvUp`  
**现状**: `onRotateIvUp` 将地图旋转到 `90 - theta` 使 IV 朝上，但不会改变 IV 自身的朝向（theta），也不会提示用户是否应关闭 auto-align  
**影响**: 用户切换到 IV Up 视图后，若 auto-align 仍开启，后续添加 IV 时朝向计算可能产生混淆  
**建议**:
- 在日志中提示当前 auto-align 状态
- 或在 IV Up 激活时建议关闭 auto-align
- 或者文档中说明此行为是预期的（IV Up 仅旋转视图不影响 IV 朝向）

---

### TODO-09 Street View 窗口生命周期

**位置**: `RunIntelligentNavigationUI.m` 中的 `createStreetView`  
**现状**: 每次点击生成新 figure，无关闭回调；若用户连续点击多个道路点，会累积多个街景窗口  
**影响**: 用户体验：需要手动逐个关闭窗口  
**建议**:
- 使用全局持久化 figure 句柄，新街景替换旧窗口
- 或在生成新街景前关闭旧窗口
- 添加窗口关闭回调记录到日志

---

### TODO-10 appendUniqueNode 容差精度

**位置**: `RunIntelligentNavigationUI.m` 中的 `appendUniqueNode`  
**现状**: 使用 `euclideanDistance < 0.01`（1 cm 米制精度）判断节点去重  
**影响**: 在 1.7 m/px 的地图比例尺下，1 cm 过于严格；可能导致本应合并的道路端点未合并，使图连通性变差  
**建议**:
- 评估将容差提高到 0.3-0.5 m（对应约 0.2-0.3 px）
- 或改为基于像素坐标的去重（1 px 容差），避免米制换算的浮点误差
- 验证提高容差后路径规划覆盖率是否改善

---

## 🟢 低优先级（后续迭代）

### TODO-11 Skeleton Road 单点边界情况

**位置**: `RunIntelligentNavigationUI.m` 中的 `redraw` 和 `drawSkeletonRoadBand`  
**现状**: 骨架道路遮罩需要至少 2 个点；单点时 UI 上 `Skeleton Road` 复选框可勾选但无效果  
**影响**: 轻微 UX 困惑  
**建议**:
- 在 skeleton 点数为 1 时禁用 `Skeleton Road` 复选框
- 或在点击时给出提示需要至少 2 个骨架点

---

### TODO-12 缺少最终交互测试记录

**位置**: `validation/` 目录  
**现状**: 只有 Octave 自动验证结果，缺少人工交互测试记录  
**影响**: 无法向老师证明 UI 的交互功能已经过完整人工验收  
**建议**:
- 在 `validation/logs/` 下创建 `manual_test_checklist.md`
- 记录每位组员的核验结果（通过/未通过/不适用）
- 按 `GROUP_REVIEW_GUIDE_CN.md` 的 12 项逐条记录

---

### TODO-13 RoadModelDataPx.m 中无道路段交叉口的显式连接

**位置**: `RoadModelDataPx.m` + `buildRoadGrid`  
**现状**: 道路模型是 408 条独立走廊段，通过 3 px 网格的空间覆盖隐式连接交叉口；A* 搜索依赖网格邻接而非路段拓扑  
**影响**: 在 T 型交叉口或平行道路间距小于 3 px 处可能出现网格桥接错误  
**建议**:
- 目视检查 `docs/road_rework/grid_path_example.png` 确认交叉口处网格连通性
- 必要时在标记图中加宽交叉口区域的绿色标记
- 重新运行提取脚本验证

---

### TODO-14 RoadModelDataPx.m 文件大小

**位置**: `RoadModelDataPx.m`  
**现状**: 408 段道路数据全部以 `appendRoadPolyline` 调用硬编码在 `.m` 文件中，文件约 450 行  
**影响**: 无功能问题，但若后续继续增加道路段会降低可读性  
**建议**:
- 考虑将数据以矩阵字面量方式直接赋值，减少函数调用开销
- 或保持当前格式（可读性好，便于按编号定位特定路段）

---

## 📊 审计摘要

| 类别 | 数量 |
|------|------|
| 🔴 高优先级 | 4 |
| 🟡 中优先级 | 6 |
| 🟢 低优先级 | 4 |
| **合计** | **14** |

---

## 更新记录

| 日期 | 更新内容 |
|------|----------|
| 2026-06-17 | 初始审查，产生 14 项 TODO |
