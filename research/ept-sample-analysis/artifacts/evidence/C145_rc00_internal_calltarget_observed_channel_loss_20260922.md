# C145：内部 call target 真实命中但收尾通道丢失（2026-09-22）

## 状态

`CHANNEL_LOST / PARTIAL_INTERNAL_CALLTARGET_OBSERVED`

H10 保持 H9 的真实 EPT 派生样本、`-n 2 -m 1`、两个 RC00 内部强制解码切口和正常父级 dispatcher 路线不变，只增加 `0x143c77e93` 的动态 marker，并采集 `RAX/RDI/RSP`。CDB 原始输出显示两轮均沿 `0x143deac60 → 0x143c17251 → 0x143c77e93` 到达内部 call target；但 guest runner 在启动后未完成 `CDB_DONE`、`run_meta.json`、`post_state.json` 或 `DONE` 收尾，不能把本轮提升为完整动态结果。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / 未收割
- run id：`EPT_RC00_DISPATCH_CALLTARGET_20260922H10`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- RC00 运行时切口：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_dispatch_calltarget_guest_20260922H10.ps1`
- runner SHA-256：`3619A5D838FD9107FB00AD12A26E32B5F390CAD9EC2FC0C9FC3A6181C79DAFCB`
- CDB 原始输出：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_CALLTARGET_20260922H10\cdb_stdout.txt`
- CDB 原始输出 SHA-256：`3082C16F61319F5FD58032873DA9B3E5A906242FF16FD108EE5C0540A395C122`
- 运行镜像日志 SHA-256：`00BB054DF532A92D3CC3064CC868C7726A9FEC5B5561A50DDDC0FA7A489566ED`
- patch.cdb SHA-256：`7A470AB555BFD4D7001B6D92554CA75105C57BA758E59756B7AE164C54FBFDA6`
- `pre_state.json` SHA-256：`7AF8A2E3DB98034AEC516DA0AC7AF2D1AEEADE1DD0B8B78E4BF019CA625E7594`
- H10 postmortem：`ept-real-decode-20260922H10-postmortem`，UUID=`b5502215-f72b-4bbb-9581-d0acdce7d18a`
- 收尾后已恢复 `qoder-armed-20260919`；当前 VM 为 `running`，Guest `LoggedInUsers=1`

## 动态直接观察

对 CDB 输出只统计“单独一行等于 marker”的命中，排除了断点命令定义中的同名字符串：

- `TARGET_ENTRY`：1 次。
- `DISPATCH_143C17FB0`、`DISPATCH_143C3DEAE`、`DISPATCH_143C30E27`、`DISPATCH_143DEAC60`：各 2 次。
- `INTERNAL_143C17251`：2 次。
- `INTERNAL_143C77E93`：2 次。
- `INTERNAL_143C774A5`、`INTERNAL_143D51144`：各 0 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`RC00_ENTRY`、`RC06_ENTRY`、`RC06_CALL`、`CALLER_OUTPUT_AFTER_COPY`、`SUCCESS_RETURN_EDGE`、`CHILD_CREATE`、`DEVICE_SEAM`：均为 0 次。
- `CDB_DONE`、`POST_STATE`：均为 0 次。

两轮 `0x143c77e93` 现场分别保持其上游状态：

- 第一轮：`RAX=0x7ffbe736dc70`、`RDI=0`、`RSP=0x14f3c0`、`RCX=0x6daf15b8`、`RDX=0x9dc70`、`R8=0x7e4`、`R9=0x1521b0`。
- 第二轮：`RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RSP=0x14f3c0`、`RCX=0x6daf15b8`、`RDX=0x9d730`、`R8=0x87f`、`R9=0x1521b0`。

## 证据解释

**直接观察**：`0x143c77e93` 不是只存在于静态反汇编中的候选地址；它在真实 EPT 派生样本的两轮正常 dispatcher 路线中被动态到达。H9 的未知点“`0x143c17251` 之后是否进入该 call target”已被缩小为“是”。

**不能推出的内容**：本轮没有该 call target 的返回现场、没有 RC00/RC06、没有 caller `+0x80` 前后缓冲、没有 `native_return`、没有 `changed_bytes`，也没有完整 `post_state`。因此不能断言该函数完成了什么业务变换，更不能断言解码发生。

**收尾限制**：guest runner 的镜像日志停在 `LAUNCH`，CDB 输出只收割到内部 marker；通道丢失导致客体前后状态与自然退出结果未收集。H10 应作为仪器/通道部分失败记录，不作为样本阴性。

## 核心完成门槛

仍未满足：没有同一真实 EPT 运行同时证明 `native_return == 0x1` 与 `changed_bytes > 0`，也没有 caller `+0x80` 前后证据。核心分离未完成。

## 下一条最小区分变量

不再重复 H10 的同一组 marker。下一轮应在已确认的 `0x143c77e93` 内部入口或其可验证返回边界建立最小、可收尾的观测，优先解决“该 call 是否返回并改变 `RAX/RDI/栈状态”这一单一问题；若动态通道再次失活，先修复收割平面，不把通道故障写成样本结果。

本轮结论：**H9 的静态 call target 已被真实动态命中两次；核心解码与分离仍未完成。**