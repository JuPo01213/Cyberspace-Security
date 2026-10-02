# Skill Evolution：从新经验到 Skill vNext

## 职责

Skill Evolution 负责：

> **当已有 Skill 获得新的 Source / Experience 时，重新理解和抽象这部分信息，与当前能力比较，并形成 Skill vNext。**

它与 Skill Construction 共享同一个核心：

```text
Source
→ Understand
→ Abstract
→ Guidance
```

区别只在于 Evolution 已经有一个当前 Skill，因此还必须：

```text
New Source
→ Understand
→ Abstract
→ compare with current Skill
→ Candidate Change
→ optional Evaluation
→ Skill vNext
```

# 演化 Source

Evolution 的 Source 可以是：

- Skill 的真实使用结果；
- 用户纠正；
- 新边界或新需求；
- 历史工作记录；
- Usage Case / Replay Case；
- 用户明确提出的 Skill 修改要求；
- 平台、Tool、Harness、API 变化；
- 已发现的重复人工补救或稳定成功模式。

Case 是常见载体，但不是进入 Evolution 的强制前置。

用户已经明确要求修改 Skill 时，直接进入本流程，不要求先人为补一个 Case。

# 执行流程

```text
1. 确定新 Source 与变化范围
2. Understand：理解新经验
3. Abstract：提取可迁移关系
4. Compare：与当前 Skill 求差
5. 形成 Candidate Change
6. 判断是否需要 Evaluation
7. 修改唯一 owner
8. 必要时验证并迭代
9. 保存必要 Case / provenance
10. Git commit → Skill vNext
```

## 1. 确定新 Source 与变化范围

先回答：

```text
发生了什么新信息？
它可能影响当前 Skill 的哪部分？
本次修改要解决什么？
```

如果 Source 是一次真实使用，优先读取：

- 实际任务目标；
- Skill revision；
- 真实输出 / tool trace / 文件变化；
- 用户反馈；
- completion / failure。

如果 Source 是历史工作记录，先确定要回顾的范围。

如果 Source 是用户明确修改要求，直接把要求作为当前变化约束。

## 2. Understand：理解新经验

不要看到一个失败就立即改 Prompt。

先重建：

```text
Goal
→ Current Skill behavior
→ Observation
→ Outcome
→ Correction / new requirement
→ Why current behavior was insufficient
```

对于较长工作轨迹，仍然重建：

```text
Initial approach
→ friction / failure
→ observation
→ decision change
→ result
```

这里的目标是解释发生了什么，而不是先决定修改方案。

## 3. Abstract：提取可迁移关系

分离：

```text
Facts
Local details
Transferable relations
```

优先抽象决策关系：

```text
conditions / observations
→ decision
→ action
→ completion / stop
```

反事实检查：

> 换掉项目、品牌、文件、题材后，这条关系仍然成立吗？

如果只在原场景成立，不要把它升级为通用 Skill rule。

明显局部错误不需要过度抽象，例如：

- typo；
- 路径错误；
- stale reference；
- API 已变；
- 用户明确要求但 Skill 漏写。

这类问题直接形成局部 Candidate Change。

## 4. Compare：与当前 Skill 求差

把新抽象与当前 Skill 对照。

可能出现：

```text
Missing
= 当前 Skill 缺少新关系

Wrong
= 当前规则与新证据冲突

Too broad
= 当前规则适用范围过宽

Too narrow
= 当前规则漏掉真实适用范围

Wrong owner
= 当前内容放错 Prompt / Workflow / Example / Tool / Harness 层

Redundant
= 新经验已经被现有 Skill 覆盖
```

如果属于 `Redundant`，通常不需要修改。

如果根因属于 Harness / Runtime / Tool / Model capability，不通过继续增加 Guidance 修复。

## 5. 形成 Candidate Change

Candidate Change 必须回答：

- 改什么；
- 为什么；
- 新 Source 是什么；
- 抽象出的可迁移关系是什么；
- 当前 Skill 哪里与它不一致；
- 哪个 owner 应承担变化；
- 可能影响哪些已有行为。

变化可以落到：

- Principle；
- Workflow；
- Prompt；
- Example；
- Trigger / Non-trigger；
- reference；
- script / schema；
- Skill boundary / packaging。

不要默认所有变化都写进 `SKILL.md`。

## 6. 判断是否需要 Evaluation

Evaluation 是分支，不是阶段门槛。

### 通常可直接修改

- typo / path / stale reference；
- 用户明确且无歧义的遗漏；
- 不改变语义的结构清理；
- 明确、局部、低风险的维护修复。

### 通常值得 Evaluation

- 把局部经验升级为通用规则；
- 修改会影响多个已有场景；
- 新旧行为存在 tradeoff；
- Example 是否有独立价值不确定；
- 需要 regression；
- 要声称“更好 / 更稳定 / 修复泛化问题”；
- Candidate Change 的正确性存在实质不确定性。

需要时见 [evaluation.md](evaluation.md)。

## 7. 修改唯一 owner

先归因，再修改。

保持：

- 一个语义一个主要 owner；
- Skill 自包含；
- supporting resource 有消费者；
- 正常运行不加载完整 Case 历史；
- Harness / Tool 能力不被文本伪造；
- Git diff 聚焦真实变化。

## 8. 必要时验证并迭代

如果 Step 6 判断需要：

```text
Candidate Change
→ Evaluation
→ conforming / deviated / regression / unmeasured
→ 回到 Evolution
```

处理：

- `conforming` → 保留；
- `deviated` → 重新理解 / 抽象 / 修改；
- `regression` → 调整边界或回退；
- `unmeasured` → 不伪装成已验证，等待或补充真实材料。

如果不需要 Evaluation，直接继续。

## 9. 保存必要 Case / provenance

Case 是来源证据，不是 Evolution 的必经中间对象。

如果这次新经验值得未来追溯：

- 保存 Usage Case；
- 或保存 Replay Case；
- 已有 Case 则更新处理结果。

典型状态：

```text
absorbed
= 已被当前 Skill revision 吸收

no-change
= 已理解，但不需要 Skill 修改

historical
= 只保留历史来源
```

具体见 [cases.md](cases.md)。

## 10. Git commit → Skill vNext

在该 Skill 自己的 Git repository 中：

```text
review diff
→ 删除 accidental / dead changes
→ 必要结构检查
→ git add
→ git commit
```

提交说明描述：

- 新 Source / Experience；
- 实际改变的能力；
- 修改边界；
- 如果执行 Evaluation，其证据范围。

新的 revision 即 Skill vNext。

# Maintenance 与 Evolution

不维护两套流程。

```text
Maintenance
= Capability 基本不变，修复、适配、清理

Evolution
= Capability、边界或抽象本身变化
```

二者都走同一个 Source → Understand → Abstract → Compare → Change 流程。

# 完成标准

一次 Evolution 完成时：

- 新 Source 和变化范围明确；
- 新经验已被正确理解；
- Local details 与 transferable relations 已分离；
- 已与当前 Skill 求差；
- Candidate Change 有真实依据；
- 修改落到正确 owner；
- 已明确 Evaluation 是否必要；
- 必要验证已经完成，或明确为 unmeasured；
- 必要 provenance 已保存；
- 已产生新的 Git revision；
- Skill 可以继续进入真实使用。

生命周期继续：

```text
Skill vNext
→ Real Use
→ New Experience
→ Evolution
```
