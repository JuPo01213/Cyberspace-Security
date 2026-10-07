# Prompt 重构架构

本目录保存从第一性原理重新划分后的 Agent 运行规则。当前版本直接取代旧模块；历史由 Git 保存，不维护平行 V2 权威源。

## 运行结构

```text
Goal Model          当前要达到什么
Epistemic State     当前相信什么、凭什么
Decision Authority  谁有权决定什么
Capability State    当前通过什么方式能够行动
        \           |           /
         \          |          /
          ---- Execution Control ----
                    |
                  Action
                    |
          Observation / Feedback
                    |
             更新对应状态

Communication 是面向用户的独立协作协议：
当 Execution Control 选择“沟通”这一行动时，
由 Communication 约束沟通内容、表达和信息边界。

Shared Memory 是跨会话、跨 Agent 的持久认知层：
只保存已经发生、明确形成或得到确认且具有长期价值的事实，
不替代运行时 Epistemic State。

Git Governance 是长期资产的版本治理层：
定义 Git 应如何维护当前权威状态与历史演化，
具体何时初始化、分支、使用 worktree 等由 Execution Control 决定。
```

## 语义所有权

每一种状态、判断和规则只在一个模块中定义。其他模块可以读取和消费，不重新定义。

- `goal-model`：目标、约束、偏好、成功条件及其当前解释。
- `epistemic-state`：事实、假设、证据、逻辑关系与认识状态变化。
- `decision-authority`：用户与 Agent 分别拥有何种判断权。
- `capability-state`：已有、可获得、适用或缺失的能力。
- `execution-control`：依据以上状态选择行动、分配资源、组织依赖、并行、等待、计划与停止；包括决定何时调用 Git 隔离能力。
- `communication`：沟通行动如何向用户投影状态、请求信息或决策，并控制表达成本。
- `shared-memory`：跨 Agent 持久保存当前仍然有效、已经确认且具有长期价值的事实；运行时假设、冲突和未确认判断仍由 `epistemic-state` 维护。
- `git-governance`：长期资产的 Git 治理原则、当前权威版本与历史边界，以及 Git 能提供的版本与隔离能力；不负责具体调度。

Few-shot 用于展示规则在现实任务中的行为形态，不承担新的语义定义。若案例与 prompt 冲突，以 prompt 为准。

高风险、不可逆操作、外部副作用与授权门禁后续单独维护，不混入当前模块。
