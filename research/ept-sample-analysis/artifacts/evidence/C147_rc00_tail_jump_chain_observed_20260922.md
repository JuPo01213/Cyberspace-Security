# C147：首段 tail-jump 链真实闭合（2026-09-22）

## 状态

`PARTIAL / TAIL_JUMP_CHAIN_OBSERVED_NO_CORE_ENTRY`

H12 保持 H11 的真实 EPT 派生样本、`-n 2 -m 1`、两个 RC00 内部切口和所有既有 dispatcher 观测不变，只增加两个静态落点 marker：`0x143c780e2` 与 `0x143ca323e`。真实样本两轮均命中完整链：`0x143c77e93 → 0x143c780e2 → 0x143ca323e`。这闭合了 H11 从静态反汇编推导出的首个 tail-jump 路线，但仍未进入 RC00/RC06 或 caller 写回。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_TAIL_JUMP_PROBE_20260922H12`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- RC00 运行时切口：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_tail_jump_probe_guest_20260922H12.ps1`
- runner SHA-256：`6EA7E1628116CB61066A19F94431BF2A7C34C3F44A0F34835D4E263139F99238`
- CDB 原始输出：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_JUMP_PROBE_20260922H12\cdb_stdout.txt`
- CDB 原始输出 SHA-256：`3385CEFDE393B4A5CD90DD73AF94B05146C226F75B1DDC489EAA0999EED3BF27`
- 运行镜像日志 SHA-256：`113BE839AD4B0D4FC4F4E36C9634057FB9D3FF1EBE77AFE8DC29E08EFA3AC241`
- `run_meta.json` SHA-256：`F6586926D3BA102C244BC9C511A7EB6B09C703F17B5F713956B8CC96FC877596`
- `pre_state.json` SHA-256：`8587D679EA5185E856F4803C102C06F9F7A272826DD3E36E6EAD462466AF96`
- `post_state.json` SHA-256：`D97287E2736F7F7DAE671B16EFD3B2C6E22C986BD8DA974BAC65688BCF072712`
- 静态复核目录：`<HOST_PATH>\EPT\artifacts\captures\tail_jump_static_20260922H12\`
- 静态反汇编 SHA-256：`74F496AA1C51A471D12F06AB8558266BB6CE9F04238CE12F3EDBCAC613E0C687`
- 静态清单 SHA-256：`B17032FCAA8D1E08AF807BB2B34C26AD688A37653DE833F2076745640FC351E5`
- H12 postmortem：`ept-real-decode-20260922H12-postmortem`，UUID=`7ee55dea-427b-4b38-b223-510d6ce35273`
- 收尾后已恢复 `qoder-armed-20260919`，并确认 VM `running`、Guest `LoggedInUsers=1`

## 动态直接观察

严格只统计 CDB 输出中“单独一行等于 marker”的命中：

- `TARGET_ENTRY`：1 次。
- `DISPATCH_143C17FB0`、`DISPATCH_143C3DEAE`、`DISPATCH_143C30E27`、`DISPATCH_143DEAC60`：各 2 次。
- `INTERNAL_143C17251`、`INTERNAL_143C77E93`：各 2 次。
- `TAIL_143C780E2`：2 次。
- `TAIL_143CA323E`：2 次。
- `INTERNAL_143C77E93_RETURN`：0 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- `run_meta.status=WAIT_TIMEOUT`，但 guest runner 已产生完整 `pre_state.json`、`post_state.json` 和 `run_meta.json`；本轮收尾成功。

两轮 tail-jump 现场：

- 第一轮 `TAIL_143C780E2`：`RIP=0x143c780e2`、`R14=0x143c780e2`、`RSP=0x14f3c8`、`RCX=0x6daf15b8`、`RDX=0x9dc70`、`R8=0x7e4`、`R9=0x1521b0`。
- 第一轮 `TAIL_143CA323E`：`RIP=0x143ca323e`、`RSP=0x14f3a0`、`RCX=0xa`，其余参数保持第一轮上下文。
- 第二轮对应 `RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RDX=0x9d730`、`R8=0x87f`、`R9=0x1521b0`，两个 tail marker 同样各命中一次。

## 静态直接观察

对 EPT 派生 PE（SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）用 Rizin 0.9.1 复核：

- `0x143c780fe` 无条件跳转到 `0x143ca323e`。
- `0x143ca3253` 无条件跳转到 `0x143a69b86`。
- `0x143a69b86` 首条为 `lea r14d,[rsi-0x1472a40a]`，随后 `0x143a69b8d` 无条件跳转到 `0x143c3b39e`。
- `0x143a69b86` 与 `0x143c3b39e` 尚未在 H12 动态观测；下一轮优先加这两个 marker。

## 靶机变化与证据解释

H12 的 `pre_state.json` 与 `post_state.json` 中样本身份一致，`System32\Hardware.exe` 均保持基线 genA（size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`），未观察到新的部署、日志输出或目标机业务变化。

**直接观察**：首个 tail-jump 链在真实 EPT 派生样本两轮闭合到 `0x143ca323e`。

**推导**：H11 的“常规返回点不命中”由控制流重定向解释，而不是 call 没有继续执行；当前路径仍处于高地址混淆 dispatcher 内。

**不能推出的内容**：tail-jump 命中不证明解码、RC06、caller `+0x80` 写回、`native_return` 或 `changed_bytes`。

## 核心完成门槛

仍未满足：没有同一真实 EPT 运行同时证明 `native_return == 0x1` 与 `changed_bytes > 0`，也没有 RC06 或 caller `+0x80` 前后缓冲证据。核心分离未完成。

## 下一条最小区分变量

保持 H12 全部条件不变，只增加 `0x143a69b86` 与其直接跳转目标 `0x143c3b39e` 的 marker，验证第二段 tail-jump 是否继续沿静态链推进；不对高地址 dispatcher 写补丁。

本轮结论：**首段 `0x143c77e93 → 0x143c780e2 → 0x143ca323e` 已被真实动态命中两轮；核心解码与分离仍未完成。**