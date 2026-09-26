# P2 · 操作者视角：多 UI 拼接、两前端规则、版本差异

> 全量重写版第 2 篇（原 §11–§13）。上一版是靠"渲染解包前端逐屏取证"写的，属于截图级证据；本篇把其中**每一个能在代码侧定位的计数都重跑了一遍**（`C32`、`C33`、`C33b`、`C34`），并把渲染观察与代码事实分开标注。
> 三态：**观察**／**推断**／**未决**。全部离线只读：`marshal`+`dis` 读 .pyc、文本检索读 `index.html`、哈希比对读 V5.0 对照件；**未执行样本、未联网**。

## 2.1 为什么操作者视角只能用渲染复现

**观察**：该样本会关 Defender、装伪装计划任务、改防火墙、清事件日志，并且（见 `P1§7`）在两条下载通道上显式关闭 TLS 校验。因此"跑一遍看界面"在真实工作站上不可接受；前端 `_pack_html/index.html` 是纯静态 HTML/JS，在浏览器里渲染是安全的——`pywebview` 不存在时页面会如实落到错误分支（`ReferenceError: pywebview is not defined`），反而把错误路径暴露出来。
**边界**：渲染取证得到的是"界面显示了什么"，不是"程序会做什么"。本篇凡有代码侧对应物的，一律以代码侧为准并注明。

## 2.2 八套 UI 层（存在性全部实测通过）

| # | 层 | 技术栈 | 职责 | 代码侧凭据（`C32`） |
|---|---|---|---|---|
| U1 | `SplashScreen` | tkinter | 环境状态行、飞书公告滚动、**卡密输入**、WebView2 缺失错误页、自绘标题栏 | 类与方法名命中 ✓ |
| U2 | `DisclaimerDialog` | tkinter | 同意/拒绝闸门 | ✓ |
| U3 | `DesktopWarningOverlay` | tkinter（独立线程，置顶+鼠标穿透） | 自动化期间"勿动"遮罩 | ✓ |
| U4 | 主界面 5 个"页面" | WebView2 + HTML/JS | 全部业务操作面 | **`create_window` 实测：宽 790、高 556、背景 `#010308`** ✓ |
| U5 | `cli_mode` | 控制台（自行分配） | GUI 的平行前端 | ✓ |
| U6 | 目标程序免责声明窗 | 第三方原生 Win32 | 被自动点同意 | `_detect_disclaimer_dialog` + `_auto_click_agree_button` ✓ |
| U7 | 目标程序密码输入窗 | 第三方原生 Win32 | 被自动定位并代填 | `PasswordWindowDetector` ✓ |
| U8 | 校验器"已绑定"弹窗 | 第三方 `#32770` | **唯一的服务端校验结果出口** | `_detect_bind_error_dialog` ✓ |

**观察（本轮新增，旧文没有）**：`index.html` 里 JS 调用的 `pywebview.api.*` **28 个方法名逐个都能在 `PyWebViewAPI` 里找到定义，无断链**；Python→JS 的 10 个推送函数（`addOptLog / addDecodeLog / updateOptProgress / updateTaskCount / updateDecodeProgress / updateDecodeStatusTag / updateDeployStatusTag / updateStatusText / addHoloWave / addSpotlight`）**在前端与字节码常量两侧都能对上**。

**接缝（结构层，与旧文一致）**：`U1 → _GLOBAL_CARD_KEY + card_key_ready` → `_check_startup_status` 50ms 轮询 → `quit` → **tkinter 拆除（`_default_root.quit/destroy` + `gc.collect` + `_win32_msg_queue_empty`（ctypes + `PeekMessageW`））** → `U4`。`run_decode_exec`(GUI) 与 `cli_mode._run_decode`(CLI) **汇入同一个 `DecodeEngine`**。

## 2.3 三套卡密规则互不对齐（本篇最要紧的一条）

**C122 只读字节码复核**：从原始样本 CArchive 的 `PYZ.pyz`（绝对文件偏移 `0x2d76d89`、长度 `6,637,778`、SHA-256=`14875591998f8c07b82f24c5c76f6eda8be40df720f925e88592fad0ab9dd89f`）对应的 `main.pyc` 中，`<module>.SplashScreen._on_confirm` 的 code object 首行 `2961`、字节码长度 `1154`；格式分支位于 code-object offset `0x01c6/0x01dc/0x0206/0x021a/0x02fa/0x030e`，通过路径从 `0x03d6` 写入 `_GLOBAL_CARD_KEY`，在 `0x03fc` 开始组装 `_confirm_callback(card_key)`（实际 `CALL` 位于 `0x0414`）。它只证明本地格式门禁，不证明外部 `Hardware.exe` 授权成功。详见 [`C122_ui_card_format_boundary_20260921.md`](../artifacts/evidence/C122_ui_card_format_boundary_20260921.md)。

| 层 | 位置 | 实测规则 | 严格度 |
|---|---|---|---|
| ① 启动窗闸门 | `main.SplashScreen._on_confirm` | `^[a-zA-Z0-9]{31,36}$` **且** `^(C\\|E(?!PT))`；文案 `'⚠ 卡密错误，验证失败！'` / `'⚠ 卡密输入有误！'` | 最严（唯一有前缀规则处） |
| ② CLI | `cli_mode` | `re.fullmatch(r'[A-Za-z0-9]{31,36}')`，帮助串 `-k <卡密> 解码卡密（31~36 位）`，错误串 `卡密格式错误（应为 31~36 位字母数字，当前长度 ` | **无前缀规则** |
| ③ 网页解码页 | `index.html` | `^[a-zA-Z0-9]{30,40}$` | 最松（30/40 越界、无前缀） |
| ④ 引擎 | `auto_decode.DecodeEngine.run_decode` | 仅 `TO_BOOL` 非空 | 形同虚设（`P1§4`） |

**观察**：①②③ 的常量都是字节码/HTML 里的字面量，实测逐字如上；CLI 侧 `EXIT_*` 常量集合实测含 `{0,1,2,4,130}`，并有 `ORDER_TO_KEY`（`-1~-8` 先于解码执行）。
**推断（旧文已述，方向不变）**：格式约束由各前端各自硬编码、后端不复核；**绕过①只要走③或走 CLI 即可**——同一份引擎被两个前端加了规则不一致的门禁，且只有 GUI 有免责闸门。

## 2.4 前端阶段计数的代码侧对照（这次不再只靠截图）

| 旧文断言 | 重跑结果 | 依据 |
|---|---|---|
| 解码流程"十步" | **观察**：`index.html` 内 `DECODE_STEPS = [ … ]` 恰好 **10 项**，`key/name/icon` 与旧文步骤名逐字相同（`card_verify 卡密验证` … `restart 完成重启`） | `C33` |
| 8 个优化项**默认全选** | **观察**：`TASKS = [ … ]` 恰好 **8 项**（`install_driver 装驱动 / fix_dx DX修复 / disable_update 关闭更新 / disable_antivirus 关闭杀毒 / remove_pe 删多余PE / disable_fast_boot 关快速启动 / other_optimize 其他优化 / activate_system 系统激活`），紧随其后的注释即「初始化任务卡片 + 默认全选」 | `C33b` |
| 解码页"6 组参数" | **观察（措辞需精确）**：5 个单选项带 `data-group`（`versionSelect / lineSelect / codeType / modeSelect / netBlock`）+ 1 个复选框 `chkSkipVT` ⇒ "6 组"= 5 radio + 1 checkbox | `C33` |
| `取消VT判断` 默认勾选 | **观察**：`<input type="checkbox" id="chkSkipVT" checked>` 是全文件**唯一**带 `checked` 的静态 input | `C32`/`C33` |
| 云下发默认"线路二" | **观察**：JS 状态里 `lineSelect: 'line2' // … 默认走线路二`，且带 `active` 的选项元素是 `line2` | `C33` |
| 「而代码兜底是 `get_download_url(line_select='line1')`」 | **未决**：`get_download_url` 的常量里确有 `'line1','line2'`，但我没取到它的默认参数元组（`run_decode` 里那个 `('line1','line2')` 是成员判定用的，不是默认值）。旧文这句**本轮未复现**。最小检查：在 `get_download_url` 的**父** code object 里找 `MAKE_FUNCTION` 前的默认值元组 | — |
| 第 3 步（获取链接）就会中断 | **依赖 `P1§6` 的"通道已坏"**，那是 2026-09-18 的历史观察（本轮不联网） ⇒ 整条"人工介入一次"的结论仍是**历史观察**，不是本页自证 | — |

## 2.5 壳怎么处理核心的控制台输出（结构要点，全部实测）

`auto_decode._call_spoofer_commandline` 的字节码：
- **观察**：`co_names` 含 `CREATE_NO_WINDOW` 与 `PIPE` ⇒ 核心（控制台程序）被以**隐藏控制台**方式起、stdout/stderr 被捕获。
- **观察**：日志常量只有 `'stdout_len='`、`'stderr_len='` ⇒ **只量长度，从不解析内容**；`sleep(8)` + `poll()` 形态成立。
- **观察**：文档串自述「新版解码核心：直接命令行调用 Hardware.exe，无需UI自动化」「调用格式: `Hardware.exe -k <卡密> -n <序列模式> -m <解码模式>`」，并记录了 v1.33 从 `communicate(timeout=60)` 改为非阻塞的原因——核心弹"已绑定"MessageBox 时会卡住不退出。
- **观察（旧文未列的 `_tc_*` 族全名）**：`_tc_nic_registry / _tc_firewall_rules / _tc_prefetch / _tc_wer / _tc_explorer_traces / _tc_own_temp / _tc_event_logs / _tc_files`。核心侧的两个日志路径常量（`SysWOW64\JW.txt`、`SysWOW64\EPTHWID.txt`）**只被 `_tc_files` 引用** ⇒ 壳对核心日志的唯一兴趣是删掉它。

**推断（保持旧判读，理由不变）**：壳与核心之间唯一的实际通信通道是 GUI 弹窗文本（`#32770` + `Static` 子控件），不是 stdout。**对核心做动态分析的正确接法**是自己在控制台跑 `Hardware.exe -k … -n … -m …` 看它的 stdout/stderr，而不是像壳那样只刮窗口。

## 2.6 GUI 侧对防火墙操作的系统性隐藏（词表实测 23 项）

**观察**：`PyWebViewAPI._is_firewall_related` 的词表是一个 **23 项 tuple**（逐字）：`防火墙, 墙策略, 墙设置, 墙规则, 墙配, 墙已, 墙+ , 墙- , 清理墙, 配置墙, 系统墙, 开启墙, 启用墙, 禁用墙, 强制开, 强制关, 阻止.*联, 禁止.*联, firewall, Firewall, FIREWALL, advfirewall, SpooferNetworkBlock`；函数体只有 `lower` / `re.search` 三个名字，指令 35 条。文档串自述："判断日志是否与墙操作相关（含'墙'隐蔽代称的所有变体）"。
**观察**：全模块里引用该函数的只有 `PyWebViewAPI`（`_log_to_frontend`）与 `PyWebViewAPI._log_to_decode_frontend`；`cli_mode` 的**任何** code object 都不引用它 ⇒ 「防火墙/联网阻断操作在 GUI 日志面板被过滤，在 CLI 与日志文件里照常输出」成立。
**推断**：这是刻意让**操作者本人**看不到该行为。（判据：词表里 18 个中文"墙"代称 + 伪装关键字 `SpooferNetworkBlock`；过滤点只挑两条前端日志通道。）

## 2.7 持久化伪装与"解码成功"的本地判据

**观察（常量级，全部命中）**：`MicrosoftEdgeUpdateTask`、GUID `C859613A-B3EF-4E7D-8A9D-6FCA0CD619A6`、伪装 `Author='Microsoft Corporation'`、`Description='Microsoft Edge 更新任务'`、`RunLevel='HighestAvailable'`、`PT0S`、`LogonTrigger`。
**结构判读（与旧文一致）**：`check_decode_status()` 的 `decoded` = 核心 exe 存在、`deployed` = `_check_auto_start()` 命中（`schtasks` + `HKCU/HKLM Run` + 启动文件夹，关键字 `MicrosoftEdgeUpdate`）。⇒ **"解码成功"与"重启后自动生效"是同一套本地可写状态的两个观测面**，没有任何服务端回执参与；让客户端显示成功的最小充分条件就是"文件在 + 计划任务在"。

## 2.8 V5.0 ↔ V5.1 差异（用对照件重跑，含两处更正）

对照件在档：`<HOST_PATH>/CTF/_reference/EPT/v5.0_sample/EPTv5_from_r14_vm.exe`（54,753,806 B）及其解包目录。重跑（`C34`）：

| 项 | 实测 | 与旧文 |
|---|---|---|
| 两侧文件数 | V5.1 = 1,998；V5.0 = 2,029；**仅 V5.0 多 31 个文件，全是 `PYZ.pyz_extracted/tkinter/*`** | ✓（旧文"5.0 多出 tkinter/ 目录"，现补精确数 31） |
| 共有文件 | **1,995 个逐字节相同**；**3 个不同**：`auto_decode.pyc`（205,671 → 208,484）、`PYZ.pyz`、`base_library.zip` | ✳ **更正**：旧文只列 `auto_decode.pyc`。`PYZ.pyz` 是容器（内含前者，自然变）；但 **`base_library.zip` 同尺寸（1,409,329）不同哈希**，旧文漏报——属打包产物差异，非逻辑变更 |
| `main.pyc` / `index.html` / `_pack_tools/*` | 逐字节相同（`main.pyc 212,654`、`index.html 208,386`、`DrvCeo.exe 26,195,121`、`EPTHWID.exe 16,896` 均命中） | ✓ ⇒ §11/2.4 的 GUI 链路**同时适用于两版** |
| `auto_decode.pyc` 归一化逐函数比对 | 仅 5.1 新增 3 个 code object：`_parse_feishu_links._in_a_tag`、`._in_href`、`._in_href.<genexpr>`；删除 0 个；指纹不同 3 个：`_parse_feishu_links` 与 **纯行号平移**的 `PasswordWindowDetector`、`._RECT`（后两者指令数/行数/名量全同，仅跨度 `2397..2783 → 2448..2834`、`2428..2433 → 2479..2484`） | ✓ 大结论成立；✳ **数字更正**：`_parse_feishu_links` 实测 **指令 1054→1319（+265）、有行号行数 199→236（+37）**，旧文写的"源码行 157→188 (+31)"**不可复现**；另外旧文的"仅行号平移"名单含 `_find_desktop_decoder_exe`，实测它指纹与行号都未变，应从该名单去掉 |

**方法要点（保留）**：比对代码对象必须先归一化——抹掉 repr 里的内存地址与行号，否则一次重编译就会造出几十个"假变化"（旧轮踩过，28 个）。
**判读（推断，与旧文同）**：从 5.0 到 5.1 的唯一实质改动集中在**云端下发链接的解析器**（升级为锚点感知的"页面可见链接"提取：用 `<a>` 扫描维护开标签位置、`href=` 取锚点、URL 字符集额外排除 `)`，并把旧的全局刮取降级为兜底——兜底日志串实测为 ` 个候选.exe链接（旧全局去重，仅供兑底用）`）。卡密链、`_call_spoofer_commandline`、`_detect_bind_error_dialog`、`check_decode_status`、前端 UI **全部逐字节未变** ⇒ **版本对比不泄露校验算法**，但坐实了该系统的变更热点与薄弱点都在那条下发链上。

## 2.9 本页作废／更正清单

1. 「除 `auto_decode.pyc` 外全部逐字节相同」→ 实为"**共有文件 1,995 相同、3 不同**"，另两个是 `PYZ.pyz`（容器）与 **`base_library.zip`（同尺寸不同哈希，旧文漏报）**。
2. 「`_parse_feishu_links` 源码行 157→188 (+31)」→ 不可复现；实测 +265 指令 / +37 有行号行数（`C34`）。
3. 「仅行号平移：`_find_desktop_decoder_exe` / `PasswordWindowDetector` / `._RECT`」→ 实测平移只有后两个。
4. 「代码兜底 `get_download_url(line_select='line1')`」→ 本轮未复现，降级为**未决**（附最小检查）。
5. 「6 组参数」→ 精确化为"5 个 `data-group` 单选组 + 1 个复选框"。

**未决（本页遗留）**：① `get_download_url` 默认参数；② 十步里第 3 步失败是否今天仍成立（需出网，本轮禁止）；③ `base_library.zip` 差异是否只是 zip mtime（可离线判定：解 zip 比内层）；④ `V5.0 的 tkinter/ 目录为何只在 5.0 出现`（打包脚本差异，未查）。

| 主张 | 证据件 | 复核动作 | 结论 |
|---|---|---|---|
| 8 套 UI 层存在、U4 窗口参数 790×556×`#010308` | `C32_p2_ui_ledger.txt` | marshal 命名/常量检索 | 观察 |
| 28 个 api 方法无断链、10 个推送函数两侧对齐 | `C32` | 交叉比对 | 观察 |
| 三套卡密规则 31–36+前缀 / 31–36 / 30–40 | `C32` §D | 字面量提取 | 观察 |
| CLI 退出码 0/1/2/4/130、`ORDER_TO_KEY` | `C32` §D | 常量 | 观察 |
| 核心 stdout 只量长度、`CREATE_NO_WINDOW`、`_tc_files` 独占核心日志 | `C32` §F | co_names + 常量 | 观察 |
| 防火墙词表 23 项、只有两个引用者 | `C32`/`C32b` | tuple 常量 + 引用者枚举 | 观察 |
| 伪装计划任务常量 | `C32` §G | 常量 | 观察 |
| 十步 / 八项默认全选 / 线路二默认 / `chkSkipVT` 唯一默认勾选 | `C33`、`C33b` | 前端数组计数 | 观察 |
| V5.0↔V5.1 差异集合与逐函数变更 | `C34` | 哈希 + 归一化 code object 比对 | 观察（含上列 3 处更正） |

下一篇：**P3 · 靶机受控动态与行为模型**。
