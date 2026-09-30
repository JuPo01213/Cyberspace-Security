---
name: guidance-engineering
description: >-
  设计、编写、审查、评估和演进面向大语言模型与 Agent 的行为指导资产。
  覆盖 Prompt Engineering、Workflow Design、Example Engineering、Skill Construction、
  Evaluation 与 Evolution；不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: Prompt、Workflow 与 Skill 的指导工程
---

# Guidance Engineering

## 核心模型

本 Skill 只处理“指导资产”：

```text
Prompt
= 如何表达行为要求

Workflow
= 行为如何组织和推进

Example
= 如何用具体示范塑造行为

Skill
= 如何把 Prompt、Workflow、Example、知识和支持资源封装成可复用能力

Evaluation
= 如何测量实际行为

Evolution
= 何时以及如何修改活动指导资产
```

主依赖链：

```text
Prompt Engineering
→ Workflow Design（需要多步/状态/分支时）
→ Skill Construction（需要长期复用时）
→ Evaluation
→ Evolution
```

Example Engineering 是横切能力，不是第六层；它可以服务 Prompt、Workflow 和 Skill，但教学 Example 与测试 Case 必须分离。

## 与 Harness / Runtime 的边界

Harness / Runtime 提供上下文装配、工具暴露、状态、sandbox、Skill discovery/loading 和执行循环等运行机制。

Guidance 可以影响模型**如何使用已有能力**，但不能仅靠文本创造或改变：

- 工具与权限；
- context window；
- memory / compaction 实现；
- sandbox；
- agent loop；
- 运行时状态机制。

问题实际属于这些层时，转交 Harness / Runtime / Tool 工程，不继续堆 Prompt。

## 唯一归属

同一语义只保留一个主要权威位置：

| 对象 | 权威位置 |
| --- | --- |
| Prompt 类型、措辞、上下文组织 | [prompt-engineering.md](references/prompt-engineering.md) |
| 阶段、状态、分支、behavior contract | [workflow-design.md](references/workflow-design.md) |
| Teaching Example / few-shot | [example-engineering.md](references/example-engineering.md) |
| Skill 能力边界、目录与资源封装 | [skill-building.md](references/skill-building.md) |
| Development/Eval Case | [evaluation/case-engineering.md](references/evaluation/case-engineering.md) |
| 测量、baseline/variant、判定 | [evaluation.md](references/evaluation.md) |
| 经验升格、修改、回归后的采纳 | [evolution.md](references/evolution.md) |

其他文件只能引用，不重复定义。

## 路由

- 写、改、审 Prompt，或判断 system/developer/skill/task/tool/grader guidance：读 [prompt-engineering.md](references/prompt-engineering.md)。
- 任务需要多步、分支、状态、失败出口或完成门：读 [workflow-design.md](references/workflow-design.md)。
- 需要 few-shot、边界示范、对照示范或工具轨迹示范：读 [example-engineering.md](references/example-engineering.md)。
- 创建、重构、打包或审查 Skill：读 [skill-building.md](references/skill-building.md)。
- 构造测试 case、从真实失败抽象测试机制：读 [evaluation/case-engineering.md](references/evaluation/case-engineering.md)。
- 判断指导是否有效：读 [evaluation.md](references/evaluation.md)。
- 根据真实证据维护活动资产：读 [evolution.md](references/evolution.md)。

只加载当前任务所需的最窄分支。

## 共同原则

- **先解决行为问题，再选择载体。** 不从“我要写一个 Skill/Prompt”反推需求。
- **最小充分干预。** 短 instruction 能解决，不升级成 workflow；workflow 能解决，不为了形式新建 Skill。
- **成熟方法优先。** 当前平台已有官方机制、成熟工具或已验证资产时先复用。
- **一个语义一个归属。** 引用权威文件，不复制规则。
- **证据不自动变成指令。** 真实失败先成为 observation/case，再通过 Evaluation/Evolution 决定是否升格。
- **可机械保证的交给机械层。** schema、script、test、permission、runtime policy 能确定性约束的，不长期依赖自然语言。
- **用户当前明确要求与真实平台约束优先。**
