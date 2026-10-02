# Skill Construction

## Skill Repository Boundary

每个 Skill 文件夹都应当单独由 Git 管理：Skill 文件夹本身就是一个本地 Git repository，也是这个 Skill 的生命周期边界。

这里的 “independent Git repository” 指独立 Git 历史，不等于必须为每个 Skill 创建独立 GitHub / GitLab 远端仓库。Remote、托管和公开发布都是可选分发层。

一个 Skill repository 可以拥有：

- `SKILL.md`；
- `references/`；
- `examples/`；
- `cases/`；
- `scripts/`、tools 和必要 assets；
- 该 Skill 自己的 Git history。

Skill 应尽可能自包含：理解、执行和后续演化该能力所需的主要知识应归这个 Skill 自己所有。真正的外部依赖必须有明确 owner 和边界。

不要用一个上层 Git repository 统一管理多个 Skill 的版本历史。外层 `skills/` 可以只是本地放置目录；每个子 Skill 自己 `git init`、自己 commit、自己回滚。

## 职责

用户明确要求“创建一个 Skill”时，创建决定已经成立。Skill Construction 负责：

> **把用户要求的能力形成一个可独立理解、可实际使用、可继续演化的初始 Skill。**

它不负责证明这个 Skill 已经成熟，也不要求在创建阶段人为构造完整 Evaluation。

调研只用于决定“怎么建得更好”，不用于重新否决用户的创建意图。

# 从零创建 Skill：执行流程

```text
1. 解析用户要求
2. 调研成熟做法
3. 定义能力边界
4. 初始化 Skill + Git
5. 写 SKILL.md
6. 补必要资源
7. 自包含与结构检查
8. 初始 commit
9. 进入真实使用
```

除非缺失事实会让能力无法定义、造成明显权限/安全错误，或者用户明确要求先确认，否则不要在步骤间反复追问。

## 1. 解析用户要求

直接从当前消息和已有上下文提取：

- Skill 名称或 working name；
- 最终目标；
- 典型触发条件；
- 明显不属于它的相邻请求；
- 预期输出 / completion；
- 已知工具、Harness、平台与约束；
- 用户提供的案例、失败经验或参考材料。

用户已经给出的信息不要再问。名称未给时根据能力目标生成 working name。环境未知但不阻塞创建时，采用最小可移植假设继续。

**进入下一步：** 已能用一两句话说明“这个 Skill 在什么情况下帮助用户完成什么”。

## 2. 调研成熟做法

调查目标是吸收成熟实践。

优先检查：

- 当前官方文档与平台限制；
- 成熟 workflow / Skill / tool / library；
- 当前项目中可借鉴的实现；
- 用户提供的经验和材料。

只提取真正影响设计的内容：

- 结构要求；
- 成熟工作顺序；
- 工具接口；
- 常见失败模式；
- 可复用 script / schema / template。

不要整篇复制资料；自己的综合与推导要和外部事实区分。

**进入下一步：** 已知道哪些成熟做法应吸收，哪些行为仍需当前 Skill 自己定义。

## 3. 定义能力边界

在落盘前形成工作中的能力定义：

```text
Goal
→ 最终要完成什么

Trigger
→ 什么请求应该触发

Non-trigger
→ 哪些相邻请求不属于它

Required behavior
→ 每次触发都必须发生什么

Conditional behavior
→ 哪些行为只在特定条件发生

Completion
→ 什么可观察结果才算完成

Failure / uncertainty
→ 信息不足、工具失败、条件不满足时怎样合法结束

Environment boundary
→ 哪些能力来自 Harness / Tool / Runtime，而不是 Skill 文本
```

只有行为依赖阶段、状态、前序结果、分支或恢复时才设计 Workflow。

最小 Workflow：

```text
Goal / completion
Stages
State / observations
Transitions / branches
Failure / stop
```

**进入下一步：** 能力边界和核心行为足够明确，可以开始创建文件。

## 4. 初始化 Skill + Git

创建 Skill 文件夹，并立即建立它自己的本地 Git repository：

```bash
python scripts/init_skill.py <name> --path <parent>
```

或等价：

```bash
mkdir <skill-name>
cd <skill-name>
git init
```

Remote 可选。

不要为了目录完整性预先创建所有 `references/`、`examples/`、`cases/`、`scripts/`、`assets/`。

**进入下一步：** Skill 文件夹存在、`.git/` 已建立、`SKILL.md` 可编辑。

## 5. 写 SKILL.md

按固定顺序完成主文件：

1. **name / description**
   - description 同时说明“做什么”和“何时应考虑它”；
2. **能力与边界**
   - 负责什么、不负责什么、什么算完成；
3. **共享 instructions**
   - 所有主要触发都需要的行为；
4. **必要 Workflow**
   - 只保留执行时真正需要的阶段、状态、分支、completion / failure exit；
5. **资源路由**
   - 明确什么条件下读取哪个 reference / example / script；
6. **Harness / Tool 边界**
   - 不把权限、live data、memory、sandbox、runtime state 等能力用文字“假装实现”。

具体 Prompt 写法见 [prompt-engineering.md](prompt-engineering.md)。

**进入下一步：** 只读取 `SKILL.md` 时，Agent 已能执行主要路径，或明确知道何时读取下一层资源。

## 6. 补必要资源

现在才创建 supporting resources：

- 长、低频、分支性知识 → `references/`；
- Example 能增加独立教学信息 → `examples/` 或按需 reference；
- 重复、确定、机械执行 → `scripts/` / schema；
- 输出模板或素材 → `assets/`；
- 如果创建本身来自一段已经完成的真实工作，可按需把关键经验保存为 Replay Case，见 [cases.md](cases.md)。

每个文件都必须能回答：

> 谁会在什么条件下读取或执行它？

答不出来就不要加。

Skill 应尽可能自包含，不依赖 Skill 文件夹外的隐含知识。

## 7. 自包含与结构检查

创建阶段只做**足以保证初始 Skill 可理解、可运行的检查**，不把完整行为 Evaluation 作为强制门槛。

检查：

- front matter 与基本目录结构合法；
- description 能支持 discovery；
- `SKILL.md` 能独立表达目标、边界和主要流程；
- supporting resources 都能从主 Skill 被发现；
- 没有依赖作者脑内信息或当前对话才能理解的关键内容；
- Harness / Tool / Runtime 能力没有被文本伪造；
- 没有明显死文件、重复 owner 或错误引用。

可以运行结构 validator：

```bash
python scripts/validate_skill.py <skill-dir>
```

它只证明结构基础，不证明 Skill 已经过真实工作检验。

**进入下一步：** Skill 已达到“可以进入真实使用”的状态。

## 8. 初始 commit

在该 Skill 自己的 Git repository 中：

```text
review diff
→ 删除 accidental / dead files
→ 必要结构检查
→ git add
→ git commit
```

提交说明描述实际形成的初始能力和边界，不把未经使用的 Skill 描述成成熟实践。

到这里可以说：

> **初始 Skill 已创建。**

## 9. 进入真实使用

Skill 创建完成后，不继续在 Construction 中人为制造测试流程。

下一阶段是：

```text
Skill v0
→ Real Use
→ Usage Case
→ Skill Evolution
→ Skill vNext
```

真实使用天然提供后续检验材料。

如果 Skill 是在工作完成后才从完整上下文中抽象出来，也可以从历史上下文构造 Replay Case，为后续 Evolution 提供材料。

后续见：

- [cases.md](cases.md)
- [skill-evolution.md](skill-evolution.md)
- [evaluation.md](evaluation.md)（只有 Evolution 中确有需要时）

# 创建完成标准

只有以下条件满足，才说“初始 Skill 已创建”：

- 用户要求的 Skill 已实际创建；
- Goal、Trigger、Non-trigger、Completion 已明确；
- 已吸收必要成熟实践；
- Skill 文件夹由自己的本地 Git repository 管理；
- `SKILL.md` 能独立指导主要路径；
- supporting resources 都有明确消费者和路由；
- Tool / Harness / Runtime 边界没有被伪造；
- 已完成必要结构和自包含检查；
- 已产生初始 Git commit。

**不要求：**

- 创建阶段必须先产生 Usage Case；
- 创建阶段必须人为构造一整套 Eval Case；
- 创建阶段必须完成行为 Evaluation；
- 创建阶段必须证明 Skill 已经成熟。

Skill 的成熟度来自后续真实使用与演化，而不是创建时一次性证明。

# 只有用户未决定是否 Skill 化时，才做必要性判断

如果用户问的是：

- “这值得做成 Skill 吗？”
- “应该写 Prompt 还是 Skill？”
- “这几个能力应该合并还是拆分？”

才判断是否 Skill 化、是否存在更自然 owner、是否应合并。

不要把这套判断反向套到“请创建一个 Skill”这种已经明确的创建命令上。

# 设计细则

## 粒度：默认聚合相关能力

多个子流程共享同一用户目标、经常共同出现、共同维护，而且拆开只增加 discovery 与同步成本时，优先聚合到一个 Skill，由主 `SKILL.md` 路由 references。

只有独立后能明显降低误触发、上下文污染或维护耦合，才拆成新 Skill。

## Prompt

具体书写见 [prompt-engineering.md](prompt-engineering.md)。不要只写“这是一个 XX 专家 Skill”；必须有真正会改变行为的 instructions。

## Example

只有示范能增加独立行为信息时读取 [example-engineering.md](example-engineering.md)。

## Knowledge / references

把低频、长背景、平台细节、schemas 和分支知识下沉。

## Scripts / Tools

重复、确定性、机械执行优先 script；实时数据、认证、授权和副作用由 Tool/Harness 实现。

## Discovery / Security / Release

- 当前 discovery、metadata 和 authority 行为见 [skill-building/official-structure.md](skill-building/official-structure.md)；
- 第三方 Skill、联网、scripts、高影响工具调用见 [skill-building/security-review.md](skill-building/security-review.md)；
- hosted/upload/plugin/public release 见 [skill-building/packaging-and-release.md](skill-building/packaging-and-release.md)。

## 生命周期交接

Construction 的结束不是“验证完成”，而是“可以进入真实使用”。

```text
Construction
→ Usage
→ Case
→ Evolution
→（必要时）Evaluation
→ Skill vNext
```

后续变化统一交给 [skill-evolution.md](skill-evolution.md)。
