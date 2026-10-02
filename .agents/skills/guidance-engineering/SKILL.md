---
name: guidance-engineering
description: >-
  设计、编写、审查和持续改进面向大语言模型与 Agent 的行为指导资产。
  覆盖 Principle / Workflow / Prompt / Example / Skill Construction / Case / Skill Evolution / Evaluation。
  不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: 从经验形成指导，并在真实使用中持续演化
---

# Guidance Engineering

## 核心

Guidance Engineering 处理两件事：

1. **把明确需求或真实工作经验压缩成可复用 Guidance / Skill；**
2. **让已经存在的 Skill 在真实使用中继续吸收经验并演化。**

Skill 不是一次创建完就“验证完成”的静态文档，而是会随着真实使用不断形成新经验的行为资产。

# 生命周期

## 创建

两个常见入口：

```text
用户明确要求创建 Skill
→ Skill Construction
→ Skill v0
```

或：

```text
已完成真实工作
→ 回顾上下文
→ 抽象可复用能力
→ Skill Construction
→ Skill v0
```

创建阶段的目标是得到**可独立理解、可实际使用的初始 Skill**，不是一次性证明其已经成熟。

见 [skill-building.md](references/skill-building.md)。

## 使用与演化

```text
Skill v0
→ Real Use
→ Usage Case
→ Skill Evolution
→ Candidate Change
→（必要时）Evaluation
→ Skill vNext
→ Real Use
→ ...
```

如果工作已经完成后才回顾经验：

```text
Historical Work Context
→ Replay Case
→ Skill Evolution
```

真实使用和真实历史是后续演化的主要素材。

# 信息层级

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
= 将 Guidance 与 supporting resources 封装成可发现能力

Case
= 尚未完全压缩的真实经验

Skill Evolution
= 把经验重新压缩进 Skill

Evaluation
= Evolution 在存在实质不确定性时使用的验证工具
```

# 执行入口

根据用户当前目标进入唯一主流程，不要自己重新拼装另一套：

```text
创建 Skill
→ [skill-building.md](references/skill-building.md)

修改 / 优化已有 Skill
→ [skill-evolution.md](references/skill-evolution.md)

记录真实使用或历史经验
→ [cases.md](references/cases.md)

设计 / 修改 Prompt
→ [prompt-engineering.md](references/prompt-engineering.md)

设计 Teaching Example / few-shot
→ [example-engineering.md](references/example-engineering.md)

Evolution 中需要验证 Candidate Change
→ [evaluation.md](references/evaluation.md)
```

## 用户明确创建或修改时

用户明确说“创建一个 Skill”时，创建决定已经成立：

- 不重新判断是否应该创建；
- 不用已有项目或成熟工具否决用户决定；
- 调研用于提高创建质量。

用户明确要求修改已有 Skill 时，同理直接进入 Skill Evolution，不重新要求用户证明“是否值得改”。

# Case

Case 是经验，不是规则。

```text
Real Use / Replay
→ Case
→ Skill Evolution
```

Case 自包含在所属 Skill repository 中，不建立跨 Skill 的集中 Case 仓库。

见 [cases.md](references/cases.md)。

# Skill Evolution

Skill Evolution 是创建之后的主要改进机制：

```text
Case / explicit change request
→ attribution
→ transferable change
→ Candidate Change
→ decide whether Evaluation is needed
→ update Skill
→ Skill vNext
```

见 [skill-evolution.md](references/skill-evolution.md)。

# Evaluation 的位置

Evaluation **不是 Skill 创建的必经阶段，也不是所有 Evolution 的必经阶段**。

只有 Candidate Change 存在实质不确定性时才进入：

```text
Candidate Change
→ optional Evaluation
→ result
→ back to Skill Evolution
```

优先使用 Usage Case / Replay Case 等真实素材。没有真实素材时，不为了满足形式要求凭空制造测试体系。

见 [evaluation.md](references/evaluation.md)。

# Prompt 与 Example

Prompt 的具体设计流程见 [prompt-engineering.md](references/prompt-engineering.md)。

Example 的具体设计流程见 [example-engineering.md](references/example-engineering.md)。

从真实 Case 形成 Example 时：

```text
Specific Case
→ abstract Principle / decision relation
→ new Generic Teaching Example
```

不要只匿名化原案例。

# Skill repository 原则

每个 Skill 文件夹：

- 自己 `git init`；
- 自己 commit；
- 自己保存 Case；
- 自己管理演变历史。

是否配置 GitHub / GitLab remote 是可选的。

Skill 应尽可能自包含，但不意味着把所有历史、所有上下文都加载进正常运行环境。

# Harness / Runtime 边界

Guidance 可以影响模型如何使用已有能力，但不能仅靠文本创造：

- Tool / Permission；
- Context window；
- Memory / Compaction；
- Sandbox；
- Agent loop；
- Runtime state。

这些属于 Harness / Runtime / Tool 层。

# 共同原则

- 真实工作是 Guidance 的主要来源。
- Skill 创建的完成条件是“可使用”，不是“已证明成熟”。
- 使用过程天然产生后续检验材料。
- Case 不自动成为 Rule。
- 先归因，再修改唯一 owner。
- 简单局部修复不强制 Evaluation。
- 要扩大规则适用范围或声称改善时，才考虑 Evaluation。
- 从具体经验抽象通用关系，再决定写入 Principle / Workflow / Prompt / Example / Skill boundary。
- 可机械保证的事情优先交给 schema、script、test、permission 或 runtime policy。
- 每个 Skill 保持自包含，并由自己的 Git history 管理演变。
