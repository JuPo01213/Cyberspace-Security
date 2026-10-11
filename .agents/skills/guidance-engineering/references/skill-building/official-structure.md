# 当前 OpenAI Skill 结构与执行边界

> 核对日期：2026-10-01。下面区分“当前官方明确要求”与“本 Skill 的可移植工程建议”。

## 当前官方明确结构

OpenAI 当前把 Skill 定义为一组 instructions + supporting files，用于可重复工作流。

一个 Skill 至少需要自己的目录和一个 `SKILL.md`。常见 supporting resources：

```text
skill-name/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
├── scripts/
└── assets/
```

当前官方资料：

- https://developers.openai.com/plugins/concepts/skills
- https://developers.openai.com/plugins/build/skills
- https://developers.openai.com/api/docs/guides/tools-skills
- https://developers.openai.com/plugins/deploy/submission-errors

## SKILL.md

Front matter 至少需要：

```yaml
---
name: ...
description: ...
---
```

`description` 决定模型何时考虑该 Skill，因此应同时包含：

- 工作流/能力是什么；
- 哪些用户目标或条件应触发它。

详细步骤、格式、安全边界、工具顺序和输出要求放正文。

当前官方 workflow boundary 要求正文能说明：

- 输入；
- 步骤；
- 输出；
- 不得推断的事实；
- 何时追问、停止或拒绝；
- 何时读取 supporting files。

用户当前明确指令优先于 Skill guideline；审查 Skill 时检查是否存在冲突或模糊指令。

## 名称

为了跨 Codex、Agent Skills 工具和仓库生态保持可移植性，本 Skill **建议**使用 lowercase hyphen-case，并让目录名与 Skill name 一致。

不要把这条工程建议误写成所有当前 OpenAI surface 的唯一合法名称规则。发布目标有自己的 validator，应以目标 surface 的当前文档为准。

## Progressive disclosure 与上下文预算

把每次执行都需要的核心规则放在 `SKILL.md`；只有特定分支才需要、且篇幅较长的细节才考虑放进 `references/`。主文件必须足以执行正常路径，不能把关键约束拆散到多层文件，迫使模型靠多跳引用拼回完整规则。

拆分前检查：

- 主文件中的内容是否确实只在部分情境下需要？
- 独立文件是否有明确职责、低频触发条件和真实消费者？
- 是否会增加导航步骤、规则不一致、遗漏或维护成本？
- 引用是否从主文件直接可发现，并明确说明何时读取？

避免多层引用、循环引用和跨文件依赖网。长参考文件提供目录，并确认目标运行环境确实能够读取引用文件。每条规则和事实应有唯一权威位置；工作流步骤只写各阶段新增的动作，不重复全局原则；检查清单验证结果，不逐条重述正文。

上下文效率不等于盲目缩短。默认模型已掌握常见概念；优先保留会改变决策的专用约定、歧义、条件、边界、例外、失败处理和验证标准。只有删去内容不会增加误解、错误决策、遗漏或返工风险时才删。

约 **500 行**是 `SKILL.md` 正文的复审触发线，不是硬性上限；接近该规模时重新评估职责边界、常驻上下文收益、使用频率、导航成本与一致性风险。不要只为低于行数门槛而机械拆分。

## agents/openai.yaml

如果包含该文件，当前 Plugin bundle 校验要求 `interface` mapping；常见字段：

```yaml
interface:
  display_name: "..."
  short_description: "..."
  default_prompt: "..."
```

当 Skill 依赖 MCP 工具时，可在其中声明 `dependencies.tools`。不要凭空填 MCP URL 或依赖；只在目标环境和实际工具已知时添加。

## 当前 OpenAI 中 Skill instructions 的位置

在当前 Responses API shell / Skills 机制中，Harness 会把已发现 Skill 的 `name`、`description`、`path` 加入 user-prompt context；模型决定是否读取完整 `SKILL.md`。当前官方文档明确说明：Skill instructions 属于 **user prompt input，而不是 system prompt input**。

因此：

- 不把 “Skill Prompt” 当成新的高权威消息角色；
- Skill 不能靠自身文本覆盖真正更高层的系统/开发者约束；
- 其他 Harness 可能有不同注入方式，跨平台时必须重新确认。

当前官方依据：
https://developers.openai.com/api/docs/guides/tools-skills

## Skill 与 MCP / 工具职责

Skill：
- tool sequence；
- decision points；
- missing/ambiguous result handling；
- output requirements；
- examples / templates / reusable guidance。

MCP / 工具：
- live data；
- authentication；
- authorization；
- controlled actions。

Dependency 让工具可用，不会替代 workflow instructions。

## 当前 hosted/API bundle 限制

OpenAI API 当前文档列出的 hosted Skill 限制包括：

- bundle 中只能有一个 `SKILL.md` / `skill.md`；
- zip 最大 50 MB；
- 每个 Skill version 最多 500 个文件；
- 单个未压缩文件最大 25 MB。

这些是当前 OpenAI hosted/API 约束，不应被误当成所有本地 Harness 的普遍限制。

## 本地与 hosted 不同

Responses API 的 local shell 和 hosted shell 使用不同的 Skill attachment 方式；Agents API sandbox 还使用 capability directories 进行发现。

因此创建 Skill 时先确认目标运行环境，不要把一种 surface 的安装/挂载方式写成所有环境的通用步骤。
