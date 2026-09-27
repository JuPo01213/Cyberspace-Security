# 标准 Windows 分析流程

这是本 Skill 的默认分析流程。它不是“行业统一标准”，而是基于成熟组件整理出的推荐组合；具体环境必须先完成端到端验证。

## 默认路径

```text
从任务契约导出所需 capability
→ 解析已登记且验证有效的 Windows 分析环境
→ 若不存在：按 windows-analysis-stack.md 建设并验证
→ 通过该环境登记的基础设施后端恢复干净 checkpoint
→ 验证本轮需要的 control / data / network / GUI / runtime 入口
→ 确认目标文件身份
→ 通过已登记 analysis runtime 提交正式 job
→ 使用 runtime 自身状态等待完成
→ 读取 results / logs / dropped files / payloads
→ 根据任务问题判断是否需要更深观察
→ 收割结论所需 artifact
→ 回滚分析 VM
```

CAPEsolo 是当前推荐 runtime 实现之一。环境登记为 CAPEsolo 时，按 `capesolo-mcp.md` 使用其 MCP、job 状态和 artifact；通用流程不把某个 runtime 或 hypervisor 名称当作接口定义。

## 深入分析按需升级

当前 runtime 结果不足时，不要整套换工具，按缺口升级：

### 需要精确动态调试

先用已登记 runtime 的 debugger；当前 runtime 为 CAPEsolo 时，先用其 interactive debugger。

如果其能力仍不足，再读 `debugger-stack.md`，补 DbgEng / DbgSrv / WinDbg。

### 需要更细的系统行为

读 `behavior-capture.md`，增加 Procmon / Noriben。

不要为了获取文件/注册表行为先写自制轮询器。

### 需要网络模拟

读 `network-analysis.md`，按需使用 FakeNet-NG。

模拟网络输入会改变目标行为时，必须记录为 intervention。

### 需要 GUI 交互

读 `gui-analysis.md`。

优先 API/MCP，其次 UI Automation，最后才使用视觉/像素级 Computer Use。

## 一次有效分析至少要闭合什么

工具“工作了”与分析“有效”是两件事。解释结论前至少确认：

- 运行的是预期目标；
- 使用的是任务要求的正确 package / options / 参数语义；
- 需要的 observer 在关键阶段有效；
- 结论引用的是本次 run 实际观察到的事实；
- 关键 artifact 已由 runtime/Host 取得；
- 任何会改变行为的 debugger/network/GUI intervention 已被标注。

## 禁止退化

已有标准分析 capability 时，不因为以下理由改走临时路径：

- 直接 PowerShell 启动更快；
- 另一台 VM 已经开着；
- 自己写 runner 看起来简单；
- 当前 runtime 参数暂时不熟；
- 第一次 MCP 调用失败。

先修正确路径。

## 相关参考

- 环境建设：`windows-analysis-stack.md`
- 能力契约：`capability-contract.md`
- CAPEsolo MCP：`capesolo-mcp.md`
- 调试：`debugger-stack.md`
- 行为：`behavior-capture.md`
- 网络：`network-analysis.md`
- GUI：`gui-analysis.md`
- 故障判断：`failure-routing.md`

