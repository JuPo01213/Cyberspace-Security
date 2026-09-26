# EPT 靶机通信与证据平面操作手册

> 适用范围：<OTHER_VM_LABEL> 上的 EPT 动态实验编排、调试器观测和行为取证。
> 本手册只规范通信与证据收割，不改变样本结论，也不把通信结果当作授权结果。
> 2026-09-23 汇总自 C64、C70、C132、H2 以及 E-HexPatch 项目记忆中的已验证故障。

## 1. 核心原则

### 1.1 三平面分离

| 平面 | 负责什么 | 允许的工作 | 不能承担的结论 |
|---|---|---|---|
| 控制面 | 启动、短命令、健康检查、状态查询 | VBoxManage/GuestControl；SSH 仅作独立诊断 | 连接成功不等于样本已运行或分支已完成 |
| 数据面 | 运行中持续保存小型状态 | Guest 本地 spool；共享目录实时镜像；结束后离线收割 | stdout 为空不等于没有输出 |
| 完成面 | 判断一次运行是否结束以及如何结束 | DONE marker、自然退出码、阶段 marker、VM 状态、离线证据 | SSH 断开、GuestControl 返回或宿主超时都不是完成事件 |

控制面失效时，数据面和完成面仍必须可独立读取。三者都失效时，结果只能记为仪器失败或未知。

### 1.2 结论分层

以下状态必须分开写入 run metadata：

- CONTROL_NOT_READY：GuestControl 会话未就绪、SSH banner 超时、NAT/Guest Additions 尚未稳定。
- DATA_PLANE_LOST：Guest 可能仍在运行，但 spool 或共享目录镜像不可读。
- DEBUGGER_NOT_REACHED：只命中入口或 dispatcher，没有业务 marker。
- STALL_SUSPECTED：超过阶段墙钟预算且没有新的阶段 marker。
- WAIT_TIMEOUT：deadline 到达，保留部分证据后收尾。
- INSTRUMENT_FAILURE：观测链断裂，不能解释为样本成功或失败。
- TARGET_RESULT：只有在完成面和业务证据同时闭合后才允许使用。

WAIT_TIMEOUT、CHANNEL_LOST、GuestControl 的 current status is: starting、SSH banner 超时，均不是授权阴性，也不是 native_return 或 changed_bytes 的值。

## 2. 每轮实验的最小流程

### 2.1 A0：宿主只读闸门

1. 读取 E: 可用空间；低于 100G 时只做只读分析，低于 60G 时停止新实验、快照、转储和克隆。
2. 确认 VM 当前状态、当前快照、实验基线和待收割目录；不把半关闭会话快照直接当作干净基线。
3. 实验前后运行 bash <HOST_PATH>，记录空间变化。
4. 单轮新增占用不超过 8G；每轮最多创建一个快照；超过 100M 的新文件必须登记用途和收尾动作。

### 2.2 A1：客户机健康闸门

按顺序检查：

1. 宿主 VBox 日志出现本次启动的 NAT: Link up，不能拿旧日志行充当当前会话证据。
2. 用短命令做两次简单探针，例如 tasklist、ver 或读取一个小型状态文件；不要使用 WMI、长时间下载、解压或杀进程链验证通道。
3. GuestControl 若刚恢复，先关闭/清理旧会话，再用短命令复测；不要把长命令塞进同一个 guest session。
4. SSH 只作为独立控制/诊断面。banner 早期超时后，按就绪时序重试一次；不要因一次 15 秒超时直接判定客户机失活。
5. 若健康闸门未闭合，运行状态标为 CONTROL_NOT_READY，不启动样本，不进入调试器结论阶段。

### 2.3 A2：脚本投递而非多层内联

Guest 侧固定使用：

1. 宿主写入完整 .ps1/.cmd 文件；
2. lab.ps1 -Action copyto 投递；
3. GuestControl 只执行简单脚本路径，或触发已经存在的计划任务；
4. 通过小型 spool/marker 读取结果。

禁止把复杂 PowerShell、管道、重定向、变量、嵌套引号和多层变量展开拼进 lab.ps1 -Action run -Cmd。四层解析链会吞掉引号和变量；出现空输出或奇怪错误时，先回到脚本投递，不尝试继续排列引号。

当前 GuestControl 的入口是 <HOST_PATH>\VMs\<OTHER_VM_LABEL>\lab.ps1。用户名和凭据由该封装统一引用；凭据不复制到新脚本、不写入日志、不回显到报告。SSH 密钥和 GuestControl 凭据不作为业务证据的一部分。

### 2.4 A3：小型数据面

每次运行建立独立目录，例如：

    C:\ept_obs\RUN_ID\
      heartbeat.txt
      phase.txt
      events.ndjson
      pre.json
      post.json
      done.json
      stdout.tail.txt
      stderr.tail.txt

规则：

- heartbeat.txt 只写时间、阶段、PID 和递增序号；
- events.ndjson 只保留阶段、进程、异常等小事件，不把全量 stdout 当状态通道；
- pre.json、post.json 只保存目标文件的路径、存在性、大小、哈希和必要时间字段；
- 每次状态更新先写临时文件，再原子替换正式 marker，避免半文件被宿主读到；
- 共享目录只镜像小文件，原始 ETL、PML、转储等大捕获物按预算另行收割；
- 数据面写入成功不等于样本业务完成，必须由完成面确认。

### 2.5 A4：完成面

done.json 至少包含：

    {
      "run_id": "RUN_ID",
      "status": "TARGET_RESULT|WAIT_TIMEOUT|INSTRUMENT_FAILURE",
      "phase": "PHASE_NAME",
      "pid": 0,
      "exit_code": null,
      "deadline_reached": false,
      "artifacts": ["pre.json", "post.json", "events.ndjson"]
    }

只有在 post.json 已写完、marker 已落盘、runner 已刷新文件并且自然退出或明确收尾后，才写 status=TARGET_RESULT。若只得到入口 marker、CDB 仍在运行、控制通道断开或被强制结束，使用 WAIT_TIMEOUT/INSTRUMENT_FAILURE。

## 3. 调试器观测规则

### 3.1 CDB 脚本化

- 调试命令放入 .cmd/-cf 文件，每行一个命令；先做无样本 smoke test，确认日志文件、命令文件和退出语义有效。
- 不再使用 bc、eb、db、.echo、g 组合成单条 breakpoint action；复合 action 失败时整条链可能静默不执行。
- 任何“已补丁” marker 必须由三时点读回生成：写入后、断点/调试器状态稳定后、调试器分离后。只在配置或 run_meta.patches 中声明，不算写入证据。
- 补丁地址避免软件断点覆盖；若必须在同一地址观察，优先采用硬件断点或在读回时确认不是 0xCC 瞬态。
- 异常捕获必须带 RIP、模块、线程、寄存器/栈窗口和当前阶段；裸 sxe av 后继续运行的 AV 记为 AV_UNATTRIBUTED。

### 3.2 进程链

- 采集期不使用 cpr: 作为唯一过滤器；先全量记录进程创建和父子 PID，再离线筛选 Hardware.exe、EPT_*.exe 等链尾进程。
- 写死一种进程模型：要么 CDB 启动并接管全链，要么自然部署后按 PID 附加；不能先给一个 PID 打补丁再启动另一个实例。
- 进程创建事件、目标 PID、模块加载和阶段 marker 必须能在同一 run_id 下对齐。
- 只命中 TARGET_ENTRY、高地址 dispatcher 或父入口，不代表到达 F060、RC00、RC06，也不代表拿到授权返回值。

### 3.3 H2 作为禁止复用样例

H2 的实际输出是：

- run_meta.status=WAIT_TIMEOUT，deadline 45 秒；
- CDB 只记录 TARGET_ENTRY，随后超时；
- 没有 PATCH1_APPLIED、PATCH2_APPLIED、F060、RC06_ENTRY、CALLER_OUTPUT_AFTER_COPY 或 SUCCESS_RETURN_EDGE；
- response_injection=false；
- Hardware.exe 磁盘哈希 PRE/POST 都是 0DDC82FC...，不能据此推断运行时内存是否被修改；
- patch.cdb 中的复合 action 没有形成写后读回证据。

因此后续臂不得原样复用 H2 的复合 action、cpr: 过滤和“等待到超时再解释”的流程。

## 4. 阶段预算与失败收尾

### 4.1 阶段 deadline

每阶段都要有 expected_duration、deadline、最后一个已确认 marker、超时动作。阶段没有新 marker 时，按墙钟 deadline 收尾，不把延长等待当作新证据。

建议顺序：

1. 健康闸门：短命令和小文件读回；
2. 投递确认：脚本、样本、配置的大小/哈希；
3. 启动确认：PID、命令行摘要、首个阶段 marker；
4. 业务观测：固定窗口，按 marker 推进；
5. 收尾：先收割数据面，再处理 VM 状态和回滚。

超过阶段预算且没有新 marker，立即标记 STALL_SUSPECTED，检查 VM CPU/IO、NAT、GuestControl/SSH、heartbeat 和磁盘，再决定是否进入 WAIT_TIMEOUT。

### 4.2 收尾顺序

1. 先复制/镜像小型 spool、marker、CDB 日志尾部和宿主控制日志；
2. 再读取自然退出码和 VM 状态；
3. 仍无完成面时，保留为 INSTRUMENT_FAILURE，不补写业务结果；
4. 只有证据已收割后才回滚或关机；
5. postmortem/instrument-failure 快照按当轮磁盘规则处理，不长期囤积。

### 4.3 客体失联后的降级

- 控制面失联但共享目录仍更新：继续等待到短 deadline，随后按 marker 收尾；
- 控制面和共享目录失联：停止发送复杂命令，保留宿主日志、VM 日志和最后状态；
- 客体无法正常关机：不把强制断电当作样本退出；在收尾记录 CHANNEL_LOST，必要时对现有快照做只读离线收割；
- 需要大转储时先检查 E: 预算，默认不启动无界 ProcDump/全量 PML/重复 VDI 克隆。

## 5. ProcMon/ETW 的轻量观测

- ProcMon 只采集与目标 PID、进程名或路径前缀相关的过滤事件；设置明确时长和 backing file 上限，不默认保存无界 PML。
- 文件行为重点观察 %TEMP%\EPT_*.exe、System32\Hardware*、EPT.cmd、Logs、HardwareLogs、JW.txt、EPTHWID.txt、Hardware.ini；将“观察到的写入者 PID”和“文件最终状态”分开记录。
- 进程面优先记录 Kernel-Process 的创建/退出和父子关系；网络面需要 PID 级归因时才开启短时 Kernel-Network 采集。
- ETL/PML 是原始捕获物，不直接放入 artifacts/evidence/；先在 VM 内筛选小型摘要，宿主只收割摘要与哈希。
- 文件 mtime/ctime 不能单独证明部署时刻；需要写者和时刻时，结合 ETW Kernel-File、USN journal 或 Security 4688，并记录仪器覆盖范围。

## 6. 真实目标 seam 与解码后行为的通信侧映射

通信侧闭环只能说明“证据链可用”，不能替代 EPT 的业务结论。真实目标运行的必要 seam 条件是：

    target_native_return == 0x1
    target_caller_diff_bytes > 0

这两个字段必须来自同一真实目标进程、同一运行的目标调用返回值和 caller before/after 内存差异。`validator_rax`、harness 输出长度、`caller_output_written`、合成 runner 的 `changed_bytes` 不得映射成目标字段。

此外，最终分析必须继续收割 RC06 之后的自然行为：进程/线程树、文件/注册表写入者与最终状态、网络尝试的 PID 归因、驱动/组件释放、注入/持久化/规避和清理。若为研究 post-decode 行为而在 `DeviceIoControl` 边界注入 response，必须把 `evidence_scope=real_sample_guest_run_injected_io` 与自然驱动 response 分开；它不等于真实授权成功。通信完成面只负责证明所有字段和行为证据来自同一次、可复核、未被提前终止的运行。

## 7. 已验证来源与不再重复的路径

- artifacts/evidence/C64_communication_DIAGSSH_20260921.md：SSH 控制臂、就绪时序和三平面结论；
- artifacts/evidence/C70_outer_time_budget_and_stall_boundary_20260921.md：阶段预算、STALL 边界和 GUI 探测停滞；
- artifacts/evidence/C132_real_decode_arm_instrument_failure_20260922.md：GuestControl/SSH/收尾同时失效时的仪器失败分类；
- <HOST_PATH>\HexPatch\probe\EPT_RC00_GLOBAL_CHILD_BPS_20260922H2\run_meta.json、cdb_stdout.txt、patch.cdb、mirror_runtime.log：H2 仅到 TARGET_ENTRY 的一手输出；
- <HOST_PATH>\VMs\<OTHER_VM_LABEL>\lab.ps1：当前 GuestControl 封装入口；
- <HOST_PATH>\Users\<USER>\.codebuddy\projects\e-HexPatch\memory\feedback_guest_channel.md：脚本投递门禁；
- <HOST_PATH>\Users\<USER>\.codebuddy\projects\e-HexPatch\memory\project_env_lab_vm.md：GuestControl、SSH、VBox 和离线收割故障模式。

以下路径禁止复用：多层内联复杂命令、GuestControl 长会话、WMI 观测、复合 CDB breakpoint action、cpr: 唯一过滤、无统一 deadline 的长等待、以 stdout 空、连接断开或进程仍存活作为业务结论。

## 8. 参考的成熟工具文档

以下资料用于校准工具语义；本项目的实际结论仍以本地一手产物为准：

- Microsoft Learn：CDB/NTSD 基础、用户态附加与子进程调试：
  https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debugging-using-cdb-and-ntsd
  https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debugging-a-user-mode-process-using-cdb
- Microsoft Learn：Process Monitor 的过滤、进程树、事件属性和原生日志能力：
  https://learn.microsoft.com/en-us/sysinternals/downloads/procmon
- Microsoft Learn：ETW 的 provider/session/consumer 模型以及有限时长 ETL 收集：
  https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/event-tracing-for-windows-simplified
- Oracle VirtualBox User Manual：Guest Control 命令族；若在线手册不可达，以本机 `VBoxManage guestcontrol --help` 和已验证的 `lab.ps1` 行为为准。
