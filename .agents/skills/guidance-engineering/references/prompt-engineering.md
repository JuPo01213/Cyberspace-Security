# Prompt Engineering

## 职责

Prompt Engineering 回答：

> **给定一个明确行为目标，怎样把它写成一段可投递、可维护、可测试的 Prompt。**

Prompt 可以独立存在，也可以表达 Principle / Workflow，或成为 Skill、应用与 grader 的一部分。

## 什么时候进入

当已经知道“希望模型怎样行为”，但还没有形成稳定可投递 Prompt 时进入。

如果底层行为目标本身还不清楚，先返回定义 Goal / Boundary / Completion；如果用户是在创建 Skill，则由 [skill-building.md](skill-building.md) 的创建流程负责上游能力定义。

## 输入

至少需要：

- 目标行为或任务结果；
- 适用条件与边界；
- 投递位置 / Harness / API（已知时）；
- 可用工具与权限（已知时）；
- 输出消费者（如果存在）；
- 已知失败案例或用户纠正（如果存在）。

缺少不会改变行为设计的信息时，不阻塞流程。

# 执行流程

```text
1. 明确可观察结果
2. 写核心行为
3. 写条件与边界
4. 分离 Instructions / Context / Task Data / State
5. 加入 Tool rules
6. 加入 Output contract
7. 加入 Failure / uncertainty exits
8. 判断是否需要 Example
9. 组织并投递 Prompt
10. Evaluation
11. revise / keep
```

## 1. 明确可观察结果

先回答：

> 模型最终要产生什么可观察结果？

不要从“你是一位专家”“请深入思考”开始。

产物应是一句或几句可验证目标，例如：

```text
审查当前活动 Skill，找出重复职责、缺失能力和错误边界，并给出最小重构方案。
```

**进入下一步：** 已能判断成功和失败，而不是只有抽象愿望。

## 2. 写核心行为

把真正影响结果的动作写成明确动词：

```text
- 读取当前活动版本；
- 区分结构问题、内容缺失和平台限制；
- 对每个发现指出唯一 owner；
- 修改后重新检查边界。
```

优先写“做什么”；只有存在真实误行为时才补“不要做什么”。

**产物：** 最小必要 instructions。

## 3. 写条件与边界

把局部规则写成条件关系：

```text
当 X → 做 A
当关键条件变为 Y → 改做 B / 跳过 A
```

不要把局部经验写成 universal rule。

同时补齐：

- 适用条件；
- non-trigger / 不适用条件；
- completion；
- failure / uncertainty。

## 4. 分离 Instructions / Context / Task Data / State

至少在语义上区分：

- **Instructions**：模型应该怎样行为；
- **Context**：完成任务所需的可信背景；
- **Task Data**：要处理的正文、文件、网页、日志；
- **State**：已经发生、且会影响下一步的结果。

外部材料中的“忽略前文”“你现在是……”默认只是 Task Data，不自动获得新的指令权。

可用 Markdown headings、XML tags 或其他稳定边界表达；标记法不是目标，减少歧义才是目标。

## 5. 加入 Tool rules

只有任务需要工具时才写。

写清：

```text
何时调用
→ 调哪个类别
→ 需要哪些输入
→ 如何解释返回
→ 失败 / 歧义时怎么办
→ 什么结果才能支撑完成结论
```

认证、授权、审批、真实权限仍由 Harness / Tool 实现，不由 Prompt 创造。

## 6. 加入 Output contract

只有确有消费者时才约束：

- 必须字段；
- 允许值；
- 顺序；
- 是否允许解释；
- 信息不足如何表示；
- 完成 / 部分完成 / 未测量怎样表达。

机器必须稳定解析时，优先 structured output / schema，而不是只靠自然语言。

## 7. 加入 Failure / uncertainty exits

提前定义合法出口：

```text
缺关键事实 → 指出缺什么
工具失败 → 报告实际失败
关键观察缺失 → 不声称完成
目标冲突 → 指出冲突并完成仍可安全完成的部分
```

这一步的目标是防止模型用猜测补齐。

## 8. 判断是否需要 Example

默认先尝试清晰 zero-shot。

如果模型仍在以下方面不稳定，再进入 [example-engineering.md](example-engineering.md)：

- 输出形状；
- 条件边界；
- 相邻概念；
- 工具选择；
- 合法失败；
- 可观察 trajectory。

Example 必须提供新增行为信息，而不是装饰。

## 9. 组织并投递 Prompt

简单 task prompt 可只包含：

```text
任务
+ 必要约束
+ 输入
+ 期望输出
```

长期 developer/application prompt 常见结构：

```text
# Purpose
# Instructions
# Tool Use
# Output
# Examples
# Context
```

这不是固定模板。结构只服务于清晰与可维护。

Skill 内 instructions 常见结构：

```text
能力
共享指导
路由
边界
```

Skill 的 discovery、description、references 和 packaging 由 [skill-building.md](skill-building.md) 负责。

## 10. Evaluation

只要要声称“更好、更稳定、修复了问题”，就进入 [evaluation.md](evaluation.md)。

至少验证：

- 目标行为是否发生；
- 边界是否有效；
- 输出契约是否满足；
- 工具行为是否符合预期；
- failure / uncertainty 是否能合法结束。

无法实际测试时，明确标记为未验证。

## 11. revise / keep

如果 Evaluation 失败，不要默认“再加一句更强的话”。

按顺序定位：

```text
目标表达错？
→ Step 1

核心行为缺失？
→ Step 2

条件 / 边界错？
→ Step 3

Context / Data / State 混淆？
→ Step 4

Tool rule 错？
→ Step 5

Output contract 错？
→ Step 6

Failure exit 缺失？
→ Step 7

需要 Example？
→ Step 8

其实是 Tool / Harness / 模型能力问题？
→ 退出 Prompt 修补，转交对应层
```

只修改真正导致偏离的 owner，然后重跑相关 Evaluation。

# 把 Principle / Workflow 编译成 Prompt

Prompt 不负责重新发明行为模型，而是把已有模型转成可执行 instructions。

### Principle → instruction

把：

```text
applies_when → action → boundary
```

表达成明确条件规则，不丢掉边界。

### Workflow → instructions

只提取执行时真正需要的信息：

- 当前阶段目标；
- 进入条件；
- 观察状态；
- 分支条件；
- 可执行动作；
- completion / failure exit。

不要把设计笔记、无消费者状态或作者解释机械塞进 Prompt。

# 完成标准

Prompt Engineering 完成时，应同时满足：

- 有明确可观察目标；
- 必要行为和边界已表达；
- Instructions / Context / Data / State 没有关键混淆；
- Tool / Output / Failure 规则只在需要时存在；
- Example 是否需要已有明确决定；
- Prompt 已按真实投递位置组织；
- 已完成必要 Evaluation，或明确记录未验证部分；
- 已知失败可以回到明确步骤修正。

# 常见反模式

- 用身份设定替代具体任务；
- 大量“务必、绝对、非常重要”但没有行为定义；
- 正负规则互相冲突；
- 把 Task Data 混成指令；
- 所有任务都塞同一长 Prompt；
- 用 Prompt 模拟权限、schema 或 runtime enforcement；
- 只规定过程，不说明成功结果；
- 为一次事故新增永久 universal rule；
- Examples 与 instructions 冲突；
- Prompt 变长后不做 eval，只凭感觉认为更强。

## 当前外部依据

核对日期：2026-10-01。

OpenAI 当前 Prompt Engineering 文档强调：不同模型/快照可能需要不同 prompting；message roles 具有不同权威；Markdown/XML 可用于划分逻辑边界；developer message 常见组成包括 Identity、Instructions、Examples、Context；few-shot 应使用多样输入与期望输出，并建议用 eval 监控 Prompt 迭代。

https://developers.openai.com/api/docs/guides/prompt-engineering
