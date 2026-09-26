# C118：完整 `.Sq>` 范围的 direct-edge 有界扫描（2026-09-21）

## 输入与映射

- 输入：`<HOST_PATH>\EPT\artifacts\captures\stream_SQSCAN_20260921A\sq_runtime_range.bin`
- 范围：`VA 0x141174000..0x14205a000`
- 大小：`15,622,144` bytes
- SHA-256：`1DAF7EC28A09B43EB456F2027BCBAEB047AAFAB6B1A290CE14EDC9CCE761D1D4`
- 映射：`VA = 0x141174000 + stream_offset`

## 方法与控制位

第一列使用原始字节扫描，不依赖反汇编边界：枚举每个 `0xE8`，按 little-endian signed `rel32` 计算 `target = callsite + 5 + rel32`。共发现 `127,855` 个原始 `E8` 候选。

控制位使用 C81 已确认的四条 runtime direct call：

```text
0x141757acf -> 0x1415844d3
0x141757af5 -> 0x1419060e7
0x141757afc -> 0x14171631b
0x141757b15 -> 0x141a93e50
```

四条控制边均命中，说明输入身份和 `E8 rel32` 映射在该范围内有效。

第二列只作辅助：扫描常见 REX + `mov/lea/store` + RIP-relative `mod=00,r/m=101` 字节形态，共发现 846 个模式；它不替代真实指令边界分析。

## 结果

原始 `E8` 扫描对以下目标均为 0 命中：

- `RUN apply soft_success`：`0x140f93570`
- `RC00/RC03/RC04/RC06`：`0x140f8d7b0/0x140f8d870/0x140f8d8d0/0x140f8d940`
- `-n/-m` 字符串：`0x140f92bf7/0x140f92c03`
- caller seam：`0x14078f250/0x14078f060`

常见 RIP-relative 辅助扫描也没有指向这些目标的命中，但由于该列不是基于可信指令边界，不单独作为全局阴性依据。

## 解释边界

在当前已捕获的完整 `.Sq>` 范围内，可以排除“存在一条原始直接 `E8` 边把该范围连接到 `RUN apply soft_success`、RC00/RC03/RC06、F250/F060 或 `-n/-m` 字符串”的具体解释。该结果不能排除寄存器间接调用、绝对地址、运行时生成的代码/表、范围外代码或保护运行时动态解密。

C118 因而加强了运行时页边界，但没有闭合自然 `-m`、真实 response producer、RC03/RC06 或驱动副作用。

## 机器输出

可复核 JSON：`artifacts/evidence/C118_runtime_sq_direct_edge_scan_20260921.json`，大小 2168 bytes，SHA-256=`266CF89EAC111F42E8FDF3BCB87586CE487F5094A1A13CE29B2677609EDEBD1F`。
