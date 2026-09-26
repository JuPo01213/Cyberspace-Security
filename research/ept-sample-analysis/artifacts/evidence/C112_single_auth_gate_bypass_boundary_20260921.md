# C112：单点授权门绕过与自然核心边界（2026-09-21）

## 目的

验证一个严格受限的 bypass seam 是否能把自然 `-n/-m` 进程推进到既有核心候选点。该实验只替换 `FUN_1407a3080` 的返回前置，不修改 `0x14078ce60`、`0x14078d900`、RC00/RC03 代码，不提供网络、卡密、设备或驱动响应。

## 实验方法

- 样本：`Hardware.genB.exe`，SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- 客体：`qoder-clean-20260920`，NIC=`null`。
- 调试器：CDB `10.0.29617.1000 AMD64`，`.childdbg 1`，`cpr:EPT_*.exe`。
- 命令行：`Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 0 -m 1`。
- 墙钟上限：`12 s`；超时杀死调试树并回滚快照。
- 子进程事件中向 `0x1407a3080` 写入六字节候选接缝：`B8 01 00 00 00 C3`（`mov eax,1; ret`）。随后安装四个硬件执行断点：`0x14078f250`、`0x14078f060`、`0x14078ee73`、`0x141757acd`。

## 直接观察

临时子进程 `EPT_9A8F25EC_28EF0874.exe` 被 CDB 跟随。创建进程事件中出现：

```text
AUTH_GATE_PATCH_ATTEMPTED
00000001`407a3080  b8 01 00 00 00 c3
CHILD_BPS_ARMED
```

这证明本轮确实修改了目标子进程地址空间中的授权函数入口，并成功安装了候选点断点；不是“只写了一个日志”或“没有跟到 child”。

在后续 `12 s` 窗口中，没有观察到 `0x14078f250`、`0x14078f060`、`0x14078ee73` 或 `0x141757acd` 的断点命中，也没有自然 RC03/RC06、有效设备响应或本地业务输出。运行元数据为 `timed_out=True`，因此这轮没有自然退出结果。

## 解释边界

这轮只证明：

1. `FUN_1407a3080` 的单点返回绕过可以在真实临时子进程中复现；
2. 单点绕过仍不足以把当前自然命令行推进到 F250/RC00 候选链；
3. 候选链未命中不能解释为核心不存在、解码失败或无本地副作用。

最可能的下一类依赖是 `main=0x1407a4b90` 内的授权/状态内联比较或其后高地址运行时 dispatch；这只是下一步候选解释，尚未通过动态观测确认。不得把本轮单点绕过扩大成“已绕过全部授权”。

## 状态

`PARTIAL / SINGLE_AUTH_GATE_BYPASS_CONFIRMED / CORE_CANDIDATE_UNREACHED`。

真实 response producer、自然 `-m` 到核心的完整链、RC03/RC06 自然输入、目标驱动/辅助字节和最终本地结果仍未取得。本轮之后 VM 已恢复 `qoder-clean-20260920`，状态为 `saved`，NIC 恢复为 `nat`。

## 产物

- 原始 CDB 输出：`artifacts/captures/natural_dispatch_f250_bypass_20260921c/cdb_stdout.txt`，SHA-256=`6EFD5BDA14FE4FA8B950DC2B92FA296CAF515471162BE02C8BA54A98B46C7B38`。
- 运行元数据：`artifacts/captures/natural_dispatch_f250_bypass_20260921c/run_meta.txt`，SHA-256=`7CFB4839289CFB939BF77AF9B341785057FA1F3571CE339A8495610DACE677CF`。
- CDB 命令：`artifacts/captures/natural_dispatch_f250_bypass_20260921c/probe.cdb`。
