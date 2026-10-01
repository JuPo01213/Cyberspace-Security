---
name: guidance-engineering
description: >-
  设计、编写、审查和持续改进面向大语言模型与 Agent 的行为指导资产。
  覆盖 Principle / Workflow / Prompt / Example / Skill Construction / Case / Evolution。
  不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: 从经验到指导，再从使用中持续演化
---

# Guidance Engineering

## 核心

Guidance Engineering 只回答：

> 如何把经验压缩成可复用指导，并在真实使用中持续修正它。

Skill 不是一次创建完成的静态文档，而是会随着使用产生反馈并演化的行为资产。

## 核心生命周期

```text
真实工作
  ↓
抽象 Skill
  ↓
Skill Usage
  ↓
Case
  ↓
Skill Evolution
  ↓
Candidate Change
  ↓
（必要时）Evaluation
  ↓
Skill vNext
```

## 信息层级

```text
Principle
= 条件、行为与边界

Workflow
= 阶段、状态、转移与停止

Prompt
= 用语言表达行为模型

Example
= 用示范具体化行为模型

Skill
= 将 Guidance 与资源封装成可发现能力
```

Prompt：见 [prompt-engineering.md](references/prompt-engineering.md)

Example：见 [example-engineering.md](references/example-engineering.md)

Skill 创建：见 [skill-building.md](references/skill-building.md)

## Case

Case 是真实使用产生的经验载体，不是规则本身。

```text
Skill
→ Real Use
→ Case
→ Evolution
```

见 [cases.md](references/cases.md)

## Skill Evolution

Skill Evolution 负责已经存在 Skill 的持续成长。

两个入口：

1. 真实使用反馈

```text
Skill 使用
→ 结果 / 用户纠正 / 边界
→ Case
→ 演化
```

2. 历史上下文回溯

```text
完整工作上下文
→ 提取关键决策
→ Replay Case
→ 抽象 Skill 或改进 Skill
```

见 [skill-evolution.md](references/skill-evolution.md)

## Evaluation 的位置

Evaluation 不是 Skill 创建的必经阶段。

它只是 Candidate Change 不确定时的验证工具：

```text
Candidate Change
→ Evaluation
→ keep / revise / reject
```

见 [evaluation.md](references/evaluation.md)

## 执行入口

```text
创建 Skill
→ skill-building.md

修改已有 Skill
→ skill-evolution.md

记录使用经验
→ cases.md

设计 Prompt
→ prompt-engineering.md

设计 Example
→ example-engineering.md

验证候选变化
→ evaluation.md
```

## 边界

Guidance 只能影响模型对已有能力的使用，不能创造：

- Tool / Permission
- Context window
- Memory / Compaction
- Sandbox
- Agent loop
- Runtime state

这些属于 Harness / Runtime 层。

## 原则

- 真实工作是 Skill 的来源。
- 使用过程天然提供检验材料。
- Case 不自动成为规则。
- 从具体案例抽象通用原则，再由通用原则构造 Example。
- Evaluation 服务于 Evolution，而不是驱动 Skill 创建。
- 每个 Skill 保持自包含，并由自己的 Git history 管理演变。
