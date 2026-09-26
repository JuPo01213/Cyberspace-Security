# 5.1 工具箱本地解码核心：边界综合（C79）

生成时间：`2026-09-21T02:17:10+00:00`。本件是对已经完成的静态分析和有界动态实验的综合，不启动样本、不联网、不等待新的 VM 通信结果。

## 结论

当前状态：**`INCOMPLETE / VALID_UNOBSERVABLE_ON_THIS_BASE`**。

这不是“本地解码核心已完成”。目前能够证实的是：`-n/-m` 在 `Hardware.genB.exe` 的明文恢复区进入参数解析；`0x14078ce60` 是一个可离线重放的 `0x10c` 字节原地变换；`RC00` 位置会把这块缓冲区送入一个保护运行时目标 `0x141757acd`。在只替换授权前置条件、恢复已捕获 `.text` 的直接入口实验中，程序在更深的 `.Sq>` 运行时 `0x1415d0f52` 发生访问冲突，未得到 RC00 返回值、最终输出缓冲区或本地解码副作用。

因此，前面关于授权、联网、外层调度器和分支阻断的证据，只能作为**入口排除和边界证据**；不能再被记作“核心解码分析完成”。

## 范围与输入对象

- 目标：`<HOST_PATH>\vmctl\out\Hardware.genB.exe`，SHA-256 `cfa6998ecc2fba92b027985c5283b09cd9c04c636158fd6961a10560afb28bd7`；guest 中 `C:\ept_core\Hardware.exe` 的哈希与其一致。
- 明文恢复窗口：`artifacts/captures/stream_C6/stream_text.bin`，大小 `8257536` bytes，SHA-256 `5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`，映射基址 `0x140000000`。
- 明确排除：`auto_decode.pyc`、GUI/下载器、`StoredVerify.*`、卡密与联网协议、支持请求、`final_status`、驱动缺失造成的猜测，以及无阶段标志的长等待。
- 动态护栏：本轮 NIC 已断开；实验只在 VM 内；没有连接 `yz.hwid001.com`；每个动态入口均有短墙钟上限。

## 已闭合的局部事实

### 参数入口不是解码本体

`C72`/`C75` 确认：`-n` 写入参数槽并置位，`-m` 写入另一参数槽并置位；CFG 追踪没有得到从这两个解析点到 RC00、RC03 或 `0x14078ce60` 的直接静态边。这说明它们是本地处理分支的输入选择，不足以证明“参数解析后就是解码”。

### `0x14078ce60` 是可复现的局部变换

该函数无内部 CALL，按恢复指令使用三个全局 dword、四个表项以及 `0x7feb352d`、`0x846ca68b` 两个混合常数，对长度 `0x10c` 的输入逐字节原地异或。离线 harness 是 `<HOST_PATH>\vmctl\local_transform_harness.py`，没有样本、网络、授权、注册表、设备或驱动依赖。

本次 self-test：输入/输出均 `268` bytes；输入 SHA-256 `7f28e601d3aec2fc26036a7feadc99a732c9715422c1055cad941befa7f1b843`；输出 SHA-256 `8e3327d21fcc3b65e97b2f103215e2da83ee5a3eac664e81279d24e45580720e`；耗时 `0.0 ms`。这只证明字节级变换复现，**没有证明方向是 encode 还是 decode，也没有证明它是最终业务解码器**。`C73` 已将它明确降级为 `local_transform_candidate`。

### RC00/RC03 是候选接缝，不是已确认核心入口

`C71` 给出的明文位置关系是：RC00 在 `0x14078ed39` 构造并传递 `0x10c` 缓冲区，随后调用 `0x14078ce60`、`0x14078d900` 和保护目标 `0x141757acd`；RC03 在 `0x14078ee89` 调用 `0x14078db80` 并以返回值决定 `decode_failed`。恢复区中没有可靠的直接 caller 边，符合 VMProtect 间接调度/运行时解密的形态，但不能据此补出缺失的调用契约。

## 有界动态实验结果

### 直接入口实验

`<HOST_PATH>\vmctl\debug_core_call.ps1` 只做了三类替换：将已捕获明文恢复到 `0x140000000`、把授权门的返回改为成功、从远程 stub 调用恢复出的 `main=0x1407a4b90`，没有改写 `0x14078ce60` 的算法，也没有配置 endpoint。

关键观测：

```text
phase=restore_plaintext bytes=8257536 sha256=5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757 written=8257536 ok=True
phase=bypass_auth_gate address=0x1407a3080 ok=True written=6
phase=jump_direct_main main=0x1407a4b90 ... ok=True
phase=fault code=0xc0000005 address=0x1415d0f52
phase=timeout no_rc00_callsite_hit
```

这把“授权闸门未过”与“核心路径已返回”区分开了：前置条件替换成功，但在保护运行时链上先发生 fault；本次没有 RC00 命中、返回寄存器、输出 buffer、文件、注册表、设备调用或进程自然退出结果。

### 运行时页面只证明“存在”，不证明“语义”

普通有界探针观察到 `0x1415d0000` 等 `.Sq>` 页面在约秒级运行中从零页变为非零页；`fault_1415d0f52_3.bin` 是其中一页的 4096-byte 捕获。它证明运行时确实会生成/解密受保护页面，但未证明该页的函数语义，也未证明它已经执行了本地解码。调试器预热实验在 2.2 秒窗口内仍未得到相同页面，故不把两种观测强行拼接成“已执行”。

## 输入—变换—输出—副作用矩阵

| 环节 | 已证实输入 | 已证实变换/调用 | 已证实输出 | 状态 |
|---|---|---|---|---|
| 参数解析 | `-n`、`-m` | 写参数槽并置位 | 内存中的选项状态 | 观察 |
| 局部变换 | `0x10c` bytes + 明确 seed/table | `0x14078ce60` 原地 XOR 流 | `0x10c` bytes | 已复现；角色未定 |
| RC00 接缝 | RC00 栈上 `0x10c` buffer、`0x11c` 长度形态 | `0x14078ce60` → `0x14078d900` → `0x141757acd` 候选链 | 未取得 | 未决 |
| 保护运行时 | `.Sq>` 运行时页 | 间接/虚拟化代码，直接入口在 `0x1415d0f52` fault | 未取得 | 未决 |
| 本地副作用 | 当前实验的探针日志和内存页 | 仅观察到实验自身写日志/内存 | 未观察到业务文件/注册表/设备结果 | 未决，不作“没有” |

## 用户态与驱动边界

当前工作区没有 `HP_WKS_SWTOOLS_DRIVER.sys` 或样本配套 `.sys` 字节；只有驱动名称字符串。因此不能判断 `0x141757acd` 之后哪些工作属于用户态、哪些需要驱动，也不能把驱动缺失解释成“核心没有驱动”。该项保持真实未决。

## 交付物与复现

- 局部变换 harness：`<HOST_PATH>\vmctl\local_transform_harness.py`。
- 有界直接入口实验：`<HOST_PATH>\vmctl\debug_core_call.ps1`。
- 静态候选链：`C71`、`C72`、`C73`、`C74`、`C75`。
- 运行时页面与调用页：`C77`、`C78`，以及 `artifacts/captures/core_debug_probe/` 中的日志和 4 KiB 页面。

离线局部 harness 的合理预算是 1 秒；本轮 VM 调试入口预算为 8 秒，普通运行时探针约 7–10 秒。出现阶段无进展时应停止并检查证据，不得把 16 分钟或旧脚本的固定时长当作“核心解码耗时”。

## 完成门禁

以下条件仍未满足，所以不能标记“本地解码核心分析完成”：

1. 没有确认 `RC00` 之后的真实调用契约和返回值；
2. 没有获得最终本地输出 buffer 或可归因的文件/注册表/设备副作用；
3. 没有闭合 `RC03 decode_failed` 的真实产生条件；
4. 没有确认用户态与驱动/辅助组件边界；
5. 保护运行时所需的 `.Sq>` 字节和驱动字节不完整，当前基线无法继续把 fault 解释成解码语义。

下一次有价值的工作只能是补齐上述缺失依赖，或在新的可观测基线上完成运行时解密/反虚拟化；重复启动旧外层脚本、等待 TCP、重跑相同 GUI/SSH 通信不会提高核心结论强度。

## 证据文件校验

- `C71`：85313 bytes，SHA-256 `ec260fe1fab93ad3bc3ef02edef9852bae0659a254d1a2046a2434e3c827e70d`
- `C72`：61727 bytes，SHA-256 `0f9b046461d4d602a3f4387149468fa32b989279c102b432ded19f7a112221af`
- `C73`：21287 bytes，SHA-256 `1eaac36e235d76ff05101e6d12e027eeb6f76fd7a0370686ea4d7e96afde2fd1`
- `C75`：29672 bytes，SHA-256 `87c7ba68bcdf149f1076d815b22de3fbaa09080685eb5aaa6b5e3625c3ffad8f`
- `C76`：772 bytes，SHA-256 `57c0465ccec5ef2fd72eb3643268a0cb01fe6a57eb0c9a3139c26d12c58a09f7`
- `C77`：5624 bytes，SHA-256 `2fbde858443eb7519428295fddd31c77e4f7c20ff3260c440f160ac1ecc204bf`
- `C78`：26763 bytes，SHA-256 `d09a038bb83c2e0de468f55dfcc5d77f061c98a8d8fa392a18792a591152b1a4`
- `direct-main log`：874 bytes，SHA-256 `d71f78863d2dea3c70b8152acce04a61be27e17379043a510ae8bfe3c8f84519`
- `warmup log`：1172 bytes，SHA-256 `86975546fa703bb93318df72bf218013510c2c07c0c11dceeb1a9cf83e591d69`
- `runtime page`：4096 bytes，SHA-256 `e2f0807847e6b71eeadf72a7076dd485b3c2316e2bc8bb2a2330c667b25e9041`
