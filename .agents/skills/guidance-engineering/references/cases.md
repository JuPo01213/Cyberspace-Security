# Cases：使用经验与 Skill 反馈回路

## 定义

Case 是 Guidance Engineering 的**学习载体**：

> **记录一次真实使用或一次专门测试中，Skill 在具体条件下实际表现了什么。**

Skill 是压缩后的经验；Case 是新的、尚未完全压缩的经验。

Case 不等于 Example：

```text
Case
= 发生过什么 / 测到了什么

Example
= 为了教模型某个行为，主动给模型看什么
```

Case 也不等于 Rule。一个 Case 可以触发调查和修改，但不会自动获得长期指令权。

## 两种主要来源

### Usage Case

来自真实任务：

- 用户实际目标；
- 当时使用的 Skill / revision；
- 相关环境；
- 模型实际行为；
- 用户纠正或结果；
- 必要证据。

它是持续优化最重要的来源。

### Eval Case

人为构造或保留，用来检验某个候选 Guidance：

- normal case；
- boundary case；
- holdout；
- regression；
- cross-carrier case。

Usage Case 和 Eval Case 都是 Case，只是来源与用途不同；不需要为它们再建立不同生命周期。

## 最小记录

Case 只保存将来重新理解这次经验所需的信息：

```yaml
case_id: CASE-...
skill: skill-name
skill_revision: git-sha-or-version

context:
  task: 这次实际要完成什么
  relevant_environment: 只记录会改变判断的模型/Harness/工具/权限

observed:
  - 实际发生的可观察行为

feedback_or_outcome:
  - 用户纠正、成功/失败结果或关键影响

interpretation:
  - 当前认为可能是什么问题；允许为空、允许以后被推翻

evidence_refs:
  - 可选；只指向真正需要保留的 trace / output / file
```

不要为了“完整日志”复制整段聊天、所有工具输出或无关上下文。

## Facts 与 Interpretation 分开

Case 中最重要的边界：

```text
Fact:
模型没有搜索，直接开始手写解析器。

Interpretation:
可能存在“过早自建、没有发现成熟能力”的问题。
```

前者是观察，后者是解释。

以后发现真正原因是工具没有暴露，也不覆写原始事实；只更新 interpretation 或后续结论。

## 如何保存

Case 属于产生它的 Skill repository，是 Skill 演化上下文的一部分，而不是全局知识数据库。

Case 默认不进入运行时上下文，避免正常使用时把全部历史塞入上下文；但它必须保存在产生它的 Skill 文件夹内部，并随这个 Skill 自己的本地 Git repository 一起版本化。

这里不要求 Skill 有独立 GitHub / GitLab remote。Case 与 Skill 的绑定来自同一个本地 Git history，而不是来自远端托管关系。

默认结构：

```text
skill-repository/
├── SKILL.md
├── references/
├── examples/
├── cases/
│   ├── cases.ndjson
│   └── evidence/        # 只有复杂 Case 真需要额外证据时才创建
└── scripts/
```

Skill repository owns:

- current guidance;
- supporting resources;
- usage cases;
- evaluation evidence;
- Git history.

`cases.ndjson` 适合追加、小记录、Git diff 和程序筛选；如果 Skill repository 已有更合适的 Markdown / JSON / test fixture 体系，直接复用，不为了格式迁移。

Case 必须能追溯到当时的 Skill revision。Skill 的版本差异由 Git 保存，不在 Case 里复制完整旧文件。

原始 Case 始终留在产生它的 Skill 内。可以从 Case 抽象出新的通用 Principle，甚至形成另一个 Skill，但不要因此把源 Case 搬出原 Skill。

## Case 如何反哺 Skill

最小反馈回路：

```text
1. 读取相关 Case
2. 判断问题是否真的属于 Guidance
3. 抽象可迁移关系
4. 找到唯一 owner
5. 做最小候选修改
6. Evaluation
7. 通过后更新 Skill 并 commit
```

### 先判断归因

一次失败可能来自：

- Prompt / Principle；
- Workflow；
- Example；
- Skill discovery / packaging；
- Harness / Runtime；
- Tool / 权限 / 网络；
- 模型能力；
- 用户目标本身。

不是 Guidance 问题，就不要通过继续加 Prompt 修复。

### 从 Case 抽象，而不是照抄

问：

> 换掉项目名、品牌、文件名、领域对象后，真正决定行为的关系还剩什么？

如果一个具体 Case 是：

```text
移动普通图片时自动生成哈希、备份和审计报告
```

不要直接写：

```text
不要做额外验证
```

应抽象成条件化原则，例如：

```text
当任务低风险、可逆，且不存在审计/恢复消费者时，
验证保持最低充分；
当风险、恢复要求或消费者改变时，提高验证强度。
```

### 一个 Case 什么时候足够

明显、局部、可直接证实的缺陷可以由一个 Case 触发修复，例如：

- 路径写错；
- 当前 API 已变；
- Prompt 明显遗漏用户明确要求；
- reference 已失效。

要形成更宽的通用原则时，一个 Case 通常只够提出候选解释；优先找相邻 Case、边界 Case 或独立 Eval 来检验是否过度抽象。

不规定机械的“N 次以后才能升级”。

### 从 Principle 到 Example

如果抽象规则难以只靠 instruction 稳定表达，再生成 Teaching Example。

这时不要把原 Case 匿名化，而要：

```text
Specific Case
→ abstract Principle
→ new Generic Example
```

Example 的构造见 [example-engineering.md](example-engineering.md)。

## 变更性质：Maintenance / Evolution

这两个词只描述修改结果，不是两个工作流。

### Maintenance change

能力契约基本不变：

- 修 Prompt；
- 更新过时 reference；
- 适配模型/API；
- 删除无价值 Example；
- 修复 discovery；
- 去重复和上下文腐化。

### Evolution change

能力本身发生变化：

- 新增/删除稳定能力；
- 扩大或收缩触发边界；
- Skill merge / split；
- Prompt 升格为独立 Skill；
- 重构能力抽象。

无论哪一种，都走同一个闭环：

```text
Case → candidate change → Evaluation → Skill vNext
```

## 不要自动修改

真实使用产生 Case，不代表每次都立刻改 Skill。

只有当 Case 能指出一个有消费者的真实缺口，且修改值得长期承担时，才进入候选修改。

否则保留 Case 即可。

## 历史案例库

需要已有的构造/历史案例时按需读取 [case-library.md](case-library.md)。

案例库不是活动 Guidance，不默认进入运行上下文。
