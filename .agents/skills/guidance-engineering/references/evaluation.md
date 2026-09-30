# Evaluation Engineering

## 职责

Evaluation 回答：

> **在已知执行条件下，一个候选 Guidance 是否真的产生了目标行为。**

它可以独立评估：

- Prompt；
- Workflow；
- Example set；
- Skill；
- General Principle 的实现。

不要求先有 Skill，也不要求先有 Workflow。

## 冻结 Requirement

运行前先固定本次真正要测什么：

```text
B = behavior requirement / contract
C = execution conditions
I = actual delivered input/context
T = observed trace
R = compare(B, T)
```

- **B**：目标、适用条件、required/prohibited、completion 等当前验收要求；
- **C**：模型/版本、参数、Harness、工具、权限、初始状态；
- **I**：实际送达的 messages、Prompt、Skill instructions、files、tool descriptions、Examples；
- **T**：输出、工具调用、文件、网络、状态变化、错误；
- **R**：`conforming | deviated | unmeasured`。

B 不属于 Workflow 专有。若已有正式 Workflow，可直接引用其完成门与边界；若只是简单 Prompt，就冻结一个简单 requirement。

关键观察缺失时只能是 `unmeasured`。

## 不同 Guidance 的测试重点

### Prompt

- 目标行为；
- 指令遵循；
- 数据/指令边界；
- 输出契约；
- 失败处理；
- 模型/版本变化。

### Workflow

Workflow 是独立的行为模型，即使没有独立 reference 也可以作为独立 unit under test：

- 阶段与顺序；
- 条件分支；
- 状态传递；
- tool trajectory；
- completion / failure exit。

### Example

- 加入后是否改善目标行为；
- holdout 上是否有效；
- 是否只模仿表面风格；
- 删除后是否真的退化。

### Skill

除执行行为外，还要测：

- positive discovery；
- indirect discovery；
- negative discovery；
- input incomplete；
- loaded-but-wrong behavior。

## Case 来源

Development / Eval Case 统一由 [evaluation/case-engineering.md](evaluation/case-engineering.md) 管理。

Teaching Example 不能作为唯一考试题。

## Principle 验证

当 Guidance 来自：

```text
Specific Case → Mechanism → General Principle
```

至少测试：

- 原则应生效的独立 concrete case；
- 条件改变后的 boundary case；
- 需要证明迁移时的 cross-carrier case。

Generic Teaching Example 被复述正确不等于原则已泛化。

## 最小运行流程

1. 冻结 B。
2. 记录 C。
3. 捕获真实 I；不要只看“设计稿 Prompt”。
4. 执行并记录与 B 相关的 T。
5. 独立判定。
6. 记录证据与 uncertainty。
7. 根据消费者决定 keep / reject / more evidence / evolution。

## Baseline / Variant

只有要做“修改导致改善”的因果结论时才需要：

- 同一个 B；
- 尽量固定模型、版本、参数、输入、Harness、Tool 和权限；
- 一次只改变一个主要变量，或明确结论只归因于组合；
- 两侧都必须可观察。

Baseline 已经符合时，不宣称“修复成功”。

## Holdout / Boundary / Cross-carrier

- **Holdout**：未进入生产 Guidance 的独立题；
- **Boundary**：改变真正决策条件，检查原则是否反转/释放；
- **Cross-carrier**：换题材/工具/表面形式，机制保持不变。

只换几个名词不算有意义的泛化测试。

## 判定原则

- 主任务与副作用约束分别判定；
- 语义完成优先于固定措辞；
- 命令成功、文件存在、HTTP 200、模型自评都不是天然业务完成；
- 结果只覆盖实际运行的模型/版本/条件；
- 没有会改变决策的消费者时，不无限增加测试。

## 最小记录

```yaml
run_id: ...
unit_under_test: prompt | workflow | example_set | skill | principle
case_id: ...
requirement_ref: ...
execution_conditions: ...
actual_input: ...
observed_trace: ...
observation_status: complete | partial | missing
behavior_result: conforming | deviated | unmeasured
deviations: []
evidence_refs: []
uncertainty: ...
```

需要因果比较时再附 baseline / variant 信息。

Evaluation 只产生测量结论；是否把变化写入活动 Guidance，由 [evolution.md](evolution.md) 决定。
