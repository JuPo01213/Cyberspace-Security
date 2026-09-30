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

## Progressive disclosure

把共享核心放 `SKILL.md`，把只在特定任务需要的长材料放 references。

每个 reference 应从 `SKILL.md` 或已明确路由的上层 reference 可发现，并写清读取条件。避免深层、不可发现的引用链。

不要重复同一事实到多个文件；决定唯一权威位置。

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
