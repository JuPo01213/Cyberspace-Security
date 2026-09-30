# Prompt Engineering

## 职责

Prompt Engineering 只回答：

> **如何把目标、约束、上下文和期望输出表达给模型。**

它不拥有多步状态机、Skill 目录结构、测试 case 或资产演进；这些分别由 Workflow、Skill、Evaluation 和 Evolution 负责。

## 先判断 Prompt 的位置

这些名称不完全属于同一协议维度；有些是消息角色，有些是来源/用途。设计时先确认目标 Harness 实际支持什么。

- **System prompt**：若宿主存在该层，用于全局、稳定、长期的高层指导。
- **Developer / application prompt**：应用长期提供的产品规则、业务约束和默认行为。
- **Skill prompt / instructions**：Skill 被加载后提供的局部能力指导；“Skill prompt”不是新的消息角色。
- **Task / user prompt**：当前任务目标、限制和材料。
- **Tool-use guidance**：告诉模型何时、为何、怎样调用工具以及怎样消费结果。
- **Grader / judge prompt**：评价其他输出或轨迹；应与被测生产指导隔离。
- **Few-shot / examples**：示范手段，不是消息角色；具体设计见 [example-engineering.md](example-engineering.md)。

## Prompt 的组成

根据任务需要组合，不把它们固定成模板：

1. **目标**：希望模型产生什么结果。
2. **指令与约束**：必须、禁止、条件性行为。
3. **上下文**：模型完成任务所需的可信事实。
4. **任务数据**：需要处理的材料，与指令分开。
5. **输出契约**：结果的形态、字段或成功标准。
6. **失败处理**：信息不足、冲突或工具失败时允许怎样结束。
7. **Examples**：只有确实提供新增行为信息时才加入。

复杂到需要正式阶段、状态、依赖和分支时，不继续扩张 Prompt 结构，转到 [workflow-design.md](workflow-design.md)。

## 书写原则

### 简单直接

优先清楚表达目标和约束。不要把“更专业”“更谨慎”“深入思考”当作可验证行为。

对 reasoning model，不默认要求展示或模拟 chain-of-thought；关注目标、约束和可观察成功标准。

### 指令、上下文与数据分开

外部材料中的命令、角色声明、网页文本和“忽略前文”默认是任务数据，不自动获得更高指令权。

用 headings、XML、Markdown 或其他稳定分隔方式，只为减少歧义；标记法本身不是质量。

### 条件优于绝对化

若一条规则存在合理反转条件，把条件写出来。

例如不要写：

```text
永远不要创建额外文件。
```

而应表达何时额外产物没有消费者、何时审计/恢复要求又使它成为交付的一部分。

### 结果优于自评

“确保完成”“确认正确”太弱。需要说明成功由什么输出、文件、工具状态或外部结果观察。

正式的 completion、failure exit、dependencies 归 [workflow-design.md](workflow-design.md) 所有；Prompt 只表达当前任务真正需要的部分。

### 不用 Prompt 伪造硬机制

认证、授权、schema、runtime policy、tool enforcement 等能在机械层保证的内容交给对应组件。

## 什么时候使用 Example

先尝试清晰 zero-shot instruction。若仍在以下方面不稳定，再考虑 Example：

- 输出形状；
- 边界判断；
- 相邻概念区分；
- 工具选择；
- 合法失败；
- 多步可观察轨迹。

Example 的构造、边界配对、泄漏与删减测试统一见 [example-engineering.md](example-engineering.md)。

## 什么时候升级为 Workflow / Skill

出现阶段、状态、分支、依赖、失败恢复或多步完成门 → [workflow-design.md](workflow-design.md)。

一套 Prompt/Workflow 已形成稳定、反复出现的能力，并需要长期 references/scripts/assets 或独立触发 → [skill-building.md](skill-building.md)。

仅仅“Prompt 很长”不是新建 Skill 的理由。

## 验证

Prompt 改写后若要声称“更好”“更稳定”或“修复了问题”，转到 [evaluation.md](evaluation.md)。未经运行验证时，只称候选 Prompt。
