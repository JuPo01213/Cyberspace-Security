# 逆向工具链与 AI Agent 接入调研（成熟度分层）

> 调研日期：2026-09-25  
> 目的：优先复用已有、维护活跃、在传统逆向/恶意软件分析中已有实际使用基础的工具与流程，并研究如何把这些能力接给 AI Agent 使用。本文不把“AI + MCP + 多工具串联”整体视为已经久经验证的方法，而是把它作为仍需实际验证的集成方案。

## 结论先行

当前较值得优先评估的路线，是尽量利用现有分析环境已经提供的自动化接口，而不是一开始自行开发“Reverse Tool Hub / Workflow Engine”：

```text
稳定宿主机 / 主 Agent
        │
        ├── REMnux MCP
        │      └── REMnux VM / Container
        │
        ├── GhidrAssistMCP
        │      └── Ghidra
        │
        └── CAPE API
               └── CAPE Master
                      └── Windows Analysis Guests

人工专家工作台：
FLARE-VM
```

推荐的职责划分：

- **REMnux**：静态分诊、文件/文档/网络/内存等分析工具集合，以及已有工具选择经验。
- **remnux-mcp-server**：把 REMnux 已有工具和分析经验暴露给 AI Agent。
- **Ghidra + GhidrAssistMCP**：深入代码级逆向、函数/Xref/反编译/注释/重命名等交互式分析。
- **CAPE**：真实 Windows 动态分析、自动化执行、行为采集、payload/unpacking、报告与 artifact。
- **FLARE-VM**：长期使用的 Windows 逆向工具环境之一；第一阶段不把它当作主要 Agent 自动执行环境。

核心原则：

> **复用 REMnux 和 CAPE 已经存在的工作流，让 AI 调用它们，而不是让 AI 重新发明这些工作流。**

---

## 成熟度必须分层看

这次调研中必须区分两件事。

### 有较长使用历史的底层工具与方法

这些项目或方法在传统逆向/恶意软件分析中有较长使用历史，至少可以把它们视为有实际使用基础的底层组件：

- REMnux 恶意软件分析环境。
- Ghidra 逆向分析平台。
- CAPE/Cuckoo 系谱的自动动态分析模式。
- FLARE-VM Windows 逆向工具环境。
- Mandiant FLARE 工具族，例如 capa、FLOSS。

### 较新的部分

AI/MCP 接入层属于较新的工程：

- remnux-mcp-server。
- GhidrAssistMCP。
- 通过 MCP 让通用 Agent 自动操作分析工具。

因此不能把“REMnux / Ghidra / CAPE 本身有长期使用历史”推导成“AI + MCP 串联后的整套工作方法已经经过长期行业验证”。

更准确的表达是：

> **底层工具和部分传统分析流程有较长使用历史；但把它们通过 MCP/API 交给通用 AI Agent 统一调度，是较新的做法，实际可靠性、可维护性和适用边界仍需要在自己的环境里验证。**

这与完全自行设计一套新的逆向 Workflow Engine 不同，但它仍然属于需要工程验证的新集成方式。

---

## REMnux：当前最直接的 AI 接入点

官方项目：

- REMnux MCP Server: https://github.com/REMnux/remnux-mcp-server
- REMnux AI 使用文档: https://docs.remnux.org/tips/using-ai

remnux-mcp-server 的定位非常直接：

> MCP server for using the REMnux malware analysis toolkit via AI assistants.

它目前支持三种官方部署模式：

### 模式 A：Agent 在宿主机，REMnux 在 VM/Container

```text
Analyst Host
│
├── AI Agent
└── remnux-mcp-server
        │
        ├── SSH
        └── Docker exec
              │
              ▼
            REMnux
```

这是最符合当前 Cyberspace 项目需求的模式，因为主 Agent 和工作状态可以留在稳定宿主机，VM 只负责执行分析。

官方 SSH 示例：

```bash
claude mcp add remnux -- \
  npx @remnux/mcp-server \
  --mode=ssh \
  --host=YOUR_VM_IP \
  --user=remnux
```

建议使用 SSH key + SSH Agent，而不是把密码写入配置。

如果启用路径隔离，应进一步使用项目提供的 sandbox / ingest-root 能力，把宿主机可上传样本范围限定到专用目录。

### 模式 B：Agent 和 MCP 都在 REMnux

```text
REMnux
├── AI Agent
├── remnux-mcp-server
└── analysis tools
```

这是最简单的本地模式，不需要网络或 SSH。

MCP 配置核心：

```json
{
  "mcpServers": {
    "remnux": {
      "command": "remnux-mcp-server"
    }
  }
}
```

### 模式 C：MCP Server 在 REMnux，宿主机远程 HTTP 连接

```text
Host Agent
   │
   │ Streamable HTTP
   ▼
REMnux
└── remnux-mcp-server
```

官方支持 HTTP transport，但远程绑定需要认证 token；若网络不可信，还需要在前面加 HTTPS reverse proxy。

相比之下，当前环境更建议优先使用 **宿主机 MCP + SSH → REMnux VM**，减少额外暴露的服务。

---

## REMnux MCP 已经编码了分析经验

重要点在于：它不是简单提供一个裸 shell。

当前项目公开的主要能力包括：

- `get_file_info`
- `suggest_tools`
- `get_tool_help`
- `analyze_file`
- `extract_iocs`
- `check_behavior_prerequisites`
- `verify_string_usage`
- `compare_files`
- `run_tool`
- `extract_archive`
- `upload_from_host`
- `download_file`

其中最重要的是：

### suggest_tools

根据检测到的文件类型推荐 REMnux 中合适的工具，并提供分析提示。

### analyze_file

根据文件类型自动选择并运行已有 REMnux 工具链。

这意味着第一阶段没有必要自己重新写：

```text
PE → FLOSS → capa → xxx
PDF → pdfid → xxx
Office → oletools → xxx
PCAP → xxx
```

这些知识已经开始由 REMnux MCP 自己维护。

### verify_string_usage / check_behavior_prerequisites

这些工具体现了一个重要设计：

不要让模型看到一个可疑字符串或静态能力标签后就直接宣布“程序一定做了某个行为”。

它会进一步区分：

- 静态 artifact。
- 实际代码引用。
- import surface。
- 分析不完整状态。
- 真正执行行为。

这种设计比单纯给 Agent 一个 shell 更适合可靠的逆向/恶意样本调查。

---

## Ghidra：通过 GhidrAssistMCP 接入

项目：

- https://github.com/symgraph/GhidrAssistMCP

REMnux 当前的 salt-state 中也包含 GhidrAssistMCP 安装与配置，REMnux 配置记录表明：

- 在 Ghidra 中启用 `GhidrAssistMCPPlugin`。
- 打开 `Window → GhidrAssistMCP`。
- 默认监听 localhost。
- 默认端口 8080。
- 支持 Streamable HTTP endpoint：`http://127.0.0.1:8080/mcp`。

GhidrAssistMCP 当前提供的能力包括：

- 函数查询。
- 字符串查询。
- imports / exports。
- 反编译。
- 反汇编。
- Xref。
- call graph。
- 注释。
- 重命名。
- 多程序处理。
- 工具开关。
- headless mode。

推荐用途：

```text
REMnux 初步分析
        │
        ├── 信息已经足够 → 输出结论
        │
        └── 需要理解代码逻辑
                 │
                 ▼
             Ghidra
                 │
          GhidrAssistMCP
                 │
                 ▼
              Agent
```

不要让模型从入口点开始盲目遍历几千个函数。

更合理的流程是：

1. REMnux/capa/FLOSS 等先缩小问题范围。
2. 确定可疑字符串、能力、import 或相关函数。
3. 再使用 Ghidra MCP 做函数级深入分析。
4. 需要时留下重命名和注释，使分析状态保存在 Ghidra 项目中。

---

## Ghidra Headless

GhidrAssistMCP 当前还支持 Ghidra headless 模式。

这意味着自动化环境不一定需要一直打开 CodeBrowser GUI。

典型模式：

```text
analyzeHeadless
    │
    ├── import binary
    ├── auto analysis
    └── start GhidrAssistMCP
            │
            ▼
           Agent
```

这适合后续做批量或无人值守分析。

但是第一阶段不建议为了“架构完整”自行开发额外 Ghidra RPC 层；优先直接使用现有 MCP。

---

## CAPE：优先复用现有动态分析能力

项目：

- https://github.com/kevoreilly/CAPEv2

CAPE 是长期维护、实际使用较多的自动动态分析系统之一。这里复用的是它现有的 sandbox 能力，并不意味着“Agent + CAPE”的整套协作方式已经经过长期验证。

典型工作流已经由 CAPE 自己完成：

```text
提交样本
  ↓
选择分析 Guest
  ↓
恢复/启动 VM
  ↓
执行
  ↓
行为采集
  ↓
文件/进程/注册表/网络
  ↓
内存 / payload / unpacking
  ↓
YARA / config extraction
  ↓
报告与 artifacts
```

模型不应该自行实现：

- Windows VM 生命周期。
- snapshot orchestration。
- 样本执行。
- API hooking。
- PCAP 收集。
- dropped files 收集。
- 自动 unpacking。
- 报告生成。

这些都是 CAPE 的职责。

CAPE 的 distributed 模式已经采用 Master + Worker/Node 的设计，并通过 REST API 提交任务、查询任务和获取报告。

因此 Agent 的接法应保持简单：

```text
Agent
  │
  ▼
CAPE REST API
  │
  ▼
CAPE Master
  │
  ▼
Windows Analysis Guests
```

Agent 只负责：

- 提交任务。
- 查询状态。
- 读取报告。
- 获取 artifacts。
- 根据报告决定是否继续静态/代码分析。

---

## FLARE-VM：定位为人工专家工作台

官方项目：

- https://github.com/mandiant/flare-vm

FLARE-VM 的官方定位是：

> 一组用于 Windows VM 的软件安装与配置脚本，用于快速建立和维护逆向工程环境。

它解决的是 Windows 逆向工具环境的建立与维护问题。

因此第一阶段建议：

```text
FLARE-VM = Human-in-the-loop expert workstation
```

而不是：

```text
FLARE-VM = 自动化 sandbox / Agent workflow engine
```

不要优先投入时间让 Agent：

- 远程控制鼠标。
- 自动点 x64dbg。
- 操作大量 GUI。
- 通过 RDP 复制输出。

如果以后明确需要 x64dbg 自动化，再单独研究其 command / script / plugin 接口或现成 MCP bridge。

---

## Mandiant FLARE 工具族

相关官方项目：

- capa: https://github.com/mandiant/capa
- FLOSS: https://github.com/mandiant/flare-floss
- FLARE-VM: https://github.com/mandiant/flare-vm

这些工具依然非常重要。

但对于 Agent 接入而言，优先级发生变化：

过去可能会自行写：

```text
Agent
→ subprocess(fl oss)
→ parse
→ subprocess(capa)
→ parse
→ ...
```

现在如果 REMnux MCP 已经能通过 `suggest_tools` / `analyze_file` 调用并组织这些工具，应优先复用 REMnux 的现有逻辑。

只有当：

- REMnux MCP 缺少关键能力；
- 需要特殊参数；
- 需要批量高性能调用；
- 需要和其他基础设施深度集成；

才考虑单独包装这些 CLI。

---

## 推荐的默认决策流程

不要机械规定每个样本都必须：

```text
FLOSS → capa → Ghidra → x64dbg → CAPE
```

更稳妥的做法是目标驱动：

```text
样本/文件
   │
   ▼
REMnux 初步分诊
   │
   ├── 已经足够回答问题
   │       └── findings
   │
   ├── 需要理解具体代码逻辑
   │       └── Ghidra + GhidrAssistMCP
   │
   └── 需要真实 Windows 运行行为
           └── CAPE
                 │
                 └── 报告返回后再决定
                     是否继续 REMnux/Ghidra
```

重点：

> 模型负责“调查决策”，已有分析工具负责各自擅长的执行部分。模型如何在这些工具之间可靠地做决策，仍需要通过端到端测试验证。

---

## 推荐部署结构

结合当前项目“Windows 靶机不稳定、主工作流应放稳定宿主机”的约束，推荐：

```text
Stable Host
│
├── Main Agent / Pi / Claude Code / other MCP client
│
├── Git repository / case records
│
├── SSH Agent
│
│
├── remnux-mcp-server
│      │
│      └── SSH ───────────────→ REMnux VM
│
├── MCP client ───────────────→ GhidrAssistMCP
│                                 └── Ghidra
│
└── CAPE API client ──────────→ CAPE Master
                                  └── Windows Analysis Guests

Optional manual workstation:
FLARE-VM
```

持久状态放在宿主机：

- case metadata。
- hashes。
- notes。
- reports。
- artifacts index。
- 配置。
- Git 历史。

VM 可以：

- 快照。
- 重置。
- 替换。
- 重建。

不要让重要分析结论只存在于某个易损 VM 中。

---

## 建议的 Case 目录

```text
cases/
└── CASE-YYYYMMDD-NNN/
    ├── metadata.md
    ├── hashes.txt
    ├── notes.md
    ├── findings.md
    ├── remnux/
    ├── ghidra/
    ├── cape/
    └── artifacts/
```

原则：

- 原始样本保持只读。
- 派生物单独存放。
- 原始报告不要因为模型上下文限制而删除。
- 给模型看的摘要和完整原始 artifact 分开。
- 凭据和 token 不写入 Git。

---

## 最小落地顺序

不要一次把所有东西装完。

### 阶段一：REMnux MCP

目标：

```text
Agent
→ REMnux MCP
→ 无害测试文件
→ get_file_info / suggest_tools / analyze_file
→ 返回结果
```

确认这一条跑通后再继续。

### 阶段二：Ghidra MCP

目标：

```text
Agent
→ GhidrAssistMCP
→ 打开测试二进制
→ functions
→ decompile
→ xrefs
```

### 阶段三：CAPE

目标：

```text
Agent
→ CAPE API
→ 提交无害测试程序
→ task id
→ status
→ report
```

### 阶段四：组合测试

```text
Agent
→ REMnux 分诊
→ 判断需要代码分析
→ Ghidra
→ 判断是否需要真实动态证据
→ CAPE
→ findings
```

第一阶段不优先做：

- 自研 Reverse Tool Hub。
- 自研 Workflow Engine。
- x64dbg GUI 自动化。
- 大量自定义 RPC。
- 为“统一接口”重新包装所有已有 MCP/API。

---

# 执行 Agent 配置提示词

下面这段可以直接交给 Codex、Claude Code、Pi 或其他具备主机操作能力的 Agent。

---

你现在的任务不是重新设计一套逆向分析框架，而是优先利用已有、维护活跃、在传统逆向分析中有实际使用基础的项目，搭建一套可被 AI Agent 调用并逐步验证的分析环境。不要预设“AI 串联后的整套流程已经成熟”。

总体原则：

- 优先复用已有项目和官方/项目方现成集成，不重复造轮子；但对较新的 AI/MCP 集成保持审慎，不把“官方提供”自动等同于“长期生产验证”。
- 不自行发明新的 Tool Hub、Workflow Engine、Agent Protocol 或抽象层，除非现有方案明确无法满足需求。
- 每引入一个组件，都要先确认其官方定位、维护状态、当前推荐部署方式和与其他组件的兼容性。
- 优先使用项目原生 API、CLI、MCP、REST API 或 headless 接口。
- 避免通过 GUI 自动点击、远程桌面模拟操作等脆弱方式集成工具。
- AI Agent 应尽可能运行在稳定宿主机；分析虚拟机作为可替换、可快照、可销毁的执行环境，而不是系统状态中心。
- 配置过程必须可重复、可恢复、可版本管理。
- 所有重要配置文件、脚本和文档都纳入 Git。
- 不要为了“统一接口”而重新包装已经具有成熟 MCP/API 接口的项目。
- 遇到不确定内容时，优先查官方文档、官方仓库、issue 和社区实际部署经验，而不是凭经验猜测。

目标架构优先采用：

```text
稳定宿主机 / 主 Agent
    │
    ├── MCP Client
    │
    ├── REMnux MCP
    │      │
    │      └── REMnux VM / REMnux 环境
    │
    ├── GhidrAssistMCP
    │      │
    │      └── Ghidra
    │
    └── CAPE API
           │
           └── CAPE Master
                 │
                 └── Windows Analysis VM
```

第一阶段目标是让模型可以直接调用已有逆向分析能力，并通过实际测试判断哪些组合可靠，而不是先实现一个新的逆向平台。

优先配置以下组件。

### REMnux

- 部署当前官方推荐版本。
- 检查 REMnux 当前官方 AI/MCP 集成。
- 优先使用 REMnux 官方维护的 remnux-mcp-server。
- 主 Agent 若运行在宿主机，优先评估 REMnux MCP 的 SSH 模式。
- 除非有明确理由，不要在不可信网络上直接开放未加保护的 MCP HTTP 服务。
- 若采用 SSH 模式，使用 SSH key 和正常的 SSH agent 管理认证。
- 验证模型可以完成：
  - 获取文件基础信息；
  - 根据文件类型推荐分析工具；
  - 调用 REMnux 已有分析工具；
  - 对样本执行已有分析流程；
  - 提取 IOC；
  - 获取工具帮助和结果；
  - 在必要时读取原始 artifact，而不是把所有输出直接塞进模型上下文。

### Ghidra

- 使用当前稳定版 Ghidra。
- 优先配置 GhidrAssistMCP 或 REMnux 当前实际维护/安装的 Ghidra MCP 集成。
- 不自行重新实现 Ghidra RPC 层。
- MCP 服务默认只监听 localhost，除非架构明确需要远程访问。
- 验证 Agent 能够：
  - 列出/搜索函数；
  - 搜索字符串；
  - 获取 xref；
  - 查看调用关系；
  - 反编译函数；
  - 查看反汇编；
  - 查看 imports / exports；
  - 添加分析注释；
  - 重命名符号。
- 自动化分析优先利用 Ghidra 自身已有能力，而不是让模型逐条模拟人工操作。

### CAPE

- CAPE 作为已有动态分析系统部署，优先复用其 sandbox workflow，不自行重写同类能力。
- Agent 只通过 CAPE 提供的稳定 API 提交任务、查询任务状态、读取报告和获取 artifact。
- Windows VM 的启动、恢复、运行样本、收集行为、网络、文件、内存、payload 等工作由 CAPE 自身负责。
- Agent 不直接远程控制 Windows VM GUI。
- 验证：
  - 提交样本；
  - 获取 task id；
  - 查询运行状态；
  - 获取最终分析报告；
  - 获取 dropped files、PCAP、memory dump 或其他 artifact；
  - 将报告交给 Agent 继续分析。

### FLARE-VM

- FLARE-VM 当前阶段作为人工专家分析工作台，而不是主要 Agent 自动执行环境。
- 保留快照。
- 不在第一阶段投入大量时间做 GUI 自动化。
- 如果后续确实需要调试器自动化，再单独研究 x64dbg 的命令接口、插件接口或已有 MCP bridge。
- 不要因为“以后可能需要”而提前构建复杂的 x64dbg 自动控制系统。

### 默认分析决策链

```text
文件进入
→ REMnux 初步分析
→ 如果已有证据足以回答问题，则停止
→ 如果需要理解具体代码逻辑，则进入 Ghidra
→ 如果需要真实运行行为，则提交 CAPE
→ CAPE 报告返回后继续结合 REMnux/Ghidra 分析
→ 形成最终 findings
```

不要机械规定：

```text
FLOSS → capa → Ghidra → x64dbg → CAPE
```

实际顺序应优先复用 REMnux 和 CAPE 已有流程，由分析目标和已有证据决定下一步；组合后的 AI 决策链需要用测试结果证明，而不是用“成熟”一词预先背书。

### 状态与安全

- 宿主机是控制面和持久化位置。
- VM 可以销毁。
- VM 中不得保存唯一副本的重要分析结果。
- 恶意样本默认视为不可信。
- 不在宿主机直接执行未知二进制。
- 动态分析在隔离环境完成。
- 明确记录哪些环境允许联网、哪些完全离线。
- 不允许分析环境访问宿主机个人文件、浏览器数据、SSH 私钥或其他敏感目录。
- API token、SSH key 不得写入 Git。
- 所有远程服务默认最小暴露面。
- 能绑定 localhost 就不要绑定 0.0.0.0。

### 执行顺序

先盘点当前机器：

- 操作系统；
- 虚拟化平台；
- 是否已有 REMnux；
- 是否已有 FLARE-VM；
- 是否已有 Ghidra；
- 是否已有 CAPE；
- Agent 当前支持哪些 MCP transport；
- SSH 环境；
- Docker/Podman；
- Python/Node；
- 网络拓扑。

然后依次：

1. 配置 REMnux。
2. 让主 Agent 成功连接 REMnux MCP。
3. 用一个无害 PE/测试文件验证完整调用链。
4. 配置 Ghidra + GhidrAssistMCP。
5. 验证 Agent 可以读取函数、xref 和反编译结果。
6. 部署或连接 CAPE。
7. 用无害测试程序完成一次 CAPE 提交和报告读取。
8. 将三者接入同一个主 Agent。
9. 建立 case/artifact 目录。
10. 编写最小使用说明。
11. 建立恢复方式和 VM 快照策略。
12. 最后才考虑额外自动化。

每完成一个阶段都必须实际测试，不要只看“服务启动成功”。

### 必须进行的端到端测试

测试 A：

```text
Agent
→ REMnux MCP
→ 分析无害测试文件
→ 返回文件信息和分析结果
```

测试 B：

```text
Agent
→ Ghidra MCP
→ 获取函数列表
→ 选取函数
→ 获取反编译结果
→ 获取 xref
```

测试 C：

```text
Agent
→ CAPE API
→ 提交无害程序
→ 等待任务完成
→ 读取行为报告
```

测试 D：

```text
Agent 接收一个 case
→ REMnux 初步分析
→ 判断需要代码分析
→ Ghidra
→ 判断是否需要动态分析
→ 必要时 CAPE
→ 输出结构化 findings
```

对每一个失败点记录：

- 错误；
- 根因；
- 修复方式；
- 是否属于版本兼容问题；
- 是否需要固定版本。

### 最终交付

最终提供：

- 实际部署架构图；
- 已安装组件及版本；
- 每个组件的官方来源；
- MCP 配置；
- CAPE API 配置说明；
- SSH 配置；
- Ghidra MCP 配置；
- 网络拓扑；
- VM 快照方案；
- case/artifact 目录结构；
- 启动命令；
- 停止命令；
- 健康检查方法；
- 端到端测试结果；
- 已知限制；
- 故障排查说明；
- 升级方法；
- 回滚方法。

完成后重新审查：

- 是否重新实现了已有项目已经提供的能力；
- 是否存在不必要的自研层；
- 是否存在 GUI 自动化可以替换成 API/MCP/CLI；
- 是否把状态错误地放进易损 VM；
- 是否存在单点故障；
- 是否能通过快照快速恢复；
- 是否可以重建；
- 是否存在敏感凭据泄露；
- 是否开放了不必要端口；
- 是否有工具已经提供更直接、更少自研的官方或项目方接入方式而没有使用。

如果发现我们自己写了某个已有项目已经能够完成的组件，优先评估删除自研实现并切换到现成方案；切换前仍需验证兼容性、稳定性和维护状态。

禁止为了代码量、架构完整感或“未来扩展性”增加当前不需要的抽象。

最终目标不是“构建一个逆向平台”，而是：

> **让现有 AI Agent 能够调用 REMnux、Ghidra 和 CAPE 的现有分析能力，并通过可重复测试逐步确认哪些组合足够稳定、可恢复、可维护。**

---

## 参考来源

- REMnux MCP Server  
  https://github.com/REMnux/remnux-mcp-server
- REMnux：Using AI  
  https://docs.remnux.org/tips/using-ai
- REMnux GhidrAssistMCP salt-state  
  https://github.com/REMnux/salt-states/blob/master/remnux/tools/ghidrassist-mcp.sls
- GhidrAssistMCP  
  https://github.com/symgraph/GhidrAssistMCP
- CAPEv2  
  https://github.com/kevoreilly/CAPEv2
- CAPE Distributed 文档  
  https://github.com/kevoreilly/CAPEv2/blob/master/docs/book/src/usage/dist.rst
- FLARE-VM  
  https://github.com/mandiant/flare-vm
- capa  
  https://github.com/mandiant/capa
- FLOSS  
  https://github.com/mandiant/flare-floss

## 后续建议

下一步不要继续抽象架构。

直接让执行 Agent：

1. 盘点现有宿主机和虚拟化环境。
2. 先落地 REMnux MCP SSH 模式。
3. 跑通无害文件端到端测试。
4. 再接 GhidrAssistMCP。
5. 最后部署/连接 CAPE。

每一步实际跑通以后再进入下一层。
