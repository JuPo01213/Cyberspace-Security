# C106：RC03 response validator 的纯 Python 参考转录

日期：2026-09-21  
状态：`VERIFIED / NATIVE_REFERENCE_MATCH`  
对象：`Hardware.genB.exe` 恢复 `.text`，SHA-256=`5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`

## 目的

C105 已经确认 RC03 成功分支的调用和输出位置。本轮把 `0x14078db80` 的本地 response validator 从机器码转成纯 Python 参考，避免把 validator 继续当成只能通过 ctypes 黑盒调用的步骤。

入口：

```text
<HOST_PATH>\EPT\method\harnesses\core_response_validator_reference.py
```

该入口只依赖 `core_predevice_reference.py` 的 32-bit mix、268-byte hash 和 transform；不映射 `.text`，不启动样本，不打开设备，不加载授权，不联网。

## 已转录的数据流

response 的布局为：

```text
+0x00  state word 0
+0x04  state word 1 / marker source
+0x08  state word 2
+0x0c  state word 3
+0x10  268-byte payload
```

`0x14078db80` 的三段判断如下：

```text
seed0 = mix(g348 ^ g344 ^ 0x4bcf194a)
check0 = inverse_rotate((tail(seed0) ^ dword0), rotate0) ^ seed0
check0 == g344

seed1 = mix(g34c ^ g344 ^ 0x6bac2dac)
marker = inverse_rotate((tail(seed1) ^ dword1), rotate1) ^ seed1

seed2 = mix(g350 ^ g344 ^ 0x032b31e2)
digest = local_hash(payload)
check2 = inverse_rotate((tail(seed2) ^ dword2), rotate2) ^ seed2
check2 == digest ^ marker ^ g344 ^ 2

seed3 = mix(g354 ^ g344 ^ 0x238a3c50)
check3 = inverse_rotate((tail(seed3) ^ dword3), rotate3) ^ seed3
check3 == dword0 ^ dword1 ^ dword2 ^ g344
```

这里的 `tail(seed)` 是原指令中 `seed + 0x7f4a7c15` 后停止在第二次乘法的 mix 变体，`inverse_rotate` 是由 `32 - (((seed >> 27) & 0xf) + 5)` 实现的旋转。marker 输出到 validator 的第二参数，RC03 外层随后将它与 `g340` 比较；因此 validator 通过不等于 RC06 成功，仍可能进入 `RC04 session_mismatch`。

## 原生交叉验证

以 C90 response（SHA-256=`bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8`）为基准，同时运行 native harness 和纯 Python reference。对 state 四个 dword、payload 和 `g340` 分别做破坏性对照：

| case | native/reference 分支 | validator | marker |
|---|---|---:|---:|
| valid | `RC06 success` / 一致 | `1` | `0x13579bdf` |
| zero response | `RC03 decode_failed` / 一致 | `0` | `0` |
| dword0 flip | `RC03 decode_failed` / 一致 | `0` | `0` |
| dword1 = 0 | `RC03 decode_failed` / 一致 | `0` | `0x0c7293bf` |
| dword2 flip | `RC03 decode_failed` / 一致 | `0` | `0x13579bdf` |
| dword3 flip | `RC03 decode_failed` / 一致 | `0` | `0x13579bdf` |
| payload bit flip | `RC03 decode_failed` / 一致 | `0` | `0x13579bdf` |
| `g340` 改一位 | `RC04 session_mismatch` / 一致 | `1` | `0x13579bdf` |

正例的第二次 transform 输出 SHA-256 仍为：

```text
7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e
```

纯参考 self-test 和 native/reference 交叉验证均在秒级内完成；没有任何 VM、设备或网络等待。

## 边界

C106 闭合的是“response 进入用户态后如何被验证、生成 marker 并选择 RC03/RC04/RC06 分支”。它不提供真实驱动 response，也不改变 C105 对自然 `-n/-m` 输入路径和目标驱动字节仍未取得的判断。
