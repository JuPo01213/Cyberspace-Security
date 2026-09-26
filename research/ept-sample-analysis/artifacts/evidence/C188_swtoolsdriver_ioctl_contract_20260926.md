# C188 · swtoolsdriver 驱动全量反汇编：RC00 内核后门契约

日期：2026-09-26 · 证据源：`runs/EPT-AUTHGATE-20260925-65/captured/captured/HpDrv*.sys.bin`
SHA-256：bf07c46effde8b6b0fd3c9586a5a9636800fb37418c1e8e606c67cb613cbf832（19,128 B，x64 KMDF）
反汇编脚本：`artifacts/evidence/driver_disasm/disasm_swtoolsdriver.py` + `disasm_handlers.py`（capstone 5.0.7）

## 1. 身份

- PDB：`<HOST_PATH>\Users\<USER>\Documents\WorkingDirectory\_swtoolsdriver\swtoolsdriver\Driver\Output\x64\Release\swtoolsdriver.pdb`
- 设备：`\Device\HP_WKS_SWTOOLS_DRIVER` + `\DosDevices\HP_WKS_SWTOOLS_DRIVER`（RC00 载体，与 RECON 历史证据一致）
- 结构：真实 DriverEntry RVA 0x1184 → KMDF 包装（WdfVersionBind）→ 业务入口 0x140006000
  - IoCreateDevice(DeviceType=FILE_DEVICE_UNKNOWN 0x22) + IoCreateSymbolicLink
  - MajorFunction：CREATE/CLOSE→0x140005000，**DEVICE_CONTROL→0x140005020**，Unload→0x140005298
- 签名：Microsoft Windows Hardware Compatibility Publisher（attestation），2018-09-06 → **2019-09-06 已过期**

## 2. IOCTL 契约（DeviceControl 0x140005020 比较树；设备类型 0x9c）

| IOCTL | 处理器 | 语义（反汇编实证） |
|---|---|---|
| 0x9C402000 | 内联 | 握手/版本：SystemBuffer 写回常量 0x01000000，BytesReturned=4 |
| 0x9C402084 | 0x1400014B4 | **RDMSR**：rdmsr，输入=MSR 索引(4B)，输出=64 位值(8B) |
| 0x9C402088 | 0x140001504 | **WRMSR**：输入=[索引4B + EDX:EAX 8B]，wrmsr |
| 0x9C40208C | 0x140001530 | **PCI 配置读**：槽位编码(bus/dev/fn 位运算) → HalGetBusDataByOffset |
| 0x9C402090 | 内联(hlt 桩) | 未实现但返回 SUCCESS |
| 0x9C4060C4/0CC/0D0/0D4 | 0x140001314 | **I/O 端口读**：`in al/ax/eax, dx`（dword/word/byte 变体） |
| 0x9C4060D8 | （range 路由） | 未实现路径（STATUS_INVALID_PARAMETER 0xC000000D） |
| 0x9C406104 | 0x1400013A8 | **物理内存映射（MDL）**：MmAllocateContiguous/MmBuildMdlForNonPagedPool/MmMapLockedPagesSpecifyCache → 返回 0x20B 结构（VA/映射VA/MDL/长度） |
| 0x9C40610C | 0x14000173C | （映射/读写族，配 MmUnmapLockedPages） |
| 0x9C406144 | 0x14000159C | **PCI 配置写**族（输入 0x14B，HalSetBusDataByOffset 路径） |
| 0x9C40A0D8/0A0DC/0A0E0 | 0x140001364 | **I/O 端口写**：`out dx, al/ax/eax` |
| 0x9C40A108+range(0x18 步进) | 0x140001364/0x140001314 | 端口/映射族 |
| 其余 | — | STATUS_NOT_IMPLEMENTED (0xC0000002) |

## 3. 语义判定

完整内核级硬件操纵工具箱：**端口 I/O 读写 + MSR 读写 + PCI 配置空间读写 + 物理内存读写（MmMapIoSpace 与 MDL 双机制）**。这正是 HWID 改写的执行机构——SMBIOS 串（物理内存）、ATA 盘串（端口 I/O）、PCI 设备身份（配置空间）、CPU 特征（MSR）全部可改。与部署域"AntiCheatExpert"伪装服务组合 = 驱动级反检测/改机产品形态（"硬件维修工具箱"名义下的硬件身份欺骗后门）。

## 4. 对主线索的推论

1. RC00 请求 = 用户态组件对本设备的 DeviceIoControl（上述 IOCTL 之一/组合），载体落实：`\\.\HP_WKS_SWTOOLS_DRIVER`。
2. 样本放弃内核驱动直接路径的原因之一：**WHQL 签名 2019 过期**，现代 Win10/11 完整校验路径必拒；testsigning 不豁免过期证书的完整校验。驱动加载分支需实测验证。
3. 下一动作：①运行中转储 FATAL@0x1407aa694 决策点（该区域运行时生成）②用户态侧定位调用这些 IOCTL 的代码（在 7.9MB payload 解出后或从解码逻辑推）③驱动加载实测（ sc create + StartService，观察签名拒绝码）。

## 5. 反汇编脚本与复现

`artifacts/evidence/driver_disasm/disasm_swtoolsdriver.py`（全节反汇编）、`disasm_handlers.py`（8 处理器 + IAT 注解）。capstone 本地静态，无 VM 依赖。
