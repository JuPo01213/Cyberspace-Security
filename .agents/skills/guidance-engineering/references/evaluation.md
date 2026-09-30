# Evaluation Engineering

## 职责

Evaluation 只回答：

> **某个候选 Guidance 或 Skill 修改，在已知条件下是否真的改善了目标行为。**

它是 `Case → Skill vNext` 反馈回路里的验证动作，不是独立生命周期阶段。

## 测量对象

```text
B = behavior requirement
C = execution conditions
I = actual delivered input/context
T = observed trace
R = compare(B, T)
```

- **B**：当前真正要满足的目标、边界与完成条件；
- **C**：模型/版本、Harness、工具、权限和初始状态；
- **I**：实际送达的 Prompt、Skill、Examples、files、tool descriptions；
- **T**：输出、工具调用、文件、状态变化和错误；
- **R**：`conforming | deviated | unmeasured`。

关键观察缺失时只能是 `unmeasured`。

## Case

测试输入和真实使用记录统一按 [cases.md](cases.md) 管理。

Teaching Example 不能同时作为唯一考试题。

## 不同对象的关注点

### Prompt

- 目标行为；
- 指令/数据边界；
- 输出契约；
- 失败处理；
- 模型/版本变化。

### Workflow

- 阶段/顺序；
- 状态；
- 分支；
- tool trajectory；
- completion / failure exit。

### Example set

- 是否带来独立改善；
- holdout 上是否有效；
- 是否只模仿表面风格；
- 删除后是否真的退化。

### Skill

除加载后的行为外，还要测：

- positive discovery；
- indirect discovery；
- negative discovery；
- incomplete input；
- loaded-but-wrong behavior。

## 最小运行

1. 冻结 B。
2. 记录 C。
3. 捕获真实 I，不只看“设计稿”。
4. 执行并记录 T。
5. 独立判定 R。
6. 把结果记录成 Case 或补充到已有 Case。
7. 决定 keep / revise / reject。

## Baseline / Variant

只有要声称“修改导致改善”时才做：

- 同一个 B；
- 尽量固定模型、版本、参数、输入、Harness、Tool 和权限；
- 一次只改变一个主要变量，或明确结论只属于组合；
- 两侧都可观察。

Baseline 已经符合时，不宣称“修复成功”。

## 泛化

当修改来源于具体 Usage Case，并声称得到通用原则时，至少考虑：

- **holdout**：未进入生产 Guidance 的独立题；
- **boundary**：改变真正决策条件，观察原则是否释放/反转；
- **cross-carrier**：换题材/工具/表面形式，但保持机制。

只换几个名词不算有意义的泛化测试。

## 判定

- 主任务完成与副作用约束分别判断；
- 语义完成优先于固定措辞；
- HTTP 200、命令成功、文件存在、模型自评都不是天然业务完成；
- 结论只覆盖实际运行的模型/版本/条件；
- 没有会改变决策的消费者时，不无限扩展测试。

## 最小记录

Evaluation 的结果可以直接进入 Case：

```yaml
case_id: CASE-...
source: evaluation
unit_under_test: prompt | workflow | example_set | skill
requirement: ...
execution_conditions: ...
observed:
  - ...
result: conforming | deviated | unmeasured
evidence_refs: []
```

不再维护第二套复杂评估历史。需要版本差异时使用 Git。
