# C156：最小 CDB 写后读回臂 A（2026-09-23）

## 结论

状态：**PARTIAL / RUNTIME_WRITE_CONFIRMED / BUSINESS_PATH_UNREACHED**。

本轮首次在目标进程的 CDB 会话中取得两处运行时写入的直接写后读回：


auto_patch_1 = 0x14078eea2: 00 00 -> EB 5E
auto_patch_2 = 0x14078ef10: 00 00 -> EB 30

这证明 eb 命令确实作用于 CDB 当前调试目标的内存地址，且读回值与期望补丁一致。它不证明补丁位于已解密/已执行的 RC00 代码，也不证明补丁在调试器分离后仍被保留。

本轮没有取得：

native_return == 0x1
changed_bytes > 0

也没有取得 F060、RC06、caller +0x80、授权返回或自然退出证据。

## 运行身份

| 项 | 值 |
|---|---|
| run id | EPT_RC00_MIN_PATCH_READBACK_20260923A |
| VM | <OTHER_VM_LABEL> |
| 快照 | qoder-armed-20260919 |
| 样本路径 | C:\\ept_core\\Hardware.exe |
| 样本 SHA-256 | CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7 |
| CDB SHA-256 | 5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67 |
| 输入长度 | 380 字符；明文不写入本件 |
| deadline | 120 s；超时后终止 CDB 进程树 |
| E: 空间前置检查 | 271.24G 可用 |

## 控制面与数据面

- GuestControl 短命令返回 CONTROL_OK，VBoxService.exe 存活，会话查询为空。
- runner 通过脚本投递到客体 C:\\ept_obs\\EPT_RC00_MIN_PATCH_READBACK_20260923A.ps1。
- 共享目录实时产生 runner.log、run.cdb、cdb.log、pre_state.json、post_state.json、run_meta.json。
- runner 最终状态为 WAIT_TIMEOUT；收尾后客体目标进程列表为空。

## CDB 直接证据

原始日志：

<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\cdb.log

命令文件：

<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\run.cdb

关键顺序：

1. CDB 输出 CDB_READY。
2. db 14078eea2 L2 读回 00 00。
3. eb 14078eea2 eb 5e 后，db 14078eea2 L2 读回 eb 5e。
4. eb 14078ef10 eb 30 后，db 14078ef10 L2 读回 eb 30。
5. PATCHES_STABLE 阶段再次读回两处均为期望值。
6. CDB 只输出模块加载流；日志中没有独立的 F060_HIT、F060_RETURN_AFTER_CALL、RC06_ENTRY、CALLER_OUTPUT_AFTER_COPY 或 SUCCESS_RETURN_EDGE 事件行。命令回显中的同名字符串不计为事件 marker。

## PRE/POST 状态

原始状态文件：

<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\pre_state.json
<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\post_state.json

以下目标在 PRE/POST 的文件级摘要中保持一致：

- C:\\ept_core\\Hardware.exe SHA-256 仍为 CFA6998E...；
- C:\\Windows\\System32\\Hardware.exe SHA-256 仍为 CFA6998E...；
- C:\\Windows\\System32\\EPT.cmd 哈希未变；
- HardwareLogs、两个候选驱动路径保持缺失；
- 本轮没有捕获到新的 EPT_*.exe 临时副本；
- PRE/POST 都没有自然样本进程列表。

文件哈希稳定只说明磁盘对象未被本轮改变，不能证明调试器内存页在分离后保留。

## 边界与下一轮修正

本轮写入发生在 CDB 初始断点阶段，早于已知运行时入口 0x14235f67b。两处地址初读为 00 00，因此该臂没有证明它们已经是目标业务代码中的原始 75 5E/74 30。

下一轮只改变观测时序：

- 保持样本、输入、VM 和磁盘预算不变；
- 将两处写入移动到 0x14235f67b 的一次性入口事件之后；
- 在同一入口动作内按“读原值 -> 单独 eb -> 立即 db”顺序执行；
- 继续使用 -o/.childdbg 全量接管子进程，不使用 cpr: 过滤；
- 保留独立的 RC00/RC06/caller marker；
- 若仍无业务 marker，按 DEBUGGER_NOT_REACHED 或 WAIT_TIMEOUT 记账，不升级为授权结论。

## 可复核材料

- runner：<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A.ps1
- 运行元数据：<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\run_meta.json
- CDB 日志：<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\cdb.log
- CDB 命令：<HOST_PATH>\\HexPatch\\probe\\EPT_RC00_MIN_PATCH_READBACK_20260923A\\run.cdb
- 通信规则：<HOST_PATH>\\EPT\\method\\COMMUNICATION_PLAYBOOK.md
