# Examples、Few-shot 与 Evals

本参考用于决定何时需要示例、示例应该如何写，以及如何避免把示例变成另一种过拟合规则。

## 默认先不用 Few-shot

如果简短 instruction 已经能稳定产生正确行为，不额外加入 example。

Example 会占上下文，而且会形成实际行为上限和模仿倾向。只有它能提供独立信息时才值得存在。

## 两类示例

### Demonstration

默认形式：

```text
真实或代表性输入
→ 期望输出 / 期望处理
```

适合：

- 输出格式；
- 稳定风格；
- 常见决策；
- 规则容易理解，但需要展示具体行为形状。

示例应简洁，并覆盖不同输入，不要堆高度重复的同类案例。

### Contrastive example

只用于微妙边界：

```text
情境
→ 一个表面合理但错误的处理
→ 为什么它错在机制上
→ 更好的处理
→ 可迁移区别
```

适合：

- 错误答案表面也很顺；
- 模型容易把两个相邻概念混淆；
- 单纯新增一句抽象规则仍不稳定。

不要把所有 example 都写成 bad/good；对照教学本身也会增加上下文和暗示。

## 优先从真实实践提炼，而不是凭空编例子

真实 problem slice、失败记录、review 和用户纠正是高价值原料，因为它们能说明模型实际上在哪些地方犯错。

但不要原样把整个事故复制进运行包。先抽掉：

- 项目专有名称；
- 偶然工具参数；
- 无关风格；
- 一次性的环境细节。

只保留要教的主要行为变量。

一个 canonical example 最好只承担一个主要教学目标。

## Example 的准入标准

进入运行时 examples 前，至少确认：

- 该行为很难仅靠短规则稳定表达；
- 在不同任务或载体中具有迁移价值；
- baseline 或当前 Skill 确实出现过相关失败；
- example 没有偷偷引入不必要的风格或流程偏好；
- instructions 与 example 完全一致；
- 它提供了其他 example 没有的独立信息。

如果删除该 example 后没有可观察退化，应认真考虑移除。

## Examples 与 Evals 分离

`examples` 是教学材料。

`evals` 是考试。

不要把相同案例既作为主要教学例，又作为唯一验收题。

至少测试：

- 应直接触发的请求；
- 间接表达同一目标的请求；
- 不完整输入；
- 不应该触发的请求；
- 容易越界或幻觉的边缘情况；
- Skill 触发后真正的行为不变量。

## Cross-carrier generalization

如果 example 教的是底层机制，eval 应尽量换载体。

例如教学案例：

> Agent 后续读取文件恢复 prompt，不能反证初始 delivery 完整。

测试时不要再次使用 Pi prompt。可以换成：

- 文件同步；
- API consumer；
- wrapper 重试；
- 配置热加载；
- 后台任务恢复。

如果模型只能在原始题材上正确回答，它学到的更可能是表面模板。

## Ablation

当 examples 开始增多时，比较：

```text
baseline
vs
Skill without example X
vs
Skill + example X
vs
minimal example set
```

评估具体失败率和可迁移行为，不只看“整体感觉更好”。

Examples 不是永久资产；它们和规则一样应该接受删除测试。
