# Guidance Synthesis & Evolution

## 职责

本文件负责两件紧密相关、实际会共用同一套证据链的工作：

1. **Synthesis**：从真实经验提炼新的可复用 Guidance；
2. **Evolution**：根据新证据修改、合并、删除或升格已有 Guidance。

它不重新定义 Prompt 写法、Workflow、Example 或 Evaluation。

## 路径 A：从具体经验生成通用 Guidance

### 1. Capture

先保留真实 Observation：

- 用户原始目标；
- 当时上下文；
- 实际输出 / tool trace；
- 可观察失败或成功；
- 用户纠正；
- 未确认事项。

### 2. Case → Mechanism

由 [evaluation/case-engineering.md](evaluation/case-engineering.md) 把具体事件整理为 development case，并提取 mechanism candidate。

Mechanism 描述：

> 哪些条件与哪种偏离/成功存在可迁移关系？

它还不是规则。

### 3. Mechanism → General Principle

General Principle 至少回答：

```yaml
principle: 通用行为原则
applies_when:
  - 哪些条件成立时适用
action:
  - 应采取/避免什么
boundary:
  - 哪些条件变化后原则应减弱、反转或停止
evidence:
  - 当前哪些 observation/case 支持
forbidden_generalization:
  - 不能把它扩大成什么
```

抽象标准：

- 换掉题材、品牌、工具后仍成立；
- 保留真正改变决策的条件；
- 不把单次事故写成 universal rule；
- 能明确说出反例或边界。

### 4. 选择 Guidance 载体

Principle 不一定要变成新 Skill。

选择最小 owner：

- 一次性表达 → Prompt；
- 阶段/状态/分支 → Workflow；
- 示范比抽象文字更有效 → Example；
- 已有 Skill 有自然 owner → 修改已有 Skill；
- 形成稳定独立能力 → Candidate Skill；
- 机械不变量 → schema / script / test / runtime enforcement。

### 5. 如果需要 Example，重新生成

从 Principle 重新构造 Generic Teaching Example，而不是把源案例匿名化。

详见 [example-engineering.md](example-engineering.md)。

### 6. 独立验证

由 [evaluation.md](evaluation.md) 用 holdout / boundary / 必要时 cross-carrier cases 验证。

Teaching Example 不能自己证明 Principle。

### 7. Promote / Merge / Reject

只有验证支持后才进入活动 Guidance。

可能结果：

- promote new guidance；
- merge into existing owner；
- revise；
- keep as project knowledge；
- reject。

## 路径 B：维护已有 Guidance

进入维护至少满足之一：

- 用户明确要求审查/优化/重构；
- 出现重复或高影响偏离；
- 模型、平台、接口或能力边界变化；
- 已定义维护周期到达且有明确消费者。

没有具体缺口时，不因为“还能更完整”就继续加规则。

## 先归因

失败可能属于：

- Prompt 表达；
- Workflow 结构；
- Example 教学；
- Skill discovery/packaging；
- Case / Evaluation；
- Harness / Runtime；
- Tool / 权限 / 网络；
- 模型能力；
- 用户目标本身。

只修改真正拥有问题的层。

## 最小维护循环

```text
缺口证据
→ 可证伪假设
→ 最小候选修改
→ Evaluation
→ keep / reject / defer
→ 更新唯一 owner
```

不在多个文件复制同一规则。

## Evidence 不自动拥有指令权

一条经验进入长期 Guidance 前，至少问：

- 是否有可信证据；
- 是否能脱离原题材成立；
- 是否有边界；
- 它会改变哪个真实决策；
- 长期收益是否高于 context / maintenance 成本；
- 是否经过独立 Evaluation。

否则停留在 Observation、Development Case 或项目知识。

## 防止腐化

- 不因单例制造 universal rule；
- 不让 Examples 只增不减；
- 不保留没有消费者的字段、状态和兼容入口；
- 不把历史 observation 写成当前事实；
- 不用 Prompt 堆叠掩盖 Tool/Harness 问题；
- 不在普通任务中加载完整维护历史。

## 结束

满足任一条件即停止：

- 最小修改已解决缺口并通过必要验证；
- 证据不足，需要新观察；
- 候选没有改善；
- 新规则造成不可接受回归；
- 问题已确认属于非 Guidance 层。
