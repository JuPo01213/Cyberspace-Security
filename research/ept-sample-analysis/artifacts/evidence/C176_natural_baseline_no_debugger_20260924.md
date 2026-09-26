# C176：无调试自然基线运行

日期：2026-09-24  
运行编号：`EPT-REAL-20260924-02`  
授权单：`IR-2026-0924-EPT`  
Guest：`<VM_LABEL>` / `<VM_LABEL>`  
证据范围：`real_sample_guest_run`  
运行模式：`natural_launch_no_debugger`

## 0. 结论摘要

本轮是新的、无调试器自然基线：观察器直接启动真实派生目标 `C:\ept_core\Hardware.exe`，不启动 CDB/WinDbg，不设置断点，不注入 I/O response，不写目标进程内存或机器码；观察器只通过旁路快照采集进程、文件、注册表、服务、计划任务和网络状态。

本轮确认：

```text
Hardware.exe 自然启动
→ 自然创建 EPT 临时子进程
→ 运行窗口内未取得 RC00/RC03/RC06 目标级 seam 证据
→ 到达 180 秒硬 deadline 后，观察器才请求停止目标及子进程
```

本轮不证明：真实 `DeviceIoControl` 返回、RC03 validator、RC06、caller `+0x80` 写回、`target_native_return`、`target_caller_diff_bytes` 或解码后行为。未观察到不等于不存在。

## 1. 前置与干预边界

| 项目 | 记录 |
|---|---|
| 目标路径 | `C:\ept_core\Hardware.exe` |
| 目标 SHA-256 | `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` |
| 输入状态 | `synthetic_invalid_card_no_secret` |
| Guest 网络 | Hyper-V 虚拟网卡断开；本轮网络快照未见非监听远端连接 |
| 调试器 | 未启动 CDB/WinDbg |
| 断点 | 无 |
| 响应注入 | 无 |
| 目标内存/机器码写入 | 无 |
| 观察方式 | 旁路轮询和前后快照，不附加、不暂停目标 |
| 硬 deadline | 180 秒 |
| 收尾 | deadline 后请求停止临时子进程和目标进程 |

## 2. 进程运行事实

事件时间线（UTC）：

```text
15:02:44.906  RUNNER_READY
15:02:50.094  观察器开始进程快照
15:02:51.422  TARGET_STARTING
15:02:51.437  TARGET_STARTED  Hardware.exe PID 4784，PPID 8464
15:02:51.469  RUNNING
15:02:54.163  临时子进程开始时间
15:02:56.219  观察器记录临时子进程 EPT_15669800_B33D1B09.exe PID 8412，PPID 4784
15:05:52.449  DEADLINE_REACHED（180 秒）
15:05:52.464  CLEANUP
15:05:52.527  请求停止 PID 8412
15:05:52.558  请求停止 PID 4784
15:05:59.046  DONE
```

这证明外层真实目标在无调试条件下能够自然启动并创建临时 EPT 子进程。它不能单独证明临时子进程已经执行到目标 RC00 seam，也不能证明后续全部行为自然完成，因为本轮到 deadline 时由观察器主动收尾。

## 3. 文件行为

前后快照中均存在：

```text
C:\ept_core\Hardware.exe
C:\Windows\System32\Hardware.exe
C:\Windows\System32\EPT.cmd
C:\Windows\System32\ept.cmd
C:\Windows\Temp\EPT_15669800_B33D1B09.exe
C:\Windows\Temp\EPT_2C6E782E_8FCCB950.exe
C:\Windows\Temp\EPT_46F4557F_E917B6D2.exe
```

与本轮运行直接对应的临时子进程文件为：

```text
C:\Windows\Temp\EPT_15669800_B33D1B09.exe
```

其进程 PID 为 `8412`，父进程为本轮目标 PID `4784`。前后快照的目标文件身份保持：

```text
C:\ept_core\Hardware.exe
length = 32671232
sha256 = CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7

C:\Windows\System32\Hardware.exe
length = 32671232
sha256 = CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7
```

`C:\Windows\System32\ept.cmd` 前后 SHA-256 均为：

```text
8FD825961D4582FF3C43E4E90AC78E4E5F8D7958B2651A7FC16C4693B6172609
```

本轮没有目标文件被改写的证据。注意：文件快照是本轮观察器的观测范围，不等于对所有 Guest 文件系统写入的全量审计。

## 4. 网络、注册表、服务与任务

- `network.ndjson` 共 74 个快照行；解析后未发现带非零远端地址/端口的连接记录。
- 快照保留了 Guest 当时的注册表、服务和计划任务集合；本证据件不把“集合未发生可见差异”升级为“样本没有任何注册表/服务/任务行为”，因为观察器采样不是 ETW/内核级写入审计。
- 由于 Guest 网卡断开，本轮不能推导样本在可联网条件下的网络行为；只能记录本轮隔离条件下未见成功的非监听远端连接。

## 5. 目标级 seam 判据

```text
target_native_return       = NOT_OBSERVED
target_caller_diff_bytes   = NOT_OBSERVED
rc06_entry                 = NOT_OBSERVED
rc06_return                 = NOT_OBSERVED
post_decode_behavior        = NOT_OBSERVED
```

本轮没有 CDB、断点或 response 注入，因此它是自然基线；但输入是无真实密钥且无真实设备 response 的隔离条件，不能据此声称样本在所有授权/响应条件下不会进入 RC06。

## 6. 可复核原件

```text
runs/EPT-REAL-20260924-02/harvest/done.json
runs/EPT-REAL-20260924-02/harvest/events.ndjson
runs/EPT-REAL-20260924-02/harvest/pre.json
runs/EPT-REAL-20260924-02/harvest/post.json
runs/EPT-REAL-20260924-02/harvest/file_changes.json
runs/EPT-REAL-20260924-02/harvest/network.ndjson
runs/EPT-REAL-20260924-02/harvest/heartbeat.json
runs/EPT-REAL-20260924-02/harvest/harvest_manifest.json
```

关键原件哈希：

```text
done.json         D16871B55E0ADCBCEA92B95F70FF714E3090315F6E6DE619686C9AC657EF7F15
events.ndjson     FFC7DD16FBDF823366AB4CD5C56DFFD2F827B8145F3B82BB07659CE0C1A77508
pre.json          A66F82CDD00B5F1FD510C4C2E67FEAD65EB4FE7563E5745689987D97045DB48A
post.json         73D90E9949FBCF463772E551CE6BBED47D979670C8DD246010065809B653BD43
file_changes.json 76B8D9BF957790DCC971783CFEA9475C5A888276E3A5649BFFABB9D17A933E54
network.ndjson    607092C28935E0A399BD21663C21E208E1DB4E8C53BF6D3890DC97BE82071DF7
```

## 7. 状态归类

```text
NATURAL_BASELINE_COMPLETE
OUTER_START_AND_TEMP_CHILD_NATURALLY_OBSERVED
RC00_RC03_RC06_NOT_OBSERVED
TARGET_SEAM_NOT_CLOSED
POST_DECODE_BEHAVIOR_NOT_OBSERVED
```

本件不把自然基线的 deadline 清理写成样本自然退出，也不把 RC06 未观察写成业务阴性。
