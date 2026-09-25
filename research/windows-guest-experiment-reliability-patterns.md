# 不稳定 Windows Guest 实验：成熟模式与复用边界调研

> 日期：2026-09-25
>
> 目的：回答“别人是否遇到同类问题、成熟系统如何解决、我们还需要自研什么”。

## 结论

没有找到一个单独标准同时覆盖 Windows malware/reverse VM、durable execution、多 Agent writer ownership、artifact provenance 和 debugger interference。

但这些问题并不新。它们分别属于已经长期存在的几个工程领域。正确做法不是继续设计一个新的小型 workflow engine，而是把成熟原语组合成一个很薄的场景 profile。

当前采用结构：

- `.agents/skills/windows-guest-experiment/SKILL.md`：当前 canonical Agent Skill；
- `references/runbook.md`：Skill 内的逐步可执行规程；
- `references/patterns.md`：成熟模式依据；
- `AGENTS.md`：只保留全局脱敏/证据规则与强制 Skill 路由；
- 平台原生状态/API：能用 CAPE/Temporal/其他 orchestrator 的就直接用；
- 自定义 `run.json + events + artifacts`：仅作为没有现成 durable state 时的 fallback。

## 问题 → 成熟领域 → 采用方式

| 真实问题 | 已有成熟领域/系统 | 我们采用什么 | 不再自研什么 |
|---|---|---|---|
| VM Running 但 Guest 未 ready | CAPE/Cuckoo guest lifecycle | baseline 后做 guest/agent canary | 用单一 VM 状态推断 readiness |
| 控制会话杀掉长 runner | sandbox worker / job runner | trigger 与长任务生命周期解耦 | 前台 SSH/GuestControl 承载整轮 |
| 控制、数据、完成混在一个通道 | sandbox result server / distributed jobs | 三者独立判定 | 一个通道包办启动、stdout、传输、完成 |
| Guest 有 dump，Host 没拿到 | artifact/result server | Host acquired/verified 才算证据 | Guest 报告文件大小就算完成 |
| worker/Guest 断线后不知道副作用是否已发生 | durable execution / idempotency | operation identity + reconcile-before-retry | 每条命令 receipt 或盲重试 |
| 相同错误机械轮询 | retry policy / SRE | retry 必须改变信息条件，分类 path/auth/transport | 无上限 polling |
| 多 Agent 同时控制一台 VM | distributed leader election | Lease/CAS/OS mutex/DB transaction | JSON owner 字段充当锁 |
| 多 Agent 接力需要恢复上下文 | durable task history / checkpoint | 当前状态 + 关键 history + artifacts | 持续手工同步 handoff/summary |
| 证据来源和处理链需要可复核 | CASE / W3C PROV | source/action/tool/result provenance | 多份重复 artifact index |
| debugger 改变自然行为 | dynamic analysis / VMI / record-replay | natural 与 instrumented 分 RUN | 把两类结果拼成一个业务结论 |
| instrumentation 成功被包装成业务进展 | acceptance-driven testing | acceptance gate，工具成果只算 instrumentation | “接近完成”式主观进度 |
| timeout/通道失败被当业务阴性 | testing/observability validity | INCONCLUSIVE / INVALID_INSTRUMENT | 未观测到 = 没发生 |

## CAPE/Cuckoo：最接近 Host → disposable Windows Guest 的长期实践

CAPE 的文档要求在保存 snapshot 前先测试 Guest agent；它把 Guest、snapshot、machine/task 状态和 Result Server 作为独立机制。其任务状态包含 pending、running、completed/recovered/reported 以及 analysis/processing failure 等类别。

这说明以下规则不应被描述为我们原创：

- Guest/VM 可回滚、Host 负责 orchestration；
- snapshot 前验证 agent；
- VM/machine 状态与 task 结果分开；
- artifact 通过 Host-side result path 收集；
- 一次分析使用明确 task identity。

来源：

- https://capev2.readthedocs.io/en/latest/installation/guest/agent.html
- https://capev2.readthedocs.io/en/latest/installation/guest/saving.html
- https://capev2.readthedocs.io/en/latest/usage/utilities.html

## Temporal：不要自己发明 durable execution

Temporal 的核心目标就是在 worker crash、network failure、infrastructure outage 后继续 workflow。它把工作状态和历史持久化，使 worker 可以恢复而不是依赖一个前台会话一直存活。

对本项目最有价值的是模式而不是强制部署 Temporal：

- workflow state 不放在易损 worker/Guest；
- 外部副作用和 workflow orchestration 分开；
- retry 必须考虑重复执行的副作用；
- history 是恢复依据，而不是聊天记录；
- 一个资源的操作应该被串行化，而不是让多个 worker 任意并发。

如果未来实验数量、等待时间、并发和恢复需求增长到需要真正 workflow engine，再评估直接使用 Temporal，而不是继续扩展自定义 STATE/event 协议。

来源：https://docs.temporal.io/

## Kubernetes Lease：owner 字段不是锁

Kubernetes 使用 Lease 做 node heartbeat 和 leader election；协调 leader election 使用 resourceVersion 的乐观并发控制，使并发抢占时只有一个更新成功。

因此本项目采用：

- 同一 VM/debug session 只有一个 active writer；
- writer 的获取必须通过原子 primitive；
- 本机单进程可用 OS mutex/file lock；
- 有数据库时用事务/CAS；
- 已有 orchestrator 时用其 lease；
- 不再设计 `lease.json` 作为并发协议。

来源：

- https://kubernetes.io/docs/concepts/architecture/leases/
- https://kubernetes.io/docs/concepts/cluster-administration/coordinated-leader-election/

## CASE / W3C PROV：证据链已有成熟语言

CASE 是面向 cyber-investigation 的社区标准，覆盖 evidence gathering、chain of custody、investigative actions 到最终报告，并强调结果可追溯回数据来源、执行者、工具和处理动作。CASE 还与 W3C PROV 对齐。

因此我们不需要把 provenance 重新设计成多份实时 Markdown。

最小需要的是：

- source：证据从哪个 run/Guest/原始对象来；
- action：做了什么采集/处理；
- tool/agent：谁或哪个工具执行；
- result：产出了什么 artifact/派生结论；
- hash：关键、不可重复或正式证据按需记录。

来源：

- https://caseontology.org/
- https://caseontology.org/resources/case_design_document.html
- https://www.w3.org/TR/prov-overview/

## AGENTS.md、Playbook 与 Agent Skills：为什么三层而不是只用 Skill

`AGENTS.md` 已形成跨 coding-agent 的开放约定，并被 Codex、GitHub Copilot 等支持；它适合 always-on 的仓库级规则和入口指针。

Agent Skills 是开放的按需加载格式，一个 Skill 是包含 `SKILL.md` 的目录，可附带 scripts/references/assets；它适合可复用、任务触发型流程，但不是所有 Agent 都会自动加载。

因此唯一真相放在 Playbook：

- `AGENTS.md` 只说“何时必须读哪个 Playbook”；
- `SKILL.md` 只负责 skills-compatible 客户端发现和跳转；
- 不在两处复制整套规则。

来源：

- https://agents.md/
- https://developers.openai.com/api/docs/guides/latest-model#using-agentsmd
- https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions
- https://agentskills.io/
- https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills

## 哪些仍然是本项目自己的薄适配

这些不是通用标准直接替我们决定的：

- 当前使用 Hyper-V、VirtualBox、PowerShell Direct、SSH 还是其他 control channel；
- Session 0 / interactive desktop 等具体 Windows 启动上下文；
- CDB/x64dbg 等 debugger 的具体 smoke 与 attach 方法；
- 某个样本的业务 acceptance；
- Host 的目录布局、artifact store 位置；
- 何时需要正式 EVIDENCE 模式。

这些应作为 profile/config，而不是重新升级成一套新的通用 workflow 协议。

## 对旧 v3 的定位

`skills/guest-communication-workbench` 保留，因为它记录了事故后如何逐步抽象出 Host Authority、三平面、OP_ID、Goal Gate 等概念，具有复盘价值。

但它不再作为当前规范来源。它混合了成熟模式、项目推导和未实测的自定义数据模型；继续扩展会逐渐变成自研 workflow engine。

当前规范入口是 `.agents/skills/windows-guest-experiment/SKILL.md`。
