# C149：高地址 dispatcher 高频循环边界（2026-09-22）

## 状态

`PARTIAL / HIGH_ADDRESS_DISPATCH_LOOP_OBSERVED`

H14 保持 H13 的真实 EPT 派生样本、`-n 2 -m 1`、两个 RC00 内部切口和全部既有 tail-jump marker 不变，只增加 `0x143f5164d` 与 `0x143e47a9f` marker。首两轮沿既有链到达这两个地址后，运行进入高频重复循环；35 秒窗口内 `TAIL_143F5164D` 命中 69 次，`TAIL_143E47A9F` 命中 73 次。没有进入 main/F250/F060/RC00/RC06，也没有 caller 写回。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_TAIL_JUMP3_PROBE_20260922H14`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- RC00 运行时切口：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_tail_jump3_probe_guest_20260922H14.ps1`
- runner SHA-256：`887092114699348B6E4D1E461BBB299783F9DCAD50B20D4954C8574E2FAC307C`
- CDB 原始输出：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_JUMP3_PROBE_20260922H14\cdb_stdout.txt`
- CDB 原始输出 SHA-256：`85295B0300417CE0959751601FEF55381FCF81DCC65C8A132CD8346D2258E16F`
- 运行镜像日志 SHA-256：`49CF63244B5BA6EFB2E082349FFF9C946B73758A3F09E2285275FB897B3041EA`
- `run_meta.json` SHA-256：`47CAD51721D2B48ABF0BC90816622E47250B1FDCEEDC4C7A6F1D74314636192E`
- `pre_state.json` SHA-256：`04BCC3C5A8F318A332243BD02DFBF4566468B15B496DD01EE5C886B416D4690C`
- `post_state.json` SHA-256：`2FEF644830E655D776B98A3F564F6870A605D0D73041CED78ED2BD43088B8847`
- 静态复核目录：`<HOST_PATH>\EPT\artifacts\captures\tail_jump3_static_20260922H14\`
- 静态反汇编 SHA-256：`55D83F186B400CB01E87F57D766BC701281207FF917F1501888A9ECA0579F5D7`
- 静态清单 SHA-256：`EE452B9B830166BFB8970DF0419935CBF605BB0B650FE1B16DD98B1C009C8285`
- H14 postmortem：`ept-real-decode-20260922H14-postmortem`，UUID=`93522270-d345-4e4f-ac24-b907519743ae`
- 收尾后已释放 stale VirtualBox session lock，恢复 `qoder-armed-20260919`，并确认 VM `running`、Guest `LoggedInUsers=1`

## 动态直接观察

严格只统计 CDB 输出中“单独一行等于 marker”的命中：

- `TARGET_ENTRY`：1 次。
- 四个父级 dispatcher：各 2 次。
- `INTERNAL_143C17251`、`INTERNAL_143C77E93`、`TAIL_143C780E2`、`TAIL_143CA323E`、`TAIL_143A69B86`、`TAIL_143C3B39E`：各 2 次。
- `TAIL_143F5164D`：69 次。
- `TAIL_143E47A9F`：73 次。
- `INTERNAL_143C77E93_RETURN`：0 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- `run_meta.status=WAIT_TIMEOUT`，guest runner 已产生完整前后状态和运行元数据；本轮收尾成功。

首轮进入高频段时，`0x143f5164d` 现场为 `RAX=0x14`、`RDI=0xa`、`R14=0x100000000`、`RSP=0x14f110`、`RCX=0xb829e52a`、`RDX=0xa`、`R8=0x7e4`、`R9=0x14f378`；随后 `0x143e47a9f` 现场 `RAX=0x6c9b7034`、`RDI=0xeab7bd36`、`R14=0x100000000`。后续循环中寄存器值发生多组变化，但仍反复回到这两个 marker。

## 静态直接观察

对 EPT 派生 PE用 Rizin 0.9.1 复核：

- `0x143f516ad` 无条件跳转到 `0x143e47a9f`。
- `0x143f516fd` 存在另一条静态跳转到 `0x143a71a97`，但 H14 未设置该点 marker。
- `0x143e47bd3` 存在直接跳转到 `0x143ba0354`，`0x143e47beb` 存在寄存器间接跳转；当前动态数据表明实际路径在 35 秒窗口内仍由高地址 dispatcher 主导。

## 靶机变化与证据解释

H14 的 `pre_state.json` 与 `post_state.json` 中样本身份一致，`System32\Hardware.exe` 保持基线 genA（size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`），未观察到新的部署、日志输出或目标机业务变化。

**直接观察**：真实 EPT 派生样本进入并持续运行在 `0x143f5164d/0x143e47a9f` 高频循环中。

**候选解释**：这可能是保护 runtime 的正常解释/状态机循环，也可能是当前 VM/调试器条件触发的反分析回路；H14 本身不能区分二者。

**下一步决策依据**：重复增加单个地址 marker 的信息价值已经下降；先进行一次延长到 120 秒的有界运行，观察循环是否自然退出并到达 `MAIN_ENTRY/F250/F060`。若仍只循环，再转向静态 loop 出口或运行时控制流采样，不继续盲目扩展 marker。

## 核心完成门槛

仍未满足：没有同一真实 EPT 运行同时证明 `native_return == 0x1` 与 `changed_bytes > 0`，也没有 RC06 或 caller `+0x80` 前后缓冲证据。核心分离未完成。

本轮结论：**H14 首次确认高地址路径进入稳定高频 dispatcher loop；这不是解码成功，也不是样本阴性。**