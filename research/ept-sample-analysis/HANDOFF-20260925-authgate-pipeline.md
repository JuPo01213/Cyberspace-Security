# 交接文档：授权闸门强制链 → 部署管线（2026-09-25 收官）

> **2026-09-26 更新（runs 52-68）：** 授权后行为清单已闭环，见 `artifacts/evidence/C187_deployment_post_auth_behavior_inventory_20260926.md`。要点：① 行为清单=指纹采集(11×wmic+ipconfig)→Hardware.ini 落盘→HpDrv*.sys 驱动投放(19128B, 内容固定 SHA bf07c46e…, WHQL 签名 2019 过期, 设备 \Device\HP_WKS_SWTOOLS_DRIVER)→AntiCheatExpert 伪装服务 config→EPT.cmd/加密日志；② 7.9MB payload=解码输出假设（缓冲区头 MZ+主体全零，文件恒 0 字节，FATAL@0x1407aa694=payload 校验点，该区域运行时生成）；③ 结果三分类（完整/快线/秒死）为保护随机化，循环重试应对；④ 仪器修复：cdb PDB 缓存遮蔽、kernelbase 双层观测、抓取 watcher。RC00/RC03/RC06 seam 仍 NOT_OBSERVED——payload 物质化被解码 seam 卡住，下一阶段=驱动全量反汇编（IOCTL→RC00 契约）。runs/EPT-AUTHGATE-20260925-52…65 + runs_61_65_consolidated.json。


> 交接背景：本轮会话上下文已不干净，用户新开会话继续。本文件 + `artifacts/evidence/C184_authgate_stage_force_chain_20260925.md` + `runs/EPT-AUTHGATE-20260925-{26..36}/` 构成完整交接物。

## 1. 一段话说清当前位置

**样本的真实授权/部署管线已被打通到部署域。** 通过「4 个授权全局变量写入（入口闸门）→ wrapper-1 ret 阶段码归零（代码族）→ wrapper-2 ret 强制 1（布尔族）→ UI 自动化点击免责声明『同意并继续』→ 向主 GUI KEY 框写入测试值 → 点击『应用并启动』」，样本在同一轮真实 Guest 运行中完成了：Setup 验证链（Init/GetServerOption/GetNotice/CardLogin）→ 免责声明 → 主 GUI → KEY 配置验证 → **加密配置落盘（`C:\Windows\System32\Hardware\Hardware`，900 B）→ `sc.exe config` 服务创建 → `StartServiceA` ×3 服务启动尝试 → 随机名临时载荷文件（`%TEMP%\GxtzesMZfGLDHgvp` 等）**。终点：隔离环境无驱动文件可装，明文 main 区段（`0x1407aa694`）调 FatalExit（本轮被跳过后进程退出）。

**尚未拿到**：RC00/RC03/RC06 seam（`target_native_return`/`target_caller_diff_bytes`）、驱动加载成功后的解码后行为（HWID 修改、伪装进程/R3.exe、`\Microsoft\Hardware` 计划任务、`System32\Logs`/`HardwareLogs`、痕迹清理）。按 AGENTS.md 完成判据，项目**未完成**。

## 2. 强制机制速查（下一轮直接照抄）

```text
CDB 附加自然 EPT_* child 后、go 之前：
  ed 0x141154ced 1; ed 0x141154cf1 1; eb 0x141154ae7 1; ed 0x141154ce9 1   ← 入口闸门
  eb 0x1403b34d0/0x1403b3280/0x1403c47e0/0x1403b3d30/0x1403c49d0 33 c0 c3  ← SDK 阶段函数补丁
硬件断点（DR0-3 全占，不可再加）：
  ba e 1 1407adae0  ".echo STAGE_LOG; da r8; r r9d; g"              ← logger1 观测（码族）
  ba e 1 1407adb40  ".echo STAGE_LOG2_CODENAME; r r8; r r9d; g"     ← logger2 观测（布尔族/码名；+k L6 可抓新驱动位点）
  ba e 1 14078ff03  ".echo STAGE_FORCE_POINT; r rbx; r eax=0; r ebx=0; g"   ← 码族强制归零
  ba e 1 14078ff87  ".echo STAGE_FORCE_POINT2_TRUE; r rbx; r rbx=1; g"      ← 布尔族强制真
软件断点：MessageBoxA/W、SoftModalMessageBox（跳过 eax=1）；kernel32!FatalExit（跳过 rip=poi(rsp)）；
         CreateWindowExA（观测）、CreateFileW（du rcx）、CreateProcessW/A（du rdx）、Sleep（r rcx）
UI 自动化（SYSTEM 会话 0 助手，模板 runs/EPT-AUTHGATE-20260925-36/winproc.ps1）：
  NspFirstRunDisclaimerWindow「同意并继续」→ NspSetupWindow 首个 Edit WM_SETTEXT '1234567890' →「应用并启动」
```

已探明的驱动内位点：`0x142037792`（GetServerOption 后/CardLogin 检查点，rbx=码）、`0x142038fab`/`0x142038fc3`（StoredAuthUsableAfterSave）、`0x142039028`（IsLogin）、`0x14203902e→0x142039034`（服务器校验失败 msgbox+FatalExit）、`0x1407aa694`（明文 main 区段 FatalExit）。

## 3. 下一轮建议动作（按优先级）

1. **观测驱动加载失败的完整后果**：run 36 终点是 StartService 失败 → 明文 FatalExit。下一轮在 FatalExit（`0x1407aa694`）处**不跳过**，先抓 `k` 看上游是谁（哪个函数在无驱动时决定退出），再决定：跳过它继续（预期进入 Cloud_Beat/Run 调度 → RC00 路径）还是先补驱动侧。
2. **补部署域观测断点**：`advapi32!CreateServiceA/W`、`OpenServiceA/W`（拿服务名——StartServiceA 的 rcx 是句柄不是名字）；`kernel32!WriteFile`（临时载荷文件内容）；对 `%TEMP%\GxtzesMZfGLDHgvp`/`kudcHHlnJWaZB` 在运行后落盘取证（收割脚本加 Copy-Item）。
3. **RC00 判据**：一旦进入 Run 调度（`0x1407b1094` → main → `0x14078d...` RC00 区），挂 `0x14078de50`(OPEN_AUTH)/`0x14078e8c0`(COMM_INIT) 硬件断点（本轮为省 DR 未挂），抓 `target_native_return`/caller +0x80 前后缓冲。注意 RECON-6 结论仍有效：样本不走 `\\.\HP_WKS_SWTOOLS_DRIVER` 设备 I/O，解码 seam 的 response 来源问题要在新证据下重新评估。
4. **KEY 值**：`1234567890` 通过了 GUI 数字检查、被驱动 CardLogin 记 -21（强制放行）并写入落盘配置。KEY=写入的硬件标识值本身（非凭证）。若后续阶段对 KEY 有格式要求，静态入口：`0x14079689c`（空检查）后的明文 GUI 校验链 + pool_refs.json。
5. **环境决策点（需用户裁决级别）**：StartService 失败的根因是隔离环境无驱动文件（有界阴性：全盘无 HP_WKS/SWTOOLS .sys）。要让管线走得更远，可能需要：从样本资源/临时载荷中提取驱动文件并落回 Guest（属「组件释放」行为取证——run 36 的随机 TEMP 文件很可能就是释放物，先取证内容再决定）。

## 4. 本轮仪器教训（勿重犯）

- **`j`/条件执行不能用于 cdb 断点动作**：执行完分支即终止整条动作链，`; g` 不再执行（run 26 整轮报废）。
- **FindWindowW 找不到 ANSI 注册的私有类**（NspFirstRunDisclaimerWindow/NspSetupWindow）：必须 EnumWindows+GetClassName；子控件用 EnumChildWindows（FindWindowExW 对 A 侧创建的全局类同样失配）。
- **Add-Type 成员函数漏导入**（GetWindowThreadProcessId）只在回调运行时爆——前台复跑捕获异常定位（run 34）。
- **复用脚本模板时 sed 运行号**：run 36 的 host_prep 漏改 → Guest 侧 spool 目录沿用 35 前缀（宿主侧归档正确，不影响证据，但检索时要看两处）。
- **StartServiceA 的 rcx 是 SC_HANDLE**：拿服务名要挂 CreateServiceA/OpenServiceA。
- `du` 显示 ANSI 串会出 UTF16 mojibake——原始字节就在 cdb.stdout 里，离线按字节解。
- 硬件断点只有 4 个 DR：logger1/logger2/forcer1/forcer2 已占满，新观测只能挤占或改软件断点（user32/kernel32/advapi32 用 `bu` 不占 DR）。
- 采集动作模板必须只用 run24 已验证形态：`.echo/da/du/r/k/u + g`，动作结尾必 `g`。
- 每轮收割后：hosts 钉扎摘除、一次性点击任务反注册、进程清理（host_harvest.ps1 已全部内建）。

## 5. 文件索引

- 证据：`artifacts/evidence/C184_authgate_stage_force_chain_20260925.md`（本阶段总台账）
- 运行原始件：`runs/EPT-AUTHGATE-20260925-26..36/`（cdb.stdout.txt / winproc / post_snapshot / run.json）
- 静态提取镜像与全池引用：`runs/EPT-STATIC-SDK-20260925-01/image_140000000.bin`（SHA-256 82D3185B…29893B）、`pool_refs.json`
- 可复用编排脚本（已验证的 Hyper-V PowerShell Direct + SYSTEM 计划任务 + CDB 附加通道）：`runs/EPT-AUTHGATE-20260925-36/host_prep.ps1` / `guest_launch.ps1` / `host_harvest.ps1` / `winproc.ps1`
- VM：<VM_LABEL>（Running）；基准检查点 `<VM_LABEL>-gen1-channel-ready`
