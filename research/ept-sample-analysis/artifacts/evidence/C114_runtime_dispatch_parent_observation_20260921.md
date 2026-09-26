# C114：父进程 runtime dispatch 短窗观测（2026-09-21）

## 状态

`PARTIAL / VALID_RUNTIME_DISPATCH_OBSERVED / CHILD_CORE_NOT_REACHED`

## 目的

在不启动 `auto_decode.pyc`、不联网、不修改本地 helper/RC00/RC03/RC06 的条件下，确认真实 PE 入口之后的高地址打包/runtime dispatch 是否会重复进入，以及它是否在本轮直接转入自然 `main`、`-n/-m` 或核心候选点。该轮把单点授权 bypass 仅作为 child 创建事件中的候选动作；只有出现 `AUTH_GATE_PATCHED` 才算 bypass 实际生效。

## 输入与边界

- 样本：`<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`
- SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- 快照：`qoder-clean-20260920`
- 运行期网卡：`null`；实验后恢复为 `nat`
- 命令行：`Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 0 -m 1`
- 调试器：Microsoft CDB `10.0.29617.1000 AMD64`
- 墙钟上限：`12 s`；超时动作：杀死 CDB 调试树，离线收割，恢复快照
- 观测点：`0x14235f67b`、`0x143c17fb0`、`0x143c3deae`、`main=0x1407a4b90`、`-n=0x1407a55ae`、`-m=0x1407a561a`、`0x14078f250/0x14078f060/0x14078ee73/0x141757acd`

## 直接观察

原始 CDB 输出中的有效 marker（按整行计数，排除了命令文件回显）：

- `PARENT_PE_ENTRY`：1 次；`RIP=0x14235f67b`。
- `PARENT_FIRST_CALL`：2 次。
- `PARENT_DISPATCH_TARGET`：2 次。
- `PARENT_MAIN`、`PARENT_N_PARSE`、`PARENT_M_PARSE`：0 次。
- `AUTH_GATE_PATCHED`、`CHILD_BPS_ARMED`：0 次。
- `0x14078f250`、`0x14078f060`、`0x14078ee73`、`0x141757acd`：无断点命中记录。

两次真实高地址 dispatch 的寄存器现场为：

```text
FIRST_CALL #1 / DISPATCH #1
  RCX=0x7e4  RDX=0x9dc70  R8=0x7e4  R9=0x1521b0

FIRST_CALL #2 / DISPATCH #2
  RCX=0x87f  RDX=0x9d730  R8=0x87f  R9=0x1521b0
```

运行元数据为 `timed_out=True / exit=TIMEOUT_KILLED`。CDB 输出、命令文件和元数据均已收割；没有把超时本身当作样本结果。

## 解释边界

这轮直接证明父进程从真实 PE 入口进入高地址 runtime dispatch，并在 12 秒窗口内至少重复两次；两次 `RCX/R8` 与 `RDX` 均变化。它把“入口后 dispatch 只观察过一次”的状态提升为“短窗口内有重复、参数变化的父进程 dispatch 现场”。

这轮**没有**证明 `RCX/R8` 是 `-n` 或 `-m` 数值，也没有证明 dispatch 已进入自然 `main`、`-n/-m`、F250、RC00 或设备路径。`AUTH_GATE_PATCHED=0` 和 `CHILD_BPS_ARMED=0` 说明本轮没有观察到 child 创建事件，因此 C112 的单点 bypass 在本轮并未实际应用；不能把本轮写成“bypass 后核心未到达”。

状态仍为 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`。真实 child 核心路径、有效 `DeviceIoControl` response、自然 `-m` 后续、RC03/RC06 和驱动副作用仍未闭合。

## 产物与哈希

- 原始输出：`artifacts/captures/natural_dispatch_runtime_bypass_20260921v2/cdb_stdout.txt`，6129 bytes，SHA-256=`6FB9AB4560F3C852CA2C236DACA7E480413AED257A3F36E4C7DCCA43BCAE156F`
- CDB 命令：`artifacts/captures/natural_dispatch_runtime_bypass_20260921v2/probe.cdb`，759 bytes，SHA-256=`6C633C8F33B104ABE8F5FB7E59191063F7A104667DABB0B5D1A8F5D08948F158`
- 运行元数据：`artifacts/captures/natural_dispatch_runtime_bypass_20260921v2/run_meta.txt`，330 bytes，SHA-256=`4B0F3DBA4123EDA4078E2B46AC29FB06E53480C1F78A6A498AD3DCF344055DCD`

## 清理

实验结束后已验证：VM=`saved`，快照=`qoder-clean-20260920`，`nic1=nat`。
