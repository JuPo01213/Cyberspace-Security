# Agent 逆向工具链配置契约

状态：工具已按固定版本部署；对应 Agent 指导 Skill 已安装；REMnux 独立执行节点仍待接入。
更新时间：2026-09-25
范围：REMnux MCP + Ghidra MCP；CAPE 本阶段明确排除。

## 1. 项目边界

当前项目有三条职责不同的能力链：

| 节点 | 职责 | 当前状态 |
|---|---|---|
| Windows Guest + CDB | EPT 真实样本运行、PID/PPID、断点、内存和后行为证据 | 已验证，继续作为动态主路径 |
| Ghidra MCP | PE/内存转储的函数、字符串、xref、反编译、调用关系和有限标注 | 已部署，benign smoke 通过；Skill 已安装 |
| REMnux MCP | 静态多工具复核、IOC、YARA/capa/FLOSS 类结果和原始 artifact | host package 已部署；REMnux 节点和 Skill 工作流待接入测试 |

REMnux 和 Ghidra 是 EPT 动态实验的辅助节点，不能替代 Windows Guest，也不能把静态推断写成真实样本运行结果。

CAPE、Windows 自动沙箱、FLARE-VM 自动化和新的统一 Tool Hub 均不在本阶段范围内。

已核验的官方来源候选：REMnux/mcp-server package 0.1.75，源码 HEAD b8ee3f1a8e91ab75d9154b20852fac9b179e5087；Ghidra 12.1.4 官方发行包 SHA-256 为 ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db；GhidrAssistMCP 2.11.0 官方发行包 SHA-256 为 baba204a9fe839921a1487be9dfb15526faea787e5e4312c8404281d82b3a1a7。Ghidra 12.1 要求 Java 21，当前宿主匹配；GhidrAssistMCP 源码构建另需 Java 25，因此采用二进制发行包。发行包已安装并完成 benign smoke；对应 Skill 记录于 <HOST_PATH>/Users/<USER>/.codebuddy/skills/remnux-mcp-workbench 和 ghidra-mcp-workbench。

## 2. 已核验宿主条件

来源：artifacts/host_inventory.json，由 config/host_inventory.ps1 生成。

- OS：Windows 10 build 19045，64 位。
- CPU：Intel Core i5-12400，12 个逻辑处理器。
- 内存：16,870,006,784 bytes，约 15.72 GiB。
- PowerShell：7.6.6。
- Hyper-V：可用；现有 <VM_LABEL>、<VM_LABEL>、<VM_LABEL> 保留不变。
- WSL：Ubuntu 2，当前为 Stopped；本阶段不把 WSL 视为已部署 REMnux。
- 已发现：Git 2.55.0.windows.3、Python 3.11.9、Python launcher 3.14.7、Node 24.21.0、npm 11.19.0、OpenSSH 10.3p1、Temurin Java 21.0.12.1。
- 未发现：Docker、Podman、QEMU、VirtualBox、Ghidra 命令入口。
- 未发现：本地已登记的 MCP 服务配置。检索结果中仅有此前代理拦截失败的 Web 缓存，不算服务安装证据。

部署选择必须考虑约 16 GiB 宿主内存和现有 Hyper-V 实验 VM，不得未经盘点直接启动新 VM 或修改现有 C173 VM。

## 3. 控制面和持久化

宿主 Windows 负责 Agent 编排、配置、凭据引用和 artifact 持久化。分析节点只负责执行工具和返回原始结果。

建议目录契约：

    <HOST_PATH>/EPT/
      config/
        host_inventory.ps1
        agent_toolchain.json
      artifacts/agent/
        remnux/<case-id>/
        ghidra/<case-id>/
      cases/<case-id>/
      reports/<case-id>/

artifacts/agent/ 和 cases/ 中必须保留：工具版本、调用参数、开始/结束状态、原始 stdout/stderr、结构化摘要、输入文件 SHA-256 和输出文件 SHA-256。

以下内容禁止进入 Git 或普通 evidence：API token、SSH 私钥、Guest 密码、CAPE 凭据、个人身份信息和未脱敏授权材料。SSH 私钥沿用独立凭据目录，MCP 配置只引用路径或 SSH agent，不内嵌私钥内容。

## 4. REMnux MCP 契约

### 角色

REMnux 只作为 Linux 静态分析和网络工件解析节点。首轮能力目标：

- 文件类型和架构识别；
- SHA-256、PE 头、节区、导入/导出和熵；
- strings/FLOSS 类字符串恢复；
- YARA 和 capa 类能力匹配；
- URL、域名、IP、注册表路径、文件路径和命令行 IOC 提取；
- 对既有文本、日志、PCAP 或 dump 元数据进行离线解析；
- 返回原始工具输出和可复核的 JSON 摘要。

### 部署和传输

- 首选独立、可快照的 REMnux VM；WSL Ubuntu 仅作为候选承载环境，未验证前不视为 REMnux。
- 使用官方 @remnux/mcp-server 0.1.75，Node.js 要求为 >=20；宿主已有 Node 24.21.0。
- 本项目首选 stdio MCP client 启动宿主侧 server，再由 server 使用 SSH connector 调用独立 REMnux VM；不使用无认证 HTTP。
- 服务默认只绑定 localhost；Agent 通过 SSH agent 或宿主受控密钥访问，连接参数不包含密码。
- VM 内工具版本、镜像/安装介质哈希和系统快照必须登记。

### 样本和执行边界

- 权威样本唯一来源仍是 <HOST_PATH>/EPT/sample/，身份以已登记 SHA-256 为准。
- 不在宿主执行未知样本；不修改权威样本；不把权威样本复制到 REMnux。
- 如需读取权威样本，必须另建受控、只读访问通道并保留来源、访问时间和 SHA-256；动态运行仍限定在现有 Windows Guest 规则内。
- REMnux 工具返回的静态能力标签、IOC 或熵值不能单独证明 EPT 授权、解码或后行为成功。

## 5. Ghidra MCP 契约

### 角色

Ghidra 作为反编译和交叉引用节点，首轮只要求：

- 导入无害 PE 测试样本并记录格式、架构、编译器识别结果；
- 列出函数、字符串、imports/exports；
- 对指定函数读取反编译结果；
- 查询 callers/callees 和 xrefs；
- 对有限目标进行重命名、注释或数据类型标注；
- 导出项目/程序元数据和操作日志。

### 部署和传输

- 固定为 Ghidra 12.1.4 + GhidrAssistMCP 2.11.0；tag commit 和官方发行包 SHA-256 已登记。
- Ghidra 12.1 官方 Getting Started 要求 Java 21；当前 Temurin 21.0.12.1 保留并直接使用，不覆盖默认 Java。
- GhidrAssistMCP 是 Ghidra 插件内 HTTP MCP server，支持 SSE 和 Streamable HTTP，默认 localhost:8080；它不是 stdio server。
- GhidrAssistMCP 源码构建要求 Java 25+；当前部署采用官方二进制 extension，不安装 JDK 25。只有需要重建插件时才侧装 JDK 25。
- 优先使用成熟项目提供的原生 MCP、headless 或 CLI 接口，不新建 Ghidra RPC/Tool Hub 层。
- MCP 服务默认 localhost 或经 SSH 隧道访问；禁止无保护的公网/局域网监听。
- Ghidra 项目和重建对象持久化到 artifacts/agent/ghidra/ 或 artifacts/captures/，不把大型项目对象写进普通 evidence。

### EPT 使用方式

- 优先分析已收回的 dump、脱敏派生物和无害 PE，保留 evidence_scope。
- 不能把 Ghidra 的静态反编译结果当作 target_native_return、target_caller_diff_bytes、RC03/RC06 或解码后行为证据。
- 对 VMProtect 高熵/虚拟化区域，报告工具边界和置信度，不把线性反汇编当作完整调用图。

## 6. Agent 决策链

Agent 不执行固定流水线，应依据 case 和证据选择节点：

    输入 case
      -> 身份/哈希/来源检查
      -> REMnux：文件、字符串、IOC、能力和原始静态 artifact
      -> Ghidra：函数、xref、反编译和有限标注
      -> Windows Guest + CDB：仅在动态假设已形成且符合当前实验门槛时进入
      -> 合并带 evidence_scope 的报告

每个工具调用至少记录：

    case_id
    input_sha256
    sample_lineage
    node
    node_version
    transport
    command_or_tool
    arguments
    stdout_path
    stderr_path
    artifact_paths
    status
    failure_class

通信成功、MCP tool list、调试器 smoke、进程存活、超时或磁盘哈希变化都不能直接升级为业务成功/失败。

## 7. 最小验收测试

### 测试 A：REMnux 静态节点

使用无害 PE，不使用 EPT 权威样本：

1. Agent 建立 SSH/stdin MCP 会话。
2. 获取工具列表和版本。
3. 计算输入 SHA-256。
4. 完成文件识别、字符串、PE 元数据和 IOC 提取。
5. 收回原始 stdout/stderr 和结构化 JSON。
6. 停止服务或关闭 VM，验证 artifact 仍在宿主。

### 测试 B：Ghidra 节点

使用同一无害 PE：

1. 创建固定版本 Ghidra project。
2. 导入并分析程序。
3. 查询函数、字符串、imports/exports。
4. 对一个已知函数获取反编译和 xref。
5. 导出项目元数据、操作日志和 SHA-256。
6. 重启节点后验证项目可读。

### 测试 C：Agent 决策

给 Agent 一个带哈希和来源的无害 PE case，要求其说明：

- 先调用哪个节点以及原因；
- 哪些字段需要静态证据；
- 哪些问题必须转给 Windows Guest/CDB；
- 哪些结论仍为未知；
- 是否生成了完整 artifact 索引。

## 8. 实际部署状态、指导 Skill 和未完成项

- REMnux MCP：官方 package 0.1.75 已安装到 <HOST_PATH>/CTF/reverse-lab/mcp/remnux-host；固定 Node 24 下 version/help smoke 通过。配套 Skill 已安装；独立 REMnux VM 和 SSH endpoint 尚未配置，因此测试 A 的真实 REMnux 工具链仍待执行。
- Ghidra 12.1.4：已安装到 <HOST_PATH>/CTF/reverse-lab/tools/ghidra_12.1.4_PUBLIC；Java 21 benign PE import/analysis 通过，project 为 <HOST_PATH>/CTF/reverse-lab/projects/smoke2。
- GhidrAssistMCP 2.11.0：已安装到该 Ghidra 版本专用用户 Extensions；headless localhost HTTP MCP smoke 通过，initialize HTTP 200、tools/list 返回 46 工具、get_binary_info 读取 notepad.exe 成功；测试后已停止服务。配套 Skill 已安装。
- SSH key/agent、REMnux VM、localhost transport 的持久化 MCP client 登记和宿主 artifact 收割脚本：待配置。
- 测试 A：REMnux package smoke 已完成，真实 REMnux 分析节点待接入。测试 B：Ghidra/GhidrAssist benign PE 已完成。测试 C：Agent 节点选择和 evidence_scope 的流程已写入 method/AGENT_STATIC_ANALYSIS_WORKFLOW.md，尚未用真实远端节点执行。
- EPT 真实样本的 sample_launch_requested 仍必须保持 false；无真实卡密时不启动目标。

## 9. 冲突处理结果

- 保留系统 Node 24.21.0：满足 REMnux MCP 的 Node >=20，不安装第二个系统 Node，不改 PATH。
- 保留系统 Temurin Java 21.0.12.1：满足 Ghidra 12.1；不为 GhidrAssistMCP 二进制包安装 JDK 25。JDK 25 仅在未来需要源码重建插件时侧装。
- 保留现有全局 npm 包：REMnux MCP 使用独立 prefix，不做 global install。
- 8080/3000 在冲突审计时均空闲；8080 仅用于临时 smoke，结束后已释放。
- Ghidra、GhidrAssistMCP、REMnux host package 均位于 reverse-lab 独立目录，不覆盖 EPT、C173 VM 或现有工具目录。
