# C132：真实 EPT 解码臂 A 的客体失活与收割失败（2026-09-22）

## 状态

`INSTRUMENT_FAILURE / CHANNEL_LOST_AFTER_REAL_LAUNCH`

本件记录一次真实 EPT 派生样本运行的仪器失败。它不证明解码成功、解码失败、分支选择、`native_return` 或 `changed_bytes` 的任何一项。

## 实验问题与固定条件

- 问题：在不修改样本、不使用 synthetic response 的条件下，真实 `Hardware.exe` 是否会产生可收割的解码/靶机变化。
- 样本路径：客体 `C:\ept_core\Hardware.exe`。
- 客体样本大小：`32,671,232` bytes。
- 客体样本 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- EPT 上游登记：`<HOST_PATH>\EPT\artifacts\CHECKSUMS.sha256` 中 genB 条目同哈希；HexPatch 只作为已核验的外部投料/VM 工程来源，不是样本权威。
- 输入：外部卡密文件仅作为运行输入；长度 `380` ASCII 字符，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`。明文未写入本件。
- 参数：`-k [redacted] -n 2 -m 1`。
- VM：`<OTHER_VM_LABEL>`，快照 `qoder-clean-20260920`；运行前客体正向控制返回 `EPT_POSCTRL`，且样本身份核对通过。
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_real_decode_guest_20260922A.ps1`，SHA-256 `6F7F3CA395CB8C001A6C79FB2CCF8F6CD27C77B9842FEA39AAB443DAFFF3A4D3`，纯 ASCII。
- run id：`EPT_REAL_DECODE_20260922A`。
- 预算：expected `120 s`，deadline `150 s`；客体 runner 写本地 `PRE/MID/POST`、stdout/stderr 和 `DONE.txt`。

## 直接观察

1. 客体 runner 通过 Guest Control 启动并返回 PID `7504`；启动命令未把卡密明文写入 host 输出。
2. 启动后的 Guest Control 新会话多次返回：`Error starting guest session (current status is: starting)`；SSH 备用通道 `127.0.0.1:2222` 返回：`Connection timed out during banner exchange`。
3. `VBox.log` 在本轮运行后记录 `Guest seems to be unresponsive`，随后出现 `TM: Giving up catch-up attempt`。这证明客体/观测通道失活，不证明样本返回值。
4. VM 控制台截图未显示可见授权弹窗；截图平面不提供进程退出、文件写入或解码结果证据。
5. 客体超过 runner 预算后无法响应 ACPI 关机；宿主执行了强制断电。断电前没有成功收割 `PRE/POST`、stdout/stderr 或 `DONE.txt`。
6. 断电后保留了快照 `ept-real-decode-20260922A-postmortem`，UUID `061bcd87-bd3c-46a7-865c-58aa15b4da94`，描述明确标注为“unharvested guest state / instrumentation failure / not evidence”。随后恢复 `qoder-clean-20260920`。
7. 当前没有本件支持的 `native_return`、`changed_bytes`、caller `+0x80` 快照、自然退出码或靶机前后差异。

## 解释边界

- 这次运行已经证明“经 EPT 身份核验的真实样本被投送并启动 runner”；没有证明“真实解码发生”。
- `Guest Control`、SSH、控制台截图和快照收尾之间没有形成可复核的完成平面，因此本臂只能归类为 `INSTRUMENT_FAILURE`。
- 不得把客体未回传文件解释为文件不存在，也不得把强制断电解释为样本退出或失败。
- 下一臂的唯一改动是：客体 runner 在本地 spool 之外，把小型状态/完成文件实时镜像到已核验的 VirtualBox 共享目录；样本路径、样本哈希、快照基线、卡密输入和命令参数保持不变。镜像通道只作为收割平面，不把共享目录文件当作样本输入。

## 原始材料与复核

- VM 日志：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\Logs\VBox.log`。
- 运行前截图：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\Logs\EPT_REAL_DECODE_20260922A_screen.png`。
- 断电后截图：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\Logs\EPT_REAL_DECODE_20260922A_after_reboot.png`。
- 保留快照：`ept-real-decode-20260922A-postmortem`。
- 本件不引用任何未能从客体取回的 spool 文件内容。

## 完成判据

本件不改变项目硬门槛。核心分离仍要求同一真实样本运行同时取得：

```text
native_return == 0x1
changed_bytes > 0
```

并保存切口命中、caller `+0x80` 前后缓冲、样本身份、VM/快照、run id 和清理状态。