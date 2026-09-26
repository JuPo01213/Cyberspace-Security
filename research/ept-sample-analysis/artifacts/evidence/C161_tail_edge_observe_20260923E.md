# C161：尾跳后继边只观测（2026-09-23）

## 结论

状态：**PARTIAL / CDB_ENTRY_CONFIRMED / TAIL1_AND_TAIL2_MARKERS_RECORDED / F060_RC03_NOT_REACHED / WAIT_TIMEOUT**。

本轮使用 CDB 在 Guest 内启动目标，未写入任何机器码。原始 CDB 日志中有独立行 `[C161_ENTRY]`、`[C161_TAIL1]`、`[C161_TAIL2]`，分别位于行 63、76、96。日志上下文确认 `[C161_TAIL1]` 命中时 RIP=`0x143c780e2`，现场首指令为 `push rbx`；`[C161_TAIL2]` 命中时 RIP=`0x143ca323e`，现场首指令为 `mov qword ptr [rsp+rcx*8-50h],r15`。两个断点在本次运行中先后命中，但单凭这两个 marker 不证明执行了两点间的特定控制流边。静态捕获显示 `0x143c780fe` 无条件跳转至 `0x143ca323e`；这是静态 CFG 证据，不等同于该跳转指令在本次运行中被单步/分支跟踪确认。F060 与 RC03 marker 未命中。runner 在 45 秒硬 deadline 后收尾为 `WAIT_TIMEOUT`。这些观测不证明业务授权或机器码修改。

核心闭环仍未满足：没有同一次运行中的 `native_return == 0x1`、`changed_bytes > 0`、caller `+0x80` 前后缓冲，也没有可归因的修改前后指令字节、部署行为或日志清理证据。

## 运行身份与执行面

| 项 | 值 |
|---|---|
| run id | `EPT_RC00_TAIL_EDGE_OBSERVE_20260923E` |
| VM | `<OTHER_VM_LABEL>`，UUID `8d0b85c0-ed29-47c7-9fe1-21bc706a057a` |
| 当前快照 | `qoder-armed-20260919` |
| 目标映像 | `C:\ept_core\Hardware.exe` |
| 样本 PRE/POST SHA-256 | `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` |
| runner | `<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_EDGE_OBSERVE_20260923E.ps1` |
| runner SHA-256 | `9BE8CDDBB43B9D1A7B7BDC150B1552706E37C7777028CE8CE0933EA66734C380`（运行时投递版本） |
| CDB 参数 | `-k [REDACTED] -n 2 -m 1`；日志未含卡密明文 |
| runner deadline | 45 秒 |
| runner 状态 | `WAIT_TIMEOUT`，CDB exit code 未取得 |
| 收尾 VM 状态 | `running`；快照未变化 |
| E: 可用空间 | 收尾约 276.6 GiB |

C161 前，因 GuestControl 持续 `VERR_DUPLICATE`，先读取证据目录、VM 日志和快照树。向 VM 发送 ACPI 关机后未完成；随后确认 GuestControl 与 Guest 服务的 session 状态异常，正常 reboot 请求也未完成。C160 数据已收割后，使用 VBoxManage 正常 poweroff，从已保留的 `qoder-armed-20260919` 快照恢复并启动，没有创建或删除快照。新启动日志出现 NAT `Link up`；恢复后两次独立 GuestControl 短探针均成功。此恢复步骤未运行样本。

## 运行器问题与第一次失败

第一次 C161 runner 因目标目录父目录在快照中不存在而无法写入状态文件，CDB 未启动，归类 `INSTRUMENT_FAILURE`。修复后运行时复制的脚本首次行仍未包含目录创建语句，因此第二次也未进入 CDB；该次 runner 前台调用在 GuestControl 超时。随后确认 Guest 仍有一个由 GuestControl 启动的 PowerShell 进程，使用短探针后该命令返回；runner 的运行日志之后记录 45 秒 deadline 超时。不得把这两次 runner 初始化/仪器问题误报为目标路径结论。

## CDB 原始日志直接观察

原始 Guest spool：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_EDGE_OBSERVE_20260923E\cdb.log`。

| 日志行 | 独立事件行 |
|---:|---|
| 63 | `[C161_ENTRY]` |
| 76 | `[C161_TAIL1]` |
| 96 | `[C161_TAIL2]` |

`[C161_F060]`、`[C161_RC03]` 独立 marker 行均未发现。命中统计来自 CDB 日志的整行精确匹配，不采用 runner `run_meta.markers` 作为唯一依据。CDB 日志中不含输入卡密明文；日志重新脱敏/镜像后 SHA-256 为 `9B02B3D7A2B239D22A9E65CEA0AFD7894609A3011F9E5E0250AB1684831EF4CF`。

## 产物校验

Guest/共享 spool 运行目录：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_EDGE_OBSERVE_20260923E\`。

| 文件 | 字节数 | SHA-256 |
|---|---:|---|
| `cdb.log` | 12,397 | `9B02B3D7A2B239D22A9E65CEA0AFD7894609A3011F9E5E0250AB1684831EF4CF` |
| `post_state.json` | 7,677 | `5F98CBF388163D3B47B46839026755BBC664B60C188AC256B0A985D6B0BE1F5C` |
| `pre_state.json` | 7,676 | `B7D0ADE25F9925CECB1F19874E0ABE7B8D42C30AB0F15B2490E11CE04920EB21` |
| `run_meta.json` | 21,725 | `6CECACBF3EEC6D0CB101B63212A81C0C15FCBF90D84A6BD990A5595AC7C8C6E1` |
| `run.cdb` | 331 | `E84599211C84F5C2CF41F99B259F02FB64B359E39B991075095CF1C4E8397AAD` |
| `runner.log` | 2,414 | `0706AF7808FB9CB5D3AF7BB3D923FA443A025229BE2E52D019D689985A5698DD` |

`run_meta.json` 因前两次失败共用同一 run id/目录而包含合并/覆盖式历史状态；故其 marker、状态计数不得单独作为 C161 唯一证据。以 runner.log 时间线和原始 CDB 日志为准。

## 证据边界与后续

- C146 动态确认内部 call/tail-jump 入口；C160 动态确认 dispatcher 走到 `0x143c17251`。C161 原始日志上下文已确认 TAIL1=`0x143c780e2`、TAIL2=`0x143ca323e` 两个实际断点 RIP 和现场首指令。另有静态捕获 H12/H13 显示 `0x143c780fe → 0x143ca323e → 0x143a69b86 → 0x143c3b39e → 0x143f5164d` 的无条件跳转链；它是静态控制流证据，不能单独证明 C161 本次运行实际经过链上每一边。
- F060/RC03 未命中，不表示授权逻辑为阴性；它可能是运行路径、观测窗口或仪器限制。
- 未获取目标执行代码页的可靠保护属性；C160 `!address` 扩展失败，不以此推断页面属性。
- 后续不再重复 C161 已命中的 dispatcher/tail 地址。C148/C149 已动态到达 `0x143f5164d`/`0x143e47a9f`，C150 曾记录 AV 但缺少寄存器/栈上下文；若重开动态轮次，优先采用独立 run id/spool 和已验证脚本哈希，在首次 AV 时一次性采集 RIP/RSP、通用寄存器、栈、当前指令、模块归属及 Guest `VirtualQuery` AllocationBase/State/Protect，并立即收割。F060/RC03/RC06 命中时再同轮记录 `native_return`、`changed_bytes`、caller `+0x80` 前后缓冲和代码字节前后对照。启动前必须重新通过 GuestControl/runner/spool 健康闸门；闸门未通过不启动样本。
