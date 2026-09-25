# Computer Use 与无头 Windows 靶机/逆向工作流调研

> 状态：调研记录，不代表已经在本项目环境中完成工程验证。
>
> 更新：2026-09-26
>
> 范围：Windows Guest、无头虚拟机、GUI 自动交互、动态分析/调试、多 Agent 工作流。
>
> 脱敏原则：本文只记录通用架构、公开项目与可复用结论，不记录真实样本、账户、主机、路径、凭据或个人身份信息。

## 结论摘要

“让 AI 在无头 Windows 靶机中通过 GUI 把程序推进到有分析价值的运行状态，再由 debugger/API/动态分析工具接手”并不是完全没人做过的想法。

更准确地说，相关能力来自几条长期独立发展的路线：

- 传统 malware sandbox 很早就存在 `human interaction / user simulation`，用于移动鼠标、点击窗口、推动样本继续执行；
- 交互式 sandbox 已经把“分析过程中直接操作 Windows VM”产品化；
- Computer Use / desktop-agent 领域已经证明“headless VM + screenshot + keyboard/mouse action”可以作为标准运行形态；
- Windows GUI Agent 正在采用 UIA/Win32/API/shell/视觉混合，而不是只靠屏幕坐标点击；
- debugger、动态插桩、行为监控本身已有成熟工具链。

目前没有发现一个公开、开源、已经形成事实标准的一体化工作流，可以直接完成：

```text
LLM GUI Agent
    ↓
理解 Windows GUI 并自动导航
    ↓
把程序推进到关键运行状态
    ↓
自动识别 semantic boundary
    ↓
无缝交给 reverse/debug agent
    ↓
持续逆向与证据收集
```

因此不能把这套完整组合描述成“已经成熟、拿来即用的标准方案”。更准确的定位是：**多个成熟/较成熟子领域的交叉点，其中 GUI→逆向工具自动交接仍需要工程验证。**

## 为什么过去很少叫 Computer Use

传统逆向和恶意软件分析领域通常不使用 “Computer Use” 这个术语，而会使用：

```text
human interaction emulation
automated interactivity
user simulation
live interaction
interactive sandbox
```

因此只搜索 “Computer Use + reverse engineering” 会低估已有实践。

传统 sandbox 的目标也不同：它们更重视 API hook、进程、文件、注册表、网络、内存 dump、行为报告等**语义观测**。GUI 往往只是用于推动程序继续运行，而不是主要分析接口。

现代多模态模型带来的变化，是 GUI 截图第一次可以被一个具备较强语义理解能力的 Agent 消费，而不仅仅是给人类分析员查看或由规则脚本机械点击。

## 已有成熟祖先：Cuckoo / CAPE human interaction

Cuckoo 很早就加入了模拟人类交互的能力，包括鼠标移动和对话框交互。这个方向后来继续存在于 CAPE 等系统中。

CAPE 的 Windows analyzer 中仍存在 `human.py` 一类 human interaction 机制。它的价值不是“完成逆向”，而是让程序更接近真实用户运行条件，推动弹窗、文档、界面流程继续执行。

同时 CAPE 又拥有动态行为监控和可编程 debugger。这意味着概念上已经存在如下组合：

```text
Windows Guest
    ↓
human interaction
    ↓
程序自然推进
    ↓
行为监控持续运行
    ↓
命中特定代码/行为条件
    ↓
debugger / dump / trace / extraction
```

这与当前设想的核心分工非常接近：

> GUI 负责把程序带到真实、有意义的运行状态；结构化逆向工具负责看清内部机制。

区别主要在于传统 human interaction 多数是规则/启发式脚本，而不是现代多模态 LLM。

值得注意的是，CAPE 的 Guest 文档也提醒避免某些可见 agent 窗口干扰 human interaction。这说明“后台控制、Guest 通信和 GUI 自动操作互相干扰”并不是当前项目特有的问题，而是成熟 sandbox 设计中已经存在的工程问题。

## 商业实践：ANY.RUN / Triage / Joe Sandbox

### ANY.RUN

ANY.RUN 已经把自动交互作为产品能力。其 Automated Interactivity 目标是模拟用户行为并推动分析对象继续执行，后续还加入更智能的内容分析来决定下一步交互。

这证明“自动操作 GUI 以触发后续行为”已经是实际 malware-analysis 产品需求，而不是纯理论构想。

但公开资料不足以证明它内部使用的就是通用 LLM Computer Use，也不能据此推断其内部架构与当前设想完全相同。

### Hatching Triage

Triage 提供 Live Interaction，使分析员能够在分析过程中直接操作 VM，以触发自动流程未覆盖的界面和行为。

它证明“自动分析 + 必要时进入真实交互桌面”是一种成熟需求。

### Joe Sandbox

Joe Sandbox 公开能力中同时出现 Live Interaction、AI/自动分析和更深层代码分析/逆向相关能力。

这说明产业方向正在靠近“交互 + 动态分析 + 逆向”的组合。

但目前没有足够公开证据证明其已经形成一个可复用的“LLM GUI Agent 自动导航 → debugger/reverse agent 自动交接”的标准工作流。因此本文不把它作为该完整方案已经成熟的证据。

## Computer Use 领域：无头并不等于没有 GUI

一个关键认知是：

```text
headless VM ≠ Guest 没有桌面
headless VM ≠ 没有虚拟显示器
```

无头通常意味着 Host 不为 VM 创建普通可见窗口，但 Guest 仍然可以拥有图形桌面、虚拟 framebuffer 或远程显示通道。

因此不应让 Agent 依赖：

```text
Host desktop
    ↓
一个可被用户遮挡/最小化的 VM 窗口
    ↓
截图
```

更合理的是：

```text
Guest virtual display
    ↓
VM screenshot / framebuffer / remote display
    ↓
Computer Use Agent
```

这样可以避免：

- 用户和 Agent 抢鼠标/键盘；
- VM 窗口被遮挡；
- 最小化导致截图失败；
- Host 多显示器/DPI/焦点变化；
- 用户正常使用 Host 时污染 Agent 的视觉环境。

## OSWorld：headless Computer Use 的重要参考

OSWorld 是 desktop/computer-use agent 领域的重要 benchmark/基础设施参考。它支持虚拟化环境，并存在 headless、screenshot observation、PyAutoGUI/computer-action 这类组合。

它的重要意义不是提供逆向能力，而是证明以下抽象本身成立：

```text
headless desktop environment
    +
screenshot observation
    +
keyboard/mouse action
```

因此，“靶机无头运行”和“模型能够看见并操作 Guest GUI”并不矛盾。

这对当前项目非常重要：Computer Use 不应该绑定到 Host 上一个真实可见的 VM 窗口，而应该绑定到 Guest/虚拟化层提供的独立桌面通道。

## WindowsAgentArena

Microsoft WindowsAgentArena 是 Windows GUI Agent 的重要参考项目。它把 Windows VM、Agent、截图/UI 观察、任务执行、环境恢复等组织成可重复运行的实验环境。

它更接近 benchmark，而不是逆向工作流，因此不适合直接当作完整逆向平台使用。

值得借鉴的是：

```text
VM lifecycle
golden/base image
agent ↔ guest protocol
UI observation
task execution
result verification
environment reset
```

这些正是当前 Windows Guest 工作流也需要解决的基础设施问题。

## Cua

Cua 是 Computer Use 基础设施方向的重要候选。其设计强调 GUI、shell/code、API 等工具面的组合，而不是要求所有操作都通过视觉点击完成。

Windows 侧公开实现/文档涉及 Win32、UI Automation、输入和截图等能力，并提供面向 Agent 的工具接口。

这一方向与当前项目的需求高度一致，因为真正高效的 Windows Agent 不应使用纯 pixel automation：

```text
能走 API / shell → 不点 GUI
能走 UIA / Win32 → 不猜像素
只有语义接口不足 → 再使用视觉 Computer Use
```

但 Cua 是否适合作为当前靶机的生产级 GUI plane，仍需要在真实 Guest、无头模式、崩溃恢复和调试器场景中做 PoC，不能仅根据项目介绍下结论。

## Microsoft UFO / UFO²

UFO 系列的重要参考价值在于 Windows 原生 GUI Agent 的混合控制思想：UIA/Win32/GUI 与 API/MCP 等能力组合，而不是把整个 Windows 当成一张图片。

这一点支持当前项目采用“semantic first, pixel fallback”的设计：

```text
API / structured tool
        ↓ 不适用
shell / PowerShell
        ↓ 不适用
UIA / Win32
        ↓ 不适用
visual Computer Use
```

这比单纯 screenshot → click 更适合逆向和调试场景。

## Computer Use 不应该替代 debugger

Computer Use 很适合做**状态导航**，但不适合承担大多数核心逆向动作。

不应优先用 Computer Use 完成：

```text
读内存
读寄存器
列线程/模块
单步
设断点
反汇编
dump
读文件
查注册表
VM snapshot/reset
```

这些操作有结构化 debugger/API/CLI 时，GUI 点击通常更慢、更脆弱、更浪费模型上下文。

Computer Use 更适合：

```text
处理 modal dialog
通过首次运行向导
操作 GUI-only 设置
完成正常用户路径
触发只有真实交互才出现的行为
观察蓝屏/登录界面/错误弹窗
在 CLI/agent 异常时提供视觉诊断
把程序推进到有分析价值的状态
```

因此更准确的定位是：

> **Computer Use = state navigation layer，而不是 reverse engineering engine。**

## GUI 与传统逆向哪个更快

不能简单二选一。

如果目标是“尽快把陌生 GUI 程序推进到某个深层运行状态”，正常 GUI 路径往往有优势，因为程序会自己完成大量初始化：对象、线程、句柄、配置、会话、UI 状态等。

如果目标是“理解核心机制、重复实验、修改控制流、读取内部状态”，结构化逆向/调试工具通常更快。

更合理的渐进流程是：

```text
GUI-driven exploration
        ↓
runtime observation
        ↓
identify semantic boundary
        ↓
structured reverse/debug
        ↓
replace repetitive GUI steps
```

第一次可以让 GUI 帮助找到真实路径；一旦核心入口、状态依赖和调用链已经确定，就逐步用 debugger/API/脚本替代重复 GUI 操作。

GUI 在这里最大的价值不是代替逆向，而是**缩小搜索空间并构造真实运行状态**。

## 为什么自然 GUI 路径有时比直接 patch 更可靠

直接修改一个 flag 或强行跳过前置流程，可能只满足表面条件，却没有构造真实路径中本应存在的上下文，例如：

```text
session
object
thread
handle
buffer
network state
UI state
```

于是会出现：

```text
某个条件被强制满足
≠
程序真正经过该流程后的完整运行状态
```

因此在探索阶段，先让程序通过真实 GUI/用户路径自然推进，再在关键边界切入 debugger，可能比一开始就绕过整个 UI 更能避免实验失真。

这不是绝对规则：一旦状态依赖已经被理解，重复走 GUI 就可能成为浪费，应当压缩成更稳定的结构化入口。

## 当前建议的混合架构

不建议：

```text
Agent
  ↓
Computer Use
  ↓
所有 Windows 操作
```

建议：

```text
                         Agent / Orchestrator
                                  │
       ┌──────────────────────────┼──────────────────────────┐
       │                          │                          │
Hypervisor / Control       Reverse / Semantic          GUI Navigation
       │                          │                          │
VM lifecycle              debugger / API / MCP      Computer Use / UIA
snapshot/reset            trace / memory / dump     screenshot / input
       │                          │                          │
       └──────────────────── Windows Guest ─────────────────┘
                                  │
                         artifacts / evidence
```

GUI plane 内部再分两级：

```text
Semantic GUI channel
UIA / Win32 / accessibility
          │
          │ 正常优先
          ↓
Windows interactive desktop
          ↑
          │ fallback
          │
Pixel GUI channel
virtual framebuffer / screenshot / remote display
```

这意味着：

- 正常情况下优先语义 GUI；
- UIA/Win32 无法覆盖时才依赖视觉；
- Guest 内部 GUI agent 失效时，尽量仍保留虚拟化层视觉通道；
- Guest 完全失效时，由 hypervisor control plane 负责 reset/restore；
- debugger/API 始终独立，不让 GUI 自动化成为核心分析瓶颈。

## Session 0 是重要边界

Computer Use 不能凭空解决 Session 0 没有正常交互桌面的问题。

如果目标程序需要真实用户桌面、窗口消息、输入或 modal dialog，应当明确维护 interactive desktop lane，而不是假设 SYSTEM/Session 0 中的后台执行等价于真实用户运行。

这也是为什么“无头”需要被正确理解：

```text
Host 没有 VM 窗口
```

可以成立，同时 Guest 内部仍然存在：

```text
interactive Windows desktop
```

二者并不冲突。

## 成熟度判断

| 能力 | 当前判断 |
|---|---|
| headless VM + 动态分析 | 成熟 |
| sandbox human/user interaction | 成熟 |
| 分析员实时操作 sandbox VM | 成熟 |
| debugger / instrumentation / dump / trace | 成熟 |
| headless desktop + Computer Use | 已有成熟 benchmark/基础设施实践 |
| Windows UIA + visual + API 混合 Agent | 已有较成熟项目，仍快速发展 |
| AI 自动理解 GUI 并推进分析对象执行 | 正在成熟，商业产品已有类似能力 |
| LLM GUI Agent → semantic boundary → reverse/debug agent 全自动交接 | 未发现公开的事实标准 |

这里必须避免一个误导：

> “组成部分已经成熟”不等于“把这些部分组合起来的完整工作流已经成熟”。

当前最需要验证的是**组合边界**，而不是重新实现所有底层能力。

## 对当前项目的工程含义

现阶段不建议立即把 Computer Use 大量规则写入 Guest workflow skill。

优先研究和复用：

1. CAPE 的 human interaction、analyzer 与 debugger 如何协作；
2. OSWorld 如何实现 headless desktop observation/action；
3. WindowsAgentArena 如何组织 Windows VM 与 Agent 的生命周期；
4. Cua/UFO 能否提供现成的 Windows semantic GUI control；
5. VirtualBox/Hyper-V 当前环境是否能提供独立于 Host desktop 的截图/输入通道；
6. 多 Agent 是否可以共享同一个 Guest 状态而不争抢 GUI/写权限。

真正值得自研的部分，应尽量缩小为：

```text
现有 Guest Workbench
        +
成熟 GUI/Computer Use 组件
        +
已有 debugger/analysis 接口
        ↓
最薄的 orchestration / handoff layer
```

而不是重新发明 sandbox、GUI driver、debugger、artifact pipeline 和 VM lifecycle。

## 推荐 PoC

PoC 不先追求“自动逆向”，只验证几个关键前提：

```text
A. VM 完全 headless 时能否稳定取得 Guest 虚拟显示截图
B. 不依赖 Host 前景窗口时能否注入键鼠/GUI 操作
C. 用户正常使用 Host 时是否完全不干扰 Agent
D. Guest 内部 UIA/agent 失效后，pixel channel 是否仍可观察 Guest
E. Guest reboot/restore 后 GUI channel 能否恢复
F. GUI 能否把一个 benign Windows GUI 程序推进到指定状态
G. 到达状态后能否把控制交给结构化 debugger/API，而不是继续点 GUI
H. 多 Agent 切换时能否恢复同一 GUI/Guest 状态
```

建议比较指标：

```text
成功率
平均工具调用数
模型 round-trip
墙钟时间
失败恢复时间
token 消耗
Host 干扰程度
Guest 崩溃后的可观测性
```

只有这些前提验证通过后，再决定是否把 Computer Use 正式纳入 Guest workflow。

## 公开参考

以下用于继续核对与深入阅读；它们分别支持不同子结论，不应被理解为都实现了本文提出的完整工作流。

- OpenAI Computer Use guide: https://developers.openai.com/api/docs/guides/tools-computer-use
- OSWorld: https://github.com/xlang-ai/OSWorld
- Microsoft WindowsAgentArena: https://github.com/microsoft/WindowsAgentArena
- Cua: https://github.com/trycua/cua
- Microsoft UFO: https://github.com/microsoft/UFO
- CAPEv2: https://github.com/kevoreilly/CAPEv2
- CAPE human interaction implementation: https://github.com/kevoreilly/CAPEv2/blob/master/analyzer/windows/modules/auxiliary/human.py
- Cuckoo historical human-interaction discussion: https://cuckoosandbox.org/blog/to-the-end-of-the-world
- ANY.RUN Automated Interactivity: https://any.run/cybersecurity-blog/automated-interactivity-stage-two/
- ANY.RUN product capabilities: https://any.run/features/
- Hatching Triage: https://hatching.io/triage/
- Joe Sandbox: https://www.joesecurity.org/

## 后续研究问题

后续不应继续泛泛搜索“有没有 Computer Use 项目”，而应集中回答：

- CAPE 的 human interaction 能否被现代 GUI Agent 替换而不破坏 analyzer 的隔离和时序？
- OSWorld/WindowsAgentArena 的 Guest service 对高风险、不稳定 Windows Guest 是否过重？
- 是否可以让 hypervisor framebuffer 成为 pixel fallback，而 UIA 成为 semantic primary？
- Hyper-V 与 VirtualBox 在 headless screenshot/input 上分别能提供什么原生能力？
- debugger attach 是否会改变 GUI 路径，需要怎样区分 natural run 与 debug run？
- 如何定义 GUI → debugger 的 semantic boundary，使 Agent 知道“现在应该停止点鼠标，开始做结构化分析”？
- 如何让多个 Agent 共享 Guest 状态，同时保持单写 owner 和可恢复 handoff？

这些问题解决之后，才适合决定最终架构。