# EPT 样本（Hardware.exe / "EPT专业游戏维修工具箱V5.1"）分析报告

> 分析目标：定位"授权通过后的真实行为"（HWID 修改 → 伪装进程 → 日志清理）以及"联网更新"部分并阻断之。
> 样本 SHA256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`（32671232 字节，UPX 定制壳）
> 关键轮次：`EPT-INJECT-20260925-23`（非侵入全内存 dump，首次 `CopyFileW` 触发 `.dump /ma`，从解压后内存恢复全部字符串）

---

## 一、网络更新部分（已定位，可阻断）★用户重点需求

**C2 / 更新服务器：`yz.hwid001.com:1029`（TCP，自定义协议，非 HTTP）**

在解压内存中恢复出的授权/云通信函数名与字符串：

| 函数/字符串 | 作用 |
|---|---|
| `StoredVerify.SetHost yz.hwid001.com:1029` | 硬编码主服务器地址+端口 |
| `Setup.SetHost yz.hwid001.com:1029` | （安装/Setup 流程同样连此服务器） |
| `SP_Verify_GetServerOption` | 拉取服务器选项 |
| `SP_Verify_CardLogin` | 用 `-k <card>` 卡号登录校验（即用户说的"授权"） |
| `SP_Verify_GetLastestVersionInfo` | **更新检查**（版本信息） |
| `SP_Verify_GetNotice` | 拉取公告 |
| `SP_Verify_IsLogin` | 登录态校验 |
| `stage=StoredVerify.SP_Cloud_Beat ok=%d ...` | **云心跳/信标（即"联网更新"）** |

> 注：扫描中出现的 `Q51.kr` / `VmD.KR` / `Vp-.JP` 经上下文判定为随机字节误匹配（前后均为非 ASCII 乱码），**非真实域名**。全 dump 唯一真实 `host:port` 即 `yz.hwid001.com:1029`。

**如何阻断（见同目录 `block_ept_network.ps1`）**：
- Guest `hosts` 重定向：`0.0.0.0 yz.hwid001.com` / `hwid001.com` / `www.hwid001.com`；撤销使用 `-Undo`。
- Windows 防火墙出站拒绝规则：幂等地阻断 TCP/1029，并额外阻断当前实验 DNS 返回的 TEST-NET 地址 `198.18.2.159`；脚本不会启动样本。
- 本分析用 VM 的网卡已处于 **Disconnected**，因此样本在沙箱中根本无法外联——这本身就是最强的"屏蔽"。
- 该屏蔽只表示网络隔离，不等同于服务端拒绝、授权失败或许可未下发；网络结论必须单独记录 DNS/TCP/进程归因。

---

## 二、授权流程（为何离线拿不到后行为）★解释卡点

授权为"两段式"：本地 `ioctlAuth`(IoCtl 码) + `magic` 校验，外加**云端校验**。

内存字符串还原的阶段链：
```
C00 open_auth(ioctlAuth=0x%08lX, magic=0x%08lX)
  → C01 open
  → C02 auth_stage0
  → C03 auth_stage1
  → SP_Verify_Init → [init_failed_soft_allow]
  → SetHost yz.hwid001.com:1029
  → SP_Verify_GetServerOption → [option_failed_soft_allow]
  → SP_Verify_CardLogin → [cardlogin_denied_clear_or_block | cardlogin_failed_soft_allow]
  → SP_Verify_IsLogin → [islogin_failed_soft_allow]
  → SP_Cloud_Beat (心跳) → [beat_hard_deny_clear_or_block | beat_not_soft_allow_clear_or_block]
```

失败分支语义：
- `xxx_failed_soft_allow`：失败时**软放行**（可能继续受限运行）
- `xxx_denied_clear_or_block` / `beat_hard_deny_clear_or_block`：**硬拒绝 → 触发自清理**（调用 `EPT.cmd del` 卸载自身）

**结论（收紧口径）**：样本具备 `StoredVerify → SetHost → GetServerOption → CardLogin → IsLogin → Cloud_Beat` 的云校验链，但当前证据只证明发生过 `yz.hwid001.com` 的 DNS 查询，未证明 TCP/1029 建连、授权请求、许可返回或 `CardLogin` 的运行时结果。因而不能把网卡断开、hosts 钉死或无 TCP 连接直接写成“服务端拒绝”或“授权失败”；后续 HWID 修改/伪装/清理在当前运行中仍是 `NOT_OBSERVED`。

---

## 三、授权后行为模型（组件级证据，已落地）★用户重点需求

自部署链（动态已稳定复现）：`DeleteFileW(Hardware.exe.tmp)` → `CopyFileW(ept_core\Hardware.exe → System32\Hardware.exe.tmp)` → `MoveFileExW(.tmp→System32\Hardware.exe)` → `CopyFileW(System32\Hardware.exe → TEMP\EPT_<RAND>_<RAND>.exe)` → 加载 COM/Shell 栈 → 创建 TEMP 子载荷（真正干活的进程）。

| 行为 | 组件/证据 | 来源 |
|---|---|---|
| **HWID 修改** | `C:\Windows\System32\hwid.cmd`（"HWID deployment data cleared" 提示） | 内存字符串 |
| **伪装/干活进程** | `R3.exe` + 配套 `R32.dll`（`EPT.cmd` 清理时 `taskkill /f /im R3.exe`） | 内存字符串 + 清理脚本 |
| **日志清理** | `rmdir /s /q "C:\Windows\System32\Logs"` 与 `"C:\Windows\System32\HardwareLogs"` | `EPT.cmd` 清理脚本（见下） |
| **持久化** | 计划任务 `\Microsoft\Hardware`，XML 来自 `C:\Windows\Temp\HardwareTask.xml` | 内存字符串 + 清理脚本 |
| **自我保护/反作弊** | `sc.exe config "AntiCheatExpert Protection" start= delayed-auto`、`sc.exe config "AntiCheatExpert Service" start= delayed-auto`、请求 `SeDebugPrivilege` | 内存字符串 |

### `EPT.cmd` 卸载/清理脚本全文（= 用户说的"日志清理 + 痕迹清除"）
```
:clear
taskkill /f /im Hardware.exe >nul 2>nul
taskkill /f /im R3.exe >nul 2>nul
schtasks /Delete /TN "\Microsoft\Hardware" /F >nul 2>nul
del /f /q "C:\Windows\System32\Hardware.exe" >nul 2>nul
del /f /q "C:\Windows\System32\Hardware" >nul 2>nul
del /f /q "<HOST_PATH>\<DIR>ware.exe" >nul 2>nul
del /f /q "<HOST_PATH>\<DIR>ware" >nul 2>nul
del /f /q "C:\Windows\Temp\HardwareTask.xml" >nul 2>nul
del /f /q "<HOST_PATH>\<DIR>Task.xml" >nul 2>nul
del /f /q "%TEMP%\HardwareTask.xml" >nul 2>nul
rmdir /s /q "C:\Windows\System32\Logs" >nul 2>nul
rmdir /s /q "C:\Windows\System32\HardwareLogs" >nul 2>nul
rmdir /s /q "<HOST_PATH>\<DIR>" >nul 2>nul
rmdir /s /q "<HOST_PATH>\<DIR>wareLogs" >nul 2>nul
echo [OK] HWID deployment data cleared
```
启动方式：`powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList 'del' -Verb RunAs -Wait"`（提权后自删）。

> 说明：上述为**组件与脚本层面的静态证据**。HWID 具体改写的注册表键（如 `HKLM\SYSTEM\CurrentControlSet\Control\...`、`MachineGuid`、卷序列号、MAC 等）的**动态写操作**尚未捕获，因为授权未通过、改写未执行（见第二节）。

---

## 四、动态捕获后行为的阻塞与下一步

**当前阻塞**：需要先区分“屏蔽噪音”和“取得真实许可”。本项目当前采用默认隔离：Guest 网卡 Disconnected，辅以 hosts/防火墙按域名、TCP/1029 和已观测 fake-IP 的阻断。该配置只保证样本不向外部授权端点发送流量，不提供真实许可，也不应被描述为授权结果。

**当前只保留的推进路线**：
1. **屏蔽与证据分离**：运行前记录网卡状态、hosts、规则和样本哈希；运行后分别统计 DNS、TCP/1029、目标 PID/进程树和本地行为。没有 TCP/1029 时标记 `AUTH_NETWORK_UNOBSERVED`，不进一步推断服务端返回。
2. **静态恢复协议**：仅在本地已有 dump、运行时解密代码和 `.pdata` 边界上恢复 `SP_Verify_CardLogin`/`SP_Cloud_Beat` 的 buffer、长度、编码和返回码。不得连接真实 C2、解码/使用内嵌 token、伪造许可或修改原始样本。
3. **行为结论**：当前 `HWID` 改写、`R3.exe`/`R32.dll`、计划任务和日志清理均保持 `NOT_OBSERVED`；只有同一次真实样本运行中的直接证据才可升级为动态结论。

---

## 五、证据清单
- `EPT-INJECT-20260925-23/harvest/mem_parent.dmp`：样本解压后全内存镜像（95MB），所有字符串来源。
- `EPT-INJECT-20260925-23/harvest/events.ndjson`、`file_changes.json`、`network.ndjson`：动态运行证据（自部署链稳定复现；网络 1386 条连接全为监听、零外联）。
- `EPT-INJECT-20260925-2x` 系列：前序轮次（自部署、反调试、状态机地址、注入尝试）佐证。
- `block_ept_network.ps1`：网络阻断脚本。
