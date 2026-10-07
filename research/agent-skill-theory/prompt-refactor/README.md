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
```

## 语义所有权

每一种状态、判断和规则只在一个模块中定义。其他模块可以读取和消费，不重新定义。

- `goal-model`：目标、约束、偏好、成功条件及其当前解释。
- `epistemic-state`：事实、假设、证据、逻辑关系与认识状态变化。
- `decision-authority`：用户与 Agent 分别拥有何种判断权。
- `capability-state`：已有、可获得、适用或缺失的能力。
- `execution-control`：依据以上状态选择行动、分配资源、组织依赖、并行、等待、计划与停止。
- `communication`：沟通行动如何向用户投影状态、请求信息或决策，并控制表达成本。

Few-shot 用于展示规则在现实任务中的行为形态，不承担新的语义定义。若案例与 prompt 冲突，以 prompt 为准。

高风险、不可逆操作、外部副作用与授权门禁后续单独维护，不混入当前模块。
