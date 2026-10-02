# Cases：Skill 的经验载体

## 职责

Case 只负责：

> **把真实使用或历史工作中值得保留的经验，保存成后续 Skill Evolution 可以重新理解的材料。**

Case 不负责直接修改 Skill，也不负责决定 Evaluation。

```text
Case
= 发生了什么

Example
= 为了教学而构造的示范

Principle / Rule
= 从经验中抽象出的可迁移关系
```

## 来源

### Usage Case

来自 Skill 的真实使用：

```text
Skill
→ Real Use
→ outcome / user correction / boundary
→ Usage Case
```

真实工作是最主要的来源。

### Replay Case

当工作已经完成，之后才回顾并抽象 Skill 时，可以从已有上下文提取 Replay Case：

```text
historical work context
→ key decisions / corrections / outcomes
→ Replay Case
```

可用材料包括：

- 对话；
- 用户纠正；
- 工具调用；
- 文件变化；
- Git diff；
- 最终产物；
- 已知失败与成功结果。

Replay Case 必须能追溯到真实历史，不是凭空编造测试题。

## 什么时候记录

出现以下情况时值得记录：

- 用户纠正 Skill 行为；
- 实际任务结果暴露缺口；
- 出现重要边界；
- 某个成功方法具有明显复用价值；
- 某个历史决策后来被证明关键；
- 该经验可能影响未来 Skill Evolution。

普通、没有新增信息的成功不需要机械记录。

# 记录流程

```text
1. 捕获 Facts
2. 保存最小 Context
3. 分离 Interpretation
4. 保存必要 Evidence
5. 判断归因方向
6. 路由到 no-change 或 Skill Evolution
```

## 1. 捕获 Facts

优先记录可观察事实，不把解释写成事实。

例如：

```text
Fact:
模型没有检索成熟方案，直接开始手写实现。
```

而：

```text
Interpretation:
Skill 可能缺少“优先复用成熟能力”的指导。
```

属于解释。

## 2. 保存最小 Context

只保存未来重新理解这个 Case 所必需的信息。

默认可以使用：

```yaml
case_id: CASE-...
source: usage | replay
skill_revision: git-sha-or-version

context:
  task: ...
  relevant_environment: ...

observed:
  - ...

feedback_or_outcome:
  - ...

interpretation:
  - ...

evidence_refs:
  - ...

status: open
```

不要复制完整聊天或完整运行日志。

## 3. 分离 Interpretation

Fact 尽量保持稳定；Interpretation 可以被后续证据推翻。

后续发现 Tool 当时根本不可用时，应更新解释，而不是篡改“模型没有搜索”这个原始事实。

## 4. 保存必要 Evidence

只有复杂 Case 真正需要时才保存额外证据。

默认结构：

```text
skill-repository/
├── SKILL.md
├── cases/
│   ├── cases.ndjson
│   └── evidence/
└── ...
```

如果已有更适合的 Markdown / JSON / fixture 体系，直接复用。

Case 必须自包含于产生它的 Skill repository，并随该 Skill 自己的 Git history 管理。

不建立跨 Skill 的集中 Case 仓库。

## 5. 判断归因方向

这里只做**路由级判断**，不在 Case 层完成修改设计。

可能属于：

- Principle；
- Workflow；
- Prompt；
- Example；
- Skill boundary / packaging；
- Harness / Runtime；
- Tool / Permission；
- Model capability；
- 用户目标本身。

如果明显不属于 Skill 层：

```text
status = no-change
reason = ...
```

并关闭。

如果可能改变 Skill：

```text
Case
→ Skill Evolution
```

详细归因、抽象和修改由 [skill-evolution.md](skill-evolution.md) 负责。

## 6. 路由与状态

最小状态：

```text
open
= 已记录，尚未完成处理

absorbed
= 已被某个 Skill revision 吸收

no-change
= 已分析，但不需要修改 Skill
```

Case 进入 Skill Evolution 后可以保持 `open`，直到 Evolution 完成：

- 修改被吸收 → `absorbed`；
- 最终判断不修改 → `no-change`。

关闭时只保存结果和 revision 指针，不复制完整版本历史。

# Case 与 Evolution

正确关系：

```text
Skill Usage / Historical Work
→ Case
→ Skill Evolution
→ Candidate Change
→ optional Evaluation
→ Skill vNext
→ close Case
```

Case 不自动成为 Rule，也不直接驱动 Prompt 修改。

# Case 与 Evaluation

Evaluation 可以使用 Case 作为材料，但 Case 不是为了 Evaluation 而存在。

优先顺序：

```text
真实使用产生经验
→ 保存 Case
→ Evolution 需要验证某个不确定变化
→ Evaluation 复用 Usage / Replay Case
```

如果没有真实使用或历史上下文提供检验材料，不为了满足形式要求凭空制造一套 Evaluation。

# 完成标准

Case 层完成时：

- Fact 与 Interpretation 已分开；
- Context 足够但不过量；
- 必要 Evidence 已保存；
- Case 位于所属 Skill 内；
- 已完成路由：
  - 明显不属于 Skill → `no-change`
  - 可能改变 Skill → 交给 Skill Evolution；
- 没有在 Case 层直接制造长期 Rule 或修改 Skill。
