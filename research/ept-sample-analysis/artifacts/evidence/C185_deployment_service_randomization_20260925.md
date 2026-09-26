# C185：部署域服务随机化与配置分支分叉（run 37）

日期：2026-09-25
evidence_scope：`real_sample_guest_run_with_predecode_gate_release`（同 C184；运行时内存内强制，无 response 注入、无可分发补丁产物）
谱系：`C:\ept_core\Hardware.exe` SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`（本轮运行前重验）← 权威样本 `CA6B4C6A…D87ACAA3B2`
原始收割件：`runs/EPT-AUTHGATE-20260925-37/`（cdb.stdout.txt / events.ndjson / winproc.ndjson / post_snapshot.json / run.json）

## 1. 一句话结论

首次观测到**部署域服务名随机化**与**已存配置分支分叉**：run 36 落盘的 900 B 加密配置使后续运行完全跳过 Setup GUI，直接走 StoredFlow → 三轮「随机服务名 Open→Create→Start」→ 明文 main 区段 FatalExit(0)。

## 2. 关键事实（cdb.stdout.txt 原始行）

1. **服务名随机化**：`OpenServiceA("HpSvcGLBDmwG24BiocdknfI")`（探测，失败）→ `CreateServiceA("HpSvcnWVwANAwnFRqMQkJM3")` → `StartServiceA` → 复查；换名 ×3（`HpSvczwwmC2oYJHyaxS3sUR`、`HpSvcjQRWUYTIbo3qtNzbXf`）。服务名 = `HpSvc` + 17 位随机字符，每次重建新名——run 36 只见 SC_HANDLE 的原因即此。
2. **死亡链补全**（EXIT_PROCESS 断点 k10 + `~*k`）：`NtTerminateProcess ← RtlExitUserProcess+0xb8 ← KERNEL32!FatalExit+0xb ← EPT_*+0x7aa694（明文 main）← +0x7b1094（调度帧）← BaseThreadInitThunk`。与 run 36 的 `k` 上游一致。
3. **`kernel32!FatalExit` 入口软件断点未命中**：死亡栈却显示执行点在 `FatalExit+0xb`——保护区 thunk（`0x14171F567`）疑似跳过 API 入口数字节进入（反入口断点设计）。run 36 同断点命中过，尚无定论，记为待验证。
4. **路径分叉（本轮最重要）**：存在 `C:\Windows\System32\Hardware\Hardware`（900 B，run 36 产物）时：CFW 仅读取该配置（无 TEMP 载荷写盘，run 36 的 `GxtzesMZfGLDHgvp`/`kudcHHlnJWaZB` 未重建）→ `StoredFlow.LoadConfig=1 / StoredAuthorizationUsable=1 / VerifyStoredCardStatusBeforeUse=1`（wrapper-2 强制）→ `SP_Verify_Init=0`、`SP_Verify_GetServerOption=-3`（原始值；早期验证阶段不经 wrapper-1，与 run 27/36 一致）→ sc.exe ×2 → 三轮服务 → FatalExit。**Setup GUI/免责声明/CardLogin/KEY 全部未发生**（winproc 空转 300 s，agree=0）。
5. `Run.StoredAuthorizationUsableBeforeDriver` 自评 rbx=0 → 强制 1（同 run 36），随后仍 3 轮服务失败 → FatalExit：该布尔强制不改变终点。
6. post_snapshot：无服务残留、无驱动、无计划任务/日志目录（success 标志仍全无）；`System32\Hardware\Hardware` 900 B 在位。svc_paths 仅含大小写误报（`perceptionsimulation` 命中大小写不敏感的 `ept`）。

## 3. 与完成判据的差额（不变 + 新增）

未闭合项同 C184 §5（RC00/RC03/RC06 seam、`target_native_return`、解码后行为）。新增认知：**配置存在性是路径选择变量**——下一轮若需重走 GUI→CardLogin→RC00 路径，必须先处置该 900 B 配置（Guest 内删除或备份后删除，动作可回滚、需登记）；若走 StoredFlow 分支，则需在「3 轮服务失败」处寻找前进条件（驱动文件缺失是有界阴性）。

## 4. 环境异常记录（如实）

15:14Z/15:17Z 两次 PowerShell Direct 查询返回与终态矛盾的结果（`C:\ept_obs` False / `Hardware.exe` not found），15:19Z 起同路径完整存在且与运行期写入一致；宿主 Hyper-V VMMS 无回滚事件、guest 无重启。两次查询数据判为不可信，原因未明。教训：关键状态判定需两种独立方法复核后再下结论。

## 5. 仪器教训（新增两条）

- `kernel32!ExitProcess` 在该系统上是到 `RtlExitUserProcess` 的轻量入口：bp 命中点的 `k` 栈顶不显示 ExitProcess 帧，判读时以完整链为准。
- 大小写不敏感正则匹配服务/路径会产生 `perceptionsimulation`→`ept` 类假阳性，过滤词要加边界。
