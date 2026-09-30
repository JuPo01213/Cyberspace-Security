# Git、分支与工作区

Git 是本 Skill 的默认基础设施，也是项目的**版本历史系统**。

加载 Skill 即视为用户授权 Agent 执行非破坏性的本地 Git 管理。目标不是“有 Git 就专业”，而是让代码、文档、设计和项目状态始终可追踪、可比较、可恢复。

## 1. 启动时必须执行

1. 找到项目根目录。
2. 检查是否已经位于 Git repository / worktree。
3. 如果不是 Git 仓库：
   - 优先 `git init -b main`；
   - 不支持时退回 `git init`。
4. 记录：
   - repository root；
   - current branch；
   - HEAD（若存在）；
   - `git status --short`；
   - 是否已有 commits；
   - working tree 是否已有用户修改。
5. 在任何实质修改前建立可比较 baseline。

不得在现有仓库内部误建嵌套 `.git`。

## 2. 默认授权边界

无需再向用户询问即可执行：
- `git init`
- `git status`
- `git diff`
- `git log`
- `git show`
- `git blame`
- 本地 `git add`
- 有意义的本地 commit
- 创建本地 branch / worktree
- 读取 merge-base / history

以下操作不因“Git 已授权”而自动获准：
- `reset --hard`
- `clean -fd`
- 丢弃未提交工作
- 强制历史改写
- push / force-push
- 删除远端数据

原则：

> Git 管理默认允许；破坏用户状态或产生远端副作用仍需独立依据。

## 3. Current Truth / Historical Truth

### 普通代码和活文档

工作树只保存**当前有效版本**。

不要这样保存历史：

```text
design-v1.md
design-v2.md
design-v3-final.md
design-v3-final2.md
```

应该始终只有：

```text
design.md
```

每次达到值得记录的状态就提交：

`Current file → meaningful commit → next current file`

历史通过：
- `git log -- path`
- `git diff <old> <new> -- path`
- `git show <sha>:path`

恢复。

### 为什么

复制版本文件会：
- 让读者不知道哪个才是当前真相；
- 让全文搜索召回大量过期内容；
- 增加 Agent 路由和上下文噪声；
- 让后续修改发生在错误版本上；
- 让 review 无法简单看到真实变化。

### 允许多版本并存的例外

只有“版本本身具有外部语义”时，例如：
- 对外 API v1/v2；
- 需要同时支持的迁移格式；
- 版本化协议；
- 正式 release notes / frozen deliverable。

这不是用文件复制代替 Git，而是产品本身确实存在多个版本。

## 4. ADR / Decision Record 与 Git

ADR 当然也由 Git 管理，没有冲突。

区别是：

- Git 回答：**这个文件怎么变过？**
- Decision Record 回答：**这个决策是什么、为什么做、现在是什么状态、被什么取代？**

### 推荐原则

- ADR 文件本身进入 Git。
- ADR 不是 `ADR-v1 / ADR-v2`。
- 同一决策的措辞修正、补证据、状态变更可以修改原文件并由 Git 记录历史。
- 如果出现一个**新的架构决策**真正取代旧决策，而保留旧决策身份有价值，则创建新的 Decision ID，并写：
  - `supersedes: ADR-xxxx`
  - 旧记录状态改为 `superseded`
- 小型项目不必强制“一决策一文件”；一个 `decision-log.md` 也可以，只要条目有稳定 ID、状态和来源。

不要同时维护：
- `decision-log.md`
- `.agent/state/decisions/`
- `docs/adr/`
中的三份同义真相。

**一个决策只选一个 canonical home**，其他位置只保存 pointer。

## 5. 新仓库的 baseline commit

不要机械执行 `git add -A`。

第一次 commit 前：
- 查看所有 untracked files；
- 识别 secrets / `.env` / private keys；
- 识别 build、cache、vendor、临时文件；
- 读取或建立符合项目工具链的 `.gitignore`；
- 确认纳入版本控制的内容代表真实项目源文件。

安全后建立 baseline commit，使后续 diff 有固定点。

如果无法确认某个文件是否安全进入 Git，宁可暂不 stage，也不要为了“干净 baseline”提交未知敏感内容。

## 6. 用户已有未提交工作

发现 dirty worktree 时：
- 不 reset；
- 不 clean；
- 不偷偷 stash；
- 不覆盖与当前任务无关的修改。

先区分：
- 用户已有工作；
- 当前任务即将产生的工作。

必要时创建独立 branch/worktree；若已有修改本身就是当前任务上下文，则在原工作树中继续，但必须保持 diff 可辨识。

## 7. Logical Commit Discipline

commit 是主要的版本单位。

### 一个 commit 尽量表达一个逻辑变化

例如：

```text
commit 1: mechanical rename/move
commit 2: introduce new interface
commit 3: migrate callers
commit 4: remove legacy path
commit 5: add new user behavior
```

优于：

```text
one giant commit:
rename + reformat + refactor + bugfix + new feature
```

### 但不要过度切碎

“一个逻辑变化”不等于“一文件一 commit”或“一函数一 commit”。

如果一个行为必须同时改 12 个文件，这 12 个文件可以属于一个 commit。

### 可验证中间状态

在合理成本下，每个 commit / patch 应尽量：
- buildable；
- testable；
- 不留下故意损坏的中间状态；
- 不引入尚未使用且会误导 reviewer 的基础设施。

这样 Git history 才能用于：
- review；
- bisect；
- rollback；
- context recovery。

### 机械变更与语义变更分开

大规模：
- format；
- rename；
- move；
- generated rewrite；

尽量与功能行为变化分 commit。

否则 reviewer 很难看出真正的语义 diff。

## 8. Commit Message

commit message 必须让未来 reviewer/Agent 不依赖当前聊天也能理解：

- **what** changed；
- **why** it changed；
- 必要时说明重要 constraint / consequence。

不要只写：
- `update`
- `fix`
- `done`
- `v2`

重要 change 的说明应该 self-contained。

## 9. 什么时候优先独立 branch / worktree

优先使用：
- 大功能；
- 高风险重构；
- 多 Agent 并行；
- 当前工作树含其他未完成工作；
- 需要频繁和 baseline 对比；
- 长时间 Prototype / 实验；
- 独立 reviewer 需要安全 checkout 不同 revision。

小而明确的修改不机械创建 worktree。

## 10. Baseline 与 Checkpoint

正式实现前按任务风险记录：
- 相关测试；
- typecheck；
- lint；
- build；
- 必要 smoke test。

如果 baseline 已失败：
- 记录具体失败；
- 不把旧失败算成新回归；
- 也不能在结束时声称“全绿”。

建议 checkpoint：
- 重要 Requirement/Design 被确认；
- vertical slice 可独立运行；
- 高风险重构前；
- 高风险迁移完成后；
- Design/Code Review 修复完成；
- Acceptance 通过；
- context/model/session handoff 前。

Checkpoint 不要求每次都 commit；但如果当前状态已经 coherent、可恢复、值得长期比较，优先 commit，而不是另存副本。

## 11. Review Fixed Point

进入 Code Review 前必须确定 fixed point：
- baseline commit；
- branch merge-base；
- 明确 tag / SHA。

Reviewer 的 diff 必须从固定点开始，不能凭当前印象判断“改了什么”。

## 12. 合并冲突

按两边的意图和来源解决，不机械选择 ours/theirs。

解决后：
- 重新运行受影响测试；
- 检查冲突标记；
- 检查两边语义是否真正保留；
- 再完成 merge/rebase。

## 13. Git 不是项目状态垃圾桶

Git 保存历史，但不意味着每个临时思路都值得 commit。

- 草稿假设 → working context / bounded continuation；
- 已确认长期事实 → durable state / canonical doc；
- 当前有效设计 → living design doc；
- 重要决策 → ADR / decision log；
- 代码与文档的演变 → Git history。

不要用 Git history 替代 source provenance，也不要用 Project State 复制 Git 已经保存的每一次变化。


## 14. Handoff 版本也交给 Git

若 Continuation 选择纳入版本控制：
- 文件路径稳定；
- **禁止 append-only handoff**；
- 每次 replace-in-place；
- 不复制 `handoff-v1/v2/final`；
- 需要看上一轮 handoff 时使用 Git history；
- 文件超过状态预算时先清理/拆 active workstream，不通过创建“下一份 handoff”逃避整理。

如果 Continuation 不跟踪，则它只是可丢弃 runtime view；长期事实必须已经进入 durable canonical state。
