> **LEGACY / 历史决策**：本文记录过渡阶段的“AGENTS + Playbook + Skill adapter”方案。当前已改为以 Agent Skill 为主交付，详见 `.agents/skills/windows-guest-experiment/SKILL.md`。

# Agent 指导形式选择

> 决策日期：2026-09-25

## 结论

本仓库采用：**AGENTS.md + canonical Playbook + optional Agent Skill adapter**。

不是只用 Skill，也不是只写一个超长 AGENTS.md。

## 职责

- `AGENTS.md`：always-on。只保存仓库级硬规则、当前权威入口和证据表达要求。
- `playbooks/.../PLAYBOOK.md`：唯一完整操作规程。工具无关，供任何 Agent/人类直接读取。
- `skills/.../SKILL.md`：按需加载适配器。只告诉支持 Agent Skills 的客户端何时使用、应读取哪个 Playbook，不复制规则。
- MCP/API/CLI：工具接口，不承担工作流规范本身。
- prompt file/custom agent：可以作为某个客户端的便利入口，但不作为唯一权威，因为支持范围更窄。

## 为什么这样做

`AGENTS.md` 是面向 coding agents 的开放格式，适合仓库级持久指令；OpenAI Codex 会自动发现并注入，GitHub Copilot 也支持 Agent instructions。

Agent Skills 是轻量开放格式，适合把特定流程按需加载，并支持 progressive disclosure。

完整 Playbook 独立存在，可以避免：

- 某个平台不支持 Skill 就丢失规则；
- AGENTS.md 变成几十页、每个请求都塞进上下文；
- Skill 和 AGENTS 各维护一份导致规则漂移；
- 更换 Agent 后必须重写同一套流程。

## 维护规则

1. 一条操作规则只在 Playbook 写一次。
2. AGENTS.md 只放入口和仓库级硬约束。
3. Skill 不复制 Playbook，只引用。
4. 平台特有配置另建 adapter，不反向污染通用 Playbook。
5. 历史方案保留但必须标 `LEGACY`，不能和 current 混用。

参考：

- https://agents.md/
- https://developers.openai.com/api/docs/guides/latest-model#using-agentsmd
- https://docs.github.com/en/copilot/reference/customization-cheat-sheet
- https://agentskills.io/
