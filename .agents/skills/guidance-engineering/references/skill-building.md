# Skill Construction

## 职责

Skill Construction 只回答：

> **怎样从已有 Source 中理解真实行为、抽象可迁移能力，并把它封装成一个可独立使用和继续演化的 Skill。**

这里的 Source 可以是：

- 用户对新能力的明确 requirement；
- 正在进行的真实工作上下文；
- 已完成工作的对话、日志、文件变化、Git history 或最终产物；
- 一个或多个已有 Case；
- 用户提供的规则、流程、Prompt、Examples 或其他材料。

这些只是**来源不同**，不应为每种来源发明一套不同的 Skill 创建算法。

统一主链：

```text
Source
→ Understand
→ Abstract
→ Capability
→ Guidance
→ Package as Skill
→ Real Use
→ Evolution
```

用户明确要求“创建一个 Skill”时，创建决定已经成立。调研和分析用于提高质量，不用于重新否决用户的创建决定。

# 第一原则：先理解 Source，不要先写 Skill

Source 不是 Skill。

尤其当 Source 是一段真实工作记录时，不要：

```text
对话
→ 摘要
→ SKILL.md
```

而应：

```text
工作记录
→ 重建真实目标与行为轨迹
→ 找出真正改变结果的决策关系
→ 去掉偶然细节
→ 定义 Capability
→ Skill
```

“总结发生了什么”和“提取可复用能力”是两件不同的事。

# 执行流程

```text
1. 确定 Source 与范围
2. Understand：理解或重建真实工作
3. Abstract：提取可迁移决策关系
4. 定义 Capability Contract
5. 调研成熟做法并校准
6. 设计 Guidance
7. 初始化 Skill repository 并封装
8. 保存必要来源证据
9. 自包含与结构检查
10. 初始 commit
11. 进入真实使用
```

除非缺失事实会让能力根本无法定义、造成明显权限/安全错误，或者用户明确要求先确认，否则不要在步骤间反复追问。

## 1. 确定 Source 与范围

先回答：

```text
Source 是什么？
要从其中构建哪个能力？
哪些内容属于本次工作范围？
```

### Source 是明确 requirement

直接读取：

- Goal；
- Trigger；
- Constraints；
- Expected result；
- 已知工具与环境；
- 用户明确要求的行为。

### Source 是当前或历史工作记录

先确定需要回顾的工作范围。

如果当前上下文已经足够明确，不要求用户重新总结。

可以使用：

- 对话；
- 工具调用；
- 文件内容和 diff；
- Git history；
- 用户纠正；
- 中间失败；
- 最终产物；
- completion evidence。

**进入下一步：** 已知道自己在解释哪一段真实材料，而不是对整个历史做无边界总结。

## 2. Understand：理解或重建真实工作

这一步的目标不是抽象规则，而是先恢复 Source 的真实结构。

### requirement 型 Source

解析：

```text
Goal
Constraints
Inputs
Expected behavior
Completion
Failure / uncertainty
Environment
```

### 工作记录型 Source

重建最小工作轨迹：

```text
Goal
→ Initial approach
→ Observations
→ Failures / friction
→ User corrections
→ Tool / method changes
→ Key decisions
→ Successful path
→ Completion
```

重点寻找**方向为什么发生变化**：

- 哪个观察使旧做法被放弃；
- 哪个用户纠正改变了行为；
- 哪个工具结果改变了下一步；
- 哪些做法看似合理但实际无效；
- 最终为什么认为任务完成。

不要把对话顺序机械复制成 Workflow。

**进入下一步：** 已能解释“这件工作实际上是怎么被做成的”。

## 3. Abstract：提取可迁移决策关系

把重建结果分成三类：

```text
Facts
= 实际发生了什么

Local details
= 项目名、品牌、文件名、一次性环境等偶然信息

Transferable relations
= 换掉表面对象后仍决定行为的关系
```

抽象的目标不是“去掉专有名词”，而是提取决策函数：

```text
conditions / observations
→ decision
→ action
→ completion / stop
```

反事实检查：

> 如果把当前项目名、工具名、品牌、题材全部替换，这条关系仍然成立吗？

如果不成立，它大概率仍是局部细节。

例如：

```text
“用了 GSAP”
≠ 可迁移能力

“成熟生态已经存在时，先发现并吸收成熟 workflow / implementation；
只有现有能力不能满足约束时，才进入自定义实现”
= 可迁移决策关系
```

不要从单个失败直接制造 universal rule。

**进入下一步：** 已得到一组真正会改变未来行为的可迁移关系。

## 4. 定义 Capability Contract

把抽象关系组织成能力，而不是直接堆进 Prompt。

最小 Capability Contract：

```text
Goal
→ 这个能力最终帮助完成什么

Trigger
→ 什么条件下应该使用

Non-trigger
→ 哪些相邻请求不属于它

Inputs / observations
→ 做决定需要看到什么

Required decisions / behavior
→ 哪些判断和动作必须发生

Workflow
→ 只有依赖阶段、状态或前序结果时才建立

Completion
→ 什么可观察结果才算完成

Failure / uncertainty
→ 信息不足、工具失败或条件不满足时怎样合法退出

Environment boundary
→ 哪些能力来自 Harness / Tool / Runtime
```

如果重建出的内容实际上包含多个独立能力，先判断：

- 是否共享同一用户目标；
- 是否经常共同触发；
- 是否共同维护；
- 拆开是否降低误触发和上下文污染。

默认聚合自然属于同一能力的内容，不因为原对话里出现多个步骤就机械拆成多个 Skill。

## 5. 调研成熟做法并校准

现在才拿抽象出来的 Capability 去对照成熟生态。

优先检查：

- 当前官方文档与平台限制；
- 成熟 workflow / Skill / tool / library；
- 当前项目已有实现；
- 用户提供的参考材料。

调研用于：

- 修正错误假设；
- 吸收成熟工作顺序；
- 发现可复用工具、schema、script；
- 明确平台边界；
- 避免把一次偶然成功误当成通用最佳实践。

不要让外部资料抹掉真实工作里已经被证明关键的约束；也不要把自己的综合伪装成“官方成熟做法”。

## 6. 设计 Guidance

根据 Capability 决定需要哪些表达形式：

```text
Principle
= 条件 → 行为 → 边界

Workflow
= 阶段 / 状态 / 转移 / completion / stop

Prompt
= 把 Guidance 表达给模型

Example
= 当示范能提供独立行为信息时使用

Script / schema
= 可机械保证、重复执行的确定性部分
```

具体 Prompt 见 [prompt-engineering.md](prompt-engineering.md)。

具体 Example 见 [example-engineering.md](example-engineering.md)。

不要为了形式完整让每个 Skill 都同时拥有 Principle、Workflow、Prompt、Example、Script。

## 7. 初始化 Skill repository 并封装

每个 Skill 文件夹应当是自己的本地 Git repository。

```bash
python scripts/init_skill.py <name> --path <parent>
```

或：

```bash
mkdir <skill-name>
cd <skill-name>
git init
```

Remote 可选。

按需组织：

```text
skill/
├── .git/
├── SKILL.md
├── references/
├── examples/
├── cases/
├── scripts/
└── assets/
```

不要为了目录完整性创建无消费者的文件。

### SKILL.md 至少应让 Agent 知道

- 这个能力何时触发；
- 目标和边界；
- 主要行为；
- 必要 Workflow；
- supporting resources 的读取条件；
- completion / failure；
- Harness / Tool 边界。

只读取 `SKILL.md` 时，Agent 应能执行主要路径，或知道什么时候读取下一层资源。

## 8. 保存必要来源证据

Skill 保存**压缩后的能力**。

Case 保存**这个能力从哪里来的重要经验**。

当 Source 是真实工作记录，而且其中存在值得未来追溯的决策、纠正或结果时，可以同时保存 Replay Case：

```text
                    ┌→ Skill
Work Reconstruction ┤
                    └→ Replay Case
```

不要把流程写成：

```text
Conversation
→ Replay Case
→ Skill
```

Replay Case 不是能力建模的必经中间产物。

它只是来源证据，具体记录方式见 [cases.md](cases.md)。

如果 Source 只是明确 requirement、没有真实历史经验，不要求凭空创建 Replay Case。

## 9. 自包含与结构检查

创建阶段只做足以保证初始 Skill 可理解、可运行的检查：

- front matter 与基本结构合法；
- description 能支持 discovery；
- `SKILL.md` 能独立表达能力；
- supporting resources 有明确消费者；
- 不依赖作者脑内信息或当前聊天才能理解；
- Harness / Tool / Runtime 能力没有被文本伪造；
- 没有明显重复 owner、死文件或错误引用。

可以运行：

```bash
python scripts/validate_skill.py <skill-dir>
```

这只证明结构基础，不证明 Skill 已经成熟。

## 10. 初始 commit

在该 Skill 自己的 Git repository 中：

```text
review diff
→ 删除 accidental / dead files
→ 必要结构检查
→ git add
→ git commit
```

提交说明描述：

- Source 的类型；
- 抽象出的能力；
- 当前边界；
- 不夸大验证程度。

到这里可以说：

> **初始 Skill 已创建。**

## 11. 进入真实使用

Construction 的终点不是“已经验证完成”，而是：

> **这个 Skill 已经可以进入真实工作。**

```text
Skill v0
→ Real Use
→ new experience
→ Case（值得保留时）
→ Skill Evolution
→ Skill vNext
```

真实使用天然检验：

- 抽象是否过宽或过窄；
- Trigger 是否正确；
- Workflow 是否遗漏；
- 原案例中的局部规律是否被误当成通用规律；
- Example 是否产生错误模仿；
- Tool / Harness 边界是否正确。

后续见 [skill-evolution.md](skill-evolution.md)。

# 创建完成标准

初始 Skill 创建完成时：

- Source 和范围已经明确；
- Source 已被正确理解或重建；
- 局部细节与可迁移关系已经分开；
- Capability Contract 已形成；
- 必要成熟实践已经用于校准；
- Guidance 与 Capability 对齐；
- Skill repository 独立 Git 管理；
- `SKILL.md` 能独立指导主要路径；
- supporting resources 都有消费者；
- 必要来源证据已按需保存；
- Tool / Harness / Runtime 边界没有被伪造；
- 已完成必要结构和自包含检查；
- 已产生初始 commit；
- Skill 已准备进入真实使用。

**不要求：**

- 每种 Source 都维护独立创建算法；
- 工作记录必须先转成 Replay Case 才能创建 Skill；
- 创建阶段必须先产生 Usage Case；
- 创建阶段必须强制 Evaluation；
- 创建阶段必须证明 Skill 已经成熟。

# Skill Repository Boundary

每个 Skill 文件夹都应当单独由 Git 管理。

Independent Git repository 指独立 Git history，不等于每个 Skill 必须拥有独立 GitHub / GitLab remote。

外层 `skills/` 可以只是放置目录：

```text
skills/
├── skill-a/
│   ├── .git/
│   └── ...
└── skill-b/
    ├── .git/
    └── ...
```

共享知识只有在它真的形成独立能力、拥有独立 owner 和生命周期时才抽出。

# 只有用户未决定是否 Skill 化时，才做必要性判断

如果用户问：

- “这值得做成 Skill 吗？”
- “应该写 Prompt 还是 Skill？”
- “这些能力应该合并还是拆分？”

才判断是否 Skill 化。

用户已经明确要求创建 Skill 时，不重新进行这层否决。

# Discovery / Security / Release

- 当前 discovery、metadata 和 authority 行为见 [skill-building/official-structure.md](skill-building/official-structure.md)；
- 第三方 Skill、联网、scripts、高影响工具调用见 [skill-building/security-review.md](skill-building/security-review.md)；
- hosted/upload/plugin/public release 见 [skill-building/packaging-and-release.md](skill-building/packaging-and-release.md)。

# 生命周期交接

```text
Source
→ Understand
→ Abstract
→ Capability
→ Guidance
→ Skill
→ Real Use
→ Experience
→ Evolution
```

Skill Construction 到这里结束，后续变化统一交给 [skill-evolution.md](skill-evolution.md)。
