# Skill Evolution：技能演化流程

## 职责

Skill Evolution 负责：

> **让一个已经存在的 Skill 从真实使用和历史经验中持续吸收反馈，并形成下一版本。**

它是 Skill 创建之后的主要改进流程。

```text
Skill
→ Use / Replay
→ Case
→ Evolution
→ Candidate Change
→ optional Evaluation
→ Skill vNext
```

Evaluation 不是前置门槛，也不是每次修改的必经步骤。

# 演化来源

## 1. 真实使用反馈

主路径：

```text
Skill 被调用
→ 真实任务执行
→ 结果 / 用户纠正 / 新边界 / 成功模式
→ Usage Case
→ Evolution
```

真实工作天然提供检验材料。

## 2. 历史上下文回溯

当工作已经完成，之后才回顾并抽象经验：

```text
完整工作上下文
→ 提取关键决策 / 纠正 / 结果
→ Replay Case
→ Evolution
```

这里的材料来自真实历史，而不是为了测试临时编造。

## 3. 用户明确要求修改已有 Skill

如果用户直接要求：

- 加入某条能力；
- 删除某条错误规则；
- 调整边界；
- 重构已有 Skill；

这个明确要求本身就是 Evolution signal。

不要重新判断“是否值得修改”；直接进入演化流程，并利用现有 Case / 上下文帮助设计。

# 执行流程

```text
1. 收集演化信号
2. 读取相关 Case / 上下文
3. 判断真正 owner
4. 抽象可迁移变化
5. 形成 Candidate Change
6. 判断是否需要 Evaluation
7. 修改 Skill
8. 必要时验证并迭代
9. 更新 Case 状态
10. Git commit → Skill vNext
```

## 1. 收集演化信号

来源可能是：

- 用户纠正；
- 使用失败；
- 新边界；
- 重复出现的人工补救；
- 明显成功且值得固化的方法；
- 历史工作复盘；
- 用户直接要求修改已有 Skill。

先明确：

> 这次为什么要改变 Skill？

## 2. 读取相关 Case / 上下文

优先读取与当前变化直接相关的：

- Usage Case；
- Replay Case；
- 用户当前明确反馈；
- 对应 Git revision；
- 相关最终产物或 evidence。

Case 是经验，不是规则。

不要：

```text
一次失败
→ 直接追加永久 Prompt
```

## 3. 判断真正 owner

先归因，再改。

检查变化真正属于：

- Principle；
- Workflow；
- Prompt；
- Example；
- Skill boundary / discovery / packaging；
- reference；
- script / schema；
- Harness / Runtime；
- Tool / Permission；
- Model capability。

如果根因不属于 Skill：

```text
不通过增加 Guidance 修复
→ Case = no-change 或转交对应层
```

## 4. 抽象可迁移变化

如果来自具体 Case，问：

> 换掉当前项目名、文件名、品牌、题材后，真正决定行为的关系还剩什么？

正确方向：

```text
Specific Case
→ 决策条件 / 机制
→ Candidate Principle / Workflow / Example / Boundary
```

避免：

```text
Specific Case
→ 匿名化
→ 假装通用规则
```

明显局部错误可以直接修，例如：

- 路径写错；
- reference 失效；
- 当前 API 已变；
- 用户明确要求但 Skill 漏写；
- 错误路由。

这类修复不需要为了“抽象”扩大问题。

## 5. 形成 Candidate Change

候选变化可以是：

- 新增、删除或收窄 Principle；
- 调整 Workflow；
- 修改 Prompt；
- 增加 / 删除 Example；
- 调整 Trigger / Non-trigger；
- 重组 references；
- 用 script / schema 替代重复自然语言规则；
- 合并或拆分能力边界。

每个 Candidate Change 应能回答：

- 改什么；
- 为什么改；
- 来源是什么；
- 哪个 owner 承担；
- 可能影响什么旧行为。

## 6. 判断是否需要 Evaluation

这是一个**分支判断**。

### 可以直接修改

通常包括：

- 明确 typo / path / stale reference；
- 用户直接指出且没有歧义的遗漏；
- 不改变行为语义的结构清理；
- 明确的局部维护修复。

### 建议进入 Evaluation

当：

- 要把局部经验升级为通用规则；
- 修改可能影响多个已有场景；
- 新旧规则存在 tradeoff；
- 要声称“更稳定 / 更好 / 修复了泛化问题”；
- 需要判断 Example 是否真有价值；
- 需要 regression；
- 对 Candidate Change 是否正确存在实质不确定性。

如果需要 Evaluation，优先使用真实 Usage Case / Replay Case 及其派生边界场景。

如果没有真实素材支撑检验，不把“缺 Evaluation”当作阻止小修复的理由，也不凭空制造脱离实际的测试体系。

## 7. 修改 Skill

修改唯一 owner。

保持：

- 自包含；
- 语义单一 owner；
- supporting resource 有消费者；
- 正常运行不加载完整 Case 历史；
- Harness / Tool 能力不被文本伪造；
- Git diff 尽可能聚焦本次变化。

## 8. 必要时验证并迭代

如果 Step 6 判断需要 Evaluation：

```text
Candidate Change
→ [evaluation.md](evaluation.md)
→ keep / revise / reject / unmeasured
```

结果处理：

- `keep` → 保留修改；
- `revise` → 回到 Step 3–7 的对应位置；
- `reject` → 回退 Candidate Change；
- `unmeasured` → 说明当前证据不足，不伪装成已验证。

如果不需要 Evaluation，直接进入下一步。

## 9. 更新 Case 状态

Evolution 完成后回写相关 Case：

### absorbed

```text
status = absorbed
revision = <new git revision>
```

表示经验已经被 Skill 新版本吸收。

### no-change

如果最终发现：

- 根因不属于 Skill；
- 该经验不值得形成长期变化；
- Candidate Change 被放弃；

则：

```text
status = no-change
reason = ...
```

Case 只保存结果指针，不复制完整版本历史。

## 10. Git commit → Skill vNext

在该 Skill 自己的本地 Git repository 中：

```text
review diff
→ 删除 accidental / dead changes
→ 必要检查
→ git add
→ git commit
```

提交说明描述：

- 吸收了什么经验；
- 改变了什么能力；
- 如果做过 Evaluation，验证范围是什么。

新的 Git revision 就是 Skill vNext。

# Maintenance 与 Evolution 的关系

不建立两套不同流程。

它们只是变化性质：

```text
Maintenance
= 能力目标和边界基本不变，只修复、适配、清理

Evolution
= 能力目标、边界或抽象本身发生变化
```

二者都使用本文件的同一流程。

# 完成标准

一次 Skill Evolution 完成时：

- 演化信号来源明确；
- 已读取必要 Case / 上下文；
- 根因与 owner 已判断；
- Candidate Change 有真实依据；
- 已决定 Evaluation 是否必要；
- Skill 已完成对应修改；
- 必要 Evaluation 已执行，或明确未执行原因；
- 相关 Case 已关闭为 `absorbed` 或 `no-change`；
- 已产生新的 Git revision；
- Skill 可以继续进入真实使用。

完成后生命周期继续：

```text
Skill vNext
→ Real Use
→ new Case
→ next Evolution
```
