# C148：第二段 tail-jump 与状态寄存器转换（2026-09-22）

## 状态

`PARTIAL / SECOND_TAIL_JUMP_STATE_TRANSITION_OBSERVED`

H13 保持 H12 的真实 EPT 派生样本、`-n 2 -m 1`、两个 RC00 内部切口和既有 tail-jump marker 不变，只增加 `0x143a69b86` 与 `0x143c3b39e` 两个静态落点 marker。真实样本两轮均沿 `0x143ca323e → 0x143a69b86 → 0x143c3b39e` 继续执行；在该段入口 `RAX` 从前一段的对象指针变为 `0x9472`。静态复核显示 `0x143c3b39e` 之后重排栈并 `jmp 0x143f5164d`。

## 身份与证据

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本 SHA-256 前后：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_TAIL_JUMP2_PROBE_20260922H13`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不记录明文
- response 注入：`false`
- RC00 运行时切口：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_tail_jump2_probe_guest_20260922H13.ps1`
- runner SHA-256：`961626C425551D58F37ECEB809E1E0EE819C71F173A0F2D6EA94350A3CE331C8`
- CDB 原始输出：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_JUMP2_PROBE_20260922H13\cdb_stdout.txt`
- CDB 原始输出 SHA-256：`A09AD2712C0DC639A2BB000813D59B547DE1873C3932E661493826EA9779DABB`
- 运行镜像日志 SHA-256：`CF78C0F8D7AB287F8D83D664356FFFF6D637DD99A11F2EAABE57192031187903`
- `run_meta.json` SHA-256：`5236F5432D778A0FA8189F5EBCE8D9BE188658A013507476F30780F9C8811FCD`
- `pre_state.json` SHA-256：`CA423E9635DBA306C4E2AACDA7B1E8C3E8DA2CBB7CB83AF3C1AC87780051901`
- `post_state.json` SHA-256：`67C67DEE39E7F001F55D9E295F72B5D29A6B0478455C513ABBF8F5A9520E9059`
- 静态复核目录：`<HOST_PATH>\EPT\artifacts\captures\tail_jump2_static_20260922H13\`
- 静态反汇编 SHA-256：`5B85CB0ED0CDDD8E8B5D9D0C632981BDF2C98795562D7F446233F40C507F4390`
- 静态清单 SHA-256：`11F05916945043E93EFD0D95889B658D6ED6308DF5D667E4F43045F14FBA018A`
- H13 postmortem：`ept-real-decode-20260922H13-postmortem`，UUID=`558b4fc4-1668-4bac-9da3-d1066d6b26ee`
- 收尾后已恢复 `qoder-armed-20260919`，并确认 VM `running`、Guest `LoggedInUsers=1`

## 动态直接观察

严格只统计 CDB 输出中“单独一行等于 marker”的命中：

- `TARGET_ENTRY`：1 次。
- 四个父级 dispatcher：各 2 次。
- `INTERNAL_143C17251`、`INTERNAL_143C77E93`、`TAIL_143C780E2`、`TAIL_143CA323E`、`TAIL_143A69B86`、`TAIL_143C3B39E`：各 2 次。
- `INTERNAL_143C77E93_RETURN`：0 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。
- `run_meta.status=WAIT_TIMEOUT`，guest runner 已产生完整前后状态与运行元数据；本轮收尾成功。

第一轮第二段现场：

- `TAIL_143A69B86`：`RIP=0x143a69b86`、`RAX=0x9472`、`RDI=0`、`R14=0x143c780e2`、`RSP=0x14f390`、`RCX=0xa`、`RDX=0x9dc70`、`R8=0x7e4`、`R9=0x1521b0`。
- `TAIL_143C3B39E`：`RIP=0x143c3b39e`、`RAX=0x9472`、`R14=0x80000000`，其余参数保持第一轮上下文。

第二轮 `RAX=0x9472`、`R14=0x80000000` 的对应 marker 同样各命中一次；第二轮 `RDX=0x9d730`、`R8=0x87f`，其余参数与 H12 第二轮一致。

## 静态直接观察

对 EPT 派生 PE用 Rizin 0.9.1 复核：

- `0x143c3b425` 无条件跳转到 `0x143f5164d`。
- `0x143f5164d` 首条为 `mov ebx, 0xdb027a93`，其后 `0x143f516ad` 无条件跳转到 `0x143e47a9f`；`0x143f516fd` 还存在另一条静态跳转到 `0x143a71a97`。
- `0x143f5164d` 尚未在 H13 动态观测；下一轮优先增加该点及其直接跳转目标 `0x143e47a9f`。

## 靶机变化与证据解释

H13 的 `pre_state.json` 与 `post_state.json` 中样本身份一致，`System32\Hardware.exe` 保持基线 genA（size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`），`System32\Logs` 未出现新的可归因输出，未观察到目标机业务变化。

**直接观察**：第二段 tail-jump 两轮均到达 `0x143c3b39e`，并伴随 `RAX=0x9472` 与 `R14=0x80000000` 的状态转移。

**推导**：当前高地址路径不是简单的重复 dispatcher 入口，而是在不同阶段重新编码/转移寄存器和栈；但这些值的业务含义仍未知。

**不能推出的内容**：`RAX=0x9472` 不是 `native_return`，`R14=0x80000000` 也不是解码成功标志；本轮没有 RC06、caller 写回或 `changed_bytes`。

## 核心完成门槛

仍未满足：没有同一真实 EPT 运行同时证明 `native_return == 0x1` 与 `changed_bytes > 0`，也没有 RC06 或 caller `+0x80` 前后缓冲证据。核心分离未完成。

## 下一条最小区分变量

保持 H13 全部条件不变，只增加 `0x143f5164d` 与直接跳转目标 `0x143e47a9f` marker，确认第三段 dispatcher 是否继续进入可识别的状态转换边界；不对高地址 dispatcher 写补丁。

本轮结论：**第二段 `0x143ca323e → 0x143a69b86 → 0x143c3b39e` 已被真实动态命中两轮，并出现可重复的寄存器状态转换；核心解码与分离仍未完成。**