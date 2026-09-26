# EPT专业游戏维修工具箱 V5.1 — 逆向分析仓库

分析对象：`sample/EPT专业游戏维修工具箱V5.1.exe`（UPX + PyInstaller 外壳，内含 Python 3.13 业务层）
与被下发的核心 `Hardware.exe`（genB，VMProtect 加壳）。结论是**服务端只下发授权判定、程序本体都在样本内**。

## 当前分析目的（2026-09-24 校正）

这是恶意样本分析，不以正规授权成功为目标。RC00/RC03/RC06 解码 seam 只是触发点；真正目标是让真实样本进程走到响应后路径，并在不截断 RC06 的前提下观察解码结果的消费方式及后续伪装、规避、持久化、注入、释放、网络和清理行为。

- C152/C175 等 caller/injection harness、映射代码段 runner、离线 forge response 只保留为局部参考，不能作为目标完成。
- 目标级实验必须区分自然驱动 response 与 I/O 边界受控注入；后者只能说明真实目标进程在受控 response 下继续执行。
- `target_native_return==0x1` 与 `target_caller_diff_bytes>0` 是必要 seam 条件，不是最终完成条件；最终还要有同一次未截断运行的解码后行为证据。
- 详见 `AGENTS.md`《分析目的与完成方向（校正）》与 `method/HANDOFF.md` §0.5。

## 从这里开始读

1. **`writeup/00-index.md`** —— 分篇索引、阅读顺序、旧→新章节映射、本次重写带来的更正表。
2. 六篇正文 —— 前五篇保留外层、授权与分支证据；当前核心目标单独见 `writeup/06-local-decoder-core.md`，其中明确区分局部变换、保护运行时和最终解码的证据强度。
3. `LAYOUT.md` —— **目录与书写规则**（放东西前先看它；有 `layout_gate.py` 机器把关）。
4. `method/COMMUNICATION_PLAYBOOK.md` —— 靶机通信三平面、健康闸门、脚本投递、CDB 观测与离线收割规则。
5. `RUN_MANIFEST_genB.md` —— 每一轮做了什么、产出哪个件、环境留在什么状态（按时间追加）。
6. 固定加载的 `ept-analysis-workbench` 与 `reverse-engineering-workbench` Skills、`method/ROADMAP.md` —— 可复用的分析流程、通用通信契约与下一步路线。

## 目录

| 目录 | 内容 |
|---|---|
| `writeup/` | 交付正文（只放 .md） |
| `artifacts/evidence/` | 证据件 `C<n>_*`（表格、清单、反编译，全部 < 5 MB） |
| `artifacts/captures/` | 原始捕获物：内存窗口、Ghidra 对象、pcap（不入库，哈希在 `CHECKSUMS.sha256`） |
| `artifacts/deprecated/` | 已作废产物，逐个说明为何不可用 |
| `sample/` `unpack/` `archive/` | 分析目标与解包树 / 脱壳工作产物 / 拆分前冻结原件 |
| `method/` | 方法论与被复用的流程脚本 |

## 复现与安全边界

复现命令按篇章列在 `writeup/05-conclusions-and-ledger.md` §5.4；分析脚本本体位于宿主工具目录（本仓库不放副本，避免“两份真相”）。
靶机操作边界（仅在 VM 内执行、实验前必须存在可回滚快照、不解码 `0x140f92550` 处内嵌 token、不连接 `yz.hwid001.com`、实验盘只读挂载）逐字写在 `writeup/00-index.md` 末尾与 `LAYOUT.md` §7。

## 本条目的公开范围

本条目收录**分析文本与小型证据件**，不含样本字节。收录/排除规则、脱敏动作与证据诚实度声明见 [PUBLIC_DELIVERY.md](PUBLIC_DELIVERY.md)。
