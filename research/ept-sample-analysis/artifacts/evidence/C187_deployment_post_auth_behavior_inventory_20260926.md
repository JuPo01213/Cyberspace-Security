# C187 · 强制放行部署管线的授权后行为清单与 payload=解码输出假设（runs 52-68）

日期：2026-09-26 · 运行窗口：EPT-AUTHGATE-20260925-52 … 65（含 65 目录内循环 66-68）· Guest：<VM_LABEL> · 基线检查点：C173-gen1-ready2

## 1. 目的与方法

目标（用户 2026-09-26 指令）：完成破解授权后的行为分析。方法：对真实样本 Guest 运行（谱系 CFA6998ECC2F…，源自 <HOST_PATH>\EPT\sample\CA6B4C6A…）做强推管线（入口闸门释放 + SDK 五阶段置零 + 调度器二道闸合成返回），以 cdb 双层（kernel32/kernelbase）API 断点 + 文件尺寸 watcher（500ms）+ 文件即时捕获器观测。每轮 run.json 记录假设/验收/停损；循环重试以对冲保护的反调试随机化。

## 2. 结果三分类（12+ 轮实测）

| 类别 | 特征 | 轮次 |
|---|---|---|
| 完整管线 | GUI 三窗（NspSetupWindow）→ 卡密输入 → wmic×11+ipconfig 指纹采集 → payload 文件创建+7.9MB 写入尝试 → HpDrv*.sys×2 投放 → sc.exe config ×2 → FATAL@0x1407aa694 | 52,53,55,56,60 |
| 快线 | 无 GUI/wmic/payload 写入，其余同上 | 57,65,66 |
| 秒死 | 管线启动前 ExitProcess@0x143ae5d57（EXIT_PROCESS_SKIPPED 拦截后线程仍完成退出） | 54,58,59,61,62,63,64 |

已排除的环境因子（各自单变量验证）：检查点恢复/污染（56 真恢复=完整，59 真恢复=秒死）、父进程 cdb（58/59 秒死但 61-64 无父 cdb 也秒死）、Temp 同名残留（62 清理 count=8 后仍秒死）、ntdll!/SetEndOfFile SW 断点（63/64 去除后仍秒死）、磁盘空间（39GB 空闲）、Defender（实时防护开、零检测）。结论：三分类为保护随机化决策，应对=循环重试。

## 3. 授权后（强制放行）行为清单 【本轮核心交付】

1. **机器指纹采集**：`cmd.exe /d /c wmic …` ×11（baseboard SerialNumber、csproduct UUID/Name、bios SerialNumber、diskdrive SerialNumber、cpu ProcessorId/SerialNumber、Win32_VideoController Name、memorychip SerialNumber、NetworkAdapterConfiguration）+ `ipconfig /all`，输出经管道读回（RDF×13）。
2. **指纹落盘**：`C:\Windows\System32\Hardware.ini` 全量写入（BoardId/Uuid/BrandModel=Virtual Machine/BiosSerial/DiskSerials=None/CpuIds=1F8BFBFF00090675/Gpus=Microsoft Hyper-V Video/Macs/Gateways/Duid，[Meta] Version=2），并有 GFS+RDF 读回动作。
3. **驱动组件投放**：`C:\Windows\Temp\HpDrv<17随机>.sys` ×2-3，单文件 19,128 字节；**两个不同随机名内容 SHA-256 完全相同**（bf07c46effde8b6b0fd3c9586a5a9636800fb37418c1e8e606c67cb613cbf832）——名字随机化、内容固定。
4. **服务伪装持久化准备**：`sc.exe config "AntiCheatExpert Protection" start= delayed-auto`、`sc.exe config "AntiCheatExpert Service" start= delayed-auto`（腾讯 ACE 反作弊命名伪装；服务本体由 payload 安装步骤创建，强推下未创建故 config 打空）。
5. **卸载脚本与加密日志**：`C:\Windows\System32\EPT.cmd`（1093B）每轮重写；`C:\Windows\System32\Hardware`（900B）= 4 字节长度前缀(0x380)+密文的追加式日志。

## 4. 驱动组件静态三连（19,128B，x64 KMDF）

- PDB 路径：`<HOST_PATH>\Users\<USER>\Documents\WorkingDirectory\_swtoolsdriver\swtoolsdriver\Driver\Output\x64\Release\swtoolsdriver.pdb`
- 设备对象：`\Device\HP_WKS_SWTOOLS_DRIVER` + `\DosDevices\HP_WKS_SWTOOLS_DRIVER`（与历史 RECON 证据的设备名一致 ⇒ RC00 请求的真实载体）
- 导入：IoCreateDevice/IoCreateSymbolicLink/IoAllocateMdl/MmBuildMdlForNonPagedPool/MmMapLockedPagesSpecifyCache/MmMapIoSpace/HalGet/SetBusDataByOffset（硬件访问型）
- 签名：Microsoft Windows Hardware Compatibility Publisher（attestation），有效期 2018-09-06 → **2019-09-06 已过期 7 年** ⇒ 当前系统上加载必然受签名过期影响（testsigning 不豁免过期 WHQL 的完整校验路径），这是后续驱动加载分支的头号嫌疑
- IOCTL：全量反汇编待下阶段（.text 仅 0x8c7 字节）

## 5. payload=解码输出假设（本阶段最重要新假设）

7.9MB（7,966,720B）写入缓冲区在写入瞬间：头 8 字节 = `4D 5A 90 00 03 00 00 00`（MZ），尾 8 字节 = 全零；!address 证明缓冲区为单一健康堆块（0x49a2000-0x5508000，MEM_COMMIT/PAGE_READWRITE，11.4MB）——排除 MDL 锁定失败。文件终态恒 0 字节（watcher 500ms 全程无字节，排除"成功后被清理"）。

⇒ 缓冲区"头部有效 + 主体全零"最自然解释：**7.9MB payload 是解码器的预期输出**，头部由模板/部分解码产生，主体依赖 RC00/RC03/RC06 解码 seam 提供内容。强推只能绕过安装器层检查；FATAL@0x1407aa694 即 payload 完整性校验失败点（该区域代码运行时动态生成——attach 时 0x1407aa640-aa6b0 全零，静态分析须运行中转储）。因此：**不解开 RC00 seam，payload 无法物质化，部署组件（及 R3.exe/\Microsoft\Hardware 任务/Logs 目录等成功标志）无法出现**。这与 AGENTS.md 的原判据框架（解码不是目的但仍是闸门）重新闭合。

## 6. 仪器沉淀（已写入技能文件）

- Guest cdb 本地 PDB 缓存遮蔽导出名（ExitProcess→ExitProcessImplementation 等），`bu mod!sym` 硬失败整行丢失；修复=移走缓存或用 kernelbase!/PDB 真名（canary-gate 化）
- 断点必须覆盖 kernel32+kernelbase 两层（样本绕过 kernel32 直接 kernelbase!CreateFileW）
- 两个退出路径：fatal-thunk（HW 断点+合成返回可拦截）/ 直接 ExitProcess@0x143ae5d57（强制跳过只能延缓）
- ntdll 层 SW 断点在秒死轮中出现但单独去除未恢复完整线（多次单变量证伪记录于 runs_61_65_consolidated.json）
- 检查点恢复必须地面判据验证（spool 消失+恢复态特有文件不存在，如 Hardware.ini 在检查点早于首次指纹写入时不应存在）
- watcher 即时捕获器（FileShare.ReadWrite 流复制+重试）是抓取自清理文件（.sys）的唯一可靠手段

## 7. 台账状态

- `target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（本阶段不变）
- 授权后行为证据：见 §3（本轮新增闭环）
- 下一阶段优先级：① 驱动全量反汇编（IOCTL 契约→RC00 请求构造）② 运行中转储 0x1407aa694 决策点 ③ 0x2437b697 常量与秒死触发条件的对照 ④ 解码 seam（driver response 受控注入的合法性问题回到 AGENTS.md 框架）

证据文件：runs/EPT-AUTHGATE-20260925-52…65（每轮 run.json/cdb.stdout/watcher.csv/captured/）；驱动二进制 captured/captured/HpDrv*.sys.bin（SHA-256 见 §4）
