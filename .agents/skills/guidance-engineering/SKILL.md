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

## 信息层级

Guidance Engineering 不按“一个概念一个文件”组织，而按**行为从形成到落地**的层级组织。

```text
意图 / 真实经验
        ↓
行为模型
├── Principle
│   = 什么条件下应该怎样做，以及边界在哪里
└── Workflow
    = 当行为具有过程性时，阶段、状态、分支和停止怎样组织
        ↓
表达层
├── Prompt
│   = 如何用语言把行为模型表达给模型
└── Example
    = 如何用具体示范把行为模型具体化
        ↓
封装层（可选）
└── Skill
    = 把相关 Guidance 与 supporting resources 封装成可发现、可复用能力
        ↓
Evaluation
        ↕
Evolution
```

**概念层级不要求和文件层级一一对应。** Workflow 是独立概念，但当前方法量不足以值得维护独立 reference；它的最小方法保留在主入口。Prompt 负责表达 Workflow，Skill 负责封装 Workflow，二者都不拥有 Workflow 本身的语义。

## 共同起点：行为要求

选择任何 Guidance 形式前，先明确最低充分的行为要求：

- **goal**：最终希望发生什么；
- **conditions / scope**：什么条件下适用；
- **required**：必须发生什么；
- **prohibited**：当前条件下不能发生什么；
- **completion evidence**：从哪里观察完成；
- **failure / uncertainty**：信息不足、冲突或工具失败时怎样合法结束；
- **environment**：当前模型、Harness、工具和权限真实提供什么。

简单行为到这里就可以直接进入 Prompt。

## Principle：条件化行为

Principle 是对行为规律的抽象：

```text
条件
→ 应采取 / 避免的行为
→ 条件变化后的边界或反转
```

它可以直接来自明确需求，也可以从具体案例经 Mechanism 抽象得到。至少要能回答：什么时候适用、做什么、哪个条件变化后不再适用、不能泛化成什么。

从真实经验提炼 Principle 的方法由 [evolution.md](references/evolution.md) 管理。

## Workflow：过程化行为

只有当正确行为依赖**时间、阶段、状态或前序结果**时，才需要 Workflow。

最小 Workflow 设计只回答五件事：

1. **Goal / completion**：整个流程最终完成什么；
2. **Stages**：哪些阶段真的有不同职责；
3. **State / observations**：哪些事实会改变下一步；
4. **Transitions / branches**：观察到什么后进入哪一步、跳过什么或回退；
5. **Failure / stop**：什么时候停止、失败、恢复或返回非完成状态。

不要为了“流程完整”增加没有消费者的阶段、日志、状态或产物。

Workflow 是行为模型，不是 Prompt 模板。设计完成后：
- 由 [prompt-engineering.md](references/prompt-engineering.md) 编译成模型需要看到的 instructions；
- 若决策或工具轨迹需要示范，由 [example-engineering.md](references/example-engineering.md) 提供 Example；
- 若需要长期 discovery、references、scripts 或资源封装，由 [skill-building.md](references/skill-building.md) 纳入 Skill。

## 两条常见工作路径

### 从明确需求直接设计

当目标和边界本来就清楚：

```text
行为要求
→ 写 Prompt
→ 必要时建立 Workflow 行为模型
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
→ Candidate Prompt / Skill（可表达或封装 Workflow）
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
| Principle / Workflow 的最小行为建模 | 本 `SKILL.md` |
| Teaching Example / few-shot | [example-engineering.md](references/example-engineering.md) |
| Skill 能力边界、触发、目录与资源封装 | [skill-building.md](references/skill-building.md) |
| Observation / Development Case / Eval Case | [evaluation/case-engineering.md](references/evaluation/case-engineering.md) |
| 测量、baseline/variant、判定 | [evaluation.md](references/evaluation.md) |
| Principle 提炼、经验升格、资产维护 | [evolution.md](references/evolution.md) |

其他文件只引用，不复制第二套同义规则。

## 路由

- “帮我写/改/审这个提示词” → [prompt-engineering.md](references/prompt-engineering.md)。
- “这套行为有多步、分支、状态或失败恢复” → 使用本 `SKILL.md` 的 Workflow 五项模型，再由 Prompt 或 Skill 落地。
- “这个规则需要示例才能讲清楚” → [example-engineering.md](references/example-engineering.md)。
- “这个经验值得固化成 Skill / 帮我创建或重构 Skill” → [skill-building.md](references/skill-building.md)，并按需调用 Evolution / Prompt / Workflow / Example / Evaluation。
- “从这次真实失败抽象可复用经验” → [evaluation/case-engineering.md](references/evaluation/case-engineering.md) + [evolution.md](references/evolution.md)。
- “这次改动真的更好吗” → [evaluation.md](references/evaluation.md)。

只加载当前任务需要的最窄分支。

## 共同原则

- 先解决行为问题，再选择载体。
- 最小充分：简单行为不制造 Workflow；不需要长期复用就不制造 Skill。
- 成熟方法优先：先检查目标生态当前官方能力、成熟工具和已有资产。
- 一个语义一个主要 owner，但概念不因没有独立文件而消失。
- Evidence 不自动等于 Instruction。
- 可由 schema、script、test、permission 或 runtime policy 确定性保证的，不长期依赖自然语言提醒。
- 未经 Evaluation 的新 Guidance 只能称 candidate。
- 用户当前明确要求、真实平台能力与工具返回优先于默认指导。
