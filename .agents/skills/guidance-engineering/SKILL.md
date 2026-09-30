---
name: guidance-engineering
description: >-
  设计、编写、审查、评估和演进面向大语言模型与 Agent 的行为指导资产。
  覆盖 Prompt Engineering、Example Engineering、Skill Construction、Evaluation 与 Evolution，
  并处理 Prompt/Skill 中的复杂 Workflow 组织；不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: Prompt、Workflow 与 Skill 的指导工程
---

# Guidance Engineering

## 核心模型

Guidance Engineering 处理六类对象，但它们不处在一条强制流水线上。

### 设计对象

```text
Prompt
= 如何把要求表达给模型

Workflow
= 当行为变复杂时，在 Prompt/Skill 中组织阶段、状态、分支、推进与停止的结构；它不是本 Skill 中独立的知识域

Example
= 如何用具体示范塑造行为

Skill
= 如何把相关 Guidance 与资源封装成可发现、可复用能力
```

### 生命周期

```text
Evaluation
= 如何测量某个 Prompt / Workflow / Example / Skill 是否真的有效

Evolution
= 如何根据证据创建、修改、合并、删除或升格 Guidance
```

正确关系更接近：

```text
行为需求
├── Prompt                    几乎总会有某种表达
│   └── Workflow structure    多步/状态/分支复杂时才需要
├── Example                   示范有独立信息价值时才需要
└── Skill                     需要可发现、可复用封装时才需要

任何候选 Guidance
→ Evaluation
→ keep / revise / reject
→ Evolution 维护
```

不要把它机械理解成“先 Prompt，再 Workflow，再 Skill，最后才能 Eval”。

## 共同起点：先明确要指导什么行为

在选择 Prompt、Workflow、Example 或 Skill 之前，先明确最低充分的行为要求：

- **goal**：最终希望发生什么；
- **scope / conditions**：什么条件下适用；
- **required**：必须发生什么；
- **prohibited**：当前条件下不能发生什么；
- **completion evidence**：从哪里看出目标真的完成；
- **failure / uncertainty**：信息不足、冲突或工具失败时允许怎样结束；
- **environment**：当前模型、Harness、工具和权限真实提供什么。

这是所有 Guidance 的共同输入，不是一个必须长期保存的新文件格式。

如果行为进一步涉及阶段、状态、依赖、分支或恢复，就在 Prompt Engineering 中使用“复杂行为 / Workflow”方法组织它；不为这个概念单独维护一套参考文件。

## 两条常见工作路径

### 从明确需求直接设计

当目标和边界本来就清楚：

```text
行为要求
→ 写 Prompt
→ 必要时在 Prompt/Skill 内组织 Workflow
→ 必要时加入 Example
→ 如需长期复用则封装 Skill
→ Evaluation
```

### 从真实经验固化

当用户在使用过程中发现“这个经验值得以后复用”：

```text
Specific Observation / Case
→ Mechanism Candidate
→ General Principle Candidate
→ 选择合适的 Guidance 载体
→ 若示范有价值，从 Principle 重新生成 Generic Teaching Example
→ Candidate Prompt / Skill（其中可包含 Workflow structure）
→ 独立 Evaluation
→ merge / promote / revise / reject
```

关键要求：

- 具体案例不是原则；
- 匿名化原案例不等于抽象；
- General Principle 必须保留适用条件和反转边界；
- Teaching Example 用来教，不能自己证明原则正确；
- 新 Skill 不是默认结果，先检查是否已有合适 owner。

## 与 Harness / Runtime 的边界

Harness / Runtime 提供上下文装配、工具暴露、状态、sandbox、Skill discovery/loading 和执行循环等运行机制。

Guidance 可以影响模型如何使用已有能力，但不能仅靠文本创造或改变：

- 工具与权限；
- context window；
- memory / compaction 实现；
- sandbox；
- agent loop；
- 运行时状态机制。

问题实际属于这些层时，转交 Harness / Runtime / Tool 工程。

## 唯一归属

| 对象 | 权威位置 |
| --- | --- |
| Prompt 分类、结构、具体写法、上下文组织 | [prompt-engineering.md](references/prompt-engineering.md) |
| Prompt 内的阶段、状态、分支、依赖、完成/失败路径 | [prompt-engineering.md](references/prompt-engineering.md) 的复杂行为 / Workflow 部分 |
| Teaching Example / few-shot | [example-engineering.md](references/example-engineering.md) |
| Skill 能力边界、触发、目录与资源封装 | [skill-building.md](references/skill-building.md) |
| Observation / Development Case / Eval Case | [evaluation/case-engineering.md](references/evaluation/case-engineering.md) |
| 测量、baseline/variant、判定 | [evaluation.md](references/evaluation.md) |
| Principle 提炼、经验升格、资产维护 | [evolution.md](references/evolution.md) |

其他文件只引用，不复制第二套同义规则。

## 路由

- “帮我写/改/审这个提示词” → [prompt-engineering.md](references/prompt-engineering.md)。
- “这套行为有多步、分支、状态或失败恢复” → [prompt-engineering.md](references/prompt-engineering.md) 的复杂行为 / Workflow 部分。
- “这个规则需要示例才能讲清楚” → [example-engineering.md](references/example-engineering.md)。
- “这个经验值得固化成 Skill / 帮我创建或重构 Skill” → [skill-building.md](references/skill-building.md)，并按需调用 Evolution / Prompt / Workflow / Example / Evaluation。
- “从这次真实失败抽象可复用经验” → [evaluation/case-engineering.md](references/evaluation/case-engineering.md) + [evolution.md](references/evolution.md)。
- “这次改动真的更好吗” → [evaluation.md](references/evaluation.md)。

只加载当前任务需要的最窄分支。

## 共同原则

- 先解决行为问题，再选择载体。
- 最小充分：简单 instruction 能解决就不引入流程结构；已有 Skill 能承载就不新建 Skill。
- 成熟方法优先：先检查目标生态当前官方能力、成熟工具和已有资产。
- 一个语义一个主要 owner。
- Evidence 不自动等于 Instruction。
- 可由 schema、script、test、permission 或 runtime policy 确定性保证的，不长期依赖自然语言提醒。
- 未经 Evaluation 的新 Guidance 只能称 candidate。
- 用户当前明确要求、真实平台能力与工具返回优先于默认指导。
