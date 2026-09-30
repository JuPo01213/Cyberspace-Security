# 标准 Windows 分析流程

这是本 Skill 的默认分析流程。它不是“行业统一标准”，而是基于成熟组件整理出的推荐组合；具体环境必须先完成端到端验证。

## 默认路径

```text
任务契约与目标后置条件
→ 选择能力 profile，读取已有证据并做必要的增量复核
→ 建立新 run record、输入身份和边界
→ 只准备本轮实际依赖的 control / data / network / GUI / runtime / collaboration 平面
→ 交付输入并由接收方读回确认
→ 通过已登记 runtime、Guest-local runner 或 Guest Agent 执行
→ 按原始事件和持久化 completion event 监督
→ 收割目标证据、部分产物和失败材料
→ 写入终态，确认精确谱系清理，再回滚/释放
→ 将重复且跨项目的缺口形成问题切片和通用改进候选
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

## 路径选择约束

已有标准分析 capability 时，不因为以下理由直接改走临时路径：

- 直接 PowerShell 启动更快；
- 另一台 VM 已经开着；
- 自己写 runner 看起来简单；
- 当前 runtime 参数暂时不熟；
- 第一次 MCP 调用失败。

先定位成熟路径缺失的具体后置条件。若它确实无法提供该语义，允许补最小适配；适配只覆盖缺口，不复制 runtime 的 task、artifact、retry 或 VM 生命周期。

## 从零建设

如果没有能力 profile 覆盖本轮目标，先读 [tool-building.md](tool-building.md)。从结构化入口、短控制探针、一次数据交付、持久完成事件和原始收割组成最小垂直骨架，再按真实任务增加 debugger、GUI、网络或复杂行为观测。安装、帮助输出和固定 sentinel 不能替代一次无害但真实的端到端任务验收。

## 相关参考

- 环境建设：`windows-analysis-stack.md`
- 能力契约：`capability-contract.md`
- CAPEsolo MCP：`capesolo-mcp.md`
- 调试：`debugger-stack.md`
- 行为：`behavior-capture.md`
- 网络：`network-analysis.md`
- GUI：`gui-analysis.md`
- 故障判断：`failure-routing.md`



