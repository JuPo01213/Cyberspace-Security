# 设计参考

本 Skill 吸收公开工程工作流与用户提供的历史讨论，但所有材料都只是设计输入，不是当前规范的权威来源。

## Matt Pocock Skills

参考：`https://github.com/mattpocock/skills`

主要吸收：
- idea / grill / spec / tickets / implement / review 的阶段意识；
- decision tree / frontier：相互独立的问题批量处理，依赖问题推迟；
- research 解决事实未知，prototype 解决设计未知；
- domain modeling / shared language；
- vertical slice / tracer bullet；
- codebase-design 的深模块、小接口、clean seam；
- review 分规格符合性与工程质量。

本 Skill 的关键调整：共享语言只能作为来源索引；面向非技术用户时，优先用户结果而不是实现术语。

## Superpowers

参考：`https://github.com/obra/superpowers`

主要吸收：
- 编码前共享设计；
- 具体 implementation plan；
- RED → GREEN → REFACTOR；
- fresh reviewer / verification-before-completion；
- Git/worktree 与基线意识。

没有机械复制所有任务都 worktree、严格 TDD 或固定流程长度。

## 用户提供的早期 DeepSeek 讨论记录

该记录被明确视为**早期参考材料**，不是当前规范。吸收的是经过后续反例仍有价值的机制：

- 场景化而不是空白式追问；
- 选项/纠偏优于让用户从零创造答案；
- 模型先形成默认判断；
- 多角度验证只用于冲突、高影响或低置信度需求；
- 深层映射用于找到真正的软件行为与规模，而不是替用户“劝退开发”；
- 通过反例持续暴露框架盲区；
- 低带宽需求可用原型作为沟通媒介。

明确淘汰：固定问题数量、固定五层万能模板、无条件默认本地/单用户/无登录、故意使用离谱危险诱饵等过时或过强做法。

## 本 Skill 当前核心

- Requirement Discovery Loop
- Attention / Cognitive Load Budget
- Recommended Defaults + Exception-driven Questionnaire
- Requirement Provenance
- Behavior Reconstruction / Convergence
- Source Recovery
- Shared Language as Index
- Project State Promotion
- Refactor over Compatibility Patch
- Invariant / Procedure / Gate

## v5 路由重构参考

v5 将 `SKILL.md` 明确为唯一主路由，并把外部 reference 的价值建立在“触发条件明确”而不是“文件存在”上。

设计参考：
- Matt Pocock, `writing-for-agents`: context pointer 同时要说明材料是什么、哪些 branch 触发它；pointer wording 决定 agent 是否可靠到达 reference。
- 同一资料强调 progressive disclosure 应按 branch 进行：所有 branch 都需要的内容留在入口，只在部分 branch 需要的材料才下沉。
- `SKILL-MECHANICS.md` 对 router skill / model invocation 的讨论进一步强调：新增可独立触发的 skill 或 reference 都会增加 context/cognitive load，应由清晰独立的触发条件证明其价值。

本 Skill 因此采用：
`Primary Route + Event Trigger + Negative Trigger`。

同时删除 `development-workflow.md`，因为主生命周期和路由属于所有 branch 的共同内容；合并 traceability/source-recovery/shared-language 为 `semantic-integrity.md`，因为它们通常由同一语义漂移事件共同触发。
## v6 设计 / Review / 状态生命周期补强

### Code design

- Matt Pocock `codebase-design`
  - 采用 module / interface / depth / seam / adapter / leverage / locality 作为稳定设计词汇。
  - 吸收四个高价值原则：depth 看 interface；deletion test；interface 是主要 test surface；不要为了假想变化提前切 seam。
  - `Design It Twice` 只用于长期、高迁移成本 interface，不机械用于所有 helper。
- Matt Pocock `improve-codebase-architecture`
  - 参考其“deepening opportunity”和 locality 思路，但不把“必须产出 finding”当成正确性目标。

### Code review

- Matt Pocock `code-review`
  - 固定 Git fixed point；
  - Spec 与 Standards 独立；
  - repo standards 优先；
  - Fowler high-signal smell baseline；
  - 独立 reviewer/context 降低相互锚定。
- obra/superpowers `requesting-code-review`
  - review early, review often；
  - reviewer 使用明确 base/head、requirements 与只读 checkout。
- obra/superpowers `receiving-code-review`
  - reviewer finding 也必须重新技术验证，不做表演式同意。

本 Skill 在这些基础上增加独立 Correctness/Bug-Hunt 与 Test-Quality axes，因为目标是高召回真实问题，而不只是 standards/spec compliance。

### Project instructions / context lifecycle

- OpenAI Codex `AGENTS.md` 官方文档
  - Codex 会在任务开始前自动读取项目级 `AGENTS.md`；
  - 项目指令有层级和大小限制，因此动态项目状态不应不断堆进该文件。
- Anthropic Claude Code memory 文档
  - `CLAUDE.md` 是项目 instruction/memory 入口；
  - 支持 `@path` 导入，可用于薄平台 adapter。
- OpenAI Responses compaction / Codex app-server
  - compaction 是运行时能力；Harness 可以用 threshold / compaction 事件实现 context-pressure 协议。
- Anthropic long-horizon prompting
  - 支持 context-awareness 的模型可以感知剩余 token budget；
  - 这种能力不能假设跨平台普遍存在，因此本 Skill 仍以事件驱动 state sync 为基础。
## v7：Git 文档历史、Design Review 与更广泛 Review 参考

### Git / Patch discipline

- Git Book, `Recording Changes to the Repository`
  - commit 是项目状态 snapshot；工作树继续表示当前状态。
- Linux Kernel, `Submitting patches`
  - 一个 patch 解决一个逻辑问题；
  - patch 描述应 self-contained；
  - logical changes 分开；
  - 中间 patch 在合理范围内保持 build/run 可用，方便 review 与 bisect。

本 Skill 由此明确：
- living docs 不创建 v1/v2/v3 副本；
- current truth 留在当前文件；
- history 交给 Git；
- mechanical change 与 semantic change 尽量拆分。

### ADR / Design Decisions

- Microsoft Engineering Fundamentals, `Design Decision Log`
  - ADR 可以直接存储并追踪在 Git 等版本控制系统；
  - 重要架构决策可使用稳定 ID / decision log。
- Microsoft `Design Reviews`
  - design artifacts、decision logs、trade studies、spikes 可以放在 repo 中并通过 PR/review 管理。

本 Skill 不把 ADR 当第二套版本历史；ADR 表达 decision identity/status，Git 表达文件演变。

### Design / Code Review

- Google Engineering Practices, `What to look for in a code review`
  - design、functionality、complexity、tests、naming、comments、style、documentation；
  - reviewer 仍需主动思考 edge case、concurrency 和真实用户影响；
  - 警惕 over-engineering 与未来假想需求。
- Microsoft Engineering Fundamentals, `Reviewer Guidance`
  - reviewer 读取全部 changed lines 与必要 surrounding context；
  - 人工 review 聚焦 architecture、business logic、tests、maintainability；
  - edge cases、concurrency、security、PII 都属于重要检查点。
- Microsoft Engineering Fundamentals Checklist
  - major component 应进行 design review 并记录 alternatives；
  - 明确 NFR / risks；
  - source control / tests / CI / observability / security 作为工程基础。
- OWASP Secure Code Review
  - baseline review 与 diff-based review；
  - architecture、entry points、trust boundaries、data flow、authn/authz、business logic、crypto、error/config；
  - manual review 与 automated scanners 互补。
- OWASP Business Logic Security
  - 检查合法流程、假设、顺序绕过、重复执行、并发 actor、contextual authorization。

这些来源被提炼为通用核心 + trigger-based specialist，不机械拼成巨大 checklist。


## v8：长项目状态分片与有界 Handoff

- OpenAI, `Harness engineering: leveraging Codex in an agent-first world`
  - 长期 Agent 工程中，单体巨型 `AGENTS.md` 会挤占 context、稀释重要规则、快速腐化并难以验证；
  - 更有效的方式是给 Agent “地图”而不是“千页手册”，把仓库知识做成可导航的 system of record。
- OpenAI Codex `AGENTS.md`
  - 项目指令存在默认大小上限，进一步说明自动加载入口应保持短小并只负责导航/约束。
- OpenAI long-running model guidance / compaction
  - 长任务 compaction 应保留 completed actions、active assumptions、tool outcomes、unresolved blockers 与 next goal；
  - 本 Skill 将这类信息放入 bounded Continuation current view，而不是无限历史 handoff。

v8 因此规定：
`INDEX → relevant shards → bounded current view → Git/source history on demand`。
