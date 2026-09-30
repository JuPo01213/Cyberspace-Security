---
name: personal-agent-workflow
description: >-
  设计、编写、审查、评估或演进 Agent 工作流及其行为资产，包括 Prompt、Skill/Workflow、
  examples/evals、行为规则和 tool-use guidance。用于把真实需求、运行证据和成熟方法整理成
  可复用工作流；不用于普通软件开发、一般研究或所有复杂任务的全局总控，也不替代 Harness/Runtime。
metadata:
  short-description: 设计、评估和演进 Agent 工作流
---

# Personal Agent Workflow

## 定位：这是 Skill，不是 Harness

本目录本身仍然属于 **Skill / Workflow 层**。

从 Transformer 看，它只能在被宿主发现、选择并加载后，通过进入上下文的 instructions、references、examples 和工具说明影响模型行为。它不能靠自身内容反向改变宿主如何：

- 发现或自动加载 Skill；
- 排列 system / developer / user / skill 等上下文；
- 压缩历史或维护 memory / project state；
- 暴露、授权或执行工具；
- 建立跨会话运行时；
- 强制全局策略。

这些能力由现有 Harness / Runtime / 平台生态决定。本 Skill 的设计必须**向宿主已有接口妥协**，而不是假设 Skill 可以升级成上层控制器。

当前 OpenAI 生态中，Skill 的主要可用表面是：`SKILL.md`、按需 supporting files（如 `references/`、`scripts/`、`assets/`）以及平台支持的 metadata / tool dependency。平台行为超出这些接口时，把它视为外部条件，不在 Skill 中伪造一套“应该如此”的 Harness。

## 为什么聚合成一个工作流

本工作流聚合的是同一条 Agent 行为工程链：

```text
行为目标与边界
→ Prompt / Skill / Workflow 载体
→ Case / Example
→ Evaluation
→ Evolution
```

因此以下内容放在一个主 Skill 内部，由 `SKILL.md` 路由到 references：

- Behavior Engineering；
- Prompt 编写；
- Skill / Workflow 编写与结构；
- Case / Example 设计；
- Evaluation；
- Evolution / 维护。

这就是本项目所说的“混同进化”：**相关内容在实践中被证明属于同一条工作流时，重新聚合到一个入口，而不是继续增加独立 Skill。**

但聚合不意味着吞掉其他层或其他领域。软件工程、Windows Guest 分析等有自己完整任务体系的工作流继续独立；Harness Context Engineering 也不由本 Skill 接管。

## 主文件常驻原则

这些内容在本 Skill 被加载后，对几乎所有分支都有价值，因此留在主 `SKILL.md`：

- **接受宿主边界。** 只使用当前生态真实提供的 Skill 能力；需要 Harness 能力时，把它作为外部依赖或另一个工程问题，不用 Skill 指令假装实现。
- **主文件负责共享约束和路由。** 只有触发后普遍有用的指导常驻；阶段性知识、平台细节、案例和格式下沉 references。
- **先复用成熟方法，再自建。** 有官方机制、成熟工具或社区工作流时先调查；不要因为模型能手写就重复造轮子。
- **区分证据与指令。** 历史、解释、失败记录和案例可以帮助判断，但不会因为被记录就自动成为长期行为规则。
- **目标不等于策略。** 先明确要产生什么可观察结果，再决定 Prompt、Skill、Workflow、Example 或 Tool guidance 应怎样实现。
- **完成条件优先于过程外观。** 候选文本、格式正确、文件生成或模型自评都不等于行为已经改善；需要与目标对应的观察或 eval。
- **案例是强行为引导。** Few-shot / contrastive example 只在抽象规则不足时使用，并控制数量和适用边界。
- **Skill 不创造权限。** 可以指导工具何时使用、怎样组合，但认证、授权、审批和真实副作用由宿主与工具系统控制。
- **避免 Skill 碎片化。** 相关、共同维护的子流程优先聚合到一个入口并按需路由；只有独立后明显降低管理和上下文成本时再拆。

## 路由

不要全量加载 references。根据当前用户目标选择最窄分支：

- 需要把模糊意图转成 Goal / Policy / Boundary / Evidence 时，读取 [behavior-engineering.md](references/behavior-engineering.md)。
- 需要直接设计或改写 Prompt 时，再读取 [prompt-workflow.md](references/prompt-workflow.md)。
- 需要创建、更新、审查、重构或打包 Skill / Workflow 时，读取 [workflow-authoring.md](references/workflow-authoring.md)；平台结构、经验沉淀、examples/evals、安全和发布细节由该 reference 再按需路由。
- 需要从真实失败抽象高信息密度案例或建立案例覆盖时，读取 [case-engineering.md](references/case-engineering.md)；只有确需历史语料时才定位读取 [case-library.md](references/case-library.md)。
- 需要验证一个行为资产是否真的生效、比较 baseline/variant 或检查边界回归时，读取 [evaluation.md](references/evaluation.md)。
- 用户明确要求优化、重构、维护工作流，或已有足够证据说明活动行为资产需要变化时，读取 [evolution.md](references/evolution.md)。

简单任务只读必要分支，不为了“完整”建立整套文档链。

## 工作流设计循环

当任务确实是设计或演进 Agent 工作流时：

1. **冻结用户目标。** 明确要改善的行为、当前载体、真实消费者和可观察完成条件。
2. **检查现有生态。** 优先查看目标平台已有 Skill 约定、当前项目已有行为资产、成熟工具和已验证做法。
3. **定位最小归属。** 判断变化应落在 Prompt、主 `SKILL.md`、某个 reference、example/eval、script，还是其实属于 Harness / Tool 层。
4. **形成候选。** 只加入会改变目标行为的最小指导；不把解释性知识自动升级成 mandatory step。
5. **验证。** 用真实或代表性输入检查目标行为、边界反转和必要回归。
6. **保留、修改或拒绝。** 没有证据证明改善时，不因为文字更完整就升级为活动规则。

普通使用不会自动触发自我修改。

## 文件职责

- `SKILL.md`：发现后的共享指导、边界和路由。
- `references/behavior-engineering.md`：行为规格、Goal/Policy、边界与证据。
- `references/prompt-workflow.md`：把行为规格编译成可投递 Prompt。
- `references/workflow-authoring.md`：创建、更新、审查和重构 Skill / Workflow，并路由到其专项资料。
- `references/case-engineering.md`：案例抽象、边界与覆盖。
- `references/case-library.md`：历史案例语料；按需定位，不作为默认指令。
- `references/evaluation.md`：运行、观察、比较和判定。
- `references/evolution.md`：显式维护、归因、回归和停止。
- `scripts/`：真正需要确定性、重复执行的工作流辅助脚本。

同一活动语义尽量只有一个主要归属。不要用复制规则解决路由或维护问题。

## 外部边界

- 普通软件功能、Bug、重构、代码审查等，交给软件工程工作流。
- Windows Guest / 安全分析等领域任务，交给对应领域工作流。
- Harness 的上下文编排、memory/state、全局权限和运行时机制，不由本 Skill 声称控制。
- MCP / Tool 提供实时数据、认证、授权和受控动作；本 Skill 只提供其工作流指导。

用户当前明确要求、平台实际约束和工具真实返回始终优先于本 Skill 的默认建议。
