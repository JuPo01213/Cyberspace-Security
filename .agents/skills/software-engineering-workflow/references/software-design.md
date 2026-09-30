# 软件设计

目标不是“层次更多”，而是让已确认的产品行为落在**小接口、深实现、清晰状态所有权、局部可推理、可测试、可替换、可运行维护的结构**中。

本文件综合 Agent-native 的 deep-module / seam 思路，以及成熟工程组织常见的 design review、NFR、trade study、decision log 实践。它是判断框架，不是固定架构模板。

## 1. Invariant：设计不能静默决定产品行为

设计可以自主决定：
- 模块划分；
- 内部数据结构；
- dependency direction；
- seam / adapter；
- 测试结构；
- 内部算法与局部优化。

设计不能在 Requirement 未定义时自行决定：
- 用户可感知行为；
- 数据保存/删除/恢复语义；
- 权限与隐私；
- 费用；
- 外部兼容责任；
- 长期能力边界；
- 不可逆结果。

一旦触及上述内容，回 Requirement Discovery。

## 2. Design Inputs

进入设计前，先收集与当前任务相关的输入，不为了完整制造文档：

### Functional
- Confirmed Requirement；
- Non-goal；
- Acceptance Scenario；
- known failure / cancel / close behavior。

### Existing System
- 当前 module/interface；
- state ownership；
- data model；
- dependencies；
- external systems；
- tests；
- architecture docs / ADR；
- repo conventions。

### NFR / Quality Attributes

不是所有项目都需要完整 NFR 文档，但以下属性如果会改变结构，必须前置识别：

- performance / latency / throughput；
- reliability / availability / recovery；
- security；
- privacy；
- concurrency；
- data integrity；
- operability / observability；
- maintainability；
- scalability；
- portability；
- accessibility；
- external compatibility；
- cost / resource constraints。

不要在代码写完后才发现“原来必须离线运行”“原来不能上传云端”“原来需要审计可证明性”。

### Risk

列出会让未来返工代价很高的风险：
- irreversible data decision；
- public interface；
- hard-to-migrate schema；
- external dependency；
- concurrency；
- security boundary；
- performance hot path；
- vendor lock-in；
- uncertain technology。

高风险未知进入 Research / Prototype，而不是靠设计文档猜。

## 3. 稳定设计词汇

- **Module**：拥有 interface 与 implementation 的任意设计单元；不等同于目录或 class。
- **Interface**：调用者为了正确使用模块必须知道的全部内容，包括输入输出、invariant、顺序要求、失败模式、配置和重要性能语义。
- **Depth**：调用者学习少量 interface 后能够获得多少行为能力。深模块 = 小接口承载大量可靠能力。
- **Seam**：可以在不修改调用方的情况下替换行为的位置。
- **Adapter**：在某个 seam 上实现 interface 的具体实现。
- **Locality**：一次概念变化、一次 bug 修复、一次验证能否集中在少数地方。
- **Leverage**：调用者付出多少认知成本，换到多少稳定能力。

不要把“文件更多”“class 更多”“抽象层更多”误认为设计更成熟。

## 4. 先读现有系统

设计新结构前搜索：
- 现有 domain terminology；
- 相近 module / interface；
- 公共组件和基础设施；
- 错误类型；
- state ownership；
- 数据访问模式；
- queue/cache/event；
- test helper；
- ADR / architecture docs；
- 已有 import/dependency rules。

优先扩展已经稳定的领域语言和 seam，而不是创造第二套平行抽象。

如果仓库已有明确架构约束，它们优先于通用风格偏好。

## 5. 核心设计检查

### Depth

> 调用者为了获得这项能力，需要理解多少内部细节？

警惕：
- 大量配置参数；
- 调用顺序必须靠记忆；
- 调用者知道内部 storage / transport / retry 细节；
- 一个“抽象”只是把原实现换了名字。

### Deletion Test

想象删掉这个 module。

- 如果复杂度也一起消失，它可能只是 Middle Man / pass-through。
- 如果复杂度会散落回多个调用者，它正在提供 locality，抽象是有价值的。

### Interface = Test Surface

主要行为应该能够通过稳定 interface 验证。

如果核心测试不得不绕过 interface、直接操作内部状态才能证明正确：
- interface 可能太弱；
- seam 可能放错；
- module 可能不是一个真正的行为单元。

### Seam 必须赚回复杂度

不要为了“将来可能替换”创建接口。

一个 adapter 本身通常不足以证明需要抽象；真正变化、外部不确定性、隔离副作用、测试边界等才是 seam 的理由。

外部系统即使当前只有一个 adapter，只要其失败、延迟、不可控性必须被隔离，也可以独立构成 seam 理由。

## 6. 信息隐藏与状态所有权

每个重要状态问：
- 谁是唯一权威 owner；
- 谁能改变它；
- 通过什么 interface 改变；
- 哪些 invariant 必须在 owner 内部维护；
- 失败时谁负责 rollback / retry / reconciliation。

警惕多个模块同时“半拥有”同一状态。

优先：
- single source of truth；
- side effect 集中；
- derived state 可重建；
- 状态变化显式；
- 不用多个 boolean 隐式拼状态机。

复杂生命周期应显式建模：

`States + Legal Transitions + Events + Invariants + Failure/Recovery`

## 7. Dependency Direction

依赖应该指向更稳定、更接近领域规则的一侧。

检查：
- 领域逻辑是否反向依赖 UI/framework 细节；
- transport/database 类型是否渗透整个代码库；
- 高层策略是否能在不启动真实基础设施的情况下测试；
- 一个外部 SDK 升级是否迫使无关业务模块一起改。

需要时用 adapter 把外部细节收进局部。

## 8. Change Locality

对最可能的未来变化做思想实验：

> 如果这个需求变化，应该改几个地方？

同一业务规则如果散落在 controller、UI、SQL、validator、test helper 中，说明缺少权威位置。

“修改文件很多”不是绝对坏，但**一个逻辑概念的变化迫使无关模块同步修改**通常是设计信号。

## 9. Complexity Budget

每新增一个概念都要回答：

> 它解决了哪个已经存在的问题？

警惕：
- future-proofing without evidence；
- abstract factory / plugin system 只有一个真实消费者；
- 为“以后也许会有”增加配置；
- 把简单分支包装成框架；
- 为避免一次迁移永久保留兼容层。

宁可在真实需求出现时重构，也不要让 speculative generality 提前占用认知预算。

## 10. Design It Twice

以下情况不要接受第一个能工作的设计：
- 新的核心 module/interface；
- 难以迁移的数据模型；
- 关键 state machine；
- 长期公共 seam；
- 会影响大量调用方的抽象；
- 安全/并发/高可用关键路径。

先提出至少 2 个真正不同的设计，不是同一结构换名字。

比较：
- interface 大小；
- depth / leverage；
- locality；
- state ownership；
- failure semantics；
- dependency direction；
- NFR 满足度；
- migration cost；
- test surface；
- observability / operations；
- 删除一个未来假设后是否仍自然。

选择后记录为什么舍弃其他方案。

普通小 helper 不需要执行 Design It Twice。

## 11. Trade Study / Spike / ADR 怎么选

### 直接设计即可
- 可逆；
- 低成本；
- 不影响大量调用方；
- 现有模式已经成熟。

### Trade Study
当多个方案都合理，而且需要显式比较：
- 成本；
- 风险；
- NFR；
- 运维；
- migration；
- vendor dependence。

### Technical Spike / Prototype
当关键问题无法靠推理确定，需要运行结果。

### ADR / Decision Log
当决策：
- 长期影响架构；
- 后续开发者需要知道 why；
- 将来可能被 supersede；
- 对外部接口/数据模型有长期后果。

ADR 不是版本历史系统；它本身由 Git 管理。普通活设计文档也由 Git 管理，不创建 v1/v2 副本。

## 12. Design Review

中高风险设计在进入 Plan 前进行独立 Design Review。

### 什么时候必须
- 新核心模块/公共 interface；
- 数据模型难迁移；
- 大规模重构；
- 外部系统集成；
- security/privacy boundary；
- concurrency；
- distributed workflow；
- 高性能关键路径；
- 复杂 failure recovery。

### Reviewer 应独立检查

1. Requirement 是否真的被设计覆盖；
2. NFR 是否被遗漏；
3. architecture 是否比问题复杂；
4. state ownership / data flow / trust boundary 是否清晰；
5. failure / rollback / retry / cancellation 是否完整；
6. observability 是否足够定位生产问题；
7. migration / compatibility 是否有真实消费者；
8. 是否存在更简单方案；
9. test surface 是否自然；
10. 哪些假设如果错了会导致最大返工。

如果 Harness 支持 fresh context / sub-agent，优先用独立 reviewer，避免设计作者自己证明自己正确。

Design Review 的目标不是产生会议纪要，而是降低高成本错误进入代码的概率。

## 13. Architecture Boundary 最好可执行

如果某个 dependency direction / module boundary 很重要，只在文档里写“不要越界”不够。

在工具链允许时，用：
- package/module visibility；
- lint/import rule；
- dependency rule；
- type system；
- build boundary；
- architecture test；

让违规能被 CI 或测试发现。

具体工具由语言和仓库决定，不在本 Skill 写死。

## 14. 可运行性与可观测性

成熟设计不只回答“正常时怎么工作”，还要回答：

- 出错时怎么知道；
- 如何定位；
- retry 是否安全；
- 有没有 idempotency；
- partial failure 怎么恢复；
- 关键业务事件是否可观察；
- 日志是否会泄露敏感信息；
- 健康检查/指标是否需要。

对一次性本地脚本不要强行引入生产级 observability；按实际运行环境和风险决定。

## 15. 设计洁净度

“优雅”不是视觉上的漂亮，而是：

- 一个概念尽量只有一个权威表示；
- 行为集中在最有信息的位置；
- 调用者只知道必须知道的东西；
- 常见变化局部化；
- 状态所有权明确；
- 错误和恢复语义明确；
- 少量稳定 abstraction，而不是大量薄 wrapper；
- 没有无消费者的 extension point；
- 没有为了历史包袱保留的双轨结构；
- 当前设计文档只表达 current truth，历史由 Git 负责。

## 16. Design Review Gate

进入 Plan 前至少确认：

- 用户可感知行为都有 Requirement 来源；
- 当前重要 NFR 已识别；
- 核心 module/interface 的 depth 合理；
- 重要 state 有唯一 owner；
- dependency direction 没把领域规则绑死在框架/基础设施上；
- 关键失败与恢复路径已经进入设计；
- test surface 清楚；
- observability/operations 与风险匹配；
- 高成本决策已在必要时 Design It Twice；
- 中高风险设计已被独立 review；
- 没有明显 speculative abstraction；
- 没有为了“少改代码”保留错误结构。

若实现者仍需要重新决定上述问题，Design 尚未完成。

## 17. 重构优先于兼容补丁

没有明确外部兼容责任的小型/内部项目，设计变更默认采用单一新结构：

`确定新权威模型 → 迁移调用方 → 更新测试/数据 → 删除旧结构`

警惕：
- `legacy/compat/old/v1` 长期存在；
- 同一概念两套 DTO/model；
- wrapper 只为不改调用方；
- 新旧字段长期双写；
- fallback 无退出条件；
- “以后再重构”。

确实需要兼容时必须写清：
- 谁仍消费旧行为；
- 为什么不能同步升级；
- 迁移路径；
- 删除条件；
- 如何观测旧路径仍在使用。
