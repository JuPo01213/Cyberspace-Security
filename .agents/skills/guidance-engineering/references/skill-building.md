# Skill Construction

## 职责

Skill Construction 只回答：

> **何时值得形成一个可发现、可复用能力，以及怎样把已有 Guidance 封装成 Skill。**

它不重新定义 Prompt、Workflow、Example 或 Evaluation。

进入本分支前，相关行为应已经在对应层说清：

- instruction → [prompt-engineering.md](prompt-engineering.md)
- 多步行为结构 → [workflow-design.md](workflow-design.md)
- teaching examples → [example-engineering.md](example-engineering.md)

## 先定义能力边界

Skill 的第一问题不是目录，而是：

- 它代表什么可复用能力；
- 哪类用户目标应该触发；
- 哪些相邻请求不应该触发；
- 哪些 Guidance 是所有触发都共享的；
- 哪些知识/示范/流程只在特定分支需要；
- 哪些确定性工作应交给 script/tool；
- 哪些能力属于 Harness/Runtime，不能由 Skill 伪造。

## 粒度：默认聚合相关工作流

理论上可区分，不代表必须拆 Skill。

优先一个主 Skill 内部路由，当多个部分：

- 经常共同出现；
- 共享触发目标；
- 共同维护；
- 拆开只增加 discovery 与同步成本。

只有独立后能显著降低误触发、上下文污染或维护耦合，或已形成明显独立用户目标时再拆。

## 创建 / 更新流程

### 1. Use-case inventory

至少覆盖：

- 直接触发；
- 间接表达同一目标；
- 信息不完整；
- 不应触发的相邻请求；
- 典型边界。

如果仓库已有相关 Skill、运行证据、review 或历史版本，先读最相关材料。

需要调查官方/成熟方案时，读 [skill-building/research-and-reuse.md](skill-building/research-and-reuse.md)。

### 2. 确定目标平台

先确认 Skill 将运行在哪个生态/宿主，再决定结构和依赖。当前 OpenAI 结构与能力边界见 [skill-building/official-structure.md](skill-building/official-structure.md)。

不要把一种 Harness 的挂载、权限或 discovery 机制写成所有平台的通用事实。

### 3. 规划文件归属

默认：

- `SKILL.md`：触发后的共享核心指导和路由；
- `references/`：只在特定分支需要的知识、policy、schema、examples 和专项流程；
- `scripts/`：适合确定性、重复执行的逻辑；
- `assets/`：要复制、转换或交付的模板/素材；
- `agents/openai.yaml`：目标平台支持时的界面与依赖元数据。

同一语义只留一个权威位置。

### 4. 写 description 与主入口

`description` 负责让模型知道“这是什么能力、什么时候考虑它”。

主 `SKILL.md` 保持短，只保留：

- 共享边界；
- 共享 workflow；
- 高价值常驻规则；
- supporting files 的读取条件。

详细措辞回 [prompt-engineering.md](prompt-engineering.md)，正式 Workflow 回 [workflow-design.md](workflow-design.md)。

### 5. 放置 Examples

Example 的设计统一见 [example-engineering.md](example-engineering.md)。

Skill 层只决定放置：

- 高频、短、几乎所有触发都需要 → 主 `SKILL.md`；
- 分支性、较长、数量较多 → reference；
- 测试 case → 不进入生产 Guidance。

### 6. Scripts 与 Tools

只有确定性、重复执行的逻辑才值得成为 script。

Skill 可以指导工具使用顺序与结果消费；认证、授权、实时数据和受控副作用由工具/Harness 实现。

第三方 Skill、联网、脚本和高影响工具调用需要 [skill-building/security-review.md](skill-building/security-review.md)。

### 7. 验证

结构校验可运行：

```bash
python scripts/validate_skill.py <skill-dir>
```

行为有效性、触发/非触发、边界和回归统一交给 [evaluation.md](evaluation.md)，不要在 Skill Construction 再维护第二套测试方法。

### 8. 发布 / 版本

只有需要 hosted/upload/plugin/public release 时读取 [skill-building/packaging-and-release.md](skill-building/packaging-and-release.md)。

## 经验如何进入 Skill

真实运行不会自动产生新规则。

```text
observation / case
→ hypothesis
→ candidate guidance
→ evaluation
→ evolution decision
→ active Skill
```

完整升格与维护规则由 [evolution.md](evolution.md) 所有。

## 完成检查

- 能力目标与触发边界清楚；
- 没有为了模块化制造新 Skill；
- 主 `SKILL.md` 没有复制 references 的长内容；
- supporting files 都有明确消费者与读取条件；
- Prompt / Workflow / Example / Eval 的权威归属没有重复；
- scripts/tools 没有承担自然语言层已经足够完成的工作，反之亦然；
- Harness/Runtime 能力没有被 Skill 文本伪造；
- 行为修改已经交由 Evaluation 验证，未验证内容明确标成候选。
