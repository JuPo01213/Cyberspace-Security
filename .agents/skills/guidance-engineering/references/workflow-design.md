# Workflow Design

## 职责

Workflow Design 回答：

> **当行为不再是一个简单输入→输出时，怎样组织阶段、状态、分支、依赖、验证和停止。**

Prompt 负责把 Workflow 表达给模型；Workflow 本身负责行为结构。

## 不再独占“行为要求”

所有 Guidance 在设计前都需要基本目标、边界和完成证据；这些是共同起点，不属于 Workflow 专有。

Workflow 只在复杂度出现后扩展这些要求，例如：

```yaml
trigger: 何时进入流程
inputs: 必要输入
stages: 阶段
state: 会改变下一步动作的状态
dependencies: 前置/后置条件
branches: 条件分支
completion: 整体完成门
failure_exit: 各失败路径怎样结束
recovery: 必要时如何恢复
```

只保留真正影响决策的字段。

## 设计方法

### 1. 先确认为什么需要 Workflow

出现以下任一情况才值得正式设计：

- 多阶段；
- 工具调用序列；
- 条件分支；
- 跨轮状态；
- 前后置依赖；
- 失败恢复；
- 单一步骤成功不等于整体完成。

否则继续使用简单 Prompt。

### 2. 划分最少阶段

只有状态或责任真的变化时才分阶段。

```text
Frame → Acquire → Decide → Act → Verify → Close
```

可以作为思考骨架，不是固定模板。能删则删，能合则合。

### 3. 为每一步定义输入与出口

每一步至少问：

- 为什么存在；
- 消费什么；
- 产生什么可观察结果或状态；
- 什么条件继续；
- 什么条件跳过；
- 什么条件停止；
- 失败后是否需要恢复。

### 4. 按事实分支

分支依据必须是可观察事实：

```text
已有可信证据满足完成条件
→ 跳过重复验证

风险/恢复要求提高
→ 增加对应保护和证据

关键事实仍缺失
→ 只获取该事实或返回合法非完成状态
```

不要按题材、工具名字或“看起来专业”分支。

### 5. 只保存必要状态

状态存在的理由只有一个：**它会改变后续动作。**

没有消费者的状态、日志和字段不进入 Workflow。

### 6. 定义整体完成门

不要把某个命令成功、文件创建或 API 200 当作整体完成，除非它就是用户目标。

整体 completion 应绑定真实消费者和最终结果。

## 如何写回 Prompt

Workflow 设计完成后，用 [prompt-engineering.md](prompt-engineering.md) 把真正需要模型知道的：

- 阶段；
- 条件；
- 状态；
- 工具使用；
- 完成/失败出口；

编译成可读 instructions。

不要把设计文档全文机械塞进 Prompt。

需要示范某个决策或 trajectory 时，调用 [example-engineering.md](example-engineering.md)。

## 什么时候封装成 Skill

Workflow 反复服务同一类能力、存在稳定触发边界、需要 supporting resources 或长期维护时，再进入 [skill-building.md](skill-building.md)。

多个相关 Workflow 可以由一个 Skill 路由，不因“流程不同”自动拆 Skill。

## 验证

任何关于阶段、顺序、分支、状态或停止条件的“改进”都必须由 [evaluation.md](evaluation.md) 实测。
