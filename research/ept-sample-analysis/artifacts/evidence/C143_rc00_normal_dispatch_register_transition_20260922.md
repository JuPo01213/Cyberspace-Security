# C143：正常 runtime dispatcher 的 RAX/RDI/RSP 状态转移（2026-09-22）

## 状态

`PARTIAL / NORMAL_DISPATCH_REGISTER_TRANSITION_OBSERVED`

H8 不做强制跳过，只扩展 C138 的父级 dispatcher 观察寄存器。真实 EPT 派生样本仍命中四段高地址链各两次；第一轮与第二轮的 `RAX/RDI/RSP` 不同，说明状态在高地址链内部建立或交换。没有进入 `main/-n/F250/F060/RC00/RC06`，运行按有界超时结束。

## 身份与运行

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_DISPATCH_REGISTERS_20260922H8`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_dispatch_registers_guest_20260922H8.ps1`
- runner SHA-256：`838F46FEF34958C8C3B1EA6BAF8A7E026297E6F4F6FADD30D73B498822049C73`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_REGISTERS_20260922H8\cdb_stdout.txt`
- CDB 日志 SHA-256：`D3BAA9221EB482874439585172EB0F4D60C6AA6EF08EEE1D5E762A78DBF22B09`
- 运行元数据 SHA-256：`22149476B78CEBD4F5A4E280622FAD8AF61411263CDC05B401AD36D1A3043CBA`
- EPT 解析摘要：`<HOST_PATH>\EPT\artifacts\captures\dispatch_registers_20260922H8\register_transition_summary.json`
- 解析摘要 SHA-256：`53A4E7771AF33DB7F05D295FC1E2159C5D5051D606ADD4458884BB8B40D5F84C`
- VM 基线：`qoder-armed-20260919`
- H8 postmortem：`ept-real-decode-20260922H8-postmortem`，UUID=`e4c89848-60d2-46d8-8b2b-d191aa5ea690`
- 收尾：已恢复 `qoder-armed-20260919`，并确认 Guest 登录状态恢复

## 直接观察

入口现场：`RAX=0x14235f67b`、`RDI=0`、`RSP=0x14ff28`；入口参数为 `RCX=0x280000`、`RDX=0x14235f67b`、`R8=0x280000`、`R9=0x14235f67b`。

第一轮 dispatcher：

- `0x143c17fb0`、`0x143c3deae`、`0x143c30e27` 均为 `RAX=0x7ffbe736dc70`、`RDI=0`、`RSP=0x14f400`，参数 `RCX/R8=0x7e4`、`RDX=0x9dc70`、`R9=0x1521b0`。
- `0x143deac60` 为 `RAX=0x7ffbe736dc70`、`RDI=0`、`RSP=0x14f3e8`，`RCX=0x6daf15b8`，其他参数保持。

第二轮 dispatcher：

- `0x143c17fb0`、`0x143c3deae`、`0x143c30e27` 均为 `RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RSP=0x14f400`，参数 `RCX/R8=0x87f`、`RDX=0x9d730`、`R9=0x1521b0`。
- `0x143deac60` 为 `RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RSP=0x14f3e8`，`RCX=0x6daf15b8`，其他参数保持。

以上值由 `register_transition_summary.json` 从原始 CDB marker 后的寄存器行逐段解析，未跨越下一个 marker。

## 其他运行结果

- `TARGET_ENTRY`：1 次；四个 dispatcher marker：各 2 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、`DEVICE_SEAM`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- 运行元数据为 `WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`；客体样本前后 SHA-256 一致；`System32\Hardware.exe` 前后保持 genA。

## 证据解释

**直接观察**：第一轮 `RDI=0`，第二轮 `RDI` 变为 `0x7ffbe736da30`；第一轮 `RAX=0x7ffbe736dc70`，第二轮变为 `0x7ffbe736d730`；`RSP` 只在 `0x143deac60` 处出现 `0x14f3e8` 的稳定变化。

**推导**：状态建立发生在第一轮 `0x143deac60` 之后、第二轮 `0x143c17fb0` 之前，或发生在其间的未观测高地址控制流中。这把破解切口从“首条 dispatcher `jmp`”收窄为“第一轮链到第二轮入口之间的状态转移区间”。

**未知**：当前还没有该区间的返回地址、间接跳转目标、内存写入点或自然 RC00 连接；不能把这些 ntdll 地址命名为某种具体对象或 API。

**完成门槛**：没有 `native_return == 0x1`、没有 `changed_bytes > 0`、没有真实 RC06、没有 caller `+0x80` 前后缓冲，核心分离仍未完成。

## 下一条最小区分变量

以第一轮 `0x143deac60` 为边界设置一次性 `pt/gu` 或返回后观察，目标是捕获它到第二轮 `0x143c17fb0` 之间的第一条可执行地址/间接跳转；同时保留 `RAX/RDI/RSP` 记录。若单步成本过高，则先对两个变化后的 ntdll 指针做只读反汇编/模块归属核验，不直接把它们当作补丁地址。

本轮结论：**正常 dispatcher 的内部状态转移已被真实观测；核心分离仍未完成，但下一次可以围绕第一轮末端到第二轮入口的窄区间做定位，而不是再次尝试外层授权谓词。**