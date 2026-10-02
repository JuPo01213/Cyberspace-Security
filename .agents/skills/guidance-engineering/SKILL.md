---
name: guidance-engineering
description: >-
  从 requirement、真实工作经验、对话记录、Case 等 Source 中理解并抽象可迁移行为，
  形成 Prompt / Workflow / Example / Skill，并让已有 Skill 在真实使用中持续演化。
  不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: Source → Understand → Abstract → Guidance → Use → Evolve
---

# Guidance Engineering

## 核心模型

Guidance Engineering 的核心不是“写 Prompt”或“整理对话”，而是：

> **把 Source 中真正决定行为的可迁移关系压缩成 Guidance，并在新经验出现时继续修正这种压缩。**

统一主链：

```text
Source
→ Understand
→ Abstract
→ Capability
→ Guidance
→ Package as Skill
→ Real Use
→ New Experience
→ Evolve
↺
```

不同输入不需要不同创建算法。

Source 可以是：

- 明确 requirement；
- 当前真实工作；
- 历史对话 / 日志 / 文件变化；
- 用户纠正；
- Case；
- 已有 Prompt / Workflow / Skill；
- 外部成熟实践。

## 第一原则：Source 不是 Guidance

尤其当 Source 是工作对话时，不要：

```text
Conversation
→ summarize
→ SKILL.md
```

应先：

```text
Conversation / Work Record
→ reconstruct what actually happened
→ identify why decisions changed
→ separate local details
→ extract transferable relations
→ define Capability
→ Guidance / Skill
```

对话顺序不是 Workflow。

某次工具选择也不是 Principle。

匿名化原案例也不是抽象。

真正值得压缩的是：

```text
conditions / observations
→ decision
→ action
→ completion / stop
```

# 信息层级

```text
Source
= requirement、真实经验或其他输入材料

Understand
= 恢复 Source 的真实目标、条件、行为和结果

Abstract
= 去掉偶然细节，提取可迁移决策关系

Capability
= Goal / Trigger / Inputs / Decisions / Boundary / Completion / Failure

Principle
= 条件 → 行为 → 边界

Workflow
= 阶段 / 状态 / 转移 / completion / stop

Prompt
= Guidance 的语言表达

Example
= Guidance 的教学示范

Skill
= Guidance 与 supporting resources 的可发现封装

Case
= 值得保留的经验 / provenance，不是能力本身

Evaluation
= 当某次 Candidate Change 存在实质不确定性时的验证工具

Git history
= Skill 的版本演变
```

# 执行入口

## 创建 Skill

无论 Source 是一句 requirement 还是一整段工作记录，都进入：

→ [skill-building.md](references/skill-building.md)

关键顺序：

```text
Source
→ Understand / Reconstruct
→ Abstract
→ Capability
→ Guidance
→ Skill
```

如果用户提供一段对话并要求“从这里做一个 Skill”，**第一动作是重建真实工作，不是先写 SKILL.md，也不是先创建 Replay Case。**

## 修改 / 优化已有 Skill

→ [skill-evolution.md](references/skill-evolution.md)

```text
New Source / Experience
→ Understand
→ Abstract
→ Compare with current Skill
→ Candidate Change
→ optional Evaluation
→ Skill vNext
```

## 保存经验或来源证据

→ [cases.md](references/cases.md)

Case 是旁路证据资产：

```text
                    ┌→ Skill / Skill vNext
Understanding       ┤
                    └→ Case（值得未来追溯时）
```

不要把 Case 变成所有创建和演化的强制中间层。

## 设计 Prompt

→ [prompt-engineering.md](references/prompt-engineering.md)

## 设计 Teaching Example / few-shot

→ [example-engineering.md](references/example-engineering.md)

## 验证不确定 Candidate Change

→ [evaluation.md](references/evaluation.md)

Evaluation 只在 Construction / Evolution 已经形成明确 claim，且是否正确存在实质不确定性时使用。

# 从工作记录重建能力

当 Source 是真实工作记录时，Understand 阶段至少恢复：

```text
Goal
Constraints
Initial approach
Observations
Failures / friction
User corrections
Tool / method changes
Key decisions
Successful path
Completion
```

最重要的问题不是“发生了哪些步骤”，而是：

> **什么观察导致了什么决策变化，为什么新的行为比原行为更适合？**

然后把内容分成：

```text
Facts
Local details
Transferable relations
```

用反事实检查抽象：

> 如果把项目名、品牌、文件名、工具名和题材换掉，这个关系仍然成立吗？

只有仍然成立、并真正改变未来行为的关系，才有资格进入 Capability / Guidance。

# Skill Construction

Construction 的目标是：

> **得到可独立理解、可实际使用的 Skill v0。**

不是：

> 创建时一次性证明它已经成熟。

创建完成后：

```text
Skill v0
→ Real Use
```

真实使用天然产生后续检验材料。

# Skill Evolution

Evolution 和 Construction 共享：

```text
Source
→ Understand
→ Abstract
```

Evolution 额外做：

```text
compare with current Skill
→ determine delta
→ update correct owner
→ Skill vNext
```

Case 可以提供新 Source，但不是唯一入口。

用户明确要求修改已有 Skill 时，不要求先人工创建 Case。

# Case

Case 保存：

- 真实事实；
- 用户纠正；
- outcome；
- provenance；
- 必要 evidence。

Case 不直接承担：

- Capability 建模；
- Principle 抽象；
- Workflow 设计；
- Example 构造；
- Git 版本历史。

Replay Case 尤其只是历史来源证据。

正确关系：

```text
Historical Work
→ Reconstruction
→ Capability / Skill

同时按需：
Reconstruction
→ Replay Case
```

见 [cases.md](references/cases.md)。

# Evaluation

Evaluation 不是：

- Skill 创建必经阶段；
- Prompt 创建必经阶段；
- Example 创建必经阶段；
- 所有修改的发布门槛。

Evaluation 是：

> **当我们已经有 Candidate Change，但真实材料不足以直接确定它是否正确时，主动降低不确定性。**

优先使用：

- Usage Case；
- Replay Case；
- 由真实材料派生的 boundary / regression。

没有真实材料时允许 `unmeasured`，不为形式完整凭空制造测试体系。

# Example

从真实经验形成 Teaching Example 时：

```text
Specific Experience
→ Abstract decision relation
→ new Generic Teaching Example
```

不是：

```text
Specific Case
→ delete names
→ Example
```

# Skill Repository Boundary

每个 Skill 文件夹：

- 自己 `git init`；
- 自己 commit；
- 自己保存 Case；
- 自己管理演变历史。

是否拥有独立 GitHub / GitLab remote 是分发选择，不是 Skill 生命周期要求。

Skill 应尽可能自包含，但正常执行不默认加载完整 Case 历史。

# Harness / Runtime 边界

Guidance 可以影响模型如何使用已有能力，但不能靠文本创造：

- Tool / Permission；
- Context window；
- Memory / Compaction；
- Sandbox；
- Agent loop；
- Runtime state。

这些属于 Harness / Runtime / Tool 工程。

# 共同原则

- 先理解 Source，再抽象，不从原材料直接跳到 instruction。
- 对真实工作先恢复因果 / 决策结构，不做表面摘要。
- 抽象的是决策关系，不是删掉专有名词。
- 对话顺序不自动等于 Workflow。
- Case 是 evidence / provenance，不是强制 IR。
- 一个语义一个主要 owner。
- 可机械保证的事情交给 schema、script、test、permission 或 runtime policy。
- Skill v0 的完成标准是“可使用”，不是“已成熟”。
- 真实使用是最自然的后续检验。
- Evaluation 只解决实质不确定性。
- Git 保存 Skill 如何演变；Case 不复制版本历史。
