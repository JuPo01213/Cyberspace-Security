# C184：授权闸门阶段强制链（runs 26–36）——从入口闸门到主 GUI 与应用并启动管线

日期：2026-09-25
evidence_scope：`real_sample_guest_run_with_predecode_gate_release`（全部强制均为运行时、内存内、按运行编号登记的最小前置放行；无 response 注入、无卡密伪造、无可分发补丁产物）
Guest：<VM_LABEL>（Win10 Pro 19045，Gen1，网卡断开，yz.hwid001.com hosts 钉到 127.0.0.1，每轮收割后摘除）
目标谱系：`C:\ept_core\Hardware.exe` SHA-256 `CFA6998E…AFB28BD7` ← 权威样本 `<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe` SHA-256 `CA6B4C6A…D87ACAA3B2`；child 为 `C:\Windows\TEMP\EPT_*.exe` 自然派生。

## 1. 本阶段静态 groundwork（全部来自 runs/EPT-STATIC-SDK-20260925-01/image_140000000.bin，66,596,864 B，SHA-256 82D3185B…29893B，VA=ImageBase+file_offset）

| 对象 | 地址 | 事实 |
|---|---|---|
| 阶段日志 wrapper-1 | `0x14078fe80` | 签名 `(rcx=tag, edx=code)`；`call 0x1407adae0` 结束于 `0x14078fed9`；**尾 epilogue `mov rbx,[rsp+0x260]` 恢复调用方 rbx（=阶段码）后 `ret`@`0x14078ff03`** |
| 阶段日志 wrapper-2 | `0x14078ff10` | 同构，调 logger2 `0x1407adb40`，`ret`@`0x14078ff87`；承载布尔阶段族 |
| logger1 | `0x1407adae0` | 共享阶段 logger；动作 `da r8; r r9d` 可读 tag+code |
| logger2（码名日志） | `0x1407adb40` | 两种调用形状：wrapper-2 传 `(r8=tag, r9d=code)`；**虚拟化驱动直接调用**传 `(r8=code, r9=码名串VA)` |
| SP_ 码名表 | `0x140f8e060` | SP_NOINIT/SP_WSAFAILED/SP_CONNECTFAILED(-3 实测)/SP_DATAERROR/SP_NOLOADCLOUDDLL/SP_FAILEDWRITE/SP_EXPIREDTOKEN/SP_UNKNOWNERRROR/SP_INVALIDCARD/SP_EXPIREDCARD/SP_BANNEDCARD/SP_INVALIDAGENT… |
| 免责窗口 | 类 `NspFirstRunDisclaimerWindow`（**ANSI 注册**：`FindWindowW` 不命中，必须 `EnumWindows`/`EnumChildWindows`） | 标题「免责及使用协议」；按钮「同意并继续」/「不同意并退出」；协议正文：《虚拟硬件信息修改工具 免责及使用协议》（自称仅内存内临时变更硬件标识） |
| 主窗口 | 类 `NspSetupWindow`，标题「EPT Hardware Console - 硬件配置档管理客户端 \| 本机授权校验」 | **KEY 字段 = 要写入的硬件标识值**（`0x140f8fc40`『默认以KEY码作为固定标识写入』），不是授权凭证；配置文件走 BCrypt 加密（密钥导入/加密向量/数据加密全套错误文案）；`-k/-n/-m/-h` CLI 参数链 @`0x1407a56b4..0x1407a5723` |
| GUI 空检查 | `0x14079689c` `cmp qword [rbp-0x70],0` | 空 KEY →「请输入KEY授权码。」（`0x140f8fcd0`）msgbox 调用点 `0x1407968ba`（调用方栈帧 `0x1407968c0` ← `0x1407991e1` ← CallWindowProcW——**纯明文**） |
| 全池引用扫描 | `runs/EPT-STATIC-SDK-20260925-01/pool_refs.json` | 528 条 GBK 串、246 条被 .text 引用，含「正在验证 KEY 授权...」@`0x140796a68`、配置/部署全套文案 |

## 2. 逐轮动态结果（cdb 附加自然 `EPT_*` child；SYSTEM 计划任务启动；每轮独立 RUN_ID 与原始收割件）

| RUN | 结果 | 关键事实 |
|---|---|---|
| 26 | INVALID_INSTRUMENT | `j` 在断点动作内执行完分支即终止整条动作链（`; g` 不再执行）→ 脚本落穿 `q` 杀目标。**教训：bp 动作内禁用 j/嵌套引号条件执行；只用 run24 已验证的 echo/da/r/k/g 形态** |
| 27 | 部分 POSITIVE | **wrapper-1 ret 单点强制（`ba e 1 14078ff03` + `r rbx; r eax=0; r ebx=0`）成立**：Init=0→GetServerOption=-3→GetNotice=-3 全部归零放行；GetNotice 后撞第三条日志路径停滞（TextShaping 加载） |
| 28 | POSITIVE（观测） | 第三条路径=logger2 码名调用：`r8=-3, r9d=0x140f8e060(SP_CONNECTFAILED)`；**调用栈证明虚拟化驱动直接调用 logger2，驱动内返回位点 `0x142037792`** |
| 29 | POSITIVE | `ba e 1 142037792` 命中，**`rbx=0xfffffffd`（阶段码确在 rbx，驱动约定证实）**，归零后链条前进，再停滞于 UI 等待 |
| 30 | POSITIVE（观测） | 强制 CardLogin 后驱动建窗（CreateWindowExA 族）；`GetMessageA` 泵被 WM_QUIT 切断 → 驱动走 `FatalExit`（返回址 `0x1420378b1`）进程终止 → **「不同意并退出」等价路径** |
| 31 | POSITIVE（识别） | 跳过 FatalExit → 撞驱动自家 `int3` 陷阱 `0x1407a7ded`（死路确认）；**免责窗口识别**（GBK 池解码：NspFirstRunDisclaimerWindow 全套文案） |
| 32 | INVALID_INSTRUMENT | winproc.ps1 未加入 host_prep 拷贝清单 → helper `-File` 指向不存在文件即死 |
| 33 | **重大 POSITIVE** | SYSTEM 一次性任务经 EnumChildWindows 找到「同意并继续」按钮（hwnd 7733356），`PostMessage BM_CLICK` 成功；**免责窗口完整控件树取证**（2×Static+协议 Edit+2×Button）；**样本首次自然进入主 GUI**（NspSetupWindow 控件群：KEY 信息/序列模式/功能模式/应用并启动/安装部署） |
| 34 | POSITIVE（定位） | 空 KEY 点「应用并启动」→「请输入KEY授权码。」msgbox——**验证链在明文 GUI 代码**（空检查 `0x14079689c` → msgbox `0x1407968c0` ← 处理器 `0x1407991e1`）；msgbox 跳过后 GUI 泵存活。另：helper v2 Add-Type 漏 `GetWindowThreadProcessId` 导入（经前台复跑捕获异常定位） |
| 35 | 重大 POSITIVE | KEY 填 `1234567890`（WM_SETTEXT 首个 Edit）+应用并启动 → **驱动真实新阶段链**：`Setup.SP_Verify_CardLogin=-21`（wrapper-1 强制点同样抓住 GUI 触发的阶段，rbx=-21→0）→ `SaveConfig=1` → `StoredAuthorizationUsableAfterSave=1`×2（位点 `0x142038fab`/`0x142038fc3`）→ `IsLogin=0`（位点 `0x142039028`）→ msgbox「**服务器校验失败！**」(`0x140f931a8`) → FatalExit（驱动位点 `0x142039034`）。**布尔阶段族走 wrapper-2/logger2** |
| 36 | （本轮收尾时收割，结果见 §4 补记） | wrapper-2 ret（`0x14078ff87`）强制 `rbx=1`（布尔阶段族全真）+ msgbox/FatalExit 均跳过；合并式 helper（同意→KEY→应用并启动一次完成，参数化修复） |

## 3. 当前机制全景（供下轮直接使用）

```text
入口闸门（每轮，CDB 附加后写内存）:
  ed 0x141154ced 1; ed 0x141154cf1 1; eb 0x141154ae7 1; ed 0x141154ce9 1

SDK 阶段函数内存补丁（C179 已验证手法，防 GUI 校验走 SDK 路径）:
  eb 0x1403b34d0 / 0x1403b3280 / 0x1403c47e0 / 0x1403b3d30 / 0x1403c49d0  →  33 c0 c3

硬件断点（4 个 DR 全用）:
  0x1407adae0  logger1 观测:  da r8; r r9d
  0x1407adb40  logger2 观测:  r r8; r r9d（+k L6 抓新驱动位点）
  0x14078ff03  wrapper-1 ret 强制:  r rbx(记录); r eax=0; r ebx=0   ← 阶段码族（0=成功语义）
  0x14078ff87  wrapper-2 ret 强制:  r rbx(记录); r rbx=1           ← 布尔阶段族（1=true 语义）

软件断点: MessageBoxA/W + SoftModal（跳过 eax=1）、FatalExit（跳过 rip=[rsp]）、
          CreateWindowExA（du rdx/r8）、CreateFileW（du rcx）、CreateProcessW/A、
          StartServiceW/A（观测）、Sleep（r rcx）

UI 自动化（SYSTEM 会话 0，与目标同会话; PostMessage BM_CLICK=0xF5 / SendMessage WM_SETTEXT=0x000C）:
  NspFirstRunDisclaimerWindow →「同意并继续」
  NspSetupWindow → 首个 Edit WM_SETTEXT '1234567890' →「应用并启动」
  （类匹配必须 EnumWindows/EnumChildWindows；FindWindowW 对 ANSI 注册类不命中）
```

## 4. RUN 36 补记（已收割；Guest 侧 spool 目录名误用 35 前缀——host_prep 漏 sed 运行号，宿主侧归档目录正确）

helper 全链成功：CLICK_AGREE → KEY_SETTEXT('1234567890' → NspSetupWindow 首个 Edit) → CLICK_APPSTART。cdb 侧新序列（`runs/EPT-AUTHGATE-20260925-36/cdb.stdout.txt`）：

```text
101/106  STAGE_LOG2_CODENAME → STAGE_FORCE_POINT2_TRUE    SaveConfig=1 / StoredAuthUsableAfterSave=1（强制为 1，无变化）
111      STAGE_LOG2_CODENAME                              （第三个布尔阶段）
124/129  STAGE_LOG ×2                                     wrapper-1 码族阶段（含 CardLogin 重跑）
133      STAGE_LOG2_CODENAME → STAGE_FORCE_POINT2_TRUE    IsLogin 0→1 强制为真
138/140  CPA_OBS ×2   CreateProcessA 命令行含 sc.exe config（服务配置创建；ANSI 串被 du 显示为 UTF16 mojibake，原始字节在 stdout 内）
143/146/161  STARTSVCA ×3  StartServiceA（服务启动尝试；rcx 为 SC_HANDLE 非串——服务名需下轮挂 CreateServiceA/OpenServiceA 观测）
153      CFW "C:\Windows\TEMP\GxtzesMZfGLDHgvp" / "kudcHHlnJWaZB"   随机名临时载荷文件
163      FATALEXIT_SKIPPED（明文 0x1407aa694，main 区段）→ 进程其后退出
```

post_snapshot 物证：**`C:\Windows\System32\Hardware\Hardware`（900 B）配置文件真实落盘**（SaveConfig=true 的独立物证）；无计划任务/日志目录/驱动文件/服务残留（StartServiceA 在无驱动文件的隔离环境失败）。

结论：布尔强制 + FatalExit 跳过使样本走完 Setup→GUI→应用并启动→配置落盘→**服务安装/启动尝试**的真实管线；终点是无驱动可装（隔离环境）+ 明文 main 区段失败 FatalExit（被跳过后进程退出）。首次观测到部署域行为（sc.exe/StartService/临时载荷文件）。

## 5. 距完成判据的差额（诚实边界）

- 已闭合：真实 child 谱系、入口闸门、Setup 链前 3 阶段+CardLogin 的真实执行与强制放行、免责声明自然点击、主 GUI 自然进入、KEY→应用并启动触发的真实配置/验证阶段链（SaveConfig=true=配置已加密落盘）。
- 未闭合：`IsLogin` 登录会话（run35 记 0）→「服务器校验失败！」失败块（msgbox `0x14203902e` + FatalExit `0x142039034`）之后的链条；RC00/RC03/RC06 seam；`target_native_return`/`target_caller_diff_bytes`；以及全部解码后行为（HWID 实际修改、伪装进程/R3.exe、计划任务 `\Microsoft\Hardware`、`System32\Logs`/`HardwareLogs`、痕迹清理）。
- 对应 rules：`AUTH_GATE_PARTIALLY_RELEASED / ISLOGIN_SESSION_UNRESOLVED / TARGET_SEAM_NOT_CLOSED / POST_DECODE_BEHAVIOR_NOT_OBSERVED`。
