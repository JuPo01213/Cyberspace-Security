# C180A：问题具体切片与原始记录

日期：2026-09-25
项目：`<REDACTED_PROJECT_PATH>`

> 本文件只记录具体问题切片、用户要求、已发生操作、客观症状和当时可确认的证据状态。
> 不写助手反思，不写改进建议，不把事后判断混入原始事实记录。
> 对无法从证据确认的事项，保留“未观察到”“未闭合”“不能判定”等原始边界。

---

## 1. 用户要求切片

按当前可回读记录，用户反复明确了以下要求：

1. “你妈的，我明天要的是结果！你他妈停，你妈了个逼的！”
2. “授权通过之后，还有实际的修改，修改还需要修改完成。完成之后，还会有伪装进程和日志清理。你妈的，你后面这么多一个都没有拿到！重大不说你妈呢，重大逼事儿没做，觉得自己做完了！”
3. “而且，这个是有联网更新的，你可能还需要去查到它联网的部分，然后屏蔽掉”
4. “你他妈的静态分析联网这一点不分析吗？我他妈不提醒你，你不搁这卡死了！”
5. 多次要求“继续”。
6. 用户说明：“我再次强调，你必须过授权之后让整个程序自然地运行，才能拿到最真实的证据。目前查明，联网下发的只是一个许可，也是授权的一部分。联网通过授权之后才会下发许可，程序才会真正运行。你只需要静态分析联网授权部分，并屏蔽你在静态校准中找授权联网和后行为证据，这样效率是非常低的。而且，你进行了这么久授权好像还是没有过，我不知道你在干什么。”
7. 用户说明：“不管怎么样，联网这部分是实打实的噪音。这个噪音需要屏蔽或清理。”
8. 用户要求“重写handoff”。
9. 用户要求：“回读该项目的完整对话，反思出现的所有问题。我需要一份问题的原始记录，和你的反思分开写，尤其注重你和靶机通信的缺陷。注意是完整的所有的对话，不要偷懒。”
10. 用户随后纠正：“让你写反思，你在干什么”。
11. 用户再次纠正：“我他妈开头就跟你说了，我要这些问题的具体切片以及你的反思，并且写成两份文件，你他妈听不懂人话吗”。

用户要求的验收重点始终是：

- 不能把部署、自复制、静态解码、harness、伪造 response 或单个断点命中当作完成；
- 必须观察授权通过后的真实继续运行；
- 必须关注 HWID 修改、修改完成、伪装/干活进程、计划任务、日志和痕迹清理、联网更新与许可下发；
- 联网授权与许可下发属于同一条业务链；
- 网络屏蔽只能作为噪音隔离，不能被表述为服务端拒绝或业务授权失败；
- 复盘要把具体问题切片和助手反思分成两个文件；
- 复盘重点包括宿主机与 Guest/靶机通信缺陷。

---

## 2. 目标偏移的原始过程

### 2.1 解码 seam 被放在过高位置

早期围绕 `RC00 / RC03 / RC06`、`target_native_return` 和 `target_caller_diff_bytes` 建立完成判据。

后续用户明确指出：解码只是触发点，不是终点；即使真实目标在受控 response 下解码成功，也必须继续观察解码结果的消费者和后行为。C152/C175 的 harness 只能证明局部 transform/validator/写回机制，不能证明真实样本完成。

后来才把 seam 降为必要但非充分条件，并把 RC06 后的进程、文件、注册表、网络、驱动/组件释放、持久化、规避和清理行为列为最终观察对象。

### 2.2 自部署链一度被当成授权后行为

动态观察到：

```text
DeleteFileW(System32\Hardware.exe.tmp)
→ CopyFileW(ept_core\Hardware.exe → System32\Hardware.exe.tmp)
→ MoveFileExW(.tmp → System32\Hardware.exe)
→ CopyFileW(ept_core\Hardware.exe → TEMP\EPT_<RAND>_<RAND>.exe)
```

后续证据表明，这属于授权前自部署和临时载荷释放，不等同于用户要求的 HWID 修改、伪装进程、日志清理或授权后行为。

### 2.3 断网和无 TCP 曾被过度解释

Guest 网卡多次处于断开状态，实验中出现 DNS 查询或无外联。早期叙述曾把“无法连接服务器”直接升级为“云授权失败、后行为不执行”。

后续静态分支显示：

- 存在 `*_failed_soft_allow` 分支；
- `*_denied_clear_or_block` 更接近服务端明确拒绝后的清理/阻断分支；
- 当前动态证据只闭合到 DNS，没有闭合 TCP、请求、许可 response 或服务端返回码。

因此当前边界应为：

```text
AUTH_NETWORK_UNOBSERVED
REAL_LICENSE_RESPONSE_UNOBSERVED
POST_AUTH_BEHAVIOR_NOT_OBSERVED
```

### 2.4 response 注入方案在真实边界确认前出现

在没有证明真实样本通过 pre-decode 授权闸门、建立有效设备/会话、产生真实 RC00 之前，曾设计 `gen_inject_cdb.py` 和 284 字节 response 注入方案，计划在 `DeviceIoControl` 边界写 response、置 `Information=284`、设置 `RAX=1`。

随后 RECON-6 发现：

- 父进程 `NtDeviceIoControlFile` 命中没有样本调用栈帧；
- 命中主要来自 bcrypt、卷设备和加载器噪音；
- `CreateFileW/A` 设备路径过滤为零；
- 当前隔离环境没有证明样本建立目标设备会话。

因此 response 注入路线的前提不成立，之后应停止把它写成真实授权路径。

### 2.5 静态授权地址反复被当作必然动态入口

曾把 `0x1407a3080`、`0x1407a30a6`、`0x1407a311f`、`0x1407a315d` 等静态候选作为必然运行时授权门或断点入口。多轮父/child 观察中没有命中这些地址。

后来才确认：静态地址只能是候选，未命中不能直接解释为授权逻辑未执行；需要运行时定位、字符串落地、合法函数边界或只读静态分析来确认。

### 2.6 高熵 CardLogin 区域被线性反汇编

`0x1403b3d30..0x1403c42ac` 被作为 CardLogin 候选范围后，曾对整段做线性反汇编并生成大量伪相对调用和无效指令。

后续发现：

- 入口短段可读，后续区域高熵、混淆或虚拟化；
- `.pdata` 对应范围熵约 7.9720，不能直接当作连续代码；
- `0x1403b8190`、`0x1403c2df8` 的 `0x25` 命中不能单独证明请求格式；
- 只能使用已验证指令起点、`.pdata`、精确 LEA/MOVABS 目标扫描和运行时映射。

### 2.7 C175 harness 的结果被降级

C175 在 Guest 内复现了局部 transform/validator/写回：

```text
harness_validator_rax=0x1
harness_decoded_output_bytes=268
harness_caller_diff_bytes=14
harness_caller_output_written=true
```

但它没有启动真实 EPT/Hardware 样本，没有自然设备 response，也没有观察 RC06 后行为，因此只能标为：

```text
CALLER_INJECTION_HARNESS_ONLY
NOT_TARGET_COMPLETION
```

### 2.8 C176 只证明了自然启动和临时 child

C176 无调试运行中：

- `Hardware.exe` 自然启动；
- 约 3 秒后自然创建 `EPT_15669800_B33D1B09.exe`；
- 没有 CDB、断点、response 注入或目标机器码写入；
- 180 秒后由观察器主动停止目标和 child。

它不能证明 RC00/RC03/RC06、许可返回或授权后行为。

### 2.9 C177 说明自然启动后附加更可靠，但仍未闭合业务结果

启动即调试时，父进程入口后退出或没有 child。改为 SYSTEM 自然启动、先发现 child、再 CDB 附加后，`-07/-08` 看到真实 child 和 main entry。

这只说明仪器边界发生差异，不能证明授权成功、网络请求、许可 response、RC06 或后行为。

### 2.10 C179 观察到 Setup 真实阶段和 session 0 阻塞

C179 对授权状态做临时内存写入后，首次看到真实 Setup 阶段日志：

```text
Setup.SP_Verify_Init = 0
Setup.SP_Verify_GetServerOption = -3
```

同时观察到：

- Winsock/名称解析模块加载；
- 没有观察到 TCP 连接；
- child 主线程停在 `Wait/UserRequest`；
- 运行身份为 SYSTEM、session 0、没有交互桌面；
- MessageBox 家族只跳过两个调用，仍有未识别 UI 阻塞调用。

该轮只能说明 Setup 进入了网络阶段后被用户交互环境阻塞，不能写成授权通过或 post-auth 完成。

---

## 3. Guest/靶机通信缺陷具体切片

### I-01：WSL 调用 Windows VBoxManage 时 stdout 假空

- 直接调用 `VBoxManage.exe`、经 `cmd.exe /C`、经 `powershell.exe` 时，WSL 侧可能得到空 stdout，exit code 仍为 0。
- 一度被看成命令无输出、探针失败或 VM 没有状态。
- 实际是 Windows 子进程 stdout/stderr 没有被当前 WSL interop 稳定捕获。
- 后续改用 Windows 侧重定向到文件，再从宿主读取。

### I-02：截图 0 字节被当成 Guest 健康失败

- `VBoxManage screenshotpng` 在 SSH 正常时仍可能返回 `E_FAIL`。
- WSL 风格路径传给 Windows 命令时，文件可能被写到另一位置。
- `stat`/`echo` 把路径错误、截图接口失败和文件不存在合并成 shot=0B。
- 样本实际没有启动时，失败对象可能只是截图探针。

### I-03：VM Running/Saved 不等于 Guest 服务就绪

- 恢复快照后出现 `Session 0 is about to close`、`Stopping all guest processes`。
- NAT Link up 等待实测可为 5 秒、20 秒、35 秒，最慢约 917 秒，部分轮次不出现 Link up。
- SSH 与 GuestControl 可能同时失效。
- 半拆卸状态曾被看成干净、可实验基线。

### I-04：GuestControl `starting` / `VERR_DUPLICATE` 导致控制面 wedge

- 出现 `current status is: starting`、`Error starting guest session`、`VERR_DUPLICATE`。
- VM 仍显示 Running，Guest Additions 也可能显示正常。
- 控制命令没有返回，收尾探针和结果文件未取得。
- 该状态属于通信/控制面问题，不能解释为样本没有进程或业务失败。

### I-05：GuestControl 认证失败，SSH banner 被误当成可登录

- GuestControl 报 `The specified user was not able to logon on guest`。
- SSH 公钥/认证返回 `Permission denied`。
- 另一轮 TCP 检查能收到 SSH banner。
- banner 只能说明端口服务响应，不能证明认证、命令执行、文件投递或结果收割可用。

### I-06：共享配置存在不等于源目录和 Guest 路径可用

- Guest 显示 Z: 映射，DisplayRoot 指向共享名，但 `Z:/probe` 不存在。
- 当时宿主 `<REDACTED_HOST_PATH>` 源目录也不存在。
- 后续 Hyper-V/SMB 只读数据面闭合，但每个 PowerShell Direct 会话不一定继承 SMB 映射。
- PSSession 将 UNC 字符串错误解释为 Guest 本地路径，记录为 `DEFERRED_TO_EXISTING_ACK`，不能写成 hash mismatch。

### I-07：SSH banner 首次超时，稍后同链路成功

- 15 秒 banner exchange 超时。
- 延长到 35 秒后，同基线返回完整 tasklist；另一诊断在 15 秒返回 PROCESS_LIST。
- 单次短超时不能判 Guest 离线；端口/banner 成功也不能证明 GuestControl、数据面或样本运行可用。

### I-08：SCP 路径假设错误，立即路径失败被伪装成轮询超时

- Guest 采集器实际已启动，但 SCP 轮询反复等待。
- 首轮实际是立即路径失败，本机 SCP 对 home-relative path 和给定路径的解释不同。
- 后续 13 次轮询均超时，没有产生证据。
- “文件还没生成”“路径不存在”“权限失败”“传输失败”没有被分开。

### I-09：控制面、数据面、完成面没有一开始就独立

- 控制面断开时，Guest 可能已经写入 PRE/MID/POST，但 Host 没有拿到。
- 大转储可能留在 Guest，Host 只拿到日志。
- C159 中共享数据面成功产出完整日志和前后状态，但控制面 later not-ready。
- 不同轮次的 SCP、GuestControl copyfrom、共享目录和 Guest 本地盘可用性不同，不能用一个通道代表全部通道。

### I-10：runner 使用错误工作目录或不可见收割位置

- runner 后台启动后，共享 spool 没有结果。
- Guest 文件可能写入默认当前目录、Guest home、本地盘或未映射路径。
- 有 PID 不等于 Host 能读到状态文件。
- C161 初始观察目录不存在，CDB 实际没有启动。

### I-11：GuestControl 会话结束连带杀掉前台 runner

- C165 中 GuestControl 会话约 4 秒后结束，同一会话启动的 Guest runner 一起被杀。
- 只有 BOOT/PRE/部分过程事件，post/delta/done 没有生成。
- C166 等待两分钟也没有收回 native_probe.log。
- 根因记录为 runner 生命周期绑定前台 GuestControl 会话。

### I-12：WMI 轮询拖慢观测器

- C165 每 3 秒使用 `Get-CimInstance Win32_Process` 查询进程。
- WMI 查询比轻量进程 API 慢，拖慢 heartbeat 和阶段推进。
- 观测器本身改变了窗口时序。

### I-13：长时间运行和大转储使 Guest/通信面一起失活

- C132 中 GuestControl、SSH、VBox 日志和 ACPI 收尾相继异常，出现 Guest unresponsive/catch-up。
- C67 中 Guest 报告 ProcDump 生成约 100 MB 文件，随后 SSH/Guest Additions 失联，Host 没拿到可解析 dump。
- 后续只能强制断电，无法取得自然退出码、完整 post 状态或完整转储。
- Guest 报告文件大小不等于 Host 已持有完整文件。

### I-14：Guest 失联后残留 VBoxHeadless 阻塞恢复

- GuestControl/Guest 服务失效后，VM 显示 poweroff，但 startvm 报 `VM session was closed before any attempt to power it on`。
- 发现旧 VM 相关 stale VBoxHeadless 链。
- 只有按命令行归属清理对应 VM 进程后，恢复动作才重新可用。
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
- 当前只能确认带/不带 debugger 的观测不同，不能直接断言差异一定由反调试导致。
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
- 这些变体实验消耗时间，没有新增可判别信息。
- 后续要求全量记录进程创建和 PPID，离线筛选名称。

### I-22：有入口 marker，但完成面和 post 文件没有生成

- C145 已看到内部 call target，runner spool 停在 LAUNCH。
- `CDB_DONE`、`POST_STATE`、`run_meta`、`DONE` 缺失。
- 只能证明到达一个中间点，不能证明函数返回、业务完成或目标正常结束。

### I-23：WAIT_TIMEOUT 和收尾成功被混为一类

- 有的运行 `WAIT_TIMEOUT` 但 Guest runner 已完整生成 pre/post/run_meta。
- 有的运行超时且没有 post/done。
- 窗口到期、runner 完成、证据完整和自然退出必须分别记录。

### I-24：run_meta 与 CDB 原始日志矛盾

- C157 用全文 substring 搜索，把 breakpoint 命令回显误判为命中。
- C159/C160 出现 `markers={}`，但原始 CDB 日志有独立命中行。
- run_meta 不能独立作为事件权威，必须保留原始日志中的独立整行 marker 和上下文。

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

### I-30：CDB 文件存在但初始 smoke 没有收回输出

- CDB 文件身份/hash 已知，但第一次 PowerShell Direct 非交互 smoke 没有可收割运行输出。
- 后续改为 Guest 本地写 `.cf/stdout/stderr/summary`，再由 PowerShell Direct PSSession `Copy-Item -FromSession` 收割。
- benign `ping.exe` attach smoke 最终通过，证明短时 CDB 和文件收割路径可用，但不证明目标样本路径可用。

### I-31：CDB 的 `-accepteula` 参数误用产生扩展加载噪声

- CDB 把 `-accepteula` 的内容误解释为 `ccepteula` 扩展名，输出 LoadLibrary 错误。
- 仍然附加成功，但第一轮不是干净 smoke。
- 后续移除该参数重跑。

### I-32：PowerShell Direct 会话没有继承 SMB 磁盘映射

- 交互式 ACK 使用单独 SMB reader 访问过样本。
- 后续 `<SESSION_NAME>` PSSession 中没有 `<MAPPED_DRIVE>:` 映射。
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
- 运行身份为 SYSTEM、session 0、无交互桌面；MessageBoxW/A/Ex/Timeout 只跳过两个，仍有未识别 UI 调用。
- 这不是 GuestControl 断线，但启动上下文没有为需要 UI 的样本提供交互桌面，属于实验通信/运行架构缺陷。

### I-35：控制面、数据面、完成面在 C173 前没有作为硬门禁

- C173 之前多轮进入样本启动或调试阶段时，GuestControl、SSH、共享目录、收尾和文件收割没有全部独立通过。
- C173 之后才形成 PowerShell Direct 控制面 + SMB 只读数据面 + Guest ACK 完成面，并通过 benign CDB smoke。
- 长时间 runner、实际 CDB 目标和 UI 交互仍未在同一套闭环中验证。

---

## 4. 助手和工具执行错误切片

1. 把 PowerShell 命令直接交给 Bash，产生 `command not found`。
2. 把 PowerShell 的 `2>$null` 带到 Bash，产生 ambiguous redirect 或创建名为 `$null` 的文件。
3. 在正则、Bash 和 Windows 路径之间混用反斜杠，产生 `unclosed group` 和路径语法错误。
4. 用 Bash heredoc 传给 PowerShell 的多行命令出现空输出，没有先证明 Guest 命令已执行。
5. `apply_patch` 在当前环境不可用，仍反复尝试，造成文档没有落盘。
6. JavaScript template literal 与 Markdown 反引号、Windows 路径冲突，产生 `Unexpected identifier`，命令根本没有执行。
7. heredoc 终止符不匹配，长补丁没有执行。
8. 对固定 `PSCustomObject` 动态添加不存在的 JSON 字段，产生 `SetValueInvocationException`。
9. 没有先验证 PowerShell 会话中的 UNC/SMB 映射作用域。
10. 用嵌套 Bash + JSON + PowerShell 引号统计文档，产生 ParserError，统计结果为空。
11. CDB 使用不存在的伪寄存器 `@$ta`，正确范围应为 `@$t0` 到 `@$t19`；整轮断点 action 失效。
12. CDB 高地址/样本代码断点产生调试器反调试、自毁或无法继续，仍有多轮继续围绕同类断点调整。
13. `skipdata=True` 后直接访问 Capstone data instruction operands，触发 `CsError`。
14. 直接按 PE 原始文件 RVA 读取运行时地址，把随机字节和无效指令当作目标代码；后来才改为从 minidump 的 Memory64List 按 VA 映射读取。
15. 对高熵/VMProtect 区域使用整段线性反汇编并生成大量伪调用目标。
16. 把 CDB 命令回显当作 marker 命中，后续才改用独立整行精确匹配。
17. 运行目录、marker、重试状态和不同轮次发生混杂，后续才建立唯一 RUN_ID 和独立目录要求。
18. 在业务输入、Guest 通信和自然授权均未闭合时建立自动化心跳和保险任务，自动化可能推动重复实验，而不是先修通信和验收门禁。

---

## 5. 当时的项目状态边界

在这份原始问题记录形成时，以下事项仍未闭合：

- CardLogin 真实请求 buffer、长度、字段和编码；
- Setup 侧网络函数的合法静态边界；
- Winsock runtime resolver 的真实 caller；
- socket/connect/send/recv 的运行时地址；
- TCP/1029 真实握手；
- 真实许可 response；
- CardLogin、IsLogin、Cloud_Beat 的成功返回码；
- session 0 剩余 UI 阻塞调用点，或 session 1 交互桌面下的自然结果；
- `target_native_return`；
- `target_caller_diff_bytes`；
- RC06 后结果消费者；
- HWID 实际修改；
- R3/R32 真实运行；
- 计划任务、日志目录和清理行为的授权后动态证据。

记录中的总状态为：

```text
STATIC_STAGE_ORDER_STRENGTHENED
DYNAMIC_RESOLUTION_PARTIALLY_RECOVERED
REAL_SETUP_STAGE_OBSERVED_AFTER_IN_MEMORY_GATE_RELEASE
SESSION_0_UI_WAIT_BLOCKING
REAL_LICENSE_RESPONSE_UNOBSERVED
TARGET_SEAM_NOT_CLOSED
POST_AUTH_BEHAVIOR_NOT_OBSERVED
```