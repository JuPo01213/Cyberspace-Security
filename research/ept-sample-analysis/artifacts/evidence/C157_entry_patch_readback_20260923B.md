# C157：入口后写入与 dispatcher 命中（2026-09-23）

## 结论

状态：**PARTIAL / ENTRY_AND_DISPATCH_OBSERVED / PATCH_WRITE_READBACK_CONFIRMED / BUSINESS_HARD_CRITERIA_UNREACHED**。

CDB 的独立运行输出确认目标入口命中后，对两个候选虚拟地址执行写入并立即读回：

- 0x14078eea2: 00 00 -> EB 5E
- 0x14078ef10: 00 00 -> EB 30

关键事实：两处写入前读回均为 00 00，与预期原始指令字节 75 5E、74 30 不符。因此这只能证明 CDB 在进程地址空间对这些地址写入了目标字节，不能认定为 sanctioned RC00 指令补丁；其所属映像/代码页、地址换算和执行关系仍待核验。随后观察到四个独立 dispatcher marker：DISPATCH_143C17FB0_HIT、DISPATCH_143C3DEAE_HIT、DISPATCH_143C30E27_HIT、DISPATCH_143DEAC60_HIT。这些事件尚未证明两处写入影响业务路径或调试器收尾后仍留存。

本轮 runner 最终状态为 WAIT_TIMEOUT（120 秒 deadline）。没有取得可信的 native_return == 0x1、changed_bytes > 0、F060/RC06 业务路径、caller +0x80 前后缓冲或自然业务完成事件。因此不能将本轮记为授权闭环。

## 运行身份与环境

| 项 | 值 |
|---|---|
| run id | EPT_RC00_ENTRY_PATCH_READBACK_20260923B |
| VM | <OTHER_VM_LABEL> |
| 快照 | qoder-armed-20260919 |
| CDB 目标 | C:\ept_core\Hardware.exe |
| 样本 SHA-256（PRE/POST） | CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7 |
| CDB SHA-256 | 5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67 |
| deadline | 120 秒；runner 记录 timed_out=True，CDB exit code 为空 |
| E: 可用空间（后续只读核对） | 274.80 GiB |
| VM 状态（后续只读核对） | poweroff；当前快照仍为 qoder-armed-20260919 |

实验输入的内容未写入本证据件；仅保留长度/哈希在原始 run_meta.json 中，避免将输入材料扩散到摘要文档。

## CDB 原始日志的严格解析

原始日志：<HOST_PATH>\HexPatch\probe\EPT_RC00_ENTRY_PATCH_READBACK_20260923B\cdb.log（171 行）。按整行精确匹配 marker、排除所有 0:000> 命令回显后，独立事件及行号如下：

| 行 | 独立运行事件 |
|---:|---|
| 54 | CDB_READY |
| 71 | TARGET_ENTRY_HIT |
| 74 | PATCH1_AFTER_ENTRY |
| 76 | PATCH2_AFTER_ENTRY |
| 78 | DISPATCH_143C17FB0_HIT |
| 79 | DISPATCH_143C3DEAE_HIT |
| 80 | DISPATCH_143C30E27_HIT |
| 81 | DISPATCH_143DEAC60_HIT |

入口内写入前读回为：

000000014078eea2  00 00
000000014078ef10  00 00

紧接写入后的读回为：

000000014078eea2  eb 5e
000000014078ef10  eb 30

以下业务 marker 在原始日志中没有独立整行命中：MAIN_ENTRY_HIT、N_PARSE_HIT、F060_HIT、F060_RETURN_AFTER_CALL、RC06_ENTRY、RC06_CALL、CALLER_OUTPUT_AFTER_COPY、SUCCESS_RETURN_EDGE。它们只在 0:000> bp ... 命令定义回显中出现。

runner 的 marker 抽取逻辑是对整份文本执行字符串包含匹配，因此 run_meta.json 中上述业务 marker 列表是命令配置回显污染，不可作为事件证据。后续解析必须只接受去除命令提示符后整行精确匹配的独立事件；更稳妥的做法是使用无 marker 名称命令回显冲突的事件格式，并由 runner 解析运行输出行，而非搜索脚本文本。

## PRE/POST 文件状态变化

PRE/POST 摘要来自客体 pre_state.json、post_state.json：

| 路径 | PRE | POST | 当前解释 |
|---|---|---|---|
| C:\ept_core\Hardware.exe | 32,671,232 字节，SHA-256 CFA6998E… | 相同 | 目标映像文件未变 |
| C:\Windows\System32\Hardware.exe | 32,198,144 字节，SHA-256 0DDC82FC… | 32,671,232 字节，SHA-256 CFA6998E… | genA→genB 文件身份/内容变化；写入者与时刻未归因 |
| C:\Windows\System32\EPT.cmd | 1,207 字节，SHA-256 60587683… | 1,093 字节，SHA-256 8FD82596… | 文件内容变化；写入者与时刻未归因 |
| C:\Windows\System32\HardwareLogs | 缺失 | 缺失 | 未见该目录 |
| C:\Windows\System32\drivers\HP_WKS_SWTOOLS_DRIVER.sys、SWTOOLS_DRIVER.sys | 缺失 | 缺失 | 未见候选驱动文件 |
| C:\R6-QZD | 缺失 | 缺失 | 未见该目录 |
| C:\Windows\Temp 下 EPT/Hardware 临时匹配 | 0 | 0 | 摘要采集时未发现匹配项 |
| 匹配进程摘要 | 0 | 0 | POST 采集时没有匹配进程；不代表运行期间无进程 |

PRE/POST 的变化与外层部署行为、调试运行或其他系统行为之间尚无写者/时间戳因果证据。不要根据最终文件状态单独推定由两处内存写入导致。

## 主要限制与下一步

1. 首先修复 marker 解析，避免命令输入回显被计作事件；保留原始日志与严格整行解析结果。
2. 下一轮先确认实际目标模块/代码页在断点时已物化，并核对候选地址字节、模块基址与实际执行控制流；不能把地址写成功等同于正确业务补丁。
3. 若继续部署链观测，使用短时 ETW Kernel-Process/Kernel-File 或受限 ProcMon 捕获，把 PID/写者/文件变更时刻与同一 run id 对齐；大捕获物先限额，再只收割小型摘要。
4. 只有同一真实运行中取得 native_return == 0x1 且 changed_bytes > 0，并保存切口、caller +0x80 前后缓冲、样本身份、VM/快照、run id 和清理状态，才满足项目硬完成判据。
5. C157 已结束，VM 当前为 poweroff，当前快照仍为 qoder-armed-20260919。下一次启动前仍需重新通过 E: 空间、VM/快照和 Guest 健康闸门；本轮收尾没有恢复或创建快照。

## 可复核材料

- runner：<HOST_PATH>\HexPatch\probe\EPT_RC00_ENTRY_PATCH_READBACK_20260923B.ps1
- 运行目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_ENTRY_PATCH_READBACK_20260923B
- 原始 CDB 日志：cdb.log
- CDB 命令：run.cdb
- PRE/POST：pre_state.json、post_state.json
- 元数据：run_meta.json（markers 字段存在命令回显污染）
- runner 日志：runner.log
- 前一轮对照：artifacts/evidence/C156_min_patch_readback_20260923A.md
- 通信规范：method/COMMUNICATION_PLAYBOOK.md
