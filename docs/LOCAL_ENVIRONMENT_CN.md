# 本机运行环境记录

更新时间：2026-06-18  
仓库：SBIAHU-UID-GroupWork

## MATLAB / 轻量替代方案

本机未检测到完整 MATLAB：

- `matlab` 命令不可用
- `C:\Program Files\MATLAB` 不存在
- `C:\MATLAB` 不存在

`winget` 目前能找到 `MATLAB Runtime` 和 `MATLAB Connector`，但它们不能替代完整 MATLAB IDE，也不能用于调试本项目的 `.m` GUI 源码。因此本机采用轻量替代方案：GNU Octave portable。

已配置的入口：

```text
C:\Tools\matlab-lite\matlab-lite.cmd
C:\Tools\matlab-lite\octave-cli.cmd
C:\Tools\matlab-lite\octave-gui.cmd
```

说明：

- `matlab-lite.cmd` 实际调用 Octave CLI，不伪装为完整 MATLAB。
- `octave-gui.exe` 在本机触发 Fail Fast Exception，因此 `octave-gui.cmd` 已改为 `octave-cli.exe --persist`。
- `octave-cli --persist` 能绕过 Octave IDE 崩溃，同时正常打开本项目的 figure UI。

项目根目录入口：

```text
RunProject_OctaveGUI.cmd
RunValidation_Octave.cmd
```

使用方式：

```powershell
.\RunValidation_Octave.cmd
.\RunProject_OctaveGUI.cmd
```

本机复测结果：

```text
CORE_VALIDATION_OK
UI_SMOKE_OK
```

可见窗口复测：`RunProject_OctaveGUI.cmd` 已成功启动 `ISE 333 智能导航界面`。

## Browser / Computer Use 插件状态

检查结论：

- Codex 配置中存在 Computer Use 运行时路径。
- `codex-computer-use.exe` 文件存在。
- `\\.\pipe\codex-computer-use-...` native pipe 存在。
- `\\.\pipe\codex-browser-use-...` native pipe 存在。
- 但当前 Codex 会话没有暴露 `computer_use`、`browser` 或等价插件工具。
- 可安装插件候选列表中没有精确的 Browser Plugin 或 Computer Use Plugin，因此无法通过本轮工具接口直接安装/启用。

已修复的可替代能力：

- `node_repl` 可用。
- Codex runtime 内置 `playwright`。
- 已安装 Playwright Chromium 到 `C:\Users\canana\AppData\Local\ms-playwright`。

复测结果：

```json
{
  "playwrightFallback": true,
  "title": "browser-fallback-ok",
  "text": "OK"
}
```

结论：Browser/ComputerUse 插件工具本身仍未在当前会话暴露；浏览器自动化 fallback 已恢复。

## 仍需注意

- 课程最终验收仍应优先使用完整 MATLAB。
- 若后续安装完整 MATLAB，需要使用 MathWorks 官方安装器、账号登录和有效许可证；这一步不能用 MATLAB Runtime 替代。
- 本机 Octave 验证不能完全替代 MATLAB 人工交互验收。
