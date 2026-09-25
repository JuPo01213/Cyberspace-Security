# 给另一个模型的审查提示词

你是一名负责 Agent 工程、Windows 虚拟化实验、可恢复工作流和证据工程的资深审查者。请对 `guest-communication-workbench v3` 做**对抗式架构审查**，不要因为文档看起来完整就默认设计正确，也不要为了显示工作量而机械增加更多文件、状态机和记录要求。

## 背景

这个技能用于：

- Windows Guest/靶机高度不稳定，可能断线、崩溃、蓝屏、回滚；
- 工作流和 AI Agent 驻留在更稳定的 Host；
- 用户可能在多个 AI Agent 之间切换；
- 需要保留关键证据，但不能让记录工作吞掉实验本身；
- 旧版本为了可靠性引入了 manifest、operation journal、channel state、lease、handoff、artifact index、summary 等多个持续同步对象；
- 实际使用中出现“一个动作后模型同时改五六份文件，大量时间花在文件同步”的严重写放大；
- 项目复盘还证明，模型容易把通信、harness、debugger smoke、局部 seam 等 instrumentation 进展包装成最终目标进展。

v3 的核心修改是：

```text
STATE.json       唯一当前状态权威
events.ndjson    唯一历史事件权威
artifacts/       原始证据
```

其他 `handoff / summary / report / incident review / artifact index` 都变成按需生成的视图。

## 你需要审查的文件

至少阅读：

1. `SKILL.md`
2. `DESIGN.md`
3. `templates/STATE.json`
4. `templates/event.example.ndjson`
5. `references/incident-patterns.md`

如果同时提供旧版 SKILL、C174、C180A、C180B，请用它们核对 v3 是否真的吸收了事故，而不是只做形式简化。

## 审查目标

### 是否真的解决了写放大

- 一次普通动作后，实际需要写几个对象？
- 有没有隐藏的同步要求会重新演化成“五六份文件一起改”？
- 哪些字段/事件其实还能再删？

### 简化有没有损失可靠性

检查以下事故在 v3 中是否仍能正确处理：

- stdout 假空；
- VM Running 但 Guest 未 ready；
- 控制会话杀掉长 runner；
- SCP/路径错误被机械轮询掩盖；
- Guest 有文件但 Host 没拿到；
- PSSession/映射盘作用域差异；
- Guest/控制面失联后的非幂等操作重试；
- debugger 改变自然运行；
- timeout、instrument failure 与业务阴性混淆；
- 多 Agent 同时修改同一 VM/调试会话。

### STATE.json 是否设计得过重

判断 STATE 中哪些字段是真正的“当前状态”，哪些应该只是事件或派生结果。

目标不是把原来的 6 个文件全部塞进一个超大 JSON。

### events.ndjson 是否足够

- 事件粒度是否合理？
- 哪些事件必须记录才能支持恢复和审计？
- 哪些动作不应该记录？
- 是否需要 event version / source / monotonic seq / artifact reference 等字段？
- seq/ACK 设计是否能支持 Guest 断线后的增量收割？

### OP_ID 是否足够克制

确认 v3 只给真正的非幂等副作用操作使用 OP_ID，而不是重新演化成“每条命令一个 receipt”。

请给出一个最小必要的 OP 生命周期，并说明断线后如何判断是否安全重试。

### 多 Agent 切换是否足够轻量

验证新 Agent 只读：

```text
STATE.json + 最近 events + 关键 artifacts
```

是否能够安全继续。

如果你认为必须保留 handoff 文件，请证明为什么它不能按需生成，而不是仅凭习惯要求持续维护。

### Goal Gate 是否真的防止目标漂移

审查 `objective / acceptance` 和 `GOAL / INSTRUMENTATION / DIAGNOSTIC` 是否足以阻止：

- harness 成功被包装成真实样本完成；
- 静态候选被写成动态事实；
- debugger smoke 被写成业务进展；
- 通信修复被包装成最终目标接近完成。

如不足，请提出**最小**改进，不要另建复杂项目管理系统。

### EXPLORE / EVIDENCE 的边界

判断 EXPLORE 是否足够轻，EVIDENCE 是否足够严格。

避免两种极端：

- 每个探索动作都走完整取证流程；
- 正式结论没有足够可复核信息。

### Git 策略

审查“不把 Git commit/push 当运行时同步协议”是否合理，并提出何时应将 runtime 事实归档进 Git/长期证据库的最小规则。

## 审查方法

请遵守：

1. 先从第一性原理判断“每条记录是否有不可替代的消费者”；
2. 如果一个字段/文件没有明确消费者，优先删除；
3. 如果信息能由已有事实确定性派生，不建立第二份实时权威；
4. 不因为“更严谨”就默认增加记录；必须计算它给 Agent 带来的写入、上下文和同步成本；
5. 区分可靠性机制和文档仪式；
6. 优先使用成熟的 append-only log、single source of truth、derived view、idempotency 等模式；
7. 对你的每项新增建议说明：解决什么具体失败、增加多少运行时成本、为什么不能按需生成。

## 输出格式

请输出：

- 总体结论：v3 是否比 v2 更适合长期 Agent 实验；
- 必须修改的问题；
- 建议修改但非必须的问题；
- 应当删除的复杂度；
- 不能删除的可靠性机制；
- 用一个真实“启动目标 → Guest 断线 → 收割 → 切换 Agent → 恢复”的示例走完整流程，统计每一步实际需要写多少次文件；
- 最后给出一个你认为最小可行的数据模型。

不要直接重写整个技能，先做审查并解释理由。
