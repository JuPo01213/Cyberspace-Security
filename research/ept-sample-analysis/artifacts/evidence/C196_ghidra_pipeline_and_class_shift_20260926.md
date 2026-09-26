# C196 · Ghidra 反编译管线打通 + 结果类漂移假设证伪

日期：2026-09-26 · 运行：EPT-AUTHGATE-20260925-81（restore 后首轮即秒死）· 工具：Ghidra 12.1.4 headless（ghidra-mcp-workbench 流程）

## 1. Ghidra 管线（正交付）

- 载入：`text_runtime.bin`（1,769,472B，运行时转储 0x140100000-0x1402B0000）以 BinaryLoader raw @0x140100000 x86:LE:64 导入，项目 `artifacts/agent/ghidra/ept-proto-1029/`
- postScript：`DecompileTargets2.java`（主动 disassemble + createFunction + DecompInterface 反编译）
- 输出：`decompile_out2.txt`（349 行可读 C）——5 个目标 handler 全部成功反编译
- 关键确认：**日志器签名** `0x1405d5f80(flag, edx=type, r8=消息串指针, r9=&帧缓冲, stack=event_id)`；状态消息串指针：0x141035980(after_len,0x361e)、0x141036a90(after_body,0x222f)、0x141037010(0xf3c)、0x141036d90——位于 0x14103xxxx 区（当前 dump 外，已登记待转储）
- 不透明谓词的全局源定位：0x14116c6c4 / 0x14116c6c8（布尔迷宫的随机源）

## 2. 结果类漂移假设证伪（重要阴性）

假设："完整/快线类只出现在 VM 低 uptime 窗口，恢复检查点可重置"。实验：RESTORE_VERIFIED（spool79/81 消失=真恢复）后首圈 → **仍然秒死**。

⇒ 结果类与 VM 恢复状态无关，与 uptime 累积无关。自 run 60（19:38 完整线）后 15+ 轮无完整线，跨 4 次恢复。剩余解释：①保护壳按**真实时间/环境指纹**的长期随机化或时 bomb 行为；②宿主侧某个我们未登记的持续变量。该谜题本身登记为观察项，不再阻塞主线（离线 Ghidra 路线不受轮盘影响）。

## 3. 下一阶段（纯离线，不受轮盘影响）

1. Ghidra 反编译 0x14014731C 后继状态链（沿事件 ID 0xf3c→0x7858/0x675f 的派遣解析，需补 dump 0x140FA1C00-CE8 表项区间——已在 proto_tables 范围内）
2. 日志消息串区（0x141030000-0x14104000）转储 → 状态标签明文化（若加密则按 C63 文案池方法解）
3. 从反编译中定位 103B 体解密例程 → 响应构造 → FATAL 验证 → payload 物质化 → seam

## 4. 台账

`target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）。
Ghidra 项目：`artifacts/agent/ghidra/ept-proto-1029/`（输入 text_runtime.bin SHA-256 见 C193 转储来源；postScript 与输出已入库）。
