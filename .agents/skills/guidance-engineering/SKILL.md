---
name: guidance-engineering
description: >-
  设计、编写、审查和持续改进面向大语言模型与 Agent 的行为指导资产。
  覆盖 Principle / Workflow 建模、Prompt Engineering、Example Engineering、Skill Construction、
  Case 反馈与 Evaluation；不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: 从经验到 Prompt、Skill 与持续改进
---

# Guidance Engineering

## 核心

Guidance Engineering 只回答一件事：

> **怎样把经验压缩成可复用指导，并在真实使用中继续修正它。**

最小闭环：

```text
Skill
  ↓ use
Case
  ↓ abstract / modify
Candidate Guidance
  ↓ evaluate
Skill vNext
  ↓ use
...
```

真正需要长期保存的只有三类东西：

```text
Skill
= 当前已经压缩好的指导

Case
= 使用中产生、尚未完全压缩的新经验

Git history
= Skill 如何从旧版本变成当前版本
```

不要为中间推理再制造一套长期对象。Mechanism、Principle candidate、维护假设等可以在处理 Case 时临时形成；只有最终有持续价值的内容才进入 Skill 或 Case。

## 信息层级

### 行为模型

```text
Principle
= 什么条件下应该怎样做，边界在哪里

Workflow
= 当行为依赖阶段、状态或前序结果时，如何推进和停止
```

Workflow 是独立概念，但当前不需要独立 reference。最小设计只回答：

- Goal / completion；
- Stages；
- State / observations；
- Transitions / branches；
- Failure / stop。

### 表达

```text
Prompt
= 用语言把行为模型表达给模型

Example
= 用具体示范把行为模型具体化
```

Prompt 的具体书写见 [prompt-engineering.md](references/prompt-engineering.md)。

Example 的设计见 [example-engineering.md](references/example-engineering.md)。

### 封装

```text
Skill
= 把相关 Guidance 与 supporting resources
  封装成可发现、可复用能力
```

创建、合并、拆分或重构 Skill 见 [skill-building.md](references/skill-building.md)。

## 学习层：Case

Skill 不直接“自我学习”。真实使用先产生 Case，再由 Case 反哺 Skill。

```text
Active Skill
→ Real Use
→ Case
→ 抽象 / 归因 / 修改
→ Evaluation
→ Skill vNext
```

Case 的记录、保存和反哺方法见 [cases.md](references/cases.md)。

**Case 默认不进入正常运行上下文。** 它属于学习层；只有在维护、优化、构造 Example 或 Evaluation 时按需读取。

## Evaluation 的位置

Evaluation 不是生命周期终点，而是候选修改进入活动 Skill 前的验证动作。

```text
Case
→ Candidate change
→ Evaluation
→ keep / revise / reject
```

具体方法见 [evaluation.md](references/evaluation.md)。

## Maintenance 与 Evolution

不把它们做成两套生命周期。

它们只是对一次 Skill 变更性质的描述：

```text
Maintenance change
= 能力目标和边界基本不变，只修复、适配、去腐化

Evolution change
= 能力目标、触发边界或抽象本身发生变化
```

这两个标签可以出现在 commit / change note 中，不需要维护两套独立状态机或 reference。

## 从明确需求创建 Guidance

当目标本来就清楚：

```text
行为要求
→ Principle / 必要时 Workflow
→ Prompt
→ 必要时 Example
→ 如需长期复用则封装 Skill
→ Evaluation
```

不是所有节点都必须出现。

## 从真实使用固化经验

当用户说“这个经验以后应该复用”：

```text
真实使用
→ Case
→ 提取可迁移关系
→ 形成候选 Principle / Workflow / Prompt / Example
→ 判断并入已有 Skill 还是形成新 Skill
→ Evaluation
→ 更新 Skill
→ Git commit
```

关键要求：

- 具体 Case 不是通用原则；
- 用户反馈是重要证据，但不会自动变成长期 instruction；
- 匿名化原案例不等于抽象；
- 从 Case 产生 Teaching Example 时，先抽象原则，再重新构造通用 Example；
- 新 Skill 不是默认结果，优先检查已有 owner。

## 与 Harness / Runtime 的边界

Guidance 可以影响模型如何使用已有能力，但不能仅靠文本创造或改变：

- 工具与权限；
- context window；
- memory / compaction；
- sandbox；
- agent loop；
- 运行时状态机制。

问题属于这些层时，转交 Harness / Runtime / Tool 工程。

## 路由

- 写、改、审 Prompt → [prompt-engineering.md](references/prompt-engineering.md)
- 设计 few-shot / Teaching Example → [example-engineering.md](references/example-engineering.md)
- 从零创建、合并、拆分、重构 Skill → [skill-building.md](references/skill-building.md)；创建时按其中“从零创建 Skill：标准流程”执行
- 从真实使用保存经验、反哺 Skill → [cases.md](references/cases.md)
- 验证候选修改是否真实有效 → [evaluation.md](references/evaluation.md)
- 查询历史/构造案例 → [case-library.md](references/case-library.md)

## 共同原则

- 先解决行为问题，再选择表达和封装形式。
- 简单行为不制造 Workflow；不需要长期复用就不制造 Skill。
- 一个语义一个主要 owner。
- 真实使用产生 Case；Case 不自动产生 Rule。
- 正常执行不加载完整 Case 历史。
- 可机械保证的交给 schema、script、test、permission 或 runtime policy。
- 未经必要 Evaluation 的新 Guidance 只能称 candidate。
- Git 保存版本演变，不用 Case 再复制一份版本历史。
- 用户当前明确要求、真实平台能力与工具返回优先。
