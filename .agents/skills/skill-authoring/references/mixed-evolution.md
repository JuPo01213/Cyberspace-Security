# 混同进化：跨 Skill 共享机制与证据

本参考用于多个 Skill 已经存在并持续演进时，避免它们各自在封闭上下文中重复犯错、重复发现同一原则或形成彼此矛盾的局部规则。

“混同”不是把所有 Skill 合并成一个超级 Skill，也不是让所有 Skill 共享同一份完整规则。它指：**真实经验、失败机制、评估方法和成熟原则可以跨 Skill 流动；最终如何表达和落地，由目标 Skill 的任务语境决定。**

## 什么时候进入混同进化

出现以下任一情况时，主动检查 sibling Skills 和相关研究材料：

- 当前问题在另一个 Skill 中已经出现过相似失败；
- 两个 Skill 使用相似的路由、状态、验证或 evidence 机制；
- 某个 Skill 已经形成更成熟的 progressive disclosure / eval / recovery 方法；
- 同一条高层原则在不同 Skill 中出现了不同实现；
- 一个 Skill 的真实失败暴露了可能影响其他 Skill 的机制；
- 用户明确要求跨 Skill 统一、融合、迁移或共同进化。

普通局部文案修正不为了形式执行全仓库比较。

## 基本单位：迁移机制，不复制文本

跨 Skill 比较时，先抽出：

```text
source observation
→ underlying mechanism
→ source conditions
→ boundary / counterexample
→ target relevance
→ target-specific expression
→ target eval
```

例如：

```text
Windows Guest:
后续恢复成功 ≠ 初始 delivery 成功

Software Engineering:
测试最终通过 ≠ 中间迁移步骤从未失败

Skill Authoring:
最终输出合理 ≠ Skill trigger / instruction 本身正确
```

三者可能共享“后续结果不能反证前序边界成功”这一机制，但不需要共享同一句 instruction。

## 跨 Skill 证据等级

不要因为一个机制在别的 Skill 成熟，就自动成为当前 Skill 的强规则。

至少区分：

- **source-only**：只在来源 Skill 有真实证据；
- **plausible-transfer**：机制看起来可迁移，但目标 Skill 尚无验证；
- **target-observed**：目标 Skill 已出现对应真实观察；
- **cross-skill-corroborated**：多个 Skill 在不同载体上独立支持同一机制；
- **mechanized**：已经稳定到可由 script/test/lint/CI 强制。

不要规定机械出现次数；看证据独立性、载体差异、边界和反例。

## 目标 Skill 仍拥有最终表达权

跨 Skill 共享机制，不要求目录或措辞统一。

同一原则可以在不同 Skill 中表现为：

- 一个路由条件；
- 一个 stop condition；
- 一个 evidence gate；
- 一个 example；
- 一个 eval fixture；
- 一个 script invariant。

目标 Skill 应选择最小、最自然、最符合自身任务结构的表达。

## 同一 Skill 内防重复，跨 Skill 不强求单一文本归属

“唯一归属”主要用于防止**同一个 Skill 内部**把同一活动规则复制到多个 reference 并逐渐分叉。

跨 Skill 可以存在同一高层机制的不同适配版本，只要：

- 每个版本都服务明确的本地行为；
- 不伪装成全局唯一真理；
- 共享来源或互证关系可追溯；
- 修改高层机制时检查受影响 sibling Skills。

如果多个 Skill 长期维护完全相同的规则，且差异只来自复制粘贴，再考虑抽成共享 reference 或上层 policy。

## 混同进化循环

1. **冻结当前目标 Skill 的问题**：先明确当前真实偏离，不从“统一所有东西”开始。
2. **扫描近邻 Skill**：只找与该机制直接相关的规则、案例、eval 和真实失败。
3. **提取共同机制**：区分表面动作和底层关系。
4. **寻找冲突与反例**：如果 sibling Skill 的经验在目标语境下不成立，保留差异，不强行统一。
5. **形成 target candidate**：用目标 Skill 自己的语言、路由和证据结构表达。
6. **跑目标 eval**：至少验证主场景、边界和回归。
7. **决定传播方向**：
   - 只保留在目标 Skill；
   - 回馈来源 Skill；
   - 同步到多个 sibling Skills；
   - 升级为共享上层原则；
   - 暂留 research/lesson，不进入指令。
8. **记录验证范围**：说明哪些是 source evidence，哪些已在 target 复现，哪些只是推导。

## 防止“混同”变成污染

不要：

- 因为一个 Skill 做得好，就把它整套流程复制进所有 Skill；
- 为追求统一命名而改写已经有效的领域语言；
- 把通用原则变成所有任务的额外 mandatory steps；
- 因一个跨域类比就声称“已验证普适”；
- 建立一个会自动覆盖所有 Skill 的巨大共享规则文件；
- 让同步成本超过实际收益。

混同进化的目标不是一致，而是**减少重复犯错，提高跨场景证据密度，让真正稳定的机制更快成熟**。
