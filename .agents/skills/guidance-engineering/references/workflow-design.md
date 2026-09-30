# Workflow Design

## 定位

Workflow Design 负责回答：

> **当目标不能由单一指令稳定完成时，行为应该怎样组织、分支、推进、验证和停止。**

Prompt 解决表达；Workflow 解决结构。

Workflow 可以存在于一次性任务中，也可以成为 Skill 内部的主流程。不要因为有 Workflow 就自动创建新 Skill。

## 行为契约

设计 Workflow 前先固定：

```yaml
goal: 最终结果
trigger: 什么条件进入流程
inputs: 需要什么输入
required: 必须发生的行为
prohibited: 不可发生的偏离
conditional: 条件动作
state: 哪些状态影响下一步
dependencies: 前置与后置条件
completion: 可观察完成证据
failure_exit: 缺失、冲突、工具失败时的出口
consumer: 谁使用结果
risk: 失败影响、可逆性和恢复要求
```

目标是结果；策略是偏好。不要把“少创建文件”“多验证”“先搜索”之类策略写成目标本身。

## 设计主流程

优先形成最短能完成任务的主链：

```text
Frame
→ Acquire
→ Decide
→ Act
→ Verify
→ Close
```

这只是抽象骨架，不是固定六步模板。真实 Workflow 可以删减、合并或改变顺序。

每一步必须回答：

- 为什么存在；
- 消费什么输入；
- 产出什么状态；
- 哪个条件进入下一步；
- 什么条件允许跳过；
- 什么情况必须停止或回退。

## 分支与状态

需要分支时，按**会改变决策的事实**分支，而不是按题材或工具名分类。

例如：

```text
如果已有可信证据满足后置条件
→ 不重复验证

如果风险高且需要恢复
→ 增加备份 / 完整性证据

如果目标仍未确定
→ 继续调查或请求最小澄清
```

状态只保存会影响后续动作的信息，不为了形式制造状态机。

## Goal 与 Policy

Goal 是成功条件。

Policy 是行动偏好。

例如：

```text
Goal:
完成指定迁移，并让目标系统可用。

Policy:
优先最小充分修改。

Boundary:
若任务明确要求审计或恢复，增加对应产物。
```

Policy 不能替代 Goal，也不能在条件变化后阻止合理反转。

## Workflow 与 Prompt

Workflow 最终仍需要通过 Prompt / code / tool orchestration 等方式落地。

如果由 LLM 主导执行，Workflow guidance 应把关键阶段、状态、分支和停止条件表达给模型；具体措辞回到 [prompt-engineering.md](prompt-engineering.md)。

不要把流程图本身当成已经有效的 Prompt。

## Workflow 与 Skill

当 Workflow 已经：

- 对一类任务稳定复用；
- 有明确触发边界；
- 需要支持资料或脚本；
- 值得长期维护；

再由 [skill-building.md](skill-building.md) 封装成 Skill。

多个紧密相关 Workflow 可以由一个 Skill 内部路由。理论上不同不等于必须拆成多个 Skill。

## 行为设计原则

- 理解不等于授权。
- 动作必须服务当前契约。
- 每个禁止项都应保留合理反转边界。
- 风险只改变确认、保护和验证强度，不凭空改写用户目标。
- 自评、命令成功、文件存在都只有和完成条件绑定后才是证据。
- 规则冲突时保留更高层真实约束，不通过继续加规则掩盖冲突。
- 可机械执行的不变量优先进入 script / schema / test，而不是长期依赖自然语言。

## 何时进入 Evaluation

只要你声称：

- Workflow 比旧方案更好；
- 某分支修复了失败；
- 某阶段顺序是必要的；
- 某停止条件降低了误行为；

就需要 [evaluation.md](evaluation.md) 的行为证据，而不是依赖设计直觉。
