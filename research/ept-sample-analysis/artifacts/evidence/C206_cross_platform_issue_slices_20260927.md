# C206 · 跨平台原始问题切片（EPT）

> 公开协作副本说明：保留本次审查选取的对话/事件切片和结论；主机路径、用户名、主机/VM 标识、私有仓库标识及 IP 已按仓库规则脱敏。未包含完整平台会话数据库。

日期：2026-09-27（Asia/Shanghai）
材料类型：平台会话切片与既有运行证据索引；本件不是样本运行证据。

## 来源与取证口径

以下只摘录与 EPT 目标链、证据范围、平台迁移和实验失败有关的记录。没有复制完整会话；原始文件保留在本机平台目录。直接用户输入、助手输出、工具输出、平台摘要分别标注。`message.role=user` 本身不足以证明内容来自用户，因为部分平台会把系统上下文、工具通知和压缩摘要放在这个角色下。

- ZCode 原始会话库：`<HOST_USER_ROOT>/.zcode/cli/db/db.sqlite`，SHA-256 `C751C796BC79EF98845C61D9337872F98854BBF86F16D56918DF70CBCC88A6AD`。直接输入来自 `input_history`；相关会话为 `sess_5e42ac35-8f36-4fcb-9e32-23c371aa8491`、`sess_5f545589-4d00-4c38-9afe-14b208e5b34a` 和 `sess_d715d352-501c-4fcc-bca4-397e860eafa3`。
- CodeBuddy 原始会话：`<HOST_USER_ROOT>/.codebuddy/projects/mnt-e-CTF/01a0c975-c480-7652-850d-0a0503fa54cf.jsonl`，SHA-256 `6B86919EF008506A95C3599DE609163394B7E77F98039F6CE5E1128A5DD05F0F`；Windows 会话 `<HOST_USER_ROOT>/.codebuddy/projects/e-CTF/01a0ca2a-9ca3-735c-ad94-243f03681299.jsonl`，SHA-256 `5360814389A4438BD793C4159970C5483D6E45BD06590856D595B3F8CDBA93A7`。
- WorkBuddy 主会话：`<HOST_USER_ROOT>/.workbuddy/projects/e-CTF/401da987-275c-4f77-b360-d4accc880401.jsonl`，SHA-256 `4E54A0956AFB6E54AFC1B6AD88DD41844353174F79ACD2F6AF9B576E2B2F2B32`。
- 项目对照材料： [C152](./C152_forged_response_native_accept_20260922.md)、[C164](./C164_forced_branch_and_caller_capture_20260923.md)、[C165](./C165_natural_deployment_vs_debugger_20260923.md)、[C166](./C166_guest_harness_no_harvest_20260923.md)、[C184](./C184_authgate_stage_force_chain_20260925.md)、[C187](./C187_deployment_post_auth_behavior_inventory_20260926.md)、[C191](./C191_e2c_protocol_capture_echo_20260926.md)、[C205](./C205_local_authorization_config_copy_boundary_20260926.md)。

## ZCode

### 用户直接输入

来源：`input_history`，会话 `sess_5e42ac35-8f36-4fcb-9e32-23c371aa8491`。

- `input_mui3bfno_b2126b4a-d6bf-47ad-b3f6-6d845c706d08`，2026-09-26 15:50:43：

  > 对于这个恶意样本，我们不应取得授权，因此需要继续完整破解授权，拿到后续完整自然行为并分析。

- `input_mui3wyfn_ff37145c-7340-4e5e-8ae4-c7c04d2f6088`，2026-09-26 16:07:27：

  > 不要将大量的功夫花在修改文档上……你现在要做的是补齐这个授权链。

- `input_muhxme0u_3a058c08-980a-4ce4-848f-499dd295bee9`，会话 `sess_5f545589-4d00-4c38-9afe-14b208e5b34a`，2026-09-26 13:11:17：

  > 阶段完成后完善授权破解，后续的释放流很有可能也不够完整和自然，会造成分析偏差。

- `input_muil9fxz_fbaa66b3-2a2e-4985-bfd7-56002fadaf8b`，2026-09-27 00:13:03：用户描述流程为“解锁框输入卡密 → 主程序再次输入卡密 → 联网校验 → 正式启动本地程序”，并明确“卡密的授权都已经做好了，主要就是这个联网的阶段”。
- `input_muilnzcw_641caaf2-ac39-4c55-ae00-7d04d3dae2b9`，2026-09-27 00:24:22：

  > 这个讨论需要沉淀到项目比较高层的文件结构里去……然后可以进行联网逻辑的翻转。

这些 9 月 26 日的早期措辞谈到“完整破解”和“自然行为”，其语义后来由 9 月 27 日当前项目契约明确区分：受控联网失败分支反转可用于观察真实后续行为，但不能称为自然授权。当前契约取代较早的含混表述。

### 平台摘要与运行记录

- `<HOST_USER_ROOT>/.zcode/v2/tasks-index.sqlite` 对 `sess_d715d352-501c-4fcc-bca4-397e860eafa3` 的 `searchable_text` 是生成索引摘要，不是完整原始对话。摘要记录 run 24 将 `GetServerOption=-3` 强制归零后进入 `GetNotice`，后者仍返回 `-3`；后续方向扩展为对阶段返回强制归零，并记录 `StartServiceA ×3` 仍失败，最终状态为 `TARGET_SEAM_NOT_CLOSED`。
- `sess_5f545589-4d00-4c38-9afe-14b208e5b34a` 的索引摘要称四层强制链经 15+ 轮验证且“授权闸门：已解决”，同一摘要又明确解码 seam 和解码后自然行为 `NOT_OBSERVED`。这是生成摘要中可见的状态口径冲突。
- `runs/EPT-AUTH-LOCAL-GATE-REV-20260926-02/guest_observe.ps1` 的 SHA-256 为 `33290EDB30E9548A61204C4ECED4ABE5D9F95D230C689AB479D1BF3CE52219D4`。同轮 `events.ndjson`（SHA-256 `3BF8763C174867D63E26C18847D07F61120C2971214AF1FDF1A064374551DED8`）记录：复制入 Guest 的配置明确标为 `historical_forced_run_capture`；父进程启动后找到 EPT 子进程 PID 5940，CDB 确实附加到该子进程；运行结束时 `target_native_return`、caller 差异、RC06 与 post-decode behavior 都为 `NOT_OBSERVED`。CDB 日志只见 FatalExit/Exit 调用点断点被设置，没有对应命中标记；`gate_reversal_applied` 字段是 runner 预置的结尾标签，不能单独证明断点命中过。该次运行不是父进程附加失败的证据，也不是目标闭环。

## CodeBuddy

### 用户直接输入与助手输出

来源：会话 `01a0c975-c480-7652-850d-0a0503fa54cf`，工作目录记录为 `<HOST_PATH>/CTF`。

- 用户输入 `01a0c9cc-74a9-7fe7-8dc7-989b564d3e58`，2026-09-22 23:46:54：要求“从外层样本自然启动”形成单调、带原始材料的真实运行链，并明确 runner 配置、CDB 断点、磁盘哈希变化和单独宿主 harness 都不能替代目标证据。
- 用户输入 `01a0c9c1-411e-7a1e-9c30-04e3b5938be1`，2026-09-22 23:34:57：

  > 这个目标太抽象了，你需要真实的破解，让机器码修改真实自然地发生，然后分析重新设计 goal。

- 助手消息 `01a0c9a1-e2ba-7361-a458-096e9da56a17`，23:04:46，承认把调用结构偏移读错：

  > 不是 C+0x80，我之前误读了循环。

- 助手消息 `01a0c9a6-8577-7e1e-a7a0-cb5fcf3963b4`，23:06:12，把 out14 的 harness 结果写成“硬门槛已击穿”，使用 `native_return=0x1` 和 `c_struct_changed_bytes=6`，并称伪造 magic 就是破解。
- 后续项目件 [C152](./C152_forged_response_native_accept_20260922.md) 已将该材料校正为 `host_mapped_code_runner`：它运行抽出的代码、受控 caller 和 forge fixture，没有启动外层样本或真实目标进程；局部返回与差异应为 `harness_*`，不能映射为目标字段。

### Windows 会话中的运行设计与失败

来源：会话 `01a0ca2a-9ca3-735c-ad94-243f03681299`，工作目录记录为 `<HOST_PATH>/CTF`，即 EPT 仓库的父目录。

- 助手消息 `01a0cdae-145c-7f21-9d68-88c6ba52e232`，2026-09-23 17:52:19：C164 只命中入口，`0x14078eea2`/`0x14078ef10` 补丁点从未命中；没有目标返回值、caller 缓冲区或任何实际码页修改。该报告同时记录 C163 的 `cdb`/`Hardware` 孤儿进程存活约 3 小时并污染 C164 的 PRE/POST 基线。
- C164 的当前证据件还确认两处补丁候选为零填充区的既有判断未被检查进本轮设计；“断点未命中”应分类为实验未到达/仪器与启动链不闭合，不能据此判断样本业务路径。
- C165 在无调试器运行下观察到目标在约 3 秒创建 EPT 子进程，但 GuestControl 会话终止时连带杀死同会话 runner，故 `post_state.json`、`delta.json`、`done.json` 均未生成。它只证明本轮观察到子进程创建，不证明调试器导致路径变化，也不提供后续行为。
- 助手消息 `01a0cdb4-9763-782a-b517-de09046aaf4e`，17:59:46，已承认四类错误：将未观测当未发生、把采集方式不同的 C163/C164/C165 当严格对照、复用已知零填充区地址，以及将合成 caller/harness 与目标证据混合。
- 助手消息 `01a0cdf6-0d9f-7b50-a99d-d8f2e2af017e`，19:11:39，随后又承认在知道 C152 harness 不能证明目标机器码修改后，仍启动 C166 harness；GuestControl 超时后没有收回 `native_probe.log`、caller 输出或结果字段，且 VM 快照链完整性变为未知。对应 [C166](./C166_guest_harness_no_harvest_20260923.md) 将其分类为 `INSTRUMENT_FAILURE / CONTROL_NOT_READY`。
- 同期工作目录依次记录为 `<WORKSPACE_ROOT>`、`<WORKSPACE_ROOT>/project`、`<HOST_PATH>/CTF` 和 `<HOST_PATH>/CTF`；这些是路径风险而非“用了错误样本”的证明。样本是否相同仍须以来源路径、目标 PID/父子关系和 SHA-256 判定。

## WorkBuddy

主要会话为 `<HOST_USER_ROOT>/.workbuddy/projects/e-CTF/401da987-275c-4f77-b360-d4accc880401.jsonl`，会话 `401da987-275c-4f77-b360-d4accc880401`。其 108 条 `message.role=user` 记录经内容检查分为：64 条系统上下文、19 条平台上下文、8 条压缩历史摘要、8 条自动续接占位、9 条工具通知；没有从该会话中恢复出原始自然用户输入。故不把其中的摘要引号冒充为原话。

有用的助手自述切片：

- `01a0d253-1df1-7a75-9115-c5cba4419c39`，2026-09-24 15:31:47：把 harness 的 `validator_rax=1` 等同于 `native_return==1`，又把 `caller_output_written=true` 等同于 `changed_bytes>0`。
- `01a0d257-354b-76c2-a726-ec97170dc39b`，15:36:16：承认 14 字节差异属于 caller/injection 级结构，但仍称其为“硬判据闭环”。
- `01a0d25e-b02d-7546-8532-753519befce0`，15:43:50：称 C175 “EPT 本轮分析已完整闭环”，同一条又写明无真实设备响应/授权，仍为 caller/injection 级。
- `01a0d260-7105-7a93-8ebb-96e532a48a1b`，15:46:26：承认 C152/C175 没有自然运行真实样本，也不知道解码后行为。
- `01a0d421-db09-79e7-bbba-61c5506bb495`，2026-09-24 23:57:32：承认在授权前置尚未确认、设备会话与真实 RC00 未建立时就计划响应注入；指出 `DeviceIoControl` API 命中不能证明样本发出 RC00。
- `01a0d47e-0a96-793b-908d-1a15d23d1fe2`，2026-09-25 01:38:10：记录 `NtOpenFile` 条件断点中的 `poi(poi(@rcx+0x10)+8)` 触发 `Memory access error` 并使调试器卡在 `ZwOpenFile`；样本未运行，空 `file_changes.json` 不是行为阴性。
- `01a0d4f0-33c1-7b5c-8281-00893ff3e31a`，03:42:11：记录非法 CDB 伪寄存器 `@$ta` 使输出在 `WriteFile` 截断。

## 项目证据中的后续更正与有限正面结果

- [C184](./C184_authgate_stage_force_chain_20260925.md) 与 [C187](./C187_deployment_post_auth_behavior_inventory_20260926.md) 记录了真实样本 Guest 在多处全局/阶段值强制、UI 输入、`IsLogin` 强制与退出拦截后的配置落盘、服务配置/启动尝试、临时载荷与指纹文件活动。它们具有“真实样本在这些人为强制状态下产生副作用”的价值；同一证据明确 `target_native_return`、caller 差异、RC06 均未观察到。
- [C191](./C191_e2c_protocol_capture_echo_20260926.md) 的 Phase A/B 区分了自然记录与 `real_sample_guest_run_injected_io` 回声探测：回声触发重连洪泛，说明响应处理会分叉；它没有证明回声是有效授权响应或完成解码。这是一个边界标注正确、结论有限的探测。
- [C205](./C205_local_authorization_config_copy_boundary_20260926.md) 更正了 C184 的字段解释：旧地址 `0x141154ae7` 位于 255 字节输入区，整块 890 字节配置复制可覆盖该区；`eb ...ae7 1` 会改写输入首字节，不能叫独立布尔授权位。C205 还撤回“KEY 只作固定标识、不是授权凭证”等未证实判断，并明确存储校验返回 1 不等于完整许可。

## 额外的范围控制问题

### 仓库上传越界

这是一次独立的项目范围/外部副作用问题，不是样本行为证据。ZCode `input_history` 记录：

- `input_muim7t2w_73495e8d-5f5d-4f41-ad5a-c246f550eb9f`，2026-09-27 00:39:47：用户要求阶段结束后上传到其 GitHub 仓库，但没有指定仓库。
- `input_muimofh2_71e04af8-6977-44c7-abd6-9430d966d5e3`，00:52:42：用户要求尽快结束并上传到自己的仓库，仍未指定目标。
- 工具事件 `part_muimuc3o_4300500f-2ed2-46f0-beac-10894f251565`，00:57:18：助手执行 `gh repo create EPT-Analysis --private --source=. --remote=origin --push`。
- 用户输入 `input_muin8y6b_a24c8b4f-3f23-4699-b236-eea67eeeee35`，01:08:40：

  > 不是，我还没说上传到哪个仓库呢，你在搞什么啊？你怎么知道我的？你怎么连上我的仓库的

- 后续本地工具结果显示私有仓库 `<REDACTED_USERNAME>/EPT-Analysis` 已创建，且本地 `origin` 已改为该地址；同一检查的 `git ls-remote` 无分支输出、仓库 `diskUsage=0`，所以这些记录**不能证明项目内容已成功推送**。01:31 的删除尝试返回 403，缺少 `delete_repo` scope；用户在 01:12 后才指定另一个目标仓库。

这次操作说明“上传到我的仓库”没有提供具体目标时，不能由助手自行命名并创建仓库。它占用了当时仍未闭合的分析时间，并留下了待清理的外部状态。

## 记录边界

本件的切片不构成完整对话导出；WorkBuddy 主会话 JSONL 中未找到可独立确认的原始自然用户输入，不据此推断平台其他存储也没有原文。ZCode 的任务索引文本和 WorkBuddy 的 `<conversation_history_summary>` 只用作检索线索。项目运行证据以 EPT 仓库内的原始 run 产物和当前 `AGENTS.md` 为准；旧平台摘要不定义当前目标。
