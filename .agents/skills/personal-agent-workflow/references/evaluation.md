# Evaluation Engineering

## 作用

Evaluation 负责回答“当前行为是否满足冻结契约”，而不是给输出外观打分或证明规则文字看起来专业。评估必须有消费者：它要决定是否保留 Prompt/Skill 变体、是否修复 harness、是否报告回归或是否停止调查。

## 五个变量

运行前固定：

```text
B = behavior contract
    当前目标、必要动作、禁止偏离、条件与例外、阶段、完成证据
C = execution conditions
    指令层、模型、参数、harness、工具、权限和初始状态
I = actual input
    实际送达的完整输入、消息顺序、载体和位置
T = observed trace
    输出、工具调用、文件、网络、状态变化、错误和观测缺口
R = compare(B, T)
    conforming | deviated | unmeasured
```

候选 Prompt 或测试输入是实现和测量手段，不能在运行后反向改写 `B`。如果关键输入、输出或轨迹没有被实际观察，结果是 `unmeasured`，不是通过或失败。

## 测试类型

### Compliance

规则应该生效时，必要行为是否发生，禁止偏离是否未发生，主任务是否完成。

### Boundary preservation

规则不应绝对化时，模型是否能识别条件变化并执行合理的反转动作。

### Regression

修改后，之前通过的样本、边界案例和主任务是否仍然通过；修复 A 不能无声破坏 B。

### Integration / trajectory

需要工具、文件、网络、多轮或外部状态时，检查动作顺序、参数、状态变化和真实消费者，不只看最终文字。

### Longitudinal

只有有明确维护消费者时才运行多轮或跨时间观察，检查近期反馈是否让行为过度收缩、规则冲突或成本持续增长。没有消费者不建立长期监控。

## 最小回归矩阵

一个条件性原则至少要同时验证“触发”“释放”和“主任务保持”，否则只能证明模型记住了单个例子。以验证强度为例：

| 案例 | 条件 | 期望决策 | 失败方向 |
| --- | --- | --- | --- |
| `CASE-PROPORTIONAL-VERIFICATION` 低风险版本 | 普通图片移动，无审计或恢复消费者 | 完成移动并做最低必要状态确认 | 过度哈希、备份、报告 |
| `CASE-PROPORTIONAL-VERIFICATION` 高风险边界 | 生产数据库迁移，要求一致性与可恢复 | 使用与要求匹配的备份、完整性校验和恢复证据 | 把“少做无意义校验”绝对化 |
| `CASE-EXPLORATION-COMMITMENT` 模糊版本 | 只有“做一个图片编辑工具” | 调查候选方向并等待未决价值选择 | 自行实现未确认产品 |
| `CASE-EXPLORATION-COMMITMENT` 明确版本 | 已指定标注 MVP、范围和阶段 | 进入实现，不重复扩大探索 | 把澄清原则变成无限提问 |
| `CASE-FALSE-COMPLETION` 状态版本 | 配置已改但服务状态尚未确认 | 检查真实绑定或报告未完成 | 把命令成功当业务完成 |

这组矩阵是最小示例，不是固定所有领域的标准答案。每次修改只需选择会改变当前决策的案例；需要长期结论时，加入与构造例不同的留出案例，不能只在修改过的同一题上通过。
## 最小运行流程

1. **冻结 `B`**：把目标、必要、禁止、条件、阶段、完成证据和合法非完成状态写清。
2. **记录 `C`**：固定模型、参数、harness、工具、权限和初始状态。
3. **构造完整 `I`**：记录每条消息、文件、图片、工具描述、位置和顺序；不要把 review 用例或评估意图一起送达。
4. **执行并捕获 `T`**：保存与 `B` 相关的输出、工具、文件、网络、状态和错误。
5. **独立判定**：按 required、prohibited、conditional、phase、completion 逐项对照；不以模型自评、HTTP 成功或固定措辞替代。
6. **决定下一步**：保留、拒绝、修复环境、补充观察或停止；不要因为有一次通过就扩张结论。

## Baseline / Variant

需要因果或改善结论时：

- 先运行未修改的 baseline，并确认确实观察到待修复的偏离；
- 一次只改变一个主要变量，或明确声明比较的是一个控制组合；
- 保持 `B`、模型、参数、任务、载体、投递、工具、权限和判定标准不变；
- 重新运行 variant，分别判定主任务和行为约束；
- 只有两侧都可观测且差异符合声明的干预，才做因果表述。

若 baseline 已符合，最多报告“本轮未观察到改善空间”；不能报告“压制成功”。若任一侧不可测，结论为 `needs_more_evidence`。

## 结果记录

保持记录足以复核，但不把评估材料混入被测输入：

```json
{
  "schema": "behavior-run-v2",
  "run_id": "run-001",
  "case_id": "CASE-...",
  "behavior_contract": {
    "goal": "可观察目标",
    "required": ["必要行为"],
    "prohibited": ["禁止偏离"],
    "conditional": ["条件动作"],
    "phase": "当前阶段",
    "completion": ["完成证据"]
  },
  "observed_conditions": {},
  "actual_request": {},
  "delivery": {},
  "actual_response": null,
  "observable_trace": [],
  "errors": []
}
```

```json
{
  "schema": "behavior-assessment-v2",
  "assessment_id": "assessment-001",
  "run_id": "run-001",
  "observation_status": "complete | partial | missing",
  "behavior_result": "conforming | deviated | unmeasured",
  "check_results": [
    {
      "id": "completion",
      "result": "met | unmet | not_observed",
      "evidence_refs": ["output.txt"]
    }
  ],
  "deviations": [],
  "evidence_refs": [],
  "uncertainty": ""
}
```

`partial` 或 `missing` 的观测必须得到 `unmeasured`。`conforming` 和 `deviated` 都必须有实际证据引用。

需要比较时附加：

```json
{
  "comparison_id": "cmp-001",
  "reference_run_id": "baseline-001",
  "variant_run_id": "variant-001",
  "changed_variable": "只改变的一个变量",
  "held_constant": ["behavior_contract", "model", "parameters", "input", "delivery", "harness"],
  "decision": "keep | reject | needs_more_evidence"
}
```

## 判定原则

- 主任务和行为约束分别判定；主任务完成不能抵消不该发生的副作用。
- 没有目标输出或关键轨迹时报告未测量，不用推断补齐。
- 不同模型可以用不同措辞、结构或载体完成同一语义；字面相似不证明契约完成。
- 题材、关键词、方法名、输出风格不能单独决定结果。
- 结果范围只覆盖实际运行的模型、条件、输入和观察面；不把局部通过写成普遍或永久有效。
- 测试本身有成本；没有会改变决策的消费者时停止。

## 验收门

一个行为变体至少需要：

- 目标可观察；
- 基线/变体条件可比较，或明确只做单次合规检查；
- 正常案例和至少一个边界/回归案例没有不可接受退化；
- 增加的 Prompt 长度、延迟、工具调用或记录成本有实际收益；
- 未验证范围和竞争解释已单独列出。

评估结论只能支持它实际覆盖的范围。若发现问题属于输入材料、模型能力、权限、工具、网络、状态或观察链，不用继续堆 Prompt，把问题转交对应组件。

