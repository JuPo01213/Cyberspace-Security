# v3 优化说明：从“多文件同步”改为“单一事实源 + 派生视图”

## 问题

v2 解决了不稳定 Guest、三平面、幂等、Agent 切换等可靠性问题，但把很多概念各自落成了实时文件：manifest、operation journal、channel state、lease、handoff、artifact index、summary 等。

在实际 Agent 工作中，这会产生严重写放大：一次实验动作之后，模型为了“保持一致”去更新多份内容，记录工作反过来压过实验本身。

C180 复盘还暴露出另一个问题：文档和自动化可以制造表面进度，使 Agent 长期优化中间 seam、通信、harness 和仪器，而最终 acceptance 没有推进。

## v3 的解决方式

### 一、运行时只有三类权威事实

```text
STATE.json       当前状态
events.ndjson    历史事件
artifacts/       原始证据
```

同一事实只记录一次。

### 二、所有文档降级为派生视图

`handoff.md`、`run-summary.md`、`incident-review.md`、`final-report.md` 默认都不存在。

需要时从三类事实源即时生成。它们不再需要反向同步，也不参与运行状态判断。

### 三、减少 STATE 写频率

STATE 只在阶段、owner/lease、channel readiness、outstanding OP、blocker、恢复状态等真正变化时写。

普通读取、轮询和无变化动作不写 STATE。

### 四、减少事件数量

只记录有信息增益的动作和观察。重复错误聚合，不记录 Agent 的逐步思考和普通只读操作。

### 五、OP_ID 只用于非幂等副作用

v2 容易让 operation receipt 变成新的台账。v3 不再维护 receipt 文件；OP 生命周期作为 event 记录，当前未决 OP 只在 STATE 中保留一个摘要。

### 六、lease 直接嵌入 STATE

不再维护 `lease.json`。多 Agent 只需读取 STATE 的当前 owner/lease。

### 七、handoff 不再持续维护

新 Agent 的默认恢复流程是：读取 STATE → 读取最近事件 → 读取被引用的关键 artifact。

只有人工需要长文本交接时才生成 handoff。

### 八、Goal Gate

为避免“仪器进展冒充业务进展”，v3 把 objective/acceptance 固定在 STATE，并要求显著动作说明自己属于 GOAL、INSTRUMENTATION 或 DIAGNOSTIC。

后两者是必要成本，但不能被表述成最终完成度。

### 九、Git 不作为实时同步协议

Git 管技能、脚本、配置和稳定结论；运行时状态默认不要求每一步 commit/push。

这保留版本管理优势，同时去掉大量无意义同步。

## 保留下来的可靠性机制

v3 没有为了轻量而删除真正重要的安全网：

- Host Authority；
- Guest disposable；
- control/data/completion 三平面；
- canary；
- 长任务脱离控制会话；
- 非幂等操作断线恢复；
- Guest 事件 seq/ACK；
- hard deadline / retry budget；
- harvest before rollback；
- unknown stays unknown；
- 自然运行与 debugger 运行分离；
- 单写 owner；
- 固定 baseline 默认恢复。

## 预期效果

典型实验动作：

```text
旧：动作 → 改 manifest → 改 operation journal → 改 channel state → 改 handoff → 改 summary → 改 evidence index
新：动作 → 追加 1 条 event
```

只有阶段或关键状态变化时：

```text
追加 event + 更新一次 STATE
```

报告、handoff、事故复盘在真正需要时一次生成。

## 风险与审查重点

简化后需要特别审查：

1. STATE 是否过度承载而变成新的“大一统垃圾桶”；
2. 哪些事件必须记录，哪些可以省略；
3. 非幂等 OP 是否仍能在断线后安全恢复；
4. event seq/ACK 是否足够支持 Guest 数据增量收割；
5. 不生成实时 handoff 后，多 Agent 恢复上下文是否仍足够；
6. EVIDENCE 模式是否仍能满足严格取证需要；
7. Git 不同步 runtime 后，项目是否需要明确的归档/导出动作。
