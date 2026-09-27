# Windows GUI 分析

只有当任务确实依赖交互式桌面状态时才引入 GUI 层。GUI 是第四条能力通道，不替代 task runtime、debugger、文件/行为采集或 VM 生命周期。

## 优先顺序

优先使用语义接口：

```text
工具自身 API / MCP
→ Windows UI Automation（UIA）
→ VM/RDP/VMConnect 的可见桌面
→ 像素级 Computer Use / 鼠标键盘
```

原因：UIA 提供对多数 Windows UI 元素的程序化访问，通常比绝对坐标和图像匹配更稳定。

## Host 与 Guest

GUI 自动化仍应由 Host Agent 决策。Guest 只提供：

- 可交互桌面；
- UIA/辅助接口；
- framebuffer / VMConnect / RDP 等显示和输入通道；
- 实际 GUI 应用。

不要把完整 Agent 和长期项目状态放进可回滚 Guest。

## Hyper-V

VMConnect 可用于连接 Hyper-V Windows VM；Enhanced Session Mode 基于 RDP 提供更完整的交互体验。GUI 能正常显示只证明桌面通道可用，不证明样本分析 runtime 或 debugger 正常。

## 使用原则

- 能通过 MCP/API 完成的动作，不要改用 GUI 点击。
- 能通过 UIA 稳定定位控件的动作，不要先使用绝对坐标。
- 只有自绘控件、无法访问的界面、验证码式视觉状态或复杂自然交互才使用像素/视觉层。
- GUI 截图、点击成功、窗口出现都不是业务成功证据；仍需读取目标结果。
- 如果目标必须在用户交互 session 运行，应先验证实际 session，而不是把 Session 0 进程存在当作等价。

## 上游

- Microsoft UI Automation: https://learn.microsoft.com/windows/win32/winauto/entry-uiauto-win32
- Hyper-V VMConnect / Enhanced Session: https://learn.microsoft.com/windows-server/virtualization/hyper-v/enhanced-session-mode
