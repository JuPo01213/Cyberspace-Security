# C144：内部 dispatcher 落点边界与状态转移前置点（2026-09-22）

## 状态

`PARTIAL / INTERNAL_143C17251_OBSERVED_CALL_TARGET_NOT_REACHED`

H9 保持 H8 的正常运行路线，只增加三个由同一 EPT 派生 PE 静态复核出的内部 marker：`0x143c17251`、`0x143c774a5`、`0x143d51144`。真实样本在每轮 `0x143deac60` 后命中 `0x143c17251`，但 `0x143c774a5` 和 `0x143d51144` 均未命中；`0x143c17251` 现场的 `RAX/RDI` 与对应 dispatcher 入口保持一致。运行仍在有界窗口内超时，没有进入 RC00/RC06。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_DISPATCH_INTERNALS_20260922H9`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_dispatch_internals_guest_20260922H9.ps1`
- runner SHA-256：`C1F34257B29D97A47A1C9F4C523A0C8436DDA40E88F14D4429054D55DFA94F9E`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_INTERNALS_20260922H9\cdb_stdout.txt`
- CDB 日志 SHA-256：`B6B4C1B46ABCD52120CE914E5E2CDC6A67D4955D0CED9BE93866738F66BBA830`
- 运行元数据 SHA-256：`9F623EA5FDDFD89AD06E15F4A9667C3EBA6E149A85ABF568B034AD6D5E3585D3`
- EPT 动态解析摘要：`<HOST_PATH>\EPT\artifacts\captures\dispatch_internals_20260922H9\internal_dispatch_summary.json`
- 动态摘要 SHA-256：`C6EF0D1499E4D1C68E2557158C8D6F717F274D827238F8E405A71CCC6BFCABE5`
- EPT 静态复核输出：`<HOST_PATH>\EPT\artifacts\captures\parent_dispatch_internal_static_20260922\rizin_internal_dispatch_disassembly.txt`
- 静态复核输出 SHA-256：`511E1A4FB6D8024CF95A78565362D750B18A8519D5CFF5AB3AF69AD855A13D35`
- VM 基线：`qoder-armed-20260919`
- H9 postmortem：`ept-real-decode-20260922H9-postmortem`，UUID=`39c180f4-610d-4fd1-8bb6-b9df112f410a`
- 收尾：已恢复 `qoder-armed-20260919`，并确认 Guest 登录状态恢复

## 静态观察

对 EPT 派生 PE（SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）用 Rizin 0.9.1 复核：

- `0x143deac60` 首条 `jmp 0x143c17251`。
- `0x143c17251` 首条写入 `[rsp + rcx - 0x6daf15b8]`，随后 `call 0x143c77e93`；当前动态 marker 选取的是该入口和两个后续候选点。
- `0x143c774a5` 与 `0x143d51144` 的静态代码存在，但 H9 动态未命中，不能把它们写成实际执行点。

## 动态直接观察

- `TARGET_ENTRY`：1 次；四个高地址 dispatcher：各 2 次。
- `INTERNAL_143C17251`：2 次，命中顺序为每轮 `DISPATCH_143DEAC60` 之后、下一轮 `DISPATCH_143C17FB0` 之前。
- `INTERNAL_143C774A5`：0 次。
- `INTERNAL_143D51144`：0 次。
- 第一轮 `INTERNAL_143C17251`：`RAX=0x7ffbe736dc70`、`RDI=0`、`RSP=0x14f3d8`、`RCX=0x6daf15b8`、`RDX=0x9dc70`、`R8=0x7e4`、`R9=0x1521b0`。
- 第二轮 `INTERNAL_143C17251`：`RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RSP=0x14f3d8`、`RCX=0x6daf15b8`、`RDX=0x9d730`、`R8=0x87f`、`R9=0x1521b0`。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、`DEVICE_SEAM`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- 运行元数据为 `WAIT_TIMEOUT`；客体样本前后身份一致；`System32\Hardware.exe` 前后保持 genA。

## 证据解释

**直接观察**：第一轮 `0x143deac60 → 0x143c17251` 的内部跳转被真实命中；静态可见的 `0x143c77e93` call target 尚未做动态 marker，因此不能从 H9 断言它是否执行；两个其他候选点没有命中。

**推导**：`0x143c17251` 是当前状态变化区间的稳定锚点，其首条栈写入和后续 `call 0x143c77e93` 是下一条最小观测点；但“写栈”不等于已确认业务状态写入。

**完成门槛**：没有 `native_return == 0x1`、没有 `changed_bytes > 0`、没有真实 RC06、没有 caller `+0x80` 前后缓冲，核心分离仍未完成。

## 下一条最小区分变量

保持 H9 全部条件不变，只增加 `0x143c77e93` marker 与 `RAX/RDI/RSP` 采集；不要对 `0x143c17251` 或其 call target 写补丁。若该点命中且状态变化可见，下一步再评估是否在它的返回边界做最小控制流实验；若不命中，则把当前 call 视为静态候选而非动态路径，转向第一轮 `0x143c17251` 之后的直接间接跳转。

本轮结论：**内部入口 `0x143c17251` 已经真实命中，状态变化区间进一步缩窄到其后续 call/间接跳转；核心分离仍未完成。**