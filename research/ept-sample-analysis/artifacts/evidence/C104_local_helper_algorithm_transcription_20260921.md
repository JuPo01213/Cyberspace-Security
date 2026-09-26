# C104：genB 本地 helper 算法级转录与交叉复现

日期：2026-09-21  
状态：`PARTIAL / PREDEVICE_ALGORITHM_REPRODUCED`  
对象：`Hardware.genB.exe` 恢复 `.text`，SHA-256=`5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`

## 结论

已将此前只以原生执行和 SHA-256 表示的三段本地 helper 转成无依赖的算术参考实现：

- `0x14078ce60`：对输入的 `0x10c`（268）字节做原地 XOR 变换；每 4 字节更新一次 32 位滚动状态，按 little-endian 字节取出 XOR keystream。
- `0x14078cd70`：对变换后的 `0x10c` 字节做 `0x43`（67）轮摘要；每轮严格消费 4 字节，合计 268 字节。
- `0x14078d900`：读取 `request+0x10` 的 268 字节和摘要，写入 `request[0:0x10]` 的四个 little-endian dword。

可读实现位于：

```text
<HOST_PATH>\EPT\method\harnesses\core_predevice_reference.py
```

内置回归检查可直接运行：

```text
py -3.13 <HOST_PATH>\EPT\method\harnesses\core_predevice_reference.py --self-test
```

本轮参考输出保存在 `<HOST_PATH>\EPT\artifacts\captures\predevice_reference_20260921A`；同输入的原生对照输出保存在 `<HOST_PATH>\EPT\artifacts\captures\predevice_harness_20260921D`。

它不启动样本、不加载授权、不打开设备、不联网。当前已经用同一份恢复机器码的原生 harness 对三类输入逐字段交叉验证。这里闭合的是“本地输入 → 本地中间变换 → 284-byte 请求侧块”的算法层，不是最终业务解码器。

## 指令到算法的对应

### 32 位混合原语

三段代码反复使用以下 32 位无符号运算。每个加法、乘法和移位结果都按 x86 dword 截断：

```text
mix_full(x):
    x = u32(x)
    x = u32(x ^ (x >> 16))
    x = u32(x * 0x7feb352d)
    x = u32(x ^ (x >> 15))
    x = u32(x * 0x846ca68b)
    return u32(x ^ (x >> 16))

mix_without_final_xor(x):
    x = u32(x)
    x = u32(x ^ (x >> 16))
    x = u32(x * 0x7feb352d)
    x = u32(x ^ (x >> 15))
    return u32(x * 0x846ca68b)
```

第二个形式只出现在 `0x14078d900` 的状态字构造中；它没有最后的 `x ^= x >> 16`。

### `0x14078ce60`：268-byte 原地变换

该函数读取的全局状态位于 `0x14115c340`：

```text
g340 = [0x14115c340]
g344 = [0x14115c344]
g348 = [0x14115c348]
g34c = [0x14115c34c]
g350 = [0x14115c350]
g354 = [0x14115c354]
```

等价伪代码如下。`payload` 是调用者传入的 268-byte 可写缓冲区：

```text
state = mix_full(g350 ^ g340 ^ g344 ^ 0xc3d2e1f0)
table = [g348, g34c, g350, g354]

for i in 0 .. 0x10b:
    if (i & 3) == 0:
        state = mix_full(state + table[(i >> 2) & 3] + i)
    payload[i] ^= byte(state, i & 3)
```

这里的 `+` 是 dword 加法；`byte(state, n)` 取 `(state >> (8*n)) & 0xff`。因此该段不会改变缓冲区长度，也没有内部 CALL、文件、注册表、设备或网络副作用。它的业务方向仍不能仅凭该函数命名为“解码”：在当前 caller seam 中它位于 `DeviceIoControl` 之前，证据只支持“请求侧本地变换”。

### `0x14078cd70`：67 轮、每轮四字节的摘要

该 helper 嵌在 `0x14078d900` 内部，读取 `g34c` 和 `g344`：

```text
state = mix_full(g34c ^ g344 ^ 0xb7e1506e)
salt = 0

for round in 0 .. 0x42:
    b0, b1, b2, b3 = payload[4*round : 4*round + 4]
    bias = u32(salt + 0x030004b9)

    x = u32((b0 + salt) ^ state)
    y = u32(b1 + 0x01000193 + salt)
    state = u32(x * 0x01000193)
    y = u32(y ^ (state >> 11) ^ state)
    state = u32(y * 0x01000193)

    y = u32(b2 + 0xfefffe6d + bias)
    y = u32(y ^ (state >> 11) ^ state)
    state = u32(y * 0x01000193)

    y = u32(b3 + bias)
    y = u32(y ^ (state >> 11) ^ state)
    state = u32(y * 0x01000193)

    salt = u32(salt + 0x0400064c)
    state = u32(state ^ (state >> 11))

return mix_full(state)
```

静态回跳关系是：循环尾部回到第一次 `movzx`，不会重新执行循环前的 `add r9, 2`。因此实际输入长度是 `0x43 * 4 = 0x10c`，此前把一次 over-capture 的 402 字节误读成算法消费长度的判断已撤回。

### `0x14078d900`：16-byte 状态构造

该函数把输入结构解释为：

```text
request[0x00:0x10]   输出四个 dword
request[0x10:0x11c]  送入 0x14078cd70 的 268-byte payload
```

它先计算 `digest = hash(request+0x10)`，然后根据 `g340..g354`、固定常量和 digest 生成四个 dword。状态构造中的每个旋转等价于：

```text
rotate = ((seed >> 27) & 0xf) + 5
rotated = rol32(value, rotate)
word = u32(rotated ^ tail ^ (tail >> 16))
```

其中 `tail = mix_without_final_xor(seed + 0x7f4a7c15)`。第二、第三、第四个 word 还分别把 `g340`、`digest` 和前三个输出按原指令顺序混入。完整可执行转录保留在 `core_predevice_reference.py`，避免报告中的伪代码因省略寄存器生命周期而变成第二套不可靠实现。

## 交叉验证

每组都使用同一组 synthetic globals：

```text
g340=0x13579bdf  g344=0x2468ace0  g348=0x01020304
g34c=0x11223344  g350=0x55667788  g354=0x99aabbcc
```

“原生”列来自 `core_predevice_harness.py` 对核验过的 genB `.text` 直接执行；“参考”列来自纯 Python 算术转录。请求块为 `state || transform_output`。

| 输入 | transform SHA-256 | hash32 | state（16 bytes） | request SHA-256 |
|---|---|---|---|---|
| C90 caller seam | 原生=参考 `6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3` | 原生=参考 `0x2567c4e5` | 原生=参考 `a47b1c4e030ca1e4bcdbae01f044cf60` | 原生=参考 `bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8` |
| 268 bytes 全零 | 原生=参考 `6521b2754d1b897a0cafc70db80cb21ff19fa3730bbff29b0fc3191b4dfd8f0a` | 参考 `0xe77427ce` | 原生=参考 `a47b1c4e030ca1e4388c6826e9dbdf3e` | 原生=参考 `897d70dd4c70bc9081188d4b6d2e2cc910d408f6bfb49e5f4b714c4be5eadc39` |
| `00 01 02 ... fb` | 原生=参考 `34db4e9c15da7f045b57c51b127feed0d2bb1fc49ae68bc86742db78dfce5e6f` | 参考 `0xbeaaacd8` | 原生=参考 `a47b1c4e030ca1e48ba07e9bb12f118c` | 原生=参考 `e0cdb6e91ef7555ea9e6af72df576dd3f7028c49a1301c6cba9cee554b31a7ef` |

第一组使用的原始输入 SHA-256 是：

```text
7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e
```

三组原生执行的墙钟耗时分别约为 27 ms、11 ms、16 ms；这些是隔离 harness 的实际运行时间，不包含 VM 启动、授权、网络或长轮询。

## 当前核心边界

当前已闭合的本地数据流是：

```text
caller-local 268 bytes
    └─ 0x14078ce60
          └─ transformed 268 bytes
                ├─ 0x14078cd70 → digest dword
                └─ 0x14078d900 → state 16 bytes
                       └─ request/response-shaped buffer 0x11c bytes
                              └─ 0x141757acd
                                    └─ DeviceIoControl / driver boundary
```

`0x14078db80` 的 validator 可以对该 `0x11c` 形状缓冲区做本地布尔/marker 校验；C92/C99 已验证正、负对照。但它不是最终业务输出。`0x141757acd` 之后的有效设备会话、目标驱动字节、响应内容以及自然 `-n/-m` 参数如何生成 caller-local 268 bytes，仍是未决项。C103 已证明当前保存的历史 blobs 中没有 `HP_WKS_SWTOOLS_DRIVER` 目标驱动镜像，因此不能用现有 `edrv` 参考驱动替代它。

所以本证据的结论仍是：

```text
本地 pre-device 变换链：已算法级复现
最终 5.1 本地解码核心：未完成
```
