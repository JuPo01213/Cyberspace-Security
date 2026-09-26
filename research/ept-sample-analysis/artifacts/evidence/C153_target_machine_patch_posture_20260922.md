# C153：靶机实际机器码变化与运行时补丁姿态（2026-09-22）

## 结论

截至 H17C/H5，靶机上没有任何 eb 运行时补丁被证实写入并保留在目标进程的可执行代码中。

已证实的变化只有两类：

1. CDB 的 bu/bp 断点机制会在命中期间把断点地址的首字节临时改为 0xCC；执行 bc 或调试器收尾后恢复原字节。这是调试器管理的瞬态变化，不是样本补丁。
2. H5 的断点命中后，CDB action 因语法错误中止，目标 0x143c17fb0 的首 5 字节仍为 E9 F9 5E 02 00，期望的 C3 没有写入。

H17C 的两个 RC00 分支写入动作只被布置在 breakpoint action 中；进程随后在高地址 0x0000000176444876 访问违例，日志没有 PATCH1_APPLIED/PATCH2_APPLIED，所以不能把 75 5e -> EB 5E 或 74 30 -> EB 30 记为已应用。

## 直接证据

### H5：首段 dispatcher patch

材料：
- <HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RET_PATCH_20260922H5\cdb_stdout.txt
- <HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RET_PATCH_20260922H5\run_meta.json

命中日志顺序：
- DISPATCH_CRACK_TARGET 出现，说明 0x143c17fb0 断点确实命中。
- 随后的 action 报 Syntax error。
- 没有出现 DISPATCH_RET_PATCH_APPLIED。
- 命中点转储仍为：
  0000000143c17fb0  e9 f9 5e 02 00  jmp Hardware+0x3c3deae

因此：

| 地址 | 原始字节 | 期望字节 | 实际结果 | 依据 |
|---|---|---|---|---|
| 0x143c17fb0 | E9 F9 5E 02 00 | C3 | 未写入；仍为原始 JMP | H5 命中时 db |

H5 的 run_meta.json 虽然记录了 patched: C3，但该字段是实验计划/参数登记，不是写入确认；现场 db 与缺失的 applied marker 优先级更高。

### H17C：RC00 两个分支 patch

材料：
- <HOST_PATH>\HexPatch\probe\EPT_RC00_PATCH_AND_DECODE_20260922H17C\cdb_stdout.txt
- <HOST_PATH>\HexPatch\probe\EPT_RC00_PATCH_AND_DECODE_20260922H17C\run_meta.json

CDB 中登记的动作是：
- 0x14078eea2: 75 5e -> EB 5E
- 0x14078ef10: 74 30 -> EB 30

但日志只出现 breakpoint 定义，没有 RC00_VALIDATOR_BRANCH、RC00_MARKER_BRANCH、PATCH1_APPLIED、PATCH2_APPLIED。随后发生 Access violation at 0000000176444876。

| 地址 | 原始字节 | 期望字节 | 实际结果 | 依据 |
|---|---|---|---|---|
| 0x14078eea2 | 75 5E | EB 5E | 未确认写入；分支断点未命中 | H17C 无 marker，先 AV |
| 0x14078ef10 | 74 30 | EB 30 | 未确认写入；分支断点未命中 | H17C 无 marker，先 AV |

## 磁盘样本哈希

### H5

run_meta.json 与 pre_state.json/post_state.json 均显示：
- C:\ept_core\Hardware.exe：前后均为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7
- C:\Windows\System32\Hardware.exe：前后均为 0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8

### H17C

- C:\Windows\System32\Hardware.exe：PRE 为 genA 0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8
- POST 为 genB CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7
- run_meta.json 明确记录 deploy_observed=false、s32_after 仍为 genA，CDB target 是 C:\ept_core\Hardware.exe。

H17C 的 genA→genB 差异是外层部署/镜像状态变化，不能归因于 eb；该轮没有 patch-applied marker，也没有 live code dump 证明两个 RC00 字节发生变化。

## 各轮登记补丁的统一判定

H2–H4、H6–H15 的元数据反复登记 0x14078eea2 与 0x14078ef10，但这些记录表示 runner 的候选 patch 配置。各轮均为 WAIT_TIMEOUT，样本前后 SHA-256 保持 genB，且没有对应的写后读回证据。因此统一标记为：DECLARED / NOT PROVEN APPLIED。

H5：HIT / WRITE FAILED。
H17C：ARMED / TARGET NOT REACHED / AV。

## 最终判定

- 永久磁盘修改：0 处。
- 已确认保留在目标进程代码中的 eb 修改：0 处。
- CDB 断点造成的瞬态 0xCC：存在，但属于调试器临时状态，收尾后恢复。
- H5 首段 dispatcher：命中，但 E9 F9 5E 02 00 未变，C3 未写入。
- H17C 两个 RC00 分支：命中前发生 AV，EB 5E/EB 30 均未获写入确认。

因此，靶机实际机器码变化的严格答案是：没有完成任何持久或已确认的业务 patch；只有断点期间的调试器瞬态 0xCC 变化。

## 复核材料

- H5 材料目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RET_PATCH_20260922H5\
- H17C 材料目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_PATCH_AND_DECODE_20260922H17C\
- 机制闭合对照：artifacts/evidence/C152_forged_response_native_accept_20260922.md