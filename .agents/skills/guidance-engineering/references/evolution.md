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

## 从具体案例到通用原则

Evolution 拥有“经验升格为通用原则”的过程。

正确链条不是：

```text
具体失败
→ 把失败改写成一条新规则
```

而是：

```text
具体案例
→ mechanism candidate
→ 找相邻案例 / 反例
→ general principle candidate
→ generic teaching example
→ 独立 eval
→ active guidance
```

### 1. 从具体案例抽出机制

读取 Case Engineering 已经产出的 mechanism candidate。先确认真正决定行为的是条件关系，而不是题材、品牌、工具或偶然步骤。

### 2. 从机制提炼原则

General Principle 必须至少包含：

```yaml
principle: 要指导的通用行为
applies_when:
  - 哪些事实成立时适用
action:
  - 应采取或避免什么
boundary:
  - 哪些关键条件变化后原则应减弱、反转或停止适用
evidence:
  - 什么观察支持该原则
forbidden_generalization:
  - 绝不能把它扩大成什么
```

原则必须比原案例更抽象，但仍然保留决定行为的条件。

例如从：

```text
移动几张普通图片时，Agent 自动生成哈希、备份和审计报告
```

不应直接得到：

```text
不要做额外验证
```

而应得到类似：

```text
当任务低风险、可逆，且不存在审计/恢复消费者时，
验证应保持最低充分；
当风险、恢复要求或消费者改变时，提高验证强度。
```

### 3. 用原则重新生成通用教学案例

原则形成后，交给 [example-engineering.md](example-engineering.md) **重新构造** Generic Teaching Example。

不要简单把源案例匿名化。优先换掉原领域与载体，只保留原则需要的决策结构。

这样可以检验：我们到底提炼出了原则，还是只学会了“那次图片移动事故”。

### 4. 再回到具体世界验证

Generic Teaching Example 用来教，不用来证明。

由 [evaluation.md](evaluation.md) 使用：

- 原领域但不同具体输入；
- 不同领域 / cross-carrier 输入；
- 原则应生效案例；
- 原则应释放或反转的 boundary case；

验证原则本身，而不是验证教学例子能否被复述。

只有经过这一步，principle candidate 才有资格进入活动 Guidance。

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
