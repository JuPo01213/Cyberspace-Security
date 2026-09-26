# C94：合成设备参数传播与用户态 I/O 边界（2026-09-21）

## 结论

本轮只验证 `RC00` 调用点到 Windows 设备 I/O 包装层的参数传播，不声称已经取得真实驱动响应或完成本地解码。结果为：`RC00` callsite 注入的合成 `session=0x1234`、`control=0x222000` 在目标 `0x141757acd` 入口可见，并继续到达 `kernel32!DeviceIoControl`、`kernelbase!DeviceIoControl` 和 `ntdll!NtDeviceIoControlFile`。由于 `0x1234` 是无效句柄，调用返回长度为 0，0x11c 字节缓冲区逐字节未改写；这不是业务层的 `decode_failed` 证据。

状态：`PARTIAL / DEVICE_ARGUMENT_PROPAGATION_CONFIRMED`。

## 范围与安全边界

- 只启动 `Hardware.exe` 的 direct local caller seam；不启动 `auto_decode.pyc`，不连接网络，不等待 TCP。
- 使用 `qoder-clean-20260920` 快照；运行器以 8 秒核心阶段上限执行，结束后恢复到 `saved / qoder-clean-20260920 / nic1=nat`。
- `PatchSyntheticDeviceArgs` 只替换 RC00 callsite 继续执行前的 RCX/RDX，未修改 `0x14078ce60`、`0x14078cd70`、`0x14078d900` 或 `0x141757acd` 的原始字节。
- 合成值不是样本自然会话，也不是有效 IOCTL；本轮不会把它们当成真实协议字段。

## 静态前提

全量数据区扫描修正了早先只扫描 `.text`/运行时 `.Sq>` 的范围限制：

- `stream_rdatafront.bin` 的 VA `0x1407ea374` 存在 `\\.\HP_WKS_SWTOOLS_DRIVER` 设备路径。
- `stream_rdata.bin`/`RG2_region_0x140e00000.bin` 的 VA `0x140f8cba0` 存在 `HP_WKS_SWTOOLS_DRIVER.sys helper`；C6 锚点记录了 `FUN_1407890d0` 对该字符串的引用。
- `stream_rdata.bin` 同时包含 `CI00`–`CI20` 授权/通信阶段字符串和 `RC00`–`RC06` 请求/响应阶段字符串。它们是定位和排除外层闸门的证据，不等于目标设备协议已经恢复。
- 外层 PE 的静态导入中可见 `LoadLibraryA`/`GetProcAddress` 等动态解析入口；没有静态导入 `DeviceIoControl`、`CreateFileW`、`NtDeviceIoControlFile` 或 `NtCreateFile`。因此 API 名称来自运行时解析和动态断点，而非导入表猜测。

## 动态运行

运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`

运行器 SHA-256：

```text
fcc8244d162d5319f7bd191fa5562ab0863b493d74fed42c59da0c88f38a0c32
```

核心命令参数为：

```text
-NativeStartup -DirectLocalCaller -ContinuePastLocalHelpers -ReplayRuntime
-TraceWinApis -PatchSyntheticDeviceArgs
-SyntheticSession 4660 -SyntheticControl 2236416 -TimeoutMs 8000
```

关键日志（`core_direct_local_caller_20260921J/out/debug_core_call.log`）：

```text
phase=rc00_callsite_hit rcx=0x0 rdx=0x0 r8=0x14f058 r9=0x11c
phase=patch_synthetic_device_args session=0x1234 control=0x222000
phase=target_entry_hit rcx=0x1234 rdx=0x222000 r8=0x14f058 r9=0x11c
phase=winapi_entry label=kernel32.dll!DeviceIoControl rcx=0x1234 rdx=0x222000 r8=0x14f058 r9=0x11c
phase=winapi_entry label=kernelbase.dll!DeviceIoControl rcx=0x1234 rdx=0x222000 r8=0x14f058 r9=0x11c
phase=winapi_entry label=ntdll.dll!NtDeviceIoControlFile rcx=0x1234 rdx=0x0 r8=0x0 r9=0x0
phase=direct_caller_post_target output_length=0x0
phase=direct_caller_return kind=local rax=0x0
```

在 `NtDeviceIoControlFile` 的栈参数中，低 32 位可见 `control=0x222000` 和 `length=0x11c`；`RCX=0x1234` 继续作为句柄传播。中间出现的 `0x80000003` 异常来自无效合成句柄/路径，不是业务返回码。

## 输入、输出与副作用

- 目标入口和 caller 返回时的 buffer 都是 284 bytes（`0x11c`），SHA-256 均为 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`，差异字节数为 0。
- buffer 前 16 bytes 仍是 C90/C92 已复现的 state 输出，后 268 bytes 仍是 local transform 输出；本轮没有新增本地解码结果。
- 返回长度 8 字节为 0；caller 返回 `RAX=0`。在无效句柄条件下，这只表示该合成 I/O 请求没有得到有效设备输出。
- 本轮未观察到新的文件、注册表、设备服务或驱动文件副作用。

原始材料哈希：

```text
debug_core_call.log                       d53feafb63c90ce69ec784d01ceceef8bf1ed8d9f173d91975310d47968bacc3
target_input_at_entry.bin                 bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8
target_input_output_at_caller_return.bin  bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8
local_transform_output.bin                6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3
local_state_output.bin                    c096ea2d01af2cb1574fb9539a7a9221632bf804ce260abd044991b2ac6de558
```

## 对核心目标的影响

C94 关闭了此前“`0x141757acd` 是否只是类似 DeviceIoControl 的调用形状”这一不确定性，并确认了合成调用参数从 RC00 seam 到 ntdll 包装层的传播。它没有关闭以下关键缺口：

- 自然 `-n/-m` 输入如何生成 session、句柄和真实 IOCTL；
- `HP_WKS_SWTOOLS_DRIVER` 或辅助组件的实际字节、加载方式和设备响应；
- 有效设备会话下的返回 buffer、RC03 结果和最终本地业务变换；
- 文件、注册表、设备或其他本地副作用。

所以当前仍不能交付“脱离授权/联网即可运行的最终解码核心”。现有可独立运行的三个 harness 只覆盖请求侧变换、状态构造和响应校验；`0x141757acd` 之后仍是需要真实设备/辅助组件证据才能闭合的边界。
