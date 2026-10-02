# Evaluation Engineering

## 职责

Evaluation 回答：

> 某个 Candidate Change 是否在已知条件下满足其行为目标。

Evaluation 不是 Skill 创建阶段，也不是所有修改的必经流程。

它只是 Skill Evolution 中，当修改结果存在不确定性时，用于降低风险的验证工具。

## 进入条件

以下情况可以进入 Evaluation：

- 要声称某个修改改善了行为；
- 新 Principle / Workflow / Prompt / Example 需要验证；
- 修改可能影响已有能力；
- 需要进行 regression 检查。

以下情况不需要强制 Evaluation：

- 明确的小修复；
- 直接纠正错误路径；
- 没有不确定性的维护修改。

## 生命周期位置

完整关系：

```text
Skill Use
↓
Case
↓
Skill Evolution
↓
Candidate Change
↓
（必要时）Evaluation
↓
Skill vNext
```

## 执行流程

```text
1. 定义 claim
2. 选择 Case
3. 固定重要条件
4. 执行验证
5. 观察结果
6. 判断
7. 记录
```

## Claim

不要问：

```text
这个 Prompt 好不好？
```

应定义为：

```text
在条件 C 下，当输入 X 出现时，模型应执行 Y，并产生可观察结果 Z。
```

## Case 选择

优先使用真实经验：

- Usage Case；
- Replay Case。

必要时补充：

- Boundary；
- Failure；
- Regression；
- Holdout。

不追求机械数量。

## 结果

```text
conforming
= 支持 claim

deviated
= 与 claim 不符

unmeasured
= 缺少足够证据
```

## 失败处理

失败时先判断 owner：

- Requirement 错误 → 回到定义；
- Case 不合适 → 重新选择；
- Skill 修改错误 → 回 Evolution；
- Harness / Tool / Model 问题 → 不通过 Skill 修补。

## 原则

- Evaluation 验证变化，不创造变化。
- 真实使用是主要反馈来源。
- 不为了 Evaluation 制造脱离实际的测试材料。
- 结论范围不能超过实际证据。