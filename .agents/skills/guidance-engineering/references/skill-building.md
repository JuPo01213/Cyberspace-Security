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

Skill Construction 回答：

> **什么时候一组 Guidance 值得被封装成一个可发现、可复用能力，以及如何完成这个封装。**

它不要求 Guidance 一定先被完整写成独立 Prompt/Workflow 文档；但在封装前，能力目标、行为边界和实际指导必须已经足够清楚。

## 从零创建 Skill：标准流程

这一节是 Skill Construction 的主执行协议。

假设当前 Agent 没有任何前文，只收到类似：

> “创建一个用于 X 的 Skill。”

应当按下面的顺序完成，而不是只写一个 `SKILL.md` 就结束。

### 0. 建立创建上下文

先确定创建所需的最低事实：

- 用户真正想重复完成的目标是什么；
- 当前是否已经存在自然 owner 的 Skill；
- 目标运行环境 / Harness 是什么；如果未知，采用可移植的最小结构，不虚构平台能力；
- 当前项目是否已有约束、模板、官方规范或成熟社区工作流；
- 哪些信息如果缺失会真正阻塞正确创建。

能从当前仓库、官方文档、现有 Skill 或用户已给材料中得到的信息，主动读取，不重复追问。

只有缺失信息会改变能力边界、造成安全问题或使 Skill 根本无法定义时才追问；否则做合理最小假设并继续。

**本阶段产物：**

```text
creation context
= user goal
+ existing owner / no owner
+ target environment
+ relevant constraints / sources
```

### 1. 先调查复用，再决定新建

创建新 Skill 前先检查：

1. 已有 Skill 是否已经拥有这个能力；
2. 当前项目规则是否已经覆盖；
3. 目标生态是否有官方能力、成熟 Skill、成熟 workflow、library、tool 或标准；
4. 是否只需要修改现有 Skill，而不是创建新的。

优先顺序：

```text
reuse existing owner
→ extend / merge existing owner
→ reuse mature external capability
→ only then create a new Skill
```

调查到的成熟实践可以成为设计依据；自己的组合、抽象和推导必须标成自己的 synthesis，不能伪装成“官方成熟做法”。

**继续新建的门槛：**

只有不存在合适 owner，且该能力有稳定、可复用的独立边界，才进入下一步。

### 2. 定义 Capability Contract

在创建文件前先把能力说清楚。

至少回答：

```text
Goal
- 这个 Skill 最终帮助用户完成什么？

Trigger
- 哪些目标 / 条件应该触发？

Non-trigger
- 哪些相邻请求不属于它？

Inputs
- 需要什么信息 / 文件 / 工具结果？

Required behavior
- 所有触发都必须发生什么？

Boundaries
- 哪些事情不能推断、不能越权、不能由 Skill 文本伪造？

Completion
- 什么可观察结果才算完成？

Environment
- 哪些能力来自 Harness / Tool / Runtime，而不是 Skill 本身？
```

如果这些问题还答不清楚，不要进入“写文件”阶段。

### 3. 建模行为

把 Capability Contract 压缩成最少的行为模型：

- 用 **Principle** 表达“什么条件下应该怎样做，以及边界在哪里”；
- 只有行为依赖阶段、状态、前序结果、分支或恢复时，才加入 **Workflow**；
- 不为了看起来完整而制造流程。

Workflow 只需要：

```text
Goal / completion
Stages
State / observations
Transitions / branches
Failure / stop
```

### 4. 规划 Skill Bundle

先决定每类内容的 owner，再创建目录：

- `SKILL.md`：能力边界、共享 instructions、主路由；
- `references/`：长、低频、分支性知识；
- `examples/` 或 reference：只有 Example 有独立教学价值时；
- `scripts/`：重复、确定、机械执行；
- `cases/`：真实使用或 Evaluation 产生的经验；
- `assets/`：真正被输出或流程消费的模板 / 素材；
- `agents/openai.yaml`：目标平台需要时的界面 / 依赖元数据。

不要先创建一堆空目录再寻找内容。

Skill 应尽可能自包含；正常执行不依赖仓库外部的隐含知识。

### 5. 创建独立 Git 管理边界

Skill 文件夹创建后立即成为自己的本地 Git repository。

优先使用：

```bash
python scripts/init_skill.py <name> --path <parent>
```

或等价地：

```bash
mkdir <skill-name>
cd <skill-name>
git init
```

这里的 Git repository 是本地版本边界。是否配置 GitHub / GitLab remote 是独立决定，不属于创建 Skill 的必要条件。

### 6. 写最小可执行 SKILL.md

按这个顺序写：

1. **name / description**
   - description 同时说明“做什么”和“何时应该考虑它”；
2. **能力与边界**
   - 让刚加载 Skill 的 Agent 知道它负责什么、不负责什么；
3. **共享 instructions**
   - 只写所有主要触发都需要的行为；
4. **必要 Workflow**
   - 只保留真正影响推进的阶段、状态、分支、完成/失败出口；
5. **资源路由**
   - 明确什么条件下读取哪个 reference / example / script；
6. **Tool / Harness 边界**
   - 不把不存在的权限、工具、memory、runtime 能力写成 Skill 自己拥有。

具体 Prompt 写法见 [prompt-engineering.md](prompt-engineering.md)。

### 7. 只添加有消费者的 supporting resources

逐项判断：

- 抽象 instruction 已经足够 → 不加 Example；
- Example 能教出新增行为信息 → 按 [example-engineering.md](example-engineering.md) 设计；
- 长知识只在某分支使用 → 下沉 reference；
- 机械规则可以确定执行 → 写 script / schema / test，而不是反复提醒模型；
- 来自真实使用的经验 → 保存 Case，见 [cases.md](cases.md)。

每增加一个文件都要能回答：

> 谁会在什么条件下读取 / 执行它？

答不出来就不要加。

### 8. Validation：先结构，再行为

先运行结构校验：

```bash
python scripts/validate_skill.py <skill-dir>
```

然后至少验证：

```text
Positive discovery
- 应该触发时能否发现 / 选择 Skill？

Negative discovery
- 相邻但不属于它的请求会不会误触发？

Execution
- 加载以后是否真的执行预期行为？

Boundary
- 关键条件变化时是否合理停止、反转或降级？

Completion
- 是否以真实结果而不是“步骤执行过”判断完成？
```

如果 Skill 是从某个真实 Case 抽象出来的，再加入独立 holdout / boundary case，避免只会复现原案例。

不能执行的验证要明确标成未验证，不把候选方案写成“已经成熟”。

### 9. 从零上下文做一次自审

提交前假设：

> 另一个 Agent 没有这次对话，只拿到这个 Skill repository。

检查它是否能够：

- 从 description 判断什么时候考虑 Skill；
- 从 `SKILL.md` 理解目标和边界；
- 找到必要 reference / script；
- 不依赖作者脑中的隐含知识；
- 不需要读取全部 Case 历史才能正常执行；
- 区分 Skill 指导与 Harness / Tool 能力；
- 在失败或信息不足时有合法出口。

如果答案是否定的，先补 Skill 本身，而不是依赖“以后解释”。

### 10. 提交初始版本

在这个 Skill 自己的 Git repository 中：

```text
review diff
→ remove accidental / dead files
→ run validation
→ git add
→ git commit
```

提交说明描述这个 Skill 此次形成了什么能力，不把未验证内容写成已经证明有效。

Remote 是可选的；本地 commit 不是可选的生命周期细节，而是 Skill 版本历史的起点。

## 两种入口如何接入这条主流程

### 入口 A：用户直接要求创建一个 Skill

```text
用户目标
→ Step 0
→ Step 1
→ ...
→ Step 10
```

不要求先存在 Case。

### 入口 B：从真实使用经验固化

```text
真实使用
→ 先保存 Case
→ Step 1 Reuse / Ownership
→ Step 2 Capability Contract
→ ...
→ Step 10
```

Case 的保存、抽象和反馈规则见 [cases.md](cases.md)。

## Definition of Done

只有同时满足以下条件，才能说“Skill 已创建”：

- 能力目标、trigger 和 non-trigger 已明确；
- 新建而不是复用已有 owner 有理由；
- Skill 文件夹由自己的本地 Git repository 管理；
- `SKILL.md` 有可执行 instructions，而不是只有身份描述；
- supporting resources 都有明确消费者；
- 需要的 references / scripts / examples 能从主 Skill 被发现；
- Tool / Harness / Runtime 边界没有被伪造；
- 至少完成结构验证；
- 对核心行为完成了与风险和复杂度相称的 Evaluation，或明确标记未验证部分；
- 已从“无前文 Agent”视角做自审；
- 已在 Skill 自己的 Git repository 中产生初始 commit。

## 先判断：真的需要 Skill 吗

满足越多，越值得 Skill 化：

- 同一类用户目标反复出现；
- 有相对稳定的触发边界；
- 不只是一个项目事实；
- 需要按需知识、Examples、scripts 或工具指导；
- 长期维护价值高于额外 discovery/context 成本；
- 与已有 Skill 合并会明显造成边界污染。

以下情况优先不建新 Skill：

- 一次性 Prompt；
- 单个项目局部事实；
- 仅仅是一条短规则；
- 已有 Skill 已有自然 owner；
- 只是某个 Harness / Tool 的实现缺口。

## 能力边界

在碰文件结构前，先回答：

- 这个 Skill 帮用户完成什么；
- 哪类请求应该触发；
- 哪类相邻请求不应该触发；
- 哪些指导对所有触发都成立；
- 哪些内容只在分支场景需要；
- 哪些操作应该交给 script/tool；
- 哪些属于 Harness/Runtime，Skill 无法实现。

## 粒度：默认聚合相关能力

当多个子流程：

- 共享同一用户目标；
- 经常共同出现；
- 共同维护；
- 拆开只增加 discovery 与同步成本；

优先聚合到一个 Skill，由主 `SKILL.md` 路由 references。

只有独立后能明显降低误触发、上下文污染或维护耦合，才拆成新 Skill。

## 设计 Guidance

### Prompt

具体书写方法见 [prompt-engineering.md](prompt-engineering.md)。

不要只写“这是一个 XX 专家 Skill”；必须有真正会改变行为的 instructions。

### Workflow

Workflow 是 Skill 可以封装的一种**行为模型**，不是 Prompt 的子概念。

需要阶段、状态、分支、依赖、工具序列或失败恢复时，先按主 `SKILL.md` 的 Workflow 五项模型确定行为结构，再：

- 用 [prompt-engineering.md](prompt-engineering.md) 把执行所需部分写成 instructions；
- 高频且短的流程可常驻主 `SKILL.md`；
- 长、低频或分支性流程可下沉 reference；
- 确定性机械步骤可交给 script/tool。

删除独立 Workflow reference 不意味着删除 Workflow 层。

### Example

只有示范能提供新增行为信息时读取 [example-engineering.md](example-engineering.md)。

### Knowledge / references

把低频、长背景、平台细节、schemas 和分支知识下沉。

### Scripts / Tools

重复、确定性、机械执行逻辑优先 script；实时数据、认证、授权和副作用由 Tool/Harness 实现。

## 规划文件归属

默认：

- `SKILL.md`：能力边界、共享指导、主路由；
- `references/`：按需知识、分支流程、Examples、schemas；
- `scripts/`：重复且适合确定性执行的逻辑；
- `assets/`：模板和最终产物素材；
- `agents/openai.yaml`：目标平台支持时的界面/依赖元数据。

不要为了完整而创建空目录、README 或重复副本。

## Description 与 Discovery

`description` 要同时表达：

- Skill 做什么；
- 哪些用户目标/条件应该让模型考虑它。

不要把触发条件只藏在正文。

目标平台的当前 discovery、metadata 和 authority 行为见 [skill-building/official-structure.md](skill-building/official-structure.md)。

## 主 SKILL.md

保持最小充分：

- 共享能力边界；
- 真正高频的 instructions；
- 主 workflow（若存在）；
- references / scripts 的读取条件；
- Tool/Harness 边界。

详细内容下沉，不把整个知识库常驻上下文。

## Example 放置

Example 的设计由 Example Engineering 负责；Skill Construction 只决定：

- 短且高频 → 主 `SKILL.md`；
- 长、低频、分支性 → reference；
- 测试 case → 不进入生产 Guidance。

## Validation

结构校验：

```bash
python scripts/validate_skill.py <skill-dir>
```

它只能证明 bundle 的基础结构，没有证明行为有效。

行为验证由 [evaluation.md](evaluation.md) 负责，至少区分：

- **Discovery**：该触发时能否发现/选择；
- **Negative discovery**：相邻请求会不会误触发；
- **Execution**：加载后是否执行正确行为；
- **Boundary**：条件变化时是否合理反转；
- **Regression**：修改是否破坏已有能力。

新 Skill 在这些测试之前只是 Candidate Skill。

## 发布 / 安全

第三方 Skill、联网、scripts、高影响工具调用：读 [skill-building/security-review.md](skill-building/security-review.md)。

需要 hosted/upload/plugin/public release：读 [skill-building/packaging-and-release.md](skill-building/packaging-and-release.md)。

## 完成检查

创建阶段以本文件前面的 **Definition of Done** 为准。

后续维护 / 演进时额外检查：

- description 与实际能力仍一致；
- Workflow 没有因为局部修补而膨胀；
- Examples 仍然提供独立教学信息；
- supporting resources 仍有消费者；
- Harness/Runtime 能力没有被 Skill 文本伪造；
- 新修改已经过适当 Evaluation；
- 未验证内容没有被写成成熟实践。


## 使用中持续改进

Skill 发布后不是终点。

真实任务中的成功、失败和用户纠正先保存为 Case，而不是直接改 `SKILL.md`。需要优化时：

```text
Skill
→ Use
→ Case
→ Candidate change
→ Evaluation
→ Skill vNext
→ Git commit
```

具体见 [cases.md](cases.md)。

Maintenance / Evolution 只描述最终变更性质，不要求不同流程。
