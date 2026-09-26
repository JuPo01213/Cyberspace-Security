# C198 · 冷重启证伪 + 秒死转储设计（E-2c 捕获的前置闭环）

日期：2026-09-26 · 运行：EPT-AUTHGATE-20260925-82（冷重启后首轮仍秒死，EXIT_SKIP×1）

## 1. 冷重启实验（uptime 假设证伪）

设计：冷重启（Stop-VM+Start-VM，无检查点恢复）重置 OS boot 时间 → uptime 0.1min 全新 boot → 立即跑捕获轮。

结果：仍秒死（EXIT_SKIP×1，无 RECV）。**boot-age/uptime 假设与恢复状态假设一并证伪**。

## 2. 结果类谜题的当前状态（诚实登记）

已证伪的影响因子（每个均为单变量实验）：检查点恢复/污染、uptime/boot-age、父进程 cdb、Temp 同名残留、ntdll/SetEndOfFile SW 断点、磁盘空间、Defender 拦截、日志器进程残留。
未证伪候选：①保护壳按**绝对时间/环境指纹**的长期调度（时间炸弹类）；②宿主侧未登记变量；③样本网络阶段的**外部依赖状态**（yz.hwid001.com 服务端会话状态——服务器侧对同一指纹/卡密的会话计数！卡密 1234567890 在服务器侧的状态随每次连接累积——我们的重连洪泛可能触发了服务器侧的封禁/降级——**但隔离环境无出网，此路径未激活**；若服务器依赖出网，无网状态下所有类应一致——矛盾，弱化）。

## 3. 秒死转储设计（把阻塞变成数据）

秒死轮必然命中 EXIT_PROCESS_SKIPPED（0x143ae5d57 ExitProcess 调用）。在该动作内追加 `.dump /f early_death.dmp`：
- 每个秒死轮产出**死亡瞬间的完整进程转储**——进程的全局状态、堆、栈全部在案
- 分析目标：定位秒死前进程处于什么状态、哪个全局/标志触发了 0x143ae5d57 的退出决策
- 与快线/完整轮的转储对照 → 结果类机制的直接证据

## 4. 台账

`target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）。
本轮运行：冷重启后 1 轮（秒死）。.dump /f 仪器保持就绪（recv#2 与 EXIT_SKIP 两处）。
下阶段：循环执行 → 秒死轮产 early_death.dmp / 非秒死轮产 child_full.dmp → 任一转储都推进协议逆向。

## 5. 追记：自然死亡剖面（同日）

冷重启后一轮出现**新深度剖面**：无 RECV/FATAL/EXIT_SKIP，但加载 SHCORE/windows.storage/Wldp/OLEAUT32（COM/Storage 栈）后死亡——进程在预网络阶段自然终止。harvest 的 cdb 击杀会在进程存活时截断运行——**harvest 前必须等待 procs=0（自然结束）**。当前仪器状态：.dump /f 同时挂在 recv#2（child_full.dmp）与 EXIT_SKIP（early_death.dmp）两处；下一轮起每轮必产出一个转储（死亡轮=early_death、网络轮=child_full），数据不再流失。
