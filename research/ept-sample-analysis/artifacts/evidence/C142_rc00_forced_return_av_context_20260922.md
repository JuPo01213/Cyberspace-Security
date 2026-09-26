# C142：强制续接访问违例的寄存器现场（2026-09-22）

## 状态

`PARTIAL / FORCED_RETURN_AV_CONTEXT_CAPTURED`

H7 保留 H6 的运行态控制流重定向，只在第一次访问违例时增加寄存器观察。`DISPATCH_RETURN_FORCED` 和 `FORCED_AV_CONTEXT` 均命中；异常现场确认 `RIP=0x14235f6ad`、`RDI=0`，而调用参数仍为第一组 dispatcher 现场值。该结果把“续接需要额外状态”从候选解释推进为直接寄存器观察，但仍不是自然解码或核心分离完成。

## 身份与运行

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_DISPATCH_AV_CONTEXT_20260922H7`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_dispatch_av_context_guest_20260922H7.ps1`
- runner SHA-256：`35E5779887D8E9E9FEF8E0FF678350298B2A67A00CCDED5CCDE608309FD6C5B6`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_AV_CONTEXT_20260922H7\cdb_stdout.txt`
- CDB 日志 SHA-256：`5E17AAEC0C4F6E2DAC4CC32B3785EF701494051FE11D4EC9BFE9A83C6E95697D`
- 运行元数据 SHA-256：`3376C57DDD12C1CAF9F5EC18ADABEBE40DB000CB77CD41BEED504C076CD865E0`
- EPT 解析摘要：`<HOST_PATH>\EPT\artifacts\captures\dispatch_av_context_20260922H7\av_context_summary.json`
- 解析摘要 SHA-256：`58CD84821BCB81A8DAC186E3518B1FC6134E7B4F64E8E105770B1D8BB5B3FBCE`
- VM 基线：`qoder-armed-20260919`
- H7 postmortem：`ept-real-decode-20260922H7-postmortem`，UUID=`82532aa7-2ec6-44d5-bdeb-b94b750820c7`
- 收尾：已恢复 `qoder-armed-20260919`，并确认 Guest 登录状态恢复

## 直接观察

- `TARGET_ENTRY`：1 次；`DISPATCH_CRACK_TARGET`：1 次；`DISPATCH_RETURN_FORCED`：1 次。
- `FORCED_AV_CONTEXT`：1 次；`FORCED_AV_CONTEXT_END`：1 次。
- 异常现场：
  - `RIP=0x14235f6ad`
  - `RDI=0x0`
  - `RSP=0x14f400`
  - `RAX=0x7ffbe736dc70`
  - `RCX=0x7e4`
  - `RDX=0x9dc70`
  - `R8=0x7e4`
  - `R9=0x1521b0`
- 随后为 `Access violation - code c0000005`，指令仍是 `imul edi,dword ptr [rdi+0EBDE3A4h],7Fh`；CDB 将该异常推进到 second chance，runner 最终按截止时间收尾。
- `DISPATCH_CALLSITE`、正常 `DISPATCH_RETURN`、`MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、`DEVICE_SEAM`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- 运行元数据为 `WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`；response 注入为 `false`；客体样本前后 SHA-256 一致。

## 证据解释

**直接观察**：强制续接动作有效；违例点和寄存器完整记录；`RDI=0`，且未进入业务链。

**推导**：在这条被强制跳过的控制流上，`0x14235f6ad` 使用的状态并非由入口参数直接提供；正常 dispatcher 链或更早运行时初始化必须建立它，至少不能把“把 RIP 送回去”当作充分条件。

**未知**：本臂仍不能证明 `RDI` 正常路径的最终值，也不能证明它单独就是唯一缺失状态；还需要在不跳过 dispatcher 的情况下记录各段链的 `RDI/RSP/RAX` 变化。

**完成门槛**：没有 `native_return == 0x1`、没有 `changed_bytes > 0`、没有 RC06、没有 caller `+0x80` 前后缓冲，核心分离仍未完成。

## 下一条最小区分变量

回到 H3 的正常 dispatcher 路线，不做强制跳转；只把四个 dispatcher marker 的寄存器采集扩展为 `RAX/RDI/RSP`，保持样本、输入、快照、断网、response 注入和截止时间不变。目标是判断状态是否在四段链之间发生可见变化；若全程不变，则改向高地址链内部的间接跳转/状态写入点；若发生变化，再以变化点为破解切口。

本轮结论：**H7 已证明强制返回动作可执行但不构成有效续接；真正应分析的是 dispatcher 的状态建立，而不是继续改外层授权谓词。**