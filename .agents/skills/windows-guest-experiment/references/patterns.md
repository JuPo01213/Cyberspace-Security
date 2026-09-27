# 设计依据与成熟度边界

本文件用于维护 Skill 时解释“为什么这样分层”，普通分析任务不必读取。

## Skill 的职责

当前结构遵循渐进披露：

- `SKILL.md`：只保存会改变 Agent 路线选择的通用原则；
- `runbook.md`：成熟能力缺失/损坏时的路由；
- 其他 references：仅在选择对应能力时读取；
- scripts：只保留真正需要重复、确定化执行的辅助代码。

不要把一次事故继续堆进 `SKILL.md`。

## 成熟组件与组合成熟度

需要严格区分：

- FLARE-VM：成熟的 Windows 逆向/恶意软件分析环境建设方案；
- Microsoft DbgEng / WinDbg / DbgSrv：成熟的 Windows 调试基础设施；
- Procmon：成熟的 Windows 行为观测工具；
- Noriben：长期使用的 Procmon 辅助分析工具；
- FakeNet-NG：成熟的动态网络分析组件；
- CAPEsolo：CAPE 生态中的 Windows standalone runtime，提供 MCP 和交互式 debugger，但相较上述老牌基础组件更年轻。

**这些组件分别成熟，不等于本 Skill 选择的组合已经成为行业统一标准。**

组合是否可作为默认能力，必须经过当前环境的端到端验证。

## 核心架构原则

```text
任务契约 / 证据要求
        ↓
通用分析流程
        ↓
runtime / tool capability
        ↓
虚拟化、通信和 GUI 后端
        ↓
本机绑定与动态运行事实
```

Host 不应因为 Guest 回滚而丢失长期状态；Guest 不应为了方便而承载整个 Agent 工作区。

依赖方向不能反转：低层平台、已安装工具、现成 VM 和单次任务事实都不能定义高层语义。通用 Skill 保存能力契约和路由；部署环境保存机器、地址、凭据和 provider 绑定；项目保存任务特有规则；run record 保存动态事实。

## 为什么不自建 workflow engine

如果成熟 runtime 已经提供 task、completion、artifact 或 retry，再维护一套 STATE、runner、done marker、轮询协议只会制造双重权威。checkpoint / restore 只有在 runtime 明确声明并验证由其管理时才归 runtime；否则属于基础设施后端。

只有成熟 runtime 明确不覆盖的动作才适合做薄适配。

