# C165：无调试器自然部署观测（2026-09-23）

## 结论

状态：**PARTIAL / NATURAL_CHILD_DEPLOYMENT_OBSERVED / DEBUGGER_NO_CHILD_OBSERVED / CHANNEL_WEDGE_RECOVERED**。

本轮首次在**不附加调试器**的条件下运行目标，并取得了 C163/C164 两轮调试器观测都没有拿到的东西：**目标在第 3 秒就创建了子进程**。

```text
2026-09-23T09:34:02.8839655Z|TARGET_STARTED|pid=8928
2026-09-23T09:34:06.1501874Z|PROC_SEEN|8928|4720|Hardware.exe|09/23/2026 17:34:02
2026-09-23T09:34:06.1501874Z|PROC_SEEN|6272|8928|EPT_FB927D78_7CFC6390.exe|09/23/2026 17:34:05
```

- 目标 `Hardware.exe` pid 8928，父进程 4720（本轮 runner 的 PowerShell）。
- 子进程 `EPT_FB927D78_7CFC6390.exe` pid 6272，**父进程 = 8928**，创建时刻 `17:34:05`，即目标启动后约 **3 秒**。

对照：C163（35 s）与 C164（150 s）都在 `.childdbg 1` 下运行，**整轮没有任何子进程创建事件**，也没有 `[C164_CHILD_ENTRY]` 之类的子进程 marker。同一个样本、同一参数、同一快照差异（qoder-clean-20260920 / qoder-armed-20260919），唯一系统性差别是**是否附加 CDB**。

因此可以确认的事实是：**在本项目的观测条件下，附加调试器的运行没有观察到子进程部署，而不附加调试器的运行在第 3 秒就完成部署。** 这是相关性 + 同参数对照，**尚未**由独立实验排除「CDB 子进程事件被抑制」等其他解释，不能直接断言 VMProtect 反调试导致分支切换。

## 运行身份

| 项 | 值 |
|---|---|
| run id | `EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165` |
| VM | `<OTHER_VM_LABEL>`（UUID `8d0b85c0-ed29-47c7-9fe1-21bc706a057a`） |
| 起跑快照 | `qoder-clean-20260920` |
| 目标 | `C:\ept_core\Hardware.exe`，SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` |
| runner | `<HOST_PATH>\HexPatch\probe\EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165.ps1`，SHA-256 `4E93BC4E4CE2C765E147B823A6C0E0402079318E6DA8A1EAB39CCE4DBEC74F3D`（与 Guest 投递副本一致） |
| 参数 | `-k [REDACTED] -n 2 -m 1` |
| 设计窗口 | 75 s 自然运行，无调试器、无补丁、无 response 注入 |
| 收尾快照 | `qoder-clean-20260920`（恢复后重建基线） |
| E: 可用空间 | 270+ GiB |

## 采集设计

`pre_state.json` → 启动目标（无调试器）→ 每 3 s 采集一次 `Hardware|EPT_|UVT|Hp|SWTOOLS` 进程面（含 PPID 与创建时间），每 15 s 记录 heartbeat（目标存活、`%TEMP%` 中 `EPT*` 数量、`Hp*` 驱动数量）→ 75 s deadline → 有界清理目标进程树 → `post_state.json` + `delta.json` + `done.json`。

## 直接观察（本轮实际跑到的部分）

完整 runner 日志：

```text
BOOT|run_id=EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165|mode=NATURAL_NO_DEBUGGER|deadline_sec=75
PRE|proc=0|temp_exe=0|core=1
TARGET_STARTED|pid=8928
PROC_SEEN|8928|4720|Hardware.exe|09/23/2026 17:34:02
PROC_SEEN|6272|8928|EPT_FB927D78_7CFC6390.exe|09/23/2026 17:34:05
```

`PRE|proc=0` 说明起跑时目标进程面是干净的（C164 的孤儿清理已生效）。`core=1` 即 `C:\ept_core` 仅原始样本。

记录在 `09:34:06` 之后中断：**GuestControl 会话在该时刻被终止，把同样由该会话启动的 Guest 侧 runner 一起杀掉**，因此 75 s 窗口与 `post_state.json` / `delta.json` / `done.json` 都没有产出。

## 本轮失败与恢复（重要教训）

1. **runner 未脱离 GuestControl 会话**：`lab.ps1 -Action run` 前台执行时，GuestControl 会话超时/失败会**一并终止** Guest 侧进程树。C164 能跑满 150 s 属侥幸（会话存活较久），C165 在约 4 s 后即被杀。→ 后续必须用「投递脚本 + 计划任务/真正脱离会话的启动方式」，或接受前台执行并只依赖共享盘 spool。
2. **runner 里用了 `Get-CimInstance Win32_Process`**（慢速 WMI）放在 3 s 循环中，本身就拖慢阶段推进。→ 改用 `Get-Process`（含 `Path` 属性）即可，避免 WMI。
3. **控制面 wedge**：会话结束后 GuestControl 反复返回 `Error starting guest session (current status is: starting)`；`cmd /c ver` 在 3 分钟内不可用，VM 侧 `VMState=running`、`GuestAdditionsRunLevel=3` 仍正常 → 分类 `CONTROL_NOT_READY`，不启动样本。
4. **有界恢复**：`controlvm poweroff` → 发现 VM `poweroff` 但 `startvm` 返回 `The VM session was closed before any attempt to power it on`，定位到属于本 VM 的 stale `VBoxHeadless` 链（6256 → 18416 → 17800，命令行匹配 `<OTHER_VM_LABEL>`）并做专属树清理 → 重启后 Guest 引导**卡在 GuestAdditionsRunLevel=1**（约 3 分钟无进展）→ 最终 `snapshot restore qoder-clean-20260920` 重建基线，启动后 `runlevel=3`，两次 `cmd /c ver` 短探针 exit 0。**未创建或删除任何快照。**

## 证据边界

- 本轮**未取得** `native_return`、`changed_bytes`、caller `+0x80` 前后缓冲，**未发生**机器码修改，未做 response 注入。
- 子进程名字段 `EPT_FB927D78_7CFC6390.exe` 与父 PID、创建时刻来自同一 run id 的 runner 日志，可归因；但**子进程的完整路径未能收割**（窗口中断），只能与清单既有的部署路径模板 `<HOST_PATH>\Users\<USER>\AppData\Local\Temp\EPT_3C9F3CEF_69BB4F9F.exe` 并列引用，不能声称本轮路径已核实。
- 「调试器存在 ⇒ 不部署子进程」目前是**同参数对照下的相关观察**，不是已确认因果；需要一次专门实验（例如在同一轮内先无调试器部署、再单独验证 CDB 子进程事件是否被抑制）才能定论。
- 子进程名字段含随机段 `FB927D78`/`7CFC6390`，说明部署物名称每次运行不同；这与清单「抓包证据件命中」记录一致，可用于后续 run 的部署归因对齐。

## 产物

目录：`<HOST_PATH>\HexPatch\probe\EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165\`

| 文件 | 说明 |
|---|---|
| `runner.log` | 本轮唯一有效阶段时间线（4 行有效事件 + BOOT/PRE） |
| `phase.txt` | 最后阶段行 |
| `pre_state.json` | 起跑前进程面为空、`C:\ept_core` 仅样本 |
| `post_state.json` / `delta.json` / `done.json` | **未产出**（会话被杀） |

配套脚本：`<HOST_PATH>\HexPatch\probe\C165_post_probe.ps1`（清理+收割用，本轮因控制面 wedge 未能执行）。

敏感数据：本轮 runner 不写 CDB，不产生含卡密的日志；`runner.log` 中的参数行不包含输入明文，本文件亦不复述。

## 下一步（按区分力排序）

1. **把调试器观测彻底换成非调试器路线**：既然自然运行 3 秒就部署子进程，而调试器运行 150 秒都不部署，就不要再把 CDB 当作取得授权接缝证据的主路径。
2. **优先复用 Guest 内直接调用路线**（C130 已证实：在 Guest 内命中 `0x14078f060` 并产出 268 B `output_after.bin`，`native_return=0x0`），叠加 C152 已证实的伪造响应判据（解密头 4 字节 `0x12345678`）与 `changed_bytes` 统计，在 Guest 侧把硬判据闭合，并明确标注为 caller/injection 级证据。
3. **若坚持以自然路径为主**，则先修正启动方式（真正脱离 GuestControl 会话）与进程采集（`Get-Process` 而非 WMI），再重跑一次完整 75 s 窗口，补齐 `post_state.json`/`delta.json`：目标存活状态、`%TEMP%` 部署物完整路径与哈希、驱动/服务变化、`C:\ept_core` 变化——这批就是交付物需要的「进程/部署/清理」可归因证据。
4. 每轮起跑前保留「目标进程面归零」闸门；本轮 `PRE|proc=0` 证明该闸门有效。

## 可复核材料

- runner：`<HOST_PATH>\HexPatch\probe\EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165.ps1`
- 收割脚本：`<HOST_PATH>\HexPatch\probe\C165_post_probe.ps1`
- 原始运行目录：`<HOST_PATH>\HexPatch\probe\EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165\`
- 前序对照：`C164_forced_branch_and_caller_capture_20260923.md`、`C163` spool、`C109_genb_pe_entry_and_child_debug_boundary_20260921.md`、`C130_decode_core_keyless_separation_final_zh.md`、`C152_forged_response_native_accept_20260922.md`
- 通信手册：`method/COMMUNICATION_PLAYBOOK.md`
