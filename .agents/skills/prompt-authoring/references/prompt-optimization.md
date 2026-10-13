
# Prompt 优化与干预比较手册

## 定位

本手册只处理已经观察到的 Prompt 行为偏离。它不重新定义任务，不把输入题材当成结论，不把研究说明当成修复，不在没有消费者的情况下制造优化记录。输入构造和判定由 [Prompt 行为验证、输入构造与语料取用手册](prompt-validation.md) 负责。

## 触发

只有以下事实之一成立才进入本手册：

- `T` 已显示目标偏离冻结的 `B`；
- 生产中出现了可复现的行为问题；
- 用户明确要求比较或优化已有 Prompt。

没有具体偏离时不凭直觉加长 Prompt。先交付当前版本，或只报告尚未测量。

## 循环

~~~text
冻结 baseline
→ 写出一个可证伪的偏离假设
→ 选择一个主要变量
→ 生成完整 variant
→ 用相同条件重放
→ 独立比较 B 与 T
→ 保留有效改动或停止
~~~

机制归因每轮只改变一个主要变量：目标句、一个约束、一个边界事例、阶段结构、锚点位置、输入分层或输出契约。完整方案比较的边界见“选择最小控制”。模型、参数、任务输入、载体、投递路径、harness 和判定标准保持不变。无法冻结这些条件时，只报告两次实际观察，不作因果表述。

## 归因

先判断偏离属于哪一层：

- Prompt 表达：目标、边界、阶段、输出或失败出口未表达清楚；
- 输入材料：事实缺失、污染、排序、长度、载体或位置不符合任务；
- 模型能力：换表达仍无法完成；
- harness/runtime：工具、权限、schema、状态、网络或观察链有问题。

只有第一层生成 Prompt variant。其他层转交对应组件，不用文字堆叠掩盖。

## 选择最小控制

从 [原则与案例手册](input-corpus.md) 选择与已观察偏离对应的原则，读取同节的构造方法、反例与案例，再生成候选。机制和案例不在本文件重复列成映射表；选择取决于输入中的行为关系，不取决于原题名。

机制对照只改变该机制的一个明确变量。若当前决策是比较完整方案，允许一个声明清楚的控制组合，保持其他条件和验收不变，但只能把改善归于组合，不能归于某条规则。不能通过把多个未声明变化改名为“一个方案”隐去环境或任务差异。

“更严格”“更专业”“更长”不是变量定义，也不是收益证据。

## 记录

脚本记录只保存实际消费者需要的内容：

~~~json
{
  "schema": "behavior-comparison-v1",
  "comparison_id": "cmp-01",
  "reference_case_id": "case-baseline",
  "changed_variable": "只改变的一个变量",
  "held_constant": ["model", "parameters", "input", "delivery", "harness", "behavior_contract"],
  "baseline_run_id": "run-a",
  "variant_run_id": "run-b",
  "baseline_result": "conforming | deviated | unmeasured",
  "variant_result": "conforming | deviated | unmeasured",
  "decision": "keep | reject | needs_more_evidence"
}
~~~

只有两个运行都可观测，且差异满足声明的干预条件，才允许 `keep` 或 `reject` 的因果结论；组合比较的结论必须限定为组合效果。任一侧为 `unmeasured` 时，决策只能是 `needs_more_evidence`。

## 保留标准

保留 variant 必须同时满足：

- 目标偏离消失或明确改善；
- 原本符合的样本没有不可接受回归；
- 增加的长度、延迟或工具成本有实际收益；
- 改动仍服务当前任务，不把测试输入、可能输出或研究说明塞进生产 Prompt。

一次无收益就停止该方向。连续改写没有新增证据时停止，不建立“为了证明认真”的额外字段。

## 交付

交付完整的：

- `baseline_prompt`
- `variant_prompt`
- 变化的一个变量
- 真实输入和运行条件
- baseline/variant 的实际输出和轨迹引用
- `conforming | deviated | unmeasured` 结果
- `keep | reject | needs_more_evidence` 决定
- 未验证范围

不要只交付修改建议或评估分数。

