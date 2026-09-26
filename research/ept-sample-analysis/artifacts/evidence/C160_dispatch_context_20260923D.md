# C160：实际 dispatcher 上下文与控制流边界（2026-09-23）

## 结论

状态：**PARTIAL / DISPATCHER_INSTRUCTIONS_CONFIRMED / DISPATCHER_CHAIN_OBSERVED / F060_RC03_NOT_REACHED / WAIT_TIMEOUT**。

本轮只观测，不写入机器码。CDB 在目标 Hardware.exe 中命中四个 dispatcher，并记录 RIP、寄存器和现场反汇编：

1. 0x143c17fb0：jmp Hardware+0x3c3deae
2. 0x143c3deae：jmp Hardware+0x3c30e27
3. 0x143c30e27：设置寄存器/栈值后 jmp Hardware+0x3deac60
4. 0x143deac60：压入 r14、rcx 后 jmp Hardware+0x3c17251

因此此前 C157/C158 的四个 dispatcher marker 对应真实执行的 PE 指令，不是字符串或命令回显。C160 的 dispatcher 事件发生在同一 CDB 启动的目标进程中。但本轮没有命中 F060（0x14078f060）或 RC03 validator（0x14078db80），没有 native_return、changed_bytes、caller +0x80 缓冲，也没有证明授权导致目标机器码修改。此处观测到的是 dispatcher 跳转链，不是授权结果。

## 运行身份与通信

| 项 | 值 |
|---|---|
| run id | EPT_RC00_DISPATCH_CONTEXT_20260923D |
| VM | <OTHER_VM_LABEL>，UUID 8d0b85c0-ed29-47c7-9fe1-21bc706a057a |
| 快照 | qoder-armed-20260919，UUID ad2c4f36-3640-432e-8ac8-39a7ecb15b39 |
| CDB 启动的目标 | C:\ept_core\Hardware.exe |
| 样本 SHA-256 PRE/POST | CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7 |
| CDB SHA-256 | 5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67 |
| runner 状态 | WAIT_TIMEOUT，deadline 120 秒，CDB exit code 未取得 |
| E: 空间 | 启动前约 272.39 GiB；收割时约 271.79 GiB |
| VM/GuestControl 收尾 | VM 为 running、当前快照未变；收尾 GuestControl 探针返回 current status is: starting，分类为控制面未就绪，不是目标结果 |

实验在用户授权的 <OTHER_VM_LABEL> VM 中执行。runner.log、run.cdb、cdb.log、run_meta.json、pre_state.json、post_state.json 经共享目录数据面产生。CDB 命令行中的输入已在日志保存前替换为 [REDACTED]；摘要不记录输入原文。

## CDB 原始输出

原始日志：<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_CONTEXT_20260923D\cdb.log。独立运行输出行及对应上下文：

| CDB 日志行 | Marker | RIP | 现场第一条指令 |
|---:|---|---|---|
| 78 | [C160_D1] | 0x143c17fb0 | e9f95e0200 jmp 0x143c3deae |
| 104 | [C160_D2] | 0x143c3deae | e9742fffff jmp 0x143c30e27 |
| 130 | [C160_D3] | 0x143c30e27 | 68bde40542 push 4205E4BDh |
| 156 | [C160_D4] | 0x143deac60 | 4156 push r14，随后 jmp 0x143c17251 |

C160_D3 后续还显示 mov [rsp],rcx、修改 ecx、压入 rax/r11 并跳到 D4。D4 的 r15=0x140000000，与 Hardware.exe 基址相符；D1–D4 的 u @rip 输出均将地址命名为 Hardware+RVA。

原脚本在每个动作里执行 !address @rip。CDB 环境输出 No export address found 和 LoadLibrary(ext) failed，因此没有有效的 !address 页面保护/区域信息。不能据此推断页面保护属性，也不能把扩展命令错误误记为目标异常。后续若需页保护，改用可在 Guest 内成功验证的 VirtualQuery 查询或正确配置的调试器扩展。

CDB 日志还含 [C160_ENTRY]、Hardware 映像范围 0x140000000..0x143f83000。此为模块范围证据，不自动等于整段均属同一可执行节。

## Metadata parser 缺陷

runner 最终写入 run_meta.markers 为空对象，尽管 cdb.log 中有上述独立 marker 行。这表示 runner 的 marker 序列化/筛选路径仍不可靠。C160 marker 是否命中以原始 cdb.log 中的独立输出行为准；不要以 run_meta.markers 的空对象否定 CDB 现场，也不要以 marker 数量字段代替原始证据。

## 与 C152/C156–C159 的关系

- C152（宿主 harness）：真实样本映射副本上的伪造响应使 native_return == 0x1、结构变化 34 字节。它证明授权判断机制可被受控输入通过，但不是 Guest 目标进程的业务闭环。
- C156/C157：对 0x14078eea2、0x14078ef10 的写后读回值虽变成 EB 5E、EB 30，入口现场原始字节为 00 00，不能算目标业务指令补丁。
- C158：确认上述候选 RVA 在入口现场为全零，反汇编成 add byte ptr [rax],al；本轮没有盲写。
- C160：确认此前观察到的四个 dispatcher 确实是执行指令并组成多跳链；但未命中 F060/RC03，没给出通向授权业务接缝的因果链。

## 下一项最小动作

1. 保留 C152 已证实的响应头判据和 C160 的真实 dispatcher 现场，不重做宿主 harness。
2. 从 C160_D4 的真实跳转目标 0x143c17251 起，在短 deadline 内追加少量下一跳/返回边观测，避免重建已经看到的 D1–D4 marker 集合。
3. 同时在 guest 侧用轻量 VirtualQuery 读取 0x143c17251、0x14078f060、0x14078db80 对应区域的 AllocationBase、State、Protect，按 PID 对齐；避免 !address 扩展失败重演。
4. 只有找到确实含预期授权分支字节的可执行映像区域后，才讨论该位置的 VM 补丁验证；同一真实运行仍须满足 native_return == 0x1、changed_bytes > 0，并保存 caller +0x80 缓冲。
5. 追踪部署/伪装/清理时，将自然部署观察与 CDB 调试运行分开；通过有时限、限量的 ETW/ProcMon记录 writer PID、父子进程和文件路径/时刻，再与同一 run id 的 PRE/POST 对齐。

## 可复核材料

- runner：<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_CONTEXT_20260923D.ps1
- 原始运行目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_CONTEXT_20260923D\
- 原始文件：runner.log、run.cdb、cdb.log、run_meta.json、pre_state.json、post_state.json
- C158 证据：artifacts/evidence/C159_c158_module_codepage_observe_20260923.md
- 通信操作手册：method/COMMUNICATION_PLAYBOOK.md
