# C150：高地址路径访问违例但缺少寄存器上下文（2026-09-22）

## 状态

`PARTIAL / HIGH_ADDRESS_DISPATCH_AV_WITHOUT_CONTEXT`

H15 是一次 120 秒长窗口验证：样本、卡密、两个 RC00 内部切口和 H14 全部 marker 保持不变，只延长 CDB/guest 运行预算。真实 EPT 派生样本先完整到达首段 tail-jump 链和 `0x143f5164d → 0x143e47a9f`，随后 CDB 的 `sxe av` 捕获到一次 `0xC0000005`。CDB 默认 AV 处理只输出了异常地址，没有采集寄存器；运行最终因 CDB 超时由 runner 收尾。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_LONG_WINDOW_PROBE_20260922H15`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- 运行窗口：`expected_duration_sec=120`，`deadline_sec=135`
- RC00 运行时切口：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_long_window_probe_guest_20260922H15.ps1`
- runner SHA-256：`A5D940F16923028027072318A0838F3954E0B3DE20953573BEBDFDEFB5231CDB`
- CDB 原始输出：`<HOST_PATH>\HexPatch\probe\EPT_RC00_LONG_WINDOW_PROBE_20260922H15\cdb_stdout.txt`
- CDB 原始输出 SHA-256：`4EE656B387AC34ED6164E9C4205D0C8A3EB87F74A1CA85223AC5AAA32636B0B3`
- 运行镜像日志 SHA-256：`2CC989DB58102F21A356374E2585EFDBDF58C4E7C6519CB62C5169FD5D317F49`
- `run_meta.json` SHA-256：`F1B9373E3D8508F75ED2502A38D9AF8C62D7D2B5E415DE7B51823369BF293B17`
- `pre_state.json` SHA-256：`A441D1FD838BDE1A30BB60ACDCC5B2CC7D73D062983F6B640D4A86344A6DD5A3`
- `post_state.json` SHA-256：`A3901941D4A294DA44B45F10E8358A818F526DA7929EC8E784A9D2A7995D64BD`
- H15 postmortem：`ept-real-decode-20260922H15-postmortem`，UUID=`dfededbd-8152-41b8-8afd-bbb470fe5710`
- 之后已执行冷启动恢复并确认 `qoder-armed-20260919`、VM `running`、Guest `LoggedInUsers=1`

## 动态直接观察

严格只统计 CDB 输出中“单独一行等于 marker”的命中：

- `TARGET_ENTRY`：1 次。
- `DISPATCH_143C17FB0`、`DISPATCH_143C3DEAE`、`DISPATCH_143C30E27`、`DISPATCH_143DEAC60`：各 1 次。
- `INTERNAL_143C17251`、`INTERNAL_143C77E93`、`TAIL_143C780E2`、`TAIL_143CA323E`、`TAIL_143A69B86`、`TAIL_143C3B39E`、`TAIL_143F5164D`、`TAIL_143E47A9F`：各 1 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- 之后出现 CDB 文本：`Access violation - code c0000005 (first chance)`，异常指令显示为 `0x000000021df70790`，但没有寄存器、栈或模块归属上下文。
- `run_meta.status=WAIT_TIMEOUT`、`timed_out=true`；guest runner 已产生完整前后状态和运行元数据。

## 靶机变化

`pre_state.json` 与 `post_state.json` 中 EPT 派生样本身份一致；`System32\Hardware.exe` 前后均为基线 genA（size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`）。`C:\Windows\Temp` 的 15 个 EPT 文件与 `EPT_runtime_hash.csv` 前后保持一致，未观察到本轮新增部署或业务输出。

## 证据解释

**直接观察**：长窗口并未证明高地址 loop 会自然到达 main；在首段 tail-jump 后，CDB 观测到一个访问违例并停住。

**未知**：由于没有 AV 时的 `RIP/RAX/RDI/RSP`、栈和模块上下文，不能判断该 AV 是样本自身保护路径、调试器条件触发，还是先前 breakpoint/保存态差异造成的仪器现象。

**不能推出的内容**：AV 不等于解码失败，也不等于分离完成；没有 RC06、caller `+0x80`、`native_return` 或 `changed_bytes`。

## 核心完成门槛

仍未满足：没有同一真实 EPT 运行同时证明 `native_return == 0x1` 与 `changed_bytes > 0`。核心分离未完成。

## 下一条最小区分变量

恢复干净基线后，保持 H15 的样本、参数、切口和 marker 不变，只把 `sxe av` 改为一次性 AV 上下文采集（`RIP/RAX/RDI/RSP/RCX/RDX/R8/R9`、当前指令和栈）并在采集后退出 CDB。该结果用于区分样本 AV 与仪器 AV，不改变样本控制流。

本轮结论：**长窗口真实运行在高地址路径触发了 AV，但上下文不足；核心解码与分离仍未完成。**