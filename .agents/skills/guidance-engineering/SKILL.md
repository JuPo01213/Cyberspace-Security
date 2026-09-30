---
name: guidance-engineering
description: >-
  设计、编写、审查、评估和演进面向大语言模型与 Agent 的行为指导资产。
  覆盖 Prompt Engineering、Workflow Design、Skill Construction、Evaluation 与 Evolution。
  适用于创建或改进 system/developer/application prompt、skill prompt、任务提示、tool-use guidance、
  可复用 workflow 与 Skill；不负责实现 Harness/Runtime、Memory、Tool 或 Sandbox 本身。
metadata:
  short-description: Prompt、Workflow 与 Skill 的指导工程
---

# Guidance Engineering

## 定位

本 Skill 处理的是**指导工程（Guidance Engineering）**：如何把人的目标和约束转成能够稳定影响模型/Agent 行为的指导资产，并进一步组织、封装、验证和演进。

它不把 Prompt、Workflow 和 Skill 混成同一个概念：

```text
Prompt
= 如何向模型表达行为要求

Workflow
= 行为本身如何组织和推进

Skill
= 把某类能力及其 Prompt、Workflow、知识与支持资源封装成可发现、可复用的能力单元
```

本 Skill 的主线固定为：

```text
Prompt Engineering
→ Workflow Design
→ Skill Construction
→ Evaluation
→ Evolution
```

这是一条能力依赖链，不意味着所有任务都必须依次执行五层。只读取当前目标真正需要的最窄分支。

## 与 Agent / Harness 的边界

Agent 是最终执行任务的整体系统；Harness / Runtime 提供模型可使用的运行机制和能力，例如上下文装配、工具暴露、状态、sandbox、Skill discovery/loading 与执行循环。

本 Skill 不构建 Harness，也不假设自然语言可以创造宿主没有提供的能力。

它负责的对象是**指导资产**：

- Prompt / Instructions；
- Workflow guidance；
- Skill 内部结构与资源组织；
- Examples / cases；
- Tool-use guidance；
- 与这些资产对应的 eval 与维护规则。

这些资产可以影响模型如何使用现有 Harness 能力，但不能仅靠文本改变：

- 工具是否存在；
- 权限和认证；
- context window；
- compaction / memory 实现；
- sandbox；
- agent loop；
- 运行时状态机制。

若问题实际属于这些层，明确转交到 Harness / Runtime / Tool 工程，而不是继续堆 Prompt。

## 第一层：Prompt Engineering

Prompt 是指导工程的基础层。先理解“怎样表达行为要求”，再讨论如何把它组织成 Workflow 或封装成 Skill。

Prompt 不是单一类型。至少区分：

- System Prompt：宿主提供的高层系统指导；
- Developer / Application Prompt：应用长期提供的行为规则与业务约束；
- Skill Prompt：由 Skill 提供、在能力被加载后影响模型行为的 instructions；它不是新的消息角色；
- Task / User Prompt：当前任务目标和材料；
- Tool-use Guidance：何时、为何、怎样使用工具；
- Grader / Judge Prompt：用于评估其他输出或轨迹；
- Few-shot / Examples：通过示范塑造行为的手段，可存在于不同 Prompt 类型中。

需要设计、改写、分类或审查 Prompt 时读取 [prompt-engineering.md](references/prompt-engineering.md)。

## 第二层：Workflow Design

Workflow 关注行为如何展开：阶段、状态、分支、依赖、失败出口、验证和停止条件。

当问题已经不是一句 instruction 能表达清楚，而涉及多步决策、条件分支、工具轨迹或完成门时，读取 [workflow-design.md](references/workflow-design.md)。

不要因为存在多个步骤就自动新建 Skill；Workflow 可以只是一个 Skill 内部的行为结构。

## 第三层：Skill Construction

Skill 是能力封装层。

当目标是创建、更新、审查、重构或打包 Skill 时，读取 [skill-building.md](references/skill-building.md)。

Skill Construction 必须以 Prompt 与 Workflow 的设计结果为输入，而不是从文件格式开始。先回答：

- 这项能力是什么；
- 哪些请求应该触发；
- 内部行为如何组织；
- 哪些 instruction 应常驻；
- 哪些知识/资源应按需读取；
- 哪些内容应交给 script/tool/runtime。

再决定 `SKILL.md`、references、scripts、assets 和 metadata 的具体结构。

## 第四层：Evaluation

没有行为证据，Prompt/Workflow/Skill 只是候选设计。

需要判断：

- 指导是否真正改变目标行为；
- 是否误触发；
- 是否出现边界退化；
- baseline 与 variant 是否可比；
- example 是否只是过拟合；

读取 [evaluation.md](references/evaluation.md)。

需要案例抽象、边界案例和回归语料时，再读取 [evaluation/case-engineering.md](references/evaluation/case-engineering.md)。历史大案例库只在确有需要时定位读取 [evaluation/case-library.md](references/evaluation/case-library.md)。

## 第五层：Evolution

当用户明确要求维护、重构、优化，或已有真实证据表明指导资产需要变化时，读取 [evolution.md](references/evolution.md)。

正常任务不会自动修改本 Skill。真实失败首先产生 observation / evidence，再经过归因、候选修改和回归，才可能进入活动指导。

## 共同原则

- **先成熟方法，后自建。** 已有官方机制、成熟工具、社区工作流或项目既有资产时先检查，不因为可以手写就重复造轮子。
- **理论分类服从真实使用。** 两个内容理论上可区分，不代表必须拆成两个 Skill；若高频共同出现、共同维护且拆分只制造重复，优先聚合。
- **Prompt 先于 Skill 格式。** 格式正确不等于行为正确；Skill authoring 必须建立在 Prompt 和 Workflow 理解之上。
- **一个语义一个主要归属。** 不通过复制相同规则解决路由问题。
- **指导不等于权限。** Skill 可以建议模型使用工具，不能创造授权。
- **证据不等于指令。** 历史记录、解释和失败案例只有在经过抽象与验证后才可能升格为长期指导。
- **完成条件必须可观察。** 模型自评、文件存在或命令成功只有在与目标契约绑定时才构成完成证据。
- **聚合优先，分化后置。** 先按真实工作形成完整能力；只有某部分出现独立任务、独立消费者和独立维护价值时才拆出新 Skill。

## 文件职责

- `SKILL.md`：五层主模型、共享边界与路由。
- `references/prompt-engineering.md`：Prompt 类型、设计原则与书写方法。
- `references/workflow-design.md`：行为契约、阶段、状态、分支和完成门。
- `references/skill-building.md`：把 Prompt + Workflow + supporting resources 封装为 Skill。
- `references/skill-building/`：Skill 结构、复用、安全、examples/evals、发布等专项资料。
- `references/evaluation.md`：行为评估、baseline/variant、回归与证据。
- `references/evaluation/`：案例工程与历史案例库。
- `references/evolution.md`：基于证据的维护、归因和演进。
- `scripts/`：适合确定性、重复执行的 Skill 初始化和验证辅助。

用户当前明确要求、平台实际约束和工具真实返回始终优先于本 Skill 的默认建议。
