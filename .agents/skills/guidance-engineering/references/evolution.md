# Evolution Engineering

## 职责

Evolution 只回答：

> **什么时候应该修改活动 Guidance，以及证据如何升格为长期规则。**

它不重新定义 Evaluation 方法；需要比较、回归和判定时调用 [evaluation.md](evaluation.md)。

## 正常使用与维护分开

```text
正常使用
Guidance + task → run/result → 停止

维护
observation/case
→ hypothesis
→ candidate change
→ evaluation
→ keep / reject / defer
→ 更新唯一权威位置
```

普通任务、一次失败或一条反馈不会自动修改 Skill。

## 何时进入维护

至少满足之一：

- 用户明确要求审查、重构、补强或优化；
- 重复或高影响偏离已有足够证据；
- 外部接口、模型、平台、能力边界发生变化；
- 已定义维护周期到达且本次检查有明确消费者。

没有具体缺口时，不凭“可以更完整”继续加规则。

## 先归因，再改资产

先判断缺口属于：

- Prompt 表达；
- Workflow 结构；
- Example 教学；
- Skill 封装/路由；
- Evaluation / case 设计；
- Harness / Runtime；
- Tool / 权限 / 网络；
- 模型能力；
- 用户目标本身尚未确定。

只修改真正拥有该语义的层。

## Observation 不自动拥有指令权

一条经验要成为长期 Guidance，至少需要：

- 有真实或可信证据；
- 能抽掉偶然题材后仍成立；
- 有明确适用边界或反例；
- 能指出会改变哪个真实决策；
- 加入后长期收益高于上下文与维护成本；
- 能通过独立 Evaluation 验证。

证据不足时，保留为 observation / development case / project knowledge，不升格。

## 选择最终载体

通过验证后，把规则放到**最能承担它的层**：

- 一次性表达 → Prompt；
- 阶段/状态/分支 → Workflow；
- 示范最有效 → Example；
- 可复用能力边界与路由 → Skill；
- 可机械判断/执行 → schema / script / test / lint / runtime enforcement。

不要把本来能机械保证的不变量继续写成自然语言提醒。

## 单一维护问题

一次修改尽量只回答一个问题：

```text
缺口是什么？
证据是什么？
谁是消费者？
唯一 owner 在哪里？
最小候选修改是什么？
什么独立测试能推翻它？
```

“更完整”“更专业”“更强”不是维护问题。

## 维护循环

1. 固定当前版本与缺口证据。
2. 形成可证伪的候选变化。
3. 修改唯一 owner，不复制到多个文件。
4. 交给 Evaluation 做目标、边界与必要回归。
5. 改善成立且成本可接受 → keep。
6. 无改善、证据不足或出现不可接受回归 → reject/defer。
7. 记录未覆盖范围，然后停止。

Baseline/variant、holdout、cross-carrier 等具体测量方法全部由 Evaluation 负责，本文件不重复。

## 防止腐化

- 不因单个案例制造 universal rule。
- 不保留没有消费者的流程、字段或历史兼容入口。
- 不把历史观察写成当前事实。
- 不为“保险”在多个文件复制同一规则。
- 不让 examples 只增不减。
- 不用 Prompt 堆叠掩盖 Harness/Tool/环境故障。
- 不在普通任务中加载完整维护历史。

## 结束

维护在以下情况之一停止：

- 缺口已被最小修改与独立验证覆盖；
- 证据不足，需要新的真实观察；
- 修改没有消费者或没有改善；
- 新规则造成不可接受回归；
- 问题归属已转移到非 Guidance 层。
