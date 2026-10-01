# Skill Construction

## Skill Repository Boundary

每个 Skill 文件夹都应当**单独由 Git 管理**：Skill 文件夹本身就是一个本地 Git repository，也是这个 Skill 的生命周期边界。

这里的 “independent Git repository” 指独立的 Git 历史，不等于必须为每个 Skill 创建独立 GitHub / GitLab 远端仓库。Remote、托管和公开发布都是可选的分发层，不能与本地版本管理边界混为一谈。

一个 Skill repository 自己拥有：

- `SKILL.md`；
- `references/`；
- `examples/`；
- `cases/`；
- `scripts/`、tools 和必要 assets；
- evaluation assets；
- 该 Skill 自己的 Git history。

Skill 应尽可能自包含：理解、执行、评估和改进该能力所需的主要知识应归这个 Skill 自己所有。自包含不等于复制无关材料；真正的外部依赖必须有明确 owner 和边界。

不要用一个上层 Git repository 统一管理多个 Skill 的版本历史。外层 `skills/` 可以只是本地放置目录；每个子 Skill 自己 `git init`、自己 commit、自己回滚。是否配置 remote 由实际需要决定。

Default local layout:

```text
skills/                     # 可只是普通目录
├── skill-a/
│   ├── .git/               # skill-a 自己的 Git repository
│   ├── SKILL.md
│   ├── references/
│   ├── cases/
│   └── ...
└── skill-b/
    ├── .git/               # skill-b 自己的 Git repository
    ├── SKILL.md
    └── ...
```

共享知识只有在它真的形成独立能力、拥有独立 owner 和生命周期时才抽出；否则优先留在自然 owner 的 Skill 内。

Skill 不是一个 Prompt 文件，而是一个可以独立版本化和演进的能力资产。

## 职责

用户明确要求“创建一个 Skill”时，创建决定已经成立。Skill Construction 的职责不是重新判断“是否值得创建”，而是把这个意图落实成一个可独立运行、可验证、可维护的 Skill。

因此：

- 不重复询问用户是否确定要创建；
- 不用已有 Skill、成熟工具或现成项目否决用户的创建决定；
- 调研只用于决定“怎么建得更好”，不用于改写用户目标；
- 只有用户本身在问“是否应该做成 Skill”时，才进行必要性判断。

## 从零创建 Skill：执行流程

假设没有任何前文，只收到：

> 创建一个用于 X 的 Skill。

直接按下面顺序执行。除非缺失事实会让能力根本无法定义、造成权限/安全错误，或者用户明确要求先确认，否则不要在步骤之间反复追问。

```text
1. 解析用户要求
2. 调研成熟做法
3. 定义能力边界
4. 初始化 Skill + Git
5. 写 SKILL.md
6. 补必要资源
7. 建最小 Cases
8. 验证并修正
9. 自包含审查
10. 初始 commit
```

### 1. 解析用户要求

直接从当前消息和已有上下文提取：

- Skill 名称或 working name；
- 最终目标；
- 典型触发条件；
- 明显不属于它的相邻请求；
- 预期输出 / completion；
- 已知工具、Harness、平台与约束；
- 用户给出的案例、失败经验或参考资料。

用户已经给出的信息不要再问。名称未给时根据能力目标生成 working name。环境未知但不阻塞创建时，采用最小可移植假设继续。

**进入下一步：** 已经能用一两句话说明“这个 Skill 在什么情况下帮助用户完成什么”。

### 2. 调研成熟做法

调查目标是吸收成熟实践，而不是决定是否创建。

优先检查：

- 当前官方文档与平台限制；
- 成熟 workflow / Skill / tool / library；
- 当前项目中可借鉴的实现；
- 用户提供的经验和材料。

只提取真正影响设计的内容：结构要求、成熟工作顺序、工具接口、常见失败模式、可复用脚本/schema/template。

不要整篇复制资料；自己的综合与推导要和外部事实区分。

**进入下一步：** 已知道哪些成熟做法应当吸收，哪些行为仍需当前 Skill 自己定义。

### 3. 定义能力边界

在写文件前先形成工作中的能力定义，不要求单独保存成文档：

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
→ 缺信息、工具失败、条件不满足时怎样结束

Environment boundary
→ 哪些能力来自 Harness / Tool / Runtime，而不是 Skill 文本
```

只有行为依赖阶段、状态、前序结果、分支或恢复时才设计 Workflow。最小 Workflow 只保留：

```text
Goal / completion
Stages
State / observations
Transitions / branches
Failure / stop
```

**进入下一步：** 能力边界和核心行为已经足够明确，可以落盘。

### 4. 初始化 Skill + Git

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

不要为了目录完整性先创建全部 `references/`、`examples/`、`cases/`、`scripts/`、`assets/`。

**进入下一步：** Skill 文件夹存在、`.git/` 已建立、`SKILL.md` 可编辑。

### 5. 写 SKILL.md

按固定顺序完成主文件：

1. **name / description**：description 同时说明“做什么”和“何时应考虑它”；
2. **能力与边界**：负责什么、不负责什么、什么算完成；
3. **共享 instructions**：所有主要触发都需要的行为；
4. **必要 Workflow**：只保留执行时真正需要的阶段、状态、分支、completion / failure exit；
5. **资源路由**：明确什么条件下读取哪个 reference / example / script；
6. **Harness / Tool 边界**：不把权限、live data、memory、sandbox、runtime state 等能力用文字“假装实现”。

具体 Prompt 写法见 [prompt-engineering.md](prompt-engineering.md)。

**进入下一步：** 只读取 `SKILL.md` 时，Agent 已能完成主要路径，或明确知道何时读取下一层资源。

### 6. 补必要资源

现在才创建 supporting resources：

- 长、低频、分支性知识 → `references/`；
- Example 能增加独立教学信息 → `examples/` 或按需 reference；
- 重复、确定、机械执行 → `scripts/` / schema / test；
- 输出模板或素材 → `assets/`；
- 真实使用或 Evaluation 产生的新经验 → `cases/`。

每个文件都必须能回答：

> 谁会在什么条件下读取或执行它？

答不出来就不要加。

Skill 应尽可能自包含，不依赖 Skill 文件夹外的隐含知识。

### 7. 建最小 Cases

先建立足以检验能力边界的最小 Cases：

- **Positive**：明确应该触发并成功完成；
- **Boundary**：关键条件变化后行为应改变；
- **Negative**：相邻但不应由该 Skill 接管；
- **Failure / incomplete**：缺关键条件或工具失败时仍能合法结束。

如果 Skill 来源于某个真实 Case，再加入至少一个不同表面载体的 holdout。

Cases 自包含在该 Skill 内，具体记录方式见 [cases.md](cases.md)。

### 8. 验证并修正

验证顺序固定：

```text
结构
→ discovery
→ execution
→ boundary / failure
→ regression（修改已有能力时）
```

先运行：

```bash
python scripts/validate_skill.py <skill-dir>
```

再执行 Step 7 的 Cases。

发现问题时：

```text
观察偏差
→ 判断归因
→ 修改唯一 owner
→ 重跑相关 Case
```

不要通过不断往 `SKILL.md` 末尾追加警告修所有问题。无法实际执行的验证要明确标记“未验证”。

**进入下一步：** 结构通过，核心路径没有已知未处理偏差。

### 9. 自包含审查

假设创建对话已经完全不存在，只留下 Skill 文件夹。

检查另一个 Agent 是否能够：

- 从 description 判断何时使用；
- 从 `SKILL.md` 理解目标、边界和完成条件；
- 找到必要 supporting resources；
- 不依赖作者脑内信息或当前聊天；
- 不读取全部 Case 历史也能正常执行；
- 区分 Skill 与 Harness / Tool；
- 在失败和不确定时有合法出口。

有缺口就返回对应步骤修改，不靠额外口头说明补洞。

### 10. 初始 commit

在该 Skill 自己的 Git repository 中：

```text
review diff
→ 删除 accidental / dead files
→ 最后一次 validation
→ git add
→ git commit
```

提交说明描述实际形成的能力和边界，不夸大验证程度。

到这里才可以说：

> Skill 已创建。

## 创建完成标准

- 用户要求的 Skill 已实际创建，而不是被重新劝退或替换成别的产物；
- Goal、Trigger、Non-trigger、Completion 已明确；
- 已吸收必要成熟实践；
- Skill 文件夹由自己的本地 Git repository 管理；
- `SKILL.md` 能独立指导主要路径；
- supporting resources 都有消费者和路由；
- Case 自包含在 Skill 内；
- Tool / Harness / Runtime 边界没有被伪造；
- 已完成结构验证和最小行为 Cases，或明确标记无法验证部分；
- 清空创建上下文后仍然自包含；
- 已产生初始 Git commit。

## 只有用户未决定是否 Skill 化时，才做必要性判断

如果用户问的是：

- “这值得做成 Skill 吗？”
- “应该写 Prompt 还是 Skill？”
- “这几个能力应该合并还是拆分？”

才判断是否 Skill 化、是否存在更自然 owner、是否应合并。

不要把这套判断反向套到“请创建一个 Skill”这种已经明确的创建命令上。

## 设计细则

### 粒度：默认聚合相关能力

多个子流程共享同一用户目标、经常共同出现、共同维护，而且拆开只增加 discovery 与同步成本时，优先聚合到一个 Skill，由主 `SKILL.md` 路由 references。

只有独立后能明显降低误触发、上下文污染或维护耦合，才拆成新 Skill。

### Prompt

具体书写见 [prompt-engineering.md](prompt-engineering.md)。不要只写“这是一个 XX 专家 Skill”；必须有真正会改变行为的 instructions。

### Example

只有示范能增加独立行为信息时读取 [example-engineering.md](example-engineering.md)。

### Knowledge / references

把低频、长背景、平台细节、schemas 和分支知识下沉。

### Scripts / Tools

重复、确定性、机械执行优先 script；实时数据、认证、授权和副作用由 Tool/Harness 实现。

### Description / Discovery / Validation / Release

- 当前 discovery、metadata 和 authority 行为见 [skill-building/official-structure.md](skill-building/official-structure.md)；
- 完整 Evaluation 方法见 [evaluation.md](evaluation.md)；
- 第三方 Skill、联网、scripts、高影响工具调用见 [skill-building/security-review.md](skill-building/security-review.md)；
- hosted/upload/plugin/public release 见 [skill-building/packaging-and-release.md](skill-building/packaging-and-release.md)。

## 使用中持续改进

创建后进入：

```text
Skill
→ Use
→ Case
→ Candidate change
→ Evaluation
→ Skill vNext
→ Git commit
```

真实任务中的成功、失败和用户纠正先保存为 Case，而不是直接改 `SKILL.md`。具体见 [cases.md](cases.md)。

Maintenance / Evolution 只描述最终变更性质，不要求不同流程。
