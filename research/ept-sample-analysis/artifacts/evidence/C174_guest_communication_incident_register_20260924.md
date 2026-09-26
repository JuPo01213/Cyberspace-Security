# C174：Guest 通信与证据收割问题记录

日期：2026-09-24
范围：回读本轮对话摘要、HANDOFF、COMMUNICATION_PLAYBOOK、RUN_MANIFEST_genB、C64/C132/C155/C159-C173 相关证据，并记录本轮文档整理期间发生的命令/路径工具错误。

本记录面向本次 EPT/C173 工作的历史复盘。它记录观测到的问题、证据损失或混杂、已验证根因、已采取加固和仍未知事项。不同运行、不同 VM、不同样本状态不合并。Guest 通信失败不构成样本业务结果。

## 1. 状态口径

- 已确认：原始运行记录或可复核文件直接支持症状/原因。
- 部分确认：症状明确，根因仅能定位到一层，仍有多个可能原因。
- 未定位：已发生操作错误，但底层机制未复现或未证明。
- 已加固：有后续验证证据证明修正路径已工作。
- 待复验：已规定修正方法，尚无后续实跑证据。

## 2. 历史 VM 与 GuestControl 通信事故

### I-01：WSL 调 Windows VBoxManage 时 stdout 假空

症状：WSL 互操作中直接调用 VBoxManage.exe、经 cmd.exe /C、经 powershell.exe 都出现 stdout 为空且 exit code 为 0。

影响：空输出曾被当成命令无结果或探针失败，污染健康闸门和进度判断。

确认原因：Windows 子进程 stdout/stderr 没有被当前 WSL interop 稳定捕获。改由 Windows 重定向到文件后可读回。

加固：Windows 侧执行并重定向 stdout/stderr 到文件，再从宿主读取；命令退出码、日志内容和目标状态分别记录。

状态：已加固。

来源：HANDOFF.md §1 约第 37 行；RUN_MANIFEST_genB.md §69 约第 838 行；C155_disk_governance_20260923.md §3.1。

### I-02：截图探针把健康 Guest 判成 0 字节/通道失败

症状：BR1/BR1b 以截图大小 shot=0B 作为主要闸门；VBoxManage screenshotpng 在 SSH 正常时也返回 E_FAIL。另一次截图路径用 WSL 风格绝对路径传给 Windows 命令，输出写到其他位置，宿主当然看不到文件。两种失败被 stat 与 echo 逻辑合并成同一个 0B。

影响：样本没有启动，实际失败的是探针，不是 Guest 健康检查，也不是样本行为。

确认原因：截图接口可在运行中的 VM 失败；跨路径语法不一致；shell 将探针错误吞并成了“没有文件”。

加固：Guest 健康以 Guest 内短探针和重复状态为主；截图只作辅助记录；每个探针分别保留 stderr、退出码和文件存在状态；探针错误不得映射成“探针测得没有”。

状态：已加固，旧 0B 结果作废为健康判据。

来源：RUN_MANIFEST_genB.md §14 附近约第 225 行。

### I-03：Guest 恢复与 NAT/Guest 服务就绪不是同一时刻

症状：恢复快照后 VBox 日志出现 Session 0 is about to close / Stopping all guest processes；NAT Link down 到 Link up 的实测等待为 5 秒、20 秒、35 秒，最慢一轮 917 秒，有轮次未出现 Link up。SSH 与 GuestControl 在同一坏会话里同时不可用。

影响：固定的短预算导致 false gate fail；更危险的是把半拆卸状态快照当成干净、已开机基线后开始实验。

确认原因：快照记录的是 Guest 服务拆卸中间态；VM 的 Running/Saved 状态不代表 NAT、Guest Additions、登录会话已经可用。

加固：恢复后等待本次启动的 Link up；执行至少两次 Guest 内短探针；校验登录与共享面；恢复顺序固定为 poweroff -> restore -> startvm。旧会话日志不得替代本次会话状态。

状态：已建立测量和双探针规则；不同 VM/快照仍须逐次测量。

来源：RUN_MANIFEST_genB.md §C46 约第 234 行；C64_communication_DIAGSSH_20260921.md。

### I-04：GuestControl starting、VERR_DUPLICATE 与控制面 wedge

症状：GuestControl 返回 current status is: starting、Error starting guest session，或连续 VERR_DUPLICATE；但 VM 仍为 Running，Guest Additions 属性也可能显示正常。C160 收尾时发生该症状；C165 后最多持续约 3 分钟，C166 的两分钟请求也进入 starting。

影响：控制命令没返回，收尾探针和结果文件未取得。此状态容易被误当成 Guest 无进程或业务失败。

确认原因：确认了 GuestControl 会话/服务在该运行阶段不可用；具体底层服务/会话资源原因没有全部定位。

加固：不要在 wedge 状态下连续发长命令；先保存已有 spool 和 VBox/宿主日志；用短探针重测。仍未恢复则分类 CONTROL_NOT_READY/CHANNEL_LOST，结束当前轮，按既定基线恢复后再验证。

状态：症状已确认；底层原因部分未定位；恢复步骤已验证过。

来源：HANDOFF.md 约第 291、315 行；RUN_MANIFEST_genB.md §160/§161/§165/§166；C160、C161、C165、C166。

### I-05：GuestControl 账户认证失败，SSH banner 被误当成登录成功

症状：VirtualBox GuestControl login 报 specified user was not able to logon；SSH batch 公钥登录报 Permission denied；另一次只读 TCP 检查收到 SSH banner。

影响：端口开放/banner 只证明 SSH 服务响应，不证明身份认证、命令执行或 Guest 进程收割可用。C168 当时为 NO_SESSIONS，ACK 和 Guest 工具清单均未生成。

确认原因：分别确认了认证失败和没有活动会话；没有证据支持把 banner 当成成功登录。

加固：认证探针与端口/banner 探针分开记账；未验证凭据、活动会话、Guest ACK 前不启动后续阶段；选择一个有已知凭据的控制面并短测。

状态：VirtualBox 候选当时控制面未闭合；后续切换至 Hyper-V PowerShell Direct 并通过。

来源：HANDOFF.md 约第 314-336 行；RUN_MANIFEST_genB.md §78；C168_channel_preflight_host_20260923.json。

### I-06：Guest 共享映射显示存在，但宿主共享源或 Guest 内路径不可用

症状：Guest 有 Z: 映射且 DisplayRoot 指向共享名，但 Z:/probe 不存在；当时宿主 <HOST_PATH>/HexPatch 源目录也不存在。后续 <OTHER_VM_LABEL> 配置显示 writable/automount，但初始目录只有 scaffold/marker，没有 ACK。共享配置存在不等于源路径、Guest 映射和待收割文件均存在。

影响：脚本无法投递或结果没有可写落点；只确认映射配置会给出过度乐观的通道状态。

确认原因：早期为共享源缺失；后期是 scaffold 已建但 Guest 探针尚未登录执行，ACK 仍不存在。属于不同时点的不同问题。

加固：逐项核验 Host source exists、VM share mapping、Guest path exists、Guest read/write、ACK path exists 和 ACK RunId；任何一步失败都独立记录。

状态：旧 VirtualBox 材料面当时不完整；后续 Hyper-V 控制面与 SMB 数据面独立验证。

来源：HANDOFF.md 约第 283、321-343 行；RUN_MANIFEST_genB.md §78；<VM_LABEL>_gen1_channel_preflight_20260924.json。

### I-07：SSH 首次 banner 超时，稍后同链路成功

症状：15 秒 SSH banner exchange 超时，随后把预算延长到 35 秒，同一基线返回完整 tasklist；另一控制诊断在 15 秒返回 PROCESS_LIST。

影响：若按首次短超时就判 Guest 不在线，会误报；反过来，端口/banner 可用也不能证明 GuestControl 或样本运行可用。

根因：已确认存在通道就绪时序差异；未证明所有超时都只是延迟。

加固：首次未就绪保留 raw error；做有界重试和短 Guest 探针；分别记录连接、认证、命令退出、输出字节数。

状态：作为时序差分已记录；SSH 不再作为 C173 主控制面。

来源：C64_communication_DIAGSSH_20260921.md；RUN_MANIFEST_genB.md §10/§22。

### I-08：SCP 目标路径假设错误，轮询超时掩盖立即路径失败

症状：Guest 采集器分离启动成功，之后 13 次 SCP 轮询均超时 75 秒；首轮实际 0 秒返回，原因是本机 SCP 只认 home-relative path，而脚本给了不同路径形式。

影响：收割为 0 字节；耗时轮询并没有产生新的可用证据。

确认原因：路径解析规则与预期不同，且脚本把“立即路径失败”和“文件暂未生成”归为同一种超时。

加固：投递前用小型 canary 验证同一方向的路径和权限；区分 path-not-found、auth failure、transport timeout、empty file、file-not-ready；输出写到已验证路径。

状态：根因已确认；后续收割路径改为共享 spool/VMMDev/离线只读取件的显式验证。

来源：RUN_MANIFEST_genB.md §CTRL2b/CTRL3 约第 236-237 行。

### I-09：不同数据收割通道并未共享相同失败边界

症状：SCP、GuestControl copyfrom、共享目录或 Guest 本地磁盘在不同轮次有不同可用性。C132 控制和 SSH 都失联，Guest 可能已经写入 PRE/MID/POST；C67 大转储留在 Guest、共享目录只回写日志；C159 共享数据面成功产出完整日志和 PRE/POST，即使 GuestControl 收尾探针 later not-ready。

影响：单一收割通道失败造成数据不可见；Guest 报出的文件大小不能当成 Host 已取得的可解析文件。

加固：控制面、实时共享 spool、PSSession/GuestControl copy、离线挂盘分别测试和标识；小文件实时镜像；大文件预设上限并优先 Guest 内摘要化；记录 Host 是否实际持有文件、大小和 SHA-256。

状态：三平面方案部分验证成功；各平台需单独做 canary。

来源：C67、C132、C159、C164、C173 channel evidence。

### I-10：分离进程仍依赖错误的目录与采集位置

症状：外层 runner 声称已经后台启动，但共享 spool 没有结果；Guest 文件可能写入默认当前目录、非预期用户 home 或 Guest 本地盘。

影响：有 PID 不等于状态文件位于 Host 可见位置；最终只能恢复 VM 后留未知字段。

确认来源：C165 的目录和会话生命周期问题；CTRL2b 的 home-relative 路径问题；C161 目标父目录在快照中不存在。

加固：runner 启动前自己创建 OBS_ROOT；记录当前目录、绝对路径、ACL、文件创建探针；先写一个 canary，再走真实阶段；不要依赖交互式 shell 当前目录。

状态：已写入现行运行方法；每个新 Guest 镜像仍要复验。

### I-11：GuestControl 会话结束杀掉前台 runner

症状：C165 GuestControl 会话在约 4 秒后结束，同一会话启动的 runner 一并被杀；只有 BOOT/PRE/部分过程事件，post/delta/done 未生成。C166 GuestControl 两分钟等待也没有收回 native_probe.log。

影响：目标字段全部未知；无法判断自然退出、runner 被杀或控制通道先断。

确认根因：runner 生命周期绑定 GuestControl 前台会话；GuestControl 断开具有进程树影响。

加固：计划任务/服务/真正脱离会话启动，或运行期间本地 spool 并允许独立收割；设置 Guest watchdog 和 done 状态；控制面不要持续等 stdout。

状态：根因和整改方向已确认；C173 只验证短命令和短时 CDB smoke，长任务脱离仍需按实际 runner 复验。

来源：C165_natural_deployment_vs_debugger_20260923.md；C166_guest_harness_no_harvest_20260923.md；RUN_MANIFEST_genB.md §77。

### I-12：WMI 放入短周期轮询导致观测器拖慢

症状：C165 runner 每 3 秒调用 Get-CimInstance Win32_Process，采集本身阻塞窗口并拖慢阶段推进。

影响：heartbeat 间隔和 deadline 不再代表预期采样时序；窗口可能还没观测完便失去通道。

确认原因：所用 WMI API 相较于本任务需要的进程字段明显偏慢。

加固：高频面使用 Get-Process/轻量 API；WMI/CIM 降频；把采集耗时写入心跳。

状态：整改已明确，后续过程查询以轻量 API 为主。

来源：C165 §发现与下一步；RUN_MANIFEST_genB.md §80。

### I-13：长时间运行和大转储让 Guest/控制面一起失活

症状：C132 Guest runner 启动后 GuestControl starting、SSH banner timeout、VBox.log 出现 Guest unresponsive/catch-up，ACPI 关机无响应。C67 Guest 报告 ProcDump 生成约 100 MB 文件后 SSH/Guest Additions 失联；Host 只拿到日志，未拿到可解析 dump。

影响：自然退出码、PRE/POST、完整日志、转储均未收齐，后来执行硬断电。

确认原因：Guest/虚拟化层资源或响应能力在大负载运行期间丧失；确切触发因素未完全定位。报告的 Guest 文件大小不证明 Host 收到完整文件。

加固：限额 ETL/PML/dump；大文件先压缩/摘要化并独立通道收割；监控 CPU/IO/heartbeat；deadline 到时先收割再结束；硬断电只作为 VM 收尾状态记录，不作为 Guest 自然退出。

状态：数据负载是已观察相关因素，底层失活根因未完全确认。

来源：C67_core_memory_capture_20260921.md；C132_real_decode_arm_instrument_failure_20260922.md；RUN_MANIFEST_genB.md §48。

### I-14：Guest 进程树终止后 VirtualBox Host 端残留 VBoxHeadless

症状：GuestControl/Guest 服务失效后，VM 显示 poweroff，但 startvm 报 VM session was closed before any attempt to power it on；发现属于旧 VM 的 stale VBoxHeadless 链。

影响：恢复 VM 和通信的动作本身失败，进一步拉长控制面不可用时间。

确认原因：本 VM 的 VirtualBox 进程链残留；已通过进程命令行归属核验后清理并恢复。

加固：只针对 VM 所属命令行/父子 PID 清理 stale 进程；恢复后检查 VM state、Guest Additions runlevel、NAT Link，并做两次 Guest 短探针。不得终止其他 VM 进程。

来源：C165 §恢复；RUN_MANIFEST_genB.md §80。

### I-15：GuestAdditions 启动阶段卡在低 runlevel

症状：stale VBoxHeadless 清理后重启，GuestAdditionsRunLevel=1 持续约 3 分钟无进展；随后从既有 clean snapshot 恢复后 runlevel=3，短探针成功。

影响：VM Running 但 GuestControl 不可用，不能进入实验阶段。

根因：启动后的 Guest Additions 服务没有完成就绪；更深层驱动/启动原因未确认。

加固：设置 Guest agent readiness deadline；runlevel 未达预期时只记录 CONTROL_NOT_READY，恢复已验证基线并重复短探针。

来源：C165 §恢复记录。

### I-16：VirtualBox startvm 在 Guest 执行前返回 E_FAIL

症状：C116 startvm --type headless 返回 VM session was closed before any attempt to power on；没有 CDB、退出码或 Guest 事件。

影响：属于宿主 VM session/startup 失败，不是样本运行失败。

确认原因：已知故障发生在 Guest 代码执行前；底层 VirtualBox session 关闭原因未进一步定位。

加固：分类 INVALID_INSTRUMENT / VM_SESSION_CLOSED_BEFORE_START；验证 VM state、VBoxHeadless 所属链和基线；没有新诊断信息时不重复同一启动调用。

来源：C116_runtime_stack_start_instrument_failure_20260921.md；RUN_MANIFEST_genB.md §43。

### I-17：子进程名过滤器与实际部署名不一致

症状：过滤器只看 EPT_*.exe，但真实部署名是 Hardware.exe；改成 cpr:Hardware.exe 后仍未建立可靠子进程观察。

影响：C134 漏检真实部署对象；C135 过滤调整后仍无可靠业务 marker；C136 外层启动后控制面失活。

已确认与未确认：C134 名称不匹配已确认；C135 证明仅改过滤名不够；C136 的部署/后续状态因通道断开未知。没有证据证明“没有子进程”。

加固：全量收集创建事件和 PPID，不用 cpr: 名称过滤作为唯一观察器；先在 benign child smoke 验证观察器；运行后离线筛选。

来源：C134、C135、C136；RUN_MANIFEST_genB.md §50-52。

### I-18：调试器改变自然部署/子进程行为

症状：同样输入的调试器轮未观察到子进程；无调试器自然轮观察到父 PID 创建子进程。自然轮随后因 GuestControl 断开而未完成后态收割。

影响：调试器轮与自然轮不可拼成同一次行为；观测到的相关差异不足以直接认定反调试因果。

确认原因：确证“带/不带 debugger 的观测不同”；CDB 是否抑制创建事件、改变时序或改变分支仍未排除。

加固：自然路径和调试器路径分 RUN_ID、分采集器、分结论；自然路径独立记录进程创建、文件部署和驱动变化；在同一类运行里完成归因。

状态：差异已确认，因果未定。

来源：C165_natural_deployment_vs_debugger_20260923.md；RUN_MANIFEST_genB.md §79。

### I-19：子进程初始断点异常后过早退出 CDB

症状：子进程初始 int 3 时脚本提前发 q，导致 child breakpoint 注入尚未运行即结束，属于 INVALID_INSTRUMENT。

影响：没有 target seam 观测；不能以“无 hit”解释样本。

加固：先在 benign child 验证初始断点处理和继续策略；按项目实测改为 ibp/正确的初始断点过滤；完整记录 child create 到 child attach 的事件。

状态：错误与修复方式已记录；修复后的 seam 未命中是另一独立结果。

来源：RUN_MANIFEST_genB.md §39 附近约第 546 行。

### I-20：CDB 复合 breakpoint action 语法失败

症状：一个 action 中串接 bc/eb/db/g 等命令出现 Syntax error；元数据仍写着 patch intent。

影响：动作链没有执行，现场字节保持原状；声明配置不能证明写入。

确认原因：CDB action 语法不接受该复合写法。

加固：使用 -cf/.cmd 命令文件，每行一个命令；动作分步执行并读回；计划、命令回显、写后字节、目标实际执行分别记账。

状态：问题已复现；命令文件已成为现行规范。

来源：C140_rc00_dispatch_ret_patch_instrument_failure_20260922.md；COMMUNICATION_PLAYBOOK.md §3.1。

### I-21：CDB 子进程观测失败后错误地尝试更多过滤器变体

症状：一个过滤名称漏事件，换成直接目标或另一个过滤器仍无法收获可靠 CDB/业务 marker；之后 Guest 通道在外层启动后失活。

影响：不能区分过滤器错误、观察器未挂接、子进程未创建和通道中断。

加固：停止盲目枚举过滤器字符串；切换为不依赖单一名称过滤的创建事件观察；先建立 benign process chain smoke，再将同一观测器用于目标运行。

来源：C134-C137；RUN_MANIFEST_genB.md §50-53。

### I-22：超时前有真实 marker，但完成面/收尾文件未生成

症状：C145 CDB 已到达内部 call target，runner spool 停在 LAUNCH；CDB_DONE、POST_STATE、run_meta、post_state、DONE 均未生成。

影响：可以保留“已观察到 call target”，不能声称函数返回、业务阶段完成或目标正常结束。

根因：数据/完成平面在运行期间中断；确切是 Guest runner、共享镜像还是 Guest 服务先断，记录未能定位。

加固：入口、阶段 marker、heartbeat 和 pre/post 使用 Guest 本地原子文件；小型 spool 实时镜像；控制面异常后从独立数据面收割；完成面缺失时保留 CHANNEL_LOST/PARTIAL。

来源：C145_rc00_internal_calltarget_observed_channel_loss_20260922.md；RUN_MANIFEST_genB.md §61。

### I-23：有界窗口超时与“收尾成功”是两个状态

症状：多个 CDB 运行 status=WAIT_TIMEOUT，但 Guest runner 已完整写 pre/post/run_meta；另一些运行超时且没有任何 done/post 文件。

影响：把两者都叫 timeout 会丢失关键差别；把有 spool 的 timeout当成业务完成也不正确。

加固：分别记录 deadline_reached、runner_completed、artifacts_complete、cdb_exit_code 和 VM state。WAIT_TIMEOUT 表示业务窗口到期；HARVEST_COMPLETE/INSTRUMENT_FAILURE 是独立字段。

状态：现行台账已逐步区分。

来源：C146-C150、C156、C159-C161、C164-C166。

### I-24：run_meta marker 与 CDB 原始日志相矛盾

症状：C157 对全文做 substring 搜索，把 breakpoint 定义回显成命中；C159/C160 又出现 markers 为空对象，但原始日志中有独立命中行。

影响：同一个 parser 同时可产生假阳性和假阴性；run_meta 单独不可作为事件权威。

加固：保留原始 stdout；以去 prompt 后独立整行 marker 为主；parser 用正/负对照测试；摘要附原始行号与事件上下文。

来源：C157、C159、C160、C161。

### I-25：同一 RUN_ID/目录被失败重试复用

症状：C161 两次前置失败与后续有效 CDB 运行复用了 run id/目录，run_meta 存有合并或覆盖的历史状态。

影响：时间线和 marker 计数无法唯一归因到一次启动。

加固：每次 Guest 启动尝试各自唯一 RUN_ID；目录预创建；存在旧 ACK/DONE 时拒绝启动；旧失败件保留独立目录，不在新轮覆盖。

来源：C161_tail_edge_observe_20260923E.md §runner failure/history contamination。

### I-26：Guest 初始观察目录缺失，CDB 实际未启动

症状：C161 首次因为父目录不存在无法写状态文件；第二次投递版本也漏了目录创建；前台 GuestControl 随后超时。CDB 没有执行。

影响：启动失败一度与目标未到达混在一起。

确认原因：脚本依赖快照已有目录，但该目录不存在；第二次修复没有进入 Guest 投递副本。

加固：Guest runner 开头自建 OBS_ROOT 并验证可写；投递后比对 Host/Guest 脚本哈希；只在 RUNNER_READY marker 出现后才进入 debugger phase。

状态：根因已确认；新脚本需要继续执行源/Guest 哈希比对。

来源：C161_tail_edge_observe_20260923E.md §32。

### I-27：AV 事件缺少上下文，日志看起来像目标错误

症状：C150 只记录访问违例地址，没有寄存器/栈；C142 有上下文采集但 second-chance/runner deadline 仍须分类。

影响：不能归因 AV 是 Guest/调试器/目标运行时哪一侧，也不能由异常事件补成业务结论。

加固：AV 命中一次性采集 RIP/RSP、通用寄存器、栈、当前指令、线程和模块归属，再退出或按已定义策略继续；保留 first/second chance、deadline 和 exit code。

来源：C142_rc00_forced_return_av_context_20260922.md；C150_rc00_high_address_av_without_context_20260922.md。

## 3. VM 启动与 Guest 就绪问题

### I-28：Gen2/DVD/UEFI 启动路线未进入 Guest

症状：Windows ISO/DVD 显示 UEFI boot loader failed；离线 Gen2 VHDX 启动到 winload.efi 报 0xc000000e，恢复环境出现 0xc0000098。Guest 内通信探针没有执行。

影响：这是 VM/Guest 启动层失败，不是 GuestControl 或样本运行结论。

加固：保留失败路线证据；切换到成功启动并有 checkpoint 的 Guest generation；新环境先验证登录、短命令和恢复。

来源：C173_mature_workflow_assessment_20260924.md；RUN_MANIFEST_genB.md C173 closure。

### I-29：Windows 安装停滞/Guest Additions 未就绪

症状：Windows 安装器停在 78%；Guest Additions、Guest OS properties、ACK 均缺失。另有 Guest 重启后 runlevel 1 长时间不进展。

影响：安装画面或 VM Running 不等于 Guest ready；不能执行 GuestControl 样本流程。

加固：状态标为 CONTROL_NOT_READY/INSTALL_STALLED；保留画面、VBox 日志和 VM 状态；恢复/重装使用新 run id；先通过 Guest 登录、Guest agent ready 和短探针。

来源：C171_rebuild_method_and_stall78_20260923.md；C165 restore note。

## 4. C173 已验证修复与仍存问题

### I-30：CDB 文件存在但非交互 smoke 未能回收输出

症状：初始 PowerShell Direct 非交互 smoke 没有可收割 CDB 输出；文件身份/hash 已知，但 runtime 状态未知。

加固及验证：改为 Guest 本地写 .cf/stdout/stderr/summary，再由 PowerShell Direct PSSession 复制；CDB 附加 benign ping.exe，干净轮有 attach marker、ping module、thread listing，stderr=0；Guest/Host 残留 cdb/ping/目标进程为零。

状态：CDB attach 与文件收割路径已通过 benign smoke；CDB 数值 exit code 没有可靠回收，记录 EXITED 状态而不伪造数值。

来源：<VM_LABEL>_gen1_debugger_smoke_20260924.json；<VM_LABEL>_gen1_cdb_benign_smoke_20260924_02/。

### I-31：CDB 参数 -accepteula 产生扩展加载噪声

症状：第一次 smoke 将 -accepteula 传给 CDB，CDB 将其解释为 ccepteula 扩展名并输出 LoadLibrary 错误；随后仍实际附加 ping.exe 并执行命令。

影响：初次日志带参数噪声，不能用作干净 smoke。

加固：重跑时移除该参数；命令文件正常执行、stdout 有 marker/module/thread、stderr 0。保留第一轮作为“参数误用”证据，不覆盖干净轮。

来源：C173 CDB smoke 01/02 和 <VM_LABEL>_gen1_debugger_smoke_20260924.json。

### I-32：PowerShell Direct 会话作用域没有 SMB 磁盘映射

症状：交互式 ACK 曾通过独立 SMB reader 访问样本；后续 <VM_USER> PSSession 中 EPTS: drive 不存在。改用 UNC 的一次复核又因路径字符串/会话访问上下文没有建立，报告 Guest path not found。

影响：这次复核没有读取样本，不能写成 hash mismatch，也不能推翻之前 Guest ACK。

加固：状态记 DEFERRED_TO_EXISTING_ACK；宿主权威 SHA-256 与既有 Guest ACK SHA-256 再比较，一致。未来若要在 PSSession 中复验，先显式使用 DATA_USER 建立 SMB session/share mapping，再做只读 canary。

状态：既有 ACK 与 Host authority 一致；当前 PSSession 的 Guest 访问未复验。

来源：C173_post_debugger_preflight_20260924.json；<VM_LABEL>_gen1_channel_preflight_20260924.json。

### I-33：Host PowerShell 与 Guest 内 PowerShell 结果字段不一致

症状：远程 Start-Process 后 CDB WaitForExit 报 EXITED，但远程 Process 对象返回的 ExitCode 为 null；部分 Invoke-Command 多行输入在当前调用包装中无可见输出。

影响：工具运行状态可确认，精确退出码字段尚未闭合。

确认程度：已观察到。究竟是远程对象序列化、进程刷新时序还是调用包装输出处理所致，未定位。

加固：Guest 端在本地读取/刷新 Process 对象并写 summary.json；Host 复制文件验证；如退出码仍空，状态保存为 EXITED / EXIT_CODE_NOT_OBSERVED，不以 0 填充。

来源：<VM_LABEL>_gen1_cdb_benign_smoke_20260924_01/02 的 summary.json。

## 5. 本轮文档/命令操作自身发生的问题

以下为本次助手在 shell、PowerShell 和文档工具之间切换时的实际操作错误，不是 Guest 故障，也不属于目标证据。

### T-01：把 PowerShell 命令直接交给 Bash

症状：Get-Command、Select-Object、Format-List 被 Bash 当作命令，返回 command not found。

原因：shell 上下文是 Bash，未显式调用 pwsh.exe。

修正：之后显式使用 pwsh.exe -NoProfile -Command；PowerShell 与 Bash 命令按工具边界分开。

### T-02：Bash 重定向写入 PowerShell 的 $null

症状：2>$null 被 Bash 解释为重定向到名为 $null 的文件，报告 ambiguous redirect。

原因：把 PowerShell 的错误流重定向语法带入 Bash。

修正：Bash 使用 2>/dev/null；PowerShell 命令放入 pwsh.exe 命令上下文。

### T-03：Windows 路径反斜杠写成无效正则

症状：rg 的文件匹配表达式有 unclosed group；后续 literal 路径 wildcard C173* 又被 Windows 文件系统报路径语法错。

原因：正则层、Bash 层和 Windows 路径层的反斜杠规则混淆。

修正：文件枚举用 rg --files/find；固定字符串用 rg -F；不把 Windows 路径当 regex separator。

### T-04：Bash heredoc 传给 PowerShell 命令产生空输出

症状：经调用包装器执行 pwsh.exe -Command - <<'PS' 的几次多行命令没有可见输出；改为显式 pwsh.exe -Command '...' 后 PSSession 探针成功。

原因：该组合的 stdin/命令包装行为未验证；没有证据证明 Guest 命令已经执行。

修正：使用已验证的单行 -Command 或保存 .ps1 文件再执行；要求显式返回 run_id 和结果 JSON。

### T-05：apply_patch 在当前 Bash 环境不可用

症状：两次尝试通过 bash 调 apply_patch 报 command not found，文档文件没有创建。

原因：该 shell PATH 未提供 apply_patch；第一次调用的模板字符串也被工具解析层提前解释。

修正：转用 codemode.write 创建新的全局 skill；项目级 SKILL.md 从未生成。此后对新文件使用单独路径和写后读取验证。

### T-06：JavaScript 模板字符串与 Markdown 反引号冲突

症状：把含 <HOST_PATH>\ 路径和 Markdown inline code 的长补丁放进 JS template literal，工具调用在执行前报 Unexpected identifier；没有任何 shell 命令运行。

原因：内容中的反引号提前结束模板字符串。

修正：废弃该补丁调用；将全局 skill 写入独立目标文件；写后读取并修复格式。

### T-07：多行 shell 文档补丁 heredoc 终止符不匹配

症状：Bash 报 heredoc wanted PATCH、apply_patch not found；长补丁没有执行。

原因：调用参数在模板文本/换行层被截断或补丁工具缺失。

修正：项目级补丁未落盘；确认 EPT method/SKILL.md 不存在后，按用户澄清把通用方法放入用户级全局 skill。

### T-08：远程 JSON PSCustomObject 不允许动态添加字段

症状：给 ConvertFrom-Json 返回的固定 PSCustomObject 动态赋值 sample_hash_state 和 sample_reconfirmation 报 SetValueInvocationException。

原因：目标属性不存在且该对象不是可扩展属性表。

修正：用 ConvertFrom-Json -AsHashtable 后增加属性；复读文件并核验 Host hash 与原 Guest ACK hash。

### T-09：PowerShell UNC 映射与远程会话作用域未先验证

症状：EPTS: 在新的 PSSession 中不存在；UNC 检查经过一次错误转义后被解释成 Guest 本地 C: 路径。

原因：会话映射不共享，且调用层的反斜杠转义没有先用 canary 验证。

修正：不把错误结果写成样本 hash mismatch；记为 DEFERRED_TO_EXISTING_ACK；未来先由数据账户显式建立映射并读小文件。

### T-10：统计命令的 PowerShell 嵌套引号解析错误

症状：用于统计记录标题数量的 `pwsh.exe -Command` 包装命令在管道和脚本块处返回 ParserError；统计结果为空。

原因：Bash、JSON 字符串和 PowerShell 双引号/管道同时嵌套，变量与管道边界在调用层被提前解析。

影响：只影响本次计数校验，不影响已写入的通信记录或 Guest 证据。

修正：改用独立的 `rg -c` 与 `tail` 命令完成计数和末尾核验；保留原始错误，不把它写成 Guest 或目标运行故障。

## 6. 目前采用的总加固

1. 先确认 Guest 已开机并健康，再确认控制面、数据面和完成面；三者不互相替代。
2. 使用短健康探针，不用截图、空 stdout、端口 banner 或 GuestControl list sessions 单独判断 Guest 状态。
3. 长任务脱离控制会话；Guest 本地 spool 是首选状态源，外部 stdout 只作辅助。
4. Host/Guest 运行前后均记录进程面；清理只针对本轮 PID/树。
5. 每次尝试独立 RUN_ID/目录；Guest 脚本自建目录并写 READY marker。
6. 数据回收先做 canary；文件没取到先区分权限、路径、传输、时序和 Guest 未写入。
7. CDB/调试器先 benign smoke，再运行目标；原始日志整行 marker 解析，命令回显不计事件。
8. 每阶段设硬 deadline；收尾先收割、后关机/恢复；任何未知保持未知。
9. Host/Guest 样本 identity、权限上下文、数据路径 hash 和业务输入状态分别记账。
10. 没有业务输入时保持 launch held；环境和工具可保持 ready，但不启动目标。

## 7. 现存未解问题

- 旧 VirtualBox GuestControl wedge 的底层服务原因没有完整归因；现有规则是识别、分类和有界恢复。
- C165/C166 证明前台会话可杀掉 runner；长期 runner 的计划任务/脱离会话路径应按实际平台另做 smoke。
- GuestControl/SPICE/SMB/SSH 的账号与磁盘映射作用域仍需逐会话验证。
- Guest 上报的自然退出码、CDB exit code 和大文件是否完整到达 Host 必须由 Host 侧文件/哈希验证，不能只信 Guest summary。
- Hyper-V Gen1 的 PowerShell Direct 与 CDB 短 smoke 已证明；长时运行与中断恢复应在真实 runner 上单独验证。

## 8. 主要来源

- <HOST_PATH>/EPT/method/COMMUNICATION_PLAYBOOK.md
- <HOST_PATH>/EPT/method/HANDOFF.md
- <HOST_PATH>/EPT/RUN_MANIFEST_genB.md，尤其 C7/C46/CTRL2b、C64/C67/C132、C134-C145、C155-C166、C168-C173 条目
- <HOST_PATH>/EPT/artifacts/evidence/C64_communication_DIAGSSH_20260921.md
- <HOST_PATH>/EPT/artifacts/evidence/C67_core_memory_capture_20260921.md
- <HOST_PATH>/EPT/artifacts/evidence/C132_real_decode_arm_instrument_failure_20260922.md
- <HOST_PATH>/EPT/artifacts/evidence/C134-C136、C140、C145、C155-C157、C159-C161、C164-C166、C168、C171、C173 相关证据
- <VM_LABEL>_gen1_debugger_smoke_20260924.json 与 C173_post_debugger_preflight_20260924.json
- <HOST_PATH>/Users/<USER>/.codebuddy/skills/guest-communication-workbench/SKILL.md
