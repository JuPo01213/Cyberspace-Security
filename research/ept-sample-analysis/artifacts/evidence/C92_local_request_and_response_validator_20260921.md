# C92：本地请求块与响应校验边界

日期：2026-09-21  
状态：`PARTIAL / REQUEST_AND_VALIDATION_BOUNDARY_CLOSED`

## 结论

C91 的 0x11c-byte caller buffer 已被拆成两个可复核的本地产物，而不是一个仍未知的“解码输出”：

- 前 16 bytes 是 `0x14078d900` 写出的本地状态块；
- 后 268 bytes 是 `0x14078ce60` 原地变换后的连续数据；
- RC00 随后把同一个 0x11c-byte buffer 同时作为输入和输出候选传给捕获范围外的 `0x141757acd`；
- `0x14078db80` 对这块 buffer 重新计算本地摘要并验证状态/marker，离线复现返回 `RAX=1`；
- 全零负对照返回 `RAX=0`，证明 validator 的正结果不是固定返回值。

因此，当前已恢复用户态 `.text` 中可以确认的职责是：**构造请求/状态块，并在后续对状态/响应做完整性校验**。它不是已经观察到的最终业务明文输出。最终业务变换仍位于 `0x141757acd` 之后的保护运行时、辅助组件或设备/驱动边界；本报告不把其中任何一个候选升级成已确认 API。

## 缓冲区分解

输入文件：`<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921H\out\target_input_at_entry.bin`。

```text
target buffer (284 bytes / 0x11c)
├─ [0x000, 0x010)  a47b1c4e030ca1e4bcdbae01f044cf60
│                  = local_state_output.bin，16 bytes，逐字节相同
└─ [0x010, 0x11c)  268 bytes
                   = local_transform_output.bin，逐字节相同
```

哈希证据：

- target buffer SHA-256：`bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`；
- target buffer 的后 268 bytes SHA-256：`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`；
- `local_state_output.bin`：`a47b1c4e030ca1e4bcdbae01f044cf60`；
- `local_transform_output.bin`：SHA-256 `6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`。

这把 C90 的两个局部 harness 与 C91 的真实目标入口快照连成了同一条数据流；它们不再只是两个相互独立的 synthetic 中间结果。

## 目标调用契约

`0x14078ee30..0x14078ee78` 的静态字节设置出如下 Windows x64 调用形状（以下栈偏移按目标函数入口的 `RSP` 计）：

```text
RCX              = RSI              ; session/handle-like value
RDX              = EBP              ; control-code-like value
R8               = caller buffer    ; input buffer
R9               = 0x11c            ; input length
[RSP+0x28]       = same buffer      ; output buffer candidate
[RSP+0x30]       = 0x11c            ; output length candidate
[RSP+0x38]       = RSP+0x40         ; bytes-returned candidate
[RSP+0x40]       = 0
```

这与 `DeviceIoControl` 一类的 8 参数 in/out 调用约定相似，且 C91 动态入口观测到 `R8=0x14f058`、`R9=0x11c`，同一地址也出现在输出候选槽。当前没有足够证据确认 `0x141757acd` 本身就是 `DeviceIoControl` 或某个特定驱动入口；准确表述是“保护运行时/设备辅助边界候选”。

在 C91 的 synthetic seam 中，`RCX=0`、`RDX=0`。目标返回后 caller buffer 未变化，caller 返回 `RAX=0`；这只能作为空 session/control 前提下的边界观察，不能代表有效设备会话的业务结果。

## RC03 validator 离线复现

研究入口：`<HOST_PATH>\vmctl\local_response_validator_harness.py`。它映射原始恢复 `.text`，直接执行 `0x14078db80` 和其内部的 `0x14078cd70`，不启动样本、不联网、不加载授权、设备或驱动；唯一的隔离写入是 4-byte marker。

真实 C91 buffer 的结果：

```text
validator       = 0x14078db80
text_sha256     = 5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757
state_sha256    = bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8
RAX             = 0x00000001
marker          = 0x13579bdf
return tail     = 0x14078de3c
```

全零 0x11c-byte state 的负对照返回 `RAX=0`、marker 保持 0、走 `0x14078de4b` return tail。研究入口已补充 `--self-test` 模式，避免把固定常数或未执行路径误判为验证成功。

## 证据与复现

- C91 原始目录：`<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921H\out\`；
- C91 `target_input_at_entry.bin` 与 `target_input_output_at_caller_return.bin`：284 bytes，逐字节相同；
- C91 `debug_core_call.log`：记录 RC00 callsite、目标入口、空 synthetic 参数和 caller `RAX=0`；
- C90 `local_transform_harness.py`、`local_state_harness.py`：复现前两段本地计算；
- C92 harness：`<HOST_PATH>\vmctl\local_response_validator_harness.py`；
- C92 正例报告：`<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921H\out\response_validator_report.json`；
- C92 marker：`<HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921H\out\response_validator_marker.bin`。

复现命令：

```powershell
py -3.13 -m py_compile <HOST_PATH>\vmctl\local_response_validator_harness.py
py -3.13 <HOST_PATH>\vmctl\local_response_validator_harness.py `
  --text <HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin `
  --state <HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921H\out\target_input_at_entry.bin
py -3.13 <HOST_PATH>\vmctl\local_response_validator_harness.py `
  --text <HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin --self-test
```

## 边界与未决项

C92 关闭的是“本地 helper 输出如何组成 RC00 buffer，以及 RC03 是否只是候选字符串锚点”的疑问；它没有关闭：

- 有效 session/control 值如何产生；
- `0x141757acd` 的保护运行时内部是否调用设备/驱动，或先做用户态辅助变换；
- 有效会话下是否改写同一 in/out buffer；
- 驱动/辅助组件字节和最终业务明文、副作用；
- 自然 `-n/-m` 路径到 `0x14078f060` 的完整连接。

当前正确结论仍是：**本地请求构造与响应/状态校验已经独立、动态、逐字节复现；最终业务解码核心不在已确认的这段用户态 helper 链中，外部边界和有效会话仍是实质未决项。**
