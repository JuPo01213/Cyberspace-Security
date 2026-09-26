# C208 · 靶机通信方式与成熟工作流对照审查

> 公开协作副本说明：保留本次审查选取的对话/事件切片和结论；主机路径、用户名、主机/VM 标识、私有仓库标识及 IP 已按仓库规则脱敏。未包含完整平台会话数据库。

日期：2026-09-27（Asia/Shanghai）
范围：EPT 的历史 VM 通信与证据收割；CodeBuddy、WorkBuddy、ZCode 记录；现有 Codex skills/workflows；厂商和沙箱官方文档。
本件为历史与当前能力审查；未连接或操作 Guest，未运行样本。

## 结论摘要

历史实际用过两代通信栈。早期以 VirtualBox 为主：宿主 `VBoxManage` 管 VM，`guestcontrol run/start/copyto/copyfrom` 执行和传文件，SSH/SCP 作网络诊断或备用收割，Shared Folder/本地 spool 作辅助数据面；部分命令从 WSL 调 Windows 工具。后续当前主线转到 Hyper-V：VM cmdlet 管生命周期，PowerShell Direct 控制 Windows Guest，持久 `PSSession` 上的 `Copy-Item` 收发文件，SMB 只读共享提供样本输入，Guest 本地 spool 和 Host 端收割文件承担运行记录。CDB 是 Guest 内观察器，不是通信通道本身。

这些路径按运行记录认定，不能把每种工具机械归给某个平台产品：同一个项目跨 ZCode、CodeBuddy、WorkBuddy 和 Codex 迁移过目录、VM 与 runner。会话平台、工作目录元数据和生成摘要不能替代每轮 `run_id` 的真实 adapter 记录。CodeBuddy 的旧轮明确走 VirtualBox/GuestControl 与 SSH/SCP；C173 起的工作明确走 Hyper-V/PowerShell Direct；ZCode 的 2026-09-25/26 run 元数据也明确记录 Hyper-V PowerShell Direct。WorkBuddy 会话内有通信工作流与事故复盘，但其主 JSONL 对应切片没有足够原始用户轮次来证明所有早期 VM 动作的产品归属。详见 C206 原始来源索引。

第一性原理下，通信成功的标准不是“连上了”，而是对目标任务证明：正确 Guest/样本身份、命令确实在预期身份上下文执行、数据在预期路径被 Host 实际取得、长 runner 不依赖临时控制会话、观察器有效、完成状态与业务证据能按同一 run 关联。任何一环不成立，只能给对应通道或仪器结论，不能给样本阴性或业务完成结论。

## 实际失误切片与当时处理

**通道就绪与健康信号混淆。** C132 中 VirtualBox VM 已运行，但 GuestControl 多次处于 `starting`；SSH 仅等到 banner 超时，屏幕截图曾返回 0 字节/E_FAIL。其他轮次 GuestControl 登录认证失败，而 SSH banner 可见。C174 I-02–I-07、C168 均支持这些是不同层次：VM 状态、Guest Additions 状态、网络端口/banner、身份认证、命令执行并不等价。后来采用 Guest 内短命令和新 nonce、把 SSH banner 与认证/命令拆开、按本次启动重新测 readiness；这是正确的恢复方向。仍需保留“底层 GuestControl wedge 原因未完全定位”的状态，不能把等待更久当成通用修复。

**宿主/客户机输出与文件路径没有正对照。** WSL 调 Windows `VBoxManage` 时 stdout 空但退出码为 0；截图目标路径用了不相容的路径格式；SCP 第一次立即 path-not-found，后续脚本却把它当成“等文件”重复轮询 12 次；Guest spool 父目录缺失也导致 CDB 没有启动。C174 I-01、I-08、I-10、I-26、I-30 记录了这些问题。改用 Windows 侧文件重定向、SCP 前先传一个已知文件、创建并检查绝对 spool 目录、分别保留退出码/stderr/文件存在和 Host 收到的字节，是有效修正。这里失败的主要是未经验证的路径和包装链，不能归因于样本。

**控制会话替代了长任务宿主。** C165 记录 GuestControl 会话结束时，同一会话启动的 runner 也结束；只有启动和部分过程事件，没有 post/delta/done。C132 的长任务期间 GuestControl 与 SSH 同时失活，约 100 MB dump 轮次没有把完整文件收回 Host。事后方案转向脱离会话的计划任务/Guest 本地 spool/独立收割，并限制大文件，但 C173 只证明短命令和短时 CDB smoke；C174 明确长 runner 独立性仍待真实 canary。不能把“用 Scheduled Task 启动”自动等同于已证明生命周期独立。

**网络或数据通道的局部成功被当成全链成功。** SSH banner 可达时认证仍可能失败；VirtualBox share 配置存在时 Host 源目录、Guest mount、目标 ACK 仍可能不存在；PSSession 建立后也不继承其他用户的 SMB 磁盘映射。C174 I-05/I-06/I-32 显示，后续正确做法是分账户、分上下文做读写/哈希 canary。C173 的 SMB Share Read + NTFS RX 配置与 Guest ACK/样本 hash 匹配支持读路径，但 `read_only_write_test=NOT_RUN`，所以“只读强制有效”仍未实测；另一个 <VM_USER> PSSession 的 SMB 复读也明确 defer，不能记作已通过。

**完成 marker 和调试器设置声明被误当作实际命中。** C145 有内部 calltarget 命中，却缺 `CDB_DONE`、POST 和返回/调用者数据；C173 CDB canary 曾有一轮参数噪声，随后干净 benign smoke 成功。C206 记录 2026-09-26 run 02 找到子进程并附加 CDB，但日志只有 FatalExit/Exit 断点设置、没有命中标记；最终 runner 静态写入 `gate_reversal_applied=fatal_exit_branch_skip`，同时 `target_native_return`、caller 差异、RC06、post-decode behavior 都是 `NOT_OBSERVED`。这不是 PowerShell Direct 失效的证据，而是观测器/闸门证据没有闭合，且完成字段写得比事实强。后续应要求原始 CDB 事件、目标进程与 RunId 关联、Host 已收割的日志和真实目标状态共同支持字段；配置值或最终标签不能证明运行时发生。

**不同运行的观察不能拼成因果链。** C165 中无调试器轮观察到 child 创建，而调试器轮没有；其采集路径、运行窗口和完成收割并不相同。记录正确承认这是差异但非反调试因果。C163/C164 孤儿进程还污染了后续基线；同 RUN_ID 复用、路径漂移和 Guest 时间变化也扩大了歧义。应固定每轮唯一身份、进程 PPID、样本哈希、baseline 和 observer，并把 debugger/natural 模式分开。上述后果是工作流设计问题，非“多重试几次通信”可修复。

## 与成熟工具语义对照

**VirtualBox Guest Control。** Oracle 文档明确需要 Guest Additions；执行和复制类子命令需要 Guest 凭据。`run` 把 stdin/stdout/stderr 接到 Host，并等待 Guest 程序完成；`start` 在程序成功启动后返回，不等待全部输出读取；`copyto/copyfrom` 是独立传输操作。因此短探针用 `run` 合理，长实验应由 Guest 自管 spool/完成 marker，再通过独立通道收割；把长 runner 的退出绑定在短控制会话上与其生命周期语义冲突。历史中后期已有这个方案，但早期没有先通过独立长任务 canary，落实不一致。[Oracle VBoxManage](https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/vboxmanage.html) 与 [Guest Additions](https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/guestadditions.html)

**SSH/SCP。** OpenSSH 是客户端—服务端架构；SSH banner 只说明服务有响应，不能证明认证或命令执行；SCP 是经 SSH 传文件。历史记录把这几步拆开的做法是正确的，但早期 SCP 路径未正对照、超时循环还掩盖立即路径失败，违反了该通道最基本的 canary 要求。[Microsoft OpenSSH overview](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh-overview)

**Hyper-V PowerShell Direct。** 官方支持本地运行的 Hyper-V Windows Guest；Host/Guest 版本、VM running、Guest 用户 profile、Hyper-V 管理权限与有效 Guest 凭据都构成前提。`Invoke-Command` 是单次命令/脚本，结束后连接关闭；持久 `New-PSSession` 可被多次复用并以 `Copy-Item` 收发文件。C173 与 9/25–26 run 使用持久 PSSession 的方向符合语义，且控制 nonce、CDB benign smoke、短文件收割实际成功；但这只证明当时的短控制/传输链，不能推出 Guest 进程独立于 session，也不能推出 CDB 目标断点必然命中。[Microsoft PowerShell Direct](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct)

**沙箱架构参考。** CAPE 使用 Guest 内 HTTP agent，要求提升权限并建议在保存 snapshot 前验证；这说明成熟沙箱通常把 Guest agent、Host 调度/任务状态和 artifact 收割作为一体设计，而不是靠一个 SSH/GuestControl 命令承担全生命周期。[CAPE agent](https://capev2.readthedocs.io/en/latest/installation/guest/agent.html) 但 CAPE 是一整套沙箱服务栈，其官方安装路线推荐 Linux/KVM，当前 Windows Hyper-V 环境并无可直接复制的小型工具。DRAKVUF 当前文档要求 Linux/Xen 并明确写明 Hyper-V 不工作，故不是此工作区的可迁移后端。[CAPE installation](https://capev2.readthedocs.io/en/latest/installation/host/installation.html) · [DRAKVUF requirements](https://drakvuf-sandbox.readthedocs.io/en/latest/usage/getting_started.html)

三平面（控制、数据、完成）适合用来拆分职责，但不是一个跨厂商统一标准，也不能替代特定 adapter 的运行语义。成熟的是组成机制：Hyper-V/VirtualBox 的原生 Guest 接口、OpenSSH、Guest agent、持久/可恢复任务状态、Guest spool 与 Host 收割。将这些机制组合成 EPT 工作流需要按当前 hypervisor、sample isolation 和目标扰动重新验证。

## 现有工作流是否发挥作用

**VirtualBox 阶段：早期执行偏离明显，后期改进有效但不彻底。** `C132/C165/C166` 在控制、数据、长 runner、完成状态没有分别验证时进入目标运行，通信失效导致关键证据无法收割；C174 后来的事故分类是有价值的补救，但没有挽回此前已丢失的 run 后态。SSH/SCP 和共享目录被定义为备用通道时，也有路径和身份上下文未经 canary 的情况。

**Hyper-V 阶段：控制与小型数据收割有效，业务闭环仍未实现。** C173 的真实证据支持 PowerShell Direct 控制、Guest ACK、样本哈希对齐、checkpoint restore 和 Guest CDB 对 benign 进程 smoke 可用。它没有启动样本；长 runner 持续性和 SMB 写拒绝没有验收。9/25–26 使用计划任务与 spool 后，能取得父子进程、CDB 输出和部分文件快照，证明通道确有产出；同轮 seam、caller 差异、RC06 和后行为仍未观察，配置还来自 `historical_forced_run_capture`。因此成熟通信栈帮助控制和收割，却没有让错误的干预或无命中的仪器自动成为目标证据。

**总体判断：部分发挥、未达全链预期。** 根因不是缺少一个“业界万能工具”，而是早期把运行样本当成通道 canary、把一次连接或一段 stdout 当成多层验收。后来虽形成了良好的分平面、nonce、唯一 RUN_ID、收割与故障分类规则，但没有把“控制可执行、数据可往返、runner 脱离、仪器命中、完成事件可被 Host 验证”做成实际启动目标前必须通过的 fail-closed gate。另一方面，具体 run 的闸门目标与断点是否执行也出现独立失误，不能把所有未闭合都归因于通信。

## Cyberspace 仓库调研记录交叉核验

在 GitHub 插件找到并只读检查了 `<REDACTED_USERNAME>/Cyberspace-Security` 默认分支 `<REDACTED_USERNAME>-upload-course-sample`。主调研件是 [不稳定 Windows Guest 实验：成熟模式与复用边界调研](../../../../research/windows-guest-experiment-reliability-patterns.md)，日期为 2026-09-25。它明确得出：没有一个标准同时覆盖 Windows malware VM、durable execution、多 Agent writer ownership、artifact provenance 和 debugger interference；应该组合成熟原语，做薄的场景适配，不自建一个小型 workflow engine。这个结论与本报告一致。

该调研记录把问题映射到 CAPE/Cuckoo Guest 生命周期和 Result Server、Temporal durable execution、Kubernetes Lease/CAS、CASE/W3C PROV；同时把 hypervisor/control adapter、Windows Session 0、CDB smoke、样本 acceptance 留作项目 profile。它支持本报告的主要判断：组件成熟不代表跨平台工作流已经被正确执行；每个具体 Guest、会话、数据路径和观察器仍要 canary，且业务 acceptance 必须由项目契约定义。

同仓库的 `history/guest-communication-workbench-v3/README.md` 和 `skills/guest-communication-workbench/SKILL.md` 将 v3 标为 LEGACY，说明其 Host Authority、三平面、OP_ID、Goal Gate 等有复盘价值，但多文件 STATE/event/lease/handoff 数据模型不应整体继续扩展。故这些文件用作历史经验来源，不把其每项字段或流程机械迁入 Codex。

仓库本身还有一个当前入口指针冲突：上述调研件称当前入口为 `.agents/skills/windows-guest-experiment/SKILL.md`；历史目录 README 却指向 `playbooks/windows-guest-experiment/PLAYBOOK.md`，而该 Playbook 首页又标成 `LEGACY / 历史设计`。因此不能仅凭仓库某一份文档的“current”字样确定规范权威。此次以用户提供的当前 EPT `AGENTS.md` 与最新要求为准，GitHub 记录用于核对来源、成熟模式和历史决策。

仓库内直接相关的历史切片为 [C180A 问题切片](../../../../history/guest-communication-workbench-v3/incidents/C180A_problem_slices_20260925.md)；EPT 路径下也保存了 C173/C174 通信验证与事故登记，可与本地 C173/C174 文件交叉核验。

## Codex 迁移与修订

能力清点表明，关键工具/文档已经在 Codex 可用目录：`windows-guest-experiment` 已有只读 `preflight.ps1`、Hyper-V/VirtualBox/SSH/SMB/CDB adapter 指南、失败路由、runbook 与 fallback 模板；`reverse-engineering-workbench` 已有 `vbox_comm.sh`、SSH process probe 和三平面通信参考。WorkBuddy 的材料是 skill、incident catalog 和 JSON 模板，没有额外可执行通信程序；ZCode/CodeBuddy 的重复 Guest communication skill 也没有脚本。故本次没有再复制一套重复工具，也没有新造通信 adapter。

本任务的只读 Host 清点显示 `Get-VM`、PowerShell Direct 所需的 `Invoke-Command -VMName`/`New-PSSession -VMName`、`ssh.exe` 和 `scp.exe` 可用；当前 VBoxManage 与 Host 侧 CDB 不可用。C173 Guest tool inventory 已确认 Guest 内有 CDB，因此 Host 缺少 CDB 不等于 Guest 无法调试。当前 Codex 的后端选择应为 Hyper-V PowerShell Direct；VirtualBox/SSH adapter 只在相应工具与 Guest 前提实际满足时使用。本轮未连接 Guest。

Codex `.agents` 中的 `windows-guest-experiment`、`reverse-engineering-workbench` 及其通信 helper 已与 ZCode `.zcode` 副本逐文件核对一致；这些核心工具材料事实上已迁移到 Codex。此次只修订 Codex 当前采用的文档，未反向覆盖其他平台副本。

Codex 侧已执行的整合：

- 更新 `method/COMMUNICATION_PLAYBOOK.md`：把早期 VirtualBox/`lab.ps1` 路径标成历史 adapter，改为按当前可用 hypervisor 选择，并要求控制、数据、runner 生命周期和完成面分别 canary。
- 调整 Codex `windows-guest-experiment` 的定位和 adapter 说明：工作流/skill 是候选方案，当前任务契约优先；明确 VBox `run`/`start` 生命周期差异，补上 Guest 子进程的 benign attach smoke 与“Host CDB 不存在≠Guest CDB 不存在”。
- EPT 专项 skill 保留样本身份、授权门槛、同 run 业务验收；通用通信细节仍由 WGE 承载，避免新增并行 `guest-communication-workbench`。

本次没有执行 Guest 动作、安装 CAPE/DRAKVUF 或迁移它们的服务栈。C208 审查原始来源与限制见 [C206 跨平台问题切片](C206_cross_platform_issue_slices_20260927.md)、[C207 第一性原理审查](C207_cross_platform_first_principles_review_20260927.md)、[C174 通信事故记录](C174_guest_communication_incident_register_20260924.md)、[C173 工作流评估](C173_mature_workflow_assessment_20260924.md)、[C132](C132_real_decode_arm_instrument_failure_20260922.md)、[C165](C165_natural_deployment_vs_debugger_20260923.md)、[C168](C168_channel_preflight_host_20260923.json)、[EPT-AUTHGATE run metadata](../../runs/EPT-AUTHGATE-20260925-36/run.json)、[C206 引用的 9/26 run events](../../runs/EPT-AUTH-LOCAL-GATE-REV-20260926-02/events.ndjson)。
