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
  status: ready_for_task
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
  capability_evidence:
    "<capability-name>":
      status: ready_for_task
      evidence: <host-verified-artifact-or-run-record>
      verified_at: <timestamp>
      scope_or_limit: <what-this-evidence-does-and-does-not-cover>
  last_verified: <timestamp>
```

真实 VM 名称、IP、token、密码、Host 路径和当前状态不得写入公开 Skill。顶层状态只是摘要；每个任务只可使用 `capability_evidence` 中有证据且范围覆盖本任务的能力。未登记的能力保持 `unknown`；某一项端到端 canary 只证明它实际覆盖的部分，例如 control/data canary 不证明 debugger 或完整收割可用。`last_verified` 不能替代逐项能力证据。

### Readiness 状态

对每项能力分别记录：

```text
discovered
  → installed
  → configured
  → bound
  → consumer_handshake
  → benign_task
  → harvestable
  → ready_for_task
  → ready_for_run
```

`installed` 只说明组件存在；`ready_for_task` 还要求入口、持久配置、消费者握手、无害调用和 Host 收割都已证明，并记录范围和限制；`ready_for_run` 还要求当前 Guest、任务身份、路径、schema、通信 profile 和运行上下文对齐。两者都不等于目标业务成功。

能力记录应包含 `evidence_source`（`upstream_official`、`curated_secondary`、`project_evidence` 或 `local_observation`）、`consumer_action`、`scope`、`limitations`、`invalidated_by` 和 `evidence_path`。安装成功、版本可读、`--help` 成功或单个回显 probe 不能直接升级为 `ready_for_task`。

### 登记位置与发现顺序

先复用项目、组织或分析平台已经声明的 capability registry；不得为了满足本 Skill 再造第二份权威登记。没有更高层登记时，使用用户级文件：`$CODEX_HOME/capabilities/windows-analysis.yaml`；若 `CODEX_HOME` 未设置，则使用 `~/.codex/capabilities/windows-analysis.yaml`。真实配置只保存在该部署环境，不进入共享仓库。

登记文件不存在表示“尚未登记”，不表示“没有可用环境”。此时先按当前任务所需能力做只读发现，再验证候选；只有确认没有满足要求的候选，才进入环境建设。环境建成后，须在所声明的 registry 位置登记；若该位置不可写或任务不允许持久化，则报告未登记状态和 Host 可核验的验证证据，不另建平行文件。

`last_verified` 应关联可核验的验证记录，而不只是填写日期。环境身份、Guest 基线、hypervisor、runtime、账户/上下文、关键通信后端、数据路径或收割路径发生变化后，相关 capability 退回 `unknown` 或 `needs_revalidation`；执行具体任务时仍需验证该任务依赖的能力，不能只凭历史状态放行。

### 增量复核

建设阶段已经验证且登记的能力默认复用。只有环境或 profile 发生变化、证据过期/冲突、当前任务需要未覆盖模式，或当前对象无法确认时，才做增量核对。每次核对先写明发生了什么变化、它会改变哪个决策和最低充分证据；能力核对失败只能说明能力状态未知或失效，不能直接说明样本业务失败。

## 选择规则

1. 先由任务契约列出必需能力和安全边界。
2. 再从已登记环境中筛选真正满足这些能力且验证仍有效的候选。
3. 多个候选都满足时，优先使用最高层成熟入口、切换成本低、维护负担小、隔离和收割更可靠的环境。
4. 没有候选时，建设缺失能力；hypervisor 由部署环境选择，不在通用 Skill 中固定。
5. 更换 hypervisor、runtime 或关键通信后端后，重新做对应 canary 和端到端验证，不能继承旧环境的 `ready`。

平台可替换不等于未经验证即可互换。替换的是后端实现，不是任务语义、证据要求或完成条件。


