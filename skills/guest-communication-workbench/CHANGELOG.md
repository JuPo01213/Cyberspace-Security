# Change Log

## v3.0

相对 v2 的主要变化：

- 将运行时持久化从多份文件收敛为 `STATE.json + events.ndjson + artifacts/`；
- `handoff / summary / report / incident review / artifact index` 改为按需生成视图；
- lease 合并进 STATE，不再维护独立 `lease.json`；
- OP receipt 合并进 event log，只有未决 OP 摘要保留在 STATE；
- OP_ID 仅用于真正非幂等或有重复副作用风险的操作；
- Guest spool 收敛为 `status.json + events.ndjson + artifacts/`，不再强制 heartbeat/phase/done/pre/post/tail 分文件；
- STATE 只在阶段或关键状态变化时写，不再每动作同步；
- event 只记录有信息增益的事实，重复错误聚合；
- 新增 Goal Gate，区分 GOAL / INSTRUMENTATION / DIAGNOSTIC，防止中间成果冒充最终进展；
- 明确 Git 不作为实时实验同步协议；
- 保留 Host Authority、三平面、canary、长任务脱离、幂等恢复、seq/ACK、deadline、先收割后回滚、多 Agent 单写 owner 等可靠性机制。
