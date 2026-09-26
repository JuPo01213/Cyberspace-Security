# C105：用户态 RC03 成功分支与本地解码输出

日期：2026-09-21  
状态：`PARTIAL / USERMODE_DECODE_SUCCESS_SEAM_REPRODUCED`  
对象：`Hardware.genB.exe` 恢复 `.text`，SHA-256=`5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`

## 结论

已确认并隔离出真正位于用户态的“响应后本地解码”操作：

1. RC03 在 `0x14078ee9b` 调用 `0x14078db80` 校验 0x11c response-shaped buffer。
2. 校验失败时进入 `RC03 decode_failed` 日志并退出。
3. 校验成功后进入 `0x14078ef02`，先比较 response marker 与 `[0x14115c340]` 的 `g340`；不一致进入 `RC04 session_mismatch`。
4. marker 一致时进入 `0x14078ef42`，对 response 的 payload `[rsp+0x60]`（268 bytes）再次调用 `0x14078ce60`。
5. 随后把这 268 bytes 原样复制到原始 caller structure 的 `+0x80`，然后进入 `RC06 success` 日志路径。

因此，当前已经可以把第二次 `0x14078ce60` 调用准确命名为：

```text
validator-accepted response payload
    └─ 0x14078ce60
          └─ caller_structure + 0x80  （268-byte 用户态解码结果）
```

这比“`0x14078ce60` 是一个变换候选”更强：它的输出位置和成功分支已经由静态调用链闭合。由于该函数是固定 keystream XOR，同一组状态下执行两次会还原输入，因此 RC00 的第一次调用形成请求侧变换，RC03 成功分支的第二次调用形成响应侧还原。

## 静态证据

### RC03 validator 分支

`0x14078ee89..0x14078eea2`：

```text
lea  rdx, [rsp + 0x44]
mov  dword ptr [rsp + 0x44], 0
lea  rcx, [rsp + 0x50]
call 0x14078db80
test eax, eax
jne  0x14078ef02
```

失败分支从 `0x14078eea4` 开始读取 response marker 和上下文，使用 `RC03 decode_failed` 格式串，并在 `0x14078eede` 结束该分支。

### marker 与成功输出

`0x14078ef02..0x14078ef42` 先执行：

```text
mov  r8d, dword ptr [rsp + 0x44]
mov  esi, dword ptr [0x14115c340]   ; g340
cmp  r8d, esi
je   0x14078ef42
```

不相等时进入 `RC04 session_mismatch`。相等时：

```text
lea  rcx, [rsp + 0x60]               ; response + 0x10
call 0x14078ce60                     ; 268-byte local decode
mov  rcx, qword ptr [r14]            ; caller structure
lea  rdx, [rsp + 0x60]
lea  rcx, [rcx + 0x80]               ; output destination
copy 0x10c bytes from [rsp+0x60]
```

复制循环由两轮 0x80-byte SIMD copy 加最后 8+4 bytes 组成，合计正好 268 bytes。没有观察到文件、注册表、设备或网络写入；该段的可见本地副作用是把解码结果写入 caller structure `+0x80`。

## caller structure 的本地输入/输出契约

RC00 在复制到临时 response buffer 前对 caller structure 做了有限的本地解释：

```text
offset +0x000   首个被复制的 dword/qword 字段；C90 synthetic seam 中为 0，语义未闭合
offset +0x004   mode dword（RC00 明确读取 `[rcx+4]`）
offset +0x008   C90 synthetic seam 放置 inline `local_probe` 的位置；字符串扫描使用 RAX 派生指针，前置赋值尚未由当前 continuation 片段闭合
offset +0x080   success branch 的 268-byte decoded output
offset +0x108   serialMode byte（RC00 明确读取 `[rcx+0x108]`）
```

在 `0x14078ed48..0x14078ed7e`，代码按 4-byte 步长扫描一个由 RAX 派生的字符串指针，并把长度限制在 `0x100` 以内；当前切出的 continuation 片段没有显示该 RAX 的前置赋值，因此不把扫描源强行归因到结构偏移 `+0x000`。在 `0x14078ed81` 读取 `[rcx+0x108]` 作为 `serialMode`，读取 `[rcx+4]` 作为 `mode`。随后从该结构复制 268 bytes 到 `[rsp+0x60]`，执行第一次 `0x14078ce60`。因此当前已知的本地数据流不是抽象的“某个 buffer”，而是：

```text
caller structure (mode/serialMode + RAX-derived string input)
    └─ copy 0x10c bytes
          └─ request transform
                └─ DeviceIoControl response buffer
                      └─ validator + marker
                            └─ second transform
                                  └─ caller structure +0x80
```

## 独立研究入口

入口：

```text
<HOST_PATH>\EPT\method\harnesses\core_local_decode_harness.py
```

它支持两种模式，并且按 RC03 的真实分支顺序执行：

- `--response <284-byte file>`：直接对 response-shaped buffer 执行原生 validator，验证 marker 后执行本地解码；
- `--input <268-byte file>` 或 `--hex`：只用于构造一个已知的 validator-accepted synthetic response，以隔离用户态成功分支。

validator 返回 0 时报告 `RC03 decode_failed`；validator 通过但 marker 不等于 `g340` 时报告 `RC04 session_mismatch`；只有两者都通过才执行第二次变换并报告 `RC06 success`。因此 harness 不会把 stale-marker response 误报成解码成功。

validator 本身的纯 Python 算法参考见 [`core_response_validator_reference.py`](../../method/harnesses/core_response_validator_reference.py)；C106 对它和 native validator 做了 state/payload/`g340` 破坏性对照，八个分支结果逐项一致。

在 `RC06 success` 下，harness 还生成一个 396-byte 的 caller-structure 最终快照，把 268-byte 结果写入 `+0x80`；这对应原生复制循环的可见用户态副作用。设备、文件、注册表和网络副作用仍单独报告为空。

运行时只映射核验过的 genB `.text` 和最小数据捕获，直接调用 `0x14078ce60`、`0x14078d900`、`0x14078db80`；不启动 `Hardware.exe`，不打开设备，不加载授权，不联网。

## 动态/离线结果

对 C90 caller seam 的 268-byte 输入：

```text
input SHA-256                 7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e
synthetic response SHA-256    bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8
validator RAX                 0x00000001
validator marker              0x13579bdf (= g340)
encrypted payload SHA-256     6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3
decoded output SHA-256        7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e
decoded output == input       True
latest direct-response run   30.655 ms; no device/network wait
```

内置 self-test 对全零和 `00 01 02 ... fb` 两组输入均返回：

```text
validator RAX = 1
decoded output == input = True
```

同一 self-test 还验证了两个负分支：全零 0x11c response 进入 `RC03 decode_failed`，把成功 response 的 `g340` 改动一位后进入 `RC04 session_mismatch`。

输出材料：

```text
<HOST_PATH>\EPT\artifacts\captures\local_decode_harness_20260921A\
<HOST_PATH>\EPT\artifacts\captures\local_decode_harness_20260921B\
```

每个 `--out-dir` 还会写出 `caller_structure_after_decode.bin`；最新直接 response 重放的材料在：

```text
<HOST_PATH>\EPT\artifacts\captures\local_decode_harness_20260921F\
```

## 边界与未决项

这次已经闭合的是“用户态成功分支的解码算法和输出字段”，不是“真实设备响应已经取得”：

- 当前 response 是由已知输入构造的 synthetic response；尚未从真实 `HP_WKS_SWTOOLS_DRIVER` 得到自然 response；
- `-n/-m` 到 caller structure 的自然输入路径仍未闭合；
- 目标驱动/辅助组件字节仍缺失，不能把 synthetic response 当成真实业务样本；
- 因此最终状态仍是 `PARTIAL`，但缺口已经从“用户态解码是否存在”收窄为“真实 response 生产端和自然输入路径”。
