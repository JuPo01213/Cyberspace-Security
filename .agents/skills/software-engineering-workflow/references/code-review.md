# 代码审查

目标不是“挑更多毛病”，而是**尽可能高召回地发现真实问题，同时压低噪声和臆测，让 code health 随时间改善**。

本文件综合 Agent-native 的独立 reviewer/fixed-point 思路，以及成熟工程组织常见的 design/functionality/complexity/tests/security review 实践。

Review 从固定 Git 范围开始，但不局限于 diff：为了判断真实影响，必须读取受影响 interface、调用方、测试和必要上下文。

## 1. Review Setup

进入 Review 前：

1. 确定 fixed point：
   - baseline SHA；
   - branch merge-base；
   - 用户指定 commit/tag。
2. 验证 fixed point 能解析，diff 范围正确。
3. 记录：
   - `git diff --stat <base>...HEAD`
   - `git diff <base>...HEAD`
   - `git log <base>..HEAD --oneline`
4. 找到 Spec / Requirement 来源。
5. 找到仓库自己的 coding/architecture standards。
6. 运行可自动化检查：
   - formatter；
   - linter；
   - typecheck；
   - unit/integration tests；
   - build；
   - dependency/security scanners（若项目已有）。
7. Reviewer 默认只读；不得为了方便审查而改当前 checkout。

没有明确 fixed point 时，不凭记忆评论“这次改动”。

## 2. Standards Discovery

通用 review 规则不能覆盖所有语言/框架。

Review 前主动寻找：
- `AGENTS.md` / repo instructions；
- contributing guide；
- architecture docs；
- formatter/linter config；
- compiler/type-check config；
- test conventions；
- existing patterns；
- 项目明确引用的官方/社区 guideline。

如果需要外部 guideline，优先官方、标准组织、成熟项目；不要随机照搬博客风格。

仓库的明确规则优先于 reviewer 的个人偏好。

## 3. Fresh-context Principle

实现者和 reviewer 的目标不同。

如果 Harness 支持 sub-agent / fresh context：
- 中大型改动优先让独立 reviewer 执行；
- 不同 review axis 尽量独立，避免上一轴结论锚定下一轴；
- 高风险 specialist review 使用不同目标 prompt。

如果只有一个模型：
- 仍按独立 passes 执行；
- 每一 pass 重新从 diff / source evidence 出发；
- 不把上一 pass 的“总体印象”当证据。

## 4. Review Axes

### Axis A — Spec / Behavior Compliance

只问：

> 已确认需求是不是被完整、准确实现？

检查：
- required behavior；
- non-goals；
- acceptance criteria；
- error / empty / cancel / close；
- permissions；
- scope creep；
- compatibility（只有真实消费者时）；
- 用户场景是否真的可达。

缺 Spec 时明确报告 `no authoritative spec`，不要发明要求。

### Axis B — Correctness / Bug Hunt

这一轴独立于 Spec。即使实现了需求，也可能有 bug。

主动寻找：
- null / undefined / empty / boundary；
- off-by-one；
- stale state；
- lost update；
- race / TOCTOU；
- deadlock / starvation；
- async ordering；
- timeout / retry / cancellation；
- duplicate execution / idempotency；
- partial failure / rollback；
- resource cleanup / leak；
- swallowed errors；
- invalid input / trust boundary；
- overwrite / data loss；
- path / encoding / timezone / locale；
- cache invalidation；
- serialization / schema mismatch；
- error path 与 happy path 不对称；
- changed contract 的遗漏调用方；
- out-of-order / repeated workflow step；
- multi-tab / multi-device / concurrent actor 行为；
- value / quota / limit bypass。

不要只扫 diff 文本；沿受影响 seam 追一层调用者/被调用者，确认新行为是否破坏既有假设。

### Axis C — Design / Maintainability / Complexity

问：

> 这份实现值得长期保留吗？是否比问题本身更复杂？

检查：
- module depth；
- interface 是否暴露过多知识；
- seam 是否真实赚回复杂度；
- state ownership；
- dependency direction；
- locality；
- side effects；
- naming / domain language；
- speculative abstraction；
- duplicate source of truth；
- legacy/fallback；
- 不必要兼容层；
- 是否存在更简单的删除/合并方案；
- 是否把 future problem 提前设计进现在；
- 可理解性是否足够让未来维护者快速修改。

#### 固定 smell baseline

仓库自己的明确标准优先；以下是高信号 heuristic，不是机械违规：

- **Mysterious Name**
- **Duplicated Code**
- **Feature Envy**
- **Data Clumps**
- **Primitive Obsession**
- **Repeated Switches**
- **Shotgun Surgery**
- **Divergent Change**
- **Speculative Generality**
- **Message Chains**
- **Middle Man**
- **Refused Bequest**

Smell 必须结合当前代码语义判断；不要为了命中列表而报 finding。

### Axis D — Test / Verification Quality

问：

> 现有测试真的能在实现错误时失败吗？

检查：
- 测 observable behavior 还是实现细节；
- bugfix 是否有能先红后绿的 regression test；
- 关键负路径/边界是否覆盖；
- assertion 是否过宽或只验证“没抛异常”；
- mock 是否把真正需要验证的核心逻辑 mock 掉；
- snapshot 是否掩盖语义错误；
- 是否 flaky；
- 新增 interface 是否通过 interface 测；
- 测试是否与 production change 同时进入；
- 测试自身是否复杂到难以信任；
- 哪个错误实现仍然会通过当前测试。

不要以 coverage 数字替代测试质量判断。

### Axis E — Behavioral Discovery / Requirement Drift

先从 diff、测试、界面和运行行为独立重建：

- 默认；
- 失败；
- 取消；
- 关闭；
- 保存；
- 删除；
- 排序；
- retry；
- 权限；
- 持久化；
- 不可逆动作。

再与 Requirement 比。

若代码形成用户可感知但未定义的行为：
- 标记 `Requirement Gap`；
- 不让 reviewer 自行选产品方案；
- 回 Requirement Discovery；
- 多个独立 Gap 可进入 Decision Questionnaire。

### Axis F — Operational / Observability Fit

对会长期运行、服务真实用户或具有后台任务的系统，检查：
- 错误是否可定位；
- 关键业务/状态转换是否可观察；
- retry/circuit breaker 是否有信号；
- 日志是否足够但不过量；
- 是否泄露 PII/secret；
- health/metrics 是否与风险匹配；
- 失败后是否能判断数据处于什么状态。

一次性本地脚本不机械要求生产级 telemetry。

### Axis G — Risk Specialists（按触发加载）

仅当 diff 涉及时追加专项 pass：

#### Security / Privacy
关注：
- trust boundary；
- entry point；
- authn/authz；
- contextual authorization；
- input source → processing → sink；
- secret/PII；
- business workflow bypass；
- crypto；
- logging / error disclosure；
- unsafe file/path operations；
- dependency/config changes。

对于新应用、重大 release、遗留系统首次接管、合规或事故后场景，可做 **baseline security review**；日常 change 默认做 **diff-based security review**。

#### Concurrency
关注：
- shared mutable state；
- ordering；
- race / deadlock；
- atomicity；
- cancellation；
- retry/idempotency；
- multi-process / multi-tab / multi-device。

#### Data / Migration
关注：
- schema evolution；
- partial migration；
- rollback；
- old/new readers；
- dual write；
- data loss；
- irreversible transformation；
- migration observability。

#### Performance
关注：
- asymptotic complexity；
- hot path；
- N+1；
- unbounded work；
- memory / allocation；
- unnecessary IO/network calls；
- latency amplification；
- benchmark validity。

#### UI / Accessibility
关注：
- keyboard；
- focus；
- semantics；
- visual/interaction regression；
- empty/loading/error state；
- user-visible feedback。

#### Public API / Compatibility
只有存在真实外部消费者时触发。

## 5. Review Granularity

### 小改动

一个 fresh reviewer 可以按 A→F 连续完成，Risk Specialist 按需。

### 中大型改动

为了提高召回率，优先拆成独立 passes / sub-agents：

1. Spec + Behavioral；
2. Correctness bug hunt；
3. Design + complexity/smell；
4. Tests + verification；
5. Operational fit；
6. Risk specialist（若触发）。

最后聚合并去重。

不要让一个“总体看起来不错”的印象阻止后续 reviewer 找问题。

## 6. Read Every Changed Line, Then Read Context

Reviewer 应：
- 读每一处 changed line；
- 看完整函数/模块，而不是只看 patch hunk；
- 必要时看 caller/callee；
- 先看测试也可以帮助理解 intent；
- 对用户可见 UI/行为，必要时运行/演示，而不是只读代码。

## 7. Change Shape 也是 Review 输入

如果 diff 同时混入：
- 大量 rename/move；
- 全库 format；
- generated rewrite；
- feature；
- bugfix；
- refactor；

先判断是否应该拆 commit/patch。

Reviewability 是质量属性。

一个难以理解的 giant diff 会显著降低 reviewer 的问题召回率。

## 8. Finding Quality Gate

每个 finding 必须包含：

- `file:line` / hunk / symbol；
- **Observed**：代码现在做什么；
- **Failure scenario / violated rule**：什么输入或流程会出错，或违反哪条明确规则；
- **Impact**：为什么值得修；
- **Severity**；
- **Confidence**；
- **Verification**：如何证明或反驳。

没有具体触发条件、证据或规则依据的“感觉可以更优雅”不算 finding。

### Severity

- **Blocker**：数据损坏、安全漏洞、核心行为错误、无法进入 Accept；
- **Major**：真实功能/设计/测试问题，当前任务应修；
- **Requirement Gap**：产品行为未定义，需要用户决策；
- **Minor**：低风险局部质量问题；
- **Note**：非阻塞建议。

formatter/linter 能稳定自动处理的问题不要占用人工 review 主体。

## 9. Reviewer 也可能错

Review finding 是技术假设，不是命令。

实施前：
- 检查 finding 是否符合当前代码库现实；
- 若 reviewer 错，给出证据并拒绝；
- 不做表演式“全部同意”。

Review 本身只读，不在审查过程中修改 checkout。审查发现问题后，先判断修复是否仍在用户已经理解并批准的方案范围内：

- 若只是当前设计内的局部实现错误，回到 Implement / Regression，修复后重新审查受影响范围。
- 若修复需要新架构、公共接口、模型/资源生命周期、性能取舍、数据语义或超出原计划的范围，把它当作新的 Design 或 Requirement Discovery 事项；先用用户能理解的实际流程说明发现、影响和候选方向，再完成 Design Alignment 后实施。

用户此前批准的是当时讲清的方案和范围，不自动授权审查中刚发现的另一种设计。存在这种边界变化时，不要用“顺手修复”跳过对齐。

## 面向用户的审查汇报

用户不懂代码时，finding 的第一句话写用户会遇到什么、发生条件和影响。文件路径、调用链、缓存、队列等实现证据放在后面作为依据，不让理解实现细节成为理解结论的前置条件。

明确区分已复现/测量的行为与静态代码推断。代码能证明重复创建了模型对象，不等于已经测得保存耗时；没有运行证据时，应说“存在会拖慢的风险”，不能把它写成已确认的运行根因。

## 10. Review Cadence

强制：
- 完成重要 feature / vertical slice 后；
- 大型重构的稳定 checkpoint；
- merge / Finish 前。

复杂任务中 review early, review often，避免所有问题在最终一次审查才堆积。

## 11. Review Learning Loop

如果线上 bug / acceptance failure / repeated review finding 暴露出一个**重复模式**：

1. 判断它是不是项目特有的长期风险；
2. 若是，更新 repo-specific checklist / test / lint / architecture rule；
3. 能自动化就优先自动化；
4. 不要把每次偶发 bug 都永久塞进 checklist。

目标是让相同类别问题越来越难再次出现。

## 12. Gate

不能进入 Accept 的情况：
- 未处理 Blocker；
- 未解释 Major；
- 关键 Requirement Gap 未确认；
- 测试/验证不能证明核心行为；
- Review fixed point 不明确；
- 重要风险 specialist 尚未执行；
- giant mixed diff 导致核心语义无法可靠审查。

Review 的成功标准不是“找到很多条”，而是：

> 高风险真实问题有较高概率被发现；低价值噪声不会淹没真正的问题；每轮 review 都让长期 code health 更好。
