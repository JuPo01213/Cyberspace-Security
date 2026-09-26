# C140：首段 dispatcher 运行时 `ret` 臂的 CDB 仪器失败（2026-09-22）

## 状态

`INVALID_INSTRUMENT / BREAKPOINT_ACTION_SYNTAX_BEFORE_PATCH`

H5 是授权 VM 内、以 EPT 派生样本为输入的首段 dispatcher 破解式验证。真实样本命中 `0x143c17fb0` 一次，CDB 随后对包含 `bc/eb` 的 breakpoint action 报 `Syntax error`；原始字节转储仍为 `e9f95e0200`，因此 `C3` 没有实际写入。没有任何后续业务 marker。该臂是仪器失败，不是样本阴性，不是“ret 失败”，也不改变核心完成门槛。

## 身份与运行

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_DISPATCH_RET_PATCH_20260922H5`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_dispatch_ret_patch_guest_20260922H5.ps1`
- runner SHA-256：`8B4CB7DA4296592590B2867D2A9B4DD2DCBF5223B133680964A9CDF2DFF4CA30`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RET_PATCH_20260922H5\cdb_stdout.txt`
- CDB 日志 SHA-256：`311E1315F42A9698511FF58576577588BCD84F00670A7D359CCFCCC47DAAFF8A`
- 运行元数据 SHA-256：`FCDFACDED5218036815DE42F2F7A024D1673887C1B3922DBB903708745A3C57C`
- EPT 解析摘要：`<HOST_PATH>\EPT\artifacts\captures\dispatch_ret_patch_instrument_20260922H5\instrument_summary.json`
- 解析摘要 SHA-256：`44A62DABA31968494156BAF5EC7204865FC8311D98BD1C066B6C81A43E9DCB26`
- VM 基线：`qoder-armed-20260919`
- postmortem：`ept-real-decode-20260922H5-postmortem`，UUID=`ab8c9a33-df87-4804-bf15-e86180241f49`
- 收尾：已恢复 `qoder-armed-20260919`，Guest 登录状态恢复

## 直接观察

- `TARGET_ENTRY`：1 次。
- `DISPATCH_CRACK_TARGET`：1 次。
- `DISPATCH_RET_PATCH_APPLIED`：0 次。
- `DISPATCH_CALLSITE`、`DISPATCH_RETURN`、`DISPATCH_143C17FB0`、`DISPATCH_143C3DEAE`、`DISPATCH_143C30E27`、`DISPATCH_143DEAC60`、`MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- 原始 CDB 日志中明确出现 `Syntax error in '.echo DISPATCH_CRACK_TARGET; ... bc 143c17fb0; eb 143c17fb0 c3; ...'`。
- 同一错误后的字节转储显示：`0x143c17fb0` 仍为 `e9f95e0200`，与 EPT 静态输入原始首五字节一致；不能声称 `C3` 已写入。
- 运行元数据为 `WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`；response 注入为 `false`。

## 解释

**观察**：断点命中，动作语法失败，补丁未应用，运行被截止收尾。

**分类**：`INVALID_INSTRUMENT`。本轮没有提供任何关于首段 `ret` 是否能让样本继续的样本行为证据。

**未决**：下一次应避免在同一个 breakpoint action 中调用 `eb`。使用 `r rip=0x14235f6ad` 的控制流重定向只改变运行态寄存器，不写代码字节；若该方法能够进入调用点/返回点或已知业务点，再考虑更低扰动的内存补丁机制。

**完成门槛**：没有 `native_return == 0x1`、没有 `changed_bytes > 0`、没有 caller `+0x80` 前后缓冲，核心分离仍未完成。

本轮结论：**H5 只证明 CDB action 语法不支持当前写法，不能证明首段 `ret` 破解路线无效。**