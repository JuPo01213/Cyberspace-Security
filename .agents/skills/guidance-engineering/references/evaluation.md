# Evaluation Engineering

## 职责

Evaluation 只负责：

> **当 Skill Evolution 中某个 Candidate Change 存在实质不确定性时，利用已有真实经验材料判断这个变化是否值得保留。**

Evaluation 不是 Skill Construction 的必经步骤，也不是所有 Evolution 的必经步骤。

```text
Skill Use / Replay
→ Case
→ Skill Evolution
→ Candidate Change
→ （必要时）Evaluation
→ Skill vNext
```

## 什么时候进入

只有出现以下情况之一时考虑进入：

- 要把局部经验升级为通用规则；
- Candidate Change 可能影响多个已有场景；
- 新旧行为存在 tradeoff；
- 要判断 Example 是否真的增加价值；
- 要做 regression；
- 要声称某个变化“更好 / 更稳定 / 修复了泛化问题”；
- 对变化是否正确存在实质不确定性。

以下情况不强制进入：

- typo / path / stale reference 修复；
- 用户明确且无歧义的遗漏修正；
- 不改变行为语义的结构清理；
- 明确、局部、低风险的维护修复。

## 检验材料从哪里来

优先使用真实材料：

1. **Usage Case**
   - Skill 后续真实调用中产生；
2. **Replay Case**
   - 从已有工作上下文回溯提取；
3. **由真实 Case 派生的边界场景**
   - 只改变真正决策条件，用来检查边界；
4. **Regression Case**
   - 来自已有重要能力或历史问题。

不要为了满足“必须 Evaluation”的形式要求，凭空制造与真实工作无关的测试集。

如果没有足够真实材料：

- 可以返回 `unmeasured`；
- 可以等待后续真实使用；
- 不把缺少 Eval 当作阻止明确小修复的理由。

# 执行流程

```text
1. 定义要验证的 Candidate Change / claim
2. 选择有来源的 Case
3. 固定会影响判断的重要条件
4. 执行 candidate
5. 捕获真实结果
6. 判定
7. 回到 Evolution
```

## 1. 定义 claim

不要问：

```text
这个 Skill 好不好？
```

而要写成：

```text
在条件 C 下，
当输入 X 出现时，
Candidate Change 应使行为从 A 变为 B，
并产生可观察结果 Z。
```

如果无法形成可观察 claim，先回 [skill-evolution.md](skill-evolution.md) 重新明确 Candidate Change。

## 2. 选择有来源的 Case

优先顺序：

```text
已有 Usage Case
→ Replay Case
→ 由这些 Case 派生的 boundary / regression
```

必要时可使用：

- Boundary；
- Failure；
- Holdout；
- Cross-carrier；
- Regression。

但这些场景应能解释“它从哪个真实经验或明确 requirement 派生”，而不是独立于工作背景凭空生成。

不追求机械数量，只覆盖会改变当前决策的场景。

## 3. 固定重要条件

记录真正影响结果的：

```text
model / version
Harness
tools / permissions
relevant parameters
initial state
actual delivered Prompt / Skill / Examples
```

不需要把所有环境信息都变成测试元数据。

## 4. 执行 candidate

Evaluation 看真实执行，而不是设计稿。

比较需要时，可以做 baseline / candidate：

```text
same relevant condition
→ baseline behavior
→ candidate behavior
```

只有要声称“变化带来改善”时才需要 baseline。

## 5. 捕获真实结果

观察：

- 最终输出；
- 工具调用；
- 文件变化；
- 状态变化；
- failure；
- completion evidence；
- 是否破坏旧能力。

关键观察拿不到时，不猜。

## 6. 判定

统一结果：

```text
conforming
= 当前证据支持 Candidate Change 的 claim

deviated
= 观察结果与 claim 不符

unmeasured
= 当前真实材料不足以判断
```

必要时附加：

```text
regression
= Candidate Change 改善目标行为但破坏重要旧能力
```

判定原则：

- 语义行为优先于固定措辞；
- 模型自评不是证据；
- 命令成功 / HTTP 200 / 文件存在不天然等于业务完成；
- 结论只覆盖实际观察条件；
- 没有证据时用 `unmeasured`，不脑补。

## 7. 回到 Evolution

Evaluation 不自己决定 Skill 生命周期。

把结果交回 [skill-evolution.md](skill-evolution.md)：

```text
conforming
→ Evolution 可保留 Candidate Change

deviated
→ Evolution 重新归因 / revise / reject

regression
→ Evolution 调整边界或回退

unmeasured
→ Evolution 决定等待真实使用、补材料或不声称已验证
```

结果可以补充到原 Case，或形成新的 Eval Case；版本变化仍由 Git 保存。

# 不同对象的关注点

### Prompt / Principle

- 目标行为；
- 条件与边界；
- instruction / data 分离；
- failure behavior。

### Workflow

- 阶段；
- 状态；
- 分支；
- completion / stop。

### Example

- 是否提供独立改善；
- 是否只模仿表面风格；
- 删除后是否真的退化；
- 是否导致错误泛化。

### Skill boundary

- discovery；
- non-trigger；
- incomplete input；
- 是否错误接管相邻请求。

# 完成标准

一次 Evaluation 完成时：

- Candidate Change / claim 明确；
- 使用的 Case 有真实来源；
- 重要执行条件已记录；
- 实际结果已观察；
- 给出 `conforming / deviated / regression / unmeasured`；
- 结论没有超过证据范围；
- 结果已经交回 Skill Evolution 处理。

Evaluation 的终点不是“发布”，而是：

```text
Evaluation result
→ Skill Evolution
```
