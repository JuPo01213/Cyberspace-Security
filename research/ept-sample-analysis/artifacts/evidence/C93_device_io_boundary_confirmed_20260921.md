# C93：`0x141757acd` 的真实设备 I/O 边界

日期：2026-09-21  13:18–13:19
状态：`PARTIAL / DEVICE_IO_BOUNDARY_CONFIRMED`

## 结论

C91/C92 只凭调用形状把 `0x141757acd` 称为“设备/辅助边界候选”。C93 在同一个有界 direct caller seam 中，对系统 API 入口布置一次性断点，实际观察到完整链：

```text
0x141757acd
    → kernel32!DeviceIoControl
    → kernelbase!DeviceIoControl
    → ntdll!NtDeviceIoControlFile
    → 返回 caller
```

因此，`0x141757acd` 的已证实职责不是独立的本地业务 decoder，而是进入 Windows 设备 I/O 路径的保护包装/调用边界。C93 使用的是 synthetic 空会话：`DeviceIoControl` 收到 `RCX=0`、`RDX=0`，所以本轮只证明 API 链和参数传递，不证明有效设备句柄下驱动会返回什么，也没有声称已经进入目标驱动。

## 动态观测

运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`，新增 `-TraceWinApis`；VM 臂上限 8 s，实际从目标入口到 caller 返回约 0.07 s。调试器恢复的静态 `.text` 与运行时 `.Sq>` 输入仍分别是 C91 的同一两份哈希；本轮结束后已立即恢复 `saved / qoder-clean-20260920 / nic1=nat`。

系统 API 断点均在目标入口后命中：

```text
kernel32!DeviceIoControl       0x7ffbe71d58d0  hit
kernelbase!DeviceIoControl     0x7ffbe498dd70  hit
ntdll!NtDeviceIoControlFile    0x7ffbe736d670  hit
```

第一层 `kernel32!DeviceIoControl` 的参数为：

```text
RCX = 0x0       ; device handle
RDX = 0x0       ; control code
R8  = 0x14f058  ; input buffer
R9  = 0x11c     ; input length
```

入口栈中继续观察到：

```text
[RSP+0x28] = 0x14f058  ; output buffer，与输入相同
[RSP+0x30] = 0x11c     ; output length
[RSP+0x38] = 0x14f048  ; bytes-returned / result-length 槽
[RSP+0x40] = 0
```

这把 C92 的“DeviceIoControl 类 ABI”升级为实际 API 证据。`CreateFileW`、`kernelbase!CreateFileW` 和 `ntdll!NtCreateFile` 断点均未命中，符合本 seam 没有建立有效设备句柄的前提。

## 结果与副作用

- caller buffer 入口和返回时均为 284 bytes，SHA-256 都是 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`，差异字节数为 0；
- `[0x14f048]` 的返回长度为 `0x0`；
- direct caller 返回 `RAX=0`；
- 在本轮 guest 文件/注册表/驱动目录没有被作为结果读取，也没有把空句柄返回升级成业务失败；
- `NtDeviceIoControlFile` 的命中说明请求已进入 ntdll 的系统调用包装层，但 `handle=0`，因此不能据此声称目标驱动已接受或处理请求。

## 与本地数据流的合并

C90–C93 现在形成一条证据完整的数据流：

```text
caller-local 0x10c input
    → 0x14078ce60  原地变换，268 bytes
    → 0x14078d900  写出 16-byte state
    → 0x141757acd
    → DeviceIoControl(handle, control, buffer, 0x11c,
                      buffer, 0x11c, &length, NULL)
    → 0x14078db80  本地状态/响应 validator
```

其中 C92 已证明 validator 对同一 0x11c buffer 的正例返回 `1`、全零负例返回 `0`。C93 则证明中间目标把该 buffer 送入设备 I/O，而不是在已恢复用户态 helper 链中产出最终业务明文。

## 证据

- 原始目录：`<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921I\out\`；
- `debug_core_call.log`：6796 bytes，SHA-256 `f215ad91cac9c3b1868d06d64a4cae76d2daa4589163dcabc3a58eb0c1659af0`；
- `target_input_at_entry.bin` 与返回快照：284 bytes，SHA-256 均为 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`；
- `target_output_length_at_caller_return.bin`：8 bytes，内容 `00 00 00 00 00 00 00 00`，SHA-256 `af5570f5a1810b7af78caf4bc70a660f0df51e42baf91d4de5b2328de0e83dfc`；
- 更新后的运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`，宿主 SHA-256 `6fc437e9722e70981148141d8222d1ef0bf9e25022dfefbc8e0c0d7fca218fb9`；
- 静态运行时范围：`<HOST_PATH>\EPT\artifacts\captures\stream_SQSCAN_20260921A\sq_runtime_range.bin`。

## 尚未闭合的真实问题

C93 关闭了“`0x141757acd` 是不是设备 I/O 边界”的问题，但仍未关闭：

- 有效 session/设备句柄和非零 control code 如何建立；
- 目标驱动或辅助组件的字节、IOCTL 语义和返回数据；
- 有效设备请求是否改写 0x11c buffer，是否存在最终本地明文或文件/注册表副作用；
- 自然 `-n/-m` 参数如何到达同一 caller；
- 在缺少目标 `.sys` 的当前干净基线中，如何获得不伪造结果的有效设备会话。

当前最强、且不越证据的结论是：**已恢复的用户态本地代码不是最终解码器；它构造 0x11c 请求块、调用 DeviceIoControl，并在返回后执行本地状态/响应校验。最终业务变换/结果位于有效设备请求及其缺失的驱动或辅助边界。**
