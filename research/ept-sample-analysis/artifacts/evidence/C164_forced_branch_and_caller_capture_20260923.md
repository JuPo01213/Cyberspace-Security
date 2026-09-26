# C164：强制绕过分支 + caller 捕获运行（2026-09-23）

## 结论

状态：**FAIL_TO_REACH_SEAM / WAIT_TIMEOUT / NO_MACHINE_CODE_MODIFICATION / ORPHAN_PROCESS_CONFOUNDER_REMOVED**。

本轮在一次真实 Guest 运行中同时设置了「入口 + 子进程断点注入 + 分支强制写 + caller +0x80 前后缓冲」四类观测，并改为后台启动、宿主经共享盘收割（不再阻塞宿主）。结果：

- CDB 在宿主可见的共享 spool 中命中且仅命中 `[C164_ENTRY]`，`markers = 1`。
- **没有** `[C164_PATCH_SITE]` / `[C164_PATCH_SITE_P]`，即 `eb 14078eea2` / `eb 14078ef10` 的强制绕过写入**从未执行**。
- **没有** `[C164_F060]`、`[C164_MARKER_CHECK]`、`[C164_RC06_PRE]`、`[C164_RC06_CALL]`、`[C164_CALLER_AFTER_COPY]`、`[C164_NATIVE_RETURN]`。
- **没有** `[C164_AV]`。
- runner 在 150 秒 deadline 后收尾为 `WAIT_TIMEOUT`，`cdb_exit_code = 1`。
- 未取得 `native_return`、`changed_bytes`、caller `+0x80` 前后缓冲，也未发生任何目标机器码修改。

因此本轮**不满足**硬判据：

```text
native_return == 0x1      —— 未取得
changed_bytes > 0         —— 未取得
```

## 运行身份

| 项 | 值 |
|---|---|
| run id | `EPT_RC00_BYPASS_FORCE_20260923C164` |
| VM | `<OTHER_VM_LABEL>`（`<OTHER_VM_LABEL>` VM，2026-09-23 状态 `running`） |
| 当前快照 | `qoder-clean-20260920` |
| 目标映像 | `C:\ept_core\Hardware.exe` |
| 样本 PRE/POST SHA-256 | `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` |
| runner 源/SHA-256 | `<HOST_PATH>\HexPatch\probe\EPT_RC00_BYPASS_FORCE_20260923C164.ps1`，Guest 投递副本哈希一致 `CB86220AFB7951452D0D24FF2B3B2F05D7D327E76A945C64FF0AE082EAEBADDB` |
| CDB SHA-256 | `5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67` |
| run.cdb SHA-256 | `0B6CB88D03D72429E137EE42B8257D48BECA64326C7BEB0027089CB2497D4017` |
| child.cdb SHA-256 | 见 spool 内文件（773 B） |
| 输入 | `chars=380`，`sha256=D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`（不记录明文） |
| deadline | 150 s |
| E: 可用空间（运行前） | 270.33 GiB |

## 采集设计（本轮与 C163 的差别）

`run.cdb`（父进程）：

```text
sxd ibp
.childdbg 1
sxe -c ".echo [C164_PARENT_AV]; ... q" av
sxe -c "$$><C:\ept_obs\EPT_RC00_BYPASS_FORCE_20260923C164\child.cdb;g" cpr
bu 14235f67b ".echo [C164_ENTRY]; r rip; r rsp; g"
bu 14078ee9b ".echo [C164_PATCH_SITE_P]; db 14078eea2 L2; db 14078ef10 L2; eb 14078eea2 EB 5E; eb 14078ef10 EB 30; db 14078eea2 L2; db 14078ef10 L2; g"
bu 14078ef42 ".echo [C164_RC06_PRE_P]; r r14; db poi(@r14)+80 L30; g"
bu 14078efe1 ".echo [C164_NATIVE_RETURN_P]; r eax; r r14; db poi(@r14)+80 L30; g"
g
```

`child.cdb`（子进程创建时注入，覆盖 C109 记录的「子进程未设断点」缺口）：入口、分支强制写点、F060、marker 比较点、RC06 前、RC06 调用、copy 完成后、native return。

强制绕过写入目标沿用 C105/C131/C133 已静态证实的两处分支：

```text
0x14078eea2  75 5E  (jne) -> EB 5E
0x14078ef10  74 30  (je ) -> EB 30
```

设计意图：把 RC03 失败分支与 marker 比较分支都改为无条件跳转，使 RC00 直接进入 RC06 变换叶，从而取得 `native_return == 0x1` 与 caller `+0x80` 的 268 字节写回（`changed_bytes > 0`）。

## 直接观察

CDB 原始日志（脱敏副本 `cdb.redacted.log`，`redacted_sha256=27184F00BBA0E6348AC1D789616C8FF2195548D17D998788E609EAB7C537DD78`；原始日志 `raw_sha256=C8576CB624E12F4F92C03EDD9EF2F25772EC463F1AAEA48AF2CDA5BA785CF327`，原始件仅留在 Guest `C:\ept_obs\<run_id>\cdb.log`，未镜像到宿主）：

```text
ModLoad: 00000001`40000000 00000001`43f83000   image00000001`40000000
(1a14.574): Break instruction exception - code 80000003 (first chance)
0:000> sxd ibp
0:000> .childdbg 1
Processes created by the current process will be debugged
0:000> sxe -c "$$><...child.cdb;g" cpr
0:000> bu 14235f67b ...
0:000> bu 14078ee9b ...
0:000> bu 14078ef42 ...
0:000> bu 14078efe1 ...
0:000> g
*** WARNING: Unable to verify checksum for C:\ept_core\Hardware.exe
[C164_ENTRY]
```

之后的 145 秒内 CDB 日志字节数恒定（heartbeat 记录 `cdb_log_bytes=4197` 自 tick=5 起不再增长直到 tick=75 超时）。

因此本轮可动态确认的只有：

1. 目标映像以基址 `0x140000000`、大小 `0x03F83000` 加载；
2. 父进程 PE 入口 `0x14235f67b` 被命中（与 C109/C160/C163 一致）；
3. 命中入口后，在 150 秒内**没有**创建被调试的子进程（`cpr` 命令未被触发），也**没有**到达 `0x14078ee9b`。

## 重要环境发现：C163 遗留孤儿进程（已清除）

C164 的 `pre.json` 与 `post.json` 进程面完全相同，说明 `cdb`/`Hardware` 两个进程在整个 C164 窗口内一直存在且**不属于本轮**。Guest 侧取证脚本确认其启动时间：

```text
cdb       pid 1904   start 2026-09-23T16:30:34.9417701+08:00
Hardware  pid 788    start 2026-09-23T16:30:35.3563592+08:00
```

即 **C163（08:30:34Z = 16:30:34+08:00）的 CDB 与其目标进程在 C163 收尾失败后未被杀掉，持续存活约 3 小时**（C163 的 `taskkill` 路径解析错误正是收尾失败的已知缺陷）。

已执行有界清理（仅匹配 `Hardware|EPT|UVT|cdb`，`taskkill /T /F` 加 PID 兜底）：

```json
"killed_pids": [1904, 788],
"after": []
```

`after` 为空，Guest 目标进程面已归零。

## Guest 驱动 / 部署 / 残留取证

同一次取证脚本（`guest_probe.json`，`Z:/probe/EPT_RC00_BYPASS_FORCE_20260923C164/guest_probe.json`）：

```json
"hp_services":      [ { "name": "shpamsvc", "status": "Stopped" } ],
"hp_driver_files":  [ { "name": "HpSAMD.sys", "bytes": 64312, "mtime": "2019-12-07T17:07:53.4704922+08:00" } ],
"temp_ept":         [],
"logs_hwid":        [ { "name": "Hardware.exe", "bytes": 32671232, "mtime": "2026-09-19T05:43:15.2962704+08:00" } ]
```

要点：

- `C:\Windows\System32\drivers` 中**只有**微软自带的 `HpSAMD.sys`（2019 年的存储驱动），**没有**清单登记的样本内核 helper `HP_WKS_SWTOOLS_DRIVER.sys`；也没有任何 `Hp`/`SWTOOLS` 服务处于运行态。
- `%TEMP%` 下**没有** `EPT_*.exe`，即 `qoder-clean-20260920` 快照中**不存在**样本的临时子进程部署物。
- `C:\ept_core` 仅有原始 `Hardware.exe`（哈希与预期一致），无附加日志/配置产物。

这三项共同说明：`qoder-clean-20260920` 是一份未运行过样本的干净基线，样本运行所需的设备/驱动与子进程部署物都尚不存在。这与「命中入口后长时间静默、既不创建子进程也不到达 RC00」的观测一致，但**仅为相关性解释，不是已动态确认的因果**。

## 证据边界

- 本轮**没有**发生目标进程机器码修改：`0x14078eea2` / `0x14078ef10` 的强制写入命令从未被 CDB 执行（无 `[C164_PATCH_SITE*]` 命中）。
- 入口命中 ≠ 授权成功；`WAIT_TIMEOUT` ≠ 授权阴性；目标文件磁盘哈希前后相同 ≠ 运行时内存未修改。本轮对三者的区分均已保留。
- `sxe ... cpr` 在 CDB 中被接受且无语法报错，但 150 秒内未触发，因此本轮的 child.cdb 注入路径**未被执行、也未得到验证或证伪**。
- `guest_probe.json` 的驱动/部署结论是清理后的瞬时快照，不代表样本运行期间的实时状态；不能用它证明样本「尝试过」安装驱动。

## 产物

目录：`<HOST_PATH>\HexPatch\probe\EPT_RC00_BYPASS_FORCE_20260923C164\`

| 文件 | 说明 |
|---|---|
| `runner.log` | 阶段时间线：BOOT→SAMPLE→INPUT→CDB_READY→CDB_STARTED→HEARTBEAT→TIMEOUT→CDB_LOGS→DONE |
| `phase.txt` | 最后阶段行 |
| `pre.json` / `post.json` | 样本哈希与目标进程面（暴露了 C163 孤儿进程） |
| `done.json` | `status=WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=1`、`response_injection=false` |
| `run.cdb` / `child.cdb` | 父/子断点脚本，SHA-256 见上表 |
| `cdb.redacted.log` | 脱敏 CDB 日志（唯一对外可引用的日志副本） |
| `guest_probe.json` | 孤儿进程清理、HP 服务/驱动、%TEMP% 与 `C:\ept_core` 残留 |

敏感数据处理：CDB 原始日志含命令行输入，仅保留在 Guest `C:\ept_obs\<run_id>\cdb.log`，**未**镜像到宿主；对外只提供 `cdb.redacted.log` 与其哈希。本文件不复述输入明文。

## 下一步（按区分力排序）

1. **去掉调试器，做一次受限的自然部署观测**：在 Guest 内以 60–90 秒窗口直接运行目标（可用 `core_continuous_probe` 之外的纯自然启动），只采集进程创建/父子 PID、`%TEMP%` 新文件、驱动/服务变化、`C:\ept_core` 与日志目录变化。这直接回答「自然路径是否创建子进程/部署物」，且成本低、不占用宿主。可作为交付物中的进程/部署行为证据。
2. **只有在步骤 1 表明自然路径能走到设备/授权接缝时**，再重跑 `child.cdb` 注入 + 分支强制写，届时才可能取得 `native_return == 0x1`、`changed_bytes > 0` 与 caller `+0x80` 前后缓冲。
3. **若自然路径始终停在入口**，则改用 Guest 内直接调用路线（C130 已证实可在 Guest 内命中 `0x14078f060` 并产出 268 B 输出），叠加 C152 已证实的伪造响应头判据（解码头 `0x12345678`）与 `changed_bytes` 统计，在 Guest 侧闭合判据，并明确标注其为 caller/injection 级证据而非自然 CLI 证据。
4. 每轮运行前必须先确认目标进程面归零（本轮教训：孤儿 `cdb`/`Hardware` 会污染 PRE/POST 进程面并可能占用设备）。

## 可复核材料

- runner：`<HOST_PATH>\HexPatch\probe\EPT_RC00_BYPASS_FORCE_20260923C164.ps1`
- 取证脚本：`<HOST_PATH>\HexPatch\probe\C164_guest_cleanup_probe.ps1`
- 原始运行目录：`<HOST_PATH>\HexPatch\probe\EPT_RC00_BYPASS_FORCE_20260923C164\`
- 前序证据：`C160_dispatch_context_20260923D.md`、`C161_tail_edge_observe_20260923E.md`、`C150_rc00_high_address_av_without_context_20260922.md`、`C133_rc00_internal_forced_decode_cut_20260922.md`、`C131_ept_upstream_identity_and_rc00_cut_20260922.md`
- 通信手册：`method/COMMUNICATION_PLAYBOOK.md`
