# Example Engineering

## 定位

Example Engineering 负责设计**用于塑造模型行为的示范资产**。

Example 不是“给模型看一个答案”这么简单。它把抽象 instruction 映射为具体的输入、决策、动作和输出，因此会向模型同时传递：

- 什么特征值得关注；
- 什么条件会改变决策；
- 应该采取什么动作；
- 什么输出形状是可接受的；
- 什么行为边界不能越过；
- 哪些风格、顺序和细节可能被模仿。

因此 Example 的行为影响可能强于同长度的解释性文字。

本文档处理 teaching examples / few-shot demonstrations。用于评估的 cases 属于 Evaluation；真实事故和运行记录可以成为 Example 原料，但不会自动获得教学权。

## 基本原则：先 zero-shot，再证明 Example 有价值

不要为了“Prompt Engineering 应该有 few-shot”而加入 examples。

默认顺序：

```text
清晰 instruction
→ 运行 / 观察
→ 找到具体不稳定行为
→ 判断 Example 是否是合适干预
→ 加入最小 Example set
→ 用留出 eval 验证
→ 保留 / 修改 / 删除
```

当前 OpenAI reasoning guidance 明确建议先尝试 zero-shot，在复杂要求确实需要时再加入少量输入/期望输出 examples。OpenAI Prompt Engineering 文档同时建议 few-shot examples 覆盖多样输入；Anthropic 当前 prompting guidance 也强调 relevant、diverse、structured。这里把这些作为成熟外部依据，但**不把任何固定 example 数量写成跨模型硬规则**。

## Example 与 Case / Eval 的区别

### Teaching Example

目的：改变模型行为。

它进入生产 Prompt、Skill 或按需 reference，模型会看到它。

### Development Case

目的：帮助理解失败、设计规则或构造候选 example。

它可以来源于真实事故、用户纠正、review 或 synthetic case，不一定进入生产上下文。

### Eval Case

目的：测量行为。

它应尽量与 teaching examples 隔离。测试对象不应提前看到评估意图、期望答案或留出 case。

关系可以是：

```text
真实事件 / Development Case
        ↓ 抽象
候选 Teaching Example
        ↓
生产 Guidance
        ↓
Holdout / Boundary / Cross-carrier Eval
```

不要直接把同一个样本从“教材”复制成唯一“考试题”。

## Example 的六种主要类型

类型不是为了分类漂亮，而是帮助选择最小干预。

### 1. Demonstration Example

结构：

```text
input
→ desired observable output / action
```

适合：

- 输出格式；
- 标签映射；
- 稳定语气；
- 常见决策；
- 规则很清楚，但需要展示具体行为形状。

这是默认类型。

### 2. Boundary Example

展示**同一规则在条件变化后应该反转、减弱或停止适用**。

结构：

```text
Case A: 条件 X
→ 行为 A

Case B: 关键条件改变
→ 行为 B
```

它的价值是阻止模型把局部规则绝对化。

例如：

```text
低风险文件移动、无审计消费者
→ 移动并做最低必要确认

生产数据库迁移、明确要求可恢复
→ 备份、完整性校验、恢复证据
```

这里真正要教的不是“少验证”或“多验证”，而是**验证强度由风险和消费者决定**。

### 3. Contrastive Example

用于“错误行为表面也很合理”的情况。

结构：

```text
情境
→ 表面合理但错误的处理
→ 错误机制
→ 更好的处理
→ 可迁移区别
```

Bad example 必须明确标记，不要让模型猜哪个是反例。

错误部分应尽量短，只保留需要区分的竞争行为；不要把一大段高质量错误输出塞进上下文，增加模仿风险。

### 4. Decision Example

重点不是最终文字，而是**在什么事实下选择哪一类动作**。

结构：

```text
observable conditions
→ decision
→ observable consequence
```

适合：

- 是否搜索；
- 是否追问；
- 是否使用工具；
- 是否升级验证；
- 是否停止；
- 是否进入另一个 workflow。

不要把不可验证的隐藏推理过程当成教学目标。需要展示的是决策条件和可观察动作。

### 5. Trajectory / Tool-use Example

用于 Agent 工具使用或多步骤任务。

结构：

```text
initial state
→ tool/action 1
→ observation
→ tool/action 2
→ completion evidence
```

只展示**必要的可观察轨迹**。

不要把一次实现里的偶然工具名、参数、等待时间或日志格式误教成通用流程。若底层工具可替换，example 应强调选择条件和后置证据。

### 6. Recovery / Failure Example

用于教模型在缺失、冲突、工具失败或证据不足时怎样合法退出。

结构：

```text
failure condition
→ 不允许的猜测 / 假完成
→ 合法 fallback / non-complete state
```

它尤其适合防止：

- 编造工具结果；
- 把部分成功报告成完成；
- 无限重试；
- 无依据扩大权限；
- 用臆测填补缺失事实。

## 从真实实践提炼 Example

真实失败通常比凭空编造的例子更有价值，但不能直接复制。

使用以下过程：

### 1. 保留原始事实

先单独保存：

- 用户原始目标；
- 当时上下文；
- 实际输出 / tool trace；
- 可观察失败；
- 用户纠正；
- 当前能确认和不能确认的事实。

### 2. 找到唯一主要机制

问：

> 如果把品牌、文件名、领域对象和偶然参数全部换掉，这次失败还剩下什么？

可能的机制包括：

- 规则被绝对化；
- 目标被材料替换；
- 工具成功冒充业务完成；
- 不该追问时反复追问；
- 缺失事实被猜测；
- 子任务吞掉主目标；
- 示例的表面格式覆盖了真正语义。

一个 canonical example 最好只承担一个主要教学目标。

### 3. 去除偶然特征

删除或替换：

- 项目专名；
- 用户身份；
- 品牌；
- 无关日期；
- 一次性路径；
- 偶然工具参数；
- 与目标机制无关的写作风格。

但不要删除会真正改变决策的：

- 权限；
- 风险；
- 可逆性；
- 阶段；
- 消费者；
- 已有证据；
- 完成条件。

### 4. 设计边界配对

如果 example 教的是条件规则，尽量同时构造一个条件翻转的 partner。

没有边界配对时，模型很容易学到：

```text
某动作 = 总是好
```

而不是：

```text
条件 X → 动作 A
条件 Y → 动作 B
```

### 5. 写 forbidden generalization

在设计阶段明确记录：

> 这个 example **不能被推广成什么**？

例如：

```text
教学目标：
低风险任务不要自动加无消费者的审计产物。

禁止泛化：
所有任务都不需要审计、哈希或备份。
```

这个字段主要用于作者和 eval，不一定进入最终 Prompt。

## 一个高质量 Example 的最小结构

内部设计时可以使用：

```yaml
id: EXAMPLE-...
purpose: 只教哪一个主要行为变量
type: demonstration | boundary | contrastive | decision | trajectory | recovery
input: 可实际送达模型的输入
desired_behavior: 可观察的目标行为
desired_output: 只有输出形状重要时填写
critical_conditions:
  - 真正改变决策的条件
irrelevant_features:
  - 不希望模型学习的偶然特征
boundary_partner: 对应边界 example，可为空
forbidden_generalization:
  - 不能从此例推出的规则
source: synthetic | real-observation-derived | external
status: candidate | active | historical
```

这是一份**设计记录格式**，不是要求把 YAML 全部送给目标模型。

最终投递给模型的 example 应只保留必要部分。

## Example Set：不要只优化单个例子

单个 example 可能很好，但 example set 仍可能整体有偏。

检查至少四个维度：

### Relevance

examples 是否真的覆盖当前行为，而不是“题材相似”。

### Diversity

改变会影响决策的条件：

- 简单 / 复杂；
- 低风险 / 高风险；
- 信息完整 / 缺失；
- 允许动作 / 禁止动作；
- 工具成功 / 失败；
- 普通 case / 边界 case。

多样性不是换几个名词，而是改变**决策维度**。

### Independence

每个 example 是否提供新的行为信息？

三个只换了文件名的 example ≈ 一个 example。

### Consistency

所有 examples 与 instruction、彼此之间是否一致？

若两个 example 对同一条件给出不同动作，先解决冲突，不要期待模型自己推断作者真正意图。

## Example 数量

不规定固定数量。

数量由**边界覆盖增益 / 上下文成本**决定。

原则：

1. zero-shot 已稳定 → 0 个；
2. 一个 example 能解决 → 不加第二个；
3. 新 example 只有在覆盖新的决策边界时才加入；
4. 当 examples 增多时，用 ablation 判断哪些可以删除；
5. 供应商文档中的推荐数量只能作为特定模型/场景经验，不升格为跨模型硬规则。

## 排列与结构化

Examples 必须和 instructions、context、task data 有清晰边界。

可以使用：

- Markdown headings；
- XML tags；
- YAML-like blocks；
- 明确的 input/output 对。

关键不是某一种标记法，而是：

- 模型能识别“这是 example”；
- example 的输入和期望行为不会和当前真实任务混淆；
- bad/good 对照不会混淆；
- 多个 example 的边界清楚；
- 使用目标平台当前支持且表现稳定的消息角色与结构。

Example 的顺序也是变量。若模型明显偏向最后一个 example，说明 example set 或 instruction 可能依赖位置，应在 eval 中换序检查。

## 防止 Style Leakage

模型不仅学习语义，也会学习：

- 句子长度；
- Markdown 习惯；
- 语气；
- 字段；
- 工具顺序；
- 是否解释；
- 是否先道歉；
- 是否创建额外产物。

所以设计 example 时逐项问：

> 这个特征是我要教的吗？

不是，就尽量去除或在不同 examples 中打散。

否则你以为在教“边界判断”，模型可能同时学会“每次都输出五个标题”。

## 防止 Label / Answer Leakage

如果当前任务中存在标准答案、grader 规则或 eval case：

- 不把留出答案写入 teaching example；
- 不把评估意图暴露给被测模型；
- 不用与 teaching example 仅换几个名词的近重复 case 声称泛化；
- grader prompt 与生产 prompt 分离。

## Cross-carrier Generalization

如果要教的是底层机制，eval 应换载体。

例如 teaching example：

```text
配置文件修改成功
≠
服务已经按新配置运行
```

留出测试可以换成：

- 数据迁移；
- API consumer；
- 文件同步；
- 部署状态；
- 任务队列；
- 浏览器自动化。

只有换题材、换表面形式后仍然遵守同一机制，才更像真正学到了规则。

## Ablation：Example 必须允许被删除

Example 不是永久资产。

当 example set 变大时，比较：

```text
baseline
vs
instructions only
vs
instructions + example A
vs
instructions + example A+B
vs
minimal surviving example set
```

关注：

- 目标行为是否改善；
- 边界是否退化；
- 是否产生新的模仿副作用；
- token / latency 成本；
- 是否只在原题材上有效。

如果删除某个 example 后没有可观察退化，应倾向删除。

## Example 与 Skill 的放置

在 Skill 中：

### 放主 SKILL.md

只有当 example：

- 很短；
- 几乎所有触发都需要；
- 不看它容易稳定犯同一种错误；
- 它提供的行为信息无法用更短 instruction 等价替代。

### 放 reference

当 example：

- 只服务某个分支；
- 较长；
- 数量多；
- 属于少见边界；
- 需要按任务类型选择。

### 不放生产 Skill

当它：

- 只是 eval case；
- 只记录一次事故；
- 还没有证明有迁移价值；
- 包含敏感/项目专有内容且无法安全抽象；
- 与当前 instruction 冲突。

## Example 与 Evaluation 的最小闭环

每次新增重要 example，至少问：

```text
为什么加？
→ baseline 观察到了什么？

它教什么？
→ 唯一主要行为变量是什么？

如何证明有效？
→ 哪个 holdout case 会改变？

如何证明没过拟合？
→ 哪个 boundary / cross-carrier case？

如何证明值得保留？
→ ablation 删除后会发生什么？
```

无法回答这些问题时，example 只能算候选，不应轻易进入长期 Guidance。

## 常见失败模式

- **Example stuffing**：用更多例子掩盖没有明确行为契约。
- **Surface diversity**：只换名词，不改变决策条件。
- **Style contamination**：无意把格式、语气、篇幅教成硬模式。
- **Boundary collapse**：只有正例，没有条件反转。
- **Bad-example imitation**：反例过长或标记不清，模型反而模仿错误。
- **Teaching-test leakage**：教材和考试题几乎相同。
- **Incident fossilization**：把一次事故的偶然细节永久固化。
- **Example supremacy**：example 与 instruction 冲突时继续堆 example，而不修语义冲突。
- **No ablation**：examples 只增不减，最终上下文越来越重。

## 外部依据与适用范围

核对日期：2026-10-01。

- OpenAI Prompt Engineering：把 Examples 作为 prompt 的常见组成，并建议 few-shot 展示多样输入与期望输出。  
  https://developers.openai.com/api/docs/guides/prompt-engineering
- OpenAI Reasoning Best Practices：对 reasoning models 建议先 zero-shot，复杂要求再加入 closely aligned few-shot examples。  
  https://developers.openai.com/api/docs/guides/reasoning-best-practices
- Anthropic Prompting Best Practices：强调 examples 的 relevant、diverse、structured，并给出其当前模型上的 multishot 经验。  
  https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/prompt-templates-and-variables

以上属于外部成熟指导。本文关于 boundary pairing、forbidden generalization、cross-carrier eval、ablation 和 Skill 放置规则，是基于这些原则与本项目现有 Guidance/Evaluation 体系形成的工程综合，**不冒充单一厂商官方标准**。
