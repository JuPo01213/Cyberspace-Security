# C91：RC00 之后边界的有界命中与缓冲区判别

日期：2026-09-21  
状态：`PARTIAL / POST_TARGET_BOUNDARY_OBSERVED`

## 结论

在不启动 `auto_decode.pyc`、不连接网络、不经过自然授权路径的直接 caller seam 中，`0x14078f060` 已实际执行到 RC00 的捕获范围外目标 `0x141757acd`。本轮没有继续解释或执行该保护运行时，而是在目标入口立即采样并让调用返回。

已观察到：

- `0x14078ce60`、`0x14078cd70`、`0x14078d900` 的本地链再次命中；
- RC00 callsite 的真实寄存器契约为 `RCX=0`、`RDX=0`、`R8=0x14f058`、`R9=0x11c`（本 seam 的 session/control synthetic 值为空）；
- 两条短臂的 `0x141757acd` 入口分别在约 0.7–1.6 秒内命中；入口 `R8=0x14f058`，对应 0x11c-byte caller buffer；
- 入口采样的 0x11c 字节与 caller 返回时同一缓冲区逐字节相同，SHA-256 均为 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`，差异字节数为 0；
- 直接 caller 随后返回 `RAX=0`。这不是最终业务成功，也不是“解码失败”；它只说明在空 session/control synthetic 前提下，该捕获外目标没有改写这块缓冲区。

因此，C91 把“本地变换/状态构造”与“捕获范围外辅助/设备候选边界”分开了，但仍没有把 `0x141757acd` 的保护语义、有效 session 下的返回契约、RC03 validator 或自然 `-n/-m` 输入路径闭合。

## 实验边界

- 客体快照：`qoder-clean-20260920`；结束时已恢复为 `VMState=saved`、`nic1=nat`；
- 样本阶段网卡 cable 为 off；临时 NAT 仅用于样本未启动时投递脚本和页面，投递后即断链；
- 恢复静态 `.text`：8,257,536 bytes，SHA-256 `5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`；
- 恢复运行时 `.Sq>`：15,622,144 bytes、3814/3814 页，SHA-256 `1daf7ec28a09b43eb456f2027bcbaeb047aafab6b1a290ce14edc9cce761d1d4`；
- 调试器 wall-clock 上限：8 s；实际目标入口和 caller 返回均在启动后约 0.7–1.6 s 内发生；
- 未读取或使用嵌入授权 token `0x140f92550`，未启动外层 Python 壳。

## 调用与数据流

```text
0x14078f060
    ├─ 0x14078ce60  原地变换：0x10c bytes
    ├─ 0x14078d900  写出 16-byte state
    │    └─ 0x14078cd70  连续消费 0x10c bytes，真实返回 0x2567c4e5
    └─ 0x141757acd  捕获范围外运行时目标
         └─ 返回到 caller continuation；本轮 synthetic 空 session 下 buffer 不变
```

目标入口前，RC00 的 stack 参数快照包含：

```text
[rsp+0x28] = 0x14f058   ; 0x11c-byte in/out buffer
[rsp+0x30] = 0x11c      ; length
[rsp+0x38] = 0x14f048   ; caller-local result/length slot candidate
[rsp+0x40] = 0
[rsp+0x48] = 0
```

这里的 `[rsp+0x38]` 只是调用契约中的候选输出槽；本轮读取到的 `0x7ffb00000000` 不符合可信长度，不能当作业务结果解释。

## 证据

原始目录：`<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921H\out\`；首条复核臂材料在 `<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921G\out\`。

- `debug_core_call.log`：SHA-256 `4b2e03b42f76b3e15d621020aab69de46080b56eb0c2e92f119660294e9d4553`；
- `local_transform_output.bin`：SHA-256 `6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`；
- `local_state_output.bin`：SHA-256 `c096ea2d01af2cb1574fb9539a7a9221632bf804ce260abd044991b2ac6de558`；
- `target_input_at_entry.bin`：284 bytes，SHA-256 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`；
- `target_input_output_at_caller_return.bin`：284 bytes，SHA-256 同上；
- `target_output_length_at_caller_return.bin`：8 bytes，SHA-256 `0eff603ed3b868e70b16373e387c106c222b54cac2bc10fe212de024aa96ff31`；
- 更新后的有界调试器：`<HOST_PATH>\vmctl\debug_core_call.ps1`，SHA-256 `68a2764ef007b9354f6dc3b2f844412f299eea397858281339a06a88c07cb5ee`。

## 状态与未决项

C91 不是最终核心完成标志。仍未确认：

- `0x141757acd` 在有效 session/control code 下是用户态辅助变换、设备/驱动调用，还是两者的包装；
- 有效 session 下是否会改写同一 0x11c buffer，以及返回值如何进入 `0x14078db80` / `RC03 decode_failed`；
- 自然 `-n/-m` 选项如何到达 `0x14078f060` 逻辑块；
- 驱动/辅助组件字节和最终本地副作用。

当前正确表述仍是：**本地 helper 链已动态闭合并可离线逐字节复现；post-target 边界已命中，但最终业务解码语义和外部组件边界仍未闭合。**
