# P6 · 5.1 工具箱本地解码核心

本篇是当前核心目标的权威收口。它不把授权、联网、`auto_decode.pyc`、GUI 或 `final_status` 当作解码结果，也不把旧的外层行为模型升级成核心完成。

## 当前结论

`Hardware.genB.exe` 的**局部用户态参考链**可按证据分层记为 `PARTIAL / USER_MODE_DECODER_REFERENCE`：本地变换、请求构造、response validator、marker 分支和 RC06 写回动作已由离线参考与受控 native seam 部分解释；但这不是自然目标进程完成。项目总体仍为 `INCOMPLETE / REAL_SAMPLE_POST_DECODE_BEHAVIOR_UNOBSERVED`：真实目标进程中的 response 来源、自然 `-n/-m` 到 caller 的完整链、RC06 后消费者以及驱动/辅助组件和伪装行为仍未取得。任何局部 `RC06 success` 都不能合并成“真实授权成功”。

- C121 提供离线 Python 参考入口 [`core_local_decoder_reference.py`](../method/harnesses/core_local_decoder_reference.py)：将 268-byte 输入、284-byte response-shaped fixture、RC03 validator、`g340` marker 比较和 RC06 第二次变换串成单命令；自测覆盖参考模型的 `RC06 success`、`RC03 decode_failed`、`RC04 session_mismatch`。C120 的受控 native trace 与 C121 对 normalized fixture 的结果一致：输出 SHA=`4836808424621ee58d80b558898d8ed2eb1227eb51e14c7f0036c072dad93bdd`，与 fixture 输入逐字节相等。这只证明 `offline_reference_synthetic_response` 的内部一致性，不证明自然目标解码。详见 [`C121_pure_python_local_decoder_closure_20260921.md`](../artifacts/evidence/C121_pure_python_local_decoder_closure_20260921.md)。
- rdata 中已定位 `-n/-m` 字符串、静态 caller seam 及其 mode/serialMode 契约，但实际解析函数到 caller 的连接仍未闭合；
- `0x14078ce60` 的 `0x10c` 字节原地变换已被离线 harness 精确复现，但其方向和业务角色未证实；
- RC00 会把这类缓冲区送入 `0x141757acd` 保护运行时候选链，RC03 的 `decode_failed` 仍只有候选静态位置；
- 只替换授权前置条件并恢复已捕获 `.text` 后，C82 的完整 `.Sq>` 快照重放在 `0x14169910f` 的 `ret 8` 处因非规范返回地址访问冲突；未得到 RC00 返回值、最终输出或本地副作用；
- C83/C84 改用原生启动、只替换授权闸门并在启动前布置 `main`/RC00 断点；两次 20 秒窗口都未命中 `main`，进度现场在不同运行间变化，C84 的句柄探针返回错误 6，不能判为解码失败；
- `.Sq>` 页面在普通有界探针中会运行时生成/解密，但页面出现不等于已理解其函数语义；配套驱动字节缺失，用户态/驱动边界仍未决。
- C90 在隔离 caller seam 中实际命中 `0x14078ce60`、`0x14078cd70` 和 `0x14078d900`；当前固化 harness 逐字节复现 0x10c 变换输出与 16 字节状态输出。该 seam 证明了本地中间计算，不证明最终业务解码完成。
- C91 在同一有界 seam 中继续命中 `0x141757acd`：两条短臂均在约 0.7–1.6 秒内到达，`R8` 指向 0x11c caller buffer；空 session/control synthetic 前提下，目标返回后该缓冲区逐字节不变，caller 返回 `RAX=0`。这确认了本地 helper 链与捕获范围外辅助/设备候选边界的实际分界，但不把空句柄返回解释成业务解码失败或成功。
- C92 把 C91 的 0x11c caller buffer 拆成已证实的数据流：前 16 bytes 等于 `0x14078d900` 的 state 输出，后 268 bytes 等于 `0x14078ce60` 的 transform 输出；`0x14078db80` 对同一 buffer 的离线原函数复现返回 `RAX=1`，全零负对照返回 `RAX=0`。RC00 的目标调用形状与 `DeviceIoControl` 类 8 参数 in/out ABI 相似，但目标仍只能称为保护运行时/设备辅助边界候选，未确认具体 API。
- C93 在同一短 direct caller seam 上对系统 API 布置断点，实际命中 `kernel32!DeviceIoControl → kernelbase!DeviceIoControl → ntdll!NtDeviceIoControlFile`；参数为 `handle=0`、`control=0`、同一 0x11c 输入/输出 buffer，返回长度为 0，buffer 不变。由此 `0x141757acd` 已确认是设备 I/O 包装边界，不是已恢复用户态中的最终业务 decoder；有效句柄、IOCTL 和驱动返回仍未取得。
- C101 对 `<HOST_PATH>\HexPatch\reference\ept-runtime-driver` 做了身份排除：参考镜像的 PE/入口/设备名与 genB 不同，且参考镜像没有 `HP_WKS_SWTOOLS_DRIVER`；`HexPatchCoreDiag` 是取证辅助驱动。该目录只能作为取证方法参考，不能作为 genB 的目标驱动或解码算法证据。
- C102 对 C6 重建视图中的 `0x1407890d0` 做了逐条核验：它把 `\\.\HP_WKS_SWTOOLS_DRIVER` 写入通信对象并调用 `0x140788f00`，说明这里是用户态设备对象初始化，不是最终解码；`C6_multi.exe` 也只有一个有效外层 x64 PE 候选。
- C103 清点了历史运行材料的 24 个 blob：目标设备名及 UTF-16 变体均为 0 命中，`driver_injected_*.bin` 均为 0 字节；现有 PE blob 全部属于已识别的 `edrv` runtime-driver 参考族，未发现可替代 genB 目标驱动的字节。
- C104 将 `0x14078ce60`、嵌入的 `0x14078cd70` 和 `0x14078d900` 从机器码转成无依赖的 32 位算术参考实现，并以 C90 seam、全零和递增字节三组输入与原生 genB `.text` 逐字段交叉复现。该结果闭合了设备前 268-byte 变换、67 轮摘要和 16-byte 状态构造的算法层，但仍不等于最终业务解码。
- C105 继续追到 RC03 成功分支：validator 与 `g340` marker 通过后，`0x14078ef42` 再次调用 `0x14078ce60`，并把 268-byte 结果复制到 caller structure `+0x80`。新的 `core_local_decode_harness.py` 直接对 0x11c response 执行该用户态解码 seam；C90 synthetic response 的第二次变换还原出原始 268 bytes，输出 SHA 与输入完全一致。

完整证据综合见 [`C79_local_decoder_core_synthesis_20260921.md`](../artifacts/evidence/C79_local_decoder_core_synthesis_20260921.md)；受控 attach、完整运行时 `.Sq>` 和原生启动边界分别见 [`C80`](../artifacts/evidence/C80_postlaunch_attach_boundary_20260921.md)、[`C81`](../artifacts/evidence/C81_runtime_sq_range_analysis_20260921.md)、[`C82`](../artifacts/evidence/C82_sq_runtime_replay_fault_20260921.md)、[`C83`](../artifacts/evidence/C83_native_startup_wait_boundary_20260921.md)、[`C84`](../artifacts/evidence/C84_native_progress_probe_variance_20260921.md)。

C85 进一步修正了 RC00 的入口解释：`0x14078ed39` 是 `.pdata` 切分后的 continuation，不是可独立调用的函数入口。前一段在 `0x14078ed36` 以 `xor r9d,r9d` 直接落入该地址；随后代码从 `[r14]` 复制 `0x10c` 字节到栈缓冲，经 `0x14078ce60` 原地变换，再由 `0x14078d900` 构造 16 字节状态，最后把这些参数交给捕获范围外的 `0x141757acd`。这闭合了本地调用契约，但没有闭合最终 decoder、驱动边界或业务输出。详见 [`C85`](../artifacts/evidence/C85_rc00_split_continuation_contract_20260921.md)。

C86 在干净客体中核对了驱动边界：`C:\ept_core\Hardware.exe` 与宿主候选一致，但 `C:\Windows\System32\drivers\HP_WKS_SWTOOLS_DRIVER.sys` 和对应 `SWTOOLS/HP_WKS/EPT/Hardware` 服务均不存在。这个结果只证明静态驱动字节不在干净基线；它不证明运行时不会释放或映射驱动，因此 `0x141757acd` 之后仍是未决边界。详见 [`C86`](../artifacts/evidence/C86_guest_driver_inventory_20260921.md)。

C87 又扫描了打包样本自身：441 个 `MZ` 只是散布字节，只有外层镜像的 `e_lfanew` 指向有效 `PE\0\0`；目标驱动名和 `SWTOOLS` 字符串在打包文件中均为 0 命中。因此当前缺失项更像运行时/不透明 payload 边界，而不是漏提取一个明文内嵌驱动。详见 [`C87`](../artifacts/evidence/C87_sample_embedded_driver_scan_20260921.md)。

C88 在断网条件下直接运行候选核心 20 秒：进程保持存活，但目标驱动路径和驱动目录新增 `.sys` 均未出现。它排除了“短窗口内直接落盘驱动”这一解释，但不排除内存映射、其他路径或更晚加载；因此仍不能闭合 `0x141757acd` 后的用户态/驱动边界。详见 [`C88`](../artifacts/evidence/C88_driver_release_probe_20260921.md)。

C89 在原生启动的首个 loader 断点处新增了两个直接对应本地阶段的入口观测：`0x14078ce60`（0x10c 字节原地变换）和 `0x14078d900`（16 字节状态构造）。两处断点、main 和 RC00 均写入成功，但 10 秒内仍只到达镜像外的进度现场，四个目标均未命中，因此没有取得真实 helper 输入/输出。这个结果把边界收窄为“普通原生启动尚未到本地 helper”，不是“本地 helper 已执行但解码失败”；同一路径不再延长等待。详见 [`C89`](../artifacts/evidence/C89_native_local_helper_boundary_20260921.md)。

C90 改用已定位的 `0x14078f060` 本地 caller seam，首次取得了真实 helper 输入/输出。`0x14078ce60` 接收 caller-local 的 0x10c 字节结构并原地变换；随后 `0x14078d900` 调用 `0x14078cd70` 对变换后连续 0x10c 字节求摘要，再写出 16 字节状态。动态输出与当前固化的 [`core_predevice_harness.py`](../method/harnesses/core_predevice_harness.py) 逐字节一致。C90 同时撤回了此前把 hash 输入解释成 402 字节的错误：`0x14078cd70` 的一次性 `add r9,2` 在循环前，回跳目标落在后续 `movzx`，每轮实际前进四字节。C90 仍停在 `0x141757acd` 之前，未取得最终业务输出或驱动副作用。详见 [`C90`](../artifacts/evidence/C90_local_helper_chain_exact_reproduction_20260921.md)。

C91 在 C90 的 caller seam 上只增加一个边界观测：恢复完整运行时 `.Sq>` 页，在 RC00 callsite 命中后于 `0x141757acd` 入口立即断下，并在直接 caller 返回点读取同一 0x11c 缓冲区。入口和返回快照 SHA-256 相同、差异字节为 0；`RCX/RDX` 为本 seam 显式合成的空 session/control 值，故该结果只能说明“空前置下目标未改写 buffer”，不能外推有效设备会话的业务结果。详见 [`C91`](../artifacts/evidence/C91_post_target_boundary_and_buffer_20260921.md)。

C92 在不启动样本的离线环境中对 RC03 validator 做了原始字节复现，并将 C91 buffer 与两个 helper 输出逐段比对。结果闭合了“本地请求/状态构造 + 响应完整性校验”边界，但没有得到最终业务明文或设备副作用；详见 [`C92`](../artifacts/evidence/C92_local_request_and_response_validator_20260921.md)。

C93 在同一 8 秒 direct caller seam 上确认 `0x141757acd` 实际进入 Windows 设备 I/O 链。由于本轮使用空 session/control synthetic 前提，API 收到的是空句柄和零控制码，不能把返回 0 写成业务失败；但“用户态 helper → DeviceIoControl → ntdll → caller”边界已不再是假设。详见 [`C93`](../artifacts/evidence/C93_device_io_boundary_confirmed_20260921.md)。

C94 在同一 seam 上只替换 RC00 callsite 继续执行前的 RCX/RDX，合成 `session=0x1234`、`control=0x222000` 被目标入口、`kernel32!DeviceIoControl`、`kernelbase!DeviceIoControl` 和 `ntdll!NtDeviceIoControlFile` 依次观察到；无效句柄导致 buffer 不变、返回长度为 0。由此确认参数传播，不把合成 I/O 的异常或 `RAX=0` 解释成业务解码失败。另在全量数据区中确认设备路径与 helper 字符串，修正了“静态范围内完全没有设备词汇”的过宽表述。详见 [`C94`](../artifacts/evidence/C94_synthetic_device_args_propagation_20260921.md)。

## 核心调用边界

```text
-n / -m 参数解析
        │
        ├─ 已知：写入选项槽并置位
        └─ 未知：没有可靠直接 CFG 边通向最终核心

RC00 候选位置
        │  0x10c-byte buffer
        ├─ 0x14078ce60  局部原地变换（动态+离线逐字节复现）
        ├─ 0x14078cd70  对变换后 0x10c 字节求摘要（动态返回已捕获）
        ├─ 0x14078d900  16 字节状态构造（动态+离线逐字节复现）
        └─ 0x141757acd  设备 I/O 包装边界（C93/C94 实际命中 DeviceIoControl 链）
                         │
                         ├─ C93：空 session/control seam，buffer 原样返回，caller RAX=0
                         ├─ C94：合成 session/control 到达 ntdll，因无效句柄无设备输出
                         └─ 有效 session/IOCTL 下的驱动返回与业务语义仍未决

RC03 候选位置
        └─ 0x14078db80 返回值 → decode_failed 文案
           真实输入、返回契约和输出仍未取到
```

其中 RC00 的 `0x14078ed39` 只能作为逻辑块中的 continuation 观察点，不能直接作为 harness 入口；直接跳转会丢失前置寄存器和调用者栈语义。

这张图是“已证实边界 + 未决连接”，不是把保护运行时的线性反汇编当作已经恢复的业务 CFG。

## 输入、变换、输出与副作用

当前固化的独立研究入口是 [`core_predevice_harness.py`](../method/harnesses/core_predevice_harness.py)。它在一个固定地址映射已核验的 genB `.text` 和最小数据捕获后，重放 `0x14078ce60`、`0x14078d900`、`0x14078db80`；接受明确的 `0x10c` 字节和六个 synthetic 全局 dword，并输出变换结果、16-byte state、0x11c request/response buffer、validator 返回值和耗时。它不联网、不访问授权、注册表、设备或驱动；这些阶段是请求侧中间计算与本地响应/状态校验，不是已证实的最终业务 decoder。C90/C92 中的旧 `<HOST_PATH>\vmctl` 文件名只保留为历史执行记录，当前可复现入口以 C99 为准。

C90 的合成输入不是自然业务密文：caller-local 结构的 mode 为 2，字符串为 `local_probe`，serial byte 为 1；六个状态 dword 也由 seam 显式设置。因此 harness 的价值是精确固定变换算法和输入/输出契约，而不是把 synthetic 结果伪装成自然解码结果。

`debug_core_call.ps1` 是另一个有界研究接缝：C82 模式恢复已有明文窗口、替换授权门返回、写回完整运行时 `.Sq>` 页面并调用恢复出的 `main=0x1407a4b90`，实际结果是 `ret 8` fault，而不是解码成功。C83 模式不写回 `.Sq>`、不伪造 `main`，从原生启动流程观察；实际结果是在样本镜像外等待且没有命中 `main`。C90/C91 模式则直接调用已定位 caller，在 8 秒内取得 helper 结果并命中 post-target 边界；仍未取得有效 session 下的最终业务输出。

## 排除项与未决项

以下内容仍然只作为排除项保留：网络连接、DNS、服务端协议、支持请求、卡密/绑定、`StoredVerify.*`、GUI 下载、外层 `completed`/`final_status`，以及 16 分钟一类没有业务阶段进展的等待。

真正继续核心分析前，必须补齐至少一个关键缺口：保护运行时所需的完整 `.Sq>` 字节、驱动/辅助组件字节，或一个能够稳定捕获运行时解密后完整调用和返回的观测基线。在此之前重复外层脚本不会提高证据强度。

## 复现与时间约束

静态证据：`C71`–`C75`、`C85`、`C94`；局部 harness 自检：`C76`、`C92`、`C99`；运行时页面/调用页：`C77`–`C78`；综合与边界报告：`C79`–`C100`。动态实验均使用明确阶段标志和短墙钟上限：离线变换/状态构造/validator 1 秒，caller seam 8 秒，post-target/API seam 8 秒，普通页面探针约 7–10 秒，post-launch attach 约 8 秒，`.Sq>` 重放与原生启动各 20 秒。没有阶段进展就停止、记录 fault 或等待边界并诊断，不继续机械等待。

因此，本篇的结论是：**本地请求构造、实际 DeviceIoControl 参数传播、调用链和 RC03 响应/状态校验已经被真实动态命中并连成同一 0x11c 数据流；有效 session 下的最终本地解码语义、驱动/辅助组件边界和业务副作用仍未被证实。**

## 样本身份纠正（C96）

C96 发现并纠正了 C95 的样本混用：`post-real-run` 快照提取的 `\\Windows\\System32\\Hardware.exe` 大小为 `32,198,144` 字节，SHA-256 为 `0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C`，与 genA/OUTER2 一致；当前 genB `<HOST_PATH>\\HexPatch\\ept-out\\Hardware.genB.exe` 大小为 `32,671,232` 字节，SHA-256 为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。C95 dump 主模块大小 `0x3F96000` 也与 genA 对齐，而不是 genB 的 `0x3F83000`。

因此，C95 的 dump 观察只能作为历史 genA/OUTER2 的用户态边界材料，不能作为 genB 核心已执行或未执行解码分支的证据。C90–C94 使用的 genB `.text`、helper seam、0x11c 请求块和 `DeviceIoControl` 动态命中保持独立有效。详见 [`C96_sample_identity_correction_20260921.md`](../artifacts/evidence/C96_sample_identity_correction_20260921.md)。

## genB baked 顶层快照扫描（C97）

C97 只读扫描了 `qoder-baked-20260921h` 的顶层差分 VDI，2,702 个已分配块中没有 `HP_WKS_SWTOOLS_DRIVER`、`.sys`、`SWTOOLS_DRIVER`、`Hardware.genB.exe` 或 `EPT_C573274B` 的 ASCII/UTF-16LE 命中；只出现 `EPT_runtime_hash`、`runtime-driver-image` 和普通 `Hardware.exe` 字符串。这个结果只对该顶层差分层成立，祖先层、无明文字符串的 payload 和内存映射组件仍未决。详见 [`C97_genb_baked_top_layer_driver_scan_20260921.md`](../artifacts/evidence/C97_genb_baked_top_layer_driver_scan_20260921.md)。

## genB 运行时页 payload 扫描（C98）

C98 对 C81 取得的完整 `.Sq>` 运行时范围（15,622,144 字节）做了 ASCII/UTF-16LE 目标字符串搜索和 `MZ → PE\0\0` x64 候选检查。目标驱动名、`.sys`、`Hardware.genB.exe`、`EPT_runtime_hash`、`runtime-driver-image` 均为 0 命中，有效 x64 PE 候选也为 0。这个结果排除了“运行时 `.Sq>` 页内直接有可识别驱动 PE/明文驱动名”，但不排除其他内存区、加密/分片 payload 或内核组件。详见 [`C98_runtime_page_payload_scan_20260921.md`](../artifacts/evidence/C98_runtime_page_payload_scan_20260921.md)。

## pre-device harness 固化（C99）

C99 把旧的临时 harness 固化为 [`core_predevice_harness.py`](../method/harnesses/core_predevice_harness.py)。它在不启动样本、不加载授权、不打开设备、不联网的条件下，直接映射核验过的 genB `.text`/最小数据捕获，调用 `0x14078ce60`、`0x14078d900` 和 `0x14078db80`。用 C90 的 268-byte 输入复现得到相同的变换 SHA、16-byte 状态、0x11c 请求块和 validator `RAX=1`；全零 validator 负对照返回 `RAX=0`。这满足了可复现的“本地 pre-device 研究入口”，但不把设备边界之后的最终业务解码冒充为已完成。详见 [`C99_predevice_harness_reproduction_20260921.md`](../artifacts/evidence/C99_predevice_harness_reproduction_20260921.md)。

## `-n/-m` 自然参数路径边界（C100）

C100 确认 genB rdata 中存在 `-n`、`-m`、`-h`、`-now` 等命令行字符串，也确认 `0x14078f250` 把 `mode`、`serialMode` 和 caller structure 传给 `0x14078f060`；但静态 `.text` 和完整 `.Sq>` 的直接 RIP xref 都没有把 `-n/-m` 连接到该 caller，`0x14078f250` 也没有发现 direct-call caller。因此 C90 的 synthetic 参数只证明 pre-device seam，不证明自然命令行路径已经闭合。详见 [`C100_cli_parameter_path_boundary_20260921.md`](../artifacts/evidence/C100_cli_parameter_path_boundary_20260921.md)。

## 参考驱动身份排除（C101）

对 `<HOST_PATH>\HexPatch\reference\ept-runtime-driver` 的静态身份核验显示，它不是当前 genB 的可直接替代驱动：genB PE `SizeOfImage=0x3F83000`、入口 `0x235F67`，参考镜像 `SizeOfImage=0xC8D000`、入口 `0x4EDC23`；当前 genB 的用户态设备路径为 `\\.\HP_WKS_SWTOOLS_DRIVER`，参考镜像注册的是随机名 `R2EHfEN7xzDfUR4GNTC676GOxk8v`，且没有 `HP_WKS_SWTOOLS_DRIVER`/`SWTOOLS` 字符串。参考目录中的 `HexPatchCoreDiag` 源码还明确是读取 `\\Driver\\edrv` 的私有诊断辅助。参考资产因此降级为“取证方法和独立研究参考”，不进入 genB 核心交付物。详见 [`C101_reference_driver_identity_exclusion_20260921.md`](../artifacts/evidence/C101_reference_driver_identity_exclusion_20260921.md)。

## C6 用户态设备对象边界（C102）

`C6_multi.exe` 是与 genB 同一 `ImageBase=0x140000000`、`SizeOfImage=0x3F83000` 的三段用户态重建视图，不是驱动镜像；对其中全部 `MZ` 候选做有效 PE 校验后只有外层 PE。函数 `0x1407890d0` 把 `\\.\HP_WKS_SWTOOLS_DRIVER` 写入通信对象偏移 `0x40`，再调用 `0x140788f00`，并按初始化成功/失败/空对象返回不同状态。因而当前正确的语义是“用户态设备对象初始化 → 设备前请求构造 → DeviceIoControl → 响应校验”，不是“`0x14078ce60` 已经是最终解码器”。详见 [`C102_c6_multi_user_mode_boundary_20260921.md`](../artifacts/evidence/C102_c6_multi_user_mode_boundary_20260921.md)。

## 目标驱动 blob 清点（C103）

对 `<HOST_PATH>\HexPatch\materials\ept\capture-20260912\real-run\recon\blobs` 的 24 个保存文件做了定点检查：`HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS_DRIVER`、`HP_WKS`、设备路径及 UTF-16LE 变体均为 0 命中；四个 `driver_injected_*.bin` 均为 0 bytes。其余可识别 PE blob 都属于已确认的 `edrv` runtime-driver 参考族，900-byte 的 `system32\Hardware` 也不符合历史 CSV 中约 8.12MB 的 runtime-driver-image。因而当前缺失的是目标驱动/辅助组件的真实字节，不是遗漏一个现成文件。详见 [`C103_target_driver_blob_inventory_20260921.md`](../artifacts/evidence/C103_target_driver_blob_inventory_20260921.md)。

## 本地 helper 算法级转录（C104）

C104 将 C90/C92 中已经通过原生执行确认、但此前主要以地址和哈希表达的三段 helper 做了可读算术转录：`0x14078ce60` 对 268 bytes 按四字节块滚动更新状态并 XOR；`0x14078cd70` 以 67 轮、每轮四字节的方式计算 dword 摘要；`0x14078d900` 将摘要、固定全局状态和混合常量组合为四个 dword，写出 16-byte state。实现位于 [`core_predevice_reference.py`](../method/harnesses/core_predevice_reference.py)。

参考实现与直接执行核验过的 genB `.text` 在三类输入上逐字段一致：C90 caller seam 的变换 SHA=`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`、摘要=`0x2567c4e5`、state=`a47b1c4e030ca1e4bcdbae01f044cf60`、request SHA=`bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`；全零和递增字节模式也分别实现了 transform、state 和 request 的原生一致性。验证过程中发现并修正了一处真正的 x86 语义问题：混合前的加法必须先按 dword 截断，不能直接用 Python 无限精度整数继续右移。

该报告只把“本地 pre-device 变换链”提升为算法级、可读、可复现结果；它没有改变当前核心结论。输入仍来自合成 caller seam，不是已经闭合的自然 `-n/-m` 业务输入；`0x14078ce60` 的业务方向仍不能仅凭静态形态判为 decode；`0x141757acd` 之后的有效设备响应、目标驱动/辅助组件和最终本地结果仍未取得。详见 [`C104_local_helper_algorithm_transcription_20260921.md`](../artifacts/evidence/C104_local_helper_algorithm_transcription_20260921.md)。

## 用户态 RC03 成功分支与本地解码输出（C105）

C105 闭合了 C104 之后此前仍未命名的用户态输出动作。`0x14078ee9b` 调用 `0x14078db80` 校验 0x11c response-shaped buffer；返回 0 时进入 `RC03 decode_failed`。返回非零后，`0x14078ef02` 比较 `[rsp+0x44]` 与全局 `g340`，不等时进入 `RC04 session_mismatch`；相等时进入 `0x14078ef42`，对 `[rsp+0x60]` 的 268-byte response payload 再次调用 `0x14078ce60`，然后将结果复制到原始 caller structure 的 `+0x80`，进入 `RC06 success`。

这确认了用户态本地解码结果的字段和算法：RC00 的第一次变换形成请求侧 payload，RC03 成功分支的第二次相同 XOR 变换还原 payload；同一固定 keystream 下两次变换互相抵消。新的 [`core_local_decode_harness.py`](../method/harnesses/core_local_decode_harness.py) 可直接接受 284-byte response，按 `validator → marker == g340 → second transform` 的真实顺序执行，并把结果写入 modeled caller structure `+0x80`，不启动样本、不打开设备、不联网。C90 synthetic response 的 validator=`1`、marker=`0x13579bdf`，解码输出 SHA=`7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e`，与输入逐字节相同；self-test 还分别验证了 `RC03 decode_failed` 和 stale-marker 的 `RC04 session_mismatch`。

因此，“用户态是否存在独立本地解码动作”已经得到肯定答案；仍未闭合的是 response 的真实驱动生产端、自然 `-n/-m` 输入路径及真实业务样本。C105 不把 synthetic response 升级为真实设备结果。详见 [`C105_user_mode_decode_success_seam_20260921.md`](../artifacts/evidence/C105_user_mode_decode_success_seam_20260921.md)。

## RC03 validator 的纯参考转录（C106）

C106 将 `0x14078db80` 的三段 state/payload 校验转录为 [`core_response_validator_reference.py`](../method/harnesses/core_response_validator_reference.py)：首 dword 检查、第二 dword 生成 marker、268-byte payload digest/第三 dword 检查以及末 dword 聚合检查均已覆盖。native 与 reference 对正常 response、全零、四个 state dword/payload 位翻转以及 `g340` stale-marker 共八个 case 逐项一致，分别稳定落入 `RC03 decode_failed`、`RC04 session_mismatch` 或 `RC06 success`。详见 [`C106_response_validator_reference_20260921.md`](../artifacts/evidence/C106_response_validator_reference_20260921.md)。

## 历史 minidump 边界（C95）

C95 从 `post-real-run` 快照链只读恢复了 `\ept\dumps\EPT_C573274B_2066D1C9.exe.3332.dmp`。这是有效 Windows minidump，不是日志；其 `ModuleList` 有 45 个模块，所有 45 个去重后的有效 x64 PE 都能归属到已登记模块，没有未知用户态 PE。`EPT_runtime_hash` 和相邻的 `runtime-driver-image` 字符串映射到主模块 `EPT_C573274B_2066D1C9.exe` 的 `0x140FA763A` 附近；dump 内没有 `HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS_DRIVER`、`Hardware.genB` 或 `auto_decode.pyc`。

这只证明主模块包含运行时驱动记录/取证逻辑，并不能证明驱动字节落盘、被用户态 minidump 收集，或已经得到有效驱动返回。C95 因而只收窄历史运行的用户态边界，不改变“本地请求构造和 DeviceIoControl 参数传播已证实、最终业务解码与驱动副作用未证实”的结论。详见 [`C95_historical_minidump_boundary_20260921.md`](../artifacts/evidence/C95_historical_minidump_boundary_20260921.md)。

## 受控 attach 证据（C80）

随后做了 6 个有效、带短墙钟上限的 post-launch attach 观测，并把 1 个使用旧客体脚本副本的记录明确剔除。断网条件下，授权门替换、main 入口、gate callsite 和 RC00 callsite 都能在相应实验中成功装载；但没有一个有效臂取得 RC00/RC03 返回值、输出缓冲区或本地副作用。

这批结果只说明“当前 attach 时序下断点未命中”，不证明样本永远不进入 main 或 RC00。A250-control 的 callsite 在 250 ms 时仍为 00，只能作为时间控制；A2200-control 及授权替换臂在较晚时点已观察到 E8。A250-main-gate-rc00 进一步把三组断点都装上后，在约 8 秒窗口内仍未命中，但 post-launch attach 会改变时序，因此不能升级成普遍阴性。

完整原始日志哈希、分类和停止条件见 C80_postlaunch_attach_boundary_20260921.md。C80 不改变本文的 INCOMPLETE / VALID_UNOBSERVABLE_ON_THIS_BASE 状态；在同一 attach/外层启动方式上不再重复，下一步必须取得完整 .Sq> 运行时字节、驱动/辅助组件字节，或新的早期观测基线。

## 完整运行时 `.Sq>` 范围（C81）

在客体内直接启动 `Hardware.exe`、网卡为 `null` 的有界采集中，目标页出现后读取了 `.Sq>` 的 `0x141174000–0x14205a000` 全部 3814 页，共 15,622,144 字节；3814/3814 次读取成功，3812 页非零。`post_send_wrapper=0x141757acd` 的运行时字节确认了到 `0x1415844d3`、`0x1419060e7`、`0x14171631b` 和 `0x141a93e50` 的四条 direct call。C81 解决的是“缺少完整运行时页”的采集缺口，不解决函数语义和业务输出。

## `.Sq>` 直接重放边界（C82）

C82 将 C81 的完整页面逐页写回新启动进程，同时恢复静态 `.text`、替换授权闸门并调用 `main`。所有 `.text` 和 `.Sq>` 写入均成功，但控制流在 `0x14169910f` 的 `ret 8` 处异常；RSP 首个 qword 为非规范返回地址，RC00 调用点没有命中。该结果归类为 `REPLAY_STATE_MISMATCH / NO_CORE_RETURN_OBSERVED`，不能把重放故障写成样本解码失败，也不能通过跳过 `ret` 伪造结果。

## 原生启动等待边界（C83）

C83/C84 从原生启动流程观察，不回放 `.Sq>`，只在首个 loader 断点恢复 `.text`、替换授权闸门并布置 `main` 与 RC00 断点。两次 20 秒窗口都没有命中 `main`；C83 进度 RIP=`0x7ffbe736d624`、RCX=`0x4d4`，C84 进度 RIP=`0x143a4a035`、RCX=`0x3e9`，且 C84 的 `DuplicateHandle` 返回错误 6。状态收窄为 `NO_SAMPLE_ENTRY_OBSERVED / RUNTIME_PROGRESS_NONDETERMINISTIC`；不据此指定等待对象、驱动或网络的具体含义，同一启动臂不再重复。

## 运行时分发边界（C107）

C107 复核了 `C15` 中两个指向 `0x14078f060` 的 rdata 指针项。当前恢复的 genB `.text` 没有指向该 rdata 表范围的 RIP-relative 引用，direct-call 图也没有 `0x14078f250` 的调用者；`C75` 的 `-n/-m` parser/consumer 窗口没有到 `0x14078f250`、`0x14078f060` 或 `0x141757acd` 的直接边。该结果只把自然参数路径缺口定位到运行时/未捕获分发，不能把函数指针表数值升级为调用链，也不能证明自然路径不存在。详见 [`C107_runtime_dispatch_table_boundary_20260921.md`](../artifacts/evidence/C107_runtime_dispatch_table_boundary_20260921.md)。

## 计划逐项验收（C108）

C108 对原计划逐项审计后，将当前状态明确为 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`：用户态 response validator、第二次变换和 caller `+0x80` 输出已经有原生/参考交叉证据；自然 `-n/-m` 路径、`RUN apply soft_success` 的真实核心调用链以及有效 `DeviceIoControl` response 尚未验证。目标驱动/辅助字节缺失作为真实未决项保留，不用参考驱动或旧 genA dump 填充。详见 [`C108_core_plan_completion_audit_20260921.md`](../artifacts/evidence/C108_core_plan_completion_audit_20260921.md)。

## 37. C109：真实 PE 入口与临时子进程调试边界（2026-09-21）

C109 修正了此前动态未命中的两个仪器假设。genB 的真实入口不是此前候选 helper 所在的 `0x1407…` `.text` 范围，而是 `0x14235f67b`；该入口实际调用高地址 `0x143c17fb0`，随后跳转到 `0x143c3deae` 的打包/运行时 dispatch 区。样本确实生成 `EPT_*.exe` 子进程；取回的副本大小为 `32,671,488` bytes，前 `32,671,232` bytes 与 genB 逐字节相同，仅追加 256 bytes。

`.childdbg 1` 能跟随子进程。早先一次 CDB 记录在子进程初始 `int 3` 后执行 `q`，因此被撤回为无效动态结果；改用正确的 `ibp` 事件过滤后，12 秒窗口仍未观察到 `0x1407a3080`、`0x14078f250` 或 `0x14078f060`，Guest Control 随后超时。这只能归类为 `WAIT_TIMEOUT / INSTRUMENT_FAILURE`，不能当作自然路径阴性。

C109 只闭合真实入口和调试器边界，不改变 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`：自然 `-n/-m` 分发、真实 response、`RC03/RC06` 和目标驱动字节仍未取得。详见 [`C109_genb_pe_entry_and_child_debug_boundary_20260921.md`](../artifacts/evidence/C109_genb_pe_entry_and_child_debug_boundary_20260921.md)。

## 自然 `main` 与 `-n` 解析动态校正（C110）

C110 在跟随临时 `EPT_*.exe` 子进程的真实地址空间中命中 `main=0x1407a4b90`，随后命中 `0x1407a55ae` 的自然 `-n` 解析调用点。该点的 `R8=0xa`，与 C75 静态识别的十进制 strtol-like 调用一致；因此“自然 `-n` 是否进入解析路径”已从 `MISSING` 提升为 `VERIFIED`。这不是 synthetic caller seam，也不是直接调用 `main` 的 harness。

C110 在第一个关键自然路径目标处停止，没有把未观察到的后续步骤写成阴性：`-m` 的完整路径、`0x14078f250/0x14078f060`、RC00 后的有效设备响应、自然 RC03/RC06 和驱动副作用仍未闭合。C100/C107 的静态结论仍有效，但对 `-n` 的“没有自然证据”表述由 C110 更新为“已取得自然解析命中”。详见 [`C110_natural_main_and_n_parse_dynamic_20260921.md`](../artifacts/evidence/C110_natural_main_and_n_parse_dynamic_20260921.md)。

当前自然路径边界应写成：

```text
Hardware.genB.exe 自然启动
    → main=0x1407a4b90
    → 临时 EPT_*.exe 子进程
    → 0x1407a55ae（-n，base=10）
    → 后续 -m / runtime dispatch / F250 / RC00：未观测
```

因此本地核心交付状态仍为 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`；C110 只是把自然命令行入口向前推进到真实 `-n` 解析，不是核心完成信号。

## 自然子进程核心候选点与授权前置边界（C111）

C111 使用 CDB 的 `cpr:EPT_*.exe` 创建进程过滤器，在临时子进程创建时成功安装 `0x14078f250`、`0x14078f060`、`0x14078ee73` 和 `0x141757acd` 四个硬件执行断点；输出中出现两次 `CHILD_BPS_ARMED`，因此这次不再是“没有跟到 child”或“断点没有装上”的仪器失败。

在未替换授权前置条件的自然命令行下，12 秒内四个候选点都没有命中，也没有自然 RC03/RC06 或有效设备响应。该结果只能写成 `VALID_CHILD_BPS_ARMED / NO_CORE_CANDIDATE_OBSERVED`：它说明当前分支在授权/设备前置条件下没有进入候选点，但不能把无效输入下的早停升级为核心不存在或解码失败。后续若继续，必须使用已审查的最小 bypass seam；重复当前无 bypass 启动没有信息价值。详见 [`C111_natural_child_core_gate_boundary_20260921.md`](../artifacts/evidence/C111_natural_child_core_gate_boundary_20260921.md)。

## 单点授权门绕过边界（C112）

C112 将最小 bypass 限定为真实临时子进程创建事件中对 `0x1407a3080` 写入 `B8 01 00 00 00 C3`（`mov eax,1; ret`），没有改动本地 helper、RC00/RC03 或设备响应。CDB 日志直接显示 `AUTH_GATE_PATCH_ATTEMPTED` 后的目标字节以及 `CHILD_BPS_ARMED`；因此该接缝已在真实 child 地址空间中复现。

但单点绕过后的 12 秒窗口仍未命中 `0x14078f250`、`0x14078f060`、RC00 候选点或 `0x141757acd`，也没有自然 RC03/RC06 或本地业务输出。该结果只说明“单点授权函数不是全部前置条件”，不能解释为核心不存在或解码失败。下一步若继续，应针对 `main` 内联状态/授权比较和高地址运行时 dispatch 建立新的返回值观测；不能继续重复同一单点绕过或延长等待。详见 [`C112_single_auth_gate_bypass_boundary_20260921.md`](../artifacts/evidence/C112_single_auth_gate_bypass_boundary_20260921.md)。

## 已知宿主 `.sys` 树身份扫描（C113）

C113 对当前宿主已知的 `<HOST_PATH>\VMs\<OTHER_VM_LABEL>\share` 和 `<HOST_PATH>\CTF` 目录递归扫描了 40 个 `.sys` 文件，共 848,240 bytes；目标设备名和驱动名的 ASCII/UTF-16LE 搜索均为 0 命中。目录中的 `hwidsrc`、`hwidsmbios`、`tpmspoof` 等文件属于实验室辅助组件，不能作为 genB 的 `HP_WKS_SWTOOLS_DRIVER`。这扩大了 C103 的排除范围，但不排除客体内存中的临时映像、无明文身份的加密载荷或未取回的快照层，因此仍不能替代真实驱动响应。详见 [`C113_known_sys_tree_target_identity_scan_20260921.md`](../artifacts/evidence/C113_known_sys_tree_target_identity_scan_20260921.md)。

## 父进程 runtime dispatch 观测（C114）

C114 在断网、12 秒墙钟和真实命令行下，对 PE 入口 `0x14235f67b` 与高地址 runtime dispatch `0x143c17fb0 → 0x143c3deae` 做了短窗观察。父进程入口命中 1 次，dispatch 连续命中 2 次；两次现场的参数分别为 `RCX/R8=0x7e4, RDX=0x9dc70, R9=0x1521b0` 与 `RCX/R8=0x87f, RDX=0x9d730, R9=0x1521b0`。这把入口后 dispatch 从单次边界推进到“短窗内重复、参数变化”的真实观察。

但本轮没有观察到 child 创建事件、`AUTH_GATE_PATCHED`、`main`、自然 `-n/-m`、F250/F060、RC00 或 post-target；因此本轮的 child bypass 并未实际应用，不能写成“bypass 后核心未到达”，更不能写成自然解码失败。状态仍是 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`。详见 [`C114_runtime_dispatch_parent_observation_20260921.md`](../artifacts/evidence/C114_runtime_dispatch_parent_observation_20260921.md)。

## 栈现场臂的仪器失败（C115）

C115 只把 C114 的高地址断点动作改为附加 `kv`、栈窗口和局部反汇编；Guest Control/收割在约 60 秒内没有产生 CDB 产物，随后按仪器失败流程中止并恢复快照、网卡。它不提供样本阴性证据，也不改变 C114 的有效父 dispatch 观察；在没有新收尾通道前，不重复该同形臂。详见 [`C115_runtime_dispatch_stack_instrument_failure_20260921.md`](../artifacts/evidence/C115_runtime_dispatch_stack_instrument_failure_20260921.md)。

## VirtualBox 启动会话失败（C116）

C116 将 C114 的栈现场动作改为不依赖符号栈回溯的 `RSP + dq @rsp L8 + u`，但 VirtualBox 在客体执行前返回 `E_FAIL / VM session was closed before any attempt to power on`，没有产生 CDB 或样本事件产物。清理后 VM 已恢复为 `saved / qoder-clean-20260920 / nic1=nat`。该结果是 `INVALID_INSTRUMENT`，不改变 C114 的有效父 dispatch 观察，也不提供样本阴性证据。详见 [`C116_runtime_stack_start_instrument_failure_20260921.md`](../artifacts/evidence/C116_runtime_stack_start_instrument_failure_20260921.md)。

## `RUN apply soft_success` 直接 xref 边界（C117）

C117 对完整恢复 `.text` 做了同一遍 Capstone x64 连续扫描：`RC00`、`RC03`、`RC04`、`RC06` 四个控制字符串各自命中一个已知 RIP-relative 引用，而 `RUN apply soft_success`（目标 `0x140f93570`）命中为 0。这个结果说明当前恢复 `.text` 不能直接建立 `soft_success → RC00/RC03/RC06` 的静态调用链；它不排除运行时算址、间接分发、未捕获代码或外层日志参数生成。详见 [`C117_soft_success_direct_xref_boundary_20260921.md`](../artifacts/evidence/C117_soft_success_direct_xref_boundary_20260921.md)。

## 完整 `.Sq>` 范围的 direct-edge 边界（C118）

C118 对 C81 捕获的完整 `.Sq>` 范围执行了原始 `E8 rel32` 扫描，并用四条已知 runtime direct call 作为控制位；四条控制边均命中，而 `RUN apply soft_success`、RC00/RC03/RC04/RC06、`-n/-m` 字符串和 F250/F060 均没有 direct E8 命中。这排除了当前运行时页内一条直接 E8 核心边，但不能排除寄存器间接调用、绝对地址、动态生成代码或范围外代码。详见 [`C118_runtime_sq_direct_edge_boundary_20260921.md`](../artifacts/evidence/C118_runtime_sq_direct_edge_boundary_20260921.md)。

## PE 入口到 runtime dispatcher 的静态链（C119）

C119 将动态命中的入口地址与原始 genB PE section/文件偏移对应起来：入口 `0x14235f67b` 的 direct call 进入 `0x143c17fb0`，随后 `0x143c17fb0 → 0x143c3deae → 0x143c30e27 → 0x143deac60` 形成可验证的 direct-jump 链。链条位于原始 `.)Bu` section；后续字节呈保护/混淆风格，不能当作普通线性业务 CFG。该结果强化了自然核心位于保护 runtime/未捕获分发边界的判断，但没有闭合自然 `-n/-m`、有效 response 或驱动副作用。详见 [`C119_genb_pe_dispatch_static_chain_20260921.md`](../artifacts/evidence/C119_genb_pe_dispatch_static_chain_20260921.md)。

## 连续 native core runner 与实际 RC06 输出（C120）

C120 改变了工作顺序：不再先等待自然外壳路径，而是让恢复的用户态 core 在受控 runner 中连续执行。C++ runner 调用 `0x14078f060`，替换输入准备 helper `0x1407b4700` 和捕获外的 `0x141757acd` 返回/continuation；CDB 命中 `F060 → ECE0 → transform → state → target stub → RC03 continuation → validator → RC06 transform`。normalized caller fixture 的 round-trip 输出与输入逐字节相等，证明受控 `host_mapped_code_runner` 执行到相关 transform/copy seam；它不证明自然设备 response、真实目标进程或解码后行为。详见 [`C120_continuous_native_decode_execution_20260921.md`](../artifacts/evidence/C120_continuous_native_decode_execution_20260921.md)。

## C175：C173 Guest 内 caller/injection harness 回归（不计目标完成，2026-09-24）

C175 把 C104/C105 的离线 harness 从宿主提升到真实 Windows Guest（<VM_LABEL>，Hyper-V Gen1）内执行；它没有启动 EPT/Hardware 真实样本，因此不是目标级运行。证据范围为 `caller_injection_harness`。投递链为：Host 打包 `python313.tar.gz`（含 `ctypes`）→ PowerShell Direct `Copy-Item -ToSession` → Guest `tar.exe` 解包为 `C:\ept_obs\python\3.13.12\python.exe`；harness `core_local_decode_harness.py` 与 4 个捕获件、2 个 forge 件一并送达，Guest 侧 SHA-256 与 Host authority 逐一一致（`HOST_VERIFIED`）。

- self-test 三控通过：`harness_rc03_branch=RC06 success` 正例 `harness_validator_rax=0x1` 且 `harness_decoded_matches_input=true`；全零响应负控 `harness_rc03_branch=RC03 decode_failed`；g340 翻转 mismatch 控 `harness_rc03_branch=RC04 session_mismatch` ⇒ Guest 内原生映射与解码工具链可信。
- `--input forge_caller_input_268.bin`：`evidence_scope=caller_injection_harness`、`harness_rc03_branch=RC06 success`、`harness_validator_rax=0x00000001`、`harness_validator_accepted=true`、`harness_marker_matches_g340=true`、`harness_decoded_output_bytes=268`、`harness_decoded_matches_input=true`、`harness_caller_output_written=true`，side_effects=`caller_structure+0x80[0x10c]`。
- `--response forge_license_response_284.bin`：同 `harness_rc03_branch=RC06 success`，且 `harness_decoded_output_sha256 == forge_caller_input_268.bin` 的哈希 ⇒ 两个 forge 件为配对：284B 响应经 validator→RC06 seam 解码后正是 268B 输入，回路自洽。
- caller `+0x80` 前后缓冲：收割 `caller_structure_after_decode.bin`（396 B），Host 重构 before 并 diff，14 字节变化全部落在 `[0x80,0x80+0x10C)`，且 `after[0x80:0x80+0x10C]==decoded_output.bin`；该数值仅为 `harness_caller_diff_bytes`。
- 运行归因：harness 子进程 PID（self-test=2788 / input=7344 / response=3084）共享父进程 PPID=5412（PowerShell Direct 会话）；`ppid_live` 因进程退出后为 `null`，如实记未知。

这里不做判据映射：`harness_validator_rax` 不等于 `target_native_return`；`harness_decoded_output_bytes`、`harness_caller_output_written` 或 `harness_caller_diff_bytes` 不等于 `target_caller_diff_bytes`。C175 的 `target_native_return`、`target_caller_diff_bytes` 均为 `NOT_COLLECTED`，RC06 后行为为 `NOT_OBSERVED`。样本 SHA-256、VM/运行编号（`EPT-C175-COREHARNESS-01`）和清理状态（Guest `C:\ept_obs` 仅非样本测试脚手架，未执行 EPT 样本）仍以 `HOST_VERIFIED` 证据保留。

限制：无真卡密、无设备、无真实授权会话；本闭环为 caller/injection 级用户态解码 seam + caller `+0x80` 写入，与 C120/C121 同口径，**不构成真实授权成功**；真实设备 response、自然 `-n/-m` 到 caller 完整链、驱动/辅助组件仍为 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`。证据综合见 [`C175_coreharness_vm_closure_20260924.md`](../artifacts/evidence/C175_coreharness_vm_closure_20260924.md)。

该结果闭合的是“可控外部前置下的连续用户态解码执行和输出”，不把受控 response/target seam 说成真实驱动行为；真实设备 response、自然输入来源和外部副作用仍另行保留为未决项。
