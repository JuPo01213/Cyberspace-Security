# Skill Evolution：技能演化流程

## 职责

Skill Evolution 负责回答：

> **一个已经存在的 Skill，如何在真实使用中持续吸收经验并形成下一版本。**

Skill 不是一次创建完成的静态文档，而是在使用中不断压缩经验的行为资产。

## 生命周期位置

```text
Skill Construction
        ↓
Skill Usage
        ↓
Case
        ↓
Skill Evolution
        ↓
Candidate Change
        ↓
（必要时）Evaluation
        ↓
Skill vNext
```

Evaluation 不是 Evolution 的前置条件，而是判断候选变化是否值得保留的工具。

# 演化来源

## 1. 真实使用反馈

主路径：

```text
Skill 被调用
↓
真实任务执行
↓
结果、用户反馈、失败、边界出现
↓
Case
↓
判断是否需要演化
```

真实使用天然提供检验材料。

不要为了验证 Skill 人工制造脱离实际的问题。

## 2. 历史上下文回溯

当用户完成一次复杂工作后，希望把经验固化成 Skill：

```text
完整工作上下文
↓
提取关键决策
↓
识别可迁移模式
↓
构造 Replay Case
↓
抽象 Skill
```

检验材料来自已有上下文：

- 对话过程；
- 用户纠正；
- 工具调用；
- 文件变化；
- 最终产物。

不是凭空设计测试。

# 执行流程

```text
1. 获取演化信号
2. 读取相关 Case
3. 判断问题归属
4. 提取可迁移关系
5. 形成 Candidate Change
6. 修改 Skill
7. 必要时 Evaluation
8. 发布 Skill vNext
```

## 1. 获取演化信号

来源：

- 使用失败；
- 用户修正；
- 新场景需求；
- 重复出现的人工操作；
- 历史工作复盘。

## 2. 读取相关 Case

Case 是经验，不是规则。

不要直接把一次失败变成永久 Prompt。

## 3. 判断问题归属

首先判断变化应该属于：

- Prompt；
- Example；
- Workflow；
- Skill boundary；
- Harness / Runtime；
- Tool 能力。

不属于 Skill 的问题不要通过增加文本修复。

## 4. 提取可迁移关系

从：

```text
Specific Case
↓
抽象机制
↓
Candidate Principle / Workflow
```

不要：

```text
Specific Case
↓
匿名化
↓
假装通用规则
```

## 5. Candidate Change

候选变化可能是：

- 增加原则；
- 删除错误规则；
- 调整边界；
- 增加 Example；
- 重构 Skill 结构。

## 6. 修改 Skill

保持：

- 自包含；
- 单一 owner；
- Git 可追踪。

每个 Skill repository 自己管理版本演变。

## 7. 必要时 Evaluation

只有当变化存在不确定性时使用：

```text
Candidate Change
↓
Evaluation
↓
keep / revise / reject
```

简单明确的修复不需要人为制造 Evaluation 流程。

## 完成标准

一次 Skill Evolution 完成时：

- 已明确演化来源；
- Case 与事实分离；
- 已完成正确归因；
- 已形成可迁移变化；
- 修改位置符合 owner；
- 必要时完成 Evaluation；
- Skill 已产生新的 Git revision。
