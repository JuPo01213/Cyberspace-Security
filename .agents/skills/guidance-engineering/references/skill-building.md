# Skill Construction

## 职责

Skill Construction 回答：

> **什么时候一组 Guidance 值得被封装成一个可发现、可复用能力，以及如何完成这个封装。**

它不要求 Guidance 一定先被完整写成独立 Prompt/Workflow 文档；但在封装前，能力目标、行为边界和实际指导必须已经足够清楚。

## 最常见入口：用户说“这个可以固化成技能”

当用户在真实任务中发现某种经验值得长期复用，不直接创建 `SKILL.md`。

使用下面的主流程：

```text
1. Capture
   保存用户指出的具体 Observation / Case

2. Reuse / Ownership Check
   先检查已有 Skill、当前项目规则、成熟官方/社区能力
   ↓
   已有 owner → 优先修改/合并
   没有 owner → 继续

3. Abstract
   Case → Mechanism → General Principle
   只在经验来源场景需要

4. Define Capability
   明确这个 Skill 解决什么重复用户目标、哪些请求不属于它

5. Design Guidance
   写 Prompt
   + 必要时 Workflow
   + 必要时 Generic Examples
   + 必要时 scripts/references/tools

6. Package Candidate Skill
   组织 SKILL.md / references / scripts / assets / metadata

7. Evaluate
   discovery + execution + boundary + regression / holdout

8. Decide
   promote / merge / revise / reject
```

其中 Case/Principle 的抽象规则由 [evolution.md](evolution.md) 和 [evaluation/case-engineering.md](evaluation/case-engineering.md) 提供；本文件负责把它们编排成“形成 Skill”的完整路径。

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

Workflow 不再维护独立 reference。它是 Prompt / Skill instructions 的复杂行为组织方式。

当能力存在阶段、状态、分支、依赖、工具序列或失败恢复时，按 [prompt-engineering.md](prompt-engineering.md) 的“复杂行为：把 Workflow 写进 Prompt”部分设计，再决定哪些内容常驻 `SKILL.md`、哪些下沉 reference、哪些交给 script/tool。

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

- 新建 Skill 而不是并入已有 owner 有明确理由；
- description 与实际能力一致；
- Prompt 不是空洞身份设定；
- 只有复杂行为才引入 Workflow structure，且没有为它复制第二套规则；
- Examples 真正增加教学信息；
- supporting resources 都有消费者；
- Harness/Runtime 能力没有被 Skill 文本伪造；
- Candidate 已经过适当 Evaluation；
- 未验证内容没有被写成成熟实践。
