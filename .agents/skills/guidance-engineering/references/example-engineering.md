# Example Engineering

## 职责

Example Engineering 只处理 Teaching Example / few-shot demonstration：

> **当抽象 instruction 不能充分传递某个行为时，怎样设计最小、清晰、可复用的示范。**

Example 不是所有 Prompt 的必需部分，也不要求在创建时先经过独立 Evaluation 才能存在。

## 什么时候进入

只有出现以下任一情况时进入：

- 输出形状难以只靠 instruction 表达；
- 条件边界容易混淆；
- 相邻概念容易误判；
- 工具选择或 trajectory 需要示范；
- failure / recovery 行为难以靠抽象规则传递；
- 用户明确要求用 Example / few-shot 教行为。

如果清晰 zero-shot 已经足够，不需要 Example。

## 输入

至少需要：

- 要教的目标行为；
- 当前 instruction / Prompt；
- 关键条件和边界；
- 来源 Principle 或 Case（如果有）；
- Example 最终放置位置。

没有真实 Case 时也可以从明确 requirement / principle 直接设计 Example，不需要为了 Example 创建而凭空制造 Evaluation Case。

# 执行流程

```text
1. 判断 Example 是否真的需要
2. 指定唯一教学变量
3. 选择 Example 类型
4. 构造最小 Example
5. 删除偶然特征
6. 组成 Example Set
7. 放置到 Prompt / Skill
8. 进入真实使用
9. 后续根据反馈 keep / revise / delete
```

## 1. 判断 Example 是否真的需要

先问：

> 当前 instruction 已经表达清楚了吗？模型真正缺的是示范，还是规则本身没写好？

如果问题来自：

- 目标不清；
- 条件缺失；
- Prompt 冲突；
- Tool / Harness 缺能力；

不要用 Example 掩盖。

## 2. 指定唯一教学变量

每个 Example 先回答：

> 这个 Example 到底要教哪一个新增行为信息？

例如：

- 某类输出格式；
- 某个边界条件；
- 某个工具选择；
- 某个合法 failure；
- 某个 decision trajectory。

不要一个 Example 同时塞进太多独立知识。

## 3. 选择 Example 类型

按教学目的选最小类型。

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
→ 禁止的猜测 / 假完成
→ 合法 fallback / non-complete state
```

## 4. 构造最小 Example

如果行为映射本来就明确，可以直接从 requirement / principle 构造。

如果来源是真实经验：

```text
Specific Case
→ abstract Principle / decision relation
→ new Generic Teaching Example
```

不要把原案例删掉人名、路径、品牌就称为“通用 Example”。

构造时：

1. 保留真正改变决策的条件；
2. 换掉源 Case 的表面载体；
3. 删除无关背景和偶然步骤；
4. 只保留目标 Prompt / Skill 真正需要的示范内容。

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
- 一次事故原始记录 → 留在 Case，不直接作为 Example；
- 纯测试材料 → 不进入生产 Guidance。

## 8. 进入真实使用

Example 形成后，先让它进入真实 Prompt / Skill 使用。

```text
Example
→ Real Use
→ outcome / user correction / boundary
→ Case
→ 如果属于已有 Skill，则进入 Skill Evolution
```

真实使用天然会暴露：

- 是否真的有教学价值；
- 是否造成错误模仿；
- 是否只是在重复 instruction；
- 是否让模型过拟合表面格式；
- 是否需要边界 Example。

## 9. 后续 keep / revise / delete

后续根据真实使用和 Evolution 决定。

```text
真实使用显示 Example 有持续价值
→ keep

出现错误泛化 / 偶然风格模仿
→ revise

长期没有独立价值或删除后无明显退化
→ delete
```

如果变化是否正确存在实质不确定性，由 [skill-evolution.md](skill-evolution.md) 决定是否调用 [evaluation.md](evaluation.md)。

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

Example Engineering 创建阶段完成时：

- Example 确实提供 instruction 之外的新增信息；
- 每个 Example 有唯一主要教学变量；
- 类型与教学目的匹配；
- Specific Case 没有被直接伪装成 Generic Example；
- 偶然风格和无关特征已清理；
- Example Set 中每个成员提供独立信息；
- 放置位置与使用频率匹配；
- Example 已达到可以进入真实使用的状态。

**不要求：**

- 创建 Example 时必须先有独立 holdout；
- 创建 Example 时必须强制 Evaluation；
- 没有真实材料时凭空制造测试集。

Example 的长期价值由真实使用和后续 Skill Evolution 继续检验。

## 外部依据

核对日期：2026-10-01。

OpenAI 当前 Prompt Engineering 文档把 few-shot 定义为在 Prompt 中提供输入/期望输出示范，并建议 examples 覆盖多样输入。

https://developers.openai.com/api/docs/guides/prompt-engineering
