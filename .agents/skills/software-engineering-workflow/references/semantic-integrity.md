# Semantic Integrity：需求来源、语义保真与来源恢复

本文件只在**当前任务依赖历史意图、经过多次总结/翻译后的需求、共享术语，或代码与需求可能发生语义漂移**时读取。

目标不是消灭抽象，而是让从用户语言到代码的转换**可追溯、可逆校验、可重新收敛**。

## 1. Provenance Chain

重要需求尽量保留：

`Source Expression → Interpretation → Confirmed Decision → Behavior Scenario → Design Mapping → Code Evidence`

不要让任一派生层覆盖上一层。

### Source Expression

保存真正有辨识度的用户原话或稳定 `source_ref`，不要把整段聊天复制进状态文件。

原始表达是证据，不意味着只能按字面实现；它的作用是防止 summary、spec、术语或代码把原意悄悄改写。

### Interpretation

模型可以解释“用户可能真正想解决什么”，但解释必须保持为解释，直到被确认。

特别警惕：
- 把偏好变成必须；
- 把当前方案变成长期需求；
- 把模糊处擅自具体化；
- 把工程便利当成用户价值。

## 2. Round-trip Check

重要 Requirement 第一次结构化后，做一次轻量语义往返：

`用户原话 → Structured Requirement → 重新生成具体使用场景`

检查：
- 是否增加了用户未表达的约束；
- 是否丢失重要限定；
- 是否把“可能/倾向”写成“必须”；
- 是否生成了明显不同的用户体验。

这不是要求逐字复述，而是检查信息压缩是否改变了行为含义。

## 3. Shared Language

共享术语用于减少重复解释，不是把用户语言替换成专业语言。

### 术语是索引，不是权威来源

一个稳定术语应能指回：
- 用户原始表达；
- 已确认使用场景；
- 当前含义；
- 工程映射。

例如：

```text
术语：单文档编辑
用户说法：一次只弄一张图
行为锚点：编辑 A 时打开 B，不会同时保留两个活动编辑会话
状态：Confirmed
```

### 什么时候值得沉淀

只在以下情况考虑形成共享术语：
- 同一概念反复出现；
- 存在多个容易混淆的说法；
- 后续 Spec / Code / Test 会频繁引用；
- 误解会改变行为；
- 用户已经自然理解这个短名称。

不要把 glossary 变成名词垃圾场。

### Progressive Vocabulary

首次：完整场景。

概念稳定后：场景 + 短名称。

双方已经熟悉后：可直接使用短名称。

出现困惑：立即退回具体场景。

## 4. Convergence Point

语义最容易漂移的位置：
- 核心设计第一次定型后；
- 重要垂直切片真正跑起来后；
- 大量实现完成、Review 前；
- Review 发现多处 Requirement Gap；
- Acceptance / Finish 前。

在这些位置按风险和漂移迹象决定是否做 Behavior Reconstruction，不机械每次执行。

## 5. Behavior Reconstruction

为了降低确认偏差，先从代码、测试、界面和运行结果独立回答：

- 用户能做什么；
- 用户不能做什么；
- 默认发生什么；
- 失败、取消、关闭时发生什么；
- 数据在哪里留下；
- 哪些动作不可逆。

形成 Behavior Snapshot 后再与 Requirement 对照：

- `aligned`
- `new_behavior`
- `missing_behavior`
- `semantic_shift`
- `unknown`

真正需要用户判断的差异进入 Requirement Discovery；若同时存在多个独立决策，再触发 Decision Questionnaire。

## 6. Source Recovery

历史回读存在天然矛盾：读少了容易断章取义，读多了会挤爆当前上下文。

原则：

> 摘要用于定位；一手来源或已确认状态用于关键判定。

证据优先级：

1. 原始用户消息、原始代码、原始文件、原始运行结果；
2. 已确认且带来源的 Requirement / Decision Record；
3. 压缩摘要、session summary、memory snapshot；
4. 模型根据历史碎片做的推断。

### Targeted Recovery

需要恢复时：

1. 先明确**当前究竟缺哪一条历史事实**；
2. 先读 `Project State INDEX → 当前相关 shard / Decision Record`，不要通读整个 state tree；
3. 有 `source_ref` 时，读原始 turn 及必要邻域；
4. 没有 pointer 时，用平台可用的语义检索/全文检索找候选；
5. 对候选做邻域扩展，直到看到问题提出、关键上下文、用户决定或话题边界；
6. 多个片段共同决定含义时，合并少量必要窗口；
7. 仍不确定时标记 `unverified-from-history`。

语义检索是候选定位器，不是最终裁判。最高相似度 chunk 可能缺少前置条件、随后改口、反例或最终确认。

### Context Budget

逐级扩展：

`INDEX/Relevant Shard → Decision Record → Source Window → Neighbor Expansion → Multi-window Merge → Full Session only if necessary`

每一步都问：新增上下文会不会改变当前判断？不会就停止。

### 平台适配

Skill 只规定**什么时候恢复、恢复什么、证据如何分级**。

Harness / 平台适配层负责 transcript 路径、数据库/API、语义检索、邻域读取和稳定 `source_ref`。不要在 Skill 中硬编码平台路径。

### Fallback

若原始记录不可访问：
- 显式标记来源不可恢复；
- 优先使用已确认 Project State；
- 高影响事项必要时重新向用户确认；
- 不把 summary 细节伪装成原始事实。

## Gate

以下任一成立时，不能把当前历史理解视为已确认事实：

- 关键 Requirement 无法追溯，而实现正依赖其细节做高影响决定；
- 共享术语已无法从来源和行为锚点稳定还原含义；
- Source Recovery 只找到孤立片段且缺少决定性上下文；
- Requirement 与当前 Behavior Snapshot 存在未解释的 `semantic_shift`。
