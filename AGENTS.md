# AGENTS.md

本文件只保存对**所有任务都成立**的仓库级规则。具体可重复工作流放在 Agent Skills 中，避免把长流程永久塞进上下文。

## Mandatory skill usage

- 当任务涉及稳定 Host 控制不稳定 Windows Guest/VM、snapshot/checkpoint、长任务、Guest 通信、debugger/instrumentation、artifact 收割、安全重试或多 Agent 接手时，**必须使用** `$windows-guest-experiment`：
  - `.agents/skills/windows-guest-experiment/SKILL.md`
- 不要把 `playbooks/windows-guest-experiment/PLAYBOOK.md`、`skills/windows-guest-experiment/` 或 `skills/guest-communication-workbench/` 当作当前执行规范；它们是历史演进材料。

## 脱敏

所有写入仓库的内容必须脱敏，包括提交材料：

- 不写个人邮箱、用户名、凭据、token、私钥、私有 IP/地址；
- 不写真实用户目录、本机私有绝对路径、机器名或可识别个人环境的信息；
- 使用 `<REDACTED_...>`、`<HOST_PATH>`、`<VM_LABEL>` 等占位符；
- 原始材料若包含此类信息，入库前先生成脱敏副本。

## 证据与表述

- 不把模型推演、组件组合或“看起来合理”写成已验证成熟实践。
- 区分：官方/源码事实、外部实践、本项目实测、推断、候选设计。
- 组件成熟不等于组合成熟；未经本项目端到端验证时明确写“未经本项目实测”。
- instrumentation、harness、smoke、静态候选等不得包装成最终业务完成。

## Git

- 积极使用 Git 管理文本、配置、脚本和稳定研究结论。
- Git 不作为每个实验动作的运行时同步协议。
