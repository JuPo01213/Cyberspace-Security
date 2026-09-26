# C199 · child_full_recv2.dmp 离线分析：minidump 解析器 + 派遣表数据表定性

日期：2026-09-26 · 数据源：`runs/EPT-AUTHGATE-20260925-82/child_full_recv2.dmp`（106,884,210B，recv#2 入口时刻全进程快照，SHA ca0ffcec…）
脚本：`artifacts/evidence/driver_disasm/mdmp_map.py`

## 1. minidump 解析器（可复用工具）

MDMP 头解析 + Memory64ListStream(9) 227 个内存段（106.8MB 映射）→ `read(va, n)` 全地址空间读取器；ThreadListStream(3) → 3 线程上下文（RIP/RSP/RDX/RBP）。
注意：MINIDUMP_HEADER 的 NumberOfStreams 在偏移 8（不是 4）；MINIDUMP_THREAD 结构 48 字节（含 Teb/Stack/Context）。

## 2. 快照时刻进程状态（recv#2 入口）

| 线程 | RIP | RDX | 状态 |
|---|---|---|---|
| TID 532（主） | 0x7ffbb9e41d90（ws2_32!recv 内） | **0x1e0004（103B 响应缓冲）** | recv 入口，缓冲全零（数据未到）✓ |
| TID 1620 | ntdll 等待 | — | 工作线程 |
| TID 5560 | ntdll 等待 | — | 工作线程 |

## 3. 派遣表解算结果

- 表基指针 *(0x140FA18F0) = 0xE97F7B20；idx=5 条目 0x140FA0D98 → handler 0x14014731C（与 C193 一致 ✓）
- **idx=0x7858/0x675f 的条目内容 = 0x15B0000015A / 0x2C40000024B**——非代码指针，是**打包 dword 对**（疑似 (状态号,事件号) 数据表）⇒ 0x7858/0x675f 索引的不是代码派遣表而是数据/元数据表，状态机的代码派遣另有机制

## 4. 下阶段（dmp 离线，无 VM 依赖）

1. 以 0x140FA18F0 表枚举**全部小索引**（0-0x100）的 handler 集合 → 反汇编 cluster → 用日志器调用（0x1405d5f80 + 立即数）标注每个 handler 的事件 ID → 事件-代码对照图
2. 0x140FD0000-0x140FE5000 区域（0x7858/0x675f 条目所在）定性：状态/事件元数据表的完整结构
3. 在 handler cluster 中定位对 103B 缓冲（堆 0x1e0004 块）的变换循环 → 解密例程与密钥
4. 密钥来源候选：dmp 全量内存中搜索与密文体相邻/相关的密钥材料；或状态机代码内的立即数密钥

## 5. 台账

`target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）。
