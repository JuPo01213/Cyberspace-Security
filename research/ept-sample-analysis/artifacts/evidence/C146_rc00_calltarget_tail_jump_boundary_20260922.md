# C146：内部 call 的尾跳转边界（2026-09-22）

## 状态

`PARTIAL / INTERNAL_CALL_TAIL_JUMP_IDENTIFIED`

H11 在真实 EPT 派生样本上保持 H10 的两个 RC00 内部切口和正常 dispatcher 路线，只增加静态候选返回点 `0x143c17261` 的动态 marker，并在首次命中时退出 CDB。真实输出中 `0x143c77e93` 两轮均命中，但 `0x143c17261` 为 0 次；第二轮 dispatcher 仍然出现。随后对同一 EPT 派生 PE 做静态复核，确认 `0x143c77e93` 并不是普通 `ret`：它从栈中 `pop r14`，加上 `0x60e81` 后 `jmp r14`。因此静态 call 的常规返回点不是当前动态控制流落点。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_CALL_RETURN_PROBE_20260922H11`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- RC00 运行时切口：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_call_return_probe_guest_20260922H11.ps1`
- runner SHA-256：`08531B909714C9369AC3BFA2D7D7451C257CFD4BED35405B4F51E19AA3FD9229`
- CDB 原始输出：`<HOST_PATH>\HexPatch\probe\EPT_RC00_CALL_RETURN_PROBE_20260922H11\cdb_stdout.txt`
- CDB 原始输出 SHA-256：`48A4A7744212D17408A88FE55AC0AAA5FFE3D6EDA870E61B4D95B5A558F345B4`
- 运行镜像日志 SHA-256：`55A49156E26DD67285245A895CB6EDF6554DA2A57C2DADA7C519C9829523F297`
- `run_meta.json` SHA-256：`9C94FACCE7F30ED929504F921ADEF7D67F453FE35CD0F86E7A79727F4D793C8A`
- `pre_state.json` SHA-256：`899EB9574D92F3D02681DDF3C5D213B421825C79D0574EE0D36E84ABE8D3B91F`
- `post_state.json` SHA-256：`39A1006BB905FDCFDC53293899227E7111FC6D56A3876645E18E158258E36E6D`
- 静态复核目录：`<HOST_PATH>\EPT\artifacts\captures\dispatch_calltarget_static_20260922H11\`
- 静态反汇编 SHA-256：`7AD449C0364F0076A6A552D64F7A5E3F1464A3C17B7C1DD58BE8029234F72921`
- 静态清单 SHA-256：`FD902A3F49A2AF7E9A7E7DD66DAB6AC6C1968CA6F40579AA3D0305AFAE4B9CD6`
- H11 postmortem：`ept-real-decode-20260922H11-postmortem`，UUID=`2958da75-29dd-4b7a-b000-9ef82f95078e`
- 收尾后已恢复 `qoder-armed-20260919`，并确认 VM `running`、Guest `LoggedInUsers=1`

## 动态直接观察

严格只统计 CDB 输出中“单独一行等于 marker”的命中：

- `TARGET_ENTRY`：1 次。
- `DISPATCH_143C17FB0`、`DISPATCH_143C3DEAE`、`DISPATCH_143C30E27`、`DISPATCH_143DEAC60`：各 2 次。
- `INTERNAL_143C17251`：2 次。
- `INTERNAL_143C77E93`：2 次。
- `INTERNAL_143C77E93_RETURN`（静态常规返回点 `0x143c17261`）：0 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- `run_meta.status=WAIT_TIMEOUT`，但 guest runner 已生成 `run_meta.json` 与 `post_state.json`；本轮不是通道丢失。

H11 的两个内部入口现场与 H10 一致：第一轮 `RAX=0x7ffbe736dc70`、`RDI=0`、`RSP=0x14f3c0`；第二轮 `RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RSP=0x14f3c0`。由于返回点没有命中，不能从动态现场直接读取 tail-jump 后的 `R14`，该值由静态指令和栈上的常规返回地址推导。

## 静态直接观察

对 EPT 派生 PE（SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）用 Rizin 0.9.1 复核：

- `0x143c17251`：`call 0x143c77e93`。
- 常规 call 返回地址：`0x143c17261`。
- `0x143c77e93`：`lea rsi, ...; pop r14; lea r14, [r14+0x60e81]; jmp r14`。
- 因此，如果栈上的常规返回地址为 `0x143c17261`，首个静态 tail-jump 落点为 `0x143c780e2`；这是下一轮动态观测目标，不是已经动态确认的业务语义。
- `0x143c780e2` 的静态代码继续进入另一段混淆 dispatcher，并非 RC00/RC06 的直接入口。

## 证据解释

**直接观察**：H11 证明 `0x143c77e93` 两轮真实到达，且常规返回地址 `0x143c17261` 未命中；静态代码证明该入口会把栈上的返回地址改造成间接跳转目标。由此，H10/H11 的“没有常规 return marker”不能被解释成函数未返回。

**推导**：当前控制流边界已从 `0x143c17251` 后的 call 缩小到 `0x143c77e93 → 0x143c780e2` 的 tail-jump；这只是控制流定位，不代表已经进入解码、RC06 或 caller 写回。

**靶机变化**：H11 `pre_state.json` 与 `post_state.json` 中 `System32\Hardware.exe` 均为基线 genA，`System32\Logs` 仍为既有目录，未观察到新的部署或输出变化。

## 核心完成门槛

仍未满足：没有同一真实 EPT 运行同时证明 `native_return == 0x1` 与 `changed_bytes > 0`，没有 RC06 入口、caller `+0x80` 前后缓冲或成功返回证据。核心分离未完成。

## 下一条最小区分变量

保持 H11 全部条件不变，只增加 `0x143c780e2` 与其直接跳转落点 `0x143ca323e` 的 marker，先确认 `0x143c77e93` 的 tail-jump 在真实运行中是否按静态推导落地；不对该 dispatcher 写补丁，不重复 H11 的常规返回点观测。

本轮结论：**`0x143c77e93` 是一个真实命中的尾跳转入口，不是普通 return 函数；核心解码与分离仍未完成。**