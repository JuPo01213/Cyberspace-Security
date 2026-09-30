# Software Engineering Workflow Skill

一套中文软件工程 Agent Skill。`SKILL.md` 是唯一主路由，同时负责启动期 Git bootstrap；reference 只在明确阶段或事件触发时加载。v6 重点强化代码设计、独立多轴 Code Review，以及跨模型/跨压缩的 Project State 生命周期。

## 路由原则

正常执行采用两级路由：

1. **Primary Route**：小修改 / 新功能 / Bug-性能 / 重构 / Research-Prototype。
2. **Event Trigger**：用户决策、批量问卷、语义漂移、事实未知、Git 风险、长期状态、工作流元修改。

入口文件负责说明**什么时候读哪个 reference、在什么阶段读、以及什么时候不要读**。主分支不是“任务开始时的文件包”，而是一组阶段指针。

```text
Task
 ↓
Primary Route
 ↓
Required References
 ↓
Work
 ↓
Event fires?
 ├─ No  → continue
 └─ Yes → load exactly that event reference
```

## 当前目录

```text
software-engineering-workflow/
├── SKILL.md                         # 唯一路由入口
├── README.md
├── SOURCES.md
├── manifest.json
├── references/
│   ├── requirements-and-decisions.md
│   ├── user-communication.md
│   ├── decision-questionnaire.md
│   ├── semantic-integrity.md
│   ├── project-state.md
│   ├── research-and-prototyping.md
│   ├── software-design.md
│   ├── implementation-planning.md
│   ├── git-and-workspaces.md
│   ├── implementation.md
│   ├── debugging.md
│   ├── code-review.md
│   ├── acceptance.md
│   ├── finishing.md
│   └── foundations.md
└── templates/
    └── decision-questionnaire.html
```

## 为什么合并

v4 中：
- `requirement-traceability.md`
- `source-recovery.md`
- `shared-language.md`

通常围绕同一个“语义是否漂移、来源是否可靠”的事件一起出现，因此合并为 `semantic-integrity.md`，避免模型自己拼装三个相邻概念。

原 `development-workflow.md` 被移除：主生命周期和路由是所有任务都需要看到的内容，应该由 `SKILL.md` 直接承担，而不是藏在外部 reference 后面。

四个 foundations 也合并为一个 `foundations.md`，且只在修改 Skill/Harness 或解决工作流冲突时触发。

## 问卷

`decision-questionnaire.md` 只在同时存在多个独立用户决策时触发。

HTML 模板支持：
- 推荐值默认选中；
- 用户只改不同意项；
- 自定义回答；
- “不确定”；
- 一次提交；
- 结构化 JSON 输出。

## 设计偏好

- 默认非技术用户；
- Attention Budget / Cognitive Load Budget；
- Requirement Discovery 贯穿全流程；
- 原始表达与关键决定可追溯；
- Project State 受控晋升，不自由写长期 Memory；
- 无真实外部兼容约束时重构优先；
- 验证强度与风险相匹配；
- 删除比叠加兼容补丁更优先。


## 读取时机

即使命中了一个 Primary Route，也不把该分支的所有 reference 一次性加载。

例如新功能：

```text
Requirement Discovery → requirements-and-decisions
Design                → software-design
Plan                  → implementation-planning
Implement             → implementation
Review                → code-review
Accept                → acceptance
Finish                → finishing
```

这使 `SKILL.md` 同时承担“选什么”和“什么时候读”的责任。


## v6 关键变化

### Git 默认初始化

加载 Skill 即视为已经授权非破坏性的本地 Git 管理。

- 非 Git 项目自动 `git init`；
- 现有仓库自动识别 root / branch / status；
- 新仓库第一次 commit 前先排除 secret、cache、build/vendor 产物；
- 不自动获得 destructive reset/clean、远端 push/force-push 权限。

### 设计质量

`software-design.md` 现在加入统一的 Module / Interface / Depth / Seam / Adapter / Locality / Leverage 词汇，以及：

- deep module；
- deletion test；
- interface = test surface；
- seam 必须赚回复杂度；
- state ownership；
- dependency direction；
- change locality；
- Design It Twice；
- 可执行 architecture boundary；
- 单一权威表示与无 legacy 双轨。

### 高召回 Code Review

`code-review.md` 使用固定 Git review range，并按多个独立 axis 检查：

1. Spec / Behavior；
2. Correctness / Bug Hunt；
3. Design / Maintainability + smell baseline；
4. Test / Verification Quality；
5. Behavioral Discovery；
6. risk-specific specialists。

中大型任务优先使用 fresh reviewer / 独立 pass，降低锚定。

### Project State / Context Lifecycle

静态记录规则与动态状态分离：

```text
AGENTS.md / CLAUDE.md adapter
        ↓
.agent/state/       # durable, promoted truth
.agent/runtime/     # replaceable continuation checkpoint
```

关键决策靠**事件触发**立即同步，不等待上下文快满。

Harness 如果知道 remaining context / compaction，则额外提供：
`context_pressure = normal | elevated | critical`
并在 elevated/critical 时刷新 continuation。


## v7 关键变化

### Git = 历史系统

普通代码和活文档只保留当前有效文件，不再用 `v1/v2/v3/final2` 副本保存历史。

- current truth → 工作树当前文件；
- history → Git commit；
- change explanation → self-contained commit message；
- review/bisect/rollback → logical commit history。

ADR 同样纳入 Git。ADR 的独立文件/ID用于表达“决策身份与 supersession”，不是替代 Git 做版本历史。

### Design Review

中高风险设计在 Plan 前增加独立 Design Review，重点检查：
- Requirement；
- NFR；
- risk；
- state ownership；
- dependency/data flow；
- failure/recovery；
- observability；
- migration；
- complexity；
- alternatives / Design It Twice。

### Review 体系

Code Review 进一步参考成熟大型工程实践，形成：
- universal axes；
- risk-triggered specialists；
- repo/ecosystem standards；
- automated checks；
- logical commit / reviewability；
- review learning loop。

新增 operational/observability axis，以及 baseline-vs-diff security review。


## v8 关键变化

### 长项目状态不再允许单文件膨胀

状态结构改为：

```text
Small INDEX
   ↓
Relevant semantic shards
   ↓
Bounded current Continuation/workstream view
   ↓
Git / source history on demand
```

`CONTINUATION.md` 明确是 **replace-in-place current view**，不是 append-only journal。

默认防膨胀 guardrail：
- state protocol ≤ 8 KiB
- INDEX ≤ 12 KiB
- active Continuation/workstream ≤ 16 KiB
- durable shard target ≤ 24 KiB，约 32 KiB 前必须拆分或重构

分片按 product area / subsystem / bounded context / active workstream，而不是日期、会话或 V1/V2/V3。

新 session 禁止通读全部 state：先 INDEX，再当前 continuation，再按 pointer 读相关 shard，够用即停止。

根 `INDEX.md` 自身也受预算约束；大型项目使用领域级 `_INDEX.md` 做层级导航，避免“地图最终变成另一本手册”。
