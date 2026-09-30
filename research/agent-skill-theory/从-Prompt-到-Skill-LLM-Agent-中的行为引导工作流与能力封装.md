# 从 Prompt 到 Skill：LLM Agent 中的行为引导、工作流与能力封装

> 状态：理论稿初版  
> 性质：概念框架与工程解释，不等同于任何单一平台的官方术语定义。

## 摘要

随着大语言模型从单轮问答系统发展为能够读取文件、调用工具、持续执行任务并根据环境反馈继续行动的 Agent，传统的 Prompt Engineering 已不足以单独描述整个 Agent 行为系统。Prompt、Workflow、Skill、Tool、Harness、Context Engineering 等概念开始同时出现，但它们经常被混为一谈。

本文尝试建立一个更清晰的层级模型：

**Prompt = 如何向模型表达行为要求。**  
**Workflow = 行为本身如何组织和推进。**  
**Skill = 把某类能力及其 Prompt、Workflow 与支持资源封装成可发现、可复用的能力单元。**

在这一模型中，Skill 不是模型参数中新训练出的“技能”，也不等同于一段更长的 Prompt。它是 Agent 生态中的能力封装：宿主可以发现它、选择它、加载它，并利用其中的指令、参考资料、脚本、案例和工具指导来支持某类任务。

与此同时，Skill 仍处在 Harness / Runtime 已有能力边界之内。它可以通过改变模型行为来影响模型如何使用文件、工具和参考资料，但不能仅凭自身文本反向创造宿主没有提供的上下文机制、权限机制或运行时能力。

## 问题的起点

在传统 LLM 使用方式中，一个任务通常可以简化为：

~~~text
用户输入
→ Prompt
→ 模型生成
~~~

此时 Prompt 几乎承担了全部显式行为引导。

但 Agent 系统不是一次生成，而更接近一个循环：

~~~text
观察当前状态
→ 模型判断
→ 读取资料 / 调用工具 / 执行动作
→ 获得新的 observation
→ 再次判断
→ 直到满足完成条件
~~~

因此，一个 Agent 要稳定完成复杂任务，仅仅写一段“更好的 Prompt”往往不够。行为需要被组织成可持续执行的过程，也需要被封装为可重复利用的能力。

这正是 Workflow 和 Skill 出现的背景。

## Prompt：行为要求的语言表达

Prompt 最直接的作用，是向模型表达当前应该如何行动。

它通常处理：

- 目标是什么；
- 哪些行为必须发生；
- 哪些行为禁止发生；
- 什么条件触发某个分支；
- 输出应该满足什么格式或语义要求；
- 什么证据可以支持完成声明；
- 是否提供 few-shot 或 contrastive examples。

例如：

~~~text
先复现问题，再提出根因假设。
没有证据时不要直接修改代码。
修复后验证与目标行为对应的实际结果。
~~~

这些内容本质上都是 Prompt Engineering：它们通过语言形式直接影响模型接下来的判断与生成。

因此可以把 Prompt 简化理解为：

> **对模型行为要求的表达层。**

Prompt 本身并不要求一定存在 Skill，也不要求存在复杂工作流。一次性的用户指令、本地模板、系统提示词都可以是 Prompt。

## Workflow：行为如何展开

Workflow 关注的不是“这句话该怎么写”，而是：

> **完成目标时，行为应该怎样组织和推进。**

例如：

~~~text
复现
→ 缩小范围
→ 建立假设
→ 验证假设
→ 修改
→ 回归验证
→ 收口
~~~

这里描述的是任务过程，而不是具体措辞。

同一个 Workflow 可以通过不同 Prompt 表达；同一个 Prompt 也可能只描述 Workflow 的其中一个阶段。

因此：

> **Prompt 描述行为要求；Workflow 描述行为结构。**

当 Agent 任务开始涉及分支、阶段、状态迁移、失败出口、验证条件和多轮执行时，Workflow 通常比单纯的 Prompt 更适合作为设计单位。

## Skill：能力的封装

Skill 这个词容易造成误解，因为中文“技能”容易让人联想到模型本身通过训练获得了一项新能力。

在 Agent 生态中，更准确的理解是：

> **Skill 是一个可发现、可加载、可复用的能力单元。**

它面向的是能力层，而不是底层实现层。

一个 Skill 可以包含：

~~~text
Skill
├── Prompt / Instructions
├── Workflow
├── References
├── Examples / Cases
├── Scripts
├── Assets
└── Tool-use guidance
~~~

所以 Skill 并不等于 Prompt，也不等于 Workflow。

它表达的是：

> “当用户需要完成这一类任务时，Agent 有一套已经准备好的方法和资源可以使用。”

例如，一个“软件工程”Skill 对用户来说表达的是：

> Agent 会按照一套稳定方法处理功能开发、Bug、重构、Review 和验证。

至于这个能力内部究竟使用多少 Prompt、多少 reference、多少脚本，是实现细节。

因此可以进一步区分：

~~~text
Prompt
= 如何向模型表达行为要求

Workflow
= 行为本身如何组织和推进

Skill
= 把某类能力及其 Prompt、Workflow、资源封装成可发现单元
~~~

这是本文最核心的三层关系。

## 为什么这一整包东西叫 Skill

Skill 的命名描述的是它对 Agent 的语义，而不是它在文件系统中的组成。

从文件系统看，它可能只是一组 Markdown、脚本和资源。

从 Transformer 看，其中大量内容最终会通过上下文影响生成。

但从 Agent 的能力模型看，它表达的是：

> **“我会做这一类事情。”**

因此 Skill 是一种 capability abstraction——能力抽象。

这也解释了为什么 Skill 不应该按每一个步骤机械拆分。

如果把“调试”“代码审查”“Git”“测试”“需求分析”全部拆成独立 Skill，能力目录会迅速碎片化，而这些内容在真实任务中往往属于同一条连续工作流。

更合理的做法通常是：

~~~text
一个能力级 Skill
→ 一个主入口
→ 内部按任务、阶段和事件路由到 references
~~~

也就是说：

> **Skill 的粒度更接近能力；reference 的粒度更接近方法、阶段和专项知识。**

## Skill 与 Prompt Engineering 的关系

Skill 的行为控制核心高度依赖 Prompt Engineering，因为它必须通过 instruction 告诉模型：

- 什么时候采用这套能力；
- 当前目标是什么；
- 什么行为优先；
- 如何处理分支；
- 什么结果算完成；
- 什么时候应该调用 supporting resources。

因此，Skill 中大量设计问题确实属于 Prompt Engineering。

但 Skill 本身仍然比 Prompt 更大。

例如：

- scripts 是确定性程序；
- assets 是产出资源；
- tool dependency 是能力依赖；
- references 是可按需读取的支撑材料。

所以更准确的关系是：

> **Prompt 是 Skill 影响模型行为的核心手段之一；Skill 是对一类能力的更高层封装。**

## Skill 与 Context Engineering 的关系

Skill 通过上下文发挥作用，但不能因此把 Skill 等同于 Context Engineering。

完整的 Context Engineering 可能涉及：

- 历史消息如何保留与压缩；
- memory 如何注入；
- retrieval 如何运行；
- tool result 如何进入上下文；
- Skill 如何被发现；
- 多种上下文如何排序；
- token budget 如何分配；
- 跨轮状态如何持续。

其中相当一部分由 Harness / Runtime 实现，Skill 本身无法直接控制。

Skill 能做的是：

> 在宿主已经提供的能力范围内，通过 instruction 引导模型如何使用这些能力。

例如，Skill 可以要求：

~~~text
只有当前决策需要时才读取对应 reference。
已有足够证据后停止继续搜索。
~~~

这会影响模型的行为，并间接改变后续进入上下文的内容。

但 Skill 不能仅凭文本要求：

~~~text
把上下文窗口扩大到某个固定值。
改变宿主的 memory compaction 算法。
修改系统消息优先级。
~~~

如果宿主没有暴露相应能力，这些只是无效的伪控制。

因此可以把边界写成：

> **Skill 可以影响模型如何使用 Harness，但不能仅靠 Skill 自身改变 Harness 提供什么能力。**

## Harness：能力运行的宿主

Harness 不应被误解成一个完全独立于模型的确定性调度器。

现代 Agent Harness 的核心决策者通常仍然是 LLM。

Harness 提供：

- 文件读取能力；
- 搜索能力；
- 工具调用能力；
- Skill discovery / loading；
- 状态与消息机制；
- 执行环境；
- 权限和安全边界。

而模型利用这些能力决定：

- 下一步做什么；
- 是否读取资料；
- 是否调用工具；
- 是否继续验证；
- 是否结束任务。

所以更准确的关系是：

~~~text
Harness 提供能力与边界
        ↓
LLM 进行核心决策
        ↓
Skill 对这套决策策略进行条件化
        ↓
模型使用 Harness 完成任务
~~~

Skill 的作用因此不是取代 Harness，而是让模型在已有 Harness 中表现出更稳定、可复用的专门能力。

## 从单一 Prompt 到能力单元

可以把 Agent 能力的组织看成一个逐步抽象的过程：

~~~text
一次性要求
→ Prompt

多步行为结构
→ Workflow

可重复的领域能力
→ Skill

Skill 被发现、加载和运行
→ Harness / Runtime
~~~

这个层级非常重要。

如果把 Prompt 当成 Skill，会导致大量一次性规则被错误永久化。

如果把 Workflow 当成 Skill，会导致一个能力被拆成大量阶段性 Skill。

如果把 Skill 当成 Harness，又会产生大量根本无法执行的伪控制规则。

因此，正确的分层不是术语洁癖，而是决定系统是否能够长期维护。

## Skill 主入口的设计原则

既然 Skill 是能力封装，那么主 SKILL.md 的任务就不是保存“所有重要知识”，而是描述这项能力如何被正确使用。

通常应该保留：

- 能力定位；
- 关键行为原则；
- 主工作流；
- 路由条件；
- 边界；
- 完成条件；
- supporting resources 的读取条件。

而把这些内容下沉到 references：

- 专项知识；
- 长案例；
- 平台细节；
- 发布说明；
- schemas；
- 特殊分支；
- 低频错误处理。

这不是单纯为了缩短文件。

本质上是为了让一个能力的主表示保持清晰：

> **Agent 一旦决定使用这个 Skill，首先应该看到什么？**

## 聚合与“混同进化”

Skill 的边界不应被视为永久固定。

随着真实使用增加，原本被拆开的能力可能被发现实际上属于同一条工作流；反过来，一个过大的 Skill 也可能逐渐产生真正独立的能力。

因此工作流可以发生：

~~~text
使用
→ 观察真实关系
→ 重新判断能力边界
→ 聚合 / 分化
→ 再使用
~~~

本文把其中的“聚合”称为一种混同进化：

> **当多个原本独立的 Skill 或方法在实践中被证明属于同一个能力体系时，把相关内容重新聚合到一个 Skill，通过主入口和 references 重新组织。**

它不是简单地让多个 Skill 相互复制规则，也不是建立一个跨 Skill 的同步协议。

它直接改变能力边界本身。

目标不是让所有内容统一，而是减少人为碎片化。

## 结论

Prompt、Workflow 和 Skill 描述的是三个不同层次的问题：

> **Prompt 解决表达。**  
> **Workflow 解决组织。**  
> **Skill 解决能力封装。**

而 Harness 提供这些能力运行所需要的环境、接口与边界。

它们共同构成一个更完整的 Agent 工程模型：

~~~text
Harness / Runtime
        ↓
提供能力、环境与边界
        ↓
LLM
        ↓
Skill：可发现的能力单元
        ↓
Workflow：能力内部的行为结构
        ↓
Prompt：行为要求的语言表达
~~~

这个模型的意义并不只是澄清几个术语。

它给出了一个实际设计原则：

> **不要因为某个行为可以写成文字，就把它叫 Prompt；不要因为存在步骤，就把每个步骤拆成 Skill；也不要因为 Skill 能影响模型的后续行为，就假设它能够控制 Harness。**

真正稳定的 Agent 系统，需要让每一种机制停留在它实际能够控制的层级上。

## 当前仍需继续研究的问题

本文只是理论稿初版，以下问题仍需要结合现有 Agent 生态、真实 Skill 实现和实测继续验证：

- Skill 的最佳能力粒度如何确定；
- 一个 Skill 在什么条件下应该聚合或分化；
- Prompt、Workflow 与 Skill 之间怎样建立可验证的行为映射；
- examples 对 Skill 行为的影响强度如何评估；
- Skill 在不同 Harness 中的可移植性；
- Skill instruction 与宿主上下文发生竞争时的实际行为；
- 如何设计跨版本、跨模型的 Skill eval；
- 哪些行为应继续保持软提示，哪些应转移到脚本、工具或运行时硬约束。

这些问题将决定 Skill 是否能够从“方便复用的提示词目录”进一步发展为稳定的 Agent 能力工程单元。
