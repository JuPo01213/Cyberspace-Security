# P1 · 样本静态分析与下发通道

> 全量重写版第 1 篇。拆分前原件保留在 `../archive/EPT_V5.1_初步Writeup.md`（未改、不删）；裸 `§n` 引用一律指该原件，新篇互指写作 `P4§3`。
> 本页每条断言标三态：**观察**（本页或件内可复现）／**推断**／**未决**。复核动作全部为宿主侧只读：读文件、算哈希、解析 PE 头、`marshal`+`dis` 反汇编 .pyc（**不执行样本任何字节码**）、`upx -d`（只解包，不运行）。未访问网络，未解码 `0x140f92550` 处内嵌 token。
> 交叉引用记法：`P4§3` 表示第 4 篇第 3 节。

## 1.1 样本身份与可复现事实

| 量 | 实测值（2026-09-19 重测） | 复核动作 |
|---|---|---|
| `EPT专业游戏维修工具箱V5.1.exe` | **54,382,515 B** | `ls`／`C31` |
| SHA-256 | `ca6b4c6a9a4ddc1c791a0bb3e98585856540c2baa7cac73f92cb21d87acaa3b2` | `verify_p1_physical.py` → `C31` |
| MD5 | `8bbfcc3c558cc746963f11810b43d437` | 同上 |
| PE | PE32+（magic `0x20b`）、machine `0x8664`、3 节、`ImageBase 0x140000000`、`AddressOfEntryPoint 0x55b40`、**`SizeOfImage 0x5d000`** | 头结构解析 `C31` |
| 节表 | `UPX0` VSize 225,280 / RawSize **0**；`UPX1` VSize 126,976 / RawSize 125,440；`.rsrc` VSize 24,576 / RawSize 20,992 | 同上 |
| 壳/附加数据划分 | 147,456 + 54,235,059 = 54,382,515（=文件大小，**精确吻合**） | 同上 |
| 解包产物 | `PYZ.pyz_extracted` **731** 个文件；解包目录递归共 1,998 文件；顶层 64 项 ⇒ CArchive 条目数 ≈ 1,998−731 = **1,267**（旧文记 1,268，含 `PYZ.pyz` 自身即闭合） | `C31` |
| 内嵌实体 | `DrvCeo.exe 26,195,121`、`EPTHWID.exe 16,896`、`Windows Defender.exe 924,160`、`PE.exe 586,109`、`Windows Update Blocker.exe 496,192`、`KSQD.exe 53,760`、`机器码专业查询工具.exe 162,304`、`DX修复/DirectX Repair.exe 1,013,760`、`_pack_html/index.html 208,386`、`network_optimization_guide.html 4,150,927` | 逐个 `ls` 比对，**10/10 逐字节相同** |
| 附带件 | `_pack_tools/Windows Update Blocker.ini`（5,328 B）——旧版清单未列 | `ls` |

**观察**：`_pack_tools` 下确为 7 个可执行体 + 1 个 ini；程序运行所需实体全部本地在样本内。

## 1.2 还原过程（含一处归因作废）

- **观察**：文件内**只有一处** `UPX!` 签名，位于 `0x3e0`；其后 8 字节为 `0d 24 0e 0a | 58 94 a0 03`（version / format / instance / method）。`0x3e0+16` 处的 a32 = `0x00053040`，与旧文"stub 里 `eax=0x53040` 长度"吻合。
- **观察（可复现）**：`upx 5.2.1` 解包直接失败：
  ```
  $ upx -d s.bin -o out.bin
  upx: s.bin: CantUnpackException: header corrupted 3
  Unpacked 0 files.
  ```
- **观察**：文件最后 4 KB 内**没有任何 UPX trailer**，尾部是 PyInstaller CArchive（以 `python313.dll` 名字 + 零填充结束）。
- **作废（旧 §1 表第 3 行）**：「UPX 头部被故意篡改（**SizeOfImage=0x6**）」——`SizeOfImage` 实测 `0x5d000`，不是 `0x6`，该归因错误。可用的篡改证据是另外两条：**UPX 自身的 format 字节 = `0x24`**（非 upx 5.x 接受的取值）**且 trailer 缺失**。
- **未决**：`header corrupted 3` 的确切成因（format 字节非法 vs trailer 缺失 vs 两者皆有）。最小判别检查：读 UPX 源码 `header.cpp` 的 `check_header` 分支，或取一个正常 UPX 打包件做差分——都不需要运行样本。
- **观察**：绕开 `upx -d` 的路径成立且留了产物：unicorn 模拟执行 stub、同时映射 RVA 空间与 `BASE` 空间后停在 OEP；`<HOST_PATH>/EPT/unpack/ept_dump_base.bin`（2,097,152 B）内 `UPX0` 窗口 `0x1000..0x37000` 的**非零字节 = 188,456 / 221,184**，与旧文"UPX0 得到 188,456 字节真实代码"**逐字节吻合**；重建件 `unpack/ept_clean.exe` = 377,344 B、1 节、EP `0x4c30`、`SizeOfImage 0x5d000`，与旧文参数一致。
- **观察（判定依据）**：重建件入口反编译出 `Could not load PyInstaller's embedded PKG archive from the executable (%s)` ⇒ PyInstaller bootloader；此后续逆原生 x86 无意义，改走 `pyinstxtractor_ng` + 字节码。
- **观察**：本机存在 **Python 3.13.15**（`py -0p` 另列 3.14 与 uv 的 3.12.14）。旧文写"本机 Python 为 3.14 ⇒ 只能另装 3.13"——现况是 PATH 上的 `python` 直接就是 3.13，`marshal`+`dis` 可当场复核所有字节码断言（本页 §1.4–§1.7 全部这样重做）。仍需注意的坑不变：**必须在非样本目录运行**，否则样本内 `struct.pyc` 会遮蔽标准库。

## 1.3 「本体都在样本内」——验证①

**观察**：释放与调用面全是本地路径，无一条经网络：

| 位置（字节码常量实测） | 值 |
|---|---|
| `main.ResourceExtractor` 文档串 | 「启动时: 从 `_MEIPASS` 异步释放 EXE/DLL/图片/HTML 到 `C:\R6-QZD\`」；常量 `C:\R6-QZD` |
| `main.view_machine_code` | 常量 `C:\R6-QZD` |
| `auto_decode.<module>` | `C:\Windows\System32\Hardware.exe`、`C:\Windows\System32\Hardware`、`C:\Windows\SysWOW64\SpooferSoftware.exe`、`C:\Windows\SysWOW64\EPTHWID.exe`、`C:\Windows\SysWOW64\WineverySet`、`C:\Windows\SysWOW64\JW.txt`、`C:\Windows\SysWOW64\EPTHWID.txt` |
| `auto_decode._deploy_epthwid` 文档串 | 「部署 EPTHWID.exe 到 `C:\Windows\SysWOW64\`…用于开机自动启动 Hardware.exe 并拦截 EPT 联网」 |

**观察（精确化，旧文写"30+ 处"）**：`_pack_html/index.html` 内 `pywebview.api.*` 共 **42 处、28 个不同方法名**，全文件仅 **1 条 http(s) 链接**（`https://423down.lanzouo.com/b0f1t9l0b`）。⇒ 前后端纯本地桥接，卡密不经任何 HTTP API 回传。

**观察（宿主现状，只读 stat，2026-09-19）**：`C:\Windows\System32\Hardware.exe`、`C:\Windows\SysWOW64\SpooferSoftware.exe`、`C:\Windows\SysWOW64\EPTHWID.exe`、`C:\R6-QZD` **均不存在** ⇒ 本机仍是"未解码"状态。

## 1.4 「卡密验证」的真相：两处真闸门 + 一处假通过

**旧 §0 摘要第 5 条作废**（"样本内唯一对卡密内容做出的实质判定在前端 JS"）。实测有**两处**内容判定，且**取值不同**：

| 位置 | 判据（字节码/前端常量实测） | 说明 |
|---|---|---|
| 前端 `index.html` | `^[a-zA-Z0-9]{30,40}$` | 纯格式，无校验和/签名/查表 |
| `main.SplashScreen._on_confirm`（tkinter 启动窗） | `^[a-zA-Z0-9]{31,36}$` **且** `^(C\|E(?!PT))`，长度常量 `{0, 31, 36}` | 更窄：31–36 位 + 前缀须为 `C`，或 `E` 开头但**不得**是 `EPT` |
| `auto_decode.DecodeEngine.run_decode` | **无**内容判定 | 见下 |

**观察（假通过的字节码序列，`C28`/`C29`）**：`run_decode` 里卡密只有非空检查，随后无条件宣布通过：
```
LOAD_FAST card_key ; TO_BOOL ; POP_JUMP_IF_TRUE L3
  LOAD_DEREF self ; LOAD_ATTR _log ; LOAD_CONST 'WARN' ; LOAD_CONST '⚠ 请先输入卡密！' ; CALL ; POP_TOP
  LOAD_CONST 'failed' ; LOAD_CONST '未输入卡密' ; BUILD_CONST_KEY_MAP ('final_status','error') ; RETURN_VALUE
L3: LOAD_DEREF self ; LOAD_ATTR _log ; LOAD_CONST 'INFO' ; LOAD_CONST '[步骤 ' …   ← 无条件走到这里
```
旧文引注的"源码行 287–291 / 550–553"**本轮确认可复现**：`co_lines()` 给 228 项、非 None 行号 207 个、跨度 `252..558`，287–291 与 550–553 全部存在。（`C28` 一度把它判成 FAIL，是我检查器 `starts_line` 用法的问题，不是文档问题——已记进 §1.8。）

**观察（本轮把"解码动作分支"做到字节码级分离，`C60`）**：`auto_decode.pyc`（208,484 B，sha256 `414476ea…`，magic `f30d0d0a` ＝本机 Python 3.13）里，`run_decode` 的出口不是"一条假通过"，而是**一个 6 取值的字母表**，每个取值都有独立构造点（全模块 36 处）：

| 出口 | 判据（由字节码算出，不是读注释） | 唯一后置动作 |
|---|---|---|
| `failed` | 卡密 `TO_BOOL`（§1.4 那条） | 立刻 return `{'final_status':'failed','error':'未输入卡密'}` |
| **`card_bound`** | `off 4084 STORE_FAST bind_error` → **`off 4192 POP_JUMP_IF_FALSE`**（源行 491） | ERROR 日志 → `off 4272 RAISE_VARARGS`（`CardKeyBoundError('此授权码已绑定其他机器')`）→ `except`（源行 550–553）里 `is_running=False` ＋ return `{'final_status':'card_bound','error':str(e)}` |
| `stopped` | 紧随其后的 `_check_stopped()` 判（`off 4312 POP_JUMP_IF_FALSE`） | return `{'final_status':'stopped'}` |
| `completed` / `no_network` / `need_manual_download` | 各自条件 | 源行 548 等独立构造点 |
| 继续解码 | 上述判定全为假 | 落到 `params.get('versionSelect')` 分发（`off 4324` 起）→ `_call_spoofer_commandline` |

同一个 `bind_error → 分岔 → raise` 形状在 `run_decode_from_exe`（`store@1704`、**分岔 `1812`**/源行 645、`raise@1892`）与 `_wait_and_type_password`（`store@1382`、**分岔 `1394`**、`raise@1456`，其 handler 在源行 4045 `RERAISE` 往上抛）**各独立成立一次** ⇒ 三处实例，不是单点。
**仪器自照（本轮自己造的两处假零，都印进件内）**：① 第一版只数 `RETURN_VALUE`，而 3.13 把常量返回编成 `RETURN_CONST`，于是给必然返回布尔的 `_detect_bind_error_dialog` 印出"0 个返回"；② 第一版只按 `BUILD_CONST_KEY_MAP` 的 keys 元组找出口，漏掉 dict 字面量的 `BUILD_MAP` 形态，把 36 处出口数成 2 处。⇒ **计数为 0 或偏小时，先证明计数器认得全部编译形态**（规则见固定加载的 `ept-analysis-workbench` Skill 与全局门禁）。

**观察**：`main`、`auto_decode`、`activate_system` 三个模块的**全部 code object**（196 + 145 + 8 个）里，`co_names`/`co_varnames`/短字符串常量中匹配 `md5|sha|hmac|crypt|rc4|aes|b64|base64|hashlib|digest` 的命中数为 **0**。唯一像样的近邻是标识符 `share_url`（`auto_decode` 内）。⇒ 密码学判定不可能发生在 Python 层。

## 1.5 卡密被原样透传给外部校验器，结果靠读弹窗回传

**观察**：`auto_decode._call_spoofer_commandline` 的常量里有 `-k`、`-n`、`-m` 三个选项，整型常量 `{1,2,3,5,8}`（+`False`），与 `series_mode = 0 if codeType=='static' else 2`、`run_mode ∈ {1,2,3}`、`time.sleep(8)` 的旧描述一致。

**观察**：回传通道是"读弹窗"。常量证据：
- `DecodeEngine.CardKeyBoundError` 文档串：「卡密已绑定其他机器的特殊异常，用于中止解码流程」；
- `run_decode` / **`run_decode_from_exe`**（旧文未提这第二个变体）都含 `'此授权码已绑定其他机器'` 与 `'⚠ 检测到：此授权码已绑定其他机器！停止解码流程。'`；
- `_detect_bind_error_dialog` 文档串（v1.52 实测记录）：弹窗类名 `#32770`、标题为空、文字在 `Static` 子控件、父链 `Static → #32770 → #32769([Desktop])`；并有 `[BIND-CHECK-B] >>> pywinauto 读子控件 hwnd=` 等三路并行策略痕迹；
- 另有 `PasswordWindowDetector`（旧文未列）：枚举顶层窗口定位标题含「输入密码」、类名 `#32770` 的对话框，采集 HWND/PID/TID/进程路径/类名样式，"锁定目标进程，防止进程切换或伪造"。

⇒ **结论（观察+推断）**：卡密有效性与机器码绑定判定全在外部 `Hardware.exe` 内；Python 层只做参数搬运与 GUI 观察。该外部校验器的内部结构是 **P4** 的主题（其 `-k/-n/-m` 解析点见 `P4§6`）。

**〔本轮更新：这条接缝已从"推断"升级为字节码级自证，`C60`〕**上面那些常量/文档串只是"存在"，真正让接缝成立的是它们之间的控制流，现已算出来：
`_detect_bind_error_dialog(self._log, self._check_stopped())` 的返回值 `bind_error` 在 `run_decode` **`off 4192` 的 `POP_JUMP_IF_FALSE`（源行 491）** 处被消费 ⇒ 真值支 `off 4272 RAISE_VARARGS` → `except` → `final_status='card_bound'`；假值支落到 `off 4312` 的 `_check_stopped()` 判，再落到 `off 4324` 的解码分发。检测器**自身**的判据也在字节码里现形：轮询循环（`check_count < max_checks`、`waited < max_wait`、`waited < 5`）里对 `dlg_title` 与 `all_child_text` 做 `CONTAINS_OP`，关键词元组是 `('绑定','授权码已绑','其他机器')` 与 `('绑定','其他机器','更换授权码','请更换')`，命中即 `[BIND] <<< 返回 True (检测到已绑定弹窗)`，N 次不中则 `返回 False (未检测到绑定弹窗)` 并放行。
⇒ 于是"**读弹窗文字 → 布尔 → 中止/继续解码**"这条链没有剩余推断成分；仍属推断的只剩"弹窗文字由 `Hardware.exe` 的哪条出口产生"，那是 P4 侧的事（`FUN_1407a2a90` 弹框与 `0x141a1ff1b`/`0x1417612fa` 的进程效果，见 §4.4(6)(7) 与 `C59`）。

**观察（接缝的 core 侧也已落到字节上，`C63`）**：上一句留的那个缺口本轮关掉了一半——壳的关键词**确实**是核心打出来的字样，且位置可指。对四块原始捕获按 GBK 与 UTF-16LE 两种编码逐字节搜（每块先证明基址：`.rdata` 块用 ASCII 地标 `yz.hwid001.com@0x140f92688` 反解出 `base=0x140f80000`，再用**不同类型**的第二地标 GBK「授权验证」`@0x140f924f8` 复核；`stream_text.bin` 用块内自带 PE 头读 `ImageBase=0x140000000`，再用已知函数字节序列 `83 3D 34 1C 9B 00 01 @0x1407a30b2` 复核，往返都印进件内）：

| 命中位置 | 内容（GBK 原文，节选） | 与壳判据的关系 |
|---|---|---|
| `0x140f9301a..0x140f93068` | `授权码已经过期!·授权码已被封停!·禁止同时在线!···此授权码已绑定其他机器，请更换授权码!·…授权状态已失效，请重新登录!···授权已在其他机器…` | 壳的两组关键词（`绑定/授权码已绑/其他机器`、`绑定/其他机器/更换授权码/请更换`）**全部命中这一段**；命中形态是 GBK，UTF-16LE 为 0 |
| `0x1407df027` 邻域（`.rdata` 前段，另一处文案池） | `…常状况，无法登录·无法激活卡密·当前设备信息与卡号绑定信息不…`、`…服务器主动踢下线或被其他连接登录挤下线）·已在其他机器…` | 同样含 `绑定`/`其他机器` |
| `0x140f924c0`（正文）/ `0x140f924f8`（标题）＝「授权状态异常，本地配置与固定部署已清理。」/「授权验证」 | **不含任何一个壳关键词** | ⇒ **阻断支的弹框不会被壳认成 `card_bound`** |

**推断（标明是推断）**：既然绑定文案与阻断文案是两组不同的串，壳侧行为应当是——卡密"已绑定"时核心弹的框被壳读到 ⇒ `final_status='card_bound'` 中止解码；而"授权状态异常＋已清理"那条硬阻断支的框**不会**被关键词命中 ⇒ 壳检测器返回 False，壳继续往下走。两件事在文字层面就分得开，但"核心在哪种输入下打哪一条"仍要看运行时：这正是本轮烘进盘里的臂（`arm22c.ps1` 的 `DLG`/`DLGCHILD` 记录会把弹窗标题与每个子控件文字按 UTF-16 hex 原样带回来）要回答的。

## 1.6 下发通道：三源与"已经坏了"

**观察（常量层，本轮重测）**：`auto_decode`/`main` 的 .pyc 里存在两组不同的飞书页面与多个直链——

| 用途 | 常量 |
|---|---|
| 解码包下载页（主） | `https://my.feishu.cn/wiki/OMXlwKvyZiYQJTkVZrMcqY6vntd?from=from_copylink` |
| 公告/通知页（旧文未列） | `https://my.feishu.cn/wiki/LJGmwx6iqikpbMkO4BJcD2tznCk?from=from_copylink`（由 `_fetch_feishu_notice` 取） |
| 硬编码直链 | `http://xz.hwid001.com/d/yd2537/laomaohwid/UVT-EPT.exe?sign=…` |
| 同主机的其它载荷 | `http://xz.hwid001.com/d/JW/TY-15852736870/WinRAR7.01-Final-x64火焰汉化版.exe?sign=…`、`http://xz.hwid001.com/d/JW/YD-15852736870/MAC硬刷工具.qp.exe?sign=…` |
| 蓝奏云 | `https://jiwu.lanzouw.com/b0hdinspa` |
| WebView2 | `https://go.microsoft.com/fwlink/p/?LinkId=2124703`、`https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/0bbb66e3-…/MicrosoftEdgeWebview2Setup.exe`，失败则 `https://developer.microsoft.com/zh-cn/microsoft-edge/webview2/consumer/` |

`.exe` 抽取正则实测有 **4 条变体**（旧文只列 1 条），例如 `'(https?://[^\s<>"\'`]+?\.exe[^\s<>"\'`]*)'` 与 `'(https?://[^\s<>"\'`)]+?/[^\s<>"\'`)]*?\.exe[^\s<>"\'`]*)'`。

> **工具瑕疵披露**：上表 URL 是从 .pyc 里按可打印字节切出来的，我的正则贪婪跨了相邻常量，原始输出里个别串尾带了一个杂字符（`…Setup.exez`、`…copylinkc`）。表内已按语义清理，但**清理是人工判断**，故 URL 正文以 `C31` 的原始行为准。

**历史观察（本次未复核）**：三源在线实测（飞书 200/92,227 B 且 `.exe` 命中 0、含 13× `login`；硬编码直链 HTTP 200 但 `application/json` 86 B `object not found`；蓝奏云真实直链需 JS）记于 2026-09-18。**本轮不重做**：目标是厂商 C2、且本机 DNS 为 fake-IP，任何出网结果都不能当归属证据。⇒ 「通道已坏」保留为**历史观察**，不是本页的自证结论；代码侧能自证的只有"存在这些常量与解析逻辑、且失败分支返回 `need_manual_download`"。

## 1.7 安全发现（改写版）：两处 Session 显式关掉 TLS 校验

旧 §10.4 写成「`install_webview2` 以 `verify=False` 下载并立即静默执行」。**实质成立，机制与函数名都需更正**：

- **观察**：`main._wv2_download_bootstrapper`（源码行跨度 `598..682`）在函数内定义嵌套类 `_TLSAdapter(HTTPAdapter)`（`__firstlineno__ = 613`），其 `init_poolmanager` 逐条指令为：
  ```
  ctx = create_urllib3_context()
  ctx.minimum_version = ssl.TLSVersion.TLSv1_2
  ctx.check_hostname = False          ← 显式关闭主机名校验
  ctx.verify_mode    = ssl.CERT_NONE  ← 显式关闭证书校验
  kwargs['ssl_context'] = ctx ; super().init_poolmanager(**kwargs)
  ```
  随后 `Session()` + `mount(...)` 该 Adapter，再 `get(...)`、`raise_for_status()`、`iter_content` 写盘、`os.path.getsize` 校验、`rename`。
- **观察**：**同一形状出现两次**——`main._fetch_feishu_notice` 里也有 `TLSAdapter.init_poolmanager`（`__firstlineno__ = 3266`），四个属性写入完全相同。⇒ 受影响的是两条通道：WebView2 组件下载、飞书公告拉取。
- **观察（执行环节）**：`_update_webview2_silently`（行跨度 `719..787`）：`bootstrapper_path = os.path.join(tempfile.gettempdir(), bootstrapper_name)` → `_wv2_download_bootstrapper(bootstrapper_path)`；返回假则 `_wv2_open_browser_fallback()`；返回真则记 `'下载完成，开始静默安装...'` 后 **`subprocess.run(..., CREATE_NO_WINDOW)`** 执行该临时文件，检查 `result.returncode`，最后 `os.remove(bootstrapper_path)`。
- **推断（成立但需限定）**：在证书与主机名都不校验的会话上，链路上任意中间人可把 `MicrosoftEdgeWebview2Setup.exe` 换成任意字节并被**无交互执行** ⇒ 目标机上的免交互代码执行。默认前提下源站是微软 CDN，所以这不是"作者埋的后门"，而是**可被在网攻击者利用的缺陷**；两种解释的区分需要作者意图证据，静态给不出。
- **边界（必须一起读）**：结论只描述 V5.1 这份样本；未观测任何一次真实 TLS 握手（未联网）。

## 1.8 本页的作废清单与复核台账

作废／更正（旧编号 → 现状）：

1. 「UPX 头被篡改成 **SizeOfImage=0x6**」→ 错，实测 `0x5d000`；替换证据为 format 字节 `0x24` + trailer 缺失（§1.2）。
2. 「样本内**唯一**对卡密内容的实质判定在前端 JS」→ 错，`SplashScreen._on_confirm` 有独立的 `31–36` + 前缀判定（§1.4）。
3. 「install_webview2 以 **verify=False** 下载」→ 机制更正：挂载 Adapter 内设 `check_hostname=False`/`CERT_NONE`，且**两处**（公告拉取同样中招）；执行者是 `_update_webview2_silently`（§1.7）。
4. 「前端 30+ 处 `pywebview.api`」→ 精确化为 42 处 / 28 个方法（§1.3）。
5. 「本机 Python 是 3.14，无法加载 3.13 字节码」→ 现况 PATH 上即 3.13.15，本页多数断言因此从"转述"升级为"当场重测"（§1.2）。
6. 自查工具瑕疵两条，一并记：`C28` 用 `Instruction.starts_line` 聚合行号得出"只有 1 个行号"，与 `co_lines()` 的 207 个矛盾 ⇒ 以 `co_lines()` 为准（`C29`）；`C28` 的"硬编码 exe 直链存在"检查表达式写坏导致 FAIL，而 URL 其实已被同一脚本打印出来 ⇒ **检查器 FAIL 不等于文档错**，逐条回看原文才判。

| 主张 | 证据件／脚本 | 复核动作 | 结论 |
|---|---|---|---|
| 样本 54,382,515 B / SHA-256 / MD5 | `C31_p1_physical_facts.txt`，`<HOST_PATH>/vmctl/verify_p1_physical.py` | 读文件 + 哈希 | 观察 |
| PE 头与 3 节、SizeOfImage `0x5d000`、EP `0x55b40` | `C31` | 结构解析 | 观察（并据此作废旧"0x6"） |
| UPX 只有一处签名 `0x3e0`、尾部无 trailer | `C31` + 尾部扫描 | 字节搜索 | 观察 |
| `upx -d` 失败原文 | upx 5.2.1 实跑（`/tmp/upxtry`） | 只解包不执行 | 观察（成因仍**未决**） |
| 脱壳得 UPX0 188,456 B；重建件参数 | `<HOST_PATH>/EPT/unpack/ept_dump_base.bin`、`unpack/ept_clean.exe` | 非零字节统计 + 头解析 | 观察 |
| 内嵌 7 exe + 2 HTML 的尺寸 | 解包目录 `ls` | 逐个比对 | 观察（10/10 相同） |
| 本体全本地、无网络取用 | `C28` §7 常量清单 | marshal+dis | 观察 |
| 前端 42 处 pywebview.api / 1 条外链 | `C28` §8 | 计数 | 观察 |
| 卡密假通过（非空 → 宣布通过） | `C28` §2、`C29` (a) | 指令序列 + `co_lines` | 观察 |
| 两处真格式闸门 30–40 / 31–36+前缀 | `C28` §8–9 + `index.html` | 常量提取 | 观察 |
| Python 层零密码学引用 | `C28` §1（3 模块 349 个 code object） | 命名/常量普查 | 观察（范围＝这 3 个模块） |
| `-k/-n/-m` 与 `sleep(8)`、读弹窗回传 | `C28` §3–4 | 常量 + 文档串 | 观察；弹窗行为本身是**未决**（未运行） |
| TLS 校验被显式关闭（两处）+ 下载即执行 | `C30_webview2_download_disasm.txt`、`C30b_tls_adapter_disasm.txt` | 逐指令 dump | 观察；"可被 MITM"为**推断** |
| 三源"已坏" | 旧 §4，2026-09-18 | **本次未复核**（不联网） | 历史观察 |
| 飞书/直链/蓝奏/微软 各 URL 与 4 条 `.exe` 正则 | `C31` | 常量抽取 | 观察（URL 尾部有工具瑕疵，见 §1.6 注） |
| 宿主三件套 + `C:\R6-QZD` 不存在 | 只读 stat | 存在性检查 | 观察（2026-09-19） |

**本页未决**：① `header corrupted 3` 的确切成因；② "通道已坏"是否今天仍成立（需出网，本轮不做）；③ `run_decode_from_exe` 与 `run_decode` 的分工；④ `PasswordWindowDetector` 被谁调用（旧文未提）；⑤ `spoofer_tongsha/jianrong` ↔ 通杀版/兼容版 的对应关系（仍是拼音推断）。

下一篇：**P2 · 操作者视角 GUI 链路与版本差异**。
