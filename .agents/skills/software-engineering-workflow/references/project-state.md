# Project State：受控长期状态、分片与上下文生命周期

平台 Memory 可以辅助，但不能作为软件项目关键需求、决策和执行连续性的唯一来源。

长期项目最危险的状态管理反模式之一是：

> 所有需求、决策、进度、失败记录和 handoff 都不断追加到同一个文件。

这种文件最终会变成不可导航的历史垃圾场。新的 Agent 第一时间去读它，却必须先消耗大量上下文才能找到少量当前有效信息。

因此本 Skill 明确区分：

1. **Instruction Policy**：什么时候读/写状态；
2. **Durable Project State**：长期有效、经过晋升的项目事实；
3. **Continuation View**：当前任务/工作流接力所需的有界热状态；
4. **Historical Record**：Git、原始对话、测试/运行证据。

这四者不能混成一个不断增长的 handoff 文件。

## 1. 核心原则：Map, Shards, Current View

长期状态采用：

`Small Index → Relevant Shards → Current Continuation → Git / Source on demand`

不是：

`One Giant Handoff → Keep Appending Forever`

### INDEX 是地图，不是正文

`.agent/state/INDEX.md` 只回答：
- 当前有哪些权威状态文件；
- 每个文件负责什么；
- 哪些与当前 workstream 相关；
- 最近确认的关键 open decision 在哪里；
- canonical source 在哪里。

不要把 requirement 正文、历史讨论、完整 ADR、debug 过程复制进 INDEX。

### INDEX 本身也必须有界

如果根 `INDEX.md` 开始接近预算，不要继续把每个细碎文件都列进去。

改成层级地图：

```text
.agent/state/INDEX.md
  → requirements/_INDEX.md
  → architecture/_INDEX.md
  → decisions/_INDEX.md
```

根 INDEX 只列**领域级入口和当前高优先级指针**；二级 INDEX 再列具体 shard。

索引层级应按稳定领域组织，不按日期/会话创建无限树。

### Shard 按语义所有权拆，不按 V1/V2/V3 拆

优先按：
- product area；
- subsystem；
- bounded context；
- active workstream；
- stable responsibility

拆分。

不要按：
- 日期；
- 会话编号；
- “第 1 版/第 2 版”；
- 每次 handoff

无限制造文件。

Git 已经负责历史。

## 2. 推荐布局

项目很小时可以保持极简；项目变长后再按需要分片。

```text
AGENTS.md                         # 短、稳定：项目工作协议 + 状态同步触发器
CLAUDE.md                         # 若使用 Claude：薄 bridge / import，不复制规则

.agent/
  state/
    INDEX.md                      # 有界热索引，只导航
    requirements/
      _INDEX.md                   # 只有根 INDEX 不再适合直接列所有 shard 时才创建
      core.md
      <domain-or-area>.md
    constraints/
      <domain-or-area>.md         # 只有需要时创建
    decisions/
      _INDEX.md                   # 可选 pointer/index；若 repo 已有 ADR，则可直接指向外部 ADR
    open-questions.md             # 只保留当前未决问题
    terminology.md                # 小项目可单文件；变大后按领域拆
  runtime/
    CONTINUATION.md               # 默认：单一当前工作流的可覆盖接力视图
    workstreams/                  # 只有并行工作流真实存在时才创建
      <stable-workstream-id>.md
```

如果 repo 已有正式：
- product requirements；
- ADR；
- API schema；
- architecture docs；

则 `.agent/state/` 保存 pointer 和状态摘要，不复制权威正文。

## 3. 默认大小预算

这些是**防止状态腐化的默认 guardrail**，不是业务语义限制。Harness 可以按模型/项目能力调整。

建议默认：
- 项目指令中的 managed state protocol：**≤ 8 KiB**
- `.agent/state/INDEX.md`：**≤ 12 KiB**
- 单个 `CONTINUATION.md` / active workstream view：**≤ 16 KiB**
- 单个 durable state shard：目标 **≤ 24 KiB**，到达约 **32 KiB** 前必须拆分或重构

同时使用结构信号：
- 一个文件出现两个以上彼此独立的长期语义所有权；
- 新 Agent 必须滚动大量无关内容才能找到当前事实；
- 文件大部分是 completed / superseded / historical narrative；
- 同一文件需要用全文检索才能知道“当前有效结论”。

任一情况出现，都应先重构状态布局，再继续追加。

**禁止因为“还能写进去”而继续增长巨型文件。**

## 4. Instruction Policy 放哪里

原则：

> 静态行为规则放在平台会自动加载的项目指令入口；动态项目状态放在独立、可路由的文件。

对于 Codex，根目录 `AGENTS.md` 是合适的项目级入口：它在任务开始前被读取。

对于 Claude Code，`CLAUDE.md` 可作为平台 adapter；若支持 import，优先指向同一个权威规则源，而不是复制整套协议。

跨平台项目优先维护一个 authoritative protocol，其他平台文件做薄适配。

### 为什么动态状态不要直接堆进 AGENTS.md / CLAUDE.md

- 自动加载会持续消耗每个 session 的上下文；
- 内容越多，真正规则越难被注意；
- 临时状态会污染长期 instruction；
- 平台可能存在项目指令大小限制；
- 静态协议和动态状态生命周期不同。

所以：

> `AGENTS.md / CLAUDE.md` 负责告诉模型“去哪里找、什么时候同步”，不负责保存全部项目历史。

## 5. 初始化时写入的状态同步协议

持续项目初始化时，自动加载的项目 instruction 中应有一个**短、明确、事件驱动**的 managed block。

建议语义：

```text
## Project State Protocol

Treat `.agent/state/INDEX.md` as a map, not a history file.
Read only the state shards relevant to the current task.

Treat `.agent/runtime/CONTINUATION.md` (or an active workstream file) as a
REPLACE-IN-PLACE current handoff view, never an append-only journal.

Synchronize durable state immediately after:
- the user confirms, rejects, or changes product behavior;
- an open decision becomes resolved;
- an architecture/interface contract changes;
- implementation/review discovers a new user-visible behavior;
- a milestone/vertical slice is accepted;
- before task/model/session handoff or Finish.

Never wait for context exhaustion.
Never append historical session summaries to the current handoff.
Use Git/source history for past states.
If a state file exceeds its budget or mixes unrelated ownership, split/refactor it
before adding more content.

Persist only durable facts with source/scope/status.
Put temporary progress only in the current continuation/workstream view.
```

重点是：**事件触发 + 有界视图 + 禁止 append-only handoff**。

## 6. Durable State：Promotion，不自由写入

状态流：

`Working Context → Candidate State Update → Promotion Check → Durable Project State`

只有通常满足以下条件才晋升：
- 会影响未来多次决策；
- 已明确确认或有强事实证据；
- 不是一次性实现细节；
- 有 source / source_ref；
- 有 scope；
- 能说明何时失效或被 supersede。

适合：
- Confirmed Requirement；
- 关键 Product Decision；
- 不可违反约束；
- 稳定领域词汇；
- 重要 non-goal；
- 长期 Architecture Contract / ADR pointer。

不适合：
- 临时 debug hypothesis；
- 当前 session 草稿；
- 尚未验证的用户偏好推断；
- 一次性 workaround；
- “以后也许有用”的普通细节。

### Canonical Home：不要重复保存

如果长期事实已有更自然的权威文件：
- architecture decision → ADR / decision log；
- Requirement → 正式 requirement/product doc；
- API contract → schema/spec；
- 当前设计 → living design doc；

则 `.agent/state/` 只保存 pointer、状态和必要摘要。

原则：

> 一个事实一个 canonical home；Git 保存 canonical file 的历史。

### Durable shard 的写法

每个 shard 只维护**当前有效状态**：
- active/confirmed；
- current constraints；
- unresolved questions；
- pointers。

完成、过时、被取代且不需要继续参与推理的内容：
- 从当前 shard 移除或标记后收敛；
- 重要 supersession 交给 ADR/Decision；
- 历史细节交给 Git。

不要在 shard 底部永久追加“2026-xx-xx 更新记录”。

## 7. State Sharding

### 什么时候拆

优先在以下情况拆分：
- 一个文件包含两个以上独立 product area/subsystem；
- 不同任务通常只需要其中一小部分；
- 文件逼近大小预算；
- merge conflict 频繁；
- 不同 Agent/workstream 同时写同一文件；
- current truth 被 historical narrative 淹没。

### 怎么拆

按稳定语义边界，例如：

```text
requirements/
  import-export.md
  editor.md
  search.md
```

而不是：

```text
requirements-1.md
requirements-2.md
requirements-old.md
requirements-2026-09.md
```

拆完：
1. 更新 `INDEX.md`；
2. 删除旧文件中已迁移正文；
3. 修正 pointer；
4. commit 这次结构重构；
5. 不保留重复副本“以防万一”。

## 8. Open Questions

`open-questions.md` 不是问题历史档案。

只保留：
- 当前 unresolved；
- 谁/什么能解决；
- 是否 blocking；
- relevant source/decision pointer。

问题解决后：
- 立即从 active list 移除；
- 必要结论晋升到 Requirement/Decision；
- 历史由 Git 保留。

## 9. Continuation View：不是日志

Continuation 回答：

> 如果下一秒换一个全新 context，新的 Agent 最少需要知道什么才能安全继续？

建议固定结构：

```text
Current goal
Current primary route / stage
Current workstream
Last known good commit
Working tree summary
Completed since last checkpoint
Currently in progress
Open hypotheses
Open product decisions
Latest verification result
Files/modules currently being changed
Next concrete action
Relevant state/source pointers
```

### Replace-in-place

更新 Continuation 时：
- 重写对应 section；
- 删除已经完成且不再影响下一步的内容；
- 不在末尾追加“上一轮总结”；
- 不复制整个聊天；
- 不把 Git log 再抄一遍。

**Continuation 是 current materialized view，不是 journal。**

### 并行 workstream

默认只有一个 `CONTINUATION.md`。

只有真实并行任务存在时才创建：

```text
.agent/runtime/workstreams/<stable-id>.md
```

每个文件只描述一个 active workstream，仍然 replace-in-place。

workstream 完成/合并后：
- 删除 runtime 文件；
- 长期结论晋升到 canonical state；
- 历史由 Git / PR / source 保存。

不要留下 `handoff-001.md`、`handoff-002.md`、`handoff-final.md` 的墓地。

## 10. Continuation Budget Gate

写 continuation 前先检查：

1. 这条信息对“下一步安全继续”是否必要？
2. 已经存在于 Git / durable state / canonical doc 的内容，能否只写 pointer？
3. 已完成内容能否删掉？
4. 当前文件是否接近预算？
5. 是否应该拆成独立 active workstream？

如果接近或超过默认预算：

> **先压缩结构/删除 stale/拆 workstream，不允许继续 append。**

如果仍然无法压缩，说明当前任务本身需要更清晰的 workstream decomposition，而不是更大的 handoff。

## 11. State Synchronization：事件驱动优先

不要依赖“模型感觉上下文快满了”。

无论剩余 context 多少，只要发生以下事件就同步 durable candidate：
- 用户确认/否决 Requirement；
- Open Decision resolved；
- architecture contract 改变；
- Requirement Gap 被确认；
- 重要 non-goal 确认；
- milestone accepted。

Continuation 则在以下时机刷新：
- 一个可恢复 checkpoint；
- model/session handoff；
- context pressure elevated；
- 准备离开当前 workstream；
- Finish 前需要交接尚未完成的后续。

## 12. Context Pressure：运行时增强，不是基础正确性来源

如果 Harness 能获得 token/context 信息，应提供稳定能力契约，例如：

```text
context_awareness: exact | approximate | none
context_pressure: normal | elevated | critical
pre_compaction_hook: supported | unsupported
```

不要根据模型名字猜能力。

### normal

只执行事件驱动 durable sync；Continuation 在有实际 checkpoint/handoff 时更新。

### elevated

重建（不是追加）当前 Continuation：
- 删除 stale；
- 保留当前 goal/progress/open decisions；
- 写下一步和 pointers。

### critical / pre-compaction

在允许压缩/上下文刷新前：
1. 同步满足 Promotion Gate 的 durable state；
2. 重建 bounded Continuation；
3. 确保 Git diff / HEAD / baseline 可恢复；
4. 标出尚未验证的假设；
5. 再允许 compaction / context reset。

如果平台只有 compaction 已发生事件，没有 pre-hook：
- 新 context 第一动作读 INDEX；
- 再读当前 Continuation；
- 再按 pointer 读相关 shard；
- 用 Git 状态和最小验证重新建立现实；
- 不完全相信压缩摘要。

## 13. 平台适配

### Codex

`AGENTS.md` 适合放短静态协议；不要把不断增长的项目记录直接堆进去。

Codex 的项目指令本身存在加载大小限制，因此“地图而非手册”也是平台约束，不只是风格偏好。

### Claude Code

`CLAUDE.md` 可作为项目 instruction adapter；支持 import 时，指向权威协议源，减少重复维护。

即使模型能感知 remaining context，也必须执行事件驱动同步，不能把关键决策推迟到最后。

### 其他平台

最低要求：
- 一个会在任务开始时加载的静态 instruction adapter，或 Harness 注入同等规则；
- Agent 能读写 repo 内 `.agent/`。

## 14. 弱模型与写权限

Harness 能分级时：
- 可靠模型：满足 Promotion Gate 后可写 Durable State；
- 低可靠模型：只写 Candidate / Continuation，或调用 `propose_state_update`；
- 冲突更新：交给更强 reviewer / user / deterministic rule。

临时上下文可以更自由；权威状态必须受控晋升。

## 15. Session Start / Handoff Read Protocol

新 session / 新模型开始时**禁止第一步通读整个 `.agent/`**。

按顺序：

1. 读平台 instruction adapter；
2. 读 `.agent/state/INDEX.md`；
3. 确定当前 workstream/task；
4. 读该 workstream 的 bounded Continuation；
5. 只按 INDEX/Continuation pointer 读相关 durable shards；
6. `git status` + `git log -1`；
7. 运行最小现实检查；
8. 只有缺关键信息时才进行 Source Recovery。

停止规则：

> 已经拥有完成当前下一步所需的状态时，停止加载更多历史。

不要为了“理解整个项目”一次读取所有 requirements、所有 ADR 和所有旧 handoff。

## 16. 与 Git 的关系

Durable State / INDEX 若属于 repo 项目事实，应纳入 Git，和代码一起 review/diff。

Continuation：
- 只为本地 context rollover → 可 `.gitignore`；
- 需要跨机器/云 workspace 接力 → 可跟踪，但仍必须 bounded + replace-in-place。

即使跟踪 Continuation，也不要靠保留旧 continuation 文件保存历史；Git 已经能恢复旧版本。

## 17. State Maintenance Review

中长期项目在以下节点检查状态系统本身：
- 重要 milestone；
- 大型 refactor；
- state file 接近预算；
- 新 Agent 明显难以定位信息；
- INDEX pointer 变多且职责不清。

检查：
- orphan shard；
- stale pointer；
- duplicate truth；
- resolved open question；
- superseded current state；
- giant shard；
- 已结束 workstream runtime 文件。

发现后立即做 state refactor；不要等它变成十万行怪物才清理。
