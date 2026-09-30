# 工作流编写与 Skill 载体

本参考是 `personal-agent-workflow` 内部的工作流设计分支，负责创建、更新、审查、重构和打包可复用工作流；当平台使用 Skill 作为载体时，同时处理 Skill 的结构与兼容要求。

它**不是独立可发现 Skill**。关于 Harness / Runtime 如何选择、排序、压缩和投递上下文，归 `context-engineering.md`；本文件只处理一个工作流被选中后如何组织自身指导、references、scripts、examples/evals 与工具边界。

## 默认原则

### 先复用成熟方法，再自建

若领域已有官方工具、标准、成熟工作流、框架或社区方案，先调查再决定是否自建。不要因为模型能手写，就跳过成熟能力。

区分来源权威，不把二次整理称为官方，不把一次本地成功称为成熟实践。需要调研、选型或判断来源时，读取 [research-and-reuse.md](workflow-authoring/research-and-reuse.md)。

### 区分知识与指令

真实观察、失败、解释、假设和设计理由可以被 Agent 看见，但**被记录不等于拥有指令权**。

- 解释性文字保存事实、原因、范围、风险和未知，帮助判断。
- 指令性文字定义条件、动作、禁止、后置条件、跳过条件或停止条件，直接改变行为。
- 单次 problem slice、单个项目故障或一次成功实现，不自动升级为通用 Skill 规则。
- 经验值得复用但尚未证明普适时，优先留在项目知识、research、design docs 或 reference 中。

需要判断一条经验该停留在哪里、何时升格时，读取 [experience-to-guidance.md](workflow-authoring/experience-to-guidance.md)。

### 默认聚合，避免 Skill 碎片化

不要为了“模块化”把紧密相关的方法、阶段和子能力拆成大量独立 Skill。

优先采用：

```text
一个主 SKILL.md
→ 负责发现、共享约束和路由
→ 按当前任务、阶段或事件读取 references
```

当多部分能力经常共同出现、共同维护、共享上下文或拆开后只会增加发现与同步成本时，优先聚合到同一个 Skill 内部。

只有在独立后能明显降低上下文污染、耦合、维护复杂度，或它已经形成明显独立的用户任务与工具/知识体系时，才考虑新建独立 Skill。

不要把“工作流不同”“成功条件不同”机械理解成必须拆 Skill；先判断是否可以由主入口安全、清晰地路由。

### Skill 约束语义，不追求流程外观

优先写稳定目标、判断边界和后置条件，不把某次事故的修复动作机械复制成所有任务的固定序列。

如果可信的当前证据已经满足某个后置条件，不要为了“按 Skill 跑一遍”而重复验证。与当前任务无关的通用步骤，不得仅因它写在 Skill 里就变成前置任务。

根据任务脆弱度选择自由度：

- 多种方案都合理 → 写目标、决策标准和边界；
- 有推荐模式但允许变化 → 写参数化流程或可配置脚本；
- 顺序、权限、安全或正确性高度脆弱 → 写明确步骤、确定脚本和硬停止条件。

### 保持入口短，按需披露

`SKILL.md` 只保留能力、触发边界、稳定约束、主要工作流和 supporting resources 的读取条件。

- `references/`：policies、schemas、examples、背景、专项流程；
- `scripts/`：重复且适合确定性执行的逻辑；
- `assets/`：最终产出需要复制/转换的模板和素材；
- `agents/openai.yaml`：Skill 的界面元数据，以及需要时声明工具依赖。

当前 OpenAI 结构、trigger、MCP 边界和 bundle 要求见 [official-structure.md](workflow-authoring/official-structure.md)。

## 创建或更新流程

### 1. 建立 use-case inventory

先收集或回读少量真实请求，至少确认：

- 用户最终目标；
- 直接触发请求；
- 间接表达同一目标的请求；
- 信息不完整时应该追问的请求；
- 不应触发该 Skill 的相邻请求；
- 典型边缘情况和禁止性推断。

如果仓库已有相关 Skill、problem slices、review、eval、历史版本或真实运行记录，先读取最相关材料，不从空白假设开始。

### 2. 定义 workflow boundary

写清：

- 输入是什么；
- 哪些步骤由 Skill 指导；
- 输出应该是什么；
- 哪些事实不得推断；
- 什么时候追问、停止或拒绝；
- 哪些 supporting files 需要按条件读取；
- 哪些实时数据、认证、授权和副作用动作属于工具/MCP，而不是 Skill 本身。

多个相关工作流可以由同一个主 Skill 路由。只有当聚合导致明显误触发、不可控上下文加载、维护冲突或跨域污染时，再拆分。

### 3. 规划 reusable resources

逐个真实用例分析：

1. 从零完成它需要哪些判断与工具？
2. 哪些知识会反复被重新发现？
3. 哪些代码会反复被重新写？
4. 哪些内容只在特定模式需要？
5. 哪些只是项目事实，不应进入通用 Skill？

没有明确收益就不创建资源目录。不要为了“看起来完整”增加 README、速查表、空目录或重复文档。

### 4. 初始化或检查结构

新建 Skill 时，可运行：

```bash
python scripts/init_skill.py <skill-name> --path <parent-dir> [--resources references,scripts,assets]
```

已有 Skill 不要重新初始化；先检查现有调用者、references、scripts、assets、tool dependencies 和权限边界。

结构要求和当前 OpenAI 兼容注意事项见 [official-structure.md](workflow-authoring/official-structure.md)。

### 5. 写最小有效指令

`description` 是主要发现/触发入口。把“它做什么、哪些用户目标或条件应该触发它”写进 description；不要只在 body 里写 when-to-use。

正文只保留真正会改变执行决策的信息。好的指令通常能回答：

- 何时适用？
- 前提是什么？
- 应该做什么？
- 什么证据算满足？
- 何时可以跳过？
- 何时必须追问、停止或拒绝？
- 哪些结论不能从当前事实推出？

用户当前明确要求优先于 Skill guideline；不要让 Skill 扩大用户任务范围或权限。

### 6. 连接工具，但不混淆职责

Skill 负责编排：何时调用工具、顺序、缺失/歧义结果怎么处理、最终输出包含什么。

MCP / 工具负责：实时数据、认证、授权和受控动作。

如果 Skill 依赖 MCP，按目标运行环境在 `agents/openai.yaml` 声明 dependency；dependency 只保证工具可用，不能替代清晰 workflow instructions。

详细边界和审查见 [official-structure.md](workflow-authoring/official-structure.md) 与 [security-review.md](workflow-authoring/security-review.md)。

### 7. Examples 只解决规则难以稳定表达的行为

模型已经能稳定做到的事情，不为了“有 Few-shot”而加 examples。

普通校准优先使用简洁 **input → desired output**。只有错误答案表面也合理、边界难以纯文字表达时，再使用 contrastive example。

examples 与 evals 分开。需要筛选 canonical examples、设计 cross-carrier eval 或做 ablation 时，读取 [examples-and-evals.md](workflow-authoring/examples-and-evals.md)。


### 8. 验证

先运行结构检查：

```bash
python scripts/validate_skill.py <skill-dir>
```

然后做行为测试：

- 直接触发；
- 间接触发；
- 输入不完整；
- 不应触发；
- 容易幻觉、越权或错误推断的边缘情况。

区分两类失败：

- 触发错误 → 优先改 description / 路由 / 作用范围；
- 触发正确但执行错误 → 改 instruction / reference / example / script / adapter。

测试可观察行为和真正的不变量，不要只匹配固定措辞。

### 9. 安全与打包

第三方 Skill、带脚本的 Skill、可联网 Skill 或高影响动作，在发布/共享前读取 [security-review.md](workflow-authoring/security-review.md)。

如果需要上传、版本化、Plugin 打包或公开提交，读取 [packaging-and-release.md](workflow-authoring/packaging-and-release.md)。不要把本地仓库能运行等同于已经满足发布要求。

### 10. 从真实使用迭代

真实运行首先产生证据，而不是直接产生规则：

```text
真实任务
→ observation / problem slice
→ 可复用经验或假设
→ 反例 / eval
→ 稳定执行指导
→ 放入合适的主 Skill 或按需 reference
→ 真正机械的不变量进入 script / test / lint / CI
```

出现一次失败后先修最窄根因，不立刻新增 universal rule。

## 完成前检查

提交前确认：

- 没把项目事实写成普遍事实；
- 没把一次失败修复写成所有任务的固定流程；
- 没把二手整理误标为官方或成熟实践；
- 没重复已有成熟工具或工作流；
- 没为了形式模块化制造不必要的新 Skill；
- description 能区分该触发和不该触发的请求；
- 每条核心指令都能说明何时改变行为；
- supporting files 都有明确读取条件；
- tool/MCP 与 Skill 的职责没有混淆；
- examples 与 instructions 一致，eval 不只复用教学题；
- 新增或修改脚本已实际运行验证；
- 敏感动作仍受授权、审批和工具权限约束；
- 修改已有 Skill 时没有破坏调用者、作用范围和已有权限边界。

优先用 Git 保留修改历史；提交说明准确标明修改的是 Skill guidance、reference、example、eval、script 还是项目知识，不夸大验证程度。
