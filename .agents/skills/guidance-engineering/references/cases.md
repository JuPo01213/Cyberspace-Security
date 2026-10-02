# Cases：使用经验与 Skill 反馈回路

## 职责

Case 是 Skill 的经验载体：

> 保存一次真实使用或回溯分析中产生的重要观察，为后续 Skill Evolution 提供依据。

Skill 是压缩后的经验；Case 是尚未完全压缩的新经验。

Case 不等于 Example，也不等于 Rule：

```text
Case = 发生了什么
Example = 为了教学构造的示范
Rule / Principle = 从多个 Case 中抽象出的可迁移关系
```

## 来源

Case 主要来自两个入口：

### Usage Case

真实任务中的反馈：

```text
Skill 使用
↓
结果 / 用户纠正 / 边界情况
↓
Case
```

### Replay Case

从已有工作上下文回溯构造：

```text
完整工作过程
↓
提取关键决策点
↓
Replay Case
```

Replay Case 不是凭空设计测试，而是从真实历史中提取。

## 什么时候记录

出现以下情况时记录：

- 用户纠正 Skill 行为；
- 任务结果暴露能力缺口；
- 发现重要边界条件；
- 某个经验可能改变未来 Skill 设计。

普通成功不需要机械记录。

## 最小结构

```yaml
case_id: CASE-...
skill_revision: git-sha-or-version

context:
  task: ...

observed:
  - 可观察事实

feedback_or_outcome:
  - 用户反馈或结果

interpretation:
  - 当前解释，可被后续推翻

status: open
```

## 处理流程

```text
1. 捕获事实
2. 保存最小 Context
3. 分离 Interpretation
4. 判断归因
5. 决定是否进入 Skill Evolution
6. 形成 Candidate Change（如果需要）
7. 必要时 Evaluation
8. 关闭 Case
```

## 归因

不要默认通过增加 Prompt 修复。

检查问题属于：

- Principle；
- Workflow；
- Prompt；
- Example；
- Skill packaging；
- Harness / Runtime；
- Tool / Permission；
- Model capability。

如果问题不属于 Skill 层，不应继续修改 Skill。

## Evolution 关系

Case 本身不会自动成为规则：

```text
Case
↓
抽象问题
↓
Skill Evolution
↓
Candidate Change
↓
（必要时）Evaluation
↓
Skill vNext
```

## 保存原则

Case 自包含于产生它的 Skill repository。

不建立跨 Skill 的集中 Case 仓库。

版本变化由该 Skill 自己的 Git history 管理。

## 状态

```text
open
= 尚未处理

absorbed
= 已被 Skill 修改吸收

no-change
= 已分析，但不修改 Skill
```

关闭 Case 时保存处理结果，不复制完整版本历史。