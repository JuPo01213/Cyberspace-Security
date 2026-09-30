# Example Engineering

## 职责

Example Engineering 只处理**Teaching Example / few-shot demonstration**：

> **用具体示范给模型增加抽象 instruction 没有充分传递的行为信息。**

它不是所有 Prompt 的必需部分。

## Example 有两条来源路径

### 路径 A：直接设计

当行为映射本来就明确，例如：

- 输出格式；
- 分类标签；
- 固定 schema；
- 已知边界；
- 已知工具调用形状；

可以直接从已知 requirement / principle 设计 Example，不需要先经历真实事故。

### 路径 B：从真实经验固化

当 Example 来自具体失败或用户纠正时，必须经过：

```text
Specific Case
→ Mechanism Candidate
→ General Principle Candidate
→ Generic Teaching Example
```

不能把原案例删掉人名、路径或品牌后就称为“通用 Example”。

从真实 Case 到可迁移 Principle 的抽象统一见 [cases.md](cases.md)。

## 默认先 zero-shot

```text
清晰 instruction
→ 观察具体不稳定行为
→ 判断 Example 是否增加新信息
→ 加入最小 Example set
→ 独立 eval
→ 保留 / 修改 / 删除
```

不规定固定 shot 数量。0 个 Example 也完全可能是最佳 Prompt。

## Example 类型

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

教模型什么时候原则应反转、减弱或停止。

### Contrastive

```text
情境
→ 表面合理但错误的处理
→ 错误机制
→ 更好的处理
```

Bad example 必须清晰标记，并尽量短。

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

用于工具失败、冲突和证据不足。

## 从 Principle 构造 Generic Teaching Example

如果来源是具体经验：

1. 指定原则中唯一主要教学变量；
2. 主动换掉源案例的题材/载体；
3. 保留真正改变决策的条件；
4. 条件性原则优先生成 boundary pair；
5. 删除无关风格、字段、工具和偶然步骤；
6. 输出目标 Prompt/Skill 可以直接使用的最小示范。

Generic 的标准是**保留机制、改变表面载体**，不是匿名化。

## Example 设计记录

设计阶段可以维护：

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

## Example Set

检查四件事：

- **Relevance**：是否教当前行为；
- **Diversity**：是否改变真实决策条件，而不是只换名词；
- **Independence**：每个 Example 是否增加新信息；
- **Consistency**：Examples 与 Instructions、彼此之间是否冲突。

三个只换文件名的例子通常没有三个例子的价值。

## 防止无意教学

模型会同时模仿：

- 语气；
- Markdown；
- 篇幅；
- 字段；
- 工具顺序；
- 是否解释；
- 是否创建额外产物。

逐项问：

> 这个特征是我要教的吗？

不是，就删除、简化或在 Example set 中打散。

## Teaching 与 Testing 分离

Teaching Example 是教材。

Usage / Eval Case 统一由 [cases.md](cases.md) 管理。

不能用：

```text
教 Example A
→ 测 A 或近重复 A
→ 宣布原则泛化
```

至少要有独立 holdout。要证明底层原则可迁移，再做 boundary / cross-carrier 测试。

## 放置

### 主 Prompt / SKILL.md

只有很短、几乎所有触发都需要、且无法被更短 instruction 替代的 Example 才常驻。

### 按需 reference

分支性、较长、数量较多或低频边界 Example 下沉。

### 不进入生产 Guidance

- 纯 eval case；
- 一次事故原始记录；
- 尚未证明有教学价值；
- 无法安全抽象的敏感内容；
- 与当前 instruction 冲突的旧示范。

## 验证与删除

Example 必须允许被删除。

如果新增 Example 没带来独立改善，或删掉后没有可观察退化，就倾向移除。

验证方法归 [evaluation.md](evaluation.md)。

## 外部依据

核对日期：2026-10-01。

OpenAI 当前 Prompt Engineering 文档把 few-shot 定义为在 Prompt 中提供输入/期望输出示范，并建议 examples 覆盖多样输入。

https://developers.openai.com/api/docs/guides/prompt-engineering
