# C197 · 全映像转储尝试与 .dump /f 修正设计

日期：2026-09-26 · 运行：EPT-AUTHGATE-20260925-82（4 轮，快线 RECV×5/CFW×1，无 FATAL——echo 探针下样本持续重连）

## 1. 发现

`.writemem` 写 66MB 全映像（`140000000 L3f83000`）**静默失败**：recv 动作内其它转储（67B/10KB/20KB/100KB/4KB）全部成功并打印 "Writing"，唯独 66MB 的既无 "Writing" 也无错误输出——命令未生效。`.writemem` 对大尺寸（>100KB 量级）不可靠。

**修正**：完整进程捕获应使用 cdb 原生命令 **`.dump /f C:\path\child.dmp`**（完整用户态转储：全映像+全堆+全栈一次拿到），在 recv#2 动作内执行一次即可。dmp 文件可被 Ghidra 直接导入（Raw/Minidump loader）或 windbg 离线分析。

## 2. 方法沉淀

1. `.writemem` 适用上限在 100KB 量级内（100KB 成功、66MB 静默失败；中间阈值未测）——大块内存捕获一律用 `.dump /f`。
2. 快线类已在 echo 探针下稳定复现（RECV×5 = 样本对探针响应的持续重连）——捕获窗口充足。
3. 4 轮循环全部"still missing"的根因是 writemem 静默失败而非结果类轮盘——**失败诊断要先看工具输出再怪环境**。

## 3. E-2c Phase C 完整设计（下阶段执行）

1. recv#2 动作内：`.dump /f C:\ept_obs\spool\<id>\child_full.dmp`（一次完整捕获）
2. dmp 离线：定位 103B 响应缓冲的解密前后内容 + 沿 0x14014731C→派遣链的运行时真实 handler 地址（dmp 内可直接读加密跳转表全量）
3. Ghidra 导入 dmp（或 full_image 分段转储）→ 反编译解密例程 → 提取密钥来源
4. 构造合法响应（injected_io 标注）→ FATAL@0x1407aa694 消失/后移验证 → payload 物质化 → RC00/RC03/RC06 seam

## 4. 台账

`target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）。
运行目录：runs/EPT-AUTHGATE-20260925-82。本轮无新捕获物（writemem 静默失败）。

## 5. 执行记录补记（同日晚间）

`.dump /f` 已接入 recv#2 动作并完成 5 轮循环——全部为秒死类（无 RECV → .dump 未触发）。快线/完整类窗口关闭中（上次快线窗口 22:05-22:39 UTC+8）。**下阶段执行要点**：在快线/完整类窗口重开时循环跑 recv#2+.dump /f 配置（每轮 ~4 分钟），dmp 落地后离线分析。窗口规律本身登记为观察项：快线/完整类集中出现于特定时段，秒死类占其余——与恢复状态无关，疑似保护壳按绝对时间/环境指纹的调度。

## 6. .dump 路径解析定案

- 反斜杠路径在 cdb 断点动作字符串中被解析吞掉（`C:\ept_obs\...` → `C:ept_obs...` 连文件名带后续命令）且降级 mini dump——**.dump 路径必须用正斜杠**（`.dump /ma /o C:/ept_obs/...`），与 .writemem 同规则。
- `/f` 在用户态不支持（cdb 明示），用户态完整转储 = `/ma`。
- 已就绪配置：recv#2 动作内 `.dump /ma /o C:/ept_obs/spool/<id>/child_full.dmp`（/o 覆盖旧文件，多连接取最后一份）。
- 快线窗口 23:33 后关闭（本轮秒死），正斜杠 /ma 配置将在下一窗口首轮即生效。

## 7. 首个全进程快照落地（重要里程碑）

- `child_full_recv2.dmp`（106,884,210 B）已在 recv#2 入口捕获（mini-dump 格式但含 107MB 内存数据），SHA-256 记录于同目录 `.sha256`
- 内容：进程全量内存（状态机运行时代码、加密跳转表、全局区、103B 请求缓冲区）
- 注意：文件名被 cdb 路径解析吞尾（`child_full.dmp dd @rsp L1`），后续用引号包裹路径修复
- 该快照是**单轮、单时点、recv#2 入口附近的部分进程内存快照**，不是完整授权链、不是完整自然运行记录，也不能代表 mut_trace.json 所在的另一轮。它适合做静态/内存取证，但不能证明请求构建、服务器响应、解码和后续行为在同一轮闭合。
- 不入 git（107MB），SHA-256 登记
