# RUN MANIFEST — EPT genB `Hardware.exe`（当前样本状态；稳定流程见固定加载的 `ept-analysis-workbench` Skill）

样本：`Hardware.exe` genB，SHA256 `cfa6998ecc2fba92b027985c5283b09cd9c04c636158fd6961a10560AFB28BD7`（大小写不敏感），32,671,232 B，VMProtect 加壳，未签名。
靶机：VirtualBox `<OTHER_VM_LABEL>`，快照 `qoder-armed-20260919`（`ad2c4f36-3640-432e-8ac8-39a7ecb15b39`），3072 MB / 4 vCPU，`paravirt=default` ⇒ `Effective: HyperV`。
执行边界：**仅在 VM 内执行**；宿主从未执行样本字节；宿主网络配置未改动。

## 1. 已固化的锚点（静态不可得，运行时才出现）

| 锚点 | 值 | 出处 |
|---|---|---|
| 校验服务器 | `yz.hwid001.com`，端口 **1029** | 内存词表 `SetHost yz.hwid001.com:1029`（159 处一致）+ 宿主侧 pcap 两次 DNS |
| 同族下载域 | `xz.hwid001.com` | §5 静态 IOC（壳侧） |
| 明文缺失证明 | genB 全盘 `http://`/`https://`/`hwid001` 计数 = **0** | 宿主侧只读扫描 |
| 内核 helper | `HP_WKS_SWTOOLS_DRIVER.sys`（`HpSvc`/`HpDrv`/`\\.\`） | 词表 `0x140f8cba0` 等 |
| IOCTL 契约字段 | `ioctlAuth`+`magic`、stage0/stage1、`nonce`、`session`、`ioctlRun`、`mode`/`serialMode`/`diskLen`、`expected=0x12345678` | 词表 CI/RC/HS 三族 |
| 返回码域 | `SP_*` 共 28 个 | 词表 `0x140f8e030`–`0x140f8e258` |
| 词表证据件 | `artifacts/evidence/genB_runtime_vocab_0x140f8c800-0x140f99000.txt`（251 条含 VA） | RG2 臂 15:20 |
| **函数表（不需运行）** | 2,593 条合法 `RUNTIME_FUNCTION`：`.text` 1,694 / `.Sq>` 870 / `.)Bu` 29，合计 4,496 KB | `artifacts/evidence/genB_functions_from_pdata.tsv`，源：真异常目录 **RVA 0x3f5d150 size 0x79e0**（在 `.)Bu`，有磁盘数据）。**段表里名为 `.pdata` 的 0x14116d000 是假的** |
| **静态导入面** | 13 描述符 / 18 thunk：`GetAdaptersInfo`(IPHLPAPI)、`RegOpenKeyExA`(ADVAPI32)、`CryptBinaryToStringW`(CRYPT32)、`WS2_32` **ordinal 21 = `setsockopt`**（查宿主 ws2_32 导出表得出）、`ShellExecuteExW`、`CoTaskMemFree`、`DeleteDC`、`RtlVirtualUnwind`、`InitCommonControlsEx`、`SetFocus`、KERNEL32×8（含 `LoadLibraryA`/`GetProcAddress`/`GetModuleHandleA`） | `artifacts/evidence/genB_static_imports.tsv` |
| **段布局** | `.text` VA 0x140001000–0x1407da92c（raw=0，运行时构建）；`.rdata` 0x1407db000–0x140f9ddd0（raw=0）；`.Sq>` 0x141174000–0x1420595f0（raw=0，VMProtect 自身代码）；`.)Bu` 0x14205b000–0x143f64b30（raw 32 MB，RWX）；EP=0x235f67b 落在 `.)Bu` | 离线读文件头 |
| **完整性要求** | manifest `requestedExecutionLevel level='asInvoker' uiAccess='false'`（文件偏移 0x1f283ba）；全文件无 `requireAdministrator`/`highestAvailable` | 离线只读扫 `.rsrc` |
| 投放路径串（运行时侧） | `<HOST_PATH>\Users\<USER>\AppData\Local\Temp\EPT_3C9F3CEF_69BB4F9F.exe` @ **0x14115b120** | RG2 区段全量串表 `artifacts/evidence/RG2_region_strings_full.tsv`（3,521 条） |
| 抓包证据件 | `artifacts/captures/pcap/VBox-3bf4.pcap`（命中 2）/ `VBox-5198.pcap`（0，hosts 钉死）/ `VBox-4e98.pcap`（0，IDLE） | §14.18 |

## 2. 追加块（原"+256 链"）当前定性

| 项 | 观测 |
|---|---|
| 结构 | **纯追加**：28 份副本 body 逐字节等于 genB；账本前缀跨相邻副本稳定；块大小恒定 256 B |
| 内容 | 无明文字段（长度/序号/时间戳/指针/状态码均未命中）；256 字节样本的 distinct≈152–176 与均匀随机期望 ≈162 相符，熵 7.06–7.31 属小样本正常值 ⇒ **不能据此谈密码结构** |
| 相邻块摘要依赖 | `digest(R_k)` 前缀 == `R_{k+1}`：**0 处** |
| **跨运行复现性** | run-1（RG2 15:39）`R1[0:32]=0d5421c248d51dbbcdf08a9f372f526d82196c864032c30ee498601c6721042b`；run-2（C1 17:09）`R1[0:32]=1fcba6522fbbf29235158cdc4b7ecd8d3cb9721df1ab2ef793331917d0842ebe`，`sha256(R1)=0F9828BC2145038094B980A7D82E629F85BE34F697A298505BE69B679360087C` ⇒ **同快照、同参数、同启动方式，R1 不同** |

⇒ **结论：追加块由运行时产生，与文件内容无关。**
按 SKILL.md 的 c 路线准入闸：无摘要/nonce 依赖证据 ⇒ **密码学路线关闭**；同时**"本地伪造账本/链尾"这条捷径也作废**（块不可预测复用）。
定性降级为：**运行时随机填充的追加块，语义未知**（用途候选：抗重放/自校验/反调试诱饵，均未证实）。

## 3. 必须记下的自我更正（四条）

1. **"第 27 跳部署"不是常数。** run-1 到 hop 28、部署在 hop 27；run-2 在 ~30 s 窗口内只到 hop 9、部署在 hop 8。⇒ 跳数由**时间与运行速度**决定，不是固定门限。之前把 27 当成有意义的常数，是过度解读。
2. **C1 臂的解密 `.text` 采集失败**（`TARGET pid= name= ws=0MB`、`bytes=0`）。根因：`param($T)` 被循环里 `$t = @(Get-Process …)` 覆盖（PowerShell 变量名大小写不敏感），产物文件名被污染成一串进程对象。账本部分不受影响，所以 §2 的复现性结论仍成立。
3. **"拿到了 4 MB 解密镜像"说过头了。** 逐页标定（与 notepad `.text` 的算子密度对比）后：0x140e00000–0x140f7ffff 熵 8.00、可打印密度 0.371（= 均匀随机期望）、24 个 64 B 探针在文件里 0 命中 ⇒ **仍是密文**；0x140f80000–0x14116ffff 是**解密的 `.rdata`**；0x141170000 之后是 `.Sq>`，即 **VMProtect 自己的代码**。⇒ 这 4 MB 里**没有一字节原始 `.text`**。

4. **"必须强制冷启动"是错的**（详见 Writeup §14.24）：`snapshot restore` 本身就会把 saved 状态换成该快照那一刻的内存镜像；start+poweroff 制造冷启动反而触发了快照里固化的待安装更新，把 guest 卡在"正在配置更新 30%"，并让 C4 产生零读数。

## 4. 未决与下一条区分性检查

**2026-09-19 19:1x 更新：`.text` 已到手（C6），下表多数条目状态改变。**

| 未决 | 当前状态 |
|---|---|
| 谁读取、谁判定 `StoredAuthorizationUsable` | **已答**：`FUN_1407a3080` 对四个 `.data` 全局做合取（`0x141154ced==1 && 0x141154cf1==1 && 0x141154ae7!=0 && 0x141154ce9!=0`）。**且同一合取在 0x1407a3–0x1407a7 至少 4 处内联重算 ⇒ 没有单点闸门可钩**。见 Writeup §14.27(1) |
| soft/hard 是真分支还是调试词表 | **已答：是真分支**。`break` 出 switch 继续走 = soft_allow；`call FUN_1407a3000(code)` = clear_or_block；另有直接 `return 1` 的第三组码。见 §14.27(2) |
| 驱动是否会被加载 | 部分：`Run.skip_driver_load_because_authorization_not_usable`、`Run.StoredAuthorizationUsableBeforeDriver`、`RUN dse_*` 在**明文 .text 内零引用**（全窗口 2,004,141 解码单元 + 三个数据区指针扫描，0 命中）⇒ 倾向"该侧被虚拟化进 `.Sq>`"。下一条检查：采 `.Sq>` 而非再采 `.text` |
| 报文字节格式 | 未决。serializer 候选已收窄：`FUN_14078ed39`（`RC00 send mode/serialMode/diskLen`）、`FUN_14078b650`（`EPT_runtime_hash.csv` + hex 字母表） |
| +256 追加块写入者 | 候选 `FUN_14078b650`，**未证实** |
| `-k/-n/-m` 逐参数解析点 | 收窄到 `FUN_1407a4b90`（1,441 行，含 `--nsp-runtime-child`×4 / `--shift-open`×3 / `MAIN startup admin=%d cfgMissing=%d`），逐参数未定位 |
| 挂死机理 | **已定案且已用于修复**：杀死 C1–C5 的是采集器自己往 guest 磁盘写的 8 MB 解密本体。C6 改为零落盘管道直流后，同一快照同一启动方式下 **guest 存活**，19 秒完成三窗口采集 |

### 环境收尾与 19:3x 的两臂追加结论

- **C7 / C7b 均在身份闸门前失败，样本从未启动**：`echo CH_OK` 通、`Get-FileHash` 连查 4 次返回空、约 2 分钟后通道彻底死亡、`screenshotpng` → `E_FAIL`。
- **§14.24 的归因被证伪**：C7b 是 `restore → resume → settle 75s`，没做冷启动，却复现了与 C4 完全相同的签名。⇒ "冷启动触发服务化"不成立。**共同点改为：armed 快照在较晚墙钟时刻被 resume 后约 2 分钟内必须完成闸门+采集，否则不可信**；触发者未决（候选：更新客户端、计划任务 `\Microsoft\Hardware`）。C6 之所以成功，是因为它是 18:37 干净 restore 之后的第一次 resume。
- **动态预算已用尽**（C6 成功 + C7 + C7b），本轮不再投臂。下一步需要先**重新武装靶机**（9-14 干净快照 + 只用策略消噪 + 关机态快照）。
- VM 现状：`poweroff → restore qoder-armed-20260919`，停在 `saved`；宿主 `E:` 空闲 168 GB。

### 14.30 的两条新事实

| 项 | 内容 |
|---|---|
| **`EPT_runtime_hash.csv` 的记录格式（观察）** | 表头 `Time,Type,Path,Length,SHA256`（0x140f8cf90）；数据行 `"%04u-%02u-%02u %02u:%02u:%02u.%03u","runtime-driver-image","%s",%llu,"%s"`（0x140f8cfb0）；路径 `%sEPT_runtime_hash.csv`（0x140f8cf78）。写入者 `FUN_14078b650`，内含 32 轮循环 + hex 字母表 ⇒ **加载驱动镜像前先把其路径/长度/SHA-256 记入本地清单**。打开/写文件走**间接调用**（`func_0x000141adf83e`、`func_0x0001416b849a`），与静态导入表无 `CreateFileW/WriteFile` 相符 |
| **B3 撤回** | `FUN_14078b650` 不是 +256 追加块写入者（它写变长 CSV 文本行，无 256 定长块操作）。+256 写入者仍未定位，且因跨运行不可复现，更可能来自壳侧 |
| **⑤ `-k/-n/-m` 解析点** | ~~未拿到~~ **已推翻**：见 §14.31(2)。三个选项都在 `main` 内被解析（0x1407a550e / 0x1407a5577 / 0x1407a55df）。当时的"未决"来自只扫了 `.rdata` 短串、又只读了 `main` 反编译的前 250 行 |

### 六项交付当前状态（19:5x，按教练裁决修订）

| 交付 | 状态 |
|---|---|
| ① `StoredAuthorizationUsable` 输入源与判定函数 | **达成（本轮补齐输入侧）**：判定 = 四个 `.data` 全局 `0x141154ced==1 && 0x141154cf1==1 && 0x141154ae7!=0 && 0x141154ce9!=0` 的短路合取（`0x1407a30b2..a30cd`），合取实例 **3 站点 / 2 函数**（非"≥4 处"）。**写入者未定位**：`.text` 内 0 处 RIP 相对写入，但 `0x1407a320e` 把 `&g3` 传给 SDK ⇒ 经指针写入；查写入者需转向被叫方 `FUN_1403b34d0/3b3d30/3c47e0/3c49d0` |
| ② soft/hard 真实条件跳转 | **字节级分离完成**（§14.38）：分叉点 `test bl,bl / jne 0x1407a311c @0x1407a3113`；出口 (a) 合取不成立 → `xor al,al` 返回 0 → **调用点汇聚到终止块 `0x1407a7b18`**；出口 (b) 各阶段失败 → `mov al,1` 返回 1 → 继续（fail-open）；出口 (c) → `call FUN_1407a3000(code)`。**两级跳转表解出：只有 `{-39,-38,-16,-4,-3,-2,-1,0}` 返回 1，其余一切码走 (c)**。未决：`FUN_1407a3000` 不写 al，其值来自 `.text` 外的 `0x141a1ff1b` ⇒ "阻断是否也终止"静态答不了 |
| ③ 驱动返回值→后续写入 | **拆两条**：用户态明文 `.text` 的直接调用关系**已闭合**（`main` 直达可达集 246/1694，**该数是下界**，见 R4b/§14.33；授权链在内，驱动契约簇/CSV/投放簇不在内，`comm_init` 全 `.text` 零前驱）；间接分派**离线清单已于 21:5x 跑完**（§14.36/§14.37）：导出表不存在、`lea` 取地址 0（全窗口滑移，控制组 167 条证明覆盖）、立即数形式的函数地址 0（控制组 `cmp edx,0x12345678` 通过）。**只剩两个未捕获对象：TLS 目录与 IAT 槽。** 口径仍是"**未发现静态入口**"，**禁止写"不可达"** |
| ④ +256 追加块写入函数 | **未达成**（有界）：在当前静态覆盖与已有动态样本内尚未定位唯一 writer；结构跨运行不可复现 ⇒ 通用语义仍未定。暂不为它盲采 `.Sq>` |
| ⑤ `-n` 解析与消费点 | **解析 + 首个数值消费点已达成；分支后语义未闭合**（§14.34）。**"被控制流平坦化阻断"这一说法已作废**：`main` 代码区内间接转移 0 条、无"代码地址入栈"模式，平坦化是把反编译产物当成了二进制事实。改为栈槽切片后拿到：`[RSP+0x70]` **两辈值**（入口 `movsxd r13,ecx` ⇒ argc；`0x1407a55b3` ⇒ strtol 形结果）⇒ 槽位≠变量；argc 消费于 `FUN_1407a1fa0(argc,argv,&out)`（扫 `--nsp-runtime-child`）；`-n`/`-m` 读取点 `0x1407a583d / 0x1407a5855`，同簇三条判定。**新缺口**：`main` 区间内 892 条指令的自封闭簇（见 ③） |
| ⑥ `0x12345678` 与 `SP_*` 引用点 | **达成**：比较在 `FUN_14078f0ad`；`SP_*` 只被函数边界外字节引用 ⇒ **名字表** |

**~~A13 口径~~：已被 §14.32 推翻。** 原写作"在 8.25 MB 明文 `.text` 内脚本扫描 0 命中"——那是 **ASCII-only 扫描造成的假负例**：WMI/`wmic` 命令行是 UTF-16LE 字面量，ASCII 扫描器看不见。双编码重扫后：**12 项硬件标识采集在用户态明文代码里已证实**（`BiosSerial`/`DiskSerials`/`CpuIds`/`CpuSerials`/`Gpus`/`MemorySerials`/`Macs`/`Gateways`/`Duid` + `Meta`/`Version` 等），落盘目标 `C:\Windows\System32\Hardware.ini` 与 `<HOST_PATH>\<DIR>ware.ini`。件：`C9_utf16_identity.{tsv,json}`。B1"标识读写下放内核 helper"只剩"改写"半边未证。

**§14.24 归因作废**：C7b 证明同一签名与冷启动无关；触发者未定，已确认的只有"armed 快照 resume 后约 2 分钟内必须完成闸门与采集"。

### 20:5x 更新：R1 交叉验证闭合（§14.33）

| 项 | 结果 |
|---|---|
| 集合比对 | Ghidra 50 锚点 / capstone 57 / 交集 49 / 仅 capstone 8 / 仅 Ghidra 1（件 `C10_xref_crosscheck.txt`） |
| 9 处差异 | **9/9 归因完毕**：8 条 Ghidra 漏报（7 条该地址未被解码；1 条目标落在未映射的 `.data`），1 条 **Ghidra 假阳性**（`[RCX+RDI+0xf8ce50]` 的数组位移常量数值恰等锚点 RVA，被当绝对地址建引用）。件 `C10c_decode_arbitration.txt` |
| 函数归属 | 15 处不一致**全在同一指令地址**上（10 处 Ghidra 合并相邻 `.pdata` 函数，5 处 `.pdata` 空洞）；`REF_LOC_DIFFERS = 0`。件 `C10b_xref_disagreement_classes.txt` |
| 裁决 | **capstone 为主仪器**；Ghidra 的 `NO_XREF` 与其独有命中均不得作阴/阳性用 |
| 新工作项 R4b | `.pdata` 有空洞而空洞内有真实被引用代码（`0x14078fafa/fb42/fb6a/fb72/fbaa`）⇒ `main` 直达可达集 246/1,694 是**下界** |
| 仪器自纠 | ① `compare_xrefs.py` 的 `splitlines()` 在锚点文本的尾随 `\r` 上再切一刀，96 行只读进 9 行且退出码 0；② `ghidra-rpc disassemble` 对无指令的地址**从下一条作答**，只在 `warning` 里说明——第一版探针据此几乎把结论判反 |

**流程**：SKILL 新增第 9 条硬闸门（八类高风险表述必须先有脚本证据件；证据件字段模板已扩到 15 列）；另补"编码可见性前置条件"与"交叉验证的解释力上限"两条。本轮不投动态臂；下一轮动态必须先写验收条件。

### 21:2x 更新：R3（⑤）主体达成 + 两处口径推翻（§14.34）

| 项 | 结果 |
|---|---|
| `[RSP+0x70]` | **两辈值**：入口 `movsxd r13,ecx` ⇒ argc；`0x1407a55b3` 又存 strtol 形调用的整数 ⇒ **槽位 ≠ 变量**，问题必须按活跃区间回答 |
| argc 的消费链 | `0x1407a531e → 0x1407a5326 call FUN_1407a1fa0(argc, argv, &[rbp-0x80])`；该函数遍历 `argv[1..argc)` 比对 `--nsp-runtime-child`，随后 `func_0x1414c9aeb(0,buf,0x104)` 取自身模块路径 |
| `-n`/`-m` 数值消费点 | `0x1407a583d`（`-n`）、`0x1407a5855`（`-m`）；同簇三条判定 `cmp ecx,r12d/ja 6af6`、`cmp ecx,1/jne 6ad1`、`test eax,eax/js 6b32` ⇒ 推断 `-n` 为下标类参数、`-m` 为带符号模式参数 |
| **作废 1** | §14.31"`main` 被控制流平坦化阻断"——代码区内**间接转移 0 条**、无"代码地址入栈"模式；那是反编译产物被当成了二进制事实 |
| **作废 2** | "只有 22% 可达 = 行走器有缺陷"——分母掺了数据：`main` 的 23,424 B 里 **19 个 512 B 窗口（9,728 B，自 `0x1407a7d90`）熵 7.46–7.92、平均"指令"长 2.65–3.06 B**，不是普通代码。判别器用已知代码函数 `FUN_1407a3080` 做对照（熵 5.65–5.78、长 3.90–4.45）。件 `C12_main_code_or_data.tsv`、`C12_control_gate.tsv`、脚本 `code_or_data_scan.py` |
| 新工作项 R7 | 这 9.7 KB 高熵内容**已在手**（在已解密 `.text` 内）。它与 ④ 至今没有静态写入者的"+256 追加块"是否同源，是下一条最有区分力的检查 |
| ⑤ 剩余缺口 | 三个失败分支目标在**代码区**内却未被走到，属真实缺口，需补 CFG 行走 |

**安全约束仍全程生效**（逐字见文末）。本轮未启动靶机、未连接任何外部主机、未解码内嵌 token；全部结论来自已归档的离线镜像与宿主侧脚本。

### 22:2x 更新：两条分支在字节层分离完毕（§14.38）

| 判据 | 结果（全部带地址，件 `C19_gate_readers.tsv`、`C20_gate_cfg.txt`） |
|---|---|
| 合取实例 | **3 站点 / 2 函数**（`FUN_1407a3080`；`FUN_1407a3510` 内两处），`main` 那两处是"全局 vs 寄存器"比对而非合取 ⇒ **§14.27"≥4 处内联"作废** |
| 分叉点 | 4 个短路 `cmp/jcc`（`0x1407a30b2/bb/c4/cd`）汇聚到 `mov bl,1` vs `xor bl,bl`；flag 分支 `test bl,bl / jne 0x1407a311c @0x1407a3113` |
| 出口 (a) | 合取不成立 → `xor al,al` → **返回 0**（全函数唯一产生 0 的路径） |
| 出口 (b) soft | Init/GetServerOption/CardLogin(8 码)/IsLogin 的失败支 → `mov al,1` → **返回 1**（fail-open） |
| 出口 (c) hard | `call FUN_1407a3000(code)`，唯一叶子 `0x1407a32b6` |
| 错误码映射 | **一条两级跳转表**（A 级表 0x7a3440/0x7a3448，B 级 0x7a3474/0x7a347c，`rdx`=镜像基址、表项存 RVA），不是两个 switch。解出全部 80 项：**只有 8 个码 `{-39,-38,-16,-4,-3,-2,-1,0}` → 返回 1；其余一切码 → `FUN_1407a3000(code)`** |
| 调用点语义 | 两个调用点（`0x1407a6a4e`、`0x1407a7b0f`——原记 `0x1407a7b0e` 系滑移重影，见 §14.39(4b)／件 `C23`）**汇聚到同一终止块 `0x1407a7b18`**（`xor ecx,ecx; call 0x1417612fa; int3`）。**§14.39(3) 已改窄**：进入终止块需「四条全局-寄存器比对全部成立 ＋ `al==0`」五条件合取 |
| 唯一未决 | 阻断路径的 `al` **不在已恢复明文内**：`FUN_1407a3000` 全程不写 al，其值来自 `call 0x141a1ff1b`（RVA 0x1a1ff1b，`.text` 之外）⇒ "阻断是否也终止"答不了，且只能靠运行时 |
| 全局写入者 | `.text` 内**无任何对四全局的 RIP 相对写入**；但 `0x1407a320e` 把 `&g3` 作为实参交给 SDK ⇒ 写入经由指针发生（"无人写"是错的读法） |

**§14.33(4) 更正（重要）**：`.pdata` 把**一个逻辑函数切成三条目**（`0x1407a3080`+`0x1407a3323`+`0x1407a341d` 共享 `[rbp+0x290]` cookie、`sub rsp,0x3a0`/`add rsp,0x3a0` 配对）。所以 10 处 `BOUNDARY_ONLY` 分歧的成因不是"Ghidra 合并相邻函数"，而是**异常表条目比逻辑函数更细**；"函数边界以 `.pdata` 为准"这条工作假设**撤销**，凡依赖边界的可达集/归属结论需按"条目≠函数"复核。

**本轮仍为纯离线**（滑移扫描 + 反汇编 + 表解码），未启动靶机、未连外部主机、未解码内嵌 token。

### 23:1x 更新：第二载体 `FUN_1407a3510` 的两处合取分离完成（§14.39）

| 判据 | 结果（全部带地址；件 `C22_cfg_boundary_validated.txt`、`C22b_bad_seed_seeds_probe.txt`、`C21`／`C21b`／`C21c`、`C23`；脚本 `cfg_dump.py`、`referee_carrier_sites.sh`） |
|---|---|
| 仪器重写 | `cfg_dump.py` 改两阶段：先建「已验证指令起点」集，跳转目的落在指令内部 ⇒ 记 `BAD-SEED` 且**不走**。闸门重跑 **100.0% / 21 块 / 0 BAD-SEED / 0 无入边块** ⇒ §14.38 断言原样复现；载体 99.4% / 208 块 / **5 BAD-SEED**；`main` 37.3%（体内已知含约 9.7 KB 高熵数据） |
| 两仪器同址闸 | 新探针 `referee_carrier_sites.sh`（Ghidra 单指令 + 断言返回地址==请求地址 + 控制组）：三批 **69 行全有返回，41 行同址一致，28 行 Ghidra 该地址无指令起点**。本节分支断言只用同址一致的地址 |
| 载体判据 2 | 实例 #1 `0x1407a354f / 558 / 561+568 / 56c+572` →「不成立」汇合 `0x1407a357a`，「全真」`jne 0x1407a4727`；实例 #2 `0x1407a4700 / 70d / 71a+720+727 / 72f` → 四条全部汇合 `0x1407a48a4`，「全真」落到 `0x1407a4737`（`call 0x1407a1340`）。**两实例全局相同、顺序不同，且 #1 全真跳进 #2 链内部 ⇒ 不是冗余拷贝** |
| 载体判据 3（推翻一条口径） | **#1 不成立 → `xor ebx,ebx` →…→ `mov eax,ebx` → 返回 0**；**#2 不成立 → 定长日志（`r9d=0x10`、`r8=0x140f92898`、`rdx=0x140f928a8`）+ `mov eax,1` → 返回 1** ⇒「合取不成立必返回 0」**只在闸门函数内成立**，极性是每个实例的属性 |
| 判据 5（`main` 侧） | `0x1407a7b4f call 0x1407a3510 ; mov ebx,eax ; cmp byte[rsp+0x64],0 ; je 0x1407a534a ; test eax,eax ; jne 0x1407a534a`，六条全同址一致；`0x1407a534a mov eax,ebx → cookie 检查 → ret` ⇒ **`main` 的返回值就是载体的返回值**；那条 `eax==0?` 分岔只决定要不要多跑一次 `call 0x14079a100` |
| 终止条件改窄 | 闸门调用前还有 4 条比对：`0x1407a7aec cmp[ced],r11d`／`a7af5 cmp[cf1],ebx`／`a7afd cmp[ae7],r12b`／`a7b06 cmp[ce9],r12d`，四条的「不满足」支全跳 `0x1407a7b4f` ⇒ 终止块 `0x1407a7b18` 需**五条件合取**。（该 26 字节窗口 Ghidra 无解码 ⇒ capstone-only、两端锚定） |
| BAD-SEED 裁决 | `0x1407a352d`：双方都在 `0x1407a35a8` 解出同一条 `jc` ⇒ **真存在的指令重叠跳转**（混淆填充），其尾端 `0x1407a35b7` 双方一致；`0x1407a3975..0x1407a46ff`：Ghidra 该段 6 问点全无指令 ⇒ 我在那里解出的「指令／跳转」不作分支证据；`0x1407a4891`：**跳转目的才对**（`movzx ebx,bl` + `xor ebx,1` ⇒ 返回 `bl` 取反），我那份 `jae 0x1407a48a1` 与那个假 `ret` 都是错位产物 |
| 假调用点 | `C19` 的 3 个调用点里 `0x1407a7b0e` 是**滑移重影**：`je 74 40` 的 rel8 操作数 `0x40` 被当作 REX 前缀，再造出一条**同目标**的 `call`。真点为 `0x1407a7b0f`（件 `C23`） |
| 载体身份（推断） | 它写第五个全局 `0x141154d10` 三处（`0x1407a35b7`／`a3629`／`a3633`）并进门先读它判符号 ⇒ 形状是「算一次、缓存、以后看缓存」的**授权状态计算／缓存函数**候选；它从不调用 `FUN_1407a3000` ⇒ 不是阻断执行者。`0x141154d10` **是本轮新扫出来的第五个全局**，此前所有清单都漏了它 |
| 环境 | 仍为纯离线：未启动靶机、未连任何外部主机、未解码 `0x140f92550` 内嵌 token、实验盘未挂载；Ghidra 探针只读（未改名、未写程序、未改工程属性） |

### 23:5x 更新：出口的"动作"落到地址上——hard = 删 `Logs`/`HardwareLogs` + 弹框「授权验证」（§14.40）

| 项 | 结果（件 `C24`、`C24b`、`C25_operator_messages.txt`、`C26_message_xrefs.txt`；脚本 `gbk_strings_scan.py`、`message_xref_scan.py`） |
|---|---|
| 中文文案此前全漏 | 上一轮词表只按 ASCII 扫，`.rdata` 里与英文标签**混排**的 GBK 文案全部没进清单。本轮补 `gb18030` 扫描（同页 47 条，内建三条控制串断言通过）⇒ 判据 3 的"日志串"一列才真正填满 |
| **清理动作定位** | 四条 `rmdir /s /q "{C,D}:\Windows\System32\{Logs,HardwareLogs}"` 全部被引用于 **`FUN_1407a2a90`**（`0x1407a2def/a2e64/a2ed9/a2f4e`），而 `C6_callgraph.tsv` 记有 `FUN_1407a3000 → FUN_1407a2a90` ⇒ **§14.38 出口 (c) 的"清理"不再是词面推断：阻断叶子调用删日志目录的函数** |
| 对话框文案 | `FUN_1407a3000` 内 `lea rdx,[0x140f924c0]`「授权状态异常，本地配置与固定部署已清理。」+ `lea r8,[0x140f924f8]`「授权验证」（**修正 §14.38 的"rdx=&消息缓冲"：rdx 直接指向该文案**） |
| 载体出口文案 | 标题「固定部署」`0x140f92898`；#2 不成立 →「未找到有效配置，请先使用 -k 完成授权配置！」（`0x1407a48b1`，在 sink `0x1407a48a4` 内）；另一失败出口 →「固定部署失败！」（`0x1407a4882`）⇒ **-k 的消费侧线索第一次与闸门判定挂上**（文案层，不证明分支） |
| soft/hard 的**可判定**依据 | (c) 同时具备「带错误码」+「四参弹框形状 `(rcx=0,rdx=正文,r8=标题,r9d=0x10)`」+「调用清理函数」；(b) 只有一条英文标签；(d) 弹框但**不**清理且返回 1 ⇒ **hard 由动作集合定义，不由形容词或文案定义** |
| 网络阶段顺序 | `test ebx,ebx @0x1407a3172` / `je @0x1407a3174`：Init 返回 0 才 `mov edx,0x405; lea rcx,[0x140f92688 "yz.hwid001.com"]; call 0x1403b3280`（SetHost，端口 1029）⇒ **fail-open 时连服务器地址都没被装填**（仅字符串普查，全程未连接） |
| 证据边界 | `C26` 每条引用成对出现（差 1 字节同目标）＝§14.39(4b) 的 REX 重影 ⇒ **函数归属安全、计数需折半**；`错误码：%d` 明文内 0 引用只否证"RIP 引用"；`FUN_1407a4a90`（`sc.exe config AntiCheatExpert … start= delayed-auto`）在 `.text` 直接 call 边里前驱为 0，不判死代码；四参形状＝推断（被叫方全在未捕获的运行时页） |
| 环境 | 同前：纯离线，靶机未启动 |

**收尾自查（补 §14.38 判据 1 的口径缺口，件 `C27_gate_readers_fulltext.{tsv,json}`）**：原滑移窗口 `0x1000..0x7DA900` 比 `.text` 段尾 `0x7E0000` **少 22,272 B**，而该尾部熵 6.673、256 种字节全出现、非零 16,817 B ⇒ 不是填充。扩到段尾重跑同一套判据：解码单元 7,650,944 → **7,671,139**，读四全局的函数仍 **3 个**（同一组）、引用行仍 28、控制串仍命中 2 次 ⇒ **§14.38(1) 的"3 站点 / 2 函数"不变，但口径现在真是"整个已解密 `.text`"**。调用点仍以 `C23` 字节裁决为准（`0x1407a6a4e`、`0x1407a7b0f`）。

### 关键采集件（C6，19:1x）

| 件 | 内容 |
|---|---|
| `artifacts/captures/stream_C6/stream_text.bin` | 解密 `.text`，0x140000000+0x7E0000，8,257,536 B，熵 6.612，`hole_chunks=0` |
| `artifacts/captures/stream_C6/stream_rdata.bin` | 0x140F80000+0x40000 |
| `artifacts/captures/stream_C6/stream_rdatafront.bin` | **0x1407DB000+0x100000，此前从未捕获过的 `.rdata` 前段** |
| `artifacts/captures/stream_C6/C6_rebuilt.exe` | fixpe 重建对象（保留运行时 VA，EP:=0x140001000），Ghidra 已分析出 1,408 函数 |
| `artifacts/evidence/C6_anchor_xrefs.tsv` | 75 锚点 → 67 条引用 / 57 个锚点命中 |
| `artifacts/evidence/C6_callgraph.tsv` | 3,400 条 `.text` 内调用边，1,299 个函数有调用者 |
| `artifacts/evidence/C6_decompiled_gate.c` | 反编译 dump：**8 个不同函数、9 个 banner**（`FUN_1407a3080` 被 dump 两次）、2,709 非空行（00:30 由 `C36b` 更正旧记的"9 函数/2,761 行"） |
对齐证明：随机 12 个 `.text` 函数按 `.pdata` 边界线性反汇编，**11 个解码字节数与声明长度逐字节相等**；运行时 PE 头与文件头逐项相同 ⇒ 镜像基址 0x140000000，无 ASLR 位移。

### 环境收尾

靶机已 `poweroff → snapshot restore qoder-armed-20260919`，停在 `saved`（该快照自身的内存镜像），宿主 `E:` 空闲 168 GB。`armed3` 的 `--live` 快照因 52 分钟不收敛被放弃（VM 进程被终止，快照树 14 节点完好，`.vbox` 已先备份为 `<OTHER_VM_LABEL>.vbox.bak-1836`）；孤儿 `.sav`（1.75 GB）未删。

## 5. 证据与清理状态

- 已归档：`artifacts/captures/pcap/`（**8/8 全部**，2026-09-20 00:30 补齐 5 份并逐个 SHA-256 回核宿主原件）、`artifacts/evidence/genB_runtime_vocab_*.txt`（注：该件含 `0x140f92550` 附近那条 ≥100 字符 base64 运行，**未解码、未使用**；派生件 `C36` 输出已就地脱敏，只登记存在性）。
- **已丢失**：run-1 的 28×256 账本原始字节（先卸载并删除了取证 VHD，随后 `snapshot restore` 覆盖脏盘）；run-2 的 `.text` 未采到。⇒ 教训：**归档动作必须在卸载/回滚之前完成并校验产物存在**。
- 已清理：`recover_trap1.vhd`、`dirty_forensic.vhd`（各 48 GB 级）均已 `detach vdisk` 并删除；宿主 `E:` 空闲 171 GB。
- 待办：`<HOST_PATH>\CTF\AGENT.md` 是注入指令文件，建议移入 `_reference/` 并标注（需用户确认）。

## 6. 全量重写 P3 轮的离线复跑（09-20 00:1x–00:3x，靶机全程未启动）

| 件 | 脚本 | 重跑了什么 | 与旧文的差 |
|---|---|---|---|
| `artifacts/evidence/C35_pcap_census.txt` | `<HOST_PATH>\vmctl\pcap_census.py` | 宿主全部 **8 份** pcap：大小/SHA-256/包数/跨度/尾部完整性、`\x02yz\x07hwid001\x03com` 与 `xz.` 的**字节级**命中、DNS 查询与 A 应答、SYN 集合、归档件哈希比对 | LEG1 包数 **671 → 687**；新测 3 份（TRAP2/KILL1/CORE2 窗口）yz=0；`xz.` 全语料 0；控制：778/778 个 53 端口包全部解析、无 0 包文件、3 份归档件与原件哈希一致 |
| `artifacts/evidence/C36_p3_offline_rederive.txt` | `<HOST_PATH>\vmctl\verify_p3.py` | 词表文件行计数与逐 needle 命中、四块捕获物的熵/可打印/零占比、C6 三件规模、genB 头与节表 + 明文面负证据（带活对照）、`.pdata` 表、导入表、`setw_CORE1.csv` | 锚点 73 → **75**；反编译 2,761 行 → **2,709 非空行**；`.text` 熵 6.612 → **6.614**；SP_* 报 27（**是我的正则漏了下划线**，见 `C36b`）；RG2 按整 4 MB 量出 6.383（**是我取值范围错**） |
| `artifacts/evidence/C36b_p3_gap_closure.txt` | `<HOST_PATH>\vmctl\verify_p3b.py` | 五处差异逐一定位：按声明区间重测 RG2、下划线感知的 SP_* 普查、manifest 四种搜索基线、直接走 `DataDirectory[1]` 数描述符/ thunk、反编译 banner 去重 | **28 个 SP_\* 确认**（旧文正确）；**13 描述符 / 11 个不同 DLL / 18 thunk 三者同时成立**；RG2 1.5 MB 密文区 **熵 8.000、可打印 0.371 逐位吻合**；manifest 元素名 @`0x1f283ba` ✓；反编译**8 个函数**（`FUN_1407a3080` 两次） |
| 在档原件回读 | `md5sum`、`cat` | `r1/r2/r3.png` 194,922 B 且 MD5 同为 `c6aefc5e…`；`shot_c4*.png` 14,275 B、MD5 `49aef4f5d05b41235b00ef9a405533d7`（与旧引用逐字符同）；`harvest/etr_TRAP2/journal.txt` 逐字符复读；`col_C1.txt` / `col_C2.txt` 的 hop 与 `R1_first32` | **C2 的旧记"0 读数"更正**：guest 内 `.text` 8,257,536 B 完整读出（`hole_pages=0`、`ZERO_PAGES=0 of 2016`、b64 5,578,244 B）并 `COLLECT_DONE`，死在其后的 `PULL FAILED`；C1 另有一处 tar 文件名插值 bug |
| 新发现的开放问题 | `sha256sum stream_text.bin` | 同一 VA 区间（`0x140000000+0x7E0000`）两次运行哈希不同：C2 `0D291B31…` vs C6 `5ae354e2…` | **未决**，并据此给 P4 全部反编译结论加"单次运行字节"限定 |
| 只读环境查询 | `VBoxManage snapshot list` / `showvminfo --machinereadable` | 6 个快照 UUID + 描述串 + 14 节点树 + `saved` / `paravirtprovider=default` / `eff=hyperv` | 全部 ✓；**收尾快照名应为 `qoder-armed-20260919`**（旧文收尾段写 pre-vtpm 只对更早轮次成立）；`VMStateChangeTime` 不随 restore 更新 ⇒ 不可当活动时钟 |
| 证据补齐 | `cp -n` + `sha256sum` | 5 份未归档抓包（含携带命中的 `VBox-2a0c.pcap`）复制进 `artifacts/captures/pcap/`，8/8 哈希回核一致 | 归档缺口闭合；宿主原件保留不动 |

## 7. 结构整理轮（09-20 01:2x，纯宿主，靶机未启动）

| 项 | 内容 |
|---|---|
| 为什么做 | 同一轮里已两次因"东西放在下一个读者不会去的地方"丢证据（先删取证 VHD 才想起归档；抓包 5/8 从未归档）。规则不落地就还会再乱。 |
| 新布局 | `writeup/` `method/` `artifacts/{evidence,captures,deprecated}/` `sample/` `unpack/` `archive/`；规则本体 `LAYOUT.md`，机器检查 `<HOST_PATH>\vmctl\layout_gate.py`，挂在 `.git/hooks/pre-commit` |
| git | `380d599` 移动前快照 → `54a58a0` 结构整理；仓库无 remote、不 push；身份用 `-c` 临时传入 |
| 大文件 | 样本 exe、解包树(1,999 文件)、内存镜像、301 MB 抓包不入库；`artifacts/CHECKSUMS.sha256` 整理后重算，`sha256sum -c` 全通过 |
| 引用改写 | 5 篇 writeup + RUN_MANIFEST + ROADMAP + `<HOST_PATH>\vmctl` 下 57 个脚本/文档；`REORG_MANIFEST.md` 记 原→新 逐条可回退 |
| 冒烟证明 | 重跑 `verify_p3b` / `verify_p4b`，数字与整理前逐项相同（RG2 密文子区间熵 8.000、放行码 8 个、13 描述符/18 thunk）⇒ 移动未改变任何结论 |
| 门禁自查 | 首跑抓出 3 处：我把 `.txt` 误列为捕获物后缀（误报 38 件）、`arm6/arm7.sh` 旧 stream 目录、P3 一处旧 pcap 路径。均已修——门禁第一天的产出就是它自己的 bug |

## 8. BR1：分支分离的预注册判据臂（09-20 17:4x 起，靶机启动前判据已冻结）

| 项 | 内容 |
|---|---|
| 唯一变量 | 带无效卡密的正常启动后，进程**退出码**是 `0x80000003`（= 走终止块）还是 `0/1`（= 走继续块） |
| 判据来源 | P4§4.4(3)(7)：终止块 `0x1407a7b18: xor ecx,ecx ; push rdx ; call 0x1417612fa ; int3`。无调试器时未处理 `int3` → `STATUS_BREAKPOINT = -2147483645`。**写在 `judge_branch.py` 里，先于任何 `startvm`** |
| 阴性/崩溃类码的处理 | 预先声明：`0xc0000005` 之类崩溃码 **不作为任一分支的证据**（判据里就写着"UNCATEGORISED"），避免事后把崩溃讲成结论 |
| 闸门顺序 | poweroff→restore `qoder-armed-20260919`→resume→信道+控制台截图双闸→`Hardware.exe` SHA256 四次复核 genB→执行→判定→回滚 |
| 启动前修掉的两个自错 | ① 原计划用 `cmd /c "<exe> & echo %errorlevel%"` 取退出码：**同一行里的 `%errorlevel%` 在程序运行前就展开**，取到的是旧值；且 `cmd /c` 的 `ExitCode` 是 `echo` 的 ⇒ 两条读数都会恒为 0，把"终止"误判成"继续"。② 该写法的 `$p.Id` 是 **cmd 的 pid**，`ReadProcessMemory` 会去窥错误的地址空间、五个窗口全读不到。两处都改回 `collect5.ps1:49` 那种直接启动（已被证明能跑） |
| 采集面 | 888 B + 1 KB ILT（tlsdir / iat / loadcfg / impdesc / ilt），stdout 单通道，客户机内除 hosts 行外不落盘 |
| 边界 | hosts 在启动样本**之前**钉到 127.0.0.1（宿主网络未动，`yz.hwid001.com` 宿主与客户机都不外连）；未解码 `0x140f92550`；快照回滚清除 hosts 与投放件 |
| 结果 | 判定件 `artifacts/evidence/C39_branch_run_verdict.txt`（臂跑完才存在）；正文写入 P4§4.15 |
| BR1 被**我自己的探针**否掉（未产生任何测量） | 15 次尝试里 `shot=0B` 恒不通过，而 `ch=CH_OK` 通过 13 次 ⇒ 样本**从未执行**。事后两条独立复现：① `controlvm screenshotpng` 对**正在运行且 SSH 应答良好**的客户机返回 `E_FAIL`；② 我给 `shot_$RID.png` 传了 `<HOST_PATH>` 绝对路径，Windows 侧的 VBoxManage 会写到别处 ⇒ 文件永远"不存在"。两条被我的 `stat ... \\|\\| echo 0` 合并成同一个 `0B`。⇒ 修正：健康判据改由**客户机侧**给出（`health.ps1`：`BOOTMIN/EXPLORER/SVCRUN`，需连续两次 `BOOTMIN` 相同且信道应答），截图降为记录项；实测 `BOOTMIN=110 EXPLORER=1 SVCRUN=81` ⇒ 客户机一直是健康的，被拒的从来不是环境而是探针。规则：探针报错必须与"探针答'没有'"分开打印，否则一次工具故障会伪装成一次科学结论。 |
| 解释约束（**启动之后**才想到，如实标注，不改判据） | 若读到的码是 `0`，还**不能**直接等于"`main` 返回 0 走了继续分支"：交付④已证样本会把自己改名成 `%sEPT_%08X_%08X.exe` 再投放（P4§4.8/§4.14），**父进程替子进程先退 0** 是这种结构的正常表现。判别用的是采集器里已有的 `POST usertmpEPT / sys32 / svccount / setupapi` 四项——若退出码为 0 且 POST 出现新的 `EPT_*` 计数或 `C:\Windows\System32\Hardware.exe` 时间戳更新，则这个 0 属于"存根退出"，分支仍未观察到，需要第二臂（按 PID 树取码）。此约束写在结果栏而不是判据脚本里，是为了不事后修改已冻结的验收判据。 |
| BR3（17:4x→02:17） | `--line-buffered` 修好后第一次真正流式：采到 10 行（`BOOT`→`CORE_HASH`=genB→`PRE`→`HOSTS_PINNED`→`RESOLVE_NOW=127.0.0.1`→`LAUNCH pid=868`→`TICK wait el=5`）后断流；随后 **3 次独立新建 SSH 会话在 60 s 内全部无应答**。判定 rc=2，未对分支作任何主张。⇒ 第一次把"死亡时刻"夹进一个 5 s 窗口 |
| BR4（02:2x→02:31） | 把 `-RedirectStandardOutput` 整个去掉（那是"我自己在客户机写盘"的混淆变量，而写盘正是本lab记录过的死因）。现象**逐字相同**：停在 `T1`（启动后 1 s），12 行，探活无应答。⇒ 混淆变量被排除：沉默不是我的采集造成的 |
| 关于"沉默"的一次**过度解读，就地撤回** | 我先把 VBox.log 里的 `TM: Giving up catch-up attempt`（单次滞后 60-77 s、一次 418 s）当成"客户机不是死而是被饿"的**决定性旁证**。用 BR1 的会话否掉了这个说法：那一会话里**样本从未启动**（闸门在 01:47 就拒绝），却有 4 次 catch-up 事件、累计滞后 60→132→194→348 s 随会话时长线性增长 ⇒ **虚拟时间滞后是本 lab 的常态（宿主不给 vCPU 时间），与样本无关**；而同一个带滞后的会话仍然应答了 13 次 `CH_OK` ⇒ 滞后**不足以**解释 BR3/BR4 的硬沉默。⇒ "饥饿"降级为**待检验假设**：BR5 用耐心检验它（若 tick 恢复则成立），并另行安排"不启动样本的纯 CPU 对照组"。教训：旁证只能缩小假设集合，不能直接升格为结论；把时间戳读全（事件发生在会话第几秒）再下判断。 |
| BR5 因此只改一件事：**耐心** | 观察窗口 300 s → **1500 s**；探活 4 次 × 90 s；并把 VBox 的 `TM … lag` 行与捕获**一起写进臂日志**，让"沉默"今后自带归因证据。判据的三态阈值一字未动；第 5 项仪器检查从"至少读回一个内存窗口"换成"采集器自证 `BOOT` 存在"（因为 BR5 只测退出码，888 B 窗口另立一臂），此项修订发生在启动之前并在此登记。 |
| BR3/BR4 采集件 | `evidence/C39b_BR3_partial_verdict.txt`、`evidence/C39b_BR3_stream.txt`（BR4 的原始流同尺寸，判定时被固定输出名覆盖，故两臂的流都单独存证） |
| BR6（03:3x，**换了问题才拿到答案**） | `C44` 发现 `.Sq>` 头 557 KB 已在 RG2 blob 内 ⇒ 未决量从"采 15 MB"缩成"读 2×512 B"。自检 `PEEK_CONTROL self=True bogus_pid=False`；`WINDOWS_READ=5/5`；两个 callee 页 **0/512 非零**；TLS `AddressOfCallBacks=0`（无回调）；IAT 31 槽里 18 非零、全在系统模块、与静态 18 thunk 数相符；13 条导入描述符 `OriginalFirstThunk` 全非零（未绑定）。⇒ §4.16-7 交付、TLS 入口解释被排除；退出码仍未取得，臂本身按判据报 rc=2（缺 `BRANCH_DONE`）。存证 `evidence/C39c_BR6_stream.txt`、`C39c_BR6_verdict.txt`、`C45_tls_callback_chain_and_iat.txt` |
| CTRL1 阴性对照（`arm9.sh`，样本**从未投放、从未启动**） | 15 次探测约 10 分钟全部 `ch=no`，客户机完全不应答 ⇒ 当时写作"可达性是底座属性、与样本无关"。**这条口径已在 `C46` 后收窄**（见下 CTRL2/CTRL2b 行）：它只证明"这些会话里样本没启动时也不可达"，不证明"永远不可达"。臂后已 poweroff+restore 回 `qoder-armed-20260919`（`arm9` 的闸失败路径不含回滚，已手工补做并核对 `VMState=saved`） |
| `C46` 基线可达性度量（纯宿主侧读日志，不是一臂） | 逐 VBox 会话量出 `NAT: Link down → up` 的等待：**35 s（BR6）/ 5 s（BASE1）/ 917 s（CTRL2）/ 从未（BR4/BR5 那轮）**；四份会话都重播同一条 `Session 0 is about to close … Stopping all guest processes` ⇒ **`qoder-armed-20260919` 拍的是半拆卸瞬间，恢复 ≠ 开机**。宿主不是瓶颈：12 逻辑核、总 44–71 %，`VBoxHeadless` 8 s 窗内 79.9 CPU-秒（≈4 核满载），`MsMpEng` 4.6 CPU-秒；坏会话里 SSH 与 `guestcontrol` **两条通道一起**不可用。⇒ 任何"沉默"读数一律不得作为分支证据。证据件 `artifacts/evidence/C46_baseline_link_timings.txt`（`verify_baseline.py` 生成） |
| BASE1 基线重建臂（`arm11.sh`，**不含样本**） | 04:25:52 起：poweroff → restore → resume → 链路 5 s 内起来 → 客户机侧健康双读（`BOOTMIN=1463 EXPLORER=1 SVCRUN=88`）→ 冻结新回滚点 **`qoder-clean-20260920`**（UUID `ec1a5369-…`，快照数 14→15，**`qoder-armed-20260919` 原样保留**）。`controlvm reset` 分支未触发。用时约 2 分 8 秒。**这是"改环境"不是"改判据"：`judge_branch.py` 的三态阈值一字未动。** |
| CTRL2 / CTRL2b 阴性对照（`arm10.sh … nolaunch`，样本从未投放） | CTRL2（旧 armed 基线，04:08）：15×35 s 等不到信道 → `GATE FAIL`；**事后 `C46` 显示该会话链路在 917 s 才起 ⇒ 失败的是我的 540 s 预算**。CTRL2b（`qoder-clean` 基线，04:29）：链路 20 s 起、闸门过、投放采集器并**分离启动成功**（`spawn7.ps1 → SPAWN rc=0 pid=3988`），随后 13 次 scp 轮询**全部 75 s 超时**、收割 0 B；其中第 1 次是 0 s 返回（路径级失败：本机 scp 只认 home 相对路径，我当时不知道）。⇒ **两条硬结论**：① "启动后约 1 分钟流停止"在**没有样本**时同样复现 ⇒ BR3–BR6 的沉默不能再归因于样本行为；② 采集器输出必须写到**家目录**、失败必须**分类**、并且**先收割后回滚**（`arm12.sh`）。 |
| CTRL3 / BR7（`arm12.sh`，进行中） | CTRL3＝同一采集器的通道判别臂：scp（分类失败）→ `guestcontrol copyfrom`（VMMDev，不经网络）→ 干净 ACPI 关机后再取。三种全废 ⇒ 结论就是"本底座无法把该观测量取出来"，按 §P3§3.13 升级为宿主级决定，**不再加臂**；任一通道成 ⇒ 才跑 BR7（同一脚本第三参 `sample`）。 |
| 离线收尾第二轮（`C48`–`C51`，**不碰靶机**） | 阶段目标点名的"能离线闭合的先做完"四项全部落地：① `C48` 覆盖式走完整个 `main`（98.0 %、6,323 条、三条控制位同遍历）给出 `r11d/ebx/r12b/r12d` 来历；② `C49` 四个闸门全局的**运行期残值本来就在 RG2 blob 里**，全为 0，且用 `0x14116c540=0x273A8BEE` 做"采集不是空白"的控制位；③ `C50` 覆盖式 `.text` 全段（99.9 %、1,993,973 条）普查 `0x100` 立即数 = **111 处 / 58 函数**，链上只有 `0x1407a1fa0`(3) 与 `0x1407a3080`(2)；④ `C51` 把 +256 落点 `0x14117c32e` 从已捕获字节里解出来（83 条 / `ret 8` / 11 字节 int3 填充），并**用对照表推翻我自己两版判"是否明文"的仪器**（熵阈值 7.4 与"页起点线性解码条数"都被否；有效判据＝远端 rel32 目标落镜像内的比例 95 % vs 数据页 70–71 %）。⇒ **交付④（+256 追加块写入者）就地闭合**，`C38` 那句"子树内无 `0x100`"是我读错同件里另一个清单，已作废（P4§4.12/§4.17）。 |
| BR7Q / BR7R（`arm20.sh`，09:17→11:35 两轮） | **`.Sq>` 两页第一次读回来了**：stdin 投 15.9 KB 采集器 → 样本 `pid=5812`（Q）/`pid=332`（R）存活 → `WINDOWS_READ=7/7`→`11/11`，`blk_ret` 509/512、`term_callee` 503/512 **非零且两臂逐字节相同**（nolaunch 对照同批窗口 0/7）。但用校准判据（POSITIVE 真入口整窗 99.6 %/odd 0；NEGATIVE `C13` 21.5 %/odd 4、XOR 19.1 %/odd 7）这两页只有 **11.8 % / 49.2 %** ⇒ 不是 x86 函数；BR7R 换成 `C55` 给出的四个真被调方 `term_a..d`（497/500/512/508 非零）后覆盖率 8.9/2.3/13.0/2.1 %、成群 `cli`/`hlt`/`int 0x9d`/`retf` ⇒ 同样不可解。**盘侧两臂都没有记录**：`new_files.txt` 显示 BR7Q 会话**全卷 10:22:29 之后再无任何写入**，而采集器 `BOOT` 是 10:22:39 ⇒ 样本启动后客户机停止提交；回包也停在 age≈8 s。GA 两轮都是 `stat` 立刻应答、`copyto` 报 `Error starting guest session (current status is: starting)`。`CLEAN_PRE=Y--- D:vol` ⇒ 基线里 `C:\Windows\System32\Logs` 确实存在（rmdir 判据有牙）。 |
| `C55`（纯离线，不花臂）——**本轮真正的产出** | B1 钉了两夜的 `0x141a1ff1b`/`0x1417612fa` 在 13.8 MB 明文（`stream_text` 8.26 MB + RG2 4 MB + 两份 rdata）里 **0 次作为 `E8` 目标、0 次作为 4 字节立即数** ⇒ 反编译产物。明文真正点名的 `.Sq>` 调用点：闸门 9 / 叶子 11 / 载体 16 / `main` 113 个；`main` 的 `...;int3` 块逐字节点名 `0x141a47d82 / 0x14152ab26 / 0x141667867 / 0x1419b182d`。同带明文 `call 0x1407b9bd4 ; int3` 解出是 **MSVC /GS failfast** ⇒ "`call X;int3` ⇒ 未处理断点 ⇒ 退出码 `0x80000003`" 这条**冻结判据的解释面收窄**（判据一字未动）。两处"末地址 −1"：叶子 `0x1407a32b6`→`0x1407a32b5`（其目标 `0x1407afba0` 在 `.text` 明文里，是个字符串/缓冲助手）；调用点 `0x1407a7b0f`→`0x1407a7b0d`。件：`artifacts/evidence/C55_sq_callee_addresses_byte_check.txt`（生成器 `<HOST_PATH>/vmctl/verify_c55.py`）。 |
| **BR7S 越界一次（安全事件，如实记录）** | `br7s.ps1` 第一版只"检查" hosts 是否钉住，打印 `HOSTS=NOT-pinned` 后**照常启动样本**（11:39:03 BOOT → 11:39:05 LAUNCH pid=2280）。发现后 4 min 内 poweroff + restore `qoder-clean-20260920`；会话日志归档 `<HOST_PATH>/vmctl/BR7S_VBox.log`（276,333 B，无 pcap 行 ⇒ 该会话没开 NetSniffer）。**暴露面既不能证实也不能排除**（guest 的 DNS 是 NAT 里的 fake-IP 代理 198.18.0.2，样本已知会解析 `xz./yz.hwid001.com` 试 443；采集器在 LAUNCH 之后没再吐任何一行）。修：`br7s.ps1`/`br7.ps1` 改为**先钉→再解析→`RESOLVE_NOW != 127.0.0.1` 就 `ABORT_NOT_PINNED` 并签名关机，绝不 `Start-Process`**；`arm21.sh` 把"记录里必须出现 `RESOLVE_NOW=127.0.0.1`"当硬断言。规则进 P5 §5.7-15：**检查+打印不是执行**。 |
| BR7S2（`arm21.sh`，11:53→12:04，行为臂第一次） | **整轮零证据**：回包 0 B、`/ept` guestproperty 0 条、`arm14` phase 6b 取件正对照 **`NEWFILE_COUNT=0`** ⇒ 落在分类 **K3（读路径自己失效）**，按规则本轮**不得**对客户机下任何否定结论。phase 6c 的离线见证（`Windows\System32\Logs` PRESENT items=1）因此**只是基线复述**，不能读成"清理支未执行"。暴露：`arm21` 第一版只投一次就不管了 ⇒ 已改成"上一次投递进程退出才重试"（与 arm20 的重复投递教训同源）。 |
| BR7 窗口清单变更（**启动前**，判据未动） | `br7.ps1` 的 `$want` 追加第 7 个窗口 `sink_hop1 = rva 0x1a10a00 len 0x200`（`C51` 的 11 个后继里唯一与 `blk_ret` 同处一个 64 KB 的），**排在清单最后**，因此不可能推迟分支判据依赖的 `blk_ret`/`term_callee` 两窗；`judge_branch.py` 的三态阈值与二值判据一字未动。改后复跑 `selftest_br7.py` → "judge reads both shapes"，且 `br7.ps1` 过 `PSParser` 语法闸。 |

## 9. 历史时间预算校正与 BR22 烘培（2026-09-21 00:42–00:54）

本轮修复了一个流程级问题：旧 `bake22.sh` 用 `95 × sleep 10s` 把等待上限写成约 16 分钟，但这不是样本或任务的必要时长。修复后的本轮观测为：触发 `00:43:14`，客户机自关机 `00:52:18`，实际等待约 **544s**；随后离线只读身份闸门、任务定义和采集器哈希均通过，`qoder-baked-20260920b` 于 `00:53:57` 建立并回滚到 clean 基线。

当时本批次的时间契约（当前臂记录以第 10 节为准）：

- bake：`expected_duration_sec` 以当前测量值为参考，`deadline_sec=720`，`poll_interval_sec=10`，完成事件为 `VM_POWER_OFF + offline_identity_verified`；deadline 到期标 `WAIT_TIMEOUT/INSTRUMENT_FAILURE`，不创建烘焙快照。
- run：`run22.sh` 使用显式墙钟 `RUN_WAIT_SEC=900`、`RUN_POLL_SEC=20`；自关机未在 deadline 内出现时保留离线材料但跳过 `judge_branch.py`，不得把硬断电尾部升级为样本结论。
- 这些数值是当前臂的可审查配置，不是通用常数；下一次更换底座或内部工作量必须重新测量并记录。

## 10. 当前通信与 BR22c 动态更新（2026-09-21 03:44–04:39）

当前动态来源是 artifacts/evidence/C64_communication_DIAGSSH_20260921.md；本节只登记它改变的事实，不回写历史臂的原始记录。

- BR22c 使用 qoder-baked-20260921h 启动开机采集器。采集器自证通过：核心输入 size=32671232、SHA-256=CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7；PEEK_CONTROL self=True、bogus_pid=False；CLEAN_PRE=Y--- D:vol；HOSTS_PINNED；RESOLVE_NOW=127.0.0.1；Hardware.exe 已以 pid=5436 启动。
- BR22c 在 180 秒 deadline 内没有 BRANCH_DONE、自然退出码或完整弹窗记录；控制日志将其分类为 WAIT_TIMEOUT 后的硬 poweroff / INSTRUMENT_FAILURE，未运行 judge_branch.py。离线收割仍证明读路径有效，NEWFILE_COUNT=199；这些事实不推出 hard/soft 分支。
- 独立 SSH 控制臂 DIAGSSHWRAP_20260921_044000 在 clean 快照、样本未投放条件下以 15 秒 deadline 返回 PROCESS_LIST，elapsed_sec=3、rc=0、bytes=6936。原始输出和 sidecar 位于 <HOST_PATH>/vmctl/process_probe/；这验证了程序级进程查询通道，但不替代样本臂。
- 同一通信链上的 15 秒 banner 超时与随后 35 秒 tasklist 成功已经被保存为 readiness 差分。非 PROCESS_LIST 结果统一归为通信/仪器状态，不得写成样本阴性。
- 本次所有 VM 操作已收尾并复核为 VMState=saved、CurrentSnapshotName=qoder-clean-20260920。硬阻断后的进程生命周期仍为 VALID_UNOBSERVABLE_ON_THIS_BASE；在同一底座上不再重复相同缺口。

### 10.1 外层调度器复验（C65，2026-09-21 07:33–07:44）

- OUTER2：客体内运行原始 `auto_decode.pyc` 的 `DecodeEngine.run_decode_from_exe`，7.351 s 返回 `final_status=failed`；错误是 SYSTEM 桌面未找到解码程序。该臂没有进入核心解码。
- OUTER3：把 `Hardware.genB.exe` 改投到 SYSTEM 桌面后重新触发；约 90 s 后 SSH banner 超时，宿主按硬截止关机。离线盘未取得 harness 日志/结果、`Hardware.exe` Prefetch 或自然退出证据，故分类为 `instrument_failure/ABSTAIN`。
- C66：共享目录日志记录 OUTER5 的 `Popen pid=2784`、8 秒后 `poll=None`，随后卡在 `_handle_disclaimer_dialog/find_target_pid`；CORE1 直接启动核心，6.7/11.6/24.2 秒均 `poll=None`，最终 `taskkill` 成功，未取得自然退出码。
- 结论：核心实际启动已证明，但 C65/C66 都没有证明业务解码完成、绑定响应或 hard/soft 分支。B1 仍为 `VALID_UNOBSERVABLE_ON_THIS_BASE`；详见 `artifacts/evidence/C65_outer_decode_runtime_20260921.md` 与 `C66_core_launch_lifecycle_20260921.md`。

### 10.2 核心运行态内存采集边界（C67，2026-09-21 08:14–08:37）

- COREDUMP3 的 19,796 B 小转储可以列出模块/线程，但内存范围不足，PEB 解析失败；它不能检索业务解码明文。
- COREDUMP4 使用 ProcDump `-ma`，15 s 后得到 45,615,564 B 未封口文件；文件头 stream directory 为空，宿主 `minidump` 解析失败。该文件不是有效完整转储。
- COREDUMP5 将等待改为 60 s、加入 `-n 1` 并清理旧文件；客体日志记录 ProcDump 已退出、文件大小 100,286,462 B，但随后 SSH 与 Guest Additions 均失去响应，宿主未取得可解析转储。
- 结论：内存采集路径证明“核心启动后可进入大转储阶段”，但没有形成可检索运行态解码证据。不得把文件大小、ProcDump 返回码或客体脚本日志写成业务解码成功；详见 `artifacts/evidence/C67_core_memory_capture_20260921.md`。

### 10.3 外层完成语义复核（C68，2026-09-21）

- `_call_spoofer_commandline` 启动 `Hardware.exe` 后固定等待 8 s；`poll() is None` 即返回 `True`，不等待核心退出、不读取授权返回值。
- 调用返回 `False` 时，`run_decode_from_exe` 只记录“调用异常，继续执行”，仍会继续免责、等待、绑定检测和后续清理。
- `final_status=completed` 由壳侧完成自启动部署/痕迹清理后自行生成；`compat2` 还包含固定 180 s 清理等待。
- 结论：外层 `completed`、`Popen` 成功和 `poll=None` 均不是业务解码成功证据。C68 仅闭合了语义解释，不改变 B1 `VALID_UNOBSERVABLE_ON_THIS_BASE`。

### 10.4 核心网络进度边界（C69，2026-09-21）

- `VBox-3bf4.pcap`（核心启动会话）在约 55.3 s 对 `yz.hwid001.com` 有查询/应答各一次，返回 `198.18.2.159`；整份 pcap 没有到该地址的 TCP 流，也没有 1029 端口流。
- `VBox-2a0c.pcap` 也只有 DNS 命中，没有到返回地址的后续连接；`VBox-5198`/`VBox-4e98` 对照没有该 DNS 命中。
- 该结果证明的是“核心启动会话进入域名解析阶段”，不是“授权报文已发送”或“服务端返回码已收到”；因没有 PID 级抓包归因，结论保持会话级。详见 `artifacts/evidence/C69_core_network_progress_boundary_20260921.md`。

### 10.5 外层时间预算与停滞边界（C70，2026-09-21）

- 原始字节码的固定等待为核心 `8 s`、免责探测参数 `5 s`、免责监控约 `30 s`、自动同意后 `2 s`、验证等待 `10 s`；`compat2` 另有固定 `180 s` 清理等待。
- 这些常量不能解释 16 分钟。`_detect_disclaimer_dialog`/`_check_disclaimer_window_gone` 内的 Win32 进程查找、`EnumWindows`、子控件读取没有统一的外层墙钟截止，可能把仪器/客体停滞伪装成长期等待；OUTER5 停在 `find_target_pid` 与此一致。
- 超过阶段预算且没有新的核心业务标志时，分类为 `STALL_SUSPECTED`，转入进程/通道/资源诊断；不得把旧脚本的等待时长、`poll=None`、`final_status=completed` 或超时文件大小写成业务解码成功。详见 `artifacts/evidence/C70_outer_time_budget_and_stall_boundary_20260921.md`。

## 11. 5.1 本地解码核心收口（2026-09-21 09:00–10:20）

本节覆盖当前核心目标，不继承前文“外层/授权行为模型达成”的语义。权威综合件为 `artifacts/evidence/C79_local_decoder_core_synthesis_20260921.md`，正文为 `writeup/06-local-decoder-core.md`。

- 静态定位：`C71`–`C75` 确认 `-n/-m` 参数解析、RC00/RC03 候选位置、`0x14078ce60` 的 `0x10c` 字节原地变换，以及 `0x141757acd` 保护运行时候选链；没有把候选锚点直接升级为最终 decoder。
- 离线 harness：`<HOST_PATH>\\vmctl\\local_transform_harness.py` 自检在 1 s 预算内完成；它复现局部变换，不证明 encode/decode 方向或最终业务输出。
- 有界直接入口：`<HOST_PATH>\\vmctl\\debug_core_call.ps1` 恢复已捕获 `.text`、替换授权前置条件并调用 `main=0x1407a4b90`；实际 fault 为 `0xc0000005 @ 0x1415d0f52`，未命中 RC00 返回、输出 buffer 或业务副作用。没有配置 endpoint。
- 运行时页面：普通有界探针观察到 `.Sq>` 页面运行时变为非零；这只证明页面可生成/解密，不证明函数语义。`.sys` 配套字节仍缺失，用户态/驱动边界未决。
- 状态：`INCOMPLETE / VALID_UNOBSERVABLE_ON_THIS_BASE`。不得把 C64–C70 的通信、授权、外层调度或时间证据记作本地解码完成。
- 清理：实验 VM 曾以 `nic1=null` 运行；随后 poweroff、restore `qoder-clean-20260920`，最终核对为 `VMState=saved`、`nic1=nat`、SSH 转发基线恢复。没有继续启动样本或重复等待。

## 12. C80：post-launch attach 核心边界补强（2026-09-21 10:28–10:38）

本节记录 C79 之后的短时、断网、post-launch attach 观测。它是核心边界补强，不是核心完成证明。

- 6 个有效臂与 1 个无效仪器记录均保留原始日志和 SHA-256；有效臂的时间跨度约 8 秒，没有长时间等待。
- A2200-control 读到 RC00 callsite 首字节 E8；A2200-auth、A250-auth 记录授权门替换成功，但都未命中 RC00。
- A250-gate-rc00 成功装载 gate callsite 与 RC00 callsite；A250-main-gate-rc00 又成功装载 main、gate、RC00 三组断点；各自有界窗口内均未命中。
- attach_core_call_authbypass.log 缺少授权门阶段标志，分类为 invalid instrumentation，不作为样本阴性证据。
- 没有取得 RC00/RC03 返回值、输出缓冲区、文件/注册表/设备副作用或自然业务退出；状态仍为 INCOMPLETE / VALID_UNOBSERVABLE_ON_THIS_BASE。
- 同一 post-launch attach、同一外层启动方式和同一断网基线停止重复。下一步依赖完整 .Sq> 运行时字节、驱动/辅助组件字节，或新的早期观测基线。

权威报告：artifacts/evidence/C80_postlaunch_attach_boundary_20260921.md；生成器：<HOST_PATH>\vmctl\synthesize_attach_evidence.py。

## 13. C81–C84：运行时 `.Sq>` 与原生启动边界（2026-09-21 10:48–11:24）

这一节只记录本地核心路径的新证据，不把通信、授权或外层调度结果升级成解码完成。

- **C81 完整运行时范围**：客体网卡为 `null`，直接启动 `Hardware.exe` 后读取 `.Sq>` VA `0x141174000–0x14205a000` 的 3814 页、15,622,144 B；3814/3814 页读取成功、3812 页非零。运行时 `post_send_wrapper=0x141757acd` 的四条 direct call 已由真实字节确认。原始范围位于 `artifacts/captures/stream_SQSCAN_20260921A/`，报告为 `artifacts/evidence/C81_runtime_sq_range_analysis_20260921.md`。
- **C82 直接重放**：恢复 `.text` 8,257,536 B、逐页写回 `.Sq>` 15,622,144 B、替换授权闸门并调用 `main=0x1407a4b90`；所有写入成功，但在 `0x14169910f` 的 `ret 8` 处 `0xc0000005`，RSP 首 qword 为非规范返回地址，RC00 未命中。分类为 `REPLAY_STATE_MISMATCH / NO_CORE_RETURN_OBSERVED`，不是样本阴性。原始材料在 `artifacts/captures/core_sq_replay_20260921A/`，报告为 `artifacts/evidence/C82_sq_runtime_replay_fault_20260921.md`。
- **C83 原生启动**：不回放 `.Sq>`、不跳转伪造 `main`，首个 loader 断点处只恢复 `.text`、替换闸门并布置 `main`/RC00 断点；20 s 内未命中 `main`。3 s 进度断点记录 RIP=`0x7ffbe736d624`（样本镜像外）、RAX=`4`、RCX=`0x4d4`，分类为 `NO_SAMPLE_ENTRY_OBSERVED / WAIT_BOUNDARY`；不据此解释具体系统 API/驱动/网络。原始材料在 `artifacts/captures/core_native_startup_20260921B/`，报告为 `artifacts/evidence/C83_native_startup_wait_boundary_20260921.md`。
- **C84 句柄探针反证**：对 C83 的 RCX 解释加入一次复制句柄/对象类型探针；新运行的进度现场为 RIP=`0x143a4a035`、RCX=`0x3e9`，`DuplicateHandle` 返回 Windows 错误 6，且仍未命中 `main`/RC00。它证明进度现场在短运行间不稳定，不能把 RCX 猜成已确认等待对象；分类为 `RUNTIME_PROGRESS_NONDETERMINISTIC / NO_CORE_ENTRY_OBSERVED`。原始材料在 `artifacts/captures/core_native_startup_20260921C/`，报告为 `artifacts/evidence/C84_native_progress_probe_variance_20260921.md`。
- **时间契约**：C81 采集总跨度约 11.5 s；C82/C83/C84 各自 20 s 墙钟截止，均有阶段标志；没有重复 C82 的快照重放或 C83/C84 的同一启动臂。
- **状态**：本地解码核心仍为 `INCOMPLETE / VALID_UNOBSERVABLE_ON_THIS_BASE`。C81 关闭了“完整运行时页面缺失”这一采集缺口；C82/C83/C84 暴露的是运行时状态/启动边界，尚未取得核心输入、变换、返回值或本地副作用。

权威报告：`artifacts/evidence/C81_runtime_sq_range_analysis_20260921.md`、`C82_sq_runtime_replay_fault_20260921.md`、`C83_native_startup_wait_boundary_20260921.md`、`C84_native_progress_probe_variance_20260921.md`；运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`；报告生成器：`<HOST_PATH>\vmctl\analyze_sq_runtime_range.py`、`<HOST_PATH>\vmctl\synthesize_sq_replay_evidence.py`、`<HOST_PATH>\vmctl\synthesize_native_startup_evidence.py`、`<HOST_PATH>\vmctl\synthesize_native_progress_probe_evidence.py`。

## 14. C85：RC00 continuation 与本地调用契约（2026-09-21 11:36）

这一节是静态闭合，不是新的 VM 运行。它修正此前把 `0x14078ed39` 当成独立入口的错误，并把 RC00 中确实可见的本地数据流固定下来。

- **入口性质**：`.pdata` 将 `0x14078ed32..0x14078ed39` 与 `0x14078ed39..0x14078ee89` 分成两行；前一行的 `xor r9d,r9d` 正好落到 `0x14078ed39`，没有直接 `call/jmp` 进入 `0x14078ed39`。因此它是依赖前置寄存器/控制流的 continuation，不能作为独立 harness 入口或直接 stub 目标。
- **本地输入与变换**：`[r14]` 指向的数据被复制到 `rsp+0x60`，两轮 `0x80` 字节复制加尾部 `8+4` 字节，形成 `0x10c` 字节缓冲；`0x14078ce60` 以该缓冲为 `RCX` 原地变换 `0x10c` 次。这个阶段已证实为本地变换，但仍未证实是最终 decode 还是请求侧变换。
- **本地状态块**：`rsp+0x50` 先清零 `0x10` 字节，随后 `0x14078d900` 写入四个 dword；它是本地 16 字节状态构造阶段，不是已观察到的文件/注册表/设备输出。
- **外部边界**：随后调用 `0x141757acd`，参数契约为 `RCX=RSI`、`RDX=EBP`、`R8=RSP+0x50`、`R9=0x11c`，并带有 `[rsp+0x20]=RSP+0x50`、`[rsp+0x28]=0x11c`、`[rsp+0x30]=RSP+0x40` 等栈参数；目标位于捕获明文 `.text` 之外，用户态/驱动/网络语义仍未决，故不纳入本地核心完成判定。
- **RC03 边界**：`0x14078ee89` 继续把 `rsp+0x50` 交给 `0x14078db80`，其返回值进入 `decode_failed` 分支；这证明了响应/标记校验位置，不证明存在独立 decoder 输出。
- **状态**：`INCOMPLETE / CONTINUATION_CONTEXT_CLOSED_ONLY`。仍没有最终解码输出、自然返回值或本地副作用证据；不再重复对 `0x14078ed39`、`main` 或同一长等待臂的机械运行。

权威报告：`artifacts/evidence/C85_rc00_split_continuation_contract_20260921.md`；生成器：`<HOST_PATH>\vmctl\analyze_rc00_continuation.py`。

## 15. C86：干净客体的驱动字节边界（2026-09-21 11:44）

本轮只读恢复 `qoder-clean-20260920` 后，通过 Guest Additions 查询目标文件、驱动目录和服务注册表；没有启动样本、没有联网、没有修改客体文件。

- `C:\ept_core\Hardware.exe` 存在，SHA-256 与宿主候选 `Hardware.genB.exe` 相同；`C:\Windows\System32\Hardware.exe` 是另一份旧副本，哈希不同。
- `C:\Windows\System32\drivers\HP_WKS_SWTOOLS_DRIVER.sys` 不存在；目标驱动目录中没有 `SWTOOLS/EPT/Hardware` 命名的 `.sys`。
- 服务注册表只见 `HpSAMD` 等系统服务，没有 `SWTOOLS/HP_WKS/EPT/Hardware` 服务；`HpSAMD.sys` 不替代目标驱动。
- 这只证明干净基线缺少静态驱动字节，不证明样本运行时不会释放/映射驱动。`0x141757acd` 后的用户态/驱动/网络边界仍未闭合，不能把 `0x14078ce60` 升级成最终 decoder。
- 状态：`INCOMPLETE / DRIVER_BYTES_UNAVAILABLE_IN_CLEAN_BASE`。

权威报告：`artifacts/evidence/C86_guest_driver_inventory_20260921.md`。

## 16. C87：样本内嵌驱动排除（2026-09-21 11:49）

本轮只读扫描宿主候选 `<HOST_PATH>\vmctl\out\Hardware.genB.exe`，没有启动样本或靶机。

- 32,671,232 B、SHA-256=`cfa6998ecc2fba92b027985c5283b09cd9c04c636158fd6961a10560afb28bd7`；原始 `MZ` 计数 441，但只有 1 个 `MZ` 的 `e_lfanew` 指向本地有效 `PE\0\0`，即外层镜像。
- 第二个裸 `PE\0\0` 位于 `0x19f0a12`，没有对应有效 `MZ` 头；`HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS`、`\\.\\` 在打包文件中均为 0 命中。
- 结合 C86，当前没有证据表明驱动是一个被遗漏的明文静态伴随文件；仍不能排除压缩/加密 payload 或运行时生成/映射。
- 状态：`INCOMPLETE / NO_PLAINTEXT_EMBEDDED_DRIVER_FOUND`。

权威报告：`artifacts/evidence/C87_sample_embedded_driver_scan_20260921.md`。

## 17. C88：断网直接核心的驱动释放探针（2026-09-21 11:55）

本轮从 `qoder-clean-20260920` 启动，网卡为 `null`，直接运行 `C:\ept_core\Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 2 -m 1`；不启动 `auto_decode.pyc`，不等待 TCP。观察器每秒检查一次目标 `.sys` 与 `C:\Windows\System32\drivers` 新 `.sys`，20 秒后停止样本并回滚。

- 样本 PID=`4132`，20 个 tick 全部 `sample_exited=False`，目标驱动路径始终不存在，`new_sys` 始终为空。
- 这证明当前 20 秒断网路径没有把目标驱动直接落到预期目录，也没有给出可收集的 `.sys` 文件；不能据此证明不存在内存映射或更晚/其他路径加载。
- 状态：`INCOMPLETE / NO_DRIVER_RELEASE_OBSERVED_IN_20S`。同一短启动/目录观察臂不再重复。

权威报告：`artifacts/evidence/C88_driver_release_probe_20260921.md`。

## 18. C89：原生启动前置于本地 helper 的边界（2026-09-21 12:03）

本轮不是重复 main/RC00 观察，而是在同一原生启动第一断点处新增 `0x14078ce60` 与 `0x14078d900` 两个本地 helper 入口断点；网卡为 `null`，墙钟上限 10 s。

- `.text` 恢复、授权前置条件替换、main、RC00、local transform 和 local state builder 的断点写入均成功。
- 10 s 内只到达镜像外的进度现场：`RIP=0x143a49c3d`、`RAX=0x36`、`RCX=0x658`；句柄复制返回错误 6。`main`、RC00、`0x14078ce60`、`0x14078d900` 均未命中。
- 因此本轮没有取得 helper 的真实 `0x10c` 输入/输出；它把当前阻断进一步定位为“原生启动尚未到本地 helper”，不是“helper 已执行但没有输出”。
- 状态：`INCOMPLETE / STARTUP_BOUNDARY_STILL_BEFORE_LOCAL_HELPERS`。不再延长同一启动等待；下一动态 seam 必须调用已定位的本地 caller，或取得更早的运行时状态。

权威报告：`artifacts/evidence/C89_native_local_helper_boundary_20260921.md`；原始日志：`artifacts/captures/core_native_local_helpers_20260921A/`。

## 19. C90：本地 helper 链动态闭合到可复现中间结果（2026-09-21 12:27–12:35）

本轮只调用已定位的本地 caller seam，不启动 `auto_decode.pyc`、GUI 或网络，也不等待自然入口。客体网卡为 `null`，恢复 `qoder-clean-20260920`，`.text` 恢复哈希为 `5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`，本地调用 wall-clock 上限为 8 s。

- `0x14078f060` 在合成的 caller-local 输入上实际进入 `0x14078ce60` 与 `0x14078d900`；transform 输入/输出均为 `0x10c` 字节，状态输出为 16 字节。`0x14078cd70` 的真实返回为 `RAX=0x2567c4e5`，`0x14078d900` 的返回值 `RAX=0xd9fa` 不是输出缓冲区内容。
- `0x14078ce60` 的动态输出 SHA-256=`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`；`local_transform_harness.py` 离线逐字节匹配。
- `0x14078d900` 的动态 16 字节输出为 `a47b1c4e030ca1e4bcdbae01f044cf60`，`local_state_harness.py` 离线逐字节匹配。第一次调试采集多取的 402 字节只使用前 268 字节；`0x14078cd70` 的一次性 `add r9,2` 在循环前，回跳目标是后续 `movzx`，所以每轮实际消费连续四字节，总代价为 `0x43×4=0x10c`。
- 运行时在 `0x14078cd70` 入口读回的代码与静态 `.text` 除断点首字节 `0xcc` 外完全一致；因此先前的 402 字节解释是回跳目标误读，已由 C90 撤回，不是运行时自修改。
- 实验在两个 helper 观测后立即停止，未命中自然 `main`/RC00 外部 callsite，也未取得 `0x141757acd` 之后的最终业务输出、驱动调用或本地副作用。
- 状态：`PARTIAL / LOCAL_HELPER_CHAIN_EXACT_REPRODUCED`。这比 C89 前进到本地中间计算，但不等于最终本地解码完成；方向、自然 `-n/-m` 输入、外部辅助/驱动边界仍未决。

权威报告：`artifacts/evidence/C90_local_helper_chain_exact_reproduction_20260921.md`；历史离线入口记录为 `<HOST_PATH>\vmctl\local_transform_harness.py`、`<HOST_PATH>\vmctl\local_state_harness.py`，当前固化入口为 `method/harnesses/core_predevice_harness.py`；原始材料：`artifacts/captures/core_direct_local_caller_20260921F/out/`。

## 20. C91：post-target 边界命中与缓冲区未改写（2026-09-21 12:49–12:55）

本轮在 C90 的直接 caller seam 上只增加 `0x141757acd` 入口和 caller 返回点观测；不启动 `auto_decode.pyc`、不连接网络，样本阶段 cable 为 off，`.Sq>` 页面从已捕获范围逐页恢复，wall-clock 上限 8 s。临时 NAT 仅用于样本未启动时投递脚本，完成后立即断链；结束时恢复到 `saved / qoder-clean-20260920 / nic1=nat`。

- C91A/C91B 两条短臂均在约 0.7–1.6 s 内到达 `0x141757acd`；C91B 修正了调试器此前错误的 R8/R9 context offset，并记录真实契约：`RCX=0`、`RDX=0`、`R8=0x14f058`、`R9=0x11c`。
- 目标入口的 `R8` 指向 284-byte（`0x11c`）caller buffer。入口文件与 caller 返回时同一地址的文件逐字节相同，SHA-256 均为 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`，差异字节数为 0。
- 直接 caller 随后返回 `RAX=0`；`[rsp+0x38]` 候选槽读到的值为 `0x7ffb00000000`，不符合可信长度，未作为业务输出使用。
- 这只证明“空 session/control synthetic 前提下 post-target 未改写 buffer”，不证明有效设备会话的业务结果，也不把返回 0 写成 decode failure。
- 状态：`PARTIAL / POST_TARGET_BOUNDARY_OBSERVED`。本地 helper 链与捕获外边界已经分开，最终有效 session 语义、RC03 validator、自然 `-n/-m` 路径和驱动/辅助组件仍未决。

权威报告：`artifacts/evidence/C91_post_target_boundary_and_buffer_20260921.md`；原始材料：`artifacts/captures/core_direct_local_caller_20260921H/out/`；更新后的运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`。

## 21. C92：本地请求块与响应校验边界（2026-09-21 13:03）

本轮不启动样本、不连接网络，只对 C91 已捕获的 `.text` 和 0x11c caller buffer 做原始字节离线复现。

- C91 的 284-byte buffer 已分段闭合：前 16 bytes 与 `local_state_output.bin` 逐字节相同，后 268 bytes 与 `local_transform_output.bin` 逐字节相同；因此它是“状态头 + 本地变换数据”的同一请求块，不是未知业务明文输出。
- `0x14078ee30..0x14078ee78` 设置的调用参数与 `DeviceIoControl` 类 8 参数 in/out ABI 相似：`R8` 为输入 buffer，`R9=0x11c`，栈上的输出 buffer 仍为同一地址，另有长度与 bytes-returned 候选槽。由于目标位于保护运行时范围，未把它确认成具体 API 或驱动入口。
- `<HOST_PATH>\vmctl\local_response_validator_harness.py` 直接执行恢复 `.text` 中的 `0x14078db80`/`0x14078cd70`：真实 C91 buffer 返回 `RAX=1`、marker=`0x13579bdf`；全零负对照返回 `RAX=0`、marker 保持 0。`--self-test` 已修正为只需要 `.text` 输入。
- 本轮闭合的是本地请求构造与响应/状态完整性校验边界，不是最终业务 decoder；最终业务变换、驱动/辅助组件和自然 `-n/-m` 输入路径仍未决。
- 状态：`PARTIAL / REQUEST_AND_VALIDATION_BOUNDARY_CLOSED`。不得把 validator 正值、空 session 返回 0 或 `DeviceIoControl` 类调用形状升级成业务成功/失败或已确认驱动事实。

权威报告：`artifacts/evidence/C92_local_request_and_response_validator_20260921.md`；历史 validator 入口记录为 `<HOST_PATH>\vmctl\local_response_validator_harness.py`，当前固化入口为 `method/harnesses/core_predevice_harness.py`；复现输出：`artifacts/captures/core_direct_local_caller_20260921H/out/response_validator_report.json`。

## 22. C93：`0x141757acd` 的真实设备 I/O 边界（2026-09-21 13:18–13:19）

本轮在 C91/C92 同一 direct caller seam 上增加一次性系统 API 断点；wall-clock 上限 8 s。运行器恢复 `.text` 与完整 `.Sq>` 页面后，实际观察到：

- `0x141757acd → kernel32!DeviceIoControl → kernelbase!DeviceIoControl → ntdll!NtDeviceIoControlFile`，三层均命中；`CreateFileW`/`NtCreateFile` 均未命中。
- 第一层 API 参数为 `RCX=0`（空句柄）、`RDX=0`（空 control）、`R8=0x14f058`、`R9=0x11c`；栈上的输出 buffer 仍是 `0x14f058`，长度为 `0x11c`，返回长度槽为 `0x14f048`。
- 目标返回后 caller buffer 284 bytes 逐字节不变，SHA-256 仍为 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`；返回长度为 0，caller `RAX=0`。
- 这把 `DeviceIoControl` 类调用形状升级为真实 API 链证据，但空句柄/零 control 只证明包装路径，不证明目标驱动已处理请求，也不把返回 0 写成业务失败。
- 状态：`PARTIAL / DEVICE_IO_BOUNDARY_CONFIRMED`。最终有效句柄、IOCTL 语义、驱动/辅助字节、返回数据和自然 `-n/-m` 连接仍未决。

权威报告：`artifacts/evidence/C93_device_io_boundary_confirmed_20260921.md`；原始材料：`artifacts/captures/core_direct_local_caller_20260921I/out/`；更新后的运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`。

## 23. C94：合成设备参数传播（2026-09-21）

本轮不使用自然授权/设备会话，只在 C93 的 direct caller seam 中对 RC00 callsite 的 RCX/RDX 做一次合成替换；不启动 `auto_decode.pyc`、不连接网络，核心阶段 wall-clock 上限 8 s，结束后恢复 `saved / qoder-clean-20260920 / nic1=nat`。

- 合成 `session=0x1234`、`control=0x222000` 在 `0x141757acd` 入口、`kernel32!DeviceIoControl` 和 `kernelbase!DeviceIoControl` 均以对应值出现，并继续到达 `ntdll!NtDeviceIoControlFile`；输入 buffer 仍为 `0x14f058`、长度 `0x11c`。
- `0x1234` 是无效句柄，调用后返回长度为 0，284-byte buffer SHA-256 前后均为 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`，差异字节数为 0。中间 `0x80000003` 异常归因于无效合成句柄/路径，不能当成业务 `decode_failed`。
- 全量 rdata 扫描同时确认设备路径 `\\.\HP_WKS_SWTOOLS_DRIVER`（VA `0x1407ea374`）、helper 字符串（VA `0x140f8cba0`）和 `FUN_1407890d0` 的锚点；外层 PE 通过 `LoadLibraryA`/`GetProcAddress` 动态解析，静态导入表没有 `DeviceIoControl`/`CreateFileW`/`NtDeviceIoControlFile`/`NtCreateFile`。
- 这关闭的是“参数是否真的穿过用户态 I/O 包装层”，不是有效驱动请求或最终 decoder。自然 session/句柄/IOCTL、驱动/辅助字节、返回数据和本地副作用仍未决。
- 状态：`PARTIAL / DEVICE_ARGUMENT_PROPAGATION_CONFIRMED`。

权威报告：`artifacts/evidence/C94_synthetic_device_args_propagation_20260921.md`；原始材料：`artifacts/captures/core_direct_local_caller_20260921J/out/`；运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`。

## 24. C95：历史运行 minidump 与驱动边界（2026-09-21）

身份限定：`post-real-run` 中提取的 `\Windows\System32\Hardware.exe` 属于 genA/OUTER2，大小 `32,198,144` 字节，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C`，不是本清单的 genB（SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）。C95 因而只能作为历史边界材料。身份纠正报告：`artifacts/evidence/C96_sample_identity_correction_20260921.md`。

本轮不启动客体，只读解析 `post-real-run` 快照链的 VDI 块映射和 NTFS `$MFT`，定位并提取 `\ept\dumps\EPT_C573274B_2066D1C9.exe.3332.dmp`。文件大小 `114,157,625` 字节，SHA-256=`3CB8891F5A114C13A793B1B0C47889DF8EDC67DC1D265203A5BAE315647E19FC`，头部为 `MDMP`。

- dump `ModuleList` 有 45 个模块；去重后的 45 个有效 x64 PE 全部归属于已登记模块，未知用户态 PE 为 0。
- `EPT_runtime_hash` 位于 dump 文件偏移 `0x1714E73`，映射到主模块 `EPT_C573274B_2066D1C9.exe` 的 `0x140FA763A`；相邻有 `runtime-driver-image`。
- dump 中未命中 `HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS_DRIVER`、`Hardware.genB`、`auto_decode.pyc`。
- 该结果只能说明主模块的运行时驱动记录/取证逻辑和历史进程 dump，不能证明驱动 PE 已落盘或包含在用户态 dump 中，也不能替代有效 session 下的本地解码观察。

状态：`PARTIAL / HISTORICAL_MINIDUMP_BOUNDARY_ONLY`。权威报告：`artifacts/evidence/C95_historical_minidump_boundary_20260921.md`；提取物：`artifacts/captures/snapshot_post_real_run_20260921/out/EPT_C573274B_2066D1C9.exe.3332.dmp`。

## 25. C97：genB baked 快照顶层驱动字符串边界（2026-09-21）

只读扫描 `qoder-baked-20260921h` 顶层差分 VDI（UUID=`ea2036b7-5c22-4ff2-982f-47ba4aba8997`）的 2,702 个已分配块，目标驱动名、`.sys`、`SWTOOLS_DRIVER`、`Hardware.genB.exe` 和 `EPT_C573274B` 的 ASCII/UTF-16LE 命中均为 0；命中的是 `EPT_runtime_hash`、`runtime-driver-image` 和普通 `Hardware.exe`，共 41 个。该结果只适用于顶层差分层，不扩展到祖先层或内存映射 payload。

状态：`PARTIAL / GENB_BAKED_TOP_LAYER_NEGATIVE`。权威报告：`artifacts/evidence/C97_genb_baked_top_layer_driver_scan_20260921.md`。

## 26. C98：genB 运行时页面中的 payload 边界（2026-09-21）

只读扫描 C81 取得的完整 `.Sq>` 运行时范围（`0x141174000..0x14205a000`，15,622,144 字节）。`HP_WKS_SWTOOLS_DRIVER`、`.sys`、`SWTOOLS_DRIVER`、`Hardware.genB.exe`、`EPT_runtime_hash`、`runtime-driver-image` 的 ASCII/UTF-16LE 命中均为 0；有效 x64 `MZ → PE\0\0` 候选为 0。该结果只收窄运行时页内的 payload 解释，不代表其他内存区或内核组件不存在。

状态：`PARTIAL / RUNTIME_PAGES_HAVE_NO_EMBEDDED_PE_OR_DRIVER_STRINGS`。权威报告：`artifacts/evidence/C98_runtime_page_payload_scan_20260921.md`。

## 27. C99：genB 本地 pre-device harness 可复现性（2026-09-21）

已将旧 `<HOST_PATH>\vmctl` 临时入口固化为 `method/harnesses/core_predevice_harness.py`。它直接运行核验过的 genB `.text` 中 `0x14078ce60`、`0x14078d900`、`0x14078db80`，不启动样本、不加载授权、不打开设备、不联网。C90 输入复现结果：变换 SHA=`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`，请求块 SHA=`bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`，state=`a47b1c4e030ca1e4bcdbae01f044cf60`，validator=`RAX=1`；全零负对照 `RAX=0`。

状态：`PARTIAL / PREDEVICE_HARNESS_REPRODUCED`。权威报告：`artifacts/evidence/C99_predevice_harness_reproduction_20260921.md`；入口：`method/harnesses/core_predevice_harness.py`。

## 28. C100：`-n/-m` 到本地 caller 的参数路径边界（2026-09-21）

已确认 rdata 中存在 `-n`、`-m`、`-h`、`-now` 字符串；已确认 `0x14078f250` 将 mode、serialMode 和 0x10c-byte caller structure 传给 `0x14078f060`。但静态 `.text`、完整 `.Sq>` 运行时函数均未发现 `-n/-m` 到该 caller 的直接 RIP xref，`0x14078f250` 也未发现 direct-call caller。C90 synthetic seam 不等于自然命令行路径。

状态：`PARTIAL / CLI_STRINGS_FOUND_CALLER_SEAM_NOT_CONNECTED`。权威报告：`artifacts/evidence/C100_cli_parameter_path_boundary_20260921.md`。

## 29. C101：参考运行时驱动身份排除（2026-09-21）

只读核对 `<HOST_PATH>\HexPatch\reference\ept-runtime-driver` 与当前 genB。genB PE 的 `SizeOfImage=0x3F83000`、入口 RVA=`0x235F67`；参考 `edrv_live_kva_full.bin` 的 `SizeOfImage=0xC8D000`、入口 RVA=`0x4EDC23`。C94 已确认 genB 用户态设备路径为 `\\.\HP_WKS_SWTOOLS_DRIVER`，参考镜像实际注册 `R2EHfEN7xzDfUR4GNTC676GOxk8v`，且没有 `HP_WKS_SWTOOLS_DRIVER`/`SWTOOLS` 字符串。参考目录的 `ept-core-diag.c` 是读取 `\\Driver\\edrv` 的私有取证辅助驱动。

结论：该参考层不能作为 genB 的目标驱动、IOCTL 语义或最终解码算法证据；只保留其 VM/kd 取证方法价值。genB 的有效设备会话、目标驱动字节、返回数据和最终本地业务变换仍未闭合。

状态：`REFERENCE_ONLY / TARGET_DRIVER_NOT_IDENTIFIED`。权威报告：`artifacts/evidence/C101_reference_driver_identity_exclusion_20260921.md`。

## 30. C102：C6 重建视图中的用户态设备对象边界（2026-09-21）

`artifacts/captures/stream_C6/C6_multi.exe` 是与 genB 相同 `ImageBase=0x140000000`、`SizeOfImage=0x3F83000` 的三段用户态重建视图，SHA-256=`8978171CE7FC33F31039EA9A5027ABDC9EDD09D52FB0F4065905967FC161C44F`；有效 PE 候选只有外层一个。`0x1407890d0` 将 `\\.\HP_WKS_SWTOOLS_DRIVER` 写入通信对象并调用 `0x140788f00`，返回值区分初始化成功/失败/空对象。

该证据把职责固定为“用户态设备对象初始化”，不把 `0x14078ce60` 或 `0x14078d900` 命名为最终 decoder。当前独立 harness 仍是设备前请求构造 + 设备后 validator；目标驱动字节、有效 IOCTL、返回 buffer 与真实 `RC03 decode_failed` 条件仍未取得。

状态：`PARTIAL / USERMODE_DEVICE_SETUP_CONFIRMED`。权威报告：`artifacts/evidence/C102_c6_multi_user_mode_boundary_20260921.md`。

## 31. C103：历史运行材料中的目标驱动 blob 清点（2026-09-21）

只读检查 `<HOST_PATH>\HexPatch\materials\ept\capture-20260912\real-run\recon\blobs` 的 24 个文件：`HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS_DRIVER`、`HP_WKS`、设备路径和 UTF-16LE 变体均为 0 命中；四个 `driver_injected_*.bin` 均为 0 bytes。现有 PE blob 属于已识别的 `edrv` runtime-driver 参考族；`system32\Hardware` 只有 900 bytes，与历史 CSV 记录的约 8.12MB runtime-driver-image 不符。

结论：保存材料中没有可直接分析的 genB 目标驱动/辅助组件字节。C93/C94 之后的缺口是真实字节缺口，不能用 `edrv` 参考层或 900-byte 文件填充。

状态：`TARGET_DRIVER_BYTES_ABSENT_FROM_PRESERVED_BLOBS`。权威报告：`artifacts/evidence/C103_target_driver_blob_inventory_20260921.md`。

## 32. C104：本地 helper 算法级转录与交叉复现（2026-09-21）

将 `0x14078ce60`、嵌入的 `0x14078cd70` 和 `0x14078d900` 从核验过的 genB `.text` 逐条转成无依赖的 32 位算术参考实现：268-byte 原地 XOR 变换、67 轮四字节摘要、16-byte state 构造。入口：`method/harnesses/core_predevice_reference.py`；不启动样本、不加载授权、不打开设备、不联网。

原生 `.text` harness 与参考实现使用同一组 synthetic globals，在 C90 caller seam、全零和 `00 01 02 ... fb` 三组输入上逐字段一致。C90 输入结果为 transform SHA=`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`、hash=`0x2567c4e5`、state=`a47b1c4e030ca1e4bcdbae01f044cf60`、request SHA=`bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`。验证时修正了 Python 无限精度与 x86 dword 截断的差异；修正后所有三组一致。

该结果把设备前本地变换链提升到算法级复现，不把它升级为最终业务 decoder。自然 `-n/-m` 输入、`0x141757acd` 后有效设备响应、目标驱动/辅助字节和最终业务副作用仍未决。权威报告：`artifacts/evidence/C104_local_helper_algorithm_transcription_20260921.md`。

## 33. C105：用户态 RC03 成功分支与本地解码输出（2026-09-21）

静态闭合 `RC03` 后续分支：`0x14078ee9b` 调用 `0x14078db80`；失败进入 `RC03 decode_failed`；成功后 `0x14078ef02` 比较 response marker 与 `g340`，通过后进入 `0x14078ef42`，对 `[rsp+0x60]` 的 268-byte payload 再次调用 `0x14078ce60`，并将结果复制到 caller structure `+0x80`，随后进入 `RC06 success`。

入口：`method/harnesses/core_local_decode_harness.py`。它支持直接输入 284-byte response，或从已知 268-byte 输入构造 validator-accepted synthetic response；按 `validator → marker == g340 → second transform` 执行，分别报告 `RC03 decode_failed`、`RC04 session_mismatch` 或 `RC06 success`，并在成功时把 268-byte 结果写入 modeled caller structure `+0x80`；不启动样本、不打开设备、不加载授权、不联网。C90 synthetic response 实测 validator=`0x1`、marker=`0x13579bdf`，第二次 transform 输出 SHA 等于原始输入 SHA=`7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e`；self-test 的正例、全零负例和 stale-marker 负例均通过。

结论：用户态本地解码算法和输出字段已闭合；真实驱动 response、自然 `-n/-m` 输入和目标驱动字节仍未决。权威报告：`artifacts/evidence/C105_user_mode_decode_success_seam_20260921.md`。

## 34. C106：RC03 response validator 纯参考转录（2026-09-21）

新增 `method/harnesses/core_response_validator_reference.py`，纯 Python 转录 `0x14078db80` 的三段 state/payload 校验和 marker 生成，不映射样本、不启动设备。native 与 reference 对正常 response、全零、state/payload 位翻转及 `g340` stale-marker 共八个 case 逐项一致，分支分别为 `RC03 decode_failed`、`RC04 session_mismatch` 和 `RC06 success`。这闭合了 response 进入用户态后的 validator 算法，不改变真实驱动 response、自然 `-n/-m` 输入和目标驱动字节仍未决的状态。权威报告：`artifacts/evidence/C106_response_validator_reference_20260921.md`。

## 35. C107：运行时分发表与自然 `-n/-m` 路径边界（2026-09-21）

`C15` 中虽然有两个 `0x14078f060` 函数指针数据项，但恢复 `.text` 内没有指向其 rdata 表范围的 RIP-relative 引用；direct-call 图也没有 `0x14078f250` 的调用者，只有 `0x14078f250 → 0x14078f060`。`C75` 的 parser/consumer 窗口同样没有到 caller seam 或 `0x141757acd` 的直接边。该结果只说明自然路径需要运行时/未捕获分发证据，不能把指针表数值升级为调用链，也不把自然路径判定为不存在。权威报告：`artifacts/evidence/C107_runtime_dispatch_table_boundary_20260921.md`。

## 36. C108：核心计划逐项验收（2026-09-21）

C108 将用户计划中的每个显式要求映射到 C71–C107、三个独立 harness 和当前运行材料。结果为：用户态 response validator/第二次变换/`+0x80` 输出已验证；自然 `-n/-m` 路径、`RUN apply soft_success` 调用链和真实 `DeviceIoControl` response 仍分别为 `MISSING` 或 `PARTIAL`。目标驱动/辅助字节缺失已作为真实未决项交付。后续只有有效 response、运行时分发命中或同身份驱动字节才构成新信息。权威报告：`artifacts/evidence/C108_core_plan_completion_audit_20260921.md`。

## 37. C109：genB 真实 PE 入口与子进程调试边界（2026-09-21）

genB 的 PE 入口 VA=`0x14235F67B`，不在此前候选 helper 所在的 `0x1407…` `.text` 范围；入口实际调用 `0x143C17FB0`，再进入 `0x143C3DEAE` 高地址打包/运行时 dispatch 区。断点实验实际观察到临时 `EPT_*.exe` 子进程；取回的 `EPT_3266F6E0_85B8E896.exe` 大小 `32,671,488` bytes、SHA-256=`3B506E9804B6BFAE8EF47C7BEC7B7C781CE83BB41A76B7999BD9EF3F159D52A4`，与 genB 的共同前缀 `32,671,232` bytes 逐字节相同，追加 `256` bytes。

`.childdbg 1` 已证实可以跟随子进程。一次早期记录因子进程初始 `int 3` 后提前 `q` 被判为 `INVALID_INSTRUMENT`；修正为 `ibp` 过滤后，目标 seam 在 `12 s` 窗口内仍未命中，Guest Control 无输出超时，分类为 `WAIT_TIMEOUT / INSTRUMENT_FAILURE`，不作为样本阴性。实验后已恢复 `qoder-clean-20260920`、`nic1=nat`，VM 为 `saved`。

状态：`PARTIAL / PE_ENTRY_AND_RUNTIME_DISPATCH_BOUNDARY_ONLY`。权威报告：`artifacts/evidence/C109_genb_pe_entry_and_child_debug_boundary_20260921.md`。

## 38. C110：自然 `main` 与 `-n` 解析动态命中（2026-09-21）

在不启动 `auto_decode.pyc`、不联网、不伪造设备响应的条件下，使用 `.childdbg 1` 跟随真实临时子进程，并对 `main`、`0x1407a55ae`、`0x14078f250`、RC00 候选点设置硬件执行断点。父进程自然命中 `main=0x1407a4b90`；临时 `EPT_1FAA9D16_324B4466.exe` 子进程随后命中 `0x1407a55ae`，寄存器显示 `R8=0xa`，与 C75 识别的十进制 strtol-like `-n` 解析调用一致。

该结果把“自然 `-n` 进入解析路径”从 `MISSING` 提升为 `VERIFIED`，但只到参数解析。`-m` 后续路径、`0x14078f250/0x14078f060`、RC00/有效 response、自然 RC03/RC06 和驱动副作用在本轮均未观察；命中第一个高价值目标后主动停止，不对后续做阴性推断。

状态：`PARTIAL / NATURAL_N_PARSE_OBSERVED`。权威报告：`artifacts/evidence/C110_natural_main_and_n_parse_dynamic_20260921.md`；原始摘录：`artifacts/captures/natural_n_parse_20260921/cdb_nparse_probe.txt`。

## 39. C111：自然子进程核心候选点与授权前置边界（2026-09-21）

本轮不启动 `auto_decode.pyc`、不联网、不伪造设备响应。CDB 使用 `.childdbg 1` 和 `cpr:EPT_*.exe` 创建进程过滤器，在临时子进程 `EPT_1E4C1342_A983B4EF.exe` 创建时实际输出两次 `CHILD_BPS_ARMED`，并安装 `0x14078f250`、`0x14078f060`、`0x14078ee73`、`0x141757acd` 四个硬件断点。

12 秒窗口内没有四个候选点命中、RC03/RC06 或有效设备响应。由于命令行使用未替换授权前置条件，该结果分类为 `VALID_CHILD_BPS_ARMED / NO_CORE_CANDIDATE_OBSERVED`，不作为核心不存在或解码失败的证据。下一次若继续，只应使用已审查的最小 bypass seam；不得重复当前无 bypass 的自然启动。

状态：`PARTIAL / AUTH_PRECONDITION_BOUNDARY_OBSERVED`。权威报告：`artifacts/evidence/C111_natural_child_core_gate_boundary_20260921.md`；原始摘录：`artifacts/captures/natural_dispatch_f250_20260921e/cdb_child_cpr_probe_excerpt.txt`；完整输出：`artifacts/captures/natural_dispatch_f250_20260921e/cdb_stdout.txt`。

## 40. C112：单点授权门绕过边界（2026-09-21）

在断网、12 秒墙钟上限和真实 `EPT_*.exe` 子进程跟随条件下，CDB 于 child 创建事件向 `0x1407a3080` 写入 `B8 01 00 00 00 C3`（`mov eax,1; ret`），日志直接显示目标六字节及 `CHILD_BPS_ARMED`。随后 `0x14078f250`、`0x14078f060`、`0x14078ee73`、`0x141757acd` 四个候选点均未命中；没有自然 RC03/RC06、有效设备响应或业务输出。

这只证明单点授权门绕过可复现，且不足以进入自然核心候选链；不能升级为核心不存在、解码失败或无副作用。下一步若继续，必须针对 `main` 内联状态/授权比较或高地址 runtime dispatch 设计新的区分性接缝，不得重复同一 bypass 或延长等待。状态：`PARTIAL / SINGLE_AUTH_GATE_BYPASS_CONFIRMED / CORE_CANDIDATE_UNREACHED`。权威报告：`artifacts/evidence/C112_single_auth_gate_bypass_boundary_20260921.md`；原始输出：`artifacts/captures/natural_dispatch_f250_bypass_20260921c/cdb_stdout.txt`。

## 41. C114：父进程 runtime dispatch 短窗观测（2026-09-21）

在 `qoder-clean-20260920`、`nic1=null`、12 秒墙钟和 `-k/-n 0/-m 1` 条件下，CDB 对真实 PE 入口与高地址 runtime dispatch 设置断点。父进程实际命中 `0x14235f67b` 一次、`0x143c17fb0` 两次、`0x143c3deae` 两次；两次现场分别为 `RCX/R8=0x7e4, RDX=0x9dc70, R9=0x1521b0` 与 `RCX/R8=0x87f, RDX=0x9d730, R9=0x1521b0`。`main`、自然 `-n/-m`、F250/F060、RC00 和 post-target 均无命中。child 创建事件没有出现，故 C112 的单点 bypass 在本轮没有实际应用（`AUTH_GATE_PATCHED=0`、`CHILD_BPS_ARMED=0`）。

该轮新增的是“父进程入口后存在重复且参数变化的 runtime dispatch 现场”，不是自然核心路径或解码结果。状态：`PARTIAL / VALID_RUNTIME_DISPATCH_OBSERVED / CHILD_CORE_NOT_REACHED`。权威报告：`artifacts/evidence/C114_runtime_dispatch_parent_observation_20260921.md`；原始输出：`artifacts/captures/natural_dispatch_runtime_bypass_20260921v2/cdb_stdout.txt`。

## 42. C115：runtime dispatch 栈现场臂的 Guest Control 仪器失败（2026-09-21）

保持 C114 的输入、快照、断网和 child 设计不变，只把高地址断点动作改为附加 `kv`、`dq @rsp L8` 和局部反汇编。VM 启动并进入 `running/nic1=null`，但 Guest Control/收割流程超过约 60 秒没有产生 CDB 输出、运行元数据或命令文件；宿主编排被中止。随后已手动 `poweroff → restore qoder-clean-20260920 → nic1=nat`，VM 为 `saved`。

该轮分类为 `INVALID_INSTRUMENT / CHANNEL_OR_GUESTCONTROL_HANG`，不是样本阴性、不是核心不存在、不是解码失败，也不改变 C114 的有效父 dispatch 证据。空的临时捕获目录未保留为正式产物；在没有新的 Guest Control 收尾方案前不重复同一栈现场臂。

## 43. C116：轻量栈现场臂的 VirtualBox 启动会话失败（2026-09-21）

C116 只把 C114 的 `kv` 现场改为轻量 `RSP + dq @rsp L8 + u`，但 `startvm --type headless` 在客体执行前返回 `E_FAIL / VM session was closed before any attempt to power on`；没有 CDB、退出码或样本事件产物。finally 已恢复 `qoder-clean-20260920`、`nic1=nat`、`saved`。分类：`INVALID_INSTRUMENT / VM_SESSION_CLOSED_BEFORE_START`；不作为样本阴性，未重复同一启动会话。权威报告：`artifacts/evidence/C116_runtime_stack_start_instrument_failure_20260921.md`。

## 44. C117：`RUN apply soft_success` 直接 xref 有界阴性（2026-09-21）

对恢复 genB `.text`（`stream_C6/stream_text.bin`，8,257,536 bytes，SHA-256=`5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757`）使用 Python 3.13 + Capstone 5.0.7 连续扫描 RIP-relative 数据引用。`RUN apply soft_success` 的目标 `0x140f93570` 命中 0 次；同一扫描的控制位 `RC00=1`（`0x14078ed97`）、`RC03=1`（`0x14078eec2`）、`RC04=1`（`0x14078ef2b`）、`RC06=1`（`0x14078efd1`）均通过。结果只说明当前恢复 `.text` 内没有直接 xref，不排除运行时算址/间接分发/未捕获代码。状态：`VALID_BOUNDED_NEGATIVE / NO_DIRECT_RIP_XREF_IN_RECOVERED_TEXT`。权威报告：`artifacts/evidence/C117_soft_success_direct_xref_boundary_20260921.md`；机器输出：`artifacts/evidence/C117a_soft_success_direct_xref_scan_20260921.json`。

## 45. C118：完整 `.Sq>` 范围的 direct-edge 有界扫描（2026-09-21）

对 C81 的完整 `.Sq>` 范围（`0x141174000..0x14205a000`，15,622,144 bytes，SHA-256=`1DAF7EC28A09B43EB456F2027BCBAEB047AAFAB6B1A290CE14EDC9CCE761D1D4`）进行原始 `E8 rel32` 扫描。共发现 127,855 个原始 `E8` 候选；四条 C81 已知控制 direct call 全部命中：`0x141757acf→0x1415844d3`、`0x141757af5→0x1419060e7`、`0x141757afc→0x14171631b`、`0x141757b15→0x141a93e50`。同一扫描对 `RUN apply soft_success`、RC00/RC03/RC04/RC06、`-n/-m` 字符串和 F250/F060 均为 0 direct E8 命中。常见 RIP-relative 字节形态扫描另有 846 个模式，但不作为完整指令边界阴性。

结论仅限当前 `.Sq>` 范围和扫描模式：未发现直接 E8 连接，不排除寄存器间接、绝对地址、运行时生成代码或范围外代码。状态：`VALID_BOUNDED_NEGATIVE / NO_DIRECT_E8_EDGE_TO_CORE_VOCAB`。权威报告：`artifacts/evidence/C118_runtime_sq_direct_edge_boundary_20260921.md`；机器输出：`artifacts/evidence/C118_runtime_sq_direct_edge_scan_20260921.json`。

## 46. C119：genB PE 入口到 runtime dispatcher 的静态 direct-jump 链（2026-09-21）

对当前 genB 原始 PE（SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）按 section 表回算文件偏移：入口 `0x14235f67b` 的真实 `call` 指向 `0x143c17fb0`；该地址首条 `E9` 直接跳到 `0x143c3deae`，后者首条 `E9` 跳到 `0x143c30e27`；landing code 的 `0x143c30e38` 再以 `E9` 跳到 `0x143deac60`。C109 已在真实进程中动态命中前三个地址，C119 提供原始 PE 字节/文件偏移对应关系。

这只闭合“入口进入高地址保护 runtime dispatcher”的静态边界，不把混淆字节线性解释为业务 CFG，也不证明自然 `-n/-m`、RUN apply、RC00/RC03/RC06 或驱动响应。权威报告：`artifacts/evidence/C119_genb_pe_dispatch_static_chain_20260921.md`。

## 47. C120：连续 native core runner 实际执行到 RC06 输出（2026-09-21）

按更新后的目标，C++ runner 调用原始 `0x14078f060`，只替换 `0x1407b4700` 输入准备和 `0x141757acd` 外部边界，不改 transform/state/validator/RC03/RC06。CDB 同进程命中 `0x14078f060`、`0x14078ece0`、`0x14078ce60`、`0x14078d900`、post-target、RC03 continuation、validator、RC06 transform 和第二次 transform。normalized 268-byte fixture 与 RC06 第二次 transform 后 payload SHA-256 同为 `4836808424621EE58D80B558898D8ED2EB1227EB51E14C7F0036C072DAD93BDD`，逐字节相等。

重要限定：post-target stub 未写 response，RC03 validator 实际接受的是 RC00 请求 buffer 的 synthetic request-echo；这证明原始 native 解码链在受控 echo seam 下真实执行，但不证明真实驱动 response 或目标机器发生业务副作用，不能满足 goal 完成门槛。执行位于宿主 C++ runner 的私有映射地址空间。权威报告：`artifacts/evidence/C120_continuous_native_decode_execution_20260921.md`；runner：`method/harnesses/core_continuous_runner.cpp`；归档：`artifacts/captures/continuous_core_decode_20260921/`。

## 48. C132：真实 EPT 解码臂 A 的客体失活与收割失败（2026-09-22）

本轮从 `qoder-clean-20260920` 开始，客体 `C:\ept_core\Hardware.exe` 先通过身份门禁：大小 `32,671,232` bytes，SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`，与 EPT `artifacts/CHECKSUMS.sha256` 的 genB 条目一致。使用外部卡密文件作为输入（仅记录长度 380 与 SHA-256，不记录明文），参数为 `-n 2 -m 1`，run id=`EPT_REAL_DECODE_20260922A`。

客体 runner 启动返回 PID `7504`，但运行后 Guest Control 多次返回 `current status is: starting`，SSH `127.0.0.1:2222` 在 banner exchange 超时；`VBox.log` 记录 Guest unresponsive/catch-up。超过 120 秒预算后客体无法响应 ACPI，宿主按安全收尾强制断电；`PRE/MID/POST`、stdout/stderr、DONE 和自然退出码均未收割。控制台截图没有可见弹窗，但不提供样本业务结果。

本轮分类为 `INSTRUMENT_FAILURE / CHANNEL_LOST_AFTER_REAL_LAUNCH`，不是解码失败、不是分支阴性，也不是核心分离完成。为保留可能已落盘但未收割的状态，关机后创建 `ept-real-decode-20260922A-postmortem`（UUID=`061bcd87-bd3c-46a7-865c-58aa15b4da94`，明确标记 not evidence），随后恢复 `qoder-clean-20260920`。下一臂只改变收割平面：客体 runner 将小型 spool 实时镜像到已核验的 VirtualBox 共享目录，样本、输入、快照和参数保持不变。详情见 `artifacts/evidence/C132_real_decode_arm_instrument_failure_20260922.md`。
## 49. C133：RC00 内部强制解码切口的静态定位（2026-09-22）

本轮不运行 VM，只对 EPT 权威代码捕获 `artifacts/captures/stream_C6/stream_text.bin` 做坐标复核和反汇编。确认真实 RC00 路径在设备/授权接缝之后有两个 2-byte 条件跳转：`0x14078eea2: 75 5e`（validator 结果）与 `0x14078ef10: 74 30`（marker/g340），其后分别通向 marker 检查和真实 RC06 `0x14078ef47`，并最终复制 268 bytes 到 caller `+0x80`。候选运行时补丁为 `75 5e -> EB 5E`、`74 30 -> EB 30`；本轮未应用。该切口保留设备调用、response 缓冲、RC06 和 caller 写回，区别于旧的外层谓词/接缝/validator 替换实验。权威证据：`artifacts/evidence/C133_rc00_internal_forced_decode_cut_20260922.md`。

## 50. C134：RC00 强制解码臂 E 的真实部署与子进程过滤边界（2026-09-22）

真实 EPT 派生样本以卡密 `-n 2 -m 1` 启动后，`C:\Windows\System32\Hardware.exe` 从基线 genA（32,198,144 bytes，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`）变为 EPT genB（32,671,232 bytes，SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`），证明部署动作发生。CDB 未出现任何独立补丁/RC06 marker；原因是本轮只过滤 `cpr:EPT_*.exe`，而真实部署名为 `Hardware.exe`。本轮分类为 `INSTRUMENT_FAILURE / DEPLOYMENT_OBSERVED_CHILD_FILTER_MISMATCH`，不作解码阴性。权威证据：`artifacts/evidence/C134_rc00_forced_decode_arm_deployment_filter_boundary_20260922.md`。

## 51. C135：RC00 强制解码臂 F 的直接部署目标观测失败（2026-09-22）

真实 EPT 派生样本以 `-n 2 -m 1` 启动后，`C:\Windows\System32\Hardware.exe` 再次从基线 genA（32,198,144 bytes，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`）变为 EPT genB（32,671,232 bytes，SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）。本轮 CDB 已将子进程过滤改为 `cpr:Hardware.exe`，但没有任何独立补丁、RC06 或 caller 输出 marker；运行元数据为 `WAIT_TIMEOUT`。因此 E 轮的过滤器名称错误不是充分解释，当前应把问题归类为 CDB 子进程观测面未可靠挂接，不作样本阴性。停止继续尝试 `cpr:` 字符串变体，下一轮改为对已部署 `System32\Hardware.exe` 直接启动/附加。权威证据：`artifacts/evidence/C135_rc00_forced_decode_direct_target_observation_failure_20260922.md`。


## 52. C136：RC00 直接目标路线的客体通道失活（2026-09-22）

G 轮先以真实 EPT 派生样本启动外层进程，准备确认 `System32\Hardware.exe` 部署后再由 CDB 直接接管；样本身份、卡密元数据、CDB 身份和 `PRE` 均通过，但外层启动后 Guest Control 与客体 heartbeat 失活，没有 `DEPLOY_OBSERVED`、直接 CDB、`POST` 或任何 RC00/RC06 marker。宿主按边界断电并创建 postmortem 快照，随后恢复 `qoder-armed-20260919`。该轮分类为 `INSTRUMENT_FAILURE / CHANNEL_LOST_AFTER_OUTER_LAUNCH`，不作为样本阴性；下一轮改为从外层启动时就由调试器接管，取消 `cpr:` 过滤依赖。权威证据：`artifacts/evidence/C136_rc00_direct_target_channel_loss_20260922.md`。


## 53. C137：RC00 全局 deferred breakpoint 的父入口边界（2026-09-22）

H2 不再使用 `cpr:` 子进程过滤器，CDB 从真实 EPT 样本启动并独立命中父进程入口 `0x14235f67b`；35 秒窗口内没有 `CHILD_CREATE`、RC00/RC06 marker，`System32\Hardware.exe` 仍为基线 genA，运行状态为 `WAIT_TIMEOUT`。该轮证明全局 deferred breakpoint 观测面有效，并把当前边界推进到父入口之后、子进程/RC00 之前；不作核心阴性或分离完成结论。下一轮只增加父 runtime dispatcher、自然 `main/-n`、F250/F060 观测点。权威证据：`artifacts/evidence/C137_rc00_global_deferred_parent_entry_boundary_20260922.md`。

## 54. C138：真实 EPT 父级 runtime dispatcher 调度链观测（2026-09-22）

H3 以 EPT 派生样本 `C:\ept_core\Hardware.exe`（SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`）和 `-n 2 -m 1` 运行；卡密只登记长度 380 与 SHA-256，不记录明文。样本上游仍为 `<HOST_PATH>\EPT\sample\`；`<HOST_PATH>\HexPatch` 仅是外部 runner/CDB/VM 材料来源。

- run id=`EPT_RC00_PARENT_DISPATCH_PROBE_20260922H3`。
- CDB 在真实父进程命中 `TARGET_ENTRY`（`0x14235f67b`）以及 `0x143c17fb0 → 0x143c3deae → 0x143c30e27 → 0x143deac60`，四个 dispatcher 地址各命中两次。
- 第一组现场为 `RCX/R8=0x7e4`、`RDX=0x9dc70`、`R9=0x1521b0`；第二组为 `RCX/R8=0x87f`、`RDX=0x9d730`、`R9=0x1521b0`；`0x143deac60` 现场 `RCX=0x6daf15b8`。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、RC00/RC06、caller 写回和成功返回 marker 均为 0；`response_injection=false`。
- 运行元数据为 `WAIT_TIMEOUT`，不是样本阴性。`System32\Hardware.exe` 前后保持 genA（size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`）。
- 静态 PE 反汇编确认入口 `0x14235f6a8` 调用 `0x143c17fb0`，并确认前三段 dispatcher 的直接跳转/常量写入边界；不把高地址链的业务语义写成已证实事实。
- 证据：`artifacts/evidence/C138_rc00_parent_runtime_dispatch_chain_20260922.md`。
- 动态原始日志及运行元数据留在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_PARENT_DISPATCH_PROBE_20260922H3\`；EPT 内解析产物为 `artifacts/captures/parent_dispatch_runtime_20260922H3/`，静态产物为 `artifacts/captures/parent_dispatch_static_20260922/`。
- H3 实验结束后已创建 `ept-real-decode-20260922H3-postmortem`（UUID=`37e9fdb5-0e05-4787-a69f-34b28918dbc5`），随后恢复 `qoder-armed-20260919`；该 postmortem 不是成功证据。

状态：`PARTIAL / PARENT_RUNTIME_DISPATCH_CHAIN_OBSERVED_NO_MAIN_OR_CHILD`。下一条最小区分变量是只在 `0x14235f6a8` 与返回点 `0x14235f6ad` 记录调用前/返回现场；不先对高地址 dispatcher 写补丁。

## 55. C139：真实 EPT 父级 dispatcher 返回点观测（2026-09-22）

H4 保持 C138 的 EPT 派生样本、`-n 2 -m 1`、卡密、快照、断网、response 注入和 RC00 两个候选补丁不变，只新增父入口调用点 `0x14235f6a8` 与返回点 `0x14235f6ad` 的一次性断点。真实样本命中 `0x143c17fb0`、`0x143c3deae`、`0x143c30e27`、`0x143deac60` 各两次；`DISPATCH_CALLSITE` 与 `DISPATCH_RETURN` 均为 0。CDB 命令已进入日志，runner 在 35 秒截止时收尾，运行状态为 `WAIT_TIMEOUT`。

- 客体样本 SHA-256 前后均为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`；样本上游仍为 `<HOST_PATH>\EPT\sample\`，HexPatch 仅提供 runner/CDB/VM 工程材料。
- run id=`EPT_RC00_PARENT_RETURN_PROBE_20260922H4`；`response_injection=false`；卡密只登记长度 380 与既有 SHA-256，不记录明文。
- H4 原始材料在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_PARENT_RETURN_PROBE_20260922H4\`；EPT 解析产物在 `artifacts/captures/parent_dispatch_return_20260922H4/`。
- H4 postmortem=`ept-real-decode-20260922H4-postmortem`，UUID=`98e6e5b1-d008-42f6-87d2-8c1d4f7f1824`；实验后已恢复 `qoder-armed-20260919`，postmortem 不是成功证据。
- `System32\Hardware.exe` 前后保持 genA：size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`。

本轮状态：`PARTIAL / PARENT_DISPATCH_NO_CALLSITE_OR_RETURN_WITHIN_WINDOW`。这不是核心解码失败，也不能证明 dispatcher 永不返回；下一臂只改变首段 `0x143c17fb0` 第一次命中时的内存字节，将其临时改为 `C3` 并继续观察返回点/自然业务点，仍使用可回滚 VM 与派生运行态。

权威证据：`artifacts/evidence/C139_rc00_parent_dispatch_return_observation_20260922.md`。
## 56. C140：首段 dispatcher 运行时 ret 臂的 CDB 仪器失败（2026-09-22）

H5 在真实 EPT 派生样本第一次命中 `0x143c17fb0` 后，尝试用同一个 breakpoint action 执行 `bc`、`eb ... c3` 并继续。`DISPATCH_CRACK_TARGET` 命中一次，但 CDB 报 `Syntax error`；随后字节转储仍为原始 `e9f95e0200`，没有 `DISPATCH_RET_PATCH_APPLIED`、返回点或业务 marker。该轮分类为 `INVALID_INSTRUMENT / BREAKPOINT_ACTION_SYNTAX_BEFORE_PATCH`，不是样本阴性。

- run id=`EPT_RC00_DISPATCH_RET_PATCH_20260922H5`；样本 SHA-256 前后均为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- 原始 CDB 日志、运行元数据和 runner 在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RET_PATCH_20260922H5\`；EPT 解析摘要在 `artifacts/captures/dispatch_ret_patch_instrument_20260922H5/`。
- H5 postmortem=`ept-real-decode-20260922H5-postmortem`，UUID=`ab8c9a33-df87-4804-bf15-e86180241f49`；结束后已恢复 `qoder-armed-20260919`。

本轮没有 `native_return == 0x1`、`changed_bytes > 0` 或任何 caller `+0x80` 证据。下一条只改 breakpoint action：不写内存，命中 `0x143c17fb0` 时将 `RIP` 重定向到已确认的 `0x14235f6ad`，以区分首段控制流阻断与 CDB 写内存语法问题。

权威证据：`artifacts/evidence/C140_rc00_dispatch_ret_patch_instrument_failure_20260922.md`。
## 57. C141：首段 dispatcher 强制返回到入口续接点的结果（2026-09-22）

H6 在真实 EPT 派生样本命中 `0x143c17fb0` 时不改代码字节，只执行 `r rip = 0x14235f6ad`。`DISPATCH_RETURN_FORCED` 命中，证明控制流重定向有效；随后在 `0x14235f6ad` 发生 `0xC0000005` 访问违例，现场指令为 `imul edi,dword ptr [rdi+0x0EBDE3A4],0x7F`，没有进入 `main/-n/F250/F060/RC00/RC06`。

- run id=`EPT_RC00_DISPATCH_RIP_REDIRECT_20260922H6`；样本 SHA-256 前后均为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- 原始 CDB 日志、运行元数据和 runner 在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_RIP_REDIRECT_20260922H6\`；EPT 解析摘要在 `artifacts/captures/dispatch_rip_redirect_20260922H6/`。
- H6 postmortem=`ept-real-decode-20260922H6-postmortem`，UUID=`292e6128-e66c-427c-93bc-eeeb0a250716`；结束后已恢复 `qoder-armed-20260919`。

本轮状态：`PARTIAL / FORCED_RETURN_REACHES_INVALID_CONTINUATION`。它说明高地址 dispatcher 在正常路径上会准备返回后所需的状态，不能被无条件跳过；不是核心分离完成。下一臂只新增 AV 现场寄存器采集，不重复相同的强制跳转。

权威证据：`artifacts/evidence/C141_rc00_forced_return_invalid_continuation_20260922.md`。
## 58. C142：强制续接访问违例的寄存器现场（2026-09-22）

H7 保留 H6 的 `RIP=0x14235f6ad` 强制续接，只在第一次 AV 处采集寄存器。`DISPATCH_RETURN_FORCED` 与 `FORCED_AV_CONTEXT` 均命中；异常现场为 `RIP=0x14235f6ad`、`RDI=0`、`RSP=0x14f400`、`RAX=0x7ffbe736dc70`，调用参数为 `RCX=0x7e4`、`RDX=0x9dc70`、`R8=0x7e4`、`R9=0x1521b0`。随后在 `imul edi,[rdi+0x0EBDE3A4],0x7F` 发生 `0xC0000005`。

- run id=`EPT_RC00_DISPATCH_AV_CONTEXT_20260922H7`；样本 SHA-256 前后均为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- 原始 CDB 日志、运行元数据和 runner 在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_AV_CONTEXT_20260922H7\`；EPT 解析摘要在 `artifacts/captures/dispatch_av_context_20260922H7/`。
- H7 postmortem=`ept-real-decode-20260922H7-postmortem`，UUID=`82532aa7-2ec6-44d5-bdeb-b94b750820c7`；结束后已恢复 `qoder-armed-20260919` 并确认 Guest 登录状态恢复。

本轮状态：`PARTIAL / FORCED_RETURN_AV_CONTEXT_CAPTURED`。它把“强制续接缺少状态”推进为寄存器证据，但不代表自然路径的最终 `RDI` 或唯一根因。下一臂回到不跳过 dispatcher 的正常链，只增加 `RAX/RDI/RSP` 现场采集。

权威证据：`artifacts/evidence/C142_rc00_forced_return_av_context_20260922.md`。
## 59. C143：正常 runtime dispatcher 的 RAX/RDI/RSP 状态转移（2026-09-22）

H8 不做强制跳过，只扩展正常父级 dispatcher 的寄存器观测。第一轮 `0x143c17fb0/0x143c3deae/0x143c30e27` 均为 `RAX=0x7ffbe736dc70`、`RDI=0`、`RSP=0x14f400`；第一轮 `0x143deac60` 为 `RSP=0x14f3e8`。第二轮前三段变为 `RAX=0x7ffbe736d730`、`RDI=0x7ffbe736da30`、`RSP=0x14f400`，第二轮 `0x143deac60` 保持该 RAX/RDI 并再次出现 `RSP=0x14f3e8`。

- run id=`EPT_RC00_DISPATCH_REGISTERS_20260922H8`；样本 SHA-256 前后均为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- 原始 CDB 日志、运行元数据和 runner 在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_REGISTERS_20260922H8\`；EPT 解析摘要在 `artifacts/captures/dispatch_registers_20260922H8/`。
- H8 postmortem=`ept-real-decode-20260922H8-postmortem`，UUID=`e4c89848-60d2-46d8-8b2b-d191aa5ea690`；结束后已恢复 `qoder-armed-20260919`。

本轮状态：`PARTIAL / NORMAL_DISPATCH_REGISTER_TRANSITION_OBSERVED`。直接证据把状态变化区间收窄到第一轮 `0x143deac60` 之后至第二轮 `0x143c17fb0` 之前；没有 `native_return == 0x1`、`changed_bytes > 0` 或 RC00/RC06 结果。下一步围绕该窄区间捕获返回/间接跳转，不再重复外层授权或首段 `ret`。

权威证据：`artifacts/evidence/C143_rc00_normal_dispatch_register_transition_20260922.md`。
## 60. C144：内部 dispatcher 落点边界与状态转移前置点（2026-09-22）

H9 保持 H8 正常路线，只增加 `0x143c17251`、`0x143c774a5`、`0x143d51144` 三个内部 marker。两轮均观察到 `0x143deac60 → 0x143c17251`，`0x143c774a5` 与 `0x143d51144` 均为 0。静态 PE 复核显示 `0x143c17251` 首条写栈并 `call 0x143c77e93`；该 call target 尚未在 H9 动态观测。

- run id=`EPT_RC00_DISPATCH_INTERNALS_20260922H9`；样本 SHA-256 前后均为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。
- 动态原始材料和 runner 在 `<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_INTERNALS_20260922H9\`；EPT 动态摘要在 `artifacts/captures/dispatch_internals_20260922H9/`。
- EPT 静态复核输出在 `artifacts/captures/parent_dispatch_internal_static_20260922/`。
- H9 postmortem=`ept-real-decode-20260922H9-postmortem`，UUID=`39c180f4-610d-4fd1-8bb6-b9df112f410a`；结束后已恢复 `qoder-armed-20260919`。

本轮状态：`PARTIAL / INTERNAL_143C17251_OBSERVED_CALL_TARGET_NOT_REACHED`。下一步只增加 `0x143c77e93` 的动态 marker，不对 `0x143c17251` 或其 call target 写补丁；核心完成门槛仍未满足。

权威证据：`artifacts/evidence/C144_rc00_internal_dispatch_boundary_20260922.md`。
## 61. C145：内部 call target 真实命中但收尾通道丢失（2026-09-22）

H10 在真实 EPT 派生样本上保持 H9 的正常 dispatcher 路线和两个 RC00 内部切口，只增加 `0x143c77e93` marker。严格排除 CDB 命令定义后的直接命中为：`TARGET_ENTRY=1`；四个高地址 dispatcher 各 2 次；`INTERNAL_143C17251=2`；`INTERNAL_143C77E93=2`；`INTERNAL_143C774A5=0`、`INTERNAL_143D51144=0`。因此 `0x143c17251` 后的 call target 已在真实 EPT 派生样本中动态到达两次。

本轮没有 `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回或成功返回 marker；`CDB_DONE`、`POST_STATE`、`run_meta.json`、`post_state.json` 和 `DONE` 均未产生。runner 镜像日志停在 `LAUNCH`，分类为 `CHANNEL_LOST / PARTIAL_INTERNAL_CALLTARGET_OBSERVED`，不是样本阴性。H10 postmortem=`ept-real-decode-20260922H10-postmortem`（UUID=`b5502215-f72b-4bbb-9581-d0acdce7d18a`）；结束后已恢复 `qoder-armed-20260919`，并确认 VM `running`、Guest `LoggedInUsers=1`。

- 权威证据：`artifacts/evidence/C145_rc00_internal_calltarget_observed_channel_loss_20260922.md`。
- 原始材料：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_CALLTARGET_20260922H10\`。

本轮只证明内部 call target 的动态到达，不证明它返回、解码、写 caller `+0x80` 或改变靶机。核心完成门槛 `native_return == 0x1` 且 `changed_bytes > 0` 仍未满足。

## 62. C146：内部 call 的尾跳转边界（2026-09-22）

H11 在真实 EPT 派生样本上只增加静态常规返回点 `0x143c17261` 的动态 marker。`0x143c77e93` 两轮均命中，`0x143c17261` 为 0 次，第二轮 dispatcher 仍继续出现；guest runner 完成了 `run_meta.json` 和 `post_state.json` 收尾，状态为 `WAIT_TIMEOUT`，不是通道丢失。

对同一 EPT 派生 PE 的静态复核显示：`0x143c17251` 调用 `0x143c77e93`，而 `0x143c77e93` 执行 `pop r14; lea r14,[r14+0x60e81]; jmp r14`，因此不是普通 `ret`。以静态常规返回地址 `0x143c17261` 推导的首个 tail-jump 目标为 `0x143c780e2`；该地址只作为下一轮观测目标，尚未动态确认。

H11 的 `pre_state.json` 与 `post_state.json` 样本身份一致，`System32\Hardware.exe` 保持基线 genA，未观察到靶机部署变化。H11 postmortem=`ept-real-decode-20260922H11-postmortem`（UUID=`2958da75-29dd-4b7a-b000-9ef82f95078e`）；结束后已恢复 `qoder-armed-20260919` 并确认 Guest 登录态。

- 权威证据：`artifacts/evidence/C146_rc00_calltarget_tail_jump_boundary_20260922.md`。
- 静态捕获：`artifacts/captures/dispatch_calltarget_static_20260922H11/`。
- 原始动态材料：`<HOST_PATH>\HexPatch\probe\EPT_RC00_CALL_RETURN_PROBE_20260922H11\`。

本轮没有 `native_return == 0x1`、`changed_bytes > 0`、RC06 或 caller `+0x80` 证据。核心完成门槛仍未满足。

## 63. C147：首段 tail-jump 链真实闭合（2026-09-22）

H12 在真实 EPT 派生样本上只增加 `0x143c780e2` 和 `0x143ca323e` 两个静态落点 marker。两轮均观察到 `0x143c77e93 → 0x143c780e2 → 0x143ca323e`；对应 marker 各 2 次。`0x143c17261` 常规返回点、RC00/RC06、caller 写回和成功返回 marker 均为 0。

静态复核显示 `0x143ca3253` 无条件跳转到 `0x143a69b86`，而 `0x143a69b8d` 再跳到 `0x143c3b39e`；两者尚未动态验证。H12 runner 已完整生成前后状态和元数据，分类为 `PARTIAL / TAIL_JUMP_CHAIN_OBSERVED_NO_CORE_ENTRY`，不是样本阴性。H12 postmortem=`ept-real-decode-20260922H12-postmortem`（UUID=`7ee55dea-427b-4b38-b223-510d6ce35273`）；结束后已恢复 `qoder-armed-20260919` 并确认 Guest 登录态。

- 权威证据：`artifacts/evidence/C147_rc00_tail_jump_chain_observed_20260922.md`。
- 静态捕获：`artifacts/captures/tail_jump_static_20260922H12/`。
- 原始动态材料：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_JUMP_PROBE_20260922H12\`。

本轮没有 `native_return == 0x1`、`changed_bytes > 0`、RC06 或 caller `+0x80` 证据。核心完成门槛仍未满足。

## 64. C148：第二段 tail-jump 与状态寄存器转换（2026-09-22）

H13 在真实 EPT 派生样本上增加 `0x143a69b86` 与 `0x143c3b39e` marker。两轮均观察到 `0x143ca323e → 0x143a69b86 → 0x143c3b39e`；两处 marker 各 2 次。`0x143a69b86` 现场 `RAX=0x9472`，`0x143c3b39e` 现场 `R14=0x80000000`。静态复核显示 `0x143c3b425 → 0x143f5164d`，后者再跳到 `0x143e47a9f`；这两个地址尚未动态验证。

H13 已产生完整前后状态和运行元数据，分类为 `PARTIAL / SECOND_TAIL_JUMP_STATE_TRANSITION_OBSERVED`，不是样本阴性。H13 postmortem=`ept-real-decode-20260922H13-postmortem`（UUID=`558b4fc4-1668-4bac-9da3-d1066d6b26ee`）；结束后已恢复 `qoder-armed-20260919` 并确认 Guest 登录态。

- 权威证据：`artifacts/evidence/C148_rc00_tail_jump2_state_transition_20260922.md`。
- 静态捕获：`artifacts/captures/tail_jump2_static_20260922H13/`。
- 原始动态材料：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_JUMP2_PROBE_20260922H13\`。

本轮没有 `native_return == 0x1`、`changed_bytes > 0`、RC06 或 caller `+0x80` 证据。核心完成门槛仍未满足。

## 65. C149：高地址 dispatcher 高频循环边界（2026-09-22）

H14 保持 H13 全部条件，只增加 `0x143f5164d` 与 `0x143e47a9f` marker。首两轮沿既有 tail-jump 链到达这两个地址；35 秒窗口内 `TAIL_143F5164D=69`、`TAIL_143E47A9F=73`，之后持续在该高地址回路中反复出现。`MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、RC00/RC06、caller 写回和成功返回 marker 均为 0。

H14 前后样本身份一致、`System32\Hardware.exe` 保持基线 genA，runner 已生成完整前后状态与元数据，分类为 `PARTIAL / HIGH_ADDRESS_DISPATCH_LOOP_OBSERVED`，不是样本阴性。H14 postmortem=`ept-real-decode-20260922H14-postmortem`（UUID=`93522270-d345-4e4f-ac24-b907519743ae`）；恢复过程中释放了 stale VirtualBox session lock，之后已恢复 `qoder-armed-20260919` 并确认 Guest 登录态。

- 权威证据：`artifacts/evidence/C149_rc00_high_address_dispatch_loop_20260922.md`。
- 静态捕获：`artifacts/captures/tail_jump3_static_20260922H14/`。
- 原始动态材料：`<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_JUMP3_PROBE_20260922H14\`。

本轮没有 `native_return == 0x1`、`changed_bytes > 0`、RC06 或 caller `+0x80` 证据。核心完成门槛仍未满足。

## 66. C150：高地址路径访问违例但缺少寄存器上下文（2026-09-22）

H15 只把 H14 的运行窗口延长到 120 秒。真实 EPT 派生样本到达首段 tail-jump 链和 `0x143f5164d → 0x143e47a9f` 后，CDB 的 `sxe av` 捕获 `0xC0000005`，异常指令显示为 `0x000000021df70790`，但没有寄存器/栈上下文；`MAIN_ENTRY`、F250/F060、RC00/RC06 和 caller 写回均为 0。runner 最终 `WAIT_TIMEOUT`，但完整前后状态和元数据已收集，分类为 `PARTIAL / HIGH_ADDRESS_DISPATCH_AV_WITHOUT_CONTEXT`，不是样本阴性。

H15 前后样本身份一致、`System32\Hardware.exe` 保持基线 genA，临时目录中的既有 EPT 文件集合未变化。H15 postmortem=`ept-real-decode-20260922H15-postmortem`（UUID=`dfededbd-8152-41b8-8afd-bbb470fe5710`）；之后已执行冷启动恢复并确认 Guest 登录态。

- 权威证据：`artifacts/evidence/C150_rc00_high_address_av_without_context_20260922.md`。
- 原始动态材料：`<HOST_PATH>\HexPatch\probe\EPT_RC00_LONG_WINDOW_PROBE_20260922H15\`。

本轮没有 `native_return == 0x1`、`changed_bytes > 0`、RC06 或 caller `+0x80` 证据。下一轮只增加 AV 上下文采集并在 AV 处退出 CDB。

## 2026-09-22：C151 外层 EPT 样本谱系纠正

- 权威上游：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe`，SHA-256 `CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`。
- 静态核对：`main.pyc` `DE746C511178B8748A265A9C56E4C7A21E9703C1CE89DEA2609B1BA6BE33E274`；`auto_decode.pyc` `414476EACB0F3EEE219B073EB3C3E85BBE5AC562AF85E357FA80E499BD56DBA2`。
- 观察：解包树内 `Hardware.exe` 文件名匹配数为 `0`；`auto_decode.pyc` 的自然路径是下载 `UVT-EPT.exe`，再部署到 `C:\Windows\System32\Hardware.exe`，然后以 `-k/-n/-m` 启动。
- 纠正：此前直接运行 `C:\ept_core\Hardware.exe` 的 H/E/F 轮没有保留“本轮由 EPT 外层样本自然产生目标”的闭合谱系，因此不得单独作为核心分离证据。
- 旧计划（已被 2026-09-24 目的校正覆盖）：曾计划从外层 EPT 样本启动并只应用两处候选补丁；该计划把 seam 数值当成硬门槛且未定义 RC06 后行为，现不再作为当前路线。当前路线见 AGENTS.md：真实目标运行必须记录样本谱系、response 来源/注入点、`target_native_return`/`target_caller_diff_bytes`，并继续观察 RC06 后行为。
- 证据：`artifacts/evidence/C151_sample_lineage_correction_20260922.md`；静态捕获目录 `artifacts/captures/outer_sample_static_20260922/`。
## 67. C152：宿主 harness 的伪造 response 局部回归（2026-09-22；不计目标完成）

H17 在映射的 EPT 派生 `.text` 和受控 caller 结构上使用 284B forge fixture。结果属于 `evidence_scope=host_mapped_code_runner`：`harness_native_return=0x1`、`harness_c_struct_diff_bytes=34`（out16）。它证明受控 fixture 可触发映射代码中的某一分支和结构写入；不证明真实目标进程 `target_native_return`、`target_caller_diff_bytes`、真实授权通过、自然设备 response 或解码后行为。C166 对照还记录过 `native_return=0x1` 且 `changed_bytes=0`，说明字段不能混用。

本轮机制结论：C = F060 `[rsp+0x50]` 0x10C 字节 in-out 结构（`0x14078f15f/0x14078f169` 构造）；受控成功路径把响应结构写回 C（纠正此前 C+0x80 起写的误读）；`0x14078f1d7: cmp [rsp+0x50],0x12345678` 是该受控 fixture 的分支条件，不把它命名为真实授权判据。解码器 `0x14078ce60` 的 XOR 流已由 Python/VEH 逐字节复现。真校验器 0x14078db80 在宿主 harness 于体内 0x14078dce9 AV（out17），维持 ret-1 桩；sanctioned 两条 EB 补丁仅作历史实验记录。

- 权威证据：`artifacts/evidence/C152_forged_response_native_accept_20260922.md`（必须按 `RETRACTED/SCOPE-CORRECTED` 说明阅读）。
- 原始材料：`<HOST_PATH>\EPT\scratch\h17\`。

C152 状态：`PARTIAL / HOST_HARNESS_LOCAL_BRANCH_OBSERVED`。目标级真实 Guest 运行、自然 response、RC06 后行为和伪装链仍未闭合。

## 68. C153：靶机实际机器码变化与运行时补丁姿态（2026-09-22）

H5/H17C 的严格复核结论是：没有任何一处 eb 业务补丁被证实写入并保留在目标进程代码中，永久磁盘修改为 0 处。H5 在真实命中 0x143c17fb0 后，CDB action 报 Syntax error；命中点现场仍为 E9 F9 5E 02 00，未变为 C3。H17C 的 0x14078eea2（75 5E -> EB 5E）和 0x14078ef10（74 30 -> EB 30）只存在于已布置的 breakpoint action，目标分支尚未命中，先在 0x0000000176444876 发生 Access violation，日志没有 PATCH1_APPLIED/PATCH2_APPLIED。

因此已确认的运行时变化只有 CDB bu/bp 断点期间的瞬态 0xCC；清除断点或调试器收尾后恢复，不能作为样本业务修改。H5/H17C 的目标程序磁盘哈希、原始字节、命中日志与超时信息见 artifacts/evidence/C153_target_machine_patch_posture_20260922.md。

- H5：EPT_RC00_DISPATCH_RET_PATCH_20260922H5，状态 WAIT_TIMEOUT，CDB target 前后 SHA-256 均为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7。
- H17C：EPT_RC00_PATCH_AND_DECODE_20260922H17C，deploy_observed=false、cdb_timed_out=true；该轮 PRE/POST 的 System32 文件身份变化属于外层部署/镜像状态，不是 eb 写入证据。

本轮状态：CLOSED / NO_CONFIRMED_LIVE_EB_PATCH。该结论不等同于 C151 的 VM/外层自然部署复现已完成；C152 仅保留为宿主 mapped-code/harness 局部分支观察，不是目标级授权或解码后行为证据。


## 69. C155：E 盘与 <OTHER_VM_LABEL> 快照链治理（2026-09-23）

优先级切换轮：暂停全部逆向动作（不回滚、不新建快照、不跑样本），先治理 E 盘空间。起点 E: 可用仅 18G / 99%，曾因磁盘不足导致 WSL 崩溃。本轮通过 VBoxManage 回收死端快照与已提取完毕的离线取证 VHD，未手工删除任何 .vdi/.sav，未触碰 EPT 权威样本。

回收结果：E: 可用 18G → 270G（+252G）；<OTHER_VM_LABEL> 目录 299G → 128G；_read 80G → ~0；快照节点 48 → 16；孤儿介质登记 12 → 0。

- 快照删除 32 个（全部 rc=0、无父盘合并阻塞）：19 个 ept-real-decode-20260922{D..H15}-postmortem（自述 not evidence）、11 个 qoder-baked-20260921{b..k}（描述重复）、A→B→C 链、qoder-backup-20260919、qoder-armed2-20260919。
- 保留 16 节点，当前分支完整：base → post-bootstrap → pre-ept → … → pre-vtpm → qoder-armed-20260919（CurrentSnapshot）→ qoder-clean-20260920 → qoder-baked-20260921k；另保留 pre-ept-run-20260922 与 H5-postmortem（C153 现场）。
- 离线 VHD 4 个 80G 回收依据：_reference/EPT/vm_artifacts/MANIFEST.txt 已确认三块 VHD 内 Hardware.exe 均为 genA 且已交叉核对、内容已提取到 _reference（199M）；genB 只存在于 <OTHER_VM_LABEL> 活动 VDI，不在这批 VHD 内。
- 注销 8 个指向已不存在路径的孤儿介质（<HOST_PATH>/vmctl/*.vhd 6 个、<HOST_PATH>/VMs/hexpatch-inject/* 2 个），避免 VirtualBox 缺失介质报错。

通道绕行（重要）：WSL 互操作下 <HOST_PATH>/Program Files 的 stdout 不被捕获（直接执行、cmd.exe /C、powershell.exe 均为空输出但 exitCode=0）。可靠方式是「Windows 侧执行 + 重定向到文件 + WSL 读回」。

治理后验证：showvminfo rc=0、State powered off、快照树 16 节点且 qoder-armed-20260919 * 标记仍在、HexPatch 共享映射未变、<HOST_PATH> 未触碰。

- 权威证据：artifacts/evidence/C155_disk_governance_20260923.md
- 原始日志：artifacts/evidence/vbox_delete_batch1.log、vbox_delete_batch2.log、vbox_delete_H15.log、vbox_closemedium_read.log、vbox_closemedium_stale.log
- 配置备份：artifacts/evidence/vbox_config_backup_20260923/（<OTHER_VM_LABEL>.vbox 567534c5…、VirtualBox.xml 62fe5f12…）

本轮状态：CLOSED / DISK_RECLAIMED。主线（C151 外层自然部署 + C154 四阶段）保持暂停，待磁盘防线建立后再继续。

## 70. 交接件与两处文档事实修正（2026-09-23）

新增 method/HANDOFF.md：自包含交接提示词（260 行），含环境与工具、规则原文条款、已闭合结论与运行矩阵、19 条陷阱清单、迁移清单、已知环境损坏、接手后第一件事、证据索引。迁移时整目录复制即可。

随交接件核验发现并修正两处过时事实：
- LAYOUT.md §7 原写「快照树 2026-09-20 04:28 起 15 个节点」，已改为 16 个节点并补 C155 指针与 48→16 的演变说明。
- method/DISK_BUDGET.md 背景行原写「C155 治理后可用 270G」，已改为 272G 并补 C155 指针。

另记录一项环境损坏（交接件 §5）：<HOST_PATH>\vmctl 目录已不存在（dir 报找不到文件，find /mnt/e -name 'layout_gate*' 无输出），去向未确认。后果是 .git/hooks/pre-commit 调用的 layout_gate.py 缺失，任何 commit 都会被门禁钩子挡下；LAYOUT.md §3/§5/§6 的脚本引用与 writeup 里的 arm14/15/16.sh 均为死链；artifacts/CHECKSUMS.sha256 末 2 条（<HOST_PATH>/vmctl/out/Hardware.genB.exe、<HOST_PATH>/vmctl/out/chk.rmt）为悬空引用，sha256sum -c 会报 2 条 No such file（其余 19 条不受影响）。尚未修复，需人工决定重建还是移除钩子。

本轮无 VM 操作、无新增快照、无样本执行。E 盘可用仍为 272G。

## 71. C156/C157：CDB 写后读回与入口后 dispatcher（2026-09-23）

C156 在 CDB 初始阶段对 0x14078eea2、0x14078ef10 执行写后读回，观察到 00 00→EB 5E 与 00 00→EB 30；由于早于已知目标入口，不能证明地址当时对应已物化业务代码。证据：artifacts/evidence/C156_min_patch_readback_20260923A.md。

C157 将写入移动至 0x14235f67b 入口命中后。原始 cdb.log 严格按独立整行解析（排除 0:000> 命令回显）确认：TARGET_ENTRY_HIT、两处候选地址写后读回（写入前均为 00 00，与预期原始指令 75 5E/74 30 不符，故不认定为目标业务指令补丁），以及 DISPATCH_143C17FB0_HIT、DISPATCH_143C3DEAE_HIT、DISPATCH_143C30E27_HIT、DISPATCH_143DEAC60_HIT 各出现一次。F060、RC06、caller 输出及成功返回 marker 均无独立事件行；run_meta.markers 对日志全文作包含匹配，受命令回显污染，相关字段不作为事件证据。

C157 runner 状态 WAIT_TIMEOUT，deadline 120 秒，CDB exit code 未取得；CDB 目标样本文件 PRE/POST SHA-256 均为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7。PRE/POST 另见 System32\Hardware.exe genA→genB（0DDC82FC…→CFA6998E…）及 EPT.cmd 1207→1093 字节变化，但写入者、时间与 CDB/外层部署因果关系均未归因。POST 临时匹配项和目标进程摘要均为空；不代表运行期间未创建进程。

核心判据仍未闭合：没有 native_return == 0x1、changed_bytes > 0、F060/RC06 命中或 caller +0x80 前后缓冲。本轮不证明授权闭环、实际业务补丁效果或文件变化归因。

- C157 权威证据：artifacts/evidence/C157_entry_patch_readback_20260923B.md。
- 原始材料：<HOST_PATH>\HexPatch\probe\EPT_RC00_ENTRY_PATCH_READBACK_20260923B\（runner.log、cdb.log、run.cdb、run_meta.json、pre_state.json、post_state.json）。
- C157 收尾只读核对：E: 可用 274.80 GiB；<OTHER_VM_LABEL> 为 poweroff，当前快照 qoder-armed-20260919；未创建快照、未改变 VM 状态。
- 下一步：先修复 marker 解析并增加物化代码页/模块基址与控制流证据；如查部署文件写入者，使用有时限且限额的 ETW/ProcMon 观测。下一轮前重做磁盘、VM/快照和 Guest 健康闸门。

## 72. C158：目标映像地址与代码页观察（2026-09-23）

C158 在 Guest 的 CDB 入口事件处确认 Hardware.exe 映像基址 0x140000000、结束地址 0x143f83000、ImageSize 0x03F83000、路径 C:\ept_core\Hardware.exe。两个候选地址分别为 RVA 0x78eea2、0x78ef10，入口读回的 8 字节均全零，CDB 反汇编均为 add byte ptr [rax],al；与此前假定的 75 5E、74 30 不符。因此本轮没有向目标地址写入机器码，不能将这些地址视为已确认的业务指令补丁点。

原始 cdb.log 中独立运行行确认 [C158_ENTRY]、lm/lmv 映像信息、两处零填充/反汇编及四个 dispatcher（143C17FB0、143C3DEAE、143C30E27、143DEAC60）。MAIN_ENTRY、N_PARSE、F060、RC06、caller 输出和成功返回无独立运行行。runner 在 120 秒 deadline 达到后记 WAIT_TIMEOUT；样本文件 SHA-256 PRE/POST 均为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7。run_meta 的 marker 解析字段未正确产生命中数组，故 marker 事件以原始 cdb.log 整行复核结果为准。

通信：首次 GuestControl 探针通过；期间 Guest Additions/Guest Control 有短暂 not-ready，随后恢复；C158 runner 通过共享数据面留下完整 cdb.log、runner.log、run.cdb、PRE/POST 和 run_meta。runner 超时不是样本业务结果。VM 查询为 running，当前快照 qoder-armed-20260919；实验前 E: 可用 274.02 GiB，实验后复核 273.15 GiB，未创建快照。C158 未取得 native_return == 0x1、changed_bytes > 0、caller +0x80 缓冲，也未闭合授权路径。

- 证据：artifacts/evidence/C159_c158_module_codepage_observe_20260923.md。
- 原始材料：<HOST_PATH>\HexPatch\probe\EPT_RC00_CODEPAGE_OBSERVE_20260923C\。
- 通信规范：method/COMMUNICATION_PLAYBOOK.md §1–§7。
- 后续只沿映像实际内容和映射定位正确业务代码；不得再把两处零填充位置当作已确认补丁点。


## 73. C160：实际 dispatcher 上下文与控制流边界（2026-09-23）

C160 在同一 CDB 启动的 Guest Hardware.exe 中采集四个 dispatcher 现场 RIP/寄存器/反汇编：0x143c17fb0 → jmp 0x143c3deae → jmp 0x143c30e27 → 设置寄存器/压栈并 jmp 0x143deac60 → 压入 r14、rcx 后 jmp 0x143c17251。原始 cdb.log 的独立输出行 78/104/130/156 分别有 C160_D1/D2/D3/D4；因此这是实际执行指令链，不是 marker 命令回显。

C160 未命中 F060（0x14078f060）、RC03 validator（0x14078db80），没有授权 native_return、changed_bytes、caller +0x80 缓冲，也没有机器码写入；结果只确认 dispatcher 链。尝试 !address @rip 时 CDB 扩展加载失败（No export address found / LoadLibrary(ext) failed），无内存区域或保护属性证据。run_meta.markers 仍为空对象，与原始日志命中行不符；marker判定以 cdb.log 整行事件为准。

运行状态 WAIT_TIMEOUT，deadline 120 秒，样本 PRE/POST SHA-256 均为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7；GuestControl 收尾探针返回 current status is: starting，分类为 CONTROL_NOT_READY，不是目标结果。VM 查询为 running，快照 qoder-armed-20260919；E: 启动前约 272.39 GiB，收割时约 271.79 GiB。

- 证据：artifacts/evidence/C160_dispatch_context_20260923D.md。
- 原始材料：<HOST_PATH>\HexPatch\probe\EPT_RC00_DISPATCH_CONTEXT_20260923D\。
- 下一条路线：从 0x143c17251 继续观测少量真实控制流；页属性改用在 Guest 验证过的 VirtualQuery，先确定真正含授权分支指令的代码位置，不复用 RVA 0x78eea2/0x78ef10 零填充候选点。保持 C152 为宿主 harness 独立结论，VM 硬判据仍未闭合。



## 74. C161：尾跳后继边只观测（2026-09-23）

C161 在恢复 qoder-armed-20260919 快照并验证 GuestControl 连续两次短探针成功后运行。首次两次尝试因 Guest 观测目录缺失和 runner 路径初始化问题未有效进入 CDB，分别为仪器失败/前台 GuestControl 超时；修复目录创建后，CDB 日志独立整行确认 [C161_ENTRY]（行63）、[C161_TAIL1]（行76，RIP=0x143c780e2，现场首指令 push rbx）、[C161_TAIL2]（行96，RIP=0x143ca323e，现场首指令 mov qword ptr [rsp+rcx*8-50h],r15）。两断点在本次运行中先后命中，不等于动态证明二者间直接控制流。H12 静态捕获显示 0x143c780fe 为 jmp 0x143ca323e；后续 H12/H13 静态边为 0x143ca3253→0x143a69b86→0x143c3b39e→0x143f5164d，但这些静态边不证明本次运行实际走完整条路径。F060、RC03 未命中。runner 45 秒硬 deadline 收尾为 WAIT_TIMEOUT；CDB exit code 未取得。结果仅为控制流观测，不证明授权成功或阴性。

目标样本 SHA-256 PRE/POST 均为 CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7。无机器码写入；没有 native_return == 0x1、changed_bytes > 0、caller +0x80 前后缓冲，也没有可归因的修改字节、部署行为或日志清理证据。原始 CDB 日志不含卡密明文；运行目录文件哈希、marker 匹配和 parser/多次运行目录复用限制见证据件。

恢复过程：GuestControl 连续 VERR_DUPLICATE，ACPI/reboot 请求均未让原 VM 状态前进；在 C160 spool 已收割、E: 空间确认充足后正常关闭 VM，从既有 qoder-armed-20260919 快照恢复并启动，未创建/删除快照。新启动 NAT Link up，GuestControl 两次短探针成功。收尾 VM running、快照未变，E: 可用约 276.6 GiB。

- 证据：artifacts/evidence/C161_tail_edge_observe_20260923E.md。
- runner：<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_EDGE_OBSERVE_20260923E.ps1（运行前 SHA-256 9BE8CDDBB43B9D1A7B7BDC150B1552706E37C7777028CE8CE0933EA66734C380）。
- 原始收割目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_TAIL_EDGE_OBSERVE_20260923E\。
- 后续：不重跑已确认的 dispatcher/tail 断点；如继续动态观测，先通过 GuestControl 活动会话及独立 C162 runner/spool 可写性闸门，再在首次访问违例处收集 RIP/RSP、通用寄存器、栈、当前指令、模块归属与 VirtualQuery AllocationBase/State/Protect；遇 F060/RC03/RC06 业务点时记录返回值、changed_bytes 和 caller +0x80 前后缓冲。使用唯一 run id、独立目录和短 deadline；timeout 只记为未取得业务证据。

## 75. C164：强制绕过分支 + caller 捕获运行（2026-09-23）

C164 在 `qoder-clean-20260920` 快照（真实访客 VM，非宿主）内做了一次 150 秒有界运行，设计上首次把「子进程断点注入（`sxe -c "$$><child.cdb;g" cpr` + `.childdbg 1`）+ 分支强制写 + caller +0x80 前后缓冲」合到同一轮：`child.cdb` 覆盖入口、`0x14078ee9b` 强制写点、F060、marker 比较点、RC06 前/调用、copy 完成后与 native return；强制写沿用 C105/C131/C133 已静态证实的两处分支 `0x14078eea2: 75 5E → EB 5E`、`0x14078ef10: 74 30 → EB 30`。runner 改为后台启动、宿主经共享盘收割，不再阻塞宿主。

结果：CDB 只命中 `[C164_ENTRY]`（`markers=1`），RIP 与 C109/C160/C163 一致为 PE 入口 `0x14235f67b`。**`[C164_PATCH_SITE]`/`[C164_PATCH_SITE_P]` 从未命中**，即两处强制绕过写入从未执行；F060、marker 比较点、RC06 前/调用、caller copy 后、native return 全部未命中；无 `[C164_AV]`。150 秒后收尾 `WAIT_TIMEOUT`，`cdb_exit_code=1`，`response_injection=false`。

判据状态：`native_return == 0x1` 未取得、`changed_bytes > 0` 未取得，caller `+0x80` 前后缓冲未取得，**未发生任何目标机器码修改**。入口命中不等于授权成功，`WAIT_TIMEOUT` 不等于授权阴性。

本轮还暴露并修正了一个真实混杂项：C164 的 `pre.json`/`post.json` 进程面完全相同，Guest 侧取证确认 `cdb`(pid 1904) 与 `Hardware`(pid 788) 的启动时间为 `2026-09-23T16:30:34/35+08:00`，即 **C163 收尾失败的遗留孤儿进程，持续存活约 3 小时**。已用 `taskkill /T /F` 加 PID 兜底做有界清理（`killed_pids=[1904,788]`，清理后目标进程面为空）。

Guest 驱动/部署取证（清理后瞬时快照）：`C:\Windows\System32\drivers` 仅有微软自带 `HpSAMD.sys`（2019），**没有**清单登记的样本内核 helper `HP_WKS_SWTOOLS_DRIVER.sys`，也无运行中的 Hp/SWTOOLS 服务；`%TEMP%` 下无 `EPT_*.exe`；`C:\ept_core` 仅原始样本。说明该快照是未运行过样本的干净基线。这与「命中入口后长时间静默、既不创建子进程也不到达 `0x14078ee9b`」一致，但只是相关性解释，**不是已动态确认的因果**。`sxe ... cpr` 被 CDB 接受且无语法报错，但 150 秒内未触发，故 child 注入路径既未被执行也未获证伪。

- 证据：artifacts/evidence/C164_forced_branch_and_caller_capture_20260923.md。
- runner：<HOST_PATH>\HexPatch\probe\EPT_RC00_BYPASS_FORCE_20260923C164.ps1（Guest 投递副本 SHA-256 CB86220AFB7951452D0D24FF2B3B2F05D7D327E76A945C64FF0AE082EAEBADDB，与宿主源一致）。
- 原始收割目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_BYPASS_FORCE_20260923C164\（`runner.log`、`phase.txt`、`pre.json`、`post.json`、`done.json`、`run.cdb`、`child.cdb`、`cdb.redacted.log`、`guest_probe.json`）。
- 敏感数据：CDB 原始日志含命令行输入，仅留在 Guest `C:\ept_obs\EPT_RC00_BYPASS_FORCE_20260923C164\cdb.log`，未镜像到宿主；对外只引用 `cdb.redacted.log` 与其哈希。
- 后续：先做一次不带调试器的受限自然部署观测（进程父子 PID、`%TEMP%` 新文件、驱动/服务变化、`C:\ept_core` 与日志目录变化），确认自然路径是否创建子进程/部署物；只有确认能走到设备/授权接缝时，才重跑 child 注入 + 强制写以争取同轮取得 `native_return == 0x1` 与 `changed_bytes > 0`。每轮运行前必须先确认目标进程面归零。

## 76. C165：无调试器自然部署观测（2026-09-23）

C165 按 C164 的「后续」执行：在 `qoder-clean-20260920` 内**不附加调试器**、无补丁、无 response 注入地自然运行目标，75 s 窗口内每 3 s 采集 `Hardware|EPT_|UVT|Hp|SWTOOLS` 进程面（含 PPID 与创建时间）。

**首次取得调试器轮次拿不到的部署证据**：`PRE|proc=0`（起跑进程面干净，C164 孤儿清理生效）→ `TARGET_STARTED|pid=8928` → **第 3 秒** `PROC_SEEN|6272|8928|EPT_FB927D78_7CFC6390.exe|09/23/2026 17:34:05`，即目标 `Hardware.exe`(8928) 自然创建了子进程 `EPT_FB927D78_7CFC6390.exe`(6272)，父 PID 归因明确。

对照 C163（35 s）与 C164（150 s）均在 `.childdbg 1` 下运行且**整轮无任何子进程创建事件**。同一样本、同一参数、同一观测项目，系统性差别只是**是否附加 CDB**。因此可确认的事实是「附加调试器的运行未观察到子进程部署，不带调试器的运行第 3 秒即部署」；这是同参数相关对照，**尚未排除**「CDB 抑制/吞掉了子进程事件」等替代解释，不能直接断言反调试导致分支切换。

本轮未取得 `native_return`、`changed_bytes`、caller `+0x80` 前后缓冲，未发生机器码修改。子进程完整路径未能收割（窗口中断），只能与清单既有部署路径模板并列引用。

运行中断与恢复：Guest 侧 runner 由 GuestControl 会话启动，会话在约 4 s 后被终止并把 runner 一并杀掉（`09:34:06` 后无输出，`post_state.json`/`delta.json`/`done.json` 未产出）；随后 GuestControl 反复返回 `Error starting guest session (current status is: starting)`，3 分钟内不可用，分类 `CONTROL_NOT_READY`。恢复步骤：`controlvm poweroff` → `startvm` 报 `The VM session was closed before any attempt to power it on`，定位并清理属于本 VM 的 stale `VBoxHeadless` 链（6256→18416→17800）→ 重启后 Guest 引导卡在 `GuestAdditionsRunLevel=1` 约 3 分钟无进展 → `snapshot restore qoder-clean-20260920` 重建基线，启动后 `runlevel=3`、两次 `cmd /c ver` 短探针 exit 0。**未创建或删除任何快照**；E: 可用 270+ GiB。

本轮 runner 两个缺陷需在下一轮修正：(1) 未脱离 GuestControl 会话，会话超时会连带杀死 Guest 侧进程树，应改用计划任务或真正脱离会话的启动方式；(2) 3 s 循环内使用慢速 WMI `Get-CimInstance Win32_Process`，应改用 `Get-Process`。

- 证据：artifacts/evidence/C165_natural_deployment_vs_debugger_20260923.md。
- runner：<HOST_PATH>\HexPatch\probe\EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165.ps1（SHA-256 4E93BC4E4CE2C765E147B823A6C0E0402079318E6DA8A1EAB39CCE4DBEC74F3D，与 Guest 投递副本一致）。
- 收割脚本：<HOST_PATH>\HexPatch\probe\C165_post_probe.ps1（因控制面 wedge 未执行）。
- 原始运行目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_NATURAL_DEPLOY_OBSERVE_20260923C165\（有效文件：`runner.log`、`phase.txt`、`pre_state.json`）。
- 后续：不再把 CDB 当作取得授权接缝证据的主路径；优先复用 Guest 内直接调用路线（C130 已证实可命中 `0x14078f060` 并产出 268 B 输出）叠加 C152 已证实的伪造响应头判据（解码头 `0x12345678`）与 `changed_bytes` 统计，在 Guest 侧闭合硬判据并明确标注为 caller/injection 级证据；若坚持自然路径，先修正脱离会话的启动方式与进程采集 API，再补齐 `post_state.json`/`delta.json` 的部署物完整路径与哈希。

## 77. C166：Guest harness 结果未收回（2026-09-23）

C166 复用 C152 H17 caller/injection harness 在 <OTHER_VM_LABEL> 中尝试运行。method/HANDOFF.md 记录 7 个输入哈希与 C152 一致；第一次 runner hash gate 因 PowerShell H/Get-History alias 冲突失败，重命名后 gate 通过并记录 Guest PID 4152 启动。随后 GuestControl 等待两分钟超时并进入 current status is: starting，native_probe.log 与 caller 输出未收回。

判定：INSTRUMENT_FAILURE / CONTROL_NOT_READY。本轮没有 native_return、changed_bytes、caller +0x80 前后缓冲或目标代码页前后差异；字段均为未取得，不是零。该路线是 harness 注入，不能代替真实 Guest 目标运行。C152 out16 的宿主结果保持独立，不与 C166 拼接。

- 复核件：artifacts/evidence/C166_guest_harness_no_harvest_20260923.md（依据现有 HANDOFF 的回溯摘要；原始 Guest 输出未回收）。
- 下一步：先恢复当前候选的 Guest 控制与数据收割通道，再核对 Guest 内样本身份；未通过前不启动目标运行。

## 78. C168：<OTHER_VM_LABEL> 宿主脚手架与通道预检（2026-09-23）

C168_CHANNEL_PREFLIGHT_20260923-01 是不启动样本的宿主侧预检。<OTHER_VM_LABEL> 为 running、快照 control-clean、Guest Additions runlevel 3。GuestControl list sessions 返回 exit 0 / NO_SESSIONS；本轮未登录 Guest。HexPatch 共享映射宿主路径存在，writable=true、autoMount=true。此前一次对 127.0.0.1:2222 的只读 banner 观测仅为端口服务信息；用户表示不记得配置 SSH，因此该观察不作为访问路径，当前预检已移除 SSH 检查。

<HOST_PATH>/HexPatch 已建立 probe、spool、tools、transfer/in、transfer/out；其中只有 Guest 健康探针与 host_to_guest.txt 标记，没有 EPT 仓库或样本副本。标记 RunId 为 CHANNEL-PREFLIGHT-20260923-01；对应 guest ACK 文件尚不存在，Guest 工具清单未取得。宿主 PATH 可见 Rizin、Python、Git；cdb.exe、windbg.exe、7z.exe 未在 PATH 中找到。宿主预检、GuestControl 包装器和 Guest 探针均通过 AST 语法解析。包装器参数转义与临时目录 ACL 检查通过；包装器未执行，因为需要交互式输入 Guest 账号。

- 证据：artifacts/evidence/C168_channel_preflight_host_20260923.json。
- 宿主预检：method/harnesses/target_vm_preflight.ps1；GuestControl 包装器：method/harnesses/guestcontrol_preflight.ps1；Guest 探针：<HOST_PATH>/HexPatch/probe/guest_preflight.ps1。
- 当前闸门：在交互式宿主 PowerShell 运行 guestcontrol_preflight.ps1。它读取当前 RunId，提示输入 Guest 用户名和隐藏密码，通过 ACL 受限临时 passwordfile 调用 GuestControl，只运行 Guest 健康探针并收割匹配 ACK。旧包装脚本检索无命中；本轮未输入或保存凭据、未运行样本。
## 79. EPT 只读运行入口准备（2026-09-23）

`EPTSample` 已作为 <OTHER_VM_LABEL> 的 transient shared folder 加入，宿主源为 `<HOST_PATH>\EPT\sample`，Guest 侧入口为 `\\VBoxSvr\EPTSample`；VM 配置实读为 readonly + auto-mount。权威外层样本 SHA-256 为 `CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`。

宿主预检会核对恰好一个 `EPT*.exe`、权威哈希、transient share 源路径、只读和自动挂载；Guest 探针在共享根枚举并哈希唯一 `EPT*.exe`。默认只做健康 ACK；`guestcontrol_preflight.ps1 -Launch` 才在哈希匹配后从只读 UNC 路径启动外层 EPT，并回写启动 PID/状态。

本入口尚未执行：GuestControl 仍为 `NO_SESSIONS`，ACK 不存在，样本未启动。项目没有可输入的明文卡密：C138/C139 只登记长度 380 与 SHA-256，C165 使用 `[REDACTED]`。因此 `-Launch` 最多只能做 GUI 冒烟，不能作为正常 EPT 流程或目标行为运行；外层 EPT 不能用旧 `Hardware.exe` 替代。

- 当前不执行 `-Launch`：缺少明文卡密，GuestControl 也仍为 `NO_SESSIONS`。
- C130 的无密钥解码核心/伪造应答是独立历史实验，不等于外层 EPT 正常运行。
- 若后续明确选择 GUI 冒烟，才使用 `target_vm_preflight.ps1 -EnsureScaffold` + `guestcontrol_preflight.ps1 -Launch`；其结果只能记为 GUI 启动请求。
## 80. C169：无密钥核心路线材料清点（2026-09-23）

C169 仅清点独立的无密钥核心复现路线，状态 `INVENTORY_ONLY / NOT_EXECUTED_ON_WIN10_CONTROL`。项目没有明文卡密：C138/C139 只登记长度 380 与 SHA-256，C165 使用 `[REDACTED]`。

已核对材料：`forge_caller_input_268.bin` SHA-256 `7C9293E800192A21F09FFFFD88C22DDEB9E83204FE221A128A8F4097CDCC5D6E`；`forge_license_response_284.bin` SHA-256 `BFA525E78731BEAAA2EBF1C64E993FCD933AC43D60B7A6E3D1F61576C78B0CC8`；C6 `.text` SHA-256 `5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757`；rdatafront SHA-256 `87BF94ECB38D5C0270E18AF6F031359EAD4A72E377C1068A8EF9705B182597BC`；rdata SHA-256 `FB63581CCC65D4DC7ADEBF5F041F7A51BC4151589C22D9494BE3437A933AC16F`；RG2 region SHA-256 `09D8D5DE6059679957D3B49F17B9AED6B85C48756FF8D36B41E4CE6E93044C7A`.

`core_predevice_harness.py` 与 `core_local_decode_harness.py` 明确不启动 Hardware.exe、不加载授权、不打开设备、不联网；C152 `runner_h17.cpp` 是宿主 harness。C130/C152 结果不能与外层 EPT 正常运行拼接。

当前不启动 `EPTSample -Launch`。若后续选择这条独立路线，先恢复 <OTHER_VM_LABEL> 的 GuestControl/数据面，再另建 run id，并把结果标注为 core-harness experiment。

## 81. C171: <OTHER_VM_LABEL> rebuild method and install stall (2026-09-23)

- Rebuilt <OTHER_VM_LABEL> from <HOST_PATH>/Windows.iso. VM UUID: e560fa3d-eb6d-4a78-b154-633bdd8bc4fc. ISO SHA-256: 5352E57EAA546FFDBFB89CFD1A215FF4BBE044DF4016ECAF76BAC6219736674F.
- Created 64 GiB dynamic VDI, 2 vCPUs, 4096 MiB RAM, NAT, Guest account <VM_USER>, and a random non-empty password. The password remains only in the host ACL-protected path <HOST_PATH>/VMs/<OTHER_VM_LABEL>/host-secrets/<VM_USER>.password.txt; it is not recorded, echoed, or shared with the Guest.
- HexPatch was added as persistent writable automount from <HOST_PATH>/HexPatch. EPTSample was added after VM start as a read-only automount transient share from <HOST_PATH>/EPT/sample because VirtualBox rejects transient share creation while powered off. Authority sample SHA-256: CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2.
- Image method recorded: capture with VBoxManage controlvm screenshotpng, then call codemode.read with the PNG path, offset 0, limit 1. The read result is an image/png marker plus an image content block. Evidence PNG: artifacts/evidence/C171_rebuild_stall78_screen.png, SHA-256 ACA746426ABF8E2320183BC18895091550867193059EBB7CCC6F87C4DF58FDA8.
- Operator reported the Windows installer stalled at 78 percent. VM was still running, Guest Additions and OS GuestProperties were unset, Guest ACK was absent, and EPT was not launched. Classification: CONTROL_NOT_READY / install stall, not a target result. Detailed method: artifacts/evidence/C171_rebuild_method_and_stall78_20260923.md.

## C173 2026-09-24 Hyper-V Gen1 communication closure
- Active fallback VM: <VM_LABEL>, Generation 1, Windows 10 Pro build 19045, hostname <VM_LABEL>.
- PowerShell Direct control is proven with account <VM_USER> and marker C:/<VM_LABEL>_guest_ready.txt. Evidence: artifacts/evidence/<VM_LABEL>_gen1_powershell_direct_20260924.json.
- Data plane: host SMB read-only share C173_EPTSample backed by <HOST_PATH>/EPT/sample. Guest ACK RunId C173-GEN1-ACK-20260924-04 reports exactly one EPT*.exe and SHA-256 CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2, matching the host authority and expected hash. Evidence: artifacts/evidence/<VM_LABEL>_gen1_channel_preflight_20260924.json and <HOST_PATH>/HexPatch/spool/C173-GEN1-ACK-20260924-04.guest.json.
- Channel checkpoint <VM_LABEL>-gen1-channel-ready is Standard and restore-verified; the post-checkpoint mutation disappeared while ready marker and ACK remained. Evidence: artifacts/evidence/<VM_LABEL>_gen1_channel_checkpoint_restore_20260924.json.
- Tool inventory records CDB/WinDbg/NTSD/KD from Microsoft Windows SDK Desktop Debuggers, 7-Zip, and Rizin. 7-Zip smoke passed; Rizin returned 0xC0000135 due a Guest runtime dependency; CDB/WinDbg file identity is recorded while non-interactive runtime smoke output remains unharvested. Evidence: artifacts/evidence/<VM_LABEL>_gen1_tool_inventory_20260924.json and artifacts/evidence/<VM_LABEL>_gen1_tool_smoke_20260924.json.
- Target gate state: ept_launch_state=NOT_REQUESTED, sample_launch_requested=false, sample_process_observed=false. native_return, changed_bytes, caller +0x80 before/after, code-page diff, and PID/PPID evidence remain PENDING. The real card value is absent from host-only secrets, so the normal EPT run remains SAMPLE_LAUNCH_HELD; historical length/hash records and harness outputs are not substituted.
- Card-source audit C173-card-source-audit-20260924-01 checked filenames and metadata only, found zero candidate card-input files, and preserved SAMPLE_LAUNCH_HELD. Evidence: artifacts/evidence/C173_card_source_audit_20260924.json.
- C173 debugger smoke closure C173-gen1-debugger-smoke-20260924-01: CDB attached benign Guest ping.exe, ran a -cf command file, harvested stdout/stderr through PowerShell Direct plus Copy-Item -FromSession, and left no target/debugger process. CDB is PASS_BENIGN_ATTACH; Rizin remains runtime dependency missing and is waived for this route; sample_launch_requested=false. Evidence: artifacts/evidence/<VM_LABEL>_gen1_debugger_smoke_20260924.json and artifacts/evidence/<VM_LABEL>_gen1_cdb_benign_smoke_20260924_02/.
- C173 post-debugger preflight C173-post-debugger-preflight-20260924-01: Guest smoke directories removed, Guest/host relevant process counts zero, channel checkpoint present. The <VM_USER> PSSession lacks the separate C173SampleReader mapping, so current sample access is DEFERRED_TO_EXISTING_ACK; host authority and existing Guest ACK hashes still match. sample_launch_requested=false; SAMPLE_LAUNCH_HELD.

## C174：Guest 通信与证据收割问题记录（2026-09-24）

- 汇总文档：`artifacts/evidence/C174_guest_communication_incident_register_20260924.md`。
- 覆盖范围：历史 VM/GuestControl/SSH/SCP/共享面故障，日志与完成面收割失败，runner 生命周期与 WMI 轮询，残留进程与 VM 就绪，CDB/marker/超时混杂，C173 已验证的通信修复，以及本轮 shell/PowerShell/路径/文档工具错误。
- 记录编号 I-01 至 I-33、T-01 至 T-10；每项区分已确认、部分确认、待复验和仍未知状态。
- 本记录只完善通信和证据边界，不改变 C173 的 `sample_launch_requested=false`、`SAMPLE_LAUNCH_HELD` 或目标字段未取得状态。

## C175 2026-09-24 C173 Guest 内 caller/injection harness 回归（不计目标完成）

- `evidence_scope=caller_injection_harness`；RUN_ID `EPT-C175-COREHARNESS-01`。VM/通信链路仅证明 harness 可在 C173 Guest 内执行，不证明 EPT 目标样本已启动。
- 投递：Host 打包 `python313.tar.gz`（17.9 MB / 2123 条目）经 `-ToSession` 送达，解包为 `C:\ept_obs\python\3.13.12\python.exe`（3.13.14），`ctypes` 校验 `CTYPES_OK 8`；harness、捕获件与 forge 件 Guest/Host SHA-256 一致（`HOST_VERIFIED`）。
- 运行（均 exit 0）：self-test 的正/负/mismatch 控制符合 harness 预期；`--input` 与 `--response` 均在映射代码段中报告 `evidence_scope=caller_injection_harness`、`harness_rc03_branch=RC06 success`、`harness_validator_rax=0x1`、`harness_decoded_output_bytes=268`、`harness_caller_output_written=true`。这只是 synthetic/caller-injection 回路自洽，不是自然 response 或真实授权结果。
- PID/PPID：self-test=2788、input=7344、response=3084；父进程 PPID=5412；`ppid_live=null`（进程退出后查询落空，如实为未知）。这些是 harness 进程归因。
- harness caller 快照的 14 字节 diff 全落在 `[0x80,0x80+0x10C)`；该数字是 harness 自构造 caller 的 `harness_caller_diff_bytes`，不得改名为目标 `target_caller_diff_bytes`。
- **禁止判据映射：** `harness_validator_rax` 不等于 `target_native_return`；`harness_decoded_output_bytes`、`harness_caller_output_written` 或 harness diff 不等于 `target_caller_diff_bytes`。C175 不满足目标级完成条件，也没有 RC06 后自然行为证据。
- 证据：`artifacts/evidence/C175_coreharness_vm_closure_20260924.md`（标题和结论已标注 `HARNESS-ONLY / NOT TARGET COMPLETION`）；收割件 `artifacts/evidence/C175_coreharness/raw/`；Host 状态 `runs/EPT-C175-COREHARNESS-01/`。

## C176 2026-09-24 无调试自然基线运行

- `evidence_scope=real_sample_guest_run`；RUN_ID `EPT-REAL-20260924-02`；授权单 `IR-2026-0924-EPT`；Guest `<VM_LABEL>`。本轮采用 `natural_launch_no_debugger`：直接启动 `C:\ept_core\Hardware.exe`，不启动 CDB/WinDbg，不设置断点，不注入 response，不写目标进程内存或机器码；仅旁路采集并在 180 秒 deadline 后收尾。
- 目标 PID `4784`（PPID `8464`）自然启动；约 3 秒后自然创建 `C:\Windows\TEMP\EPT_15669800_B33D1B09.exe`，PID `8412`、PPID `4784`。这是无调试条件下的外层启动→临时子进程链证据，不能升级为 RC00/RC03/RC06 已发生。
- 目标 `C:\ept_core\Hardware.exe` 与 `C:\Windows\System32\Hardware.exe` 均为 32,671,232 B、SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`；`ept.cmd` 前后 SHA-256 均为 `8FD825961D4582FF3C43E4E90AC78E4E5F8D7958B2651A7FC16C4693B6172609`。本轮没有目标文件改写证据。
- 网络快照未发现非监听远端连接；这只表示断网隔离条件下未见成功外联，不代表联网条件下行为阴性。注册表/服务/任务为前后快照，未将采样差异升级为全量写入审计。
- `done.json`：`target_native_return=NOT_OBSERVED`、`target_caller_diff_bytes=NOT_OBSERVED`、`rc06_entry=NOT_OBSERVED`、`rc06_return=NOT_OBSERVED`、`post_decode_behavior=NOT_OBSERVED`。180 秒到点后由观察器请求停止 PID `8412` 和 `4784`，不能写成样本自然退出。
- 证据件：`artifacts/evidence/C176_natural_baseline_no_debugger_20260924.md`；原始收割件：`runs/EPT-REAL-20260924-02/harvest/`。关键收割哈希：`done.json=D16871B55E0ADCBCEA92B95F70FF714E3090315F6E6DE619686C9AC657EF7F15`、`events.ndjson=FFC7DD16FBDF823366AB4CD5C56DFFD2F827B8145F3B82BB07659CE0C1A77508`、`pre.json=A66F82CDD00B5F1FD510C4C2E67FEAD65EB4FE7563E5745689987D97045DB48A`、`post.json=73D90E9949FBCF463772E551CE6BBED47D979670C8DD246010065809B653BD43`、`file_changes.json=76B8D9BF957790DCC971783CFEA9475C5A888276E3A5649BFFABB9D17A933E54`、`network.ndjson=607092C28935E0A399BD21663C21E208E1DB4E8C53BF6D3890DC97BE82071DF7`。
- 状态：`NATURAL_BASELINE_COMPLETE / OUTER_START_AND_TEMP_CHILD_NATURALLY_OBSERVED / TARGET_SEAM_NOT_CLOSED / POST_DECODE_BEHAVIOR_NOT_OBSERVED`。本轮证明了外层启动/临时子进程创建不是 CDB 引入，但由于无真实设备 response、无真实卡密且 deadline 到点收尾，仍不能证明解码后完整行为。
## C177：临时授权闸门与自然 child 附加边界（2026-09-25）

- `EPT-AUTHGATE-20260925-01` 至 `-06` 的失败/未命中状态均已按控制面、运行身份或启动即调试差异记录；不得将其写成授权失败。
- `EPT-AUTHGATE-20260925-07`、`-08` 采用 C176 已验证的 SYSTEM 自然启动路径，先观察 `EPT_*` child 再 CDB 附加；两轮均确认自然 child、CDB 附加和两个临时点的实际写入。
- `-08` 命中 `0x1407a4b90`，寄存器 `RCX=0x8, RDX=0x5998c0, R8=0x592680, R9=0x5a6260`；后续授权分支和核心候选未命中，30 秒调试等待到期。
- `real_card_present=false`、`network_request_sent=false`、`response_injection=false`；`target_native_return`、`target_caller_diff_bytes`、目标代码页差异和 post-auth 行为均 `NOT_OBSERVED`。状态：`NATURAL_CHILD_ATTACHED_PATCHED_POINTS_ARMED / AUTHORIZATION_SUCCESS_NOT_ESTABLISHED / TARGET_SEAM_NOT_CLOSED`。
- 证据：`artifacts/evidence/C177_auth_gate_attach_boundary_20260925.json`；原始件：`runs/EPT-AUTHGATE-20260925-07/`、`runs/EPT-AUTHGATE-20260925-08/`。
## C178：静态授权阶段交叉核对（2026-09-25）

- 在登记的 `stream_C6/stream_text.bin` 上完成精确 RIP-relative `LEA`/`MOVABS` 目标扫描，确认 `StoredVerify`、Init、SetHost、GetServerOption、CardLogin、IsLogin、Cloud_Beat` 的静态阶段标签顺序。
- `0x1407a320e` 取得 `0x141154ae7`，`0x1407a3215` 调用 `0x1403b3d30`；该边界与 `C20_gate_cfg.txt`、`C43b_site_attribution.txt` 一致。
- 本轮只增强 `OBSERVED_STATIC` 阶段顺序和 CardLogin 地址传递边界；协议字段、动态 Winsock resolver caller、请求/response buffer 与长度、runtime return code 和授权结果仍未闭合。
- 证据：`artifacts/evidence/C178_static_stage_xref_boundary_20260925.json`；状态：`STATIC_STAGE_ORDER_STRENGTHENED / PARTIALLY_RECOVERED_DYNAMIC_RESOLUTION / PROTOCOL_UNRESOLVED`。

## C180：主程序入口门释放但解码授权门未通过（2026-09-25）

- RUN_ID `EPT-AUTHGATE-20260925-20`，无 `-k` 参数；四全局写入仅用于入口观察，不能称解码授权。
- 阶段日志只有 `Setup.SP_Verify_Init=0x00000000` 与 `Setup.SP_Verify_GetServerOption=0xfffffffd`，随后消息框和 `KERNEL32!FatalExit`；没有 `StoredFlow`/`Run.*`、`HIT_OPEN_AUTH`、`HIT_COMM_INIT` 或 `HIT_RC00`。
- `rc03`、`rc06`、`target_native_return`、`target_caller_diff_bytes` 和后授权行为均 `NOT_OBSERVED`。状态：`MAIN_ENTRY_GATE_RELEASED_BUT_DECODE_AUTHORIZATION_NOT_PASSED`。
- 证据：`artifacts/evidence/C180_decode_gate_not_passed_20260925.json`；原始件：`runs/EPT-AUTHGATE-20260925-20/`。

## C184 2026-09-25 授权闸门阶段强制链（runs 26-36）→ 部署管线首次打通

- 总台账：`artifacts/evidence/C184_authgate_stage_force_chain_20260925.md`；交接：`HANDOFF-20260925-authgate-pipeline.md`；原始件 `runs/EPT-AUTHGATE-20260925-26..36/`。
- 机制：入口 4 全局（0x141154ced/cf1/ae7/ce9）+ wrapper-1 ret 0x14078ff03 码族归零 + wrapper-2 ret 0x14078ff87 布尔族置 1 + SDK 阶段函数 33c0c3 补丁 + SYSTEM 会话 0 UI 自动化（同意并继续/KEY WM_SETTEXT/应用并启动）。全部内存内、按运行登记、无 response 注入、无卡密伪造。
- 首次取得：Setup 链真实阶段码（Init=0/GetServerOption=-3/GetNotice=-3/CardLogin=-3 与 GUI 触发 -21）；免责声明自然点击；主 GUI 自然进入；KEY=标识值语义确认；**加密配置落盘 `C:\Windows\System32\Hardware\Hardware`（900B）**；**sc.exe config 服务创建 + StartServiceA ×3 + %TEMP% 随机名载荷文件（GxtzesMZfGLDHgvp/kudcHHlnJWaZB）**——首次进入部署/释放行为域。
- 死路记录：免责「不同意」路径（WM_QUIT）→ FatalExit 0x1420378b1 → 跳过 → int3 陷阱 0x1407a7ded；IsLogin=false →「服务器校验失败！」0x140f931a8 → FatalExit 0x142039034；明文 main 区段 FatalExit 0x1407aa694（无驱动可装）。
- 状态：`AUTH_GATE_PARTIALLY_RELEASED / PIPELINE_REACHED_DEPLOY_STAGE / RC00_RC03_RC06_NOT_OBSERVED / target_native_return=NOT_OBSERVED / target_caller_diff_bytes=NOT_OBSERVED / POST_DECODE_BEHAVIOR=PARTIAL(sc.exe+StartService+TEMP 载荷文件已见,HWID 修改/任务/日志/清理未到)`。未完成。
