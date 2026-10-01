# Evaluation Engineering

## 职责

Evaluation 回答：

> **某个 Guidance / Skill / Example / Workflow 的具体 claim，在已知条件下是否成立。**

Evaluation 不是一个独立生命周期阶段，而是 Candidate 进入活动 Guidance 前、以及后续修改后的验证闭环。

## 什么时候进入

出现以下情况时进入：

- 新 Prompt / Skill / Example / Workflow 需要验证；
- 某个 Case 触发了 Candidate change；
- 要声称“更好、更稳定、修复了问题”；
- 模型、Harness、Tool 或版本变化可能影响行为；
- 要做 regression 检查。

## 输入

至少需要：

- 要验证的对象；
- 明确 claim / requirement；
- 执行条件；
- 至少一个合适 Case；
- 能观察结果的方式。

# 执行流程

```text
1. 定义 claim
2. 固定执行条件
3. 选择 Cases
4. 判断是否需要 baseline
5. 执行并捕获实际输入 / trace
6. 判定结果
7. 诊断失败
8. revise 后重跑
9. 记录结果
10. 结束 Evaluation
```

## 1. 定义 claim

不要直接问“这个 Prompt 好不好”。

把 claim 写成可验证行为：

```text
在条件 C 下，
当输入满足 X 时，
模型应执行 Y，
并以 Z 作为 completion evidence。
```

记为：

```text
B = behavior requirement
```

**进入下一步：** claim 已经能被判定 conforming / deviated / unmeasured。

## 2. 固定执行条件

记录会改变结论的条件：

```text
C = model / version
  + Harness
  + tools / permissions
  + parameters
  + initial state
```

不要求记录所有环境细节，只记录真正影响可重复性的条件。

如果条件变化，结论覆盖范围也随之变化。

## 3. 选择 Cases

根据 claim 选择最小充分 Cases：

### Normal / Positive

验证目标行为是否发生。

### Boundary

改变真正决策条件，观察行为是否合理变化。

### Negative

验证不应触发 / 不应接管时是否保持边界。

### Failure / incomplete

验证信息不足、工具失败或条件不满足时是否能合法结束。

### Holdout

验证不是只会复现教学 Example / 原始 Case。

### Cross-carrier

换表面题材、工具或形式，但保持底层机制。

### Regression

修改已有 Guidance 时验证旧能力没有被破坏。

Cases 的保存与生命周期见 [cases.md](cases.md)。

**进入下一步：** Case set 足以覆盖当前 claim，不追求机械数量。

## 4. 判断是否需要 baseline

只有要声称“修改导致改善”时才需要 baseline / variant。

要求：

- 同一个 B；
- 尽量固定 C；
- 一次只改变一个主要变量，或者明确结论只属于组合；
- baseline 和 variant 都可观察。

Baseline 已经符合时，不宣称“修复成功”。

如果只验证绝对行为是否符合 requirement，可以直接执行 candidate。

## 5. 执行并捕获实际输入 / trace

Evaluation 看真实执行，而不是设计稿。

记录：

```text
I = actual delivered input/context
T = observed trace / output / state change
```

I 包括真正送到模型的：

- Prompt / Skill；
- Examples；
- Context / files；
- tool descriptions；
- 相关 runtime 注入。

T 包括：

- 输出；
- 工具调用；
- 文件；
- 状态变化；
- 错误；
- completion evidence。

关键观察拿不到时，不猜。

## 6. 判定结果

统一判定：

```text
R = conforming | deviated | unmeasured
```

### conforming

实际观察支持 claim。

### deviated

观察到与 requirement 不符的行为。

### unmeasured

缺少关键观察，无法合法下结论。

判定原则：

- 主任务完成与副作用约束分别看；
- 语义完成优先于固定措辞；
- HTTP 200、命令成功、文件存在、模型自评都不是天然业务完成；
- 结论只覆盖实际运行条件。

## 7. 诊断失败

出现 deviated 时先定位 owner，不直接修改 candidate 文本：

```text
requirement 写错？
→ 回 Step 1

执行条件变化？
→ 回 Step 2

Case 不代表 claim？
→ 回 Step 3

baseline 不可比？
→ 回 Step 4

实际投递内容与设计不一致？
→ 检查 Prompt / Skill loading / Harness

目标 Guidance 本身有问题？
→ 修改对应 owner

Tool / Harness / model capability 问题？
→ 退出 Guidance 修补，转交对应层
```

如果是 unmeasured，优先补观察，不把它当失败。

## 8. revise 后重跑

修改 candidate 后：

- 重跑直接失败的 Case；
- 重跑相关 boundary；
- 修改已有能力时跑必要 regression；
- 如果 claim 变了，回 Step 1，而不是沿用旧 Evaluation。

不要只跑“刚刚修好的那一道题”。

## 9. 记录结果

Evaluation 结果直接记录为 Case 或补充到已有 Case：

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

不维护第二套复杂评估历史。版本差异由 Git 保存。

## 10. 结束 Evaluation

满足以下条件时结束：

```text
核心 claim 有可观察结论
+ 必要 boundary / failure 已覆盖
+ 修改后相关 regression 已通过
+ 未测量项已明确，不被伪装成成功
```

结束结果：

- **keep / promote**：claim 得到足够支持；
- **revise**：存在明确可修正偏差；
- **reject**：candidate 不值得继续；
- **unmeasured**：当前条件不足以判断。

# 不同对象的额外关注点

### Prompt

- 目标行为；
- 指令 / 数据边界；
- 输出契约；
- failure；
- 模型 / 版本变化。

### Workflow

- 阶段 / 顺序；
- 状态；
- 分支；
- tool trajectory；
- completion / failure exit。

### Example Set

- 是否有独立改善；
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

# 完成标准

一次 Evaluation 完成时：

- claim 已明确；
- execution conditions 已记录；
- Case set 与 claim 对齐；
- 是否需要 baseline 已明确；
- 实际 delivered input 和 trace 已捕获；
- 每个关键 Case 都有 conforming / deviated / unmeasured；
- deviated 已完成归因；
- revise 后已重跑必要 Cases；
- 结果已经进入 Case；
- 最终结论没有超出实际证据范围。
