# C186：部署管线全链观测、调度器合成返回与载荷写入失败（runs 37–48）

日期：2026-09-25/26
evidence_scope：`real_sample_guest_run_with_predecode_gate_release`（运行时内存内强制；无 response 注入、无可分发补丁产物）
谱系：`C:\ept_core\Hardware.exe` SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`（每次布防后 in-guest 重验）← 权威样本 `CA6B4C6A…D87ACAA3B2`；派生物源 `artifacts/captures/hardware_guest_test.exe`
原始收割件：`runs/EPT-AUTHGATE-20260925-37..48/`（cdb.stdout / events / winproc / post_snapshot / run.json）
交接物：`HANDOFF-20260925-authgate-pipeline.md` + C184

## 1. 一段话结论

部署管线（Setup 链→免责→主 GUI→KEY→CardLogin→配置落盘→服务创建/启动轮次→载荷释放→明文 fatal 尾块）已**全链可观测、可复现、可强制**；调度器第二闸门与合成返回机制打通后 main 线程**自然返回**，进程按"部署完成即退出"语义终止。**RC00/解码 seam 仍未到达**——阻塞点移到部署完成条件（7.9MB 载荷 WriteFile 未落盘 + StartService 在隔离环境失败）。

## 2. 逐轮速览

| RUN | 结果 | 关键事实 |
|---|---|---|
| 37 | POSITIVE（观测） | **服务名随机化**：`HpSvc`+17 随机串，每轮 Open→Create→Start→reOpen ×3；死亡链 FatalExit+0xb→RtlExitUserProcess→NtTerminateProcess；FatalExit 入口断点被 thunk 绕过 |
| 38 | INVALID_INSTRUMENT | 映像内软件断点（0xCC@0x1407aa68c）→ 秒死于保护区 `0x143ae5d57`（空返回帧）——最初误归因为完整性校验 |
| 39 | INVALID_INSTRUMENT | 同签名秒死（0x1407aa68c 硬件断点）——0xCC 归因被撤回 |
| 40 | POSITIVE（判别） | 37 原样重放→完整链：判别成功，38/39 死因非断点地址本身 |
| 41 | INVALID_INSTRUMENT | 108f/567 硬件断点集仍秒死 → 与 40 对比指向**轮次间残留状态** |
| 42 | INVALID_INSTRUMENT | 恢复基准检查点后 GUI 前冻结：COM 期 first-chance 异常未透传，cdb 停在无脚本覆盖提示符 |
| 43 | POSITIVE（判别） | 干净基线 + 无 wrapper-1 强制 →「服务器配置获取失败!」（`0x140f92ed0`）msgbox→ExitProcess：wrapper-1 为 GetServerOption 必需强制 |
| 44 | **重大 POSITIVE** | GUI 全链 + FATAL_THUNK 命中 + 合成返回执行 → 调度器续跑 0x67 字节 → 第二闸门（call `0x1407b1464`→AL=0）→ `0x1407c1d18` fatal 包装器 |
| 45 | INVALID_INSTRUMENT | SW 断点 `kernel32!FatalExit+0xb`（0xCC 写入 API 落点字节）→ 保护区检测 → 直落尾块快速终止 |
| 46 | INVALID_INSTRUMENT | 与 44 相同断点地址集仍秒死 → **轮次残留污染**由排除法确证 |
| 47 | INVALID_INSTRUMENT | 冻结复现于 COM 期 → C++ EH（0xE06D7363）默认断下 |
| 48 | **重大 POSITIVE** | 全链无冻结；**`WFW r8=0x799000`（7.9MB）载荷写入尝试**（文件遗留 0 字节）；合成返回落 `109b/eax=1` 强制第二闸门 → 成功路径 `b08e4(1,0)` → **main 自然返回**（RtlExitUserThread）→ 进程退出 |

## 3. 机制全景（新增部分）

```text
部署函数 0x1407a4b90（23KB，含全部阶段链）由调度器 0x1407b108f 调用：
  config 检查（缺→驱动区 msgbox 服务器配置获取失败!→ExitProcess；wrapper-1 强制为必需）
  → Setup 链（Init/GetServerOption/GetNotice，wrapper-1 强制归零）→ GUI（免责→主GUI→KEY→应用并启动）
  → CardLogin(-21→0) → SaveConfig(900B) → StoredAuth 家族（wrapper-2 强制）
  → 载荷释放：CreateFileW %TEMP%\随机名(30字符) → WriteFile 0x799000（未落盘，文件遗留 0 字节）
  → 服务轮次（HpSvc 随机名 ×3，StartService 失败）
  → 明文 fatal 尾块 0x1407aa68c → call thunk 0x14171f567 →（绕过 FatalExit 入口落 +0xb）
调度器第二闸门 0x1407b1094..0x1407b10fb：
  mov ebx,eax; call 0x1407b1464 → AL：1=成功路径 call 0x1407b08e4(cl=1,dl=0)→main 返回
                                0=fatal 包装器 0x1407c1d18 → ExitProcess
```

## 4. 仪器教训（新增，全部为本阶段实测）

1. **映像内只许硬件断点；外部 API 的软件断点也可能触发保护**：`kernel32!FatalExit+0xb` 上的 0xCC 被保护区检测（API 落点字节完整性），走快速终止路径。
2. **thunk 多态**：明文尾块的 `call 0x14171f567` 解析到不同 API 落点（FatalExit / ExitProcessImplementation），且总是**绕过 API 入口**——入口断点不可靠，落点（+0xb）断点会被检测。
3. **cdb 默认 first-chance 断下异常必须显式透传**：COM 期 C++ EH（`e06d7363`）、保护区 int3（`80000003`）等会让无脚本覆盖的提示符冻结目标。run 48 的透传集：`av, c0000005, e06d7363, 80000003, 80000004, c000001d, c0000094, e0434352`。
4. **轮次间残留污染**：全链运行留下的状态（配置文件、TEMP 载荷壳、服务等）改变下一轮行为（38/39/41/45/46 的秒死均发生在全链轮之后）。**每轮恢复基准检查点 + 重新布防 + 哈希重验**为强制纪律（本轮已执行：42/44/47/48 恢复后布防）。
5. cdb 伪寄存器 `$t0-$t8` 跨断点传递上下文可行且已验证（合成返回的核心机制）。
6. `ExitProcess` 断点 k 栈顶不显示自身帧（jmp thunk 语义）；`Get-CimInstance` 过滤词注意大小写不敏感假阳性（`perceptionsimulation` 命中 `ept`）。

## 5. 环境与谱系记录

- 15:14Z/15:17Z 两次矛盾读数（C185 §4）事后与新证据吻合的解释方向：差分盘（AVHDX）层状态与检查点层的视图差异；未定论，以双方法复核为纪律。
- 15:58Z 起每轮恢复基准检查点 `<VM_LABEL>-gen1-channel-ready`；恢复后需重新布防 `C:\ept_core\Hardware.exe`（检查点早于布防）并重验哈希；`chkdsk` 待办：`C:\Windows\System32\Hardware\Hardware` 幻影目录条目（dir 可见/打开失败）随最后一次恢复已不在现役视图。
- StartServiceA 失败根因未捕获（服务名随机化使 sc 句柄查询无意义；错误码需 return-side 断点）。

## 6. 距完成判据的差额（诚实边界）

- 新闭合：部署域全链观测（含 7.9MB 载荷写入尝试、服务随机化）、调度器第二闸门定位与强制、合成返回机制、干净退出路径。
- 未闭合：`target_native_return`/`target_caller_diff_bytes`（RC00/RC03/RC06 seam）；载荷内容（7.9MB 写入失败，0 字节遗留）；部署完成条件（StartService 成功 → 被部署组件承载 Run/RC00？）；全部解码后行为（HWID 修改、伪装进程/R3.exe、`\Microsoft\Hardware` 计划任务、`System32\Logs`/`HardwareLogs`、痕迹清理）。
- 对应 rules：`TARGET_SEAM_NOT_CLOSED / POST_DECODE_BEHAVIOR_NOT_OBSERVED / DEPLOY_COMPLETION_UNRESOLVED`。

## 7. 下一轮决策点（需用户裁决级别）

1. **部署完成路径**：7.9MB 载荷写入失败原因（handle/返回值观测）；若载荷=驱动，隔离 Guest 需允许其加载（testsigning/DSE——环境级变更）。
2. **RC00 位置假设**：调度器成功路径即 main 返回，Run/RC00 可能由被部署的服务/驱动承载——若成立，seam 观测需转向服务进程/驱动加载路径，而非父进程。
