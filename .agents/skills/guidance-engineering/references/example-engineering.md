# Example Engineering

## 职责

Example Engineering 只处理 Teaching Example / few-shot demonstration：

> **当抽象 instruction 不能稳定传递行为时，怎样设计最小、有效、可验证的示范。**

Example 不是所有 Prompt 的必需部分。

## 什么时候进入

只有出现以下任一情况时进入：

- 输出形状难以只靠 instruction 稳定表达；
- 条件边界容易混淆；
- 相邻概念容易误判；
- 工具选择或 trajectory 不稳定；
- failure / recovery 行为难以靠抽象规则传递；
- 用户明确要求用 Example / few-shot 教行为。

如果清晰 zero-shot 已经稳定，不需要 Example。

## 输入

至少需要：

- 要教的目标行为；
- 当前 instruction / Prompt；
- 关键条件和边界；
- 来源 Principle 或 Usage Case（如果有）；
- Example 最终放置位置；
- 可用于验证的独立 Case。

# 执行流程

```text
1. 判断 Example 是否真的需要
2. 指定唯一教学变量
3. 选择 Example 类型
4. 构造最小 Example
5. 删除偶然特征
6. 组成 Example Set
7. 放置到 Prompt / Skill
8. 独立 Evaluation
9. keep / revise / delete
```

## 1. 判断 Example 是否真的需要

先问：

> 当前 instruction 已经表达清楚了吗？模型真正缺的是示范，还是规则本身还没写好？

如果问题来自：

- 目标不清；
- 条件缺失；
- Prompt 冲突；
- Tool / Harness 缺能力；

不要用 Example 掩盖。

如果 instruction 清晰但行为仍不稳定，继续。

## 2. 指定唯一教学变量

每个 Example 先回答：

> 这一个 Example 到底要教模型哪一个新增行为信息？

例如：

- 某类输出格式；
- 某个边界条件；
- 某个工具选择；
- 某个合法 failure；
- 某个 decision trajectory。

不要一个 Example 同时塞进太多独立知识。

**进入下一步：** 能用一句话说清 Example 的教学目的。

## 3. 选择 Example 类型

按教学目的选最小类型：

### Demonstration

```text
input → desired observable output/action
```

用于格式、标签、常见决策或稳定输出形状。

### Boundary

```text
条件 A → 行为 A
关键条件改变 → 行为 B
```

用于教原则何时反转、减弱或停止。

### Contrastive

```text
情境
→ 表面合理但错误的处理
→ 错误机制
→ 更好的处理
```

Bad example 必须短且清晰标记。

### Decision

```text
observable conditions → decision → observable consequence
```

用于搜索、追问、工具选择、验证升级或停止。

### Trajectory / Tool-use

```text
initial state
→ action/tool
→ observation
→ next action
→ completion evidence
```

只示范必要可观察轨迹，不教学隐藏 chain-of-thought。

### Recovery / Failure

```text
failure condition
→ 禁止的猜测/假完成
→ 合法 fallback / non-complete state
```

## 4. 构造最小 Example

如果行为映射本来明确，可以直接从 requirement / principle 构造。

如果来自真实经验，必须先：

```text
Specific Case
→ abstract Principle
→ new Generic Teaching Example
```

不要把原案例删掉人名、路径、品牌就称为通用 Example。

构造时：

1. 保留真正改变决策的条件；
2. 换掉源 Case 的表面载体；
3. 删除无关步骤和背景；
4. 输出目标 Prompt/Skill 可以直接使用的最小示范。

Generic 的标准是**保留机制、改变表面载体**。

## 5. 删除偶然特征

模型会同时模仿：

- 语气；
- Markdown；
- 篇幅；
- 字段；
- 工具顺序；
- 是否解释；
- 是否创建额外产物。

逐项问：

> 这是我要教的吗？

不是就删除、简化或在 Example Set 中打散。

## 6. 组成 Example Set

当一个 Example 不够时，只加入提供独立信息的下一个 Example。

检查：

- **Relevance**：是否教当前行为；
- **Diversity**：是否改变真实决策条件，而不是只换名词；
- **Independence**：是否增加新信息；
- **Consistency**：是否与 instructions 或其他 Example 冲突。

三个只换文件名的例子通常没有三个例子的价值。

不规定固定 shot 数量。

## 7. 放置到 Prompt / Skill

按使用频率放置：

- 很短、几乎所有触发都需要 → 主 Prompt / `SKILL.md`；
- 长、低频、分支性 → 按需 reference / examples；
- 纯 Evaluation Case、一次事故原始记录、尚未证明教学价值 → 不进入生产 Guidance。

## 8. 独立 Evaluation

Teaching Example 是教材，不能同时作为唯一考试题。

至少使用独立 holdout；如果要证明底层原则可迁移，再做：

- boundary；
- cross-carrier；
- recovery / failure（相关时）。

验证方法见 [evaluation.md](evaluation.md)。

## 9. keep / revise / delete

根据 Evaluation：

```text
行为改善且没有明显副作用
→ keep

行为部分改善但出现新误导
→ 返回 Step 2 / 4 / 5 修正

没有独立改善
→ delete

删除后无可观察退化
→ 倾向 delete
```

Example 必须允许被删除。

# Example 设计记录

设计阶段可以临时维护：

```yaml
id: EXAMPLE-...
purpose: 唯一教学变量
type: demonstration | boundary | contrastive | decision | trajectory | recovery
input: 示例输入
desired_behavior: 可观察目标行为
critical_conditions:
  - 真正改变决策的条件
irrelevant_features:
  - 不希望被学习的偶然特征
boundary_partner: 可为空
forbidden_generalization:
  - 不能推出什么
source_principle: 可为空
source_case: 可为空
status: candidate | active | historical
```

最终投递给模型时只保留必要内容。

# 完成标准

Example Engineering 完成时：

- 已证明 Example 有存在理由；
- 每个 Example 有唯一主要教学变量；
- 类型与教学目的匹配；
- 没有把 Specific Case 直接伪装成 Generic Example；
- 偶然风格和无关特征已清理；
- Example Set 中每个成员提供独立信息；
- 放置位置与使用频率匹配；
- 已用独立 Case 验证；
- 有明确 keep / revise / delete 结论。

## 外部依据

核对日期：2026-10-01。

OpenAI 当前 Prompt Engineering 文档把 few-shot 定义为在 Prompt 中提供输入/期望输出示范，并建议 examples 覆盖多样输入。

https://developers.openai.com/api/docs/guides/prompt-engineering
