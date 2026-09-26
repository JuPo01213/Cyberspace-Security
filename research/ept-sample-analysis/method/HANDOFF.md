# HANDOFF — EPT / Hardware.exe 静态授权与联网噪音分析

> 更新：2026-09-25
>
> 本文件是当前阶段的唯一交接摘要。它覆盖旧版 HANDOFF 中已经被推翻的动态注入、设备 I/O 和旧 VM 叙述；旧实验记录仍保留在 `RUN_MANIFEST_genB.md`、`artifacts/evidence/` 和 `archive/` 中，但不能覆盖本文的当前结论。

---

## 0. 当前任务目标

分析恶意样本“EPT专业游戏维修工具箱V5.1 / Hardware.exe”，重点不是完成正规商业授权，也不是只证明本地解码函数能运行，而是恢复并理解：

1. 授权/许可的真实联网路径；
2. 网络噪音、更新和心跳行为，并在 Guest 内可控地屏蔽；
3. 授权后的 HWID 修改、伪装/干活进程、持久化和日志/痕迹清理；
4. 如未来获得合适的受控验证条件，证明真实样本继续执行到上述行为，而不是用 harness 或合成 response 代替。

**当前阶段只做静态恢复和网络屏蔽配置，不连接真实 C2，不使用真实卡密，不运行新的 patch/response 注入实验。**

---

## 1. 权威身份与工作目录

| 项目                         | 当前值                                                                |
| -------------------------- | ------------------------------------------------------------------ |
| 工作目录                       | `<HOST_PATH>\EPT`                                                       |
| 权威样本上游                     | `<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe`                           |
| 权威上游 SHA-256               | `CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2` |
| 当前 Guest 中运行的 Hardware 派生物 | `C:\ept_core\Hardware.exe`                                         |
| 当前 Guest 派生物 SHA-256       | `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` |
| 当前 Guest 派生物长度             | `32671232` 字节                                                      |
| 关键静态运行轮次                   | `runs\EPT-INJECT-20260925-23`                                      |
| 关键内存证据                     | `runs\EPT-INJECT-20260925-23\harvest\mem_parent.dmp`               |
| 当前有效 Guest                 | `<VM_LABEL>`，PowerShell Direct，账户 `<VM_USER>`              |

权威上游样本、Guest 派生物和历史捕获物必须分开记账。不能因为文件名相同，直接把两个 SHA-256 当成同一对象；任何新运行都要记录来源路径、完整哈希、运行编号和当前状态。

样本原始文件不得修改。任何运行时观察或临时副本都必须可回滚，且不能把派生物反向写回 `sample\`。

---

## 2. 当前结论（最高优先级）

### 2.1 联网目标已定位

静态解密内存中确认的主要联网端点：

```text
yz.hwid001.com:1029
TCP，自定义协议，非 HTTP
```

已确认的阶段/字符串包括：

- `StoredVerify.SetHost`
- `Setup.SetHost`
- `SP_Verify_Init`
- `SP_Verify_GetServerOption`
- `SP_Verify_CardLogin`
- `SP_Verify_IsLogin`
- `SP_Verify_GetLastestVersionInfo`
- `SP_Verify_GetNotice`
- `SP_Cloud_Beat`
- `StoredVerify.StoredAuthorizationUsable`
- `skip_driver_load_because_authorization_not_usable`

`SP_Verify_CardLogin` 是卡密/许可登录阶段；`GetLastestVersionInfo`、`GetNotice` 和 `SP_Cloud_Beat` 属于更新、公告和心跳/续期相关阶段。

### 2.2 当前动态网络证据只到 DNS

现有运行和抓包证明：

- `yz.hwid001.com` 曾发生 DNS 查询；
- 实验环境曾返回 `198.18.2.159`；
- 当前证据没有闭合到 TCP/1029 三次握手；
- 没有可靠的授权请求 payload；
- 没有许可 response；
- 没有运行时 `CardLogin` 返回码或 `Cloud_Beat` 返回码。

因此不能把“断网”“hosts 钉死”“没有 TCP”直接写成服务端拒绝或授权失败。当前准确状态是：

```text
AUTH_NETWORK_UNOBSERVED
REAL_LICENSE_RESPONSE_UNOBSERVED
POST_AUTH_BEHAVIOR_NOT_OBSERVED
```

### 2.3 当前授权后行为仍未取得动态闭环

静态证据显示样本可能涉及：

- `hwid.cmd`：HWID 部署/修改相关脚本；
- `R3.exe`、`R32.dll`：伪装/实际工作组件；
- 计划任务 `\Microsoft\Hardware`；
- `HardwareTask.xml`；
- `C:\Windows\System32\Logs`、`HardwareLogs`；
- `EPT.cmd`：卸载、自删、进程终止和日志清理脚本；
- `AntiCheatExpert Protection`、`AntiCheatExpert Service`；
- `SeDebugPrivilege` 请求。

这些目前是静态模型，不是授权后动态事实。当前已动态复现的主要是授权前自部署：

```text
DeleteFileW(Hardware.exe.tmp)
→ CopyFileW(ept_core\Hardware.exe → System32\Hardware.exe.tmp)
→ MoveFileExW(.tmp → System32\Hardware.exe)
→ CopyFileW(ept_core\Hardware.exe → TEMP\EPT_<RAND>_<RAND>.exe)
→ COM/Shell 初始化
```

`R3.exe`、计划任务、HWID 实际写入和日志清理在当前运行中仍为 `NOT_OBSERVED`。

---

## 3. 网络噪音屏蔽状态

### 3.1 屏蔽脚本

文件：

```text
<HOST_PATH>\EPT\block_ept_network.ps1
```

脚本只修改 Guest 内的网络策略，不启动样本，不连接 C2。当前行为：

- hosts 增加：
  - `0.0.0.0 yz.hwid001.com`
  - `0.0.0.0 hwid001.com`
  - `0.0.0.0 www.hwid001.com`
- 使用 `netsh.exe advfirewall firewall` 建立幂等出站阻断规则；
- 阻断 TCP/1029；
- 额外阻断已观测实验地址 `198.18.2.159`；
- 每次变更后刷新 DNS 缓存；
- `-Undo` 移除脚本添加的 hosts 行、删除规则并刷新 DNS 缓存。

典型用法：

```powershell
# Guest 内管理员 PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <HOST_PATH>\EPT\block_ept_network.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <HOST_PATH>\EPT\block_ept_network.ps1 -Undo
```

不要在宿主机上运行该脚本，不要把 Guest 内屏蔽误写成宿主网络配置修改。

### 3.2 屏蔽的证据口径

网络屏蔽只回答：

```text
样本不能向已知端点发送可用的 TCP/1029 流量
```

它不回答：

```text
服务端是否拒绝了卡密
授权是否成功
服务端下发了什么许可
样本是否已经完成 CardLogin
```

所有报告必须把“隔离/屏蔽”和“授权结果”分栏记录。

---

## 4. 已确认的授权状态机

从 `/23` 非侵入全内存 dump 恢复出的阶段链：

```text
StoredVerify.begin
  → SP_Verify_Init
  → SetHost(yz.hwid001.com, 1029)
  → SP_Verify_GetServerOption
  → SP_Verify_CardLogin
  → SP_Verify_IsLogin
  → SP_Cloud_Beat
  → StoredAuthorizationUsable / 后续本地授权状态判断
```

已发现的失败分支标签：

```text
init_failed_soft_allow
option_failed_soft_allow
cardlogin_failed_soft_allow
islogin_failed_soft_allow
beat_not_soft_allow_clear_or_block
cardlogin_denied_clear_or_block
beat_hard_deny_clear_or_block
```

静态语义边界：

- `*_failed_soft_allow` 只能说明存在软放行候选分支；不能据此证明后续行为一定执行；
- `*_denied_clear_or_block` 说明存在服务端明确拒绝后的清理/阻断分支；不能据此证明本轮已经收到该拒绝；
- `SP_*` 名称是返回码/日志语义，不等于网络报文格式；
- 请求字段、response 字节布局、校验和/加密方式、服务器返回码映射仍未完全恢复。

### 4.1 授权返回码清单

已从静态字符串发现一组 `SP_*` 返回码，包括：

```text
SP_NOERROR
SP_INVALIDCARD
SP_EXPIREDCARD
SP_BANNEDCARD
SP_NOACTIVATEDCARD
SP_OFFLINE
SP_CONNECTFAILED
SP_WSAFAILED
SP_NOLOADCLOUDDLL
SP_UNKNOWN_CODE
```

完整字符串和引用应以 `/23` dump 及相关证据件为准。不要把这些名字直接当作已观察到的服务器返回值。

---

## 5. 已推翻的路线（不要重复）

1. **不要再把 `DeviceIoControl` 当成已确认的授权边界。**
   - `RECON-6` 中父进程 `NtDeviceIoControlFile` 调用栈没有样本帧；观测到的是 bcrypt、卷设备和加载器噪音。
   - `CreateFileW/A` 按 `\\` 设备路径过滤也没有命中。
   - 当前隔离环境没有证据表明样本建立 `\\.\\HP_WKS_SWTOOLS_DRIVER` 会话。
2. **不要再依赖静态地址 `0x1407a3080` 作为必然授权门。**
   - 该地址在父/child 的既有动态观察中均未命中。
   - 只能把它作为历史静态候选，不能作为新实验断点地址。
3. **不要再运行 `gen_inject_cdb.py` 或旧的 284 字节 response 注入路线。**
   - 旧方案没有先证明真实设备会话和真实 RC00；
   - synthetic response、harness 解码和 mapped-code runner 不计入自然授权；
   - 旧证据只能作为机制参考，不能写成真实样本已授权。
4. **不要用断网结果推断服务端拒绝。**
   - 现有网络证据只到 DNS；TCP、请求和 response 未闭合。
5. **不要把静态组件字符串当成后行为动态证据。**
   - `R3.exe`、`hwid.cmd`、`HardwareTask.xml`、`Logs` 和 `EPT.cmd` 只能证明样本具备或计划使用这些组件/路径。
6. **不要重复长时间等待和高频调试断点。**
   - 样本存在反调试；样本代码上的软件/硬件断点曾导致自毁、卡死或观测失效；
   - 高速断点和全线程快照曾导致输出爆炸；
   - 没有新假设时，延长同一路线不会增加信息。

---

## 6. 静态分析资产与入口

### 6.1 核心证据

| 路径                                                                      | 用途                           |
| ----------------------------------------------------------------------- | ---------------------------- |
| `runs\EPT-INJECT-20260925-23\harvest\mem_parent.dmp`                    | 解压后父进程全内存 dump，约 95 MB       |
| `runs\EPT-INJECT-20260925-23\harvest\network.ndjson`                    | 本轮网络观察                       |
| `runs\EPT-INJECT-20260925-23\harvest\events.ndjson`                     | 本轮事件观察                       |
| `runs\EPT-INJECT-20260925-23\harvest\file_changes.json`                 | 本轮文件变化                       |
| `artifacts\evidence\genB_functions_from_pdata.tsv`                      | `.pdata` 函数边界候选              |
| `artifacts\evidence\genB_static_imports.tsv`                            | 静态导入清单                       |
| `artifacts\evidence\C69_core_network_progress_boundary_20260921.md`     | DNS 有、TCP 未闭合                |
| `artifacts\evidence\C71_local_decoder_candidate_callchain_20260921.txt` | 历史本地 decoder 候选链，不能升级为自然授权路径 |
| `writeup\04-genb-directed-static.md`                                    | 授权闸门、soft/hard 分支和清理动作静态结论   |
| `EPT_Hardware_analysis.md`                                              | 当前网络与后行为综合报告                 |
| `block_ept_network.ps1`                                                 | Guest 网络屏蔽脚本                 |

### 6.2 CardLogin 当前静态定位

历史运行时映射中，`CardLogin` 候选范围为：

```text
0x1403b3d30 .. 0x1403c42ac
```

已确认的上层调用关系包括：

```text
0x1407a3215 → 0x1403b3d30
```

但该范围混有 VMProtect/运行时解密内容，不能直接对整段做线性反汇编并把所有 `E8` 相对目标当成真实调用图。后续静态分析必须：

1. 使用 `.pdata` 和已验证指令起点切分函数/子区间；
2. 只保留目标落在已映射模块、已知 IAT 或已确认动态解析槽的调用；
3. 识别 `LoadLibrary*`、`GetProcAddress`、`WSAStartup`、`socket`、`connect`、`send`、`recv` 的真实调用者；
4. 沿参数流追踪 host、port、card、HWID、请求长度、输出 buffer 和返回码；
5. 把确定事实、候选推断和未闭合字段分开写。

### 6.3 关键 dump 字符串地址

以下地址是 `/23` 运行时 dump 中的地址，用于静态定位，不是新动态断点地址：

```text
StoredVerify.begin                  0x140f92508
StoredAuthorizationUsable           0x140f9252d
SP_Verify_CardLogin                 0x140f92718
cardlogin_denied_clear_or_block     0x140f92740
cardlogin_failed_soft_allow         0x140f92770
SP_Cloud_Beat                       0x140f927e8
yz.hwid001.com / 1029              0x140f92698 附近
```

---

## 7. 下一步：只读静态协议恢复

当前最高信息增益路线如下，禁止连接真实 C2：

### 第一步：恢复合法代码边界

- 读取 `genB_functions_from_pdata.tsv`；
- 对 `0x1403b3d30..0x1403c42ac` 做 `.pdata` 覆盖切分；
- 用运行时 dump 的虚拟地址映射读取字节；
- 对缺失 `.pdata` 的代码区只做候选标记，不强行并入 CFG；
- 过滤滑移反汇编造成的伪 `call`。

### 第二步：恢复动态网络 API 链

重点搜索/归因：

```text
LoadLibraryA/W
GetProcAddress
WSAStartup
WSAGetLastError
socket
connect
send / WSASend
recv / WSARecv
closesocket
```

目标不是只找字符串，而是确定：

```text
哪个合法调用者取得 API 地址
哪个 buffer 被传给 send
send 的实际长度来源
recv 的 buffer、容量和返回值
返回码如何转成 SP_*
许可数据写入哪个全局/对象
```

### 第三步：恢复字段与阶段参数

至少要分别记录：

| 字段              | 当前状态                     |
| --------------- | ------------------------ |
| host/port       | 已知：`yz.hwid001.com:1029` |
| card 字段         | 未闭合                      |
| HWID/机器标识字段     | 未闭合                      |
| 请求头/命令号         | 未闭合                      |
| 请求长度            | 未闭合                      |
| response 长度     | 未闭合                      |
| 返回码位置           | 未闭合                      |
| checksum/加密/编码  | 未闭合                      |
| 许可字段            | 未闭合                      |
| `IsLogin` 消息    | 未闭合                      |
| `Cloud_Beat` 消息 | 未闭合                      |
| 更新/公告字段         | 仅静态命名已知                  |

### 第四步：形成可审查静态报告

报告必须把每个结论标成：

```text
OBSERVED_STATIC       字节/地址/字符串直接支持
INFERRED              多个证据一致但仍有解释空间
UNRESOLVED            当前材料不能闭合
NOT_OBSERVED_DYNAMIC  没有运行时证据，不代表不存在
```

不得用“协议可能是……”代替字段证据，也不得生成或发送测试请求到真实端点。

---

## 8. 动态实验门禁（当前暂停）

在以下条件全部满足前，不进行新的 response 注入、pre-decode patch 或联网验证：

1. 已有合法静态调用链，而不是整段线性反汇编猜测；
2. 已确认真实样本当前环境确实建立了有效通信/会话；
3. 已确认目标进程和样本谱系；
4. 已明确 response 来源、注入点和证据范围；
5. 用户明确要求进入受控动态阶段；
6. Guest 有可回滚快照、硬 deadline、事件收割和清理方案。

即便未来进入受控动态阶段，也必须区分：

```text
real_sample_guest_run
real_sample_guest_run_injected_io
host_mapped_code_runner
caller_injection_harness
offline_reference_synthetic_response
synthetic_device_boundary
```

只有真实 Guest 目标进程的同一次运行，才能使用：

```text
target_native_return
target_caller_diff_bytes
```

而且这两个字段也只是 RC06 seam 的必要条件，不是最终完成条件。最终还必须继续运行并取得 RC06 后的消费者和自然行为证据。

---

## 9. 证据与报告纪律

- 不把 DNS 证据写成 TCP 连接；
- 不把 TCP 连接写成许可成功；
- 不把返回码字符串写成已收到该返回码；
- 不把静态脚本写成动态执行；
- 不把 `DeviceIoControl` 噪音写成驱动授权；
- 不把 harness、Python 解码、mapped-code runner 或 synthetic response 写成真实样本完成；
- 不修改原始样本；
- 不连接 `yz.hwid001.com`；
- 不解码或使用未知来源的内嵌 token；
- 不为了增加“进度”重复生成无新信息的证据件；
- 运行完成后先收割，再回滚或清理；
- 任何新证据都记录来源、哈希、运行号、环境、scope 和未决项。

---

## 10. 当前一句话交接

**当前已完成：** 定位 `yz.hwid001.com:1029`、授权阶段名、soft/hard 分支、授权前自部署和 Guest 内网络噪音屏蔽脚本。

**当前未完成：** CardLogin/Cloud_Beat 的真实报文字段、许可 response、授权后的自然运行以及 HWID/R3/计划任务/日志清理动态证据。

**接手后的第一动作：** 拔除联网组件，在外围屏蔽联网无法真正排除噪音。

---

## 11. 2026-09-25 静态网络 API 路径复核

- 在 <VM_LABEL> 的断网 Guest 内，使用 CDB 对既有 EPT-INJECT-20260925-23 全内存 dump 做离线分析；没有启动样本、没有打补丁、没有连接 C2、没有发送网络请求。
- 既有 dump SHA-256 为 A73C875C4E08A8319D9FE85EA4B4DFD94EA83A7C046F48A99426C0D2467F8F22；Guest 派生 Hardware.exe SHA-256 为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7；两者在三轮静态 CDB 运行中均未改变。
- IAT 现场确认 ws2_32!setsockopt，以及 LoadLibraryA、GetModuleHandleA、GetProcAddress；socket、connect、send、recv、WSAStartup 不在直接 IAT 槽，支持 Winsock 链通过运行时解析的静态判断。
- dump 中确认 yz.hwid001.com、yz.hwid001.com:1029、StoredVerify、SP_Verify_CardLogin 和 SP_Cloud_Beat 字符串；只找到 WSAStartup 名称片段，未找到 WSASend、WSARecv、getaddrinfo、gethostbyname、inet_addr、htons、closesocket 等名称。connect 命中仅为通用状态文案，不能当作调用点。
- 0x1403b3d30..0x1403c42ac 在当前 dump 中不能线性反汇编闭合：入口短段可读，之后出现不可解码或混淆字节；0x1403b8190、0x1403c2df8 的 0x25 命中不能单独证明请求格式。
- 当前静态结论收紧为 PARTIALLY_RECOVERED_DYNAMIC_RESOLUTION；CardLogin 请求 buffer/长度、response buffer/长度、运行时返回码、TCP/1029 握手和真实许可 response 仍为 UNRESOLVED 或 NOT_OBSERVED。
- 证据：artifacts/evidence/C176_static_network_api_boundary_20260925.json；原始输出位于 artifacts/evidence/EPT-STATIC-NET-20260925-01/ 至 ...-03/。
- 对已登记的 stream_C6/stream_text.bin 做控制性测量：CardLogin .pdata 跨度 66,716 字节熵 7.9720、入口 512 字节熵 7.4261；已知闸门窗口 512 字节熵 5.7795。该差异支持把 CardLogin 区域视为高熵/虚拟化或数据混合区，禁止线性反汇编升级为网络调用图。宿主未安装 Capstone，本轮没有用替代反汇编器填补缺口。
## 12. 2026-09-25 临时授权闸门与自然 child 附加边界

- 运行 `EPT-AUTHGATE-20260925-01` 至 `-06` 记录了入口地址、运行身份、命令行和 child 创建条件；`-01` 的父入口地址截断导致 CDB 启动失败，`-02` 至 `-05` 在“启动即调试”模式下父进程命中入口后调用 `NtTerminateProcess`，没有 child，临时点没有执行；`-06` 以 <VM_USER> 直接自然启动也未找到 child。
- 对照 C176 的已验证 launcher 后恢复 SYSTEM 计划任务自然启动。在 `EPT-AUTHGATE-20260925-07` 和 `-08` 中，父进程自然创建真实临时 child，随后 CDB 才附加；没有连接 C2、没有 response 注入、没有真实卡密，Guest 网卡保持断开。
- `-07` 证明 child 地址空间内两个临时写入实际发生，并命中 `0x1407a4b90`；`-08` 使用自动继续动作再次命中 `0x1407a4b90`，现场 `RCX=0x8, RDX=0x5998c0, R8=0x592680, R9=0x5a6260`。`0x1407a6a6a`、`0x1407a7aec`、`0x14078f060` 在 30 秒窗口内未命中，CDB 等待到期后收尾。
- 当前结论是 `NATURAL_CHILD_ATTACHED_PATCHED_POINTS_ARMED / AUTHORIZATION_SUCCESS_NOT_ESTABLISHED / TARGET_SEAM_NOT_CLOSED`。`target_native_return`、`target_caller_diff_bytes`、目标代码页差异、RC06 和 post-auth 行为仍为 `NOT_OBSERVED`；临时写入不等于业务授权成功。
- 证据：`artifacts/evidence/C177_auth_gate_attach_boundary_20260925.json`；原始日志和命令文件位于 `runs/EPT-AUTHGATE-20260925-07/`、`runs/EPT-AUTHGATE-20260925-08/`。
- 本边界只保留 Guest 内存观察，不生成可复用补丁产物或许可证数据；正常真实卡运行仍保持 `SAMPLE_LAUNCH_HELD`。
## 13. 2026-09-25 静态授权阶段交叉核对

- 使用完整 `artifacts/captures/stream_C6/stream_text.bin` 做精确 RIP-relative `LEA`/`MOVABS` 目标扫描，输入长度 `8,257,536`、SHA-256 `5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757`；没有把滑移字节升级为线性 CFG。
- 已确认的静态阶段顺序为：`StoredVerify.begin`/`StoredAuthorizationUsable` → `SP_Verify_Init` → `yz.hwid001.com`/`StoredVerify.SetHost` → `SP_Verify_GetServerOption` → `SP_Verify_CardLogin` → `SP_Verify_IsLogin` → `SP_Cloud_Beat`。
- `0x1407a320e` 取得 `0x141154ae7` 地址，`0x1407a3215` 调用 `0x1403b3d30`；C20/C43b 与本轮字节扫描一致。该结果把 CardLogin 写入登录态全局的地址传递边界钉住，但没有恢复 SDK 内部写入或网络报文。
- C176 的动态解析结论保持不变：IAT 有 `LoadLibraryA`/`GetModuleHandleA`/`GetProcAddress`，直接 IAT 没有 `socket`/`connect`/`send`/`recv`/`WSAStartup`；实际 runtime resolver caller、buffer、长度、返回码和许可 response 仍 `UNRESOLVED`/`NOT_OBSERVED`。
- 证据：`artifacts/evidence/C178_static_stage_xref_boundary_20260925.json`。本轮没有启动样本、连接 C2、解码 token、注入 response 或生成补丁产物。



---

## 14. 2026-09-25 授权门数据放行与真实阶段链（重要突破）

- 用**纯数据写入**放行授权：CDB 内 \`ed 0x141154ced 1 / ed 0x141154cf1 1 / eb 0x141154ae7 1 / ed 0x141154ce9 1\`。同一 attach 会话内读回确认：写入前四项全为 0，写入后四项全为 1。不修改代码页、不产生分发包、随进程退出消失。门谓词来自静态：\`0x1407a3080\` 对四全局做短路合取。
- 放行后样本**首次进入真实验证链**并吐出真实阶段名与返回码：\`Setup.SP_Verify_Init\` → **r9d=0（SP_NOERROR）**；\`Setup.SP_Verify_GetServerOption\` → **r9d=0xfffffffd（-3）**，而 -3 正落在静态恢复的 soft-allow 集 \`{-39,-38,-16,-4,-3,-2,-1,0}\` 内。
- 阶段日志断点：\`ba e 1 1407adae0\`，动作 \`da r8 ; r r9d ; k L12 ; g\`。\`0x1407adae0\` 是两条流程共用的阶段日志函数，r8=标签串，r9d=阶段返回码。
- 网络面确认：放行后加载 \`napinsp/pnrpnsp/wshbth/NLAapi/mswsock/DNSAPI/NSI/winrnr/fwpuclnt/rasadhlp\`，即 Winsock 与名称解析栈；但无任何 TCP 连接（无 SYN_SENT、无监听）。
- **真正的当前阻塞**：子进程主线程处于 \`Wait/UserRequest\`，CPU 在连续 40–95 秒窗口内逐位不变，属用户交互等待；样本以 SYSTEM 跑在 **session 0**，无交互桌面，因此无人可应答。API 层跳过 MessageBox 家族（\`bu user32!MessageBoxW/A/ExW/TimeoutW\` + \`r eax=1; g @$ra\`）已成功跳过两个框（\`SKIP_MSGBOXA\`、\`SKIP_MSGBOXTO\`），但仍进入用户等待，说明还有至少一个未识别的阻塞 UI 调用。这是仪器边界，不是授权结论。
- **架构发现（Setup 与 Stored 分离）**：镜像内存在两套流程标签，\`SetupFlow.begin/Setup.SP_Verify_*/Setup.SaveConfig/Setup.StoredAuthorizationUsableAfterSave\` 与 \`StoredFlow.begin/LoadConfig/StoredAuthorizationUsable\`。全镜像 RIP 相对引用扫描证明 \`Setup.*\` 串**没有任何 RIP 相对引用点**；运行时用 \`k L12\` 定位到 Setup 驱动器执行地址 **\`0x142037706\`**，其调用者为 **\`0x1407b1094\`**（也就是调用 \`main 0x1407a4b90\` 的同一调度器）。\`0x142037xxx\` 是重度 VMProtect 虚拟化区，静态判定点不可恢复。
- **阴性结果**：把 StoredVerify 侧阶段 SDK 函数入口改成 \`xor eax,eax; ret\`（SetHost \`0x1403b3280\`、Init \`0x1403b34d0\`、GetServerOption \`0x1403c47e0\`、CardLogin \`0x1403b3d30\`、IsLogin \`0x1403c49d0\`）**没有改变** Setup 侧记录的阶段码，证明 Setup 流程使用独立实现。
- 后行为标志物全部缺失：\`Logs\`/\`HardwareLogs\`/\`R3.exe\`/\`Hardware.ini\`/\`HardwareTask.xml\`/计划任务 \`\Microsoft\Hardware\`/驱动均未出现。**过存储授权门是必要条件但不充分**，Setup 验证流程的网络阶段仍须成功。
- 证据：\`artifacts/evidence/C179_auth_gate_data_release_20260925.json\`；原始运行目录 \`runs/EPT-AUTHGATE-20260925-09\` 至 \`-14\`。
- 下一步（按信息增益排序）：① 用 \`k\` 栈回溯定位剩余阻塞 UI 调用（\`user32!GetMessageW\`/\`DialogBoxParamW\`/\`MessageBoxIndirectW\`）；② 或改在 **session 1 有桌面**的环境运行，使 UI 可被应答；③ 或在 SDK 边界拦截 Setup 侧阶段函数强制返回 0。
- 清理：-09 至 -14 全部收尾，Guest 相关进程 0、hosts 钉已移除、计划任务已注销；权威宿主样本与 Guest 派生物哈希未变。

## 15. 2026-09-25 主程序入口门与解码授权门严格分离

- C179/C180 的四全局写入（ced/cf1/ae7/ce9）只能标记为 `MAIN_ENTRY_GATE_RELEASED`，含义是允许进入主程序 GUI/入口观察；不得写成解码授权通过、真实许可成功或 RC00 已发生。
- `EPT-AUTHGATE-20260925-20` 在无 `-k` 参数下仍只观察到 `Setup.SP_Verify_Init=0` 和 `Setup.SP_Verify_GetServerOption=0xfffffffd`，随后进入消息框/`FatalExit`。
- 本轮没有 `StoredFlow`、`Run.*`、`StoredAuthorizationUsableBeforeDriver`、`skip_driver_load_because_authorization_not_usable`、`HIT_OPEN_AUTH`、`HIT_COMM_INIT` 或 `HIT_RC00`；RC03、RC06、`target_native_return` 和 `target_caller_diff_bytes` 均未取得。
- `Hardware.exe`/`EPT.cmd` 自部署文件和既有任务不能证明解码后行为；后授权标志物仍未观察。
- 当前准确结论：`MAIN_ENTRY_GATE_RELEASED_BUT_DECODE_AUTHORIZATION_NOT_PASSED`。证据：`artifacts/evidence/C180_decode_gate_not_passed_20260925.json`。

## 16. 2026-09-25 当前状态与目标

### 当前状态

- 四个全局变量的临时内存写入只属于 `MAIN_ENTRY_GATE_RELEASED`：它让主程序入口/GUI继续运行，不代表卡密有效，不代表解码授权通过，也不代表真实 RC00 发生。
- `EPT-AUTHGATE-20260925-25`（C182）仍停在 `Setup.SP_Verify_GetServerOption=0xfffffffd`，随后进入服务器配置失败消息和 `FatalExit`。本轮没有观察到 `StoredFlow`、`Run.*`、`StoredAuthorizationUsableBeforeDriver`、`skip_driver_load_because_authorization_not_usable`、`HIT_OPEN_AUTH`、`HIT_COMM_INIT` 或 `HIT_RC00`。
- C182 的结论是 `SETUP_SERVER_OPTION_FAILURE`，按 Windows Guest runbook 分类为 `INCONCLUSIVE`，不能写成授权阴性，也不能写成解码失败。
- C183 的完整镜像引用扫描未恢复 Run/driver dispatch；相关字符串在明文区无 RIP-relative 或 raw absolute 引用，继续重复 plaintext `.text` 扫描没有信息增益。
- `target_native_return`、`target_caller_diff_bytes`、caller `+0x80` 前后缓冲、RC03、RC06、目标代码页差异、PID/PPID 归因和解码后行为均为 `NOT_OBSERVED`。
- 收尾已验证：Guest 相关进程为 0，实验任务为 0，hosts 网络钉为 0；C182/C183 原始证据和 C180 结论保留。

### 当前目标

- 在真实样本 Guest 派生进程的同一次运行中，继续定位并临时放行真正的 Stored/Run 解码授权门；只允许 Guest 副本内存级、可回滚研究，不修改权威样本，不生成可分发绕过包。
- 证明样本进入真实驱动/设备初始化和 RC00，再继续观察 RC03、RC06 及其消费者；不能用主程序入口门、harness、静态字符串、合成 response 或历史结果替代。
- 最终验收必须在同一次真实 Guest 运行中同时取得：`target_native_return == 0x1`、`target_caller_diff_bytes > 0`、命中切口、caller `+0x80` 前后缓冲、响应来源、目标代码页前后差异、目标 PID/PPID 以及 RC06 后自然行为。

### 执行边界

- 无真实卡密：不搜索、不猜测、不模拟、不使用历史卡密哈希或 harness 输出替代。
- 不连接真实 C2，不注入 response；Guest 网络保持断开或按运行契约临时钉死并在收尾移除。
- 每轮使用唯一 RUN_ID、先收割后回滚；工具失败、超时、无命中和通信断开分别分类，不能升级为业务结论。
- 下一步优先分析已有 runtime `.Sq>`/VMProtect dispatch 证据和运行时调度边界；不再重复已证明无信息增益的明文 `.text` 线性扫描。

证据索引：`C180_decode_gate_not_passed_20260925.json`、`C182_authgate_run25_20260925.json`、`C183_run_dispatch_refscan_sq_boundary_20260925.json`。
