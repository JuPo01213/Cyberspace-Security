# Cases：经验与来源证据

## 职责

Case 负责保存：

> **真实使用或历史工作中，未来仍值得重新理解的事实、纠正、结果和来源证据。**

Case 不是 Skill Construction 的必经中间表示，也不负责直接抽象能力。

```text
Source / Experience
→ Understand / Reconstruct
→ Abstract
→ Skill

同时，必要来源证据
→ Case
```

所以：

```text
Conversation
→ Replay Case
→ Skill
```

不是强制流程。

更准确的是：

```text
                    ┌→ Capability / Skill
Work Reconstruction ┤
                    └→ Replay Case（按需保存）
```

## Case 与其他对象

```text
Case
= 来源事实和经验记录

Principle
= 从经验中抽象出的可迁移关系

Workflow
= 依赖阶段 / 状态的行为模型

Example
= 为教学而构造的示范

Git history
= Skill 版本如何变化
```

不要让 Case 同时承担这些职责。

# 两类主要 Case

## Usage Case

来自已有 Skill 的真实使用：

```text
Skill
→ Real Use
→ observation / result / user correction
→ Usage Case
```

适合后续 Skill Evolution。

## Replay Case

来自已经发生过的真实工作：

```text
Historical Work
→ reconstruction
→ selected facts / decisions / outcomes
→ Replay Case
```

Replay Case 的作用是保存来源证据和关键历史，不是把整段工作记录转录一遍。

可引用：

- 对话；
- 工具调用；
- 文件变化；
- Git diff；
- 用户纠正；
- 中间失败；
- 最终产物；
- completion evidence。

Replay Case 必须能追溯到真实历史。

# 什么时候值得保存

只有未来重新理解它有价值时才记录。

常见信号：

- 用户纠正了重要行为；
- 实际结果推翻了原假设；
- 出现新的边界；
- 一个成功方法具有明显复用价值；
- 某个历史决策后来被证明关键；
- Skill Evolution 需要保留变化来源；
- 构建 Skill 时需要保存“为什么会形成这条能力”的来源证据。

普通、没有新增信息的成功不需要机械记录。

# 记录流程

```text
1. 捕获 Facts
2. 保存最小 Context
3. 分离 Interpretation
4. 保存必要 Evidence
5. 标记用途 / owner
6. 交给 Construction 或 Evolution 的对应流程
```

## 1. 捕获 Facts

优先保存可观察事实。

例如：

```text
Fact:
模型没有检索成熟方案，直接开始手写实现。
```

而：

```text
Interpretation:
可能缺少“成熟生态存在时优先复用”的 Guidance。
```

只是当前解释。

## 2. 保存最小 Context

只保存未来重新理解事实所必需的信息。

```yaml
case_id: CASE-...
source: usage | replay
skill_revision: optional-git-sha

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

Replay Case 在 Skill 尚未创建时可以没有 `skill_revision`；创建后再按需补 revision 指针。

不要复制整个对话、全部日志或所有工具输出。

## 3. 分离 Interpretation

Facts 尽量保持稳定；Interpretation 可以变化。

例如后续发现：

```text
模型没有搜索
```

是因为当时没有 Web Tool。

那么应更新 Interpretation，而不是修改历史 Fact。

## 4. 保存必要 Evidence

默认：

```text
skill-repository/
├── SKILL.md
├── cases/
│   ├── cases.ndjson
│   └── evidence/
└── ...
```

只有复杂 Case 真正需要额外证据时才创建 `evidence/`。

如果已有更合适的 Markdown / JSON / fixture 体系，直接复用。

Case 自包含于所属 Skill repository。

不建立跨 Skill 的集中 Case 仓库。

## 5. 标记用途 / owner

Case 自己不完成能力设计，只标明它接下来可能服务什么：

```text
construction_source
= 构建初始 Skill 时保留的来源证据

evolution_source
= 已有 Skill 的新经验

evaluation_material
= 某次 Evaluation 可复用的真实材料

historical_only
= 仅保留历史，不驱动当前 Guidance
```

一个 Case 可以服务多个用途，但不要因此复制多份。

## 6. 交给对应流程

### 构建新 Skill

Construction 不要求先创建 Case。

正确关系：

```text
Source
→ Understand / Reconstruct
→ Abstract
→ Capability
→ Skill

必要来源证据
→ Replay Case
```

见 [skill-building.md](skill-building.md)。

### 改进已有 Skill

```text
Usage / Replay Case
→ Skill Evolution
```

见 [skill-evolution.md](skill-evolution.md)。

### 验证 Candidate Change

Evaluation 可以复用已有 Usage / Replay Case，但 Case 并不是为了 Evaluation 而存在。

见 [evaluation.md](evaluation.md)。

# 状态

最小状态：

```text
open
= 仍可能影响 Construction / Evolution

absorbed
= 已被某个 Skill revision 吸收

no-change
= 已分析，不需要改变 Skill

historical
= 仅保留来源历史
```

关闭 Case 时保存结果和 revision 指针，不复制完整 Git 历史。

# 完成标准

一个 Case 记录合格时：

- 来源是真实使用或可追溯历史；
- Fact 与 Interpretation 已分开；
- Context 足够但不过量；
- Evidence 只保存必要部分；
- 已明确它服务 Construction、Evolution、Evaluation 还是仅历史；
- 没有把 Case 直接伪装成 Principle、Workflow 或 Example；
- 没有把完整版本历史复制到 Case 中。
