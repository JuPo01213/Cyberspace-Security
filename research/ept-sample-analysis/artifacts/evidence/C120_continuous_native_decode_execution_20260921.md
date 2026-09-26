# C120：连续 native core runner 实际执行到 RC06 输出（2026-09-21）

## 状态

`PARTIAL / HOST_MAPPED_CODE_RUNNER_WITH_SYNTHETIC_ECHO_RESPONSE / NOT_TARGET_COMPLETION`

## 目标

让恢复的用户态 native seam 在受控输入和 synthetic request-echo response 下连续执行，以收割输入、变换和输出。该轮不调用 `core_local_decode_harness.py` 的 synthetic response 模式，而是调用恢复 `.text` 中的原始 `0x14078f060`；它不是外层 EPT/Hardware 目标进程的自然运行，也不取得自然设备 response。

## 两个受控外部 seam

### 输入准备 seam：`0x1407b4700`

`0x14078f060` 原本先调用该 helper 初始化 0x10c-byte本地输入缓冲区。runner 将该 helper 替换为 tail-call 到宿主 callback，由 callback 把 normalized 268-byte fixture 复制到原始目的地址。这个 seam 只提供受控输入，不改 `0x14078ce60`、`0x14078d900`、`0x14078db80` 或 RC06 copy。

### post-target seam：`0x141757acd`

runner 在该捕获范围外目标处写入 stub。stub 保存 `RCX/RDX/R8/R9` 到 scratch，记录到达标记，然后 `add rsp,8` 去掉 RC00 call 的返回槽，跳到已确认的 RC03 continuation `0x14078ee89`。它不写 response buffer、不改解码函数；这样保留原始 RC03/RC06 代码和栈布局。

受控状态：`HANDLE_GLOBAL=1`、`CONTROL_GLOBAL=0x222000`，六个本地 dword 使用既有 harness 的 synthetic globals。

## 实际 native 命中链

CDB 软件断点在同一 runner 进程内逐项命中，每个 marker 各 1 次（transform 两次）：

```text
0x14078f060       F060_HIT
0x14078ece0       ECE0_HIT
0x14078ce60       TRANSFORM_HIT       # RC00/request side
0x14078d900       STATE_HIT
0x141757acd       TARGET_HIT           # controlled external seam
0x14078ee89       RC03_CONT_HIT
0x14078db80       VALIDATOR_HIT
0x14078ef42       RC06_TRANSFORM_HIT
0x14078ce60       TRANSFORM_HIT       # RC06/response side
```

这证明的是恢复代码段在受控 runner 中连续执行到了 RC06 相关 transform/copy，不是静态字符串命中或独立 Python/helper 自测。但必须限定：post-target stub 没有写入任何 response 数据；RC03 validator 看到的是 RC00 留在同一 0x11c buffer 中的请求块，因此这是 **synthetic request-echo response**，不是目标驱动返回。它不能作为真实 response、自然目标 RC06 或项目完成证据。

## 输入与输出

normalized caller fixture：

- 文件：`artifacts/captures/continuous_core_decode_20260921/cdb_normalized_input.bin`
- 大小：268 bytes
- SHA-256：`4836808424621EE58D80B558898D8ED2EB1227EB51E14C7F0036C072DAD93BDD`
- 结构：保留 `mode=2`、`ocal_probe`、`serialMode=1`；将 C90 原始 fixture 中被 caller 语义消费的 offset `0x08` 字节置零

RC06 第二次 transform 前的 response payload（原始 fixture）：`rc06_payload_before_original.bin`，SHA-256=`B18A22B220E8182377332A5C7F60F31821988BF17C7DB4BFC882A21499CAEAAC`。

RC06 第二次 transform 后实际收割的 payload（基于 synthetic request-echo）：

- 文件：`artifacts/captures/continuous_core_decode_20260921/rc06_payload_after_normalized.bin`
- 大小：268 bytes
- SHA-256：`4836808424621EE58D80B558898D8ED2EB1227EB51E14C7F0036C072DAD93BDD`
- 与 normalized input：**逐字节相等，0 differences**

原始未归一化 C90 fixture 也经过同一连续链；其 RC06 payload 与原始输入仅在 offset `0x08` 相差 1 byte，说明该差异来自 caller structure 字段语义，而不是 transform 逆运算失败。

## 反向分析结果

- 第一次 `0x14078ce60` 是受控 runner 中的 RC00/request-side transform；
- `0x14078d900` 构造 16-byte state；
- controlled target stub 返回后，恢复的 `0x14078db80` validator 执行；
- marker 通过后，`0x14078ef42` 触发第二次 `0x14078ce60`；
- runner 在受控栈/缓冲区条件下执行到 RC06 copy 相关阶段；
- 本轮没有真实目标进程的文件、注册表、网络、驱动或 post-decode 行为证据；唯一外部副作用是 runner 自己的输入提供、stub 跳转和日志落盘。

## 可复现入口

源代码：`<HOST_PATH>\EPT\method\harnesses\core_continuous_runner.cpp`

编译环境：MSVC x64，使用 `/std:c++17 /EHsc /Zi /DEBUG`。CDB 通过 `core_continuous_probe!invoke_caller` 在映射完成后布置软件断点，命令文件和原始日志已归档。

归档目录：`<HOST_PATH>\EPT\artifacts\captures\continuous_core_decode_20260921\`

其中包括 runner source、EXE/PDB、native chain trace、RC06 output capture trace、normalized input 和实际 RC06 payload。

## 仍然未覆盖的边界

C120 证明了“可控输入 + 受控外部返回边界”下的连续 native 用户态解码实际发生，并不等于自然 `Hardware.exe` 已经在真实驱动上成功运行。真实驱动 response、自然 `-n/-m` 到 caller structure 的来源、真实文件/设备副作用仍需单独证明；本轮不把受控 seam 冒充为真实设备行为。
