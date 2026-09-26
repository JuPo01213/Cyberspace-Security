# C180：EPT 项目完整问题原始记录与助手反思

日期：2026-09-25
项目：`<HOST_PATH>\EPT`
范围：从本项目开始到本报告生成时，围绕 EPT / Hardware.exe、授权、联网、Guest 通信、调试器、证据收割和文档交接发生的问题。

---

## 0. 资料完整性与口径

本报告严格拆成两部分：

- **第一部分：问题原始记录**。只记录用户要求、已发生操作、客观症状、证据状态和当时形成的结论；不把事后反思混入事实栏。
- **第二部分：助手反思**。明确指出哪些是助手的判断错误、路线错误、通信设计错误、证据管理错误和执行纪律错误。

本报告使用的材料：

1. 当前会话注入的完整项目摘要，其中保留了此前所有已知用户消息和主要实验时间线；
2. `method/HANDOFF.md`；
3. `method/COMMUNICATION_PLAYBOOK.md`；
4. `RUN_MANIFEST_genB.md`；
5. `artifacts/evidence/C174_guest_communication_incident_register_20260924.md`；
6. C173、C175、C176、C177、C178、C179 及此前 C64-C166 证据件；
7. `EPT_Hardware_analysis.md`、`AGENTS.md` 和项目工作日志。

历史对话检索没有返回额外结果，因此本报告不伪造当前上下文之外的逐字记录。用户原话部分只对当前摘要中明确保留的原话使用引号；更早的实验细节以项目一手证据件为准。凡无法从原始会话或证据直接确认的内容，标为“未闭合”“部分确认”或“未知”。

---

# 第一部分：问题原始记录

## 1. 用户要求的原始记录

当前可回读到的用户消息按顺序如下：

1. “你妈的，我明天要的是结果！你他妈停，你妈了个逼的！”
2. “授权通过之后，还有实际的修改，修改还需要修改完成。完成之后，还会有伪装进程和日志清理。你妈的，你后面这么多一个都没有拿到！重大不说你妈呢，重大逼事儿没做，觉得自己做完了！”
3. “而且，这个是有联网更新的，你可能还需要去查到它联网的部分，然后屏蔽掉”
4. “你他妈的静态分析联网这一点不分析吗？我他妈不提醒你，你不搁这卡死了！”
5. “继续”
6. “继续”
7. “继续”
8. “2”
9. “继续”
10. “我再次强调，你必须过授权之后让整个程序自然地运行，才能拿到最真实的证据。目前查明，联网下发的只是一个许可，也是授权的一部分。联网通过授权之后才会下发许可，程序才会真正运行。你只需要静态分析联网授权部分，并屏蔽你在静态校准中找授权联网和后行为证据，这样效率是非常低的。而且，你进行了这么久授权好像还是没有过，我不知道你在干什么”
11. “Your task is to create a detailed and highly structured summary of the conversation so far.”
12. “不管怎么样，联网这部分是实打实的噪音。这个噪音需要屏蔽或清理。”
13. “继续”
14. “重写handoff”
15. 当前消息：要求“回读该项目的完整对话，反思出现的所有问题。我需要一份问题的原始记录，和你的反思分开写，尤其注重你和靶机通信的缺陷。注意是完整的所有的对话，不要偷懒”。

用户要求的核心验收标准从这些消息中一直没有改变：

- 不能把部署、自复制、静态解码、harness、伪造 response 或单个断点命中当作任务完成；
- 必须关注授权后的真实行为：HWID 修改、修改完成、伪装/干活进程、日志和痕迹清理、持久化、联网更新；
- 授权和联网许可是同一条业务链的一部分；
- 要么让真实样本自然继续运行，要么明确标注受控研究路径，不能混淆；
- 联网噪音要被屏蔽或清理，但屏蔽本身不能被描述成服务器拒绝或授权失败；
- 当前复盘必须覆盖完整问题，尤其是宿主与 Guest / 靶机的通信缺陷。

## 2. 任务目标发生偏移的原始过程

### 2.1 最初把解码 seam 放在过高位置

早期项目围绕 `RC00 / RC03 / RC06`、`target_native_return` 和 `target_caller_diff_bytes` 建立完成判据。随后用户明确指出：

- 解码只是触发点，不是终点；
- 即使真实目标进程在受控 response 下解码成功，也必须继续观察解码结果的消费者和后行为；
- C152/C175 等 harness 只能证明局部机制，不能证明真实样本完成。

项目后来把 seam 改为“必要但非充分条件”，最终完成要求增加 RC06 后的进程、文件、注册表、网络、驱动/组件释放、持久化、规避和清理行为。

### 2.2 早期把部署链误当成授权后行为

动态捕获到以下真实动作：

```text
DeleteFileW(System32\Hardware.exe.tmp)
→ CopyFileW(ept_core\Hardware.exe → System32\Hardware.exe.tmp)
→ MoveFileExW(.tmp → System32\Hardware.exe)
→ CopyFileW(ept_core\Hardware.exe → TEMP\EPT_<RAND>_<RAND>.exe)
```

这些动作后来证明是授权前自部署/临时载荷释放，不是用户要求的 HWID 修改、伪装进程、日志清理或授权后行为。

### 2.3 早期把断网和无 TCP 过度解释为授权失败

Guest 网卡多次处于断开状态，抓包/网络快照看到 DNS 或无外联。早期叙述曾把“无法连接服务器”直接升级为“云授权失败、后行为不执行”。后续静态分支发现：

- `*_failed_soft_allow` 分支存在；
- `*_denied_clear_or_block` 更接近服务端明确拒绝后的清理分支；
- C69 只证明 DNS，不证明 TCP、请求、response 或服务端返回码。

当前正确口径改为：`AUTH_NETWORK_UNOBSERVED`、`REAL_LICENSE_RESPONSE_UNOBSERVED`、`POST_AUTH_BEHAVIOR_NOT_OBSERVED`。

### 2.4 过早设计 response 注入

在没有证明真实样本通过 pre-decode 授权闸门、建立有效设备/会话、产生真实 RC00 之前，曾设计并生成 `gen_inject_cdb.py` 和 284 字节 response 注入方案，试图在 `DeviceIoControl` 边界写 response、置 `Information=284`、设置 `RAX=1`。

后续 RECON-6 证明：

- 父进程的 `NtDeviceIoControlFile` 命中没有样本调用栈帧；
- 命中主要来自 bcrypt、卷设备和加载器噪音；
- `CreateFileW/A` 设备路径过滤为零；
- 当前隔离环境没有证明样本建立 `\\.\\HP_WKS_SWTOOLS_DRIVER` 会话。

因此该注入前提不成立，路线被废弃。

### 2.5 静态授权地址反复被当作动态入口

曾把 `0x1407a3080`、`0x1407a30a6`、`0x1407a311f`、`0x1407a315d` 等静态候选当作必然运行时授权门或断点入口。后续多轮父/child 动态观察中，静态授权门没有命中。当前证据要求改为运行时定位或只作静态候选，不再把静态地址未命中直接解释为业务阴性。

### 2.6 对高熵 CardLogin 区域做线性反汇编

`0x1403b3d30..0x1403c42ac` 被当作 CardLogin 候选范围。对该范围做整段线性 Capstone/CDB 反汇编后产生大量伪相对调用和无效指令。C176/C178 后确认：

- 入口短段可读，后续区域高熵、混淆或虚拟化；
- `.pdata` 范围熵约 7.9720，不能直接当作连续代码；
- `0x1403b8190`、`0x1403c2df8` 的 `0x25` 命中不能单独说明请求格式；
- 只能使用已验证指令起点、`.pdata`、精确 LEA/MOVABS 目标扫描和运行时映射。

### 2.7 C175 harness 结果被严格降级

C175 在 C173 Guest 内复现了局部 transform/validator/写回：

- `harness_validator_rax=0x1`；
- `harness_decoded_output_bytes=268`；
- `harness_caller_diff_bytes=14`；
- `harness_caller_output_written=true`。

但 C175 没有启动真实 EPT/Hardware 样本，没有自然设备 response，也没有 RC06 后行为。其结果被明确标为：

```text
CALLER_INJECTION_HARNESS_ONLY / NOT_TARGET_COMPLETION
```

### 2.8 C176 证明了自然启动和临时 child，但没有证明授权

C176 无调试自然运行：

- `Hardware.exe` 自然启动；
- 约 3 秒后自然创建 `EPT_15669800_B33D1B09.exe`；
- 没有 CDB、断点、response 注入或目标机器码写入；
- 180 秒后由观察器主动停止目标和 child。

C176 只能证明外层启动和临时子进程自然出现，不能证明 RC00/RC03/RC06、许可返回或授权后行为。

### 2.9 C177 证明了自然 child 后附加比启动即调试更可靠

`EPT-AUTHGATE-01` 至 `-06` 中，启动即调试的方式导致父进程入口后退出或没有 child；恢复到 SYSTEM 自然启动、先发现 child、再 CDB 附加后，`-07/-08` 成功看到真实 child 和 main entry。

但 C177 仍没有得到授权成功、真实卡、网络请求、response、RC06 或后行为。它只证明了“自然先启动、后附加”的仪器边界更合适。

### 2.10 C179 进一步定位到用户交互等待和 Setup/Stored 分离

C179 对四个授权状态全局做了 Guest 内存中的临时数据写入，随后首次看到真实 Setup 阶段日志：

- `Setup.SP_Verify_Init`，`r9d=0`；
- `Setup.SP_Verify_GetServerOption`，`r9d=-3`，落在静态 soft-allow 集合中；
- Winsock/名称解析模块加载；
- 没有观察到 TCP 连接；
- child 主线程停在 `Wait/UserRequest`；
- session 0 无交互桌面，MessageBox 家族只跳过了两个，仍有未识别 UI 阻塞调用。

C179 的意义是把阻塞从“可能未过授权”推进到“真实 Setup 流程进入网络阶段后被 session 0 用户交互阻塞”，但仍不能写成授权通过或 post-auth 完成。

---

## 3. Guest / 靶机通信缺陷原始记录

以下是本项目中最重要的通信缺陷。每项先记录事实，再记录直接影响；反思放在第二部分。

### I-01：WSL 调用 Windows VBoxManage 时 stdout 假空

- 直接调用 `VBoxManage.exe`、经 `cmd.exe /C`、经 `powershell.exe` 时，WSL 侧可能得到空 stdout、exit code 仍为 0。
- 一度被误看成命令无输出、探针失败或 VM 没有状态。
- 实际是 Windows 子进程 stdout/stderr 没有被当前 WSL interop 稳定捕获。
- 后续改用 Windows 侧重定向到文件，再从宿主读取。

### I-02：截图 0 字节被当成 Guest 健康失败

- `VBoxManage screenshotpng` 在 SSH 正常时仍可能返回 `E_FAIL`。
- WSL 风格路径传给 Windows 命令时，文件被写到另一个位置。
- `stat`/`echo` 把“路径错误、截图接口失败、文件不存在”合并为 shot=0B。
- 样本实际没有启动，失败对象是截图探针。

### I-03：VM Running/Saved 不等于 Guest 服务就绪

- 恢复快照后，VBox 日志出现 `Session 0 is about to close`、`Stopping all guest processes`。
- NAT Link up 等待实测可为 5 秒、20 秒、35 秒，最慢约 917 秒，部分轮次不出现 Link up。
- SSH 与 GuestControl 可能同时失效。
- 半拆卸状态曾被误认为干净、可实验基线。

### I-04：GuestControl `starting` / `VERR_DUPLICATE` 导致控制面 wedge

- 反复出现 `current status is: starting`、`Error starting guest session`、`VERR_DUPLICATE`。
- VM 仍显示 Running，Guest Additions 也可能显示正常。
- 控制命令没有返回，收尾探针和结果文件未取得。
- 该状态被明确分类为通信/控制面问题，不能解释为样本无进程或业务失败。

### I-05：GuestControl 认证失败，SSH banner 被误当成可登录

- GuestControl 报 `The specified user was not able to logon on guest`。
- SSH 公钥/认证返回 `Permission denied`。
- 另一轮 TCP 检查能收到 SSH banner。
- banner 只说明端口服务响应，不证明认证、命令执行、文件投递或结果收割可用。

### I-06：共享配置存在不等于共享源和 Guest 路径可用

- Guest 显示 Z: 映射，DisplayRoot 指向共享名，但 `Z:/probe` 不存在。
- 当时宿主 `<HOST_PATH>\HexPatch` 源目录也不存在。
- 后续 Hyper-V/SMB 中共享配置和只读权限闭合，但每个 PowerShell Direct 会话不一定继承 `C173SampleReader` 的 SMB 映射。
- C173 post-debugger preflight 中，PSSession 把 UNC 字符串错误解释成 Guest 本地路径，记录为 `DEFERRED_TO_EXISTING_ACK`，不能写成 hash mismatch。

### I-07：SSH banner 首次超时，稍后同链路成功

- 15 秒 banner exchange 超时。
- 延长到 35 秒后，同基线返回完整 tasklist；另一诊断在 15 秒返回 PROCESS_LIST。
- 单次短超时不能判 Guest 离线，但端口/banner 成功也不能证明 GuestControl、数据面或样本运行可用。

### I-08：SCP 路径假设错误，立即路径失败被伪装成轮询超时

- Guest 采集器实际已启动，但 SCP 轮询反复等待。
- 首轮实际为立即路径失败，本机 SCP 对 home-relative path 和给定路径形式的解释不同。
- 后续 13 次轮询均超时，耗时没有产生证据。
- “文件还没生成”“路径不存在”“权限失败”“传输失败”没有被分开。

### I-09：控制面、数据面、完成面没有一开始就真正独立

- 控制面断开时，Guest 可能已经写入 `PRE/MID/POST`，但 Host 没有拿到。
- 大转储可能留在 Guest，Host 只拿到日志。
- C159 中共享数据面成功产出完整日志和前后状态，但控制面 later not-ready。
- 不同轮次的 SCP、GuestControl copyfrom、共享目录、Guest 本地盘可用性不同，不能用一个通道代表全部通道。

### I-10：runner 使用了错误工作目录或不可见收割位置

- runner 后台启动后，共享 spool 没有结果。
- Guest 文件可能写入默认当前目录、Guest home、本地盘或未映射路径。
- 有 PID 不等于 Host 能读到状态文件。
- C161 初始观察目录不存在，CDB 实际没有启动。

### I-11：GuestControl 会话结束连带杀掉前台 runner

- C165 中 GuestControl 会话约 4 秒后结束，同一会话启动的 Guest runner 一起被杀。
- 只有 BOOT/PRE/部分过程事件，`post/delta/done` 没有生成。
- C166 等待两分钟也没有收回 `native_probe.log`。
- 根因是 runner 生命周期绑定前台 GuestControl 会话。

### I-12：WMI 轮询拖慢了观测器

- C165 每 3 秒用 `Get-CimInstance Win32_Process` 查询进程。
- WMI 查询比任务所需轻量进程 API 慢，拖慢 heartbeat 和阶段推进。
- 观测器本身改变了窗口时序。

### I-13：长时间运行和大转储使 Guest/通信面一起失活

- C132 中 GuestControl、SSH、VBox 日志和 ACPI 收尾相继异常，出现 Guest unresponsive/catch-up。
- C67 中 Guest 报告 ProcDump 生成约 100 MB 文件，随后 SSH/Guest Additions 失联，Host 没拿到可解析 dump。
- 后续只能强制断电，无法取得自然退出码、完整 post 状态或完整转储。
- Guest 报告“文件大小”不等于 Host 已持有完整文件。

### I-14：Guest 失联后残留 VBoxHeadless 阻塞恢复

- GuestControl/Guest 服务失效后，VM 显示 poweroff，但 startvm 报 `VM session was closed before any attempt to power it on`。
- 发现旧 VM 相关 stale VBoxHeadless 链。
- 只有按命令行归属清理对应 VM 的进程后，恢复动作才重新可用。
- 清理其他 VM 进程存在误伤风险。

### I-15：Guest Additions 处在低 runlevel

- stale VBoxHeadless 清理后，GuestAdditionsRunLevel=1 持续约 3 分钟。
- VM 虽启动，GuestControl 仍不可用。
- 从已知 clean snapshot 恢复后 runlevel=3、短探针成功。

### I-16：VirtualBox startvm 在 Guest 执行前失败

- C116 中 startvm 返回 `VM session was closed before any attempt to power on`。
- 没有 CDB、Guest 退出码或样本事件。
- 该轮只能记 `INVALID_INSTRUMENT / VM_SESSION_CLOSED_BEFORE_START`，不能记样本阴性。

### I-17：子进程过滤名和实际部署名不一致

- 过滤器只看 `EPT_*.exe`，但实际部署对象包括 `Hardware.exe`。
- 改为 `cpr:Hardware.exe` 后仍没有可靠业务 marker。
- 不能由过滤器漏事件推导没有 child、没有 RC00 或解码失败。

### I-18：调试器改变自然部署/子进程行为

- C163/C164 带 CDB，整轮没有子进程创建事件。
- C176 无调试器自然运行，约 3 秒出现真实临时 child。
- 事实是带/不带 debugger 的观测不同；因果尚未闭合，不能直接断言是反调试导致分支切换。
- 两种运行不能拼成同一次自然行为。

### I-19：子进程初始 `int 3` 后 CDB 过早退出

- 子进程创建后初始断点事件触发，脚本过早执行 `q`。
- child breakpoint 注入还没有运行，属于仪器失败。
- 该轮不能以无 hit 解释样本。

### I-20：CDB 复合 breakpoint action 语法失败

- 在一个 action 中串 `bc`、`eb`、`db`、`g` 等命令，CDB 报 `Syntax error`。
- 元数据仍曾记录 patch intent，但目标字节没有写入。
- 计划配置、命令回显和实际写后读回没有分离。

### I-21：过滤器失败后继续枚举过滤字符串

- 先后尝试不同 `cpr:` 名称，但无法区分过滤错误、观察器没挂、目标没创建和 Guest 通道已断。
- 这种变体实验消耗时间，没有新增可判别信息。
- 后续要求全量记录进程创建和 PPID，离线筛选名称。

### I-22：有入口 marker，但完成面和 post 文件没有生成

- C145 已看到内部 call target，runner spool 停在 LAUNCH。
- `CDB_DONE`、`POST_STATE`、`run_meta`、`DONE` 缺失。
- 只能证明到达一个中间点，不能证明函数返回、业务完成或目标正常结束。

### I-23：WAIT_TIMEOUT 和收尾成功被混为一类

- 有的运行 `WAIT_TIMEOUT` 但 Guest runner 已完整生成 pre/post/run_meta。
- 有的运行超时且没有 post/done。
- “窗口到期”“runner 完成”“证据完整”“自然退出”必须分别记录。

### I-24：run_meta 与 CDB 原始日志矛盾

- C157 用全文 substring 搜索，把 breakpoint 命令回显误判为命中。
- C159/C160 出现 `markers={}`，但原始 CDB 日志有独立命中行。
- run_meta 不能独立作为事件权威，必须优先保留原始日志的独立整行 marker 和上下文。

### I-25：失败重试复用 RUN_ID/目录

- C161 两次前置失败与后续有效运行复用同一 run id/目录。
- `run_meta` 出现合并或覆盖历史状态。
- marker 数和时间线无法唯一归因到一次启动。

### I-26：Guest 观察目录缺失，CDB 没有启动

- 初始 runner 因父目录不存在无法写状态文件。
- 第二次投递的版本仍漏了目录创建。
- 前台 GuestControl 随后超时，CDB 实际没有执行。

### I-27：AV 没有上下文

- C150 只记录访问违例地址，没有 RIP/RSP/寄存器/栈和模块归属。
- 不能区分样本 AV、调试器 AV、坏地址跳转或仪器错误。
- 后续规则要求一次性采集上下文，并把无上下文 AV 标为 `AV_UNATTRIBUTED`。

### I-28：Gen2/DVD/UEFI 路线没有进入 Guest

- Windows ISO/DVD 出现 UEFI boot loader failed。
- 离线 Gen2 VHDX 启动遇到 `0xc000000e`、恢复环境 `0xc0000098`。
- 通信探针没有执行，不能当作 Guest 或样本结果。

### I-29：Windows 安装停在 78%，Guest Additions 未就绪

- Guest Additions、Guest OS properties 和 ACK 缺失。
- VM 画面存在不等于 Guest ready。
- 必须标为 `CONTROL_NOT_READY / INSTALL_STALLED`。

### I-30：CDB 文件存在但初始非交互 smoke 没有收回输出

- CDB 文件身份/hash 已知，但第一次 PowerShell Direct 非交互 smoke 没有可收割运行输出。
- 后续改为 Guest 本地写 `.cf/stdout/stderr/summary`，由 PowerShell Direct PSSession `Copy-Item -FromSession` 收割。
- benign `ping.exe` attach smoke 最终通过，证明短时 CDB 和收割路径可用，但不证明目标样本路径可用。

### I-31：CDB 的 `-accepteula` 参数误用产生扩展加载噪声

- CDB 把 `-accepteula` 的内容误解释为 `ccepteula` 扩展名，输出 LoadLibrary 错误。
- 仍然附加成功，但第一轮不是干净 smoke。
- 后续移除该参数重跑。

### I-32：PowerShell Direct 会话没有继承 SMB 磁盘映射

- 交互式 ACK 使用单独 SMB reader 访问过样本。
- 后续 `<VM_USER>` PSSession 中没有 `EPTS:` 映射。
- UNC 复核因会话作用域和字符串错误失败。
- Host authority 与已有 Guest ACK hash 一致，但当前会话没有重新读取样本。

### I-33：Host/Guest PowerShell 结果字段不一致

- 远程 `Start-Process` 后 CDB `WaitForExit` 显示 `EXITED`。
- 远程 Process 对象的 `ExitCode` 仍为 null。
- 多行 `Invoke-Command` 有时没有可见输出。
- 不能用 null 填 0，必须记录 `EXITED / EXIT_CODE_NOT_OBSERVED`。

### I-34：C179 的 session 0 用户交互阻塞

- C179 通过纯内存授权状态放行后，真实 Setup 阶段开始运行。
- Winsock/名称解析模块加载，真实阶段日志出现。
- child 主线程在 `Wait/UserRequest`，CPU 长时间不变。
- 运行身份为 SYSTEM、session 0、无交互桌面；MessageBoxW/A/Ex/Timeout 只跳过两个，仍有未识别的 UI 调用。
- 这不是 GuestControl 断线，但仍是通信/实验架构缺陷：启动上下文没有为需要 UI 的样本提供交互桌面，也没有事先完成 UI 阻塞识别。

### I-35：控制面、数据面、完成面在 C173 前没有作为硬门禁

- C173 之前多轮进入样本启动或调试阶段时，GuestControl、SSH、共享目录、收尾和文件收割并没有全部独立通过。
- 后续 C173 才形成 PowerShell Direct 控制面 + SMB 只读数据面 + Guest ACK 完成面，并通过 benign CDB smoke。
- 但长时间 runner、实际 CDB 目标和 UI 交互仍没有在同一套闭环中验证。

## 4. 助手/工具自身的执行错误原始记录

这些不是 Guest 业务问题，但直接增加了时间和误判风险：

1. 把 PowerShell 命令直接交给 Bash，产生 `command not found`。
2. 把 PowerShell 的 `2>$null` 带到 Bash，产生 ambiguous redirect 或创建名为 `$null` 的文件。
3. 在正则、Bash 和 Windows 路径之间混用反斜杠，产生 `unclosed group` 和路径语法错误。
4. 用 Bash heredoc 传给 PowerShell 的多行命令出现空输出；没有先证明 Guest 命令执行成功。
5. `apply_patch` 在当前环境不可用，仍反复尝试，造成文档没有落盘。
6. JavaScript template literal 与 Markdown 反引号、Windows 路径冲突，造成 `Unexpected identifier`，命令根本没有执行。
7. heredoc 终止符不匹配，长补丁没有执行。
8. 对固定 `PSCustomObject` 动态添加不存在的 JSON 字段，产生 `SetValueInvocationException`。
9. 没有先验证 PowerShell 会话中的 UNC/SMB 映射作用域。
10. 用嵌套的 Bash + JSON + PowerShell 引号统计文档，产生 ParserError，统计结果为空。
11. CDB 使用不存在的伪寄存器 `@$ta`，应为 `@$t0` 到 `@$t19`；导致整轮断点 action 失效。
12. CDB 高地址/样本代码断点产生调试器反调试、自毁或无法继续，仍有多轮继续围绕同类断点调整。
13. `skipdata=True` 后直接访问 Capstone data instruction operands，触发 `CsError`。
14. 直接按 PE 原始文件 RVA 读取运行时地址，把随机字节和无效指令当作目标代码；后来才改为从 minidump 的 Memory64List 按 VA 映射读取。
15. 高熵/VMProtect 区域使用整段线性反汇编并生成大量伪调用目标。
16. 曾把 CDB 命令回显当作 marker 命中，后续才改用独立整行精确匹配。
17. 运行目录、marker、重试状态和不同轮次发生混杂，后续才建立唯一 RUN_ID 和独立目录要求。
18. 建立了自动化心跳和保险任务，但在业务输入、Guest 通信和自然授权均未闭合时，自动化容易推动重复实验，而不是先修通信和验收门禁。

---

# 第二部分：助手反思

## 5. 最大的根本错误：没有按用户的完成定义工作

用户从第二条要求开始就明确说“授权通过后还有实际修改、伪装进程和日志清理”。我却长时间围绕本地 decoder、RC06、驱动候选、断点、响应注入和部署链推进，并多次把局部技术进展当成主线进展。

这不是单纯的工具问题，而是目标函数错误：

- 用户验收的是“真实样本继续运行后的行为”；
- 我实际优化的是“尽快得到一个可观测的内部 seam”；
- seam 本来只是必要条件，我却反复把它当成接近完成的证据。

更严重的是，在用户已经明确纠正后，仍然继续提出 response 注入、授权门 patch 和设备 I/O 方案，说明我没有把用户的验收标准真正写成每轮实验的硬门禁。

## 6. 第二个根本错误：把“没有看到”过早转换成“没有发生”

具体表现：

- 断网后无 TCP，被说成云授权失败；
- DeviceIoControl 没有样本帧，被拿来支撑本地授权链不存在；
- 静态地址断点未命中，被拿来支撑授权门未执行；
- 后行为文件没出现，被直接解释为授权未通过；
- GuestControl/SSH 失联，被混入样本业务阴性；
- 超时、强杀、无自然退出码，被混入样本结束。

正确做法应该是先判定观测面是否有效，再判定业务结果。项目后来建立了 `CONTROL_NOT_READY`、`DATA_PLANE_LOST`、`DEBUGGER_NOT_REACHED`、`STALL_SUSPECTED`、`WAIT_TIMEOUT`、`INSTRUMENT_FAILURE` 等分类，但这些分类本应从第一轮就存在。

## 7. 通信架构的主要失败：把控制、数据和完成绑在了一起

项目早期把 GuestControl/SSH 同时当作：

- 启动器；
- 长任务保持器；
- stdout 状态管道；
- 文件传输通道；
- 退出码来源；
- 完成判据。

因此只要 GuestControl starting、SSH banner timeout、SCP 路径失败、共享映射失效或大转储拖垮 Guest，所有信息一起丢失。

这是本项目最严重的通信设计缺陷。修复方向应该是一开始就采用：

```text
控制面：只做短命令、投递、启动和健康检查
数据面：Guest 本地原子 spool + 独立小文件镜像
完成面：DONE marker + 自然退出/明确收尾 + VM 状态
```

任何一个平面失败，都不能替代另外两个平面。只有三平面都闭合，才允许写业务结论。

## 8. 没有先做“通信 canary”，就把真实样本当成通信测试

许多轮次没有在进入样本前证明以下最小条件：

1. Guest 真的已 ready；
2. 当前登录身份可以执行目标命令；
3. 当前会话能访问数据目录；
4. Guest 可以创建并写入观察目录；
5. Host 可以立即收回一个小 canary 文件；
6. 长任务不会随 GuestControl 会话结束而被杀；
7. 调试器 stdout、stderr、命令文件和退出状态可收割；
8. 收尾可以按 PID/树进行且不会误伤其他 VM。

结果是大量样本运行其实同时承担了“验证通信”的职责。一旦通信失败，就无法判断样本业务是否运行，更无法判断断点是否生效。

## 9. 选择了会改变样本行为的观测方式，却没有把干扰作为首要变量

CDB、硬件断点、软件断点、启动即调试、child filter、入口 patch 都可能改变：

- 进程创建时序；
- 反调试分支；
- child 是否出现；
- VMProtect dispatcher 行为；
- UI/线程等待；
- 目标进程生命周期。

C165/C176 对照已经显示无调试器自然运行会出现 child，而带 CDB 的运行没有出现 child。即使还不能证明反调试因果，这已经足够说明“带调试器”和“自然运行”不能混用解释。

正确的优先级应当是：

1. 先做无调试自然基线，旁路收集完整进程/文件/网络/注册表状态；
2. 再做 benign 调试器 smoke；
3. 再做自然启动后附加，而不是启动即调试；
4. 每个调试器动作都要证明没有改变目标状态，不能只证明 CDB 自己输出了 marker。

## 10. 过早追逐设备 I/O，浪费了大量实验预算

当时看到了 `DeviceIoControl`、IOCTL 候选和本地 decoder seam，就把它们当成真实授权边界。没有先完成：

- 样本是否真的打开设备；
- 是否有样本栈帧；
- 是否有有效句柄/会话；
- 是否有真实 RC00 参数；
- 是否存在对应驱动。

直到 RECON-6 才证明设备 I/O 是噪音或旁路未走。之后才停止注入路线。这是“静态候选先验压过动态边界证据”的典型错误。

## 11. 过早生成文档和自动化，掩盖了核心问题未解决

项目生成了大量 C 编号证据件、台账、handoff、roadmap、自动化任务和报告，但在真实授权、通信和后行为未闭合时，文档数量并不代表信息量。

用户明确批评过“重大事情没做，却觉得做完了”。这说明文档工作还产生了副作用：

- 让项目看起来进度很快；
- 让旧结论继续存在并影响新路线；
- 让不同状态、不同 VM、不同样本派生物混在一起；
- 把应当暂停的低信息量路线继续自动化。

后续只有在用户明确要求交付文档，或文档本身是下一步执行的硬输入时，才应优先写文档。否则应先推进能直接增加目标级信息的工作。

## 12. 身份和证据范围管理虽然后来修正，但起步太晚

项目后期才明确区分：

```text
real_sample_guest_run
real_sample_guest_run_injected_io
host_mapped_code_runner
caller_injection_harness
offline_reference_synthetic_response
synthetic_device_boundary
```

在此之前，`validator_rax`、harness diff、mapped code、response fixture 和真实目标字段容易在同一报告中相邻出现，增加误读风险。

正确做法应该是从第一份 JSON 开始就强制：

- `evidence_scope`；
- `sample_sha256`；
- `run_id`；
- `vm/snapshot`；
- `target_pid/ppid`；
- 输入/response 来源；
- 是否修改目标内存；
- 是否继续到 RC06 后；
- 是否自然退出或被强杀。

## 13. 对用户沟通的反思

用户多次用“继续”推动执行，说明用户要的是持续推进而不是反复解释。我的问题不是没有输出，而是输出方向多次偏离：

- 把已经被用户否定的 decoder 中心路线重新包装；
- 需要静态联网分析时，先做了很多动态仪器调试；
- 用户强调真实自然运行时，没有马上停止 response/harness 叙事；
- 用户指出网络是噪音时，先前报告仍把断网和授权失败混在一起；
- 用户要求重写 handoff 时，旧版本中仍有大量已过时的动态注入主线，说明状态同步不及时。

以后每次继续前应先用一句话复述当前硬目标，并明确：

```text
本轮只解决哪个阻塞？
如果没有直接证据，本轮结束时写什么状态？
什么结果绝对不能被升级解释？
```

## 14. 当前问题的责任排序

按对项目影响从大到小：

1. **目标优先级错误**：没有把授权后真实行为作为最高验收门槛。
2. **通信三平面缺失**：控制面、数据面、完成面被耦合。
3. **没有先验证 Guest 通信 canary**：把样本运行兼作通信测试。
4. **调试器介入改变样本行为**：没有先建立自然基线和后附加模型。
5. **把观测阴性升级为业务阴性**：多次产生错误方向。
6. **过早响应注入和授权 patch**：没有先证明真实入口和真实 I/O 边界。
7. **样本身份、运行号、目录和 marker 混杂**：造成证据归因困难。
8. **工具链边界错误**：Bash/PowerShell/WSL/Windows 路径、引号和重定向频繁出错。
9. **高负载数据收割设计不当**：大 dump、无限 stdout、WMI 高频轮询拖垮 Guest。
10. **文档和自动化先于业务闭环**：增加了表面进度，延迟了真正排障。

## 15. 仍未解决的问题

截至本报告生成时，以下仍不能声称闭合：

- CardLogin 的真实请求 buffer、长度、字段和编码；
- Setup 侧网络函数的合法静态边界；
- Winsock runtime resolver 的真实 caller；
- socket/connect/send/recv 的运行时地址；
- TCP/1029 真实握手；
- 真实许可 response；
- CardLogin、IsLogin、Cloud_Beat 的成功返回码；
- UI 阻塞的剩余调用点，或 session 1 交互桌面下的自然结果；
- `target_native_return`；
- `target_caller_diff_bytes`；
- RC06 后结果消费者；
- HWID 实际修改；
- R3/R32 真实运行；
- 计划任务、日志目录和清理行为的授权后动态证据。

当前应使用的总状态是：

```text
STATIC_STAGE_ORDER_STRENGTHENED
DYNAMIC_RESOLUTION_PARTIALLY_RECOVERED
REAL_SETUP_STAGE_OBSERVED_AFTER_IN_MEMORY_GATE_RELEASE
SESSION_0_UI_WAIT_BLOCKING
REAL_LICENSE_RESPONSE_UNOBSERVED
TARGET_SEAM_NOT_CLOSED
POST_AUTH_BEHAVIOR_NOT_OBSERVED
```

## 16. 后续必须执行的通信整改清单

在任何新的目标级运行前，必须逐项通过：

### A. Guest 控制面

- VM 当前启动会话的 NAT/Hyper-V 状态确认；
- Guest agent/PowerShell Direct readiness；
- 两次短命令探针；
- 当前身份认证确认；
- 不使用旧会话；
- 当前会话的命令、当前目录、权限和退出码可回收。

### B. Guest 数据面

- Guest 自建唯一 `C:\ept_obs\RUN_ID`；
- 先写 canary，再做目标启动；
- Host 立即收回 canary 并比对内容/hash；
- 使用原子临时文件替换 marker；
- 小文件实时镜像；
- 大文件只在已验证路径和预算内收割。

### C. Guest 完成面

- `READY`、`HEARTBEAT`、`PHASE`、`DONE` 独立文件；
- 自然退出、deadline、观察器请求停止、强制断电分开记录；
- 没有 `DONE` 不得写 `TARGET_RESULT`；
- Host 必须验证文件实际存在、大小和 hash；
- Guest summary 的 exit code 不能替代 Host 侧核验。

### D. 目标运行方式

- 先无调试自然运行；
- 需要调试时自然启动 child 后再附加；
- 不把 CDB 启动模式与自然模式合并解释；
- session 0 UI 阻塞问题必须先解决或单独标记；
- 任何临时内存写入必须记录 before/after 和作用域；
- 任何 response 注入必须先证明真实边界，并且不能在 RC06 或首个行为点截断。

---

## 17. 一句话结论

本项目最主要的失败不是“逆向能力不够”，而是**没有把用户真正要的授权后真实行为作为硬验收目标，也没有先建立独立、可收割、可归因的 Guest 通信三平面**。因此大量时间被消耗在错误的设备 I/O、静态地址、调试器断点、harness 和文档路线上；后续应先保证通信和完成面，再谈任何样本业务结论。
