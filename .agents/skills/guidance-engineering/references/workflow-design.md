# Workflow Design

## 职责

Workflow Design 只回答：

> **行为怎样分阶段、分支、推进、验证和停止。**

Prompt 负责表达，Workflow 负责结构。Workflow 可以只服务一次任务，也可以被 Skill 封装。

## Behavior Contract：正式归属

Guidance Engineering 中，正式的行为契约只在这里定义。

按需要使用这些字段：

```yaml
goal: 最终结果
trigger: 何时进入流程
inputs: 所需输入
required: 必须发生的行为或结果
prohibited: 当前条件下不可发生的偏离
conditional: 条件动作
state: 会改变下一步的状态
dependencies: 前置与后置条件
completion: 可观察完成证据
failure_exit: 缺失、冲突或工具失败时的合法出口
consumer: 谁使用结果
risk: 失败影响、可逆性和恢复要求
```

不是所有 Workflow 都必须填满字段；只保留会改变决策的内容。

Prompt 和 Evaluation 可以引用该 contract，但不要各自维护另一套同义 schema。

## 设计流程

### 冻结 Goal

Goal 是结果；Policy 是行动偏好。

“少创建文件”“先搜索”“多验证”通常是 Policy，不是 Goal。Policy 可以随风险、用户要求和环境变化，不能吞掉完成条件。

### 划分最少阶段

只在状态或决策真的发生变化时划分阶段。

可以用：

```text
Frame → Acquire → Decide → Act → Verify → Close
```

作为思考骨架，但它不是固定模板；能删则删，能合则合。

### 按事实分支

分支条件必须是可观察事实，例如：

- 是否已有可信证据满足后置条件；
- 风险是否高到需要恢复证据；
- 目标是否仍未确定；
- 工具是否可用；
- 权限是否足够。

不要按“看起来专业”或题材名称分支。

### 只保存必要状态

状态存在的唯一理由是改变下一步动作。没有消费者的状态字段不进入 Workflow。

### 定义完成与失败出口

每条主路径都应知道：

- 什么证据表示完成；
- 什么情况允许跳过；
- 什么情况必须停止；
- 何时返回非完成状态，而不是猜测或假完成。

## Workflow 的落地

LLM 主导执行时，用 [prompt-engineering.md](prompt-engineering.md) 把关键阶段、条件和出口表达成指导。

需要示范决策或可观察工具轨迹时，用 [example-engineering.md](example-engineering.md)。

Workflow 稳定复用、需要独立触发或 supporting resources 时，再由 [skill-building.md](skill-building.md) 封装。

## 验证

只要声称某个阶段、分支、顺序或停止条件是必要改进，就交给 [evaluation.md](evaluation.md) 测量；Workflow 文件本身不定义测试方法。
