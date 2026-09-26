# C82 · runtime `.Sq>` replay fault evidence

## 判定

本次重放没有到达 RC00 调用点，也没有产生可归因的本地解码输出。它应判为 `REPLAY_STATE_MISMATCH / NO_CORE_RETURN_OBSERVED`，不是“样本核心解码失败”，更不是成功证据。

这次实验的有效结果是：完整运行时 `.Sq>` 页面和静态 `.text` 都能写回目标进程，但把页面快照直接叠加到一个新启动进程并跳到主函数后，控制流在一个 `ret 8` 上使用了非规范返回地址。由此可区分“页面缺失”与“运行时栈/调度状态未被快照覆盖”。

## 运行边界

- 客体快照：`qoder-clean-20260920`；运行期间网卡为 `null`。
- 启动参数：`-k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 2 -m 1`。
- 观察器只做短时 warmup、恢复 `.text`、写回 `.Sq>`、设置断点并继续；没有启动外层 `auto_decode.pyc`，没有访问网络。
- `.text` 恢复目标：`0x140000000`，长度 8,257,536 字节；写入成功。
- `.Sq>` 恢复目标：`0x141174000`，长度 15,622,144 字节；3814/3814 页写入成功。
- 授权闸门 `0x1407a3080` 的最小 bypass 写入成功；RC00 调用点 `0x14078ee73` 已布置观察断点。

## 原始日志中的阶段结果

```text
﻿2026-09-21T03:05:08.4551969Z phase=launch command=synthetic_core_no_network
2026-09-21T03:05:08.4728363Z phase=created pid=896 tid=9164
2026-09-21T03:05:08.4728363Z phase=loader_created waiting_initial_breakpoint
2026-09-21T03:05:08.4999427Z phase=warmup_start seconds=2
2026-09-21T03:05:11.5843293Z phase=warmup_page va=0x1415d0000 nonzero=0 read_error=0
2026-09-21T03:05:11.5843293Z phase=warmup_break_requested ok=True error=203
2026-09-21T03:05:11.5968458Z phase=exception code=0x80000003 address=0x7ffbe73710d0 rip=0x143d227a7 rsp=0x14fc08
2026-09-21T03:05:11.7924727Z phase=restore_plaintext bytes=8257536 sha256=5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757 written=8257536 ok=True
2026-09-21T03:05:11.7924727Z phase=bypass_auth_gate address=0x1407a3080 ok=True written=6
2026-09-21T03:05:11.9254577Z phase=replay_sq bytes=15622144 written=15622144 pages_ok=3814 pages_failed=0 ok=True
2026-09-21T03:05:11.9254577Z phase=arm_callsite address=0x14078ee73 ok=True original=e8 error=0
2026-09-21T03:05:11.9254577Z phase=jump_direct_main main=0x1407a4b90 stub=0x1c0000 break=0x1c0027 argv=0x1b0000 ok=True
2026-09-21T03:05:11.9455648Z phase=fault code=0xc0000005 address=0x14169910f rip=0x14169910f rsp=0x1457b0 rax=0x1458e0 rcx=0x141153b18 stack_error=0 stack_bytes=512 page_error=0 page_bytes=4096
2026-09-21T03:05:11.9455648Z phase=timeout no_rc00_callsite_hit
```

## 故障现场

- 异常：`0xc0000005`；故障地址/RIP：`0x14169910f`；RSP=`0x1457b0`；RAX=`0x1458e0`；RCX=`0x141153b18`。
- 故障页：`0x141699000`，页内现场字节：`c2 08 00 4c 8b 64 24 08 9c 66 46 85 a4 24 dd 90`；开头 `c2 08 00` 是 `ret 8`。
- 故障栈首个 qword：`0xdf36dabf2fae9836`。该值不是规范的 x64 用户态返回地址；随后可见 `0x1407bee13`、`0x1407b8c69` 等旧启动路径地址。
- 观察窗口内没有 `RC00` 调用点命中，没有 `RC03 decode_failed` 记录，也没有返回值、文件、注册表、设备调用或其他本地结果可归因。

## 证据解释

本次运行排除了“因为 `.Sq>` 页面没有被恢复所以立即失败”这一解释：每一页的写入结果均为成功，故障页也与完整范围采集中的对应页面一致。它同时证明原始 `.Sq>` 页面不是可独立搬运的纯代码快照；至少还有运行时栈、间接调度状态或其他进程态依赖没有随页面复制。

因此不能把 `0x14169910f` 的故障修成“跳过 ret”或伪造返回地址。那会改变被测控制流，无法回答真实核心做了什么。下一次有信息价值的动态判别应改为：从原生启动流程进入，在启动前布置主函数/RC00 观察点，只替换授权前置条件，不回放整段 `.Sq>`，并继续使用 20 秒级墙钟上限。

## 可复核材料与哈希

- 运行日志：`<HOST_PATH>\EPT\artifacts\captures\core_sq_replay_20260921A\debug_core_call.log`；SHA-256 `22ed694d39b7a25420bd7db5855cd81cde73407f16f4a90f5c1309ff31dc5a27`。
- 故障栈：`<HOST_PATH>\EPT\artifacts\captures\core_sq_replay_20260921A\fault_stack.bin`；SHA-256 `6e3f3f07e332a94414a223283dc88fa311540c0e6cd35383975d58d7b2f860fb`；长度 512 字节。
- 故障页：`<HOST_PATH>\EPT\artifacts\captures\core_sq_replay_20260921A\fault_page.bin`；SHA-256 `c62aec438172d98b3842f1631142e5bc3a3ac45edf3502d916df676c78fdead1`；长度 4096 字节。
- 完整运行时范围：`<HOST_PATH>\EPT\artifacts\captures\stream_SQSCAN_20260921A\sq_runtime_range.bin`；SHA-256 `1daf7ec28a09b43eb456f2027bcbaeb047aafab6b1a290ce14edc9cce761d1d4`；长度 15622144 字节。
- 静态 `.text` 输入：`<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin`；SHA-256 `5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`；长度 8257536 字节。
- 运行器：`<HOST_PATH>/vmctl/debug_core_call.ps1`；证据生成器：`<HOST_PATH>/vmctl/synthesize_sq_replay_evidence.py`。

## 状态

`INCOMPLETE`: 已取得完整运行时代码页，并验证了一个有边界的直接重放失败点；本地解码核心的输入、变换、输出/副作用及用户态/驱动边界仍未闭合。
