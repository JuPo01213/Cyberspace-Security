# Case Engineering

## 职责

Case Engineering 管理**Development Case 与 Eval Case**。

它负责把真实事件或构造场景转成可用于分析、压测和回归的测试材料；它不负责生产 Teaching Example。Teaching Example 由 [../example-engineering.md](../example-engineering.md) 从合适的 development case 中选择和改写。

## 三种对象

### Observation

真实发生过的输入、输出、tool trace、环境和用户纠正。

只记录事实与不确定性，不自动获得规则权。

### Development Case

为了理解机制、设计 Guidance 或定位失败而整理的案例。

它可以来自真实 observation，也可以 synthetic。它不一定进入长期测试集。

### Eval Case

为了测量某个明确 behavior contract 而保存的测试材料。

只有有稳定消费者、可观察判定标准，并能改变 keep/reject/revise 决策时，才值得进入长期回归集。

## 从 Observation 到 Case

1. 保存原始目标、上下文、实际轨迹和影响。
2. 区分观察、推断、假设。
3. 提取唯一主要机制：跳过、提前、替换、假完成、范围漂移、条件误判等。
4. 去除不会改变决策的项目专名、品牌和偶然参数。
5. 保留真正决定行为的权限、风险、可逆性、阶段、消费者、已有证据和完成条件。
6. 根据用途生成 development case 或 eval case。

若要把其中某个机制用于教学，再交给 [../example-engineering.md](../example-engineering.md)，不要直接把完整事故复制进生产 Prompt。

## Case Card

```yaml
id: CASE-...
purpose: 这个 case 要测或分析什么
source: real-observation | synthetic | derived
contract_ref: 对应 behavior contract / requirement
input: 可实际投递的输入
critical_conditions:
  - 会改变正确决策的条件
expected_observation:
  - 可观察行为，不要求固定措辞
failure_modes:
  - 什么构成偏离
role: development | compliance | boundary | regression | integration | longitudinal
evidence:
  - 要捕获的输出/工具/文件/状态
status: candidate | active | historical
```

Case card 是测试资产，不进入被测 Prompt。

## 机制分类

需要组织大案例库时，可按机制而不是题材索引：

- 依赖绑定；
- 阶段与状态；
- 目标与范围；
- 证据与完成；
- 分解与组合；
- 表示与接口；
- 示例与续接；
- 显著性与信息密度；
- 反馈与资源边界；
- 任务字段与交付形态。

分类只是检索索引，不构成新的规则体系。

## Boundary Case

条件性原则至少需要测试“规则生效”和“规则释放/反转”。

Boundary case 应改变一个真正影响决策的事实，而不是只换名词。

例如测试“验证强度是否按风险变化”时，变化的是风险、可逆性、恢复要求或消费者，而不是把“图片”换成“文档”。

## Holdout 与 Cross-carrier

Teaching Example 和 Eval Case 分离。

如果要测试底层机制是否泛化：

- 保留未进入生产 guidance 的 holdout；
- 尽量换题材、工具或表面形式；
- 保持真正的行为机制不变。

这能降低“只记住教学题”的假象。

## 案例库

[evaluation/case-library.md](case-library.md) 是历史/构造语料库，只按需定位读取，不作为默认上下文，也不自动代表当前活动规则。

是否进入生产 Example，由 Example Engineering 决定；是否进入长期回归集，由 Evaluation 的消费者与证据需求决定。
