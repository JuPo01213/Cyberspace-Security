> **LEGACY / 旧适配器**：当前 canonical skill 已迁移到 `.agents/skills/windows-guest-experiment/SKILL.md`。保留本文件仅用于追踪演进。

---
name: windows-guest-experiment
description: 在稳定 Host 上执行或恢复不稳定 Windows Guest/VM 实验时使用。适用于快照恢复、控制/数据/完成分离、长任务、非幂等副作用、多 Agent 接手、artifact 收割和观测有效性判断。优先复用现有 sandbox/workflow/lease 能力，不创建第二套运行时协议。
type: workflow
version: 1.0
---

# Windows Guest Experiment

这是一个薄适配 Skill，不是独立规范。

执行此类任务时：

1. 先读取 `../../playbooks/windows-guest-experiment/PLAYBOOK.md`，以它为当前唯一操作规范。
2. 如果正在做架构修改或质疑某条规则来源，再读取 `../../research/windows-guest-experiment-reliability-patterns.md`。
3. 优先使用当前平台已有 task state、artifact store、retry、lease/CAS；不要因为本 Skill 存在就额外创建 STATE/events。
4. 如果平台完全没有 durable state，才使用 Playbook 中的最小 fallback。
5. `../guest-communication-workbench/` 是历史 v3，仅用于复盘，不作为当前执行入口。

关键执行门禁：

- acceptance 先于 instrumentation；
- canary 先于真实目标；
- 长 runner 脱离控制会话；
- 副作用未知先 reconcile，不盲重试；
- Host acquired 才算取得证据；
- timeout/instrument/transport failure 不升级成业务阴性；
- 同一可变资源必须有原子 single-writer 机制；
- rollback 前先 harvest。
