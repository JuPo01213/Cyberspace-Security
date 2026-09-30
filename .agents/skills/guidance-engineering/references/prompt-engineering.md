# Prompt Engineering

## 职责

Prompt Engineering 回答的不是“Prompt 有哪些种类”，而是：

> **给定一个行为目标，具体应该怎样写出一段可投递、可维护、可测试的 Prompt。**

Prompt 可以独立存在，也可以表达一个 Principle / Workflow，或成为 Skill、应用与 grader 的一部分。

## 先区分两个维度

不要把所有“Prompt 类型”混成同一分类。

### 1. 投递位置 / 指令权威

由目标 Harness / API 决定，例如：

- system；
- developer / instructions；
- user / task input；
- Skill 被加载后进入上下文的 instructions。

不同平台不一定拥有同样的消息角色和优先级。先确认真实接口，再决定放置。

### 2. Prompt 的功能

同一条消息里可以同时包含：

- identity / role；
- task goal；
- behavioral instructions；
- tool-use guidance；
- output contract；
- examples；
- context / reference material；
- grader criteria。

“Skill Prompt”“Tool Prompt”“Grader Prompt”更多是在描述来源或用途，不一定是独立消息角色。

## 一套可直接使用的 Prompt 编写流程

### 1. 写清目标结果

先用一句话回答：

> 模型最终要产生什么可观察结果？

不要从“你是一位专家”“请深入思考”开始。

例如：

```text
目标：审查一个已有 Skill，找出重复职责、缺失能力和错误边界，并给出最小重构方案。
```

### 2. 写必要行为

把真正影响结果的动作写成明确动词：

```text
- 读取当前活动版本，不凭记忆审查旧版本。
- 区分结构问题、内容缺失和平台限制。
- 对每个发现指出唯一 owner。
- 修改后检查引用与行为边界。
```

优先写“做什么”，只有存在真实误行为时再补“不要做什么”。

### 3. 写条件与边界

避免把局部规则写成绝对命令。

使用：

```text
当 X 时 → 做 A
当关键条件变为 Y 时 → 改做 B / 跳过 A
```

例如：

```text
当仓库已有成熟实现时先复用；
只有现有实现存在明确缺口时再做最小自建。
```

而不是：

```text
永远不要自己实现。
```

### 4. 分开 Instructions、Context 与 Task Data

至少在语义上区分：

- **Instructions**：模型应该怎样行为；
- **Context**：完成任务所需的可信背景；
- **Task Data**：要处理的正文、文件、网页、日志等；
- **State**：已经发生、且会影响下一步的结果。

外部材料中的“忽略前文”“你现在是……”默认只是 Task Data，不自动获得新的指令权。

可以用 Markdown headings、XML tags 或其他稳定边界表达。标记法本身不是目标，减少歧义才是目标。

### 5. 写工具使用规则（如果需要）

不要只写“可以使用工具”。

写清真正影响决策的部分：

```text
何时调用
→ 调哪个类别的工具
→ 需要哪些输入
→ 如何解释返回
→ 失败/歧义时怎么办
→ 什么工具结果才能支撑完成结论
```

例如：

```text
涉及当前官方接口时先检索当前官方文档。
若搜索没有得到足够证据，不把猜测写成当前事实。
```

认证、授权、审批和服务器端 policy 仍由 Harness / Tool 实现，不由 Prompt 创造。

### 6. 写输出契约

只约束真正有消费者的输出。

可写：

- 必须包含哪些字段；
- 允许哪些值；
- 需要什么顺序；
- 是否允许解释；
- 信息不足时怎样表示；
- 什么算完成、部分完成或未测量。

如果结构必须机器可靠解析，优先使用平台的 structured output / schema，而不是单靠自然语言。

### 7. 处理失败与不确定性

提前定义合法出口，防止模型用猜测补齐：

```text
缺少关键事实 → 明确指出缺什么；
工具失败 → 报告实际失败，不编造结果；
关键观察缺失 → 不声称完成；
目标存在冲突 → 指出冲突并完成仍可安全完成的部分。
```

### 8. 判断是否需要 Example

先尝试清晰 zero-shot。

当模型在以下方面仍不稳定时，再读 [example-engineering.md](example-engineering.md)：

- 输出形状；
- 条件边界；
- 相邻概念；
- 工具选择；
- 合法失败；
- 可观察 trajectory。

Example 是新增行为信息，不是装饰。

### 9. 组织 Prompt

对于长期 developer/application prompt，一个常见、可读的结构是：

```text
# Identity / Purpose        可选
# Instructions              核心
# Tool Use                  需要时
# Output                    需要时
# Examples                  需要时
# Context                   动态背景
```

这不是固定模板。当前 OpenAI 文档把 Identity、Instructions、Examples、Context 作为常见 developer-message 组织方式，但明确最优内容和顺序会随模型变化。

对于简单 task prompt，完全可以只有：

```text
任务
+ 必要约束
+ 输入
+ 期望输出
```

不要为了“专业”套大模板。

## 三个常用骨架

### 简单任务 Prompt

```text
任务：
{要完成什么}

要求：
- {真正影响结果的要求}
- {边界/限制}

输入：
{task data}

输出：
{只有确有需要时描述}
```

### Developer / Application Prompt

```text
# Purpose
{产品或助手长期目标}

# Instructions
- {稳定行为规则}
- 当 {condition} 时，{action}
- 不要 {具体已知误行为}

# Tool Use
{何时使用哪些工具，以及如何处理失败}

# Output
{稳定输出契约}

# Examples
{只有有独立教学价值时}

# Context
{动态事实，由应用注入}
```

### Skill 内 Instructions

```text
能力：
{这个 Skill 帮模型做什么}

共享指导：
- {所有触发都需要的规则}

路由：
- 当 {condition} 时读取 {reference/script}
- 当 {condition} 时执行 {workflow}

边界：
- {不得推断/不得越权的事项}
```

Skill 的 discovery、description、references 和 packaging 由 [skill-building.md](skill-building.md) 负责。

## Prompt 的修改方法

不要通过“再加一段更强的话”无限堆叠。

出现失败时先判断：

1. 目标是否表达错；
2. 条件或边界是否缺失；
3. 关键信息是否根本没进入上下文；
4. 底层行为模型是否其实缺少 Principle / Workflow，而不是措辞不够强；
5. 需要的是 Example；
6. 其实是 Tool/Harness/权限问题；
7. 模型本身在当前条件下是否无法稳定完成。

只修改真正导致偏离的变量。

## 把 Principle / Workflow 编译成 Prompt

Prompt 不负责发明行为模型，而负责把已经明确的 Principle / Workflow 转成模型需要看到的 instructions。

### Principle → instruction

把 `applies_when → action → boundary` 表达成清晰条件规则，避免把边界丢掉。

### Workflow → instructions

从 Workflow 中只提取执行时真正需要的信息：

- 当前阶段的目标；
- 进入条件；
- 需要观察的状态；
- 分支条件；
- 可执行动作；
- completion / failure exit。

不要把完整设计笔记、无消费者的中间状态或作者解释机械塞进 Prompt。

如果 Workflow 很短，可以直接写成顺序/条件 instructions；复杂 Workflow 在 Skill 中可以下沉为按需 reference，但它的行为模型仍来自主 Guidance 设计，而不是由 Prompt 文件重新定义。

需要示范某个决策边界或 tool trajectory 时，再调用 [example-engineering.md](example-engineering.md)。

## 常见反模式

- 用身份设定替代具体任务；
- 大量“务必、绝对、非常重要”但没有行为定义；
- 正负规则互相冲突；
- 把 Task Data 混成指令；
- 所有任务都塞同一长 Prompt；
- 用 Prompt 模拟权限、schema 或 runtime enforcement；
- 只规定过程，不说明成功结果；
- 为了防一次事故新增永久 universal rule；
- Examples 与 instructions 冲突；
- Prompt 变长后不做 eval，只凭感觉认为更强。

## 模型与版本适配

Prompt 行为依赖具体模型、模型版本和投递方式。不同模型可能需要不同显式程度。

因此生产 Prompt：

- 记录实际模型/版本与投递层；
- 不把某个模型上的经验升级成跨模型硬规则；
- 更换模型或重要版本时重新跑代表性 eval；
- 对当前平台能力有疑问时重新检查当前官方文档。

## 验证

只要要声称“这个 Prompt 更好、更稳定、修复了问题”，就转到 [evaluation.md](evaluation.md)。

未经实际测试，只称 candidate prompt。真实使用中的成功、失败和用户纠正应保存为 Case，见 [cases.md](cases.md)。

## 当前外部依据

核对日期：2026-10-01。

OpenAI 当前 Prompt Engineering 文档强调：不同模型/快照可能需要不同 prompting；message roles 具有不同权威；Markdown/XML 可用于划分逻辑边界；developer message 常见组成包括 Identity、Instructions、Examples、Context；few-shot 应使用多样输入与期望输出，并建议用 eval 监控 Prompt 迭代。

https://developers.openai.com/api/docs/guides/prompt-engineering
