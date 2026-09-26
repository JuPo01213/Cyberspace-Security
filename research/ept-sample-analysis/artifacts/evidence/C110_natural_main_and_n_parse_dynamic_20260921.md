# C110：genB 自然 `main` 与 `-n` 参数解析动态边界

## 目的

C100/C107 只证明了 `-n/-m` 字符串、解析器窗口和本地 caller seam 在静态侧彼此没有可靠直接边；C109 又确认真实样本会产生临时 `EPT_*.exe` 子进程。因此本轮只补一个高信息价值问题：自然启动是否真正进入 genB 的 `main`，以及 `-n` 是否在真实子进程中进入已定位的十进制解析调用点。

本轮不启动 `auto_decode.pyc`，不连接网络，不伪造授权或设备响应，也不把参数解析命中当作本地解码完成。

## 输入与环境

- 样本：`<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`
- SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- 大小：`32,671,232` bytes
- 动态快照：`qoder-armed-20260919`
- 运行参数：`C:\ept_core\Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 0 -m 1`
- NIC：`null`
- 调试器：Microsoft CDB `10.0.29617.1000 AMD64`
- 观测方式：`.childdbg 1` 跟随临时子进程；对 `main`、`0x1407a55ae`、`0x14078f250`、RC00 候选点使用硬件执行断点；单次 Guest Control 墙钟上限约 `12 s`。

## 直接观察

### 自然启动命中 `main`

父进程在 `0x1407a4b90` 命中真实硬件执行断点。CDB 同时显示了自然命令行及其参数槽，命令行为：

```text
C:\ept_core\Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 0 -m 1
```

这不是直接调用 `main` 的 harness，也不是从 `.text` 捕获中跳入；它是样本启动后在真实进程地址空间中的自然入口观测。

### 临时子进程命中 `-n` 的真实解析调用点

在跟随的临时子进程 `EPT_1FAA9D16_324B4466.exe` 中，`0x1407a55ae` 命中：

```text
rip=00000001407a55ae
rcx=00000000005a4b5e
rdx=0000000000145fa0
r8 =000000000000000a
rax=0000000000000000
```

静态 C75 已将该点确定为对 `0x1407c0494` 的 strtol-like 调用；其第三个参数 `R8=0xa` 是十进制基数，`RCX` 是待解析字符串，`RDX` 是解析结束位置的输出槽。由于该命中发生在自然临时子进程中，现可将“`-n` 进入真实十进制解析路径”标为 `VERIFIED`，不再沿用 C100 的 `MISSING` 表述。

## 没有观察到的内容

本轮在 `-n` 解析点停止，没有继续执行到：

- `-m` 解析后的完整自然分发；
- `0x14078f250` / `0x14078f060` caller seam；
- RC00 后的 `0x141757acd` 或有效设备响应；
- RC03、RC04、RC06 的自然输入；
- 本地文件、注册表、设备或驱动副作用。

因此 `-m` 到核心、自然参数到 `F250/RC00` 的连接，以及真实 response producer 仍未闭合。没有继续无界等待：命中第一个关键自然路径目标后即停止本轮。

## 解释边界

本轮新增的最强结论是：

```text
自然 Hardware.genB.exe 启动
    → 真实 main = 0x1407a4b90
    → 临时 EPT_*.exe 子进程
    → 0x1407a55ae
    → 十进制 -n 解析调用
```

这条证据修正了 C100/C107 的静态边界，但没有证明解析结果继续到本地解码 caller，更没有证明解码成功。`F250/RC00` 未命中属于本轮在第一个目标处主动停止，不是自然路径阴性。

状态：`PARTIAL / NATURAL_N_PARSE_OBSERVED`。

## 清理

实验结束后已执行：

- 关闭 `<OTHER_VM_LABEL>`；
- 恢复快照 `qoder-clean-20260920`；
- 恢复 `nic1=nat`；
- 当前 VM 状态：`saved`。

## 产物

- 原始摘录：`../captures/natural_n_parse_20260921/cdb_nparse_probe.txt`
- 相关静态依据：[`C75_main_cfg_n_m_to_core_20260921.txt`](C75_main_cfg_n_m_to_core_20260921.txt)、[`C100_cli_parameter_path_boundary_20260921.md`](C100_cli_parameter_path_boundary_20260921.md)、[`C109_genb_pe_entry_and_child_debug_boundary_20260921.md`](C109_genb_pe_entry_and_child_debug_boundary_20260921.md)
