# C204 · RC00 边界契约、请求块自洽性证明与卡密→会话键派生（本轮授权链推进）

日期：2026-09-26 · 运行：EPT-AUTHGATE-20260926-16（attempt 1 = 秒死类）
对象：`C:\ept_core\Hardware.exe`，SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
（谱系 `<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe` → `artifacts\captures\hardware_guest_test.exe`，见 C151）

分析用的运行时字节来源：`runs/EPT-AUTHGATE-20260925-82/child_full_recv2.dmp`（minidump Memory64，已用 `method/scripts/mdmp_read.py` 离线读取，未启动样本）
离线可复算脚本：`method/scripts/pe_rva_dump.py`、`method/scripts/mdmp_read.py`、`method/scripts/scan_global_refs.py`

本件不宣称授权通过、不宣称解码成功；`target_native_return` / `target_caller_diff_bytes` / `rc06_stage` 仍 `NOT_OBSERVED`。

---

## 1. RC00 边界的真实契约（本轮新信息）

`0x14078ee27..0x14078ee73` 是 RC00 的完整调用准备序列（运行时反汇编，非磁盘字节）：

```text
0x14078ee2c  lea  rcx, [rsp+0x50]          ; 284 字节块基址
0x14078ee31  call 0x14078d900              ; build_state -> 写 16 字节 state header @[rsp+0x50]
0x14078ee36  mov  qword [rsp+0x38], 0      ; lpOverlapped = NULL
0x14078ee3f  lea  rax, [rsp+0x40]
0x14078ee44  mov  qword [rsp+0x30], rax    ; lpBytesReturned = &[rsp+0x40]
0x14078ee49  lea  r8,  [rsp+0x50]          ; lpInBuffer
0x14078ee4e  lea  rax, [rsp+0x50]
0x14078ee53  mov  dword [rsp+0x28], 0x11c  ; nOutBufferSize = 284
0x14078ee5b  mov  r9d, 0x11c               ; nInBufferSize  = 284
0x14078ee61  mov  qword [rsp+0x20], rax    ; lpOutBuffer = [rsp+0x50]
0x14078ee66  mov  edx, ebp                 ; dwIoControlCode
0x14078ee68  mov  dword [rsp+0x40], 0      ; *lpBytesReturned = 0
0x14078ee70  mov  rcx, rsi                 ; hDevice
0x14078ee73  call 0x141757acd              ; RC00 包装（AGENTS.md 所指 0x141757acd）
0x14078ee8e  mov  dword [rsp+0x44], 0
0x14078ee96  lea  rcx, [rsp+0x50]
0x14078ee9b  call 0x14078db80              ; RC03 validator，输入仍是 [rsp+0x50]
```

**关键事实（与既有假设的差别）：**

1. 284 字节块的构成为 `build_state(transform(payload)) || transform(payload)`：payload 在 `[rsp+0x60]`（268 字节），先经 `0x14078ce60` 原地变换，再由 `0x14078d900` 在 `[rsp+0x50]` 写 16 字节 header。
2. **`lpInBuffer == lpOutBuffer == [rsp+0x50]`**：请求与响应是**同一块缓冲区**，驱动被期望原地改写它。
3. RC03 validator 的输入也恰好是 `[rsp+0x50]`（`0x14078ee96`）。因此 **RC00 的返回值与 RC03 的判据共享同一块 284 字节内存**。
4. 调用 `0x141757acd` 之后 `0x14078ee78..0x14078ee8d` 在本次转储中是未解锁的填充字节；该段会在运行时被解密覆盖，**不得**按转储字节当作静态代码分析。

## 2. 请求块本身就是被 validator 接受的 response（本轮决定性证明）

用仓库已有的纯 Python 参考（`method/harnesses/core_predevice_reference.py` + `core_response_validator_reference.py`）直接验证：

```text
payload = 268 字节任意值
transformed = local_transform(payload, keys)
request_blob = build_state(transformed, keys) + transformed      # 样本送给驱动的 284 字节
validate_response(request_blob, keys)  ->  accepted=True, marker==keys.g340
```

实测（`keys` 取全零 / 合成值 / 仅 g340 非零 三种）：

| keys | validator_accept | marker | RC04(marker==g340) |
|---|---|---|---|
| 全零 | True | 0x00000000 | pass |
| 合成（0x13579bdf…） | True | 0x13579bdf | pass |
| 仅 g340=0xDEADBEEF | True | 0xdeadbeef | pass |
| 负对照：request_blob 的 d0 翻一位 | **False** | — | fail |

**结论：`build_state` 生成的 header 与该块自身 payload 自洽，所以 RC00 的请求块天然满足 RC03 的四项校验，且 marker 自动等于当时的 `g340`。**

因此，**“驱动调用返回成功但不改动该 284 字节缓冲区”就是一份协议上合法的 response**，不需要伪造任何密码学材料、不需要知道卡密、不需要服务器。这是本轮授权链推进的核心可验证设计，取代此前 handle=0/control=0 的 synthetic 注入。

## 3. 六个“会话键”的真实来源（两套，此前被混为一谈）

运行时全 `.text` 引用扫描（`scan_global_refs.py`，8.2 MB 运行时映像）给出的读写点：

| 全局 | 唯一写入点 | 含义 |
|---|---|---|
| `g340` `[0x14115c340]` | `0x14078e263`（`mov [g340],eax`）、`0x14078e9ed`（`mov [g340],ebx`）、`0x14078e6f9`（清零） | **设备会话 ID** |
| `g344` `[0x14115c344]` | `0x14078ac61`（清零）、`0x14078af4d`、`0x14078af5c` | **卡密派生** |
| `g348` `[0x14115c348]` | `0x14078b076` | **卡密派生** |
| `g34c` `[0x14115c34c]` | `0x14078b0a4` | **卡密派生** |
| `g350` `[0x14115c350]` | `0x14078b0dc` | **卡密派生** |
| `g354` `[0x14115c354]` | `0x14078b0fc` | **卡密派生** |

- `g340` 由 `0x14078e1a9..0x14078e263` 一次 **32 字节 DeviceIoControl**（`nOutBufferSize=0x20`，包装 `0x1417584bc`）的结果写入；`comm_init` 路径的日志串为
  `"CI08 comm_init begin h=%p session=0x%08lX comm=%s"` / `"CI10 comm_init attached_existing …"` / `"CI11 comm_init direct_open_ok …"`（`0x140f8d3c8` 附近）。
  → **`g340` 是设备会话产物，不是卡密产物。驱动不在线时它保持 0**（这解释了 run 82 在 recv#2 时刻六个全局全为 0）。
- `g344..g354` 只由 **`0x14078ac40`**（纯函数）写入：调用点 `0x14078e6a7`（comm 路径）与 `0x14078caf1`。

## 4. 卡密格式约束与派生算法（可离线复算）

`0x14078e640..0x14078e6a7` 在调用派生函数前先校验输入串：

```text
0x14078e645  call 0x1417772e6      ; eax = strlen(key)
0x14078e64a  add  eax, -0xa
0x14078e64d  cmp  eax, 0x13
0x14078e650  ja   0x14078e6f9      ; 长度不在 [10, 29] -> 失败返回
0x14078e680.. 每字符必须落在 0-9 / A-F / a-f
```

**⇒ 卡密是 10..29 位十六进制字符串。** 早期 run 11-19 使用的 32 位 `CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` **不满足该约束**；本轮使用的 `1234567890`（10 位）满足。

`0x14078ac40` 的结构（纯算术，无 I/O、无随机源）：

1. 清零 `0x14115c344`、`0x14115c348..357`、`0x14115c358..367`、`0x14115c3f0..42f`、`0x14115c368`、`0x14115c36c`；
2. `strlen` 检查 1..63 + hex 检查；
3. 两轮 FNV-1a 变体滚动哈希（种子 `0x7da49f05` / `0xd3050ee9`，乘子 `0x01000193`，每步 `x ^= x>>13`），各自以 `(len*0x9e3779b9) ^ hash` 收尾再经 `mix_full`（murmur3 fmix32 常量 `0x7feb352d` / `0x846ca68b`）→ `ebx`、`ebp`；
4. 由 `ebp`/`ebx` 生成 **28 字节字母数字串**写入 `0x14115c3f0`：首字节取 52 字符表 `0x140f8cdc0`（`a-z A-Z`），其后 27 字节取 62 字符表 `0x140f8ce50`（`a-z A-Z 0-9`）；
5. 逐项写入 `g344 @0x14078af4d/0x14078af5c`（含特例 `0x8cd812fd`）、`g348 @0x14078b076`、`g34c @0x14078b09e`、`g350 @0x14078b0d6`、`g354 @0x14078b0f6`，以及 `g358/g35c/g360/g364/g368/g36c`。

**⇒ 全部密钥材料都是卡密的确定性函数**：同一卡密在同一进程里得到同一组 `g344..g354`，与设备、网络、时间均无关。这使“离线复算 + 离线构造合法 response”成立；`g340` 仍需设备会话（或为零）。

### 4.1 本轮转录进度（诚实边界）

`method/scripts/ept_keyderive.py` 已落地**部分**转录：

- 已验证并可直接跑：输入前置约束（含 `--check` 向量，实测 32 位 `CAAAA…` 被拒、`1234567890` 通过）、两轮滚动哈希（种子 `0x7da49f05`/`0xd3050ee9`、乘子 `0x01000193`、后置 `x ^= x>>13`、收尾 `mix_full((len*0x9e3779b9) ^ hash)`）、28 字节 token（表 `0x140f8cdc0`/`0x140f8ce50`）、`g344`、`g358/g35c/g360/g364/g368/g36c`。
- **尚未转录**：`g348 / g34c / g350 / g354`（指令位于 **`0x14078b035..0x14078b0f6`**）。这四个字是 268 字节 transform 与 RC03 validator 的直接输入，寄存器 `edx/r8d/r10d` 生命周期交织，必须逐条钉死后才能称为 keygen；脚本对它们显式 `UnfinishedTranscription`，**不以“看起来对”的版本冒充密钥派生**。
- 因此：**当前还不能离线复算 keystream，也还不能离线解码 1029 的 103 字节帧体**；该步骤是下一轮的第一个动作（地址范围已给出）。

## 5. 网络 1029 与 RC00 是两个不同通道

- 1029（`yz.hwid001.com:1029`，hosts 钉扎 127.0.0.1）承载 `[u32 107][103B]` 帧，属 HWID/授权上报（C190 §7）。
- RC00 的 response 只由 `0x14078ee73 → 0x141757acd` 这条设备调用产生，缓冲即 `[rsp+0x50]` 的 284 字节。
- 本轮**不**把两者混用：RC00 注入只发生在设备边界，不触碰 1029。

## 6. 本轮动态运行结果（诚实标注）

`runs/EPT-AUTHGATE-20260926-16`：

- 驱动器：样本自投放驱动预载为 `STATE: 4 RUNNING`（设备在线）；hosts 钉扎；mock 1029 监听在线。
- **自然命令行启动**（首次）：`C:\ept_core\Hardware.exe -k 1234567890 -n 2 -m 1`（`-k` 卡密、`-n` codeType dynamic=2、`-m` mode1=1，取自样本自带 Python 包装的调用约定）。
- child `EPT_639EE53B_F3BEEC8A.exe`（pid 1960）+ CDB 附加成功；winproc/watcher 启动。
- 结果：child 经 `EPT_639EE53B_F3BEEC8A+0x3ae5d57 → kernel32!ExitProcessImplementation` 直接退出。
  - 4 个硬件断点（`0x14078e6ac` 派生完成 / `0x14078ee73` RC00 调用点 / `0x14078ee9b` RC03 调用点 / `0x14171f567` FATAL thunk）**全部未命中**；
  - `protocol.ndjson` 仅 `LISTENER_1029_UP`（连接数 0）；`winproc.ndjson` = `agree:0 edits:0 app:0`（无窗口）；
  - 无文件写入、无网络、无设备 IOCTL。
- 分类：**秒死类**（C187 §2 的三分类之一，比例随机）。判定为 `DEBUGGER_NOT_REACHED`，**不得**写成解码失败或授权失败。
- 处置：本轮改为循环重试（`loop16.ps1`）。**在修掉 §7.6 的嵌套 `j` 故障后**，attempt 2 得到本轮最完整的自然轮：

### 6.1 attempt 2（非秒死类，新信息最多）

`runs/EPT-AUTHGATE-20260926-16/att2_cdb.stdout.txt`（41,888 B）、`att2_protocol.ndjson`、`frame_1..3.hex`、`sendbuf_at_send.bin`、`recvbuf_at_recv.bin`

| 观测 | 值 |
|---|---|
| `KB_CFW` ×3 | `"C:\Windows\System32\Hardware"`（C187 §3.5 的追加式加密日志） |
| `WFW` ×12 | 日志行含 `[2026-09-26 18:48:27] ` + `SetupFlow.begin` + `Setup.` + 栈上格式串 `stage=%s ret=%d na…` |
| `DIOC` ×1 | `rcx=0x1c0 rdx=0x390008 r8=0`（卷设备噪声，非目标 IOCTL） |
| `CONN` ×3 | sockaddr `02 00 04 05 7f 00 00 01` = AF_INET:1029:127.0.0.1 |
| `SEND_OBS` ×3 | `r8=0x6b`(107)，发送缓冲 0x5de010；调用方 `EPT_…+0x11f943`（0x1401xxxxx 协议状态机，与 C192 §3 一致） |
| `RECV` ×3 | 无响应（监听 `Respond=0` 纯记录），每次 8 s 超时 |
| `MSGBOXA_SKIPPED` ×1 | 超时后弹框被自动跳过 |
| 终局 | `EXIT_PROCESS_SKIPPED` ×1（直接 ExitProcess 路径） |
| 未命中 | `KEY_DERIVER_DONE`、`RC00_CALLSITE`、`RC03_VALIDATOR_CALLSITE`、`FATAL_THUNK_OBS` 全 0 |

**同轮一致性核对（关键）**：CDB 在 `ws2_32!send` 处 `.writemem` 下来的前 107 字节与监听器 `frame_3.hex` **逐字节相同**：
`6B000000 8D3DA9BDD221C8BD 961317BD8850CB62 … C3710318 618DDCE1 BF71C942 097091`
⇒ 同一轮的“进程内发送缓冲”与“线路帧”互证，不再依赖跨轮拼接。

**103 字节体结构（跨 6+ 轮稳定）**：
```text
off 0..7    8D xx xx xx xx 21 C8 BD     中段 4 字节每帧变化
off 8..38   96 13 17 BD 88 50 CB 62 6B 26 8A 65 E9 48 2F 4F 87 A6 99 27 6A D1 F0 84 00 61 A3 43 ED 19 A8   （固定 31 B）
off 39      随帧变化（1 B）
off 40..46  随帧变化（7 B）
off 47..102 固定（56 B，… 18 61 8D DC E1 BF 71 C9 42 09 70 91）
```
变化点固定在同一批偏移 ⇒ 若为定 keystream 流密码，则明文只在 `[1..4]`、`[39..46]` 变化（共 12 B），其余 91 B 明文固定。该结构是离线反推编解码器的直接抓手。

### 6.2 本轮结论：当前唯一闸门是 1029 响应

三轮自然启动（含 `-k 1234567890 -n 2 -m 1`）中，**`KEY_DERIVER_DONE`（`0x14078e6ac`，comm_init 内派生完成点）从未命中**，而每轮都出现
`CONN 1029 → SEND(107) → 8 s 超时 → 重连 ×3 → MessageBox → 直接 ExitProcess`。
⇒ 与 C190 §7 一致：**HWID 阶段的输入是 1029 响应；拿不到它就不会进入容器/设备会话，也就永远到不了 `comm_init`/RC00。**
本轮把这条依赖从“推断”升级为“同轮时序耦合的实测”：*网络超时序列发生 → 4 个硬件断点全 0*。

## 7. 仪器故障与修复（本轮实测，避免重犯）

1. **CDB 符号解析会无限期卡住**：当 `module!symbol` 的 PDB 不在本地缓存且符号服务器不可达时（`sym` 目录内出现 `download*.error`），`bu kernelbase!CreateProcessA`、`bu kernelbase!DeviceIoControl` 会长时间无输出，表现为“运行卡死”，实际是仪器故障。
2. **`-y <含空格路径>` 不可用**：`Start-Process -ArgumentList` 不会给参数加引号，CDB 会把 `C:\Program Files (x86)\…` 拆成多个参数并把 `Files (x86)\Windows Kits\Debuggers\x64\sym` 当成被调试目标。
   **修复**：在启动进程内设 `$env:_NT_SYMBOL_PATH = <本地 sym 目录>` 后再 `Start-Process`（子进程继承）。本条已在 `guest_launch.ps1` 落地并实测：CDB 日志从“卡在 1.4 KB”变为正常推进到运行结束。
3. **不要重命名 `sym` 目录**：旧 `host_prep.ps1` 每轮把 `sym` 改名成 `sym_off_HHMMSS`，直接导致符号缓存丢失并触发 (1)。本轮已改为“保留并统计 PDB 数”。
4. **对 `cmd.exe` 做 CDB 语法预检不代表真实靶机**：模块集合不同会使 `bu user32!…` 触发符号下载卡死。本轮预检已收窄为仅 `PF_BEGIN/PF_ARMED` 空跑。
5. **heredoc 内联写 PowerShell 会丢反斜杠层级**（`\10`→0x08、`\x64`→`d`）：脚本一律用文件写入工具。本轮已踩一次并修复。
6. **断点动作里的嵌套 `j 条件 '分支A' '分支B'` 会静默吞掉整条动作（含其末尾的 `g`）** —— 这是本项目多轮“样本自己死了”的假象来源之一。
   实测（`att1_cdb.stdout.txt`）：`bu ws2_32!send ".echo SEND_OBS; …; j (@r8 > 0x40 && @r8 < 0x400) '…SEND_BUF_DUMPED…' '…'; g"` 命中时**只**打印了 `SEND_OBS/r r…` 三行，`SEND_BUF_DUMPED` 与任一分支的 `u poi(@rsp) L10` 都没有输出，且动作未继续到 `g` ⇒ 调试器停在该断点回到提示符，脚本随后执行到 `~*k`、`q`，**在样本仍在运行时结束调试**（`~*k` 里 3 个线程仍 Unfrozen 即为证据）。
   **修复**：断点动作内一律不用嵌套 `j`；需要分支时改用无条件命令 + 固定长度转储（本轮已把 `send`/`recv`/`WriteFile` 三条改成无条件 `.writemem … @rdx @rdx+0x200`）。
   **影响面**：此前所有轮次的 `SEND_BUF_DUMPED`/`RECV_BUF_DUMPED` 恒为 0、以及“WFW/SEND 之后运行就结束”的现象，很可能都是本条仪器故障而非样本行为。
7. **`bu kernelbase!DeviceIoControl` 在真实靶机上可直接用**（run 16 attempt 1 实测命中 1 次，参数 `rcx=0x1c0 rdx=0x390008 r8=0`，为卷设备噪声），说明该符号在真实靶机进程里可解析；本轮的“卡住”只出现在缺少 PDB 的进程（cmd.exe 预检）与 `sym` 缓存被改名之后。
8. **attempt 1 的正向收获（同一轮）**：自然 `-k` 启动下首次捕获到
   - `CONN` sockaddr `02 00 04 05 7f 00 00 01`（AF_INET, port 0x0405=1029, 127.0.0.1）；
   - `SEND_OBS` `r8=0x6b`（107 字节）——与 C191 的 `[u32 107][103B]` 帧结构一致；
   - `KB_CFW` `"C:\Windows\System32\Hardware"` + `WFW` ×9（含 `[2026-09-…` 时间戳行）——即 C187 §3.5 的加密追加日志，说明部署阶段被自然走到。
   - 但 4 个硬件断点（含 `0x14078e6ac` comm_init 派生完成）仍未命中 ⇒ **该轮仍未到设备会话阶段**，与 C190 “HWID 阶段需要网络响应”的判定一致。

## 8. 台账状态

- `target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：`NOT_OBSERVED`
- 新增（本轮，静态/离线，`evidence_scope=static_runtime_dump + offline_reference`）：
  - RC00 契约（in==out==`[rsp+0x50]`，284 字节，call site `0x14078ee73`）
  - “请求块即合法 response”的离线证明（含负对照）
  - `g340`=设备会话 / `g344..g354`=卡密派生 的读写点分离
  - 卡密格式约束（10..29 位十六进制）与派生算法结构
- 下一步（已定稿，等一轮非秒死即可执行）：在 `0x14078ee73` 处**不改写缓冲区、仅令该调用返回成功**（`r eax=1`，跳过 `0x141757acd`），使 RC03 自然接受 RC04 自然通过、RC06 自然执行；标注 `real_sample_guest_run_injected_io`。
