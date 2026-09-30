# Evaluation Engineering

## 职责

Evaluation 只回答：

> **在固定执行条件下，当前 Guidance 是否产生了目标行为。**

它不重新设计 Prompt/Workflow，也不决定经验是否升格；前者回对应设计层，后者由 Evolution 决定。

## 测量对象

```text
B = frozen behavior contract / requirement
C = execution conditions
I = actual delivered input
T = observed trace
R = compare(B, T)
```

- **B**：优先引用 [workflow-design.md](workflow-design.md) 中已经冻结的 behavior contract；简单 Prompt 可以使用同等明确的局部 requirement。
- **C**：模型、参数、Harness、工具、权限、初始状态。
- **I**：实际送达的消息、文件、图片、工具描述及其顺序。
- **T**：输出、工具调用、文件、网络、状态变化和错误。
- **R**：`conforming | deviated | unmeasured`。

关键观察缺失时只能是 `unmeasured`，不能猜测通过或失败。

## Case 来源

测试材料统一由 [evaluation/case-engineering.md](evaluation/case-engineering.md) 管理。

Teaching Examples 是教材，不是唯一考试题。新增 Example 后至少保留独立 holdout；要测泛化，可使用 boundary 或 cross-carrier case。

## 测试类型

- **Compliance**：规则应生效时是否发生目标行为。
- **Boundary preservation**：关键条件变化时是否能正确释放/反转规则。
- **Regression**：修改后旧任务是否退化。
- **Integration / trajectory**：工具、文件、网络、多轮和真实状态是否按契约推进。
- **Longitudinal**：只有有长期维护消费者时，才观察跨时间行为漂移。

## 最小运行流程

1. 冻结 B。
2. 记录 C。
3. 固定完整 I，避免把评估意图或答案泄漏进去。
4. 执行并捕获与 B 相关的 T。
5. 独立判定 required/prohibited/conditional/completion。
6. 输出 R 与证据。
7. 把结果交给当前消费者：保留、拒绝、继续取证或进入 Evolution。

## Baseline / Variant

只有要声称“修改造成改善”时才需要因果比较：

- baseline 与 variant 使用同一 B；
- 保持模型、参数、任务、Harness、工具、权限和判定标准尽量不变；
- 明确唯一主要 changed variable；组合修改只能归因于组合；
- 两侧都必须可观察。

baseline 已符合时，不声称“修复成功”；最多说明本轮没有观察到改善空间。

## 判定原则

- 主任务完成与副作用约束分别判定。
- 语义满足优先于固定措辞相似。
- 命令成功、文件存在、模型自评都不是天然完成证据。
- 结果只覆盖实际运行的模型、条件、输入和观察面。
- 题材或关键词相似不等于机制相同。
- 没有会改变决策的消费者时，不无限扩展测试。

## 最小记录

保留足够复核的信息即可：

```yaml
run_id: ...
case_id: ...
behavior_contract_ref: ...
execution_conditions: ...
actual_input: ...
observed_trace: ...
observation_status: complete | partial | missing
behavior_result: conforming | deviated | unmeasured
deviations: []
evidence_refs: []
uncertainty: ...
```

需要 baseline/variant 时，再附：

```yaml
reference_run: ...
variant_run: ...
changed_variable: ...
held_constant: [...]
decision: keep | reject | needs_more_evidence
```

Evaluation 只产生测量结果；是否把候选修改写入活动 Guidance，由 [evolution.md](evolution.md) 决定。
