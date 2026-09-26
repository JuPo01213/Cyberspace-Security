# C117：`RUN apply soft_success` 直接 xref 有界阴性（2026-09-21）

## 目的

判断 `RUN apply soft_success` 是否在当前已恢复 genB `.text` 中存在可直接追踪的 RIP-relative 数据引用，并用已知 `RC00/RC03/RC04/RC06` 字符串作为同一扫描的控制位。该检查只回答“当前恢复 `.text` 的直接数据引用”，不把字符串命中升级为调用链，也不排除运行时算址、间接引用或未捕获代码。

## 输入与工具

- 输入：`<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin`
- 大小：`8,257,536` bytes
- SHA-256：`5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757`
- 映射：`VA = 0x140000000 + stream_offset`
- 工具：Python 3.13 + Capstone `5.0.7`
- 扫描方式：Capstone x64 `skipdata=True`，连续遍历整个输入；对每条解码指令检查 RIP-relative memory operand，计算 `target = instruction_va + instruction_size + disp32`
- 覆盖统计：`2,004,141` 条指令；`11,973` 个 skip-data 单元；输入范围全部遍历

## 结果

| 字符串目标 | VA | 直接 RIP-relative xref 数 |
|---|---:|---:|
| `RUN apply soft_success` | `0x140f93570` | **0** |
| `RC00 send` | `0x140f8d7b0` | 1，`0x14078ed97` |
| `RC03 decode_failed` | `0x140f8d870` | 1，`0x14078eec2` |
| `RC04 session_mismatch` | `0x140f8d8d0` | 1，`0x14078ef2b` |
| `RC06 success` | `0x140f8d940` | 1，`0x14078efd1` |

控制命中示例：

```text
0x14078ed97: lea rcx, [rip + 0x7fea12] -> 0x140f8d7b0
0x14078eec2: lea rcx, [rip + 0x7fe9a7] -> 0x140f8d870
0x14078ef2b: lea rcx, [rip + 0x7fe99e] -> 0x140f8d8d0
0x14078efd1: lea rcx, [rip + 0x7fe968] -> 0x140f8d940
```

## 机器输出

可复核 JSON：`artifacts/evidence/C117a_soft_success_direct_xref_scan_20260921.json`，大小 1822 bytes，SHA-256=`9BAA773D26D1A30F0B4A2BE947E4244526E3612D5EE43F45CAD132E4EEECDD65`。

## 解释边界

在当前 8,257,536-byte 恢复 `.text` 内，`RUN apply soft_success` 没有与 RC00/RC03/RC04/RC06 同类的直接 RIP-relative 数据引用；因此不能从这份 `.text` 直接建立 `RUN apply soft_success → RC00/RC03/RC06` 的静态调用链。

这不是全局不存在结论。仍未排除：运行时解密后的代码、寄存器/绝对地址间接引用、保护运行时生成的日志参数、外层/其他模块代码以及未捕获页面。C117 只把该主张的当前静态范围固定为 `VALID_BOUNDED_NEGATIVE / NO_DIRECT_RIP_XREF_IN_RECOVERED_TEXT`，不能替代真实自然路径动态命中。

## 当前影响

C117 加强了排除边界：`RUN apply soft_success` 的字符串所在数据页已知，但在恢复 `.text` 中没有直接引用；C114 的父进程 runtime dispatch 观察仍是当前最接近该未决连接的新动态证据。自然 `-m`、有效 response、RC03/RC06 和驱动副作用仍未闭合。
