# 决策问卷协议

Decision Questionnaire 是 Requirement Discovery 的批量人机交互界面，不是项目启动时的一次性需求表。

它可以在 Design、Implementation、Review、Acceptance 的任意 Convergence Point 出现。

## 目标

把：

`多个价值未知 → 多轮聊天 → 机械确认`

改成：

`模型先判断 → 当前 Frontier → 推荐默认 → 用户只改例外 → 一次提交`

## Invariant：问卷用于审阅模型已经完成的判断

问卷不是把模型不会做的思考推给用户。

进入问卷前，Agent 应尽量完成：
- 仓库/现状研究；
- 事实核查；
- 候选方案筛选；
- 推荐答案；
- 简短用户层理由。

## Current Frontier

若多个决策彼此独立，可以放在同一张问卷。

若 B 的合理选项取决于 A 的答案，则 B 不应和 A 在同一 frontier 中伪装成独立问题。提交 A 后再重新计算下一轮。

这兼顾批量效率和信息正确性。

## Attention Filtering

不是所有选择都值得进入问卷。

进入问卷通常满足至少一项：
- 不同答案会改变用户可感知行为；
- 会长期限制用户能力；
- 影响数据、隐私、费用、兼容性或不可逆结果；
- 用户已经表达过相关偏好但当前实现可能偏离；
- 需求来源低置信度或存在矛盾。

内部工程细节默认由 Agent 决定。

## 每题结构

建议包含：
- 一个自然语言问题；
- 一个短使用场景；
- 2–4 个用户层选项；
- 模型推荐项（默认预选）；
- 推荐理由；
- “不确定”；
- 自定义输入。

不需要单独的“接受推荐”按钮。

## 默认语义

- 未修改推荐项 → `default_accepted`；
- 改选其他项 → `overridden`；
- 自定义 → `custom`；
- 不确定 → `uncertain`。

`uncertain` 不能自动退回推荐值。

## 一次性提交

提交结果应结构化，例如：

```json
{
  "questionnaire_id": "editor-behavior-01",
  "decisions": [
    {
      "id": "document-opening",
      "status": "default_accepted",
      "recommended": "single",
      "answer": "single"
    },
    {
      "id": "overwrite",
      "status": "custom",
      "recommended": "ask",
      "answer": "同名时自动加序号，不覆盖旧文件"
    },
    {
      "id": "autosave",
      "status": "uncertain",
      "recommended": "off",
      "answer": null
    }
  ]
}
```

一次提交后由 Agent 更新 Requirement State，并重新计算是否还有下一 frontier。

## 推荐理由

推荐理由说明用户能看到的结果、复杂度或 trade-off，不向用户倾倒 reducer/schema/线程模型等内部理由。

## “不确定”是有效答案

“不确定”表示用户现在不愿或不能决定。它不是失败，也不是授权模型偷偷采用推荐。

Agent 应判断：
- 是否可以采用可逆临时假设继续；
- 是否需要 Prototype；
- 是否阻塞当前路径；
- 是否推迟到后续 Convergence Point。

## 与权限分离

需求问卷表达的是产品意图，不自动等于对文件删除、生产部署、付款、外部消息发送等运行时动作的授权。

理解 ≠ 授权；目标 ≠ 行动许可。

## 网页模板

`templates/decision-questionnaire.html` 是无依赖单文件模板：
- 默认推荐预选；
- 支持其他选项、自定义、不确定；
- 一次提交；
- 输出结构化 JSON；
- 同时触发浏览器 `CustomEvent` 与 `postMessage`，方便未来 Harness 嵌入。
