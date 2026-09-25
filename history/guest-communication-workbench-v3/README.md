# Guest Communication Workbench v3：历史保留说明

> 状态：LEGACY / 历史设计，不作为当前执行规范。

旧目录仍保留在：

`skills/guest-communication-workbench/`

原始 v3 首次提交可通过 Git 历史查看：

`27ce88405e46e86a43f3f27f50fafea1fd30adab`

## 为什么不删除

v3 记录了真实事故之后形成的多项重要认识，包括 Host Authority、Guest disposable、控制/数据/完成分离、canary、非幂等操作恢复、harvest-before-rollback、Goal Gate 和减少写放大。

这些内容有复盘价值，也能解释当前 Playbook 为什么存在。

## 为什么不继续把它当 Current

v3 同时把若干成熟领域原语重新包装成了自定义 workflow/data model，例如 STATE、events、lease、OP lifecycle 等。继续沿这条路线扩展，会逐渐变成自研 durable workflow engine。

重新调研后，当前策略改为：

- sandbox 生命周期优先复用 CAPE/Cuckoo 类模式；
- durable execution 借鉴/复用现有 workflow 系统；
- single-writer 使用真实 Lease/CAS/OS lock；
- provenance 采用 CASE/W3C PROV 思路；
- 仓库指导采用 AGENTS.md + canonical Playbook + thin Skill adapter。

## 当前入口

`playbooks/windows-guest-experiment/PLAYBOOK.md`

相关调研：

`research/windows-guest-experiment-reliability-patterns.md`

旧材料不得删除；如果未来继续发现旧设计中的有效经验，应把其原则迁移到 Current Playbook，并在这里记录来源，而不是重新激活整个 v3。

## 已归档的原始事故材料

- `incidents/C180A_problem_slices_20260925.md`：具体问题切片、通信事故和当时证据边界；
- `incidents/C180B_assistant_reflection_20260925.md`：对判断、执行、通信设计和文档优先级失误的反思。

这两份材料作为历史事实与复盘依据保留，不作为当前运行时规范。
