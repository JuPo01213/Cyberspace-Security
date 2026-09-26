# C141：首段 dispatcher 强制返回到入口续接点的结果（2026-09-22）

## 状态

`PARTIAL / FORCED_RETURN_REACHES_INVALID_CONTINUATION`

H6 在真实 EPT 派生样本第一次命中 `0x143c17fb0` 时，不写代码字节，只把 `RIP` 重定向到已确认的调用返回地址 `0x14235f6ad`。`DISPATCH_RETURN_FORCED` 命中，证明控制流重定向动作有效；样本随即在 `0x14235f6ad` 发生 `0xC0000005` 访问违例，未进入 `main/-n/F250/F060/RC00/RC06`。这是一条有效的破解式区分结果，但不是解码成功。

## 身份与运行

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_DISPATCH_RIP_REDIRECT_20260922H6`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_dispatch_rip_redirect_guest_20260922H6.ps1`
- runner SHA-256：`66BDDC36BDDACA3B9EB873CD0C27153476B6F58AB69035C45E8D4774E32F84E4`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RIP_REDIRECT_20260922H6\cdb_stdout.txt`
- CDB 日志 SHA-256：`9A98AD7A4BAAB103D45118B480BE9233F6123B8D7FDFD68E9EF7BDF89FEC8474`
- 运行元数据 SHA-256：`F25054D4F51E9E2DA54D278744F7FF2EDFA361A8F6506F86ED21AB10BA7E6A9E`
- EPT 解析摘要：`<HOST_PATH>\EPT\artifacts\captures\dispatch_rip_redirect_20260922H6\forced_redirect_summary.json`
- 解析摘要 SHA-256：`F31BCB0AC18F6C5D300C4D866FD0DA9DAA31836996C7DB00CAF0B81390F2F6B0`
- VM 基线：`qoder-armed-20260919`
- H6 postmortem：`ept-real-decode-20260922H6-postmortem`，UUID=`292e6128-e66c-427c-93bc-eeeb0a250716`
- 收尾：已恢复 `qoder-armed-20260919`；Guest Additions/登录状态随后恢复，未把 H6 运行态带入下一臂

## 直接观察

- `TARGET_ENTRY`：1 次。
- `DISPATCH_CRACK_TARGET`：1 次。
- `DISPATCH_RETURN_FORCED`：1 次。
- `DISPATCH_CALLSITE`、正常 `DISPATCH_RETURN`、四段 dispatcher 的普通 observer marker、`MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、`DEVICE_SEAM`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- 随后 CDB 记录：`Access violation - code c0000005`，现场指令地址为 `Hardware+0x235f6ad`，即 `0x14235f6ad`。
- CDB 给出的现场指令为：`imul edi,dword ptr [rdi+0EBDE3A4h],7Fh`；调试器显示的无效访问地址为 `0x000000000EBDE3A4`。
- 运行元数据为 `WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`；客体样本前后 SHA-256 一致；`System32\Hardware.exe` 前后保持 genA。

## 证据解释

**直接观察**：`RIP` 重定向 action 被执行；控制流到达 `0x14235f6ad`；在那里立即发生访问违例；没有触发已知业务链。

**推导**：高地址 dispatcher 不只是一个可以被无条件跳过的保护入口。正常路径在回到 `0x14235f6ad` 之前，至少会准备该续接代码使用的寄存器/上下文；直接跳过首段链时，`RDI`/相关状态不满足该指令的访问要求。

**候选解释**：缺失状态可能由首段 dispatcher、其后续状态机或更早的入口初始化共同产生。当前证据不能把责任唯一归给 `0x143c17fb0` 首条跳转，也不能把 `0x14235f6ad` 命名为正常业务续接点。

**完成门槛**：没有 `native_return == 0x1`、没有 `changed_bytes > 0`、没有真实 RC06、没有 caller `+0x80` 前后缓冲，核心分离仍未完成。

## 下一条最小区分变量

保留 H6 的 `RIP` 重定向，仅新增异常处理命令在第一次 `AV` 处记录 `RIP/RDI/RSP/RAX/RCX/RDX/R8/R9` 和一小段栈内容，然后停止该臂。目的只是确认缺失状态的寄存器现场，不再重复相同的强制跳转，不对首段 dispatcher 盲目写 `C3`。

本轮结论：**破解式跳过已证明可把控制流送到 `0x14235f6ad`，但该续接需要未被准备的运行状态；分离点应进一步收进“dispatcher 写状态/恢复上下文”而不是继续改外层授权谓词。**