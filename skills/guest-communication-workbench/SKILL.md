---
name: guest-communication-workbench
description: LEGACY 历史设计，仅用于复盘 guest-communication-workbench v3 的演进与事故经验。新实验请使用 playbooks/windows-guest-experiment/PLAYBOOK.md；不要以本技能作为当前运行时规范。
type: workflow
version: 3.0
---

# Guest Communication Workbench v3

> **LEGACY / 历史保留**：本 v3 不再是当前执行规范。请使用 `../../playbooks/windows-guest-experiment/PLAYBOOK.md`。保留本文用于理解事故、设计演进和避免重复踩坑。

用于 Windows Guest/靶机实验。Guest 可以崩溃、蓝屏、断网、失去 Guest agent、被强制关机或回滚；工作流和长期事实留在更稳定的 Host。

v3 的首要原则：**事实只写一次，其他内容按需生成。**

## 核心不变量

- **Host Authority**：跨崩溃、跨回滚、跨 Agent 要保留的状态，以 Host 已持久化的副本为准。
- **Guest Is Disposable**：Guest 只承担执行、临时 spool 和必要采集；不保存唯一长期状态。
- **Communication ≠ Result**：通信成功只证明链路可用；通信失败不构成业务失败。
- **Harvest Before Rollback**：回滚、重启、强制关机前先尽可能收割。
- **Unknown Stays Unknown**：未观测字段使用 `null` / `NOT_OBSERVED`，不用 0、空串或猜测值补齐。
- **One Fact, One Write**：同一事实不同时同步到 manifest、handoff、summary、report 等多份文件。
- **Derived Docs Are Views**：handoff、run summary、incident review、报告均按需生成，不作为实时权威状态。
- **Side Effects Need Identity**：只有可能重复产生副作用的操作才需要 `OP_ID`；断线后先查状态，不盲目重发。
- **No New Information, No Blind Retry**：重复失败没有新增判别信息时停止机械重试。
- **Single Writer by Default**：同一 VM、调试会话或可变资源默认只有一个写 owner。
- **Instrumentation Is Not Progress**：通信、harness、smoke、断点、静态候选和局部 seam 只能证明仪器或中间条件，不得包装成最终目标进展。

## 运行时事实源

Host 运行期默认只维护：

```text
runtime/
├── STATE.json       # 当前状态权威；覆盖写
├── events.ndjson    # 历史事实权威；只追加
└── artifacts/       # 原始日志、dump、截图、结果文件等
```

不要在每一步同时维护：

```text
manifest.json
channel-state.json
lease.json
handoff.json
artifact-index.json
run-summary.json
status.md
NEXT.md
```

这些需要时从三类事实源生成。

### STATE 只在真正变化时写

更新条件：

- active `RUN_ID` / VM / baseline 改变；
- phase / status 改变；
- 写 owner / lease 改变；
- 三平面 readiness 发生实质变化；
- outstanding 非幂等操作状态改变；
- blocked_on / next_safe_action 改变；
- Guest 增量收割游标批量推进；
- 最终结束/恢复状态改变。

普通读取、无变化轮询、重复看日志、静态浏览、每条调试命令都不要触发 STATE 重写。

### Event 只记录有信息增益的事实

应记录：

- 状态变化；
- 有副作用操作开始/完成/未知；
- 新目标阶段或关键 marker；
- 新 artifact 被 Host 取得；
- 通道故障、恢复、deadline；
- 会改变实验路线的判断。

默认不记录：

- 没有状态变化的轮询；
- 重复读取同一文件；
- 普通只读命令；
- 同一错误的完全重复输出；
- Agent 的逐步思考过程。

重复事件聚合，例如 `same_error_count: 6`，不要写 6 份同义记录。

### Artifact 只存原始证据

原始证据不复制进 Markdown。事件中只引用 artifact 路径、大小，关键时记录 hash。

大文件按需收割；模型读取时使用 tail/range/关键词/事件序号，不把整份日志塞入上下文。

## 最小状态模型

参考 `templates/STATE.json`。核心字段：

```text
objective
acceptance
active_run
phase
status
owner / lease
channels
outstanding_op
sync
blocked_on
next_safe_action
```

`objective` 和 `acceptance` 只在用户改变目标时更新，不随每个动作改写。

## Goal Gate

准备投入显著时间的动作先回答：

> 这一步直接推进哪个 acceptance 条目？

动作分为：

```text
GOAL              直接增加最终验收证据
INSTRUMENTATION   让观测链更可靠
DIAGNOSTIC        定位环境/工具问题
```

后两类可以必要，但不能报告成业务完成或“接近完成”。

连续多轮只有 instrumentation 成果而 acceptance 没变化时，重新审视主线，不继续堆工具、文档和自动化。

## 工作模式

### EXPLORE

用于快速验证路径。最低要求：

- 唯一 RUN_ID；
- 目标身份/hash；
- VM/baseline；
- 控制短探针；
- 数据 canary；
- deadline；
- 真正有副作用操作的 OP_ID；
- 结束前 harvest。

不要求为每轮生成正式 summary、handoff 或证据报告。

### EVIDENCE

用于形成正式可复核结论。在 EXPLORE 基础上增加：

- 必要 PRE/POST；
- 进程/目标谱系；
- 原始日志；
- 关键 artifact 长度/hash；
- 需要时的 benign smoke；
- 严格 marker 解析；
- cleanup / 恢复验证。

默认先 EXPLORE；准备形成结论时再进入 EVIDENCE。

## 三平面

### Control Plane

负责 VM 生命周期、checkpoint、短健康探针、脚本投递/触发、短状态查询。

优先宿主原生直连，例如 Hyper-V PowerShell Direct 或等价机制。SSH/GuestControl 可辅助。

**控制命令返回不代表长任务完成。**

### Data Plane

Guest 先本地落盘，再由 Host 增量收割。最小 spool：

```text
GUEST_SPOOL/<RUN_ID>/
├── status.json
├── events.ndjson
└── artifacts/
```

不要为了 heartbeat、phase、done、pre、post、stdout tail、stderr tail 强制分裂出大量同步文件；优先作为 `status.json` 字段或事件。

工具自身必须产生独立文件时，把它当 artifact，不建立新的状态权威。

### Completion Plane

完成可以由自然退出、Guest terminal state、目标阶段闭合、deadline 收尾或离线状态闭合判定。

以下不是完成事件：

- SSH/GuestControl/PSSession 断开；
- 控制命令返回；
- stdout 为空；
- VM Running；
- 端口/banner 可见；
- 进程仍存活。

## Canary

VM 每次启动/恢复后，正式实验前先做短 canary：

- Host 能查询 VM 状态；
- Guest 身份/OS 可读取；
- 短命令可执行；
- Guest 能写小文件；
- Host 能读回并核对内容；
- 需要长任务时，先证明 runner 不随控制会话退出而死亡；
- 需要调试器时，先对 benign target 做 smoke。

VM Running、NAT ready、Guest agent ready、登录成功、共享路径可用不是同一事件。

Canary 通过只写一次事件，不再同步到多份台账。

## 长任务

长任务必须与前台控制会话生命周期分离，可用计划任务、Guest 服务、独立 runner 或明确支持 detach 的 agent job。

控制连接只做：

```text
deploy → trigger → short confirm → later query/harvest
```

Guest runner 最小职责：自建运行目录、写临时 status/events、执行明确任务、产生必要 artifacts、terminal 时更新状态。

**下一步做什么由 Host/Agent 决定，不把完整 workflow 放进 Guest。**

## OP_ID 只用于真正有重复风险的操作

通常需要 OP_ID：

- 启动目标；
- 修改目标/系统状态；
- 恢复 checkpoint；
- 修改 debugger 状态且重复执行可能有副作用；
- 创建/删除持久化资源。

普通读取、健康查询、日志读取不需要 OP_ID。

OP 生命周期写进 `events.ndjson`；当前未决 OP 只在 `STATE.json.outstanding_op` 保留摘要。**不维护独立 receipt 文件。**

断线后：

- 不立即重发非幂等操作；
- 先查 Guest/VM/目标状态和事件；
- 已生效则不重跑；
- 无法判定则标 `OP_STATE_UNKNOWN`；
- 只有证明未生效时才允许新 OP_ID 重试。

## 增量事件与 ACK

Guest `events.ndjson` 使用单调递增 `seq`。Host 在 `STATE.json.sync` 保存最后已持久化的 Guest seq。

重连只收割：

```text
seq > last_acked_guest_seq
```

ACK 按批次推进，不要求每个事件重写 STATE。

出现序号缺口时记录一次 `EVENT_GAP` 并诊断，不反复搬运整个日志“同步”。

## 多 Agent 切换

同一可变资源默认一个写 owner。owner/lease 直接存在 `STATE.json`。

新 Agent 默认只读：

```text
STATE.json
+ events.ndjson 最近一小段
+ STATE 引用的关键 artifacts
```

通常即可继续。

只有用户明确要求、上下文非常复杂或需要人工归档时才生成 `handoff.md`。handoff 是一次性导出视图，不是实时同步文件。

不要依赖复制完整聊天历史恢复执行状态。

## Shell / 路径边界

Agent → Host shell → hypervisor → Guest 是多层解析链。明确复杂命令由哪一层解释。

复杂 PowerShell、批处理、调试器命令、重定向、嵌套引号优先：

```text
Host 写脚本文件 → 必要时 hash → 投递 → 短命令执行
```

新路径、共享、PSSession、身份上下文第一次使用先做 canary。不要假设一个会话继承另一个会话的映射盘或认证上下文。

命令包装本身没有验证时，不用真实目标替它做测试。

## 调试器与观测器

每轮明确一种模型：

```text
natural launch only
natural launch then attach
debugger launch
```

自然运行和调试器运行用不同 RUN_ID，只能对照，不能拼成一次业务结果。

高频观测使用轻量 API；WMI/CIM 降频。名称过滤只用于离线筛选，不能用“过滤器没看到”证明“没有子进程”。

调试器、patch、异常上下文细节按需加载专用 profile，不塞进每轮通信核心。

## Retry / deadline / 信息增益

每阶段至少有：

```text
expected_duration
deadline
retry_budget
same_error_budget
```

- 没有新 marker/状态变化时不无限延长等待；
- 同一错误达到预算且环境未变化，停止同一路径；
- 下一次尝试必须改变假设、通道、参数或观测手段；
- path-not-found、auth failure、file-not-ready、transport timeout 必须区分，不能全部变成“继续轮询”。

模型输出默认结构化摘要；大日志按 range/seq/关键词读取。

## 收尾与恢复

固定顺序：

```text
停止新增副作用操作
→ 增量收割新事件和关键 artifacts
→ 更新最终 STATE
→ 保存必要 Host 控制日志
→ 清理本轮登记对象
→ 关机/恢复 baseline/保留现场
→ 恢复后重新 canary
→ 追加一个恢复结果事件
```

默认快照策略：

```text
immutable baseline → restore → run → harvest → restore baseline
```

默认不为每轮创建新 snapshot。只有 unique failure、postmortem 或人工明确要求时保留额外快照。

## Git 与同步

Git 用于：skill、脚本、配置、稳定研究结论、用户要求保存的报告、可复用自动化代码。

运行时 `STATE.json`、`events.ndjson` 和大 artifacts 默认不要求每个动作 commit/push；是否长期归档由项目策略决定。

**不要把 Git commit 变成每一步实验的同步协议。**

## 按需派生文档

以下默认不存在，只有需要时生成：

```text
handoff.md
run-summary.md
incident-review.md
final-report.md
artifact-index.md
```

生成时读取 `STATE.json + events.ndjson + artifacts/`；生成后无需反向同步到运行状态。

## 最小事件格式

示例见 `templates/event.example.ndjson`。

```text
seq
ts
run_id
kind
status
op_id?       # 仅需要时
artifact?    # 仅需要时
data?        # 小型结构化数据
```

不要把完整 stdout、dump、长反汇编或整段推理塞进 event。

## 常见反模式

| 不要 | 改成 |
|---|---|
| 一个动作改五六份文件 | event 一次写入；阶段变化再更新 STATE |
| 实时维护 handoff/summary/report | 按需生成视图 |
| 每条命令都建 OP receipt | 只给非幂等副作用 OP_ID |
| 每个 heartbeat 单独文件 | status 字段 / event |
| 每次重新传完整日志 | seq 增量 + range/tail |
| 空 stdout = Guest 没输出 | Guest 落盘 + Host 收割 |
| banner = 登录成功 | connect/auth/execute 分开 |
| 长前台会话承载 runner | detach runner + spool |
| Guest 声称文件存在 = Host 已取得 | Host acquire；关键时 verify |
| 每轮创建 snapshot | 固定 baseline |
| 调试器阴性 = 自然运行阴性 | 分 RUN 对照 |
| instrumentation 成功 = 业务进展 | Goal Gate |
| 相同失败不断轮询 | 达预算即停，改变方法 |
| Git commit = 运行时同步 | Git 管代码/稳定结论，运行态独立 |

## 停止条件

遇到以下任一情况停止当前实验路径并保留已有事实：

- 输入缺失或目标身份不符；
- 控制或数据 canary 未通过；
- baseline/VM 状态不明；
- 非幂等 OP 状态未知且无法安全判断；
- Host 资源低于停止线；
- 原始证据无法可靠收割；
- 观察器覆盖不足；
- 同类失败达到预算且没有新增信息；
- 连续 instrumentation 工作没有推进任何 acceptance 条目。

停止不是业务失败，而是阻止不确定状态和无效工作继续扩大。

## 最小检查

开始前：objective/acceptance 对齐；RUN_ID 唯一；目标 hash、VM、baseline 明确；control/data canary 通过；deadline 已定；只有真正有副作用的动作才分配 OP_ID。

运行中：只记录有信息增益的事件；阶段真正改变时才更新 STATE；长任务不依赖前台控制会话；大输出留在 artifact；instrumentation 不冒充目标进展。

结束或切换 Agent：先 harvest 后 rollback；outstanding OP 已完成、冻结或明确 UNKNOWN；STATE 足以说明 phase/status/owner/blocked_on/next_safe_action；新 Agent 先读 STATE + event tail，不默认生成 handoff 文件。
