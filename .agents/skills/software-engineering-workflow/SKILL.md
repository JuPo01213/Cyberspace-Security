---
name: software-engineering-workflow
description: 面向真实代码仓库的软件工程主工作流。用于新功能、局部修改、Bug/回归/性能、重构/架构调整、调研原型和跨会话大型开发；入口负责按任务分支与运行事件精确路由到所需 reference，而不是一次加载全部工程文档。
---

# Software Engineering Workflow

目标：把用户意图推进为**可追溯、可验证、可审查、可交付的软件行为**。

主链：

`Explore → Design → Design Alignment（用户可感知设计）→ Plan → Baseline → Implement → Review → Accept → Finish`

Requirement Discovery 可以在任意阶段发生，并回流到前面的适当阶段。


## Startup Bootstrap

本节在**每次加载本 Skill 后、Primary Route 判定之前**执行。它不是可选事件。

### 1. Git bootstrap：默认已授权

加载本 Skill 即视为用户已经授权 Agent 对当前软件项目执行**非破坏性的本地 Git 管理**，无需再次询问是否可以初始化仓库。

1. 确定当前项目根目录；若已经位于 Git repository / worktree 中，使用现有仓库，不创建嵌套仓库。
2. 若项目目录不是 Git 仓库且目录可写：
   - 优先执行 `git init -b main`；
   - 若当前 Git 不支持该参数，则执行 `git init`，保留本地默认分支。
3. 立即读取：
   - repository root；
   - current branch / HEAD；
   - `git status --short`；
   - 是否已有 commits；
   - 是否存在用户未提交改动。
4. 在任何代码修改前建立可比较的 baseline。
5. 把 Git 当作项目历史系统：
   - 普通代码/文档只保留当前有效版本；
   - 不通过复制 `foo-v1 / foo-v2 / foo-final2` 保存历史；
   - 重要演进用有意义的 commit 记录；
   - 需要查看旧状态时用 `git log/diff/show` 恢复。


默认授权包括：`init/status/diff/log/add/commit/branch/worktree` 等本地、可恢复的 Git 操作。

**授权不自动扩展到：**
- `git reset --hard`；
- `git clean -fd`；
- 丢弃或覆盖用户未提交工作；
- 强制改写历史；
- 向远端 push / force-push；
- 删除远端分支。

这些属于破坏性或外部副作用，必须有独立依据。

### 2. 初始 commit

新建仓库不等于立刻 `git add -A && git commit`。

第一次 commit 前先检查明显不应进入版本库的内容，例如：
- `.env`、credential、private key、token；
- build/cache/vendor 产物；
- 大型临时文件；
- 平台本地运行状态。

安全后，把当前可信项目状态作为 baseline commit。若无法安全判断，不要为了“必须有首个 commit”把未知文件全部纳入版本控制。

### 2.1 文档与 ADR 的版本原则

- **Living document**：同一路径持续更新，Git 保存历史；不复制版本文件。
- **ADR / Decision Record**：同样纳入 Git。重要决策可以拥有稳定 ID；若新决策真正取代旧决策，可新建一个 superseding decision 并引用旧 ID。不要制造 `ADR-v2/ADR-final`。
- **正式版本制品**：只有版本号本身具有外部语义（例如 API v1/v2、发布说明、迁移格式）时，才允许多个版本并存。

原则：**当前目录表达 current truth，Git 表达 history。**


### 3. Project control plane

当满足任一条件时，在正式开发前触发 `DURABLE STATE`：
- 新建一个会持续开发的软件项目；
- 任务明显跨多个阶段或会话；
- 已经存在需要长期保持的 Requirement / Decision / Architecture Contract。

这时读取 `references/project-state.md`，初始化项目状态协议。

初始化时必须遵守：
- `INDEX.md` 只做小型导航；根 INDEX 过大时建立领域级二级 INDEX，而不是继续膨胀；
- 状态按语义责任分片，不用 V1/V2/V3 或会话编号分片；
- handoff/Continuation 是有界 current view，**replace-in-place，不追加历史**；
- 旧状态由 Git / canonical docs / source history 保存；
- 超出预算先拆分/清理，再继续写。

小型一次性补丁不为了仪式感强制创建状态目录，但 Git bootstrap 仍然执行。


## Router Contract

**先路由，再读文件。不要预加载全部 references。**

开始任何实质工作前：

1. 选择一个**主任务分支**；
2. 沿该分支推进，但**只在进入对应阶段前**读取该阶段的 reference；
3. 工作过程中若出现“事件触发器”，立即追加读取对应文件；
4. 一个阶段尚未到、一个事件尚未触发，就不要为了“更完整”提前加载它的 reference；
5. 两个主分支都像时，按任务目标选更具体的一个，不把两个分支的文件简单并集。

### 分支判定

- **小型局部修改**：目标行为明确，只改少量现有 seam，不需要重新设计产品结构。
- **新功能 / 中型改动**：新增或明显改变用户可感知行为，需要设计与计划。
- **Bug / 回归 / 性能**：目标是恢复已知正确行为、找根因或改善已定义指标。
- **重构 / 架构调整**：主要目标是改变内部结构，同时尽量冻结现有行为。
- **Research / Prototype**：主要目标是消除事实未知或设计未知，还不是生产实现。
- **大型 / 跨会话任务**：不是独立主分支；先选择上面的真实工作分支，再叠加 Project State 事件。

如果“正确行为是什么”本身没有定义，就不是纯 Bug；先触发 Requirement Discovery。

## Route Resolution

路由只做两次判断：

1. **任务目标是什么？** 用它选 Primary Route。
2. **当前发生了什么特殊事件？** 用它触发 Event Reference。

不要按文件名、关键词数量或“这个也可能有用”来选 reference。

常见歧义：
- “修一个问题”但正确行为未定义 → Bug 主分支 + USER DECISION，不是 Feature 文件全加载。
- “新增功能”过程中发现性能根因 → Feature 主分支 + FACT / DESIGN UNKNOWN，不切成整套 Bug 路由。
- “重构”过程中用户行为变化 → Refactor 主分支 + Requirement Discovery。
- “跨会话”不是开发类型 → 真实主分支 + DURABLE STATE。

每次准备读取一个 reference 前，应该能用一句话回答：

> **哪个阶段或哪个事件刚刚触发了它？**

答不出来就不要读。

## Primary Routes

### 小型局部修改

流程：

`Inspect → Contract → Patch → Verify → Review → Finish`

**阶段指针：**
- 进入 `Patch / Implement` 前 → 读 `references/implementation.md`
- 进入 `Review` 前 → 读 `references/code-review.md`
- 进入 `Verify / Accept` 前 → 读 `references/acceptance.md`
- 进入 `Finish` 前 → 读 `references/finishing.md`

不要在任务开始时一次加载以上四个文件。

**条件升级：**
- 发现现有结构本身需要改变 → 追加 `references/software-design.md`
- 修改会形成未定义用户行为 → 触发 USER DECISION / Requirement Discovery
- 只有局部确定性修改时，不读 design、questionnaire、project-state

### 新功能 / 中型改动

流程：

`Explore → Requirement Discovery → Design → Design Review → Design Alignment → Plan → Baseline → Implement → Review → Accept → Finish`

**阶段指针：**
- 进入 `Requirement Discovery` → 读 `references/requirements-and-decisions.md`
- 进入 `Design` → 读 `references/software-design.md`
- 中高风险设计进入 `Design Review` → 使用同一 `software-design.md` 的独立审查协议
- 进入 `Design Alignment` → 读 `references/user-communication.md` 的设计对齐协议；先让用户看懂实际使用流程，再处理尚未确认的产品取舍
- 进入 `Plan` → 读 `references/implementation-planning.md`
- 进入 `Implement` → 读 `references/implementation.md`
- 进入 `Review` → 读 `references/code-review.md`
- 进入 `Accept` → 读 `references/acceptance.md`
- 进入 `Finish` → 读 `references/finishing.md`

这些文件按阶段加载，不在 Explore 时全部读取。

用户已经把行为讲得很清楚，也仍应在进入 Requirement Discovery 时读 `requirements-and-decisions.md`；它负责区分 Confirmed / Assumed / Open Decision，以及实现中重新发现的需求，不只是“向用户提问”。

### Bug / 回归 / 性能

流程：

`Reproduce → Minimize → Hypothesize → Instrument → Fix → Regression → Review → Accept → Finish`

**阶段指针：**
- 进入 `Reproduce / Diagnose` → 读 `references/debugging.md`
- 进入 `Fix` → 读 `references/implementation.md`
- 进入 `Review` → 读 `references/code-review.md`
- 进入 `Accept` → 读 `references/acceptance.md`
- 进入 `Finish` → 读 `references/finishing.md`

**条件升级：**
- 期望行为不明确 → 追加 `references/requirements-and-decisions.md`
- 修复需要重新设计 seam → 追加 `references/software-design.md`
- 性能/外部机制存在事实未知或设计未知 → 追加 `references/research-and-prototyping.md`
- 方案会改变进程/后台服务的生命周期，或持续占用 GPU、内存等资源 → 这是设计取舍；读 `references/software-design.md` 和 `references/user-communication.md`，先把资源何时占用/释放讲成用户可感知的流程，再决定实现。

如果“正确行为是什么”还没定义，就先解决 Requirement Gap，不以“修 Bug”为名替用户决定产品行为。

### 重构 / 架构调整

流程：

`Inspect → Freeze Behavior → Design → Design Review → Design Alignment（用户行为、资源生命周期或成本取舍变化时）→ Migration Plan → Incremental Refactor → Regression → Review → Accept → Finish`

**阶段指针：**
- 进入 `Design` → 读 `references/software-design.md`
- 中高风险设计进入 `Design Review` → 使用同一 `software-design.md` 的独立审查协议
- 重构改变用户可感知行为，或改变后台服务/模型/资源的生命周期与持续成本时，进入 `Design Alignment` → 读 `references/user-communication.md` 的设计对齐协议
- 进入 `Migration Plan` → 读 `references/implementation-planning.md`
- 进入 `Incremental Refactor` → 读 `references/implementation.md`
- 进入 `Review` → 读 `references/code-review.md`
- 进入 `Accept` → 读 `references/acceptance.md`
- 进入 `Finish` → 读 `references/finishing.md`

无真实外部消费者时，不为“可能兼容”保留旧路径；直接迁移调用方并删除 legacy 结构。

若重构实际改变用户行为，立即触发 Requirement Discovery，不继续把它称为“纯重构”。

### Research / Prototype

流程根据未知类型选择，不强行走完整生产链。

**阶段指针：**
- 需要确认外部事实、官方能力、已有成熟方案 → 读 `references/research-and-prototyping.md` 的 Research 部分
- 需要用一次性实现验证设计可行性 → 读同文件的 Prototype 部分

一旦从探索转为生产实现，重新选择对应主任务分支；不要因为 prototype 已经能跑就让它自然滑成 production。

## Event Triggers

事件 reference 是**条件加载**。触发条件比文件名更重要。

### DESIGN ALIGNMENT — 用户需要理解并校准拟议设计

当设计新增或改变用户可感知的流程、默认行为、数据去向或重要取舍时，在 Plan / 实施前读取 `references/user-communication.md` 的设计对齐协议。用户已经讲清需求，不代表已经理解或认可代理提出的方案。用一个真实场景讲明输入、过程、结果与出错时的表现，说明关键取舍，并给用户纠正方案的机会；用户表示不理解时先换一种说法或举例，不把沉默、困惑或单纯提出需求当成设计同意。已由用户明确指定的具体方案和行为不重复索要批准；纯内部、行为不变的局部重构也不设置形式上的确认门槛。

### USER DECISION — 需要用户做产品判断

当技术选择会改变用户可感知行为、业务语义、数据/隐私/费用、兼容性、不可逆结果，而现有 Requirement 未定义时：

**读取：**
- `references/user-communication.md`
- `references/requirements-and-decisions.md`（若当前主分支尚未读取）

不要把 class、API、schema、框架或设计模式直接抛给非技术用户；先翻译成实际行为和使用场景。

### BATCH DECISIONS — 同时有多个独立用户决策

当存在 **2 个或以上可以在同一轮独立回答**、且都值得占用用户注意力的产品决策时：

**读取：**
- `references/decision-questionnaire.md`
- `references/user-communication.md`

使用当前 decision frontier；推荐答案作为默认值，用户主要修改例外或标记“不确定”。

**不要触发：**
- 只有一个关键问题；
- 后一个问题依赖前一个答案；
- 只是内部工程选择。

### SEMANTIC DRIFT — 历史意图、摘要或术语可能失真

当出现任一情况：
- 当前关键结论只来自压缩 summary / memory；
- Requirement 经过多次总结、翻译或专业化表达；
- 用户原话与当前 Spec/术语可能不一致；
- 同一概念出现多个含义；
- 代码行为与 Requirement 可能发生漂移；
- 需要从历史记录恢复关键决定；

**读取：**
- `references/semantic-integrity.md`

**不要触发：**
- 当前任务不依赖历史意图；
- 普通术语只是工程内部命名，没有用户语义风险；
- 已有带来源且仍适用的 Confirmed Decision 足以支撑当前判断。

### FACT / DESIGN UNKNOWN — 当前不知道事实或设计是否可行

**读取：**
- `references/research-and-prototyping.md`

Research 解决“世界是什么”；Prototype 解决“这个设计能不能工作”。用户价值选择不靠实验替用户决定。

### WORKSPACE RISK — Git 状态或并行修改会影响安全

当工作树有用户未提交改动、任务改动较大、需要独立分支/worktree、存在并行开发或冲突风险时：

**读取：**
- `references/git-and-workspaces.md`

普通只读分析或极小无冲突改动，不为仪式感强制建立 worktree。

### DURABLE STATE — 任务跨会话/跨模型，或产生长期有效决策

当项目需要跨会话持续，或出现会长期影响后续工作的稳定 Requirement / Decision / Constraint 时：

**读取：**
- `references/project-state.md`

模型提出 candidate state update；只有满足晋升条件才进入 Durable Project State。

长项目还必须维持 bounded state topology：`INDEX → relevant shards → current Continuation`，禁止单文件 handoff 累积历史。

**不要触发：**
- 一次性临时任务；
- 临时方案、猜测、实现细节；
- 为“以后也许有用”而囤积信息。

### WORKFLOW META — 正在修改 Skill / Harness / Agent 规则

只有在编辑本工作流、设计新的 Agent 行为，或工作流规则互相冲突时：

**读取：**
- `references/foundations.md`

普通软件开发任务不要加载它。

## Always-on Invariants

这些规则不需要额外 reference 才生效：

1. **需求可被发现，不能被偷偷决定。**
2. **用户表达需求不等于用户理解并认可代理设计。** 对会改变使用体验的方案，先完成设计对齐，再进入实施计划。
3. **用户注意力和认知负担是预算。** 模型先研究、判断、给默认；用户主要处理例外。
4. **用户原始表达不能被派生摘要、专业术语或实现细节覆盖。**
5. **事实未知、设计未知、价值未知分开处理。**
6. **没有最新证据，不声明完成。**
7. **没有真实兼容责任时，重构优先于补丁和 legacy 兼容层。**
8. **不要为了“更完整”读取未触发的 reference。**
9. **Git 是默认项目基础设施。** 非 Git 项目在 Skill 启动时自动初始化；不以“未明确授权”为理由跳过本地 Git 管理。
10. **状态记录按事件同步，不等待上下文告急。** 关键决策一旦确认就立即持久化候选；上下文压力只负责触发额外 continuation checkpoint。
11. **状态必须有界且可路由。** `INDEX` 只导航，durable state 按语义分片，Continuation 覆盖式更新；禁止把长期项目追加成一个巨型 handoff。
12. **工作树只保存当前真相，版本历史交给 Git。** 普通文档和代码禁止用复制文件维持 V1/V2/V3 历史。

## Stage Gates

- **Explore → Design**：理解现有系统、可复用 seam、关键未知。
- **Design → Design Alignment**：关键用户行为、NFR、风险与主要 trade-off 已明确；中高风险设计已完成独立 Design Review；方案已能用具体使用场景向用户讲清。
- **Design Alignment → Plan**：用户可感知的行为与会持续占用/释放资源的取舍，已用具体场景说明并由用户校准；仍表示不理解或不认可的部分不得被写成已确认设计。无行为、资源生命周期或成本变化的内部修改可跳过此门槛。
- **Plan → Implement**：任务可执行、可验证；关键依赖和迁移路径清楚。
- **Implement → Review**：计划内行为完成，局部验证已有新鲜证据。
- **Review → Accept**：Blocker/Major 已处理；Requirement Gap 已确认或明确阻塞。若修复超出已对齐方案，或需要新的架构、公共接口、资源生命周期或产品取舍，退回对应的 Design / Design Alignment，不在 Review 阶段顺手改代码。
- **Accept → Finish**：验收证据充分，没有未处理的关键行为漂移或 legacy 残留。

## Completion

完成时必须能说明：
- 实现了哪些已确认行为；
- 用什么证据验证；
- 是否发现并处理了新的 Requirement Gap；
- 是否仍有未验证或不确定项；
- Git / 文档 / Project State 是否需要收口；
- 是否留下无消费者的兼容层、临时迁移逻辑或旧路径。

如果回答不了其中与当前任务相关的项，任务还没有完成。
