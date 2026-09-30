# Example Engineering

## 职责

Example Engineering 只处理**Teaching Example / few-shot demonstration**：

> **用具体示范塑造模型行为。**

真实事故、开发调试材料和测试题不是 Teaching Example。它们由 [evaluation/case-engineering.md](evaluation/case-engineering.md) 管理；只有经过选择和改写后，某个 case 才可能成为生产 Example。

## 默认：先 zero-shot

顺序固定为：

```text
清晰 instruction
→ 观察具体不稳定行为
→ 判断是否需要示范
→ 加入最小 Example set
→ 用独立 eval 验证
→ 保留 / 修改 / 删除
```

不为了“Prompt 应该有 few-shot”而加 Example。不同模型/版本对 few-shot 的收益不同，不规定固定数量。

## Example 类型

### Demonstration

```text
input → desired observable output/action
```

用于格式、标签、常见决策和稳定行为形状。

### Boundary

```text
条件 A → 行为 A
关键条件改变 → 行为 B
```

用于教会模型**什么时候规则应反转、减弱或停止适用**。

### Contrastive

```text
情境
→ 表面合理但错误的处理
→ 错误机制
→ 更好的处理
```

只在错误行为表面也很合理时使用。Bad example 必须明确标记，并尽量短，避免反向模仿。

### Decision

```text
observable conditions → decision → observable consequence
```

用于搜索、追问、工具选择、升级验证、停止等决策。展示可观察条件和动作，不教学不可验证的隐藏推理。

### Trajectory / Tool-use

```text
initial state
→ action/tool
→ observation
→ next action
→ completion evidence
```

只保留必要轨迹；不要把偶然工具名、等待时间或日志格式教成普遍规则。

### Recovery / Failure

```text
failure condition
→ 禁止的猜测/假完成
→ 合法 fallback / non-complete state
```

用于工具失败、证据不足、冲突或缺失信息。

## 从 Principle 生成 Generic Teaching Example

Teaching Example 的直接语义来源应该是**已经明确的 Principle Candidate**，而不是具体事故本身。

推荐链条：

```text
Specific Case
→ Mechanism
→ General Principle
→ Generic Teaching Example
```

Case Engineering 负责 Specific Case → Mechanism；Evolution 负责 Mechanism → General Principle；Example Engineering 只负责 **Principle → Teaching Example**。

这样做的目的，是阻断案例偶然细节进入长期教学资产。

### Generic 不等于“匿名化”

错误方法：

```text
原案例：移动 photo.jpg 时做了多余 SHA-256
→ 把 photo.jpg 改成 file.txt
→ 当作通用例
```

这仍然只是原案例的换皮。

正确方法是先得到原则：

```text
验证强度应由风险、可逆性和真实消费者决定
```

然后从原则重新构造一个新载体：

```text
低风险：把临时草稿复制到个人目录，无审计消费者
→ 最低充分确认

高风险边界：发布生产配置，需要审计与可恢复
→ 增加完整性与恢复证据
```

这里教的是原则的条件结构，而不是“文件移动”这个题材。

## 从 Principle 变成 Teaching Example

进入本文件前，应已经有一个 principle candidate。若手上只有具体事故，先回 [evaluation/case-engineering.md](evaluation/case-engineering.md) 抽 mechanism，再由 [evolution.md](evolution.md) 提炼原则。

从 Principle 生成 Example 时：

1. 指定原则中唯一要教学的决策关系；
2. 主动选择与源案例不同的中性或替代载体；
3. 保留 `applies_when / action / boundary` 的结构；
4. 对条件性原则优先生成 boundary pair；
5. 删除不影响原则的风格、字段和步骤；
6. 渲染成目标 Prompt/Skill 能直接使用的最小示范。

Example 不保存完整事故史，也不承担“证明原则正确”的职责。

## Example 设计记录

设计阶段可记录：

```yaml
id: EXAMPLE-...
purpose: 唯一主要教学变量
type: demonstration | boundary | contrastive | decision | trajectory | recovery
input: 示例输入
desired_behavior: 可观察目标行为
critical_conditions:
  - 真正改变决策的条件
irrelevant_features:
  - 不希望被学习的偶然特征
boundary_partner: 可为空
forbidden_generalization:
  - 不能从此例推出什么
source_principle: PRINCIPLE-...
source_case: 仅用于追溯证据，可为空
status: candidate | active | historical
```

这是作者记录，不要求全部发送给模型。

## Example Set 的质量

只看四件事：

- **Relevance**：是否真的教当前行为。
- **Diversity**：是否覆盖不同**决策条件**，而不只是换名词。
- **Independence**：每个 Example 是否增加新的行为信息。
- **Consistency**：Examples 与 instructions、彼此之间是否冲突。

三个只换文件名的 examples，行为信息通常仍接近一个。

## 防止无意教学

模型会同时模仿语义与表面特征。检查每个 Example 中的：

- 语气；
- Markdown 结构；
- 篇幅；
- 字段；
- 工具顺序；
- 是否解释；
- 是否创建额外产物。

不是教学目标的特征，应删除、简化或在 Example set 中打散。

Bad/good 对照、标准答案和 grader 规则要有清晰边界，避免把评估答案泄漏给生产模型。

## 放置

### 放主 Prompt / SKILL.md

仅当 Example 很短、几乎所有任务都需要，而且不能由更短 instruction 等价替代。

### 放按需 reference

当 Example 较长、只服务某分支、属于少见边界或需要从多个示范中选择。

### 不进入生产 Guidance

当它只是：

- eval case；
- 一次事故记录；
- 尚未证明有迁移价值的候选；
- 无法安全抽象的敏感/项目专有材料；
- 与当前 instruction 冲突的历史示范。

## 验证与删除

Teaching Example 的测试方法归 [evaluation.md](evaluation.md) 所有。

至少需要独立 holdout，而不是拿教材本身当唯一考题。若要证明学到的是底层机制，可由 Evaluation 设计 boundary 或 cross-carrier case。

Examples 必须允许被删除。新增 Example 没有独立收益，或删掉后无可观察退化，就应倾向移除。

## 外部依据

核对日期：2026-10-01。

- OpenAI Prompt Engineering：few-shot 通过输入/期望输出 examples 引导模型，并建议覆盖多样输入。  
  https://developers.openai.com/api/docs/guides/prompt-engineering
- OpenAI Reasoning Best Practices：reasoning models 先尝试 zero-shot，复杂要求再加入 closely aligned few-shot examples。  
  https://developers.openai.com/api/docs/guides/reasoning-best-practices

其余关于 boundary pairing、forbidden generalization、独立 holdout 与删除测试，是本项目基于这些原则和自身 Evaluation 体系形成的工程综合，不冒充官方标准。
