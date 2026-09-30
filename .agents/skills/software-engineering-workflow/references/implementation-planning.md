# 实现计划与 Tickets

Plan 的职责是把已确认 Design 编译成可执行工作，不重新发明需求和架构。

## 垂直切片优先

差的拆法：
- 建数据库层；
- 建 service 层；
- 建 API 层；
- 建 UI；
- 最后补测试。

好的拆法：
- 用户可以创建一个最小对象；
- 用户可以读取这个对象；
- 用户可以编辑并看到结果；
- 用户可以删除并收到正确反馈。

每个 slice 穿过必要的层，但保持范围小、可验证、可独立审查。

## Task 模板

每个任务至少说明：

```text
任务：
行为：
依赖：
预计修改：
测试：
实现步骤：
验证：
完成条件：
```

复杂任务补充：
- migration；
- feature flag；
- rollout；
- backward compatibility；
- observability。

## 文件必须具体

计划应尽量给出：
- 现有文件路径；
- 新文件路径；
- 需要修改的 symbol/module；
- 测试文件；
- 运行命令。

但不要在还没看仓库时凭空编文件名。

## Blocking Edges

多个 ticket 之间显式记录：
- A blocks B；
- A 和 C 可并行；
- D 依赖 Design decision X。

不要把一个 DAG 写成“1、2、3、4”然后默认所有步骤串行。

## Task 大小

一个 task 应满足：
- 有独立行为结果；
- 有自己的测试/验证；
- reviewer 可以独立接受或拒绝；
- 可以在一个合理上下文中完成。

不要为了“颗粒度小”拆出没有独立价值的 scaffolding ticket。

## Plan Review

实施前检查：
- 是否每个 required 都落到某个 task；
- 是否有 task 不对应任何需求或设计；
- 是否横向拆层导致长期红灯；
- 是否把未知留给 implementer；
- 是否有验证命令；
- 是否说明破坏性 migration/数据变化；
- 是否能安全中断并恢复。

通过后再进入实施。


## 对重构任务的计划要求

如果正确实现需要改变既有结构，Plan 不应伪装成“最小补丁”。

对于无外部兼容约束的项目，计划应明确：
- 新的权威接口/模型；
- 哪些调用方要同步修改；
- 哪些测试要重写或迁移；
- 哪些旧代码在本次任务中删除；
- 是否需要一次性数据迁移；
- 完成后仓库中不再保留哪些旧概念。

不要把“先加 adapter，再以后清理”作为默认两阶段方案。

只有无法同步升级真实消费者时，才计划过渡兼容层；并且兼容层本身必须有删除 ticket 或可验证退出条件。

## 语义引用

重要 task 应引用相关 Requirement/Decision，而不是只引用上一层计划摘要。若 task 会把一个 Assumed/Open Decision 固化为产品行为，Plan 必须显式阻塞或安排 Requirement Discovery。

## 长项目的可接力边界

长项目的 task/workstream 还应满足：

- 下一 Agent 可以只读取该 workstream 的 Requirement/Design/Continuation 就继续；
- 不依赖一个包含整个项目历史的 handoff；
- workstream 有稳定 ID，而不是 `part1/part2/v2`；
- 完成后长期结论回到 canonical state，runtime handoff 被删除或重写。

如果一个 task 无法在合理上下文内描述其当前状态，优先继续拆 workstream，而不是扩大 handoff 文件。
