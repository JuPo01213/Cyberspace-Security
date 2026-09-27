---
name: windows-guest-experiment
description: 为需要 Windows Guest/VM 的分析任务选择、建设和复用成熟分析能力。优先使用现有标准环境和官方入口；能力缺失时先安装、配置或修复；仅在确认成熟方案确有缺口后使用最小薄适配。
---

# Windows 分析能力路由

本 Skill 解决的是“**该用什么成熟能力完成任务**”，不是“如何自己造一套 VM 工作流”。

## 默认决策顺序

1. 先识别完成当前任务通常使用的成熟工具、标准分析环境或现有项目能力。
2. 已存在且可用：使用其最高层、官方或已经验证的入口，完整复用其任务生命周期、状态和产物管理。
3. 尚未安装但可合理部署：在授权、成本和安全边界内，先安装、配置并验证，再执行真实任务。
4. 已安装但故障：优先修复；“调用失败”“不会用”“参数不清楚”都不等于该成熟方案不适用。
5. 只有确认成熟方案确实缺少当前任务所需能力时，才为该缺口增加最小薄适配；不得因此重做成熟方案已经解决的部分。

不得因为 PowerShell、SSH、直接启动进程、临时 VM、手写脚本或手算更容易立即执行，就绕过可用或可合理建设的成熟能力。

## Host 与 Guest

- Agent、项目状态、长期判断和证据解释保留在稳定 Host。
- Windows Guest 是可回滚的执行环境，主要承载分析工具、runtime 和目标程序。
- 若成熟 runtime 已提供 task、completion、artifact、retry 或 VM 生命周期，不建立第二套并行状态机。

## 证据约束

- configured / armed / requested 不等于 observed / hit / applied。
- 不同 run 的事实不得拼成同一条因果链。
- 会改变目标行为的 intervention 必须随结论保留。
- unknown 保持 unknown；超时、通信失败或插桩失效不自动等于业务阴性。
- 当前任务和项目契约高于旧摘要、旧 handoff 和模型先前结论。

## 按需参考索引

只读取当前任务真正需要的 reference：

- **没有标准 Windows 分析环境 / 需要重建环境** → `references/windows-analysis-stack.md`
- **需要 Host Agent 通过成熟 runtime 提交、观察和收割样本任务** → `references/capesolo-mcp.md`
- **需要比 runtime 内置 debugger 更深的远程调试能力** → `references/debugger-stack.md`
- **需要详细文件/注册表/进程行为证据** → `references/behavior-capture.md`
- **需要隔离网络模拟或网络侧观察** → `references/network-analysis.md`
- **任务确实依赖交互式 Windows GUI** → `references/gui-analysis.md`
- **成熟能力损坏、缺失或需要判断是否 fallback** → `references/runbook.md`
- **已经确认要使用低层 transport/CLI 薄适配** → `references/adapters.md`
- **遇到失败，需要判断修复还是换路线** → `references/failure-routing.md`
- **修改本 Skill 或解释成熟度来源** → `references/patterns.md`

不要为了“全面”而一次加载所有 reference。

