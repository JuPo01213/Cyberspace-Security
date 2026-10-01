# Cases：使用经验与 Skill 反馈回路

## 职责

Case 是 Skill 的学习载体：

> **保存一次真实使用或 Evaluation 中，发生了什么、为什么值得记住，以及它最后是否反哺了 Skill。**

Skill 是压缩后的经验；Case 是尚未完全压缩的新经验。

Case 不等于 Example，也不等于 Rule：

```text
Case = 发生过什么 / 测到了什么
Example = 为了教学而构造什么示范
Rule / Principle = 从一个或多个 Case 中抽象出的可迁移关系
```

## 什么时候进入

出现以下任一情况时记录 Case：

- 真实任务中出现成功、失败、用户纠正或重要边界；
- Evaluation 产生可保留结果；
- 某个现象可能影响未来 Skill 行为；
- 需要为一次 Skill 修改保留来源证据。

普通、无新增信息的成功不必机械记录。

## 输入

至少需要：

- 当时的 Skill revision；
- 任务或测试条件；
- 可观察行为；
- 用户反馈或实际结果；
- 必要证据。

# 执行流程

```text
1. 判断是否值得记录
2. 捕获 Facts
3. 记录最小 Context
4. 分离 Interpretation
5. 保存 Case
6. 判断归因
7. 决定是否需要改 Skill
8. 抽象并形成 Candidate change
9. Evaluation
10. 关闭 Case
```

## 1. 判断是否值得记录

记录标准：

> 这个观察以后是否可能改变设计、验证、维护或理解？

如果答案是否定的，不创建 Case。不要把 Case 系统变成完整运行日志。

## 2. 捕获 Facts

先记录可观察事实，不夹带解释。

```text
Fact:
模型没有搜索，直接开始手写解析器。
```

“模型缺乏成熟能力发现意识”属于 Interpretation，不是 Fact。

## 3. 记录最小 Context

只保留将来重新理解事实所需的信息：

```yaml
case_id: CASE-...
skill_revision: git-sha-or-version

context:
  task: 实际要完成什么
  relevant_environment: 只记录会改变判断的模型/Harness/工具/权限

observed:
  - 可观察事实

feedback_or_outcome:
  - 用户纠正、成功/失败结果或关键影响

interpretation:
  - 可为空

evidence_refs:
  - 可为空

status: open
```

不要复制整段聊天、全部工具输出或无关上下文。

因为 Case 已位于所属 Skill 内，通常不需要重复保存 Skill 名称。

## 4. 分离 Interpretation

Facts 尽量保持稳定；Interpretation 可以被后续证据推翻。

```text
Fact:
模型没有搜索。

Interpretation A:
可能过早自建。

后续发现:
Web 工具当时没有暴露。

Interpretation B:
真正问题属于 Harness / Tool availability。
```

不要为了保持旧结论而篡改原始事实。

## 5. 保存 Case

Case 自包含于产生它的 Skill repository。

默认：

```text
skill-repository/
├── SKILL.md
├── cases/
│   ├── cases.ndjson
│   └── evidence/        # 只有复杂 Case 需要额外证据时才创建
└── ...
```

`cases.ndjson` 适合小记录、追加和 Git diff；如果 Skill 已有更合适的 Markdown / JSON / fixture 体系，直接复用。

Case 与 Skill revision 一起由该 Skill 自己的本地 Git history 管理，不要求独立 GitHub / GitLab remote。

原始 Case 始终留在产生它的 Skill 内。

## 6. 判断归因

问：

> 这个现象真正属于哪一层？

可能属于：

- Prompt / Principle；
- Workflow；
- Example；
- Skill discovery / packaging；
- Harness / Runtime；
- Tool / 权限 / 网络；
- 模型能力；
- 用户目标本身。

不是 Guidance 问题，就不要通过继续加 Prompt 修复。

**进入下一步：** 已知道应该改哪个 owner，或者确认不应改 Skill。

## 7. 决定是否需要改 Skill

明显、局部、可直接证实的缺陷可以直接形成候选修复，例如：

- 路径写错；
- API 已变；
- Prompt 明显遗漏用户明确要求；
- reference 已失效。

如果要形成更宽的通用原则，一个 Case 通常只够提出候选解释；优先找相邻 Case、boundary Case、cross-carrier Case 或独立 Evaluation。

不规定机械的“N 次以后才能升级”。

没有长期改动价值时：

```text
status = no-change
```

然后进入 Step 10。

## 8. 抽象并形成 Candidate change

从 Case 抽象时问：

> 换掉项目名、品牌、文件名和领域对象后，真正决定行为的关系还剩什么？

Specific Case：

```text
移动普通图片时自动生成哈希、备份和审计报告
```

不要直接变成：

```text
不要做额外验证
```

而应抽象成：

```text
当任务低风险、可逆，且不存在审计/恢复消费者时，
验证保持最低充分；
当风险、恢复要求或消费者改变时，提高验证强度。
```

Candidate change 可以落到：

- Principle / instruction；
- Workflow；
- Example；
- reference；
- script / schema / test；
- Skill boundary。

从 Principle 构造 Teaching Example 时走 [example-engineering.md](example-engineering.md)，不要直接匿名化源 Case。

## 9. Evaluation

任何声称“这次修改修复了问题 / 可以推广”的 Candidate change，都进入 [evaluation.md](evaluation.md)。

失败时按归因回退：

```text
归因错 → Step 6
抽象过宽 / 过窄 → Step 8
修改 owner 错 → Step 6
测试设计不足 → 补 Case 后重跑
```

通过后更新 Skill，由 Git 保存变更历史。

## 10. 关闭 Case

Case 不应永久停留在“待处理”。

最小状态：

```text
open
= 尚未决定如何处理

absorbed
= 已被某次 Skill 修改吸收，并完成必要 Evaluation

no-change
= 已调查，但不需要修改 Skill
```

关闭时至少记录：

- 最终 status；
- `absorbed` 时对应 commit / revision；
- `no-change` 时一句理由。

不要把 Skill 版本历史复制进 Case，只保存指针。

# Usage Case 与 Eval Case

### Usage Case

来自真实任务，是持续优化最重要的来源。

### Eval Case

人为构造或保留，用于检验 Candidate Guidance，例如 normal、boundary、holdout、regression、cross-carrier。

二者走同一保存与关闭流程，只是来源不同。

# Maintenance 与 Evolution

它们只描述最终变更性质，不是两套 Case 流程：

```text
Maintenance change
= 能力目标基本不变，只修复、适配、去腐化

Evolution change
= 能力目标、触发边界或抽象本身发生变化
```

无论哪一种都走：

```text
Case
→ Candidate change
→ Evaluation
→ Skill vNext
→ close Case
```

# 完成标准

一个 Case 处理完成时：

- Facts 与 Interpretation 已分开；
- Context 最小但足够；
- Case 保存在所属 Skill 内；
- 归因已经完成；
- 已决定是否需要 Skill 修改；
- 需要修改时已经形成 Candidate change 并完成必要 Evaluation；
- status 已从 `open` 变为 `absorbed` 或 `no-change`；
- Skill 变更历史仍由 Git 管理，而不是复制进 Case。

## 历史案例库

需要已有构造/历史案例时按需读取 [case-library.md](case-library.md)。

案例库不是活动 Guidance，不默认进入运行上下文。
