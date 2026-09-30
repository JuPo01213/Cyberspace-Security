# 收尾与交付

Finish 是把“代码可用”变成“工程变更可交接”。

## 最终验证

按项目实际需要运行：
- full/targeted test suite；
- typecheck；
- lint；
- build；
- smoke/E2E；
- migration validation。

不要为了看起来完整重复已经足够且昂贵的验证；但重要结论必须有最新结果。

## 最终 Diff Review

检查：
- 未计划文件；
- debug print；
- 临时 fixture；
- TODO；
- 未使用依赖；
- 意外格式化；
- generated file 是否应该提交；
- secret/credential；
- 过大的无关重构；
- 无消费者的 compatibility shim / legacy branch / deprecated path；
- 已完成迁移但仍残留的旧接口、旧模型和 feature flag。

## 文档

只更新真正被行为改变影响的文档：
- README；
- API docs；
- migration notes；
- ADR；
- changelog；
- operator runbook。

不要为每个小改动制造冗余报告。

## Git 状态

确认：
- 用户原有改动仍安全；
- 当前变更已清楚分组；
- commit/PR 状态符合项目惯例；
- worktree 若要清理，确认没有未提交内容。

## PR / Handoff

PR 说明可以记录本次变更；项目运行时 handoff 不应变成追加日志。

若任务尚未结束、需要交给下一模型/session：
- 按 `project-state.md` 重建 bounded Continuation；
- 只保留当前目标、进度、未决项、最新验证、下一步和 pointer；
- 删除 stale/completed narrative；
- 不创建 `handoff-v2/final/next`；
- 历史交给 Git。

交付说明优先包含：
- What：改变了什么行为；
- Why：对应哪项需求/问题；
- Verify：实际运行了什么；
- Risk：剩余风险/兼容性；
- Follow-up：刻意没有包含的后续。

不要把内部思维过程当交付说明。

## 不把 follow-up 偷塞进当前范围

实现中发现：
- 旧架构问题；
- 额外优化；
- 无关 bug；
- 更大重构。

记录下来，但除非阻塞当前正确性，否则不要顺手扩大 diff。


## 收尾时优先删除历史残留

对于没有外部兼容责任的项目，Finish 必须问：

> 这次改动完成后，哪些旧结构已经没有继续存在的理由？

能够删除的旧路径应在同一变更中删除，而不是默认留给“以后清理”。

Follow-up 适合记录真正独立的新工作，不适合把本次已经明确可删除的技术债延期。

## Project State 收口

Finish 前：
- 检查本次任务是否产生值得长期保存的 Confirmed Requirement / Decision；
- 只晋升真正会影响未来工作的稳定信息，并附来源与 scope；
- resolved open questions 从 active list 移除；
- 完成的 runtime workstream/Continuation 清理或重建为空闲状态；
- 检查 INDEX 是否仍短小、pointer 是否有效；
- 不把整个 session 总结塞进长期状态，也不把 handoff 当历史档案。
