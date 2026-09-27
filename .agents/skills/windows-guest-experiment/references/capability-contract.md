# Windows 分析能力契约

本参考定义通用工作流与具体实现之间的边界。高层只声明需要什么能力，低层实现不得反向改变任务语义、证据标准或分析目标。

## 依赖方向

```text
任务契约 / 证据要求
        ↓
通用分析流程
        ↓
分析 runtime 契约
        ↓
Guest 工具能力
        ↓
虚拟化与通信后端
        ↓
本机名称、路径、地址和凭据
```

只允许上层选择或约束下层。以下推导无效：

- Host 安装了某个 hypervisor，不等于通用流程必须使用它；
- 某台 VM 已经存在或正在运行，不等于它是标准分析 capability；
- 某个工具已安装，不等于整条任务、证据和清理链路已经闭合；
- 某次任务需要特殊启动、调试或网络干预，不等于后续任务都应固化该步骤；
- 某个本地适配器更容易调用，不等于它可以取代更高层 runtime。

## 分层职责

### 任务契约

由当前项目或单次任务定义：目标身份、允许的干预、网络边界、证据要求、完成条件和清理要求。它不进入通用 Skill。

### 通用分析流程

定义稳定阶段：解析需求、选择能力、恢复基线、提交任务、观察状态、取得产物、解释证据和回滚。它不包含机器名、地址、账号、样本路径或一次性参数。

### 分析 runtime

负责其声明覆盖的 task/job、状态、结果、artifact、retry 和可选 debugger。CAPEsolo 是当前推荐实现之一；推荐实现不能反向成为通用接口本身。

### Guest 工具集

FLARE-VM、DbgEng、Procmon、Noriben、FakeNet-NG 等提供具体分析能力。工具存在只证明该工具可候选使用，不证明环境整体 ready。

### 基础设施后端

Hyper-V、VMware、VirtualBox 或其他成熟平台只负责其声明覆盖的基础设施能力。一个可用于正式分析的后端至少要按当前任务需要提供并验证：

- VM start / stop / status；
- checkpoint create / restore / identify；
- bootstrap 网络与隔离分析网络之间的受控切换；
- Host → Guest command/control；
- Host ↔ Guest data/artifact；
- 需要 GUI 时的真实交互 session；
- runtime / debugger 所需的隔离连接。

PowerShell Direct、Guest Control、SSH、SMB、VMConnect 和 provider CLI 都只是这些能力的实现，不属于通用任务语义。

## 能力登记

公开 Skill 只定义结构；真实绑定保存在本机或部署环境的私有配置中。最小登记形状可以是：

```yaml
windows_dynamic_analysis:
  status: ready
  environment: <local-environment-id>
  guest_base: flare-vm
  runtime:
    kind: <runtime-kind>
    entry: <verified-entry>
  infrastructure:
    provider: <hypervisor-or-platform>
    checkpoint: <verified-checkpoint>
    control: <verified-control-channel>
    data: <verified-data-channel>
    network: <verified-isolated-network>
    gui: <verified-gui-channel-or-null>
  last_verified: <timestamp>
```

真实 VM 名称、IP、token、密码、Host 路径和当前状态不得写入公开 Skill。`ready` 必须来自端到端验证，不能由“组件已安装”推导。

## 选择规则

1. 先由任务契约列出必需能力和安全边界。
2. 再从已登记环境中筛选真正满足这些能力且验证仍有效的候选。
3. 多个候选都满足时，优先使用最高层成熟入口、切换成本低、维护负担小、隔离和收割更可靠的环境。
4. 没有候选时，建设缺失能力；hypervisor 由部署环境选择，不在通用 Skill 中固定。
5. 更换 hypervisor、runtime 或关键通信后端后，重新做对应 canary 和端到端验证，不能继承旧环境的 `ready`。

平台可替换不等于未经验证即可互换。替换的是后端实现，不是任务语义、证据要求或完成条件。

