# C90：本地 helper 链的动态观测与离线精确复现

日期：2026-09-21  
状态：`PARTIAL / LOCAL_HELPER_CHAIN_EXACT_REPRODUCED`  
对象：`Hardware.genB.exe` 的恢复 `.text`，地址 `0x14078ce60`、`0x14078cd70`、`0x14078d900`

## 结论先行

这一次终于观测到了用户要求的本地变换链，但还不能称为“最终解码完成”。在一个不连接网络、不启动 `auto_decode.pyc`、不经过自然授权路径的最小 caller seam 中，原生代码实际完成了：

```text
0x14078f060  local caller
      │
      ├─ 0x14078ce60  原地变换，输入/输出各 0x10c 字节
      │
      └─ 0x14078d900  写出 16 字节状态
              └─ 0x14078cd70  对变换后 0x10c 字节求局部摘要
```

动态结果与两个独立离线 harness 精确一致：

- `0x14078ce60`：捕获输出 SHA-256=`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`，离线重放完全相同；
- `0x14078cd70`：真实返回 `RAX=0x2567c4e5`；
- `0x14078d900`：捕获 16 字节输出为 `a47b1c4e030ca1e4bcdbae01f044cf60`，离线重放完全相同。

这闭合了“输入经过什么本地变换、产生什么本地中间结果”的研究层，但没有闭合最终业务输出、方向（请求编码还是响应解码）、`0x141757acd` 之后的辅助组件/驱动边界，也没有证明自然 `-n/-m` 路径会使用这组输入。

## 关键静态校正

此前把 `0x14078cd70` 的输入误记为 402 字节，是对回跳目标的误读，现就地撤回。

在 `0x14078cd70` 中，`0x14078cdad: add r9, 2` 位于第一次循环体之前；循环尾部 `0x14078ce2f: jne 0x14078cdb1` 回到 `movzx`，并不回到 `add r9,2`。因此：

- 第一次迭代先读偏移 `0,1,2,3`；
- 后续迭代每次由 `lea r9,[r9+4]` 前进四字节；
- `0x43` 次迭代实际消费 `0x43 × 4 = 0x10c` 字节；
- 调试器第一次为保险多取的 402 字节只是 over-capture，偏移 `0x10c..0x191` 不参与计算。

宿主 Unicorn 对恢复的原始机器码直接执行也返回 `0x2567c4e5`，与客体中的真实返回值一致。运行时在 `0x14078cd70` 入口读回的 256 字节代码与静态 `.text` 完全一致，除入口断点临时留下的首字节 `0xcc` 外没有差异；因此这不是运行时改写造成的结果。

## 动态 seam 与时间边界

实验从 `qoder-clean-20260920` 启动，客体网卡为 `null`。调试器恢复已核验的 `.text`（8,257,536 字节，SHA-256=`5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`），只替换授权闸门的前置返回，并设置合成的通信状态 dword；没有连接 endpoint，也没有启动外层 Python 壳。

`0x14078f060` 通过远程最小 stub 调用，参数为：

- `RCX` 指向 0x10c 字节 caller-local 结构：偏移 0 为 0，偏移 4 为 mode `2`，偏移 8 为 ASCII `local_probe\0`，偏移 `0x108` 的 serial byte 为 `1`；
- `EDX=2`；
- `R8B=1`。

本轮 wall-clock 上限为 8 秒。阶段日志先观察到 transform entry/return，再观察到 state-builder entry、hash entry/return、state-builder return，随后立即停止；`main` 和 RC00 外部 callsite 没有被等待。该 seam 是研究入口，不是自然业务运行的成功证明。

## 输入、变换和输出证据

### 0x14078ce60

动态输入文件：`core_direct_local_caller_20260921F/out/local_transform_input.bin`，268 字节，SHA-256=`7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e`。

动态输出文件：`local_transform_output.bin`，268 字节，SHA-256=`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`。

离线入口：`<HOST_PATH>\vmctl\local_transform_harness.py`。使用相同的六组显式 synthetic dword：

```text
g340=0x13579bdf  g344=0x2468ace0
g348=0x01020304  g34c=0x11223344
g350=0x55667788  g354=0x99aabbcc
```

离线输出与动态输出逐字节相同；该函数没有文件、注册表、设备、驱动或网络副作用。

### 0x14078cd70 / 0x14078d900

调试器在 `0x14078d900` 入口记录 `RCX=0x14f058`，因此 hash helper 的 `RCX=0x14f068` 正好是变换后 0x10c 缓冲区。`0x14078cd70` 真实返回：

```text
RAX=0x2567c4e5
```

`0x14078d900` 返回时输出缓冲区为：

```text
a4 7b 1c 4e 03 0c a1 e4 bc db ae 01 f0 44 cf 60
```

动态输出文件和离线 replay 文件的 SHA-256 都是：

```text
c096ea2d01af2cb1574fb9539a7a9221632bf804ce260abd044991b2ac6de558
```

离线入口：`<HOST_PATH>\vmctl\local_state_harness.py`。它逐条转录 `0x14078cd70` 的 67 轮摘要和 `0x14078d900` 的四个 dword 构造；当前采集文件仍有 402 字节，但 harness 明确只消费前 268 字节。该前缀的 SHA-256 等于变换输出：`6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3`。

## 边界、未决项和不应过度解释的部分

已确认的只是本地中间计算链。以下仍未确认：

- `0x14078ce60` 在业务上究竟是 encode 还是 decode；
- `0x14078d900` 生成的 16 字节状态是否是校验、请求元数据还是响应状态；
- RC00 随后的 `0x141757acd` 及其 `.Sq>`/辅助组件边界；
- 驱动字节和设备副作用；干净客体中没有目标 `.sys`，20 秒断网探针也没有观察到预期路径落盘；
- 自然 `-n/-m` 输入如何到达这组 helper，以及 helper 的结果如何形成最终业务输出。

因此 C90 的状态保持为 `PARTIAL`，而不是核心完成。停止点位于本地状态构造之后、捕获范围外调用之前；本轮没有把授权、联网、GUI、`final_status` 或长时间等待混入核心判定。

## 原始材料与复核哈希

目录：`artifacts/captures/core_direct_local_caller_20260921F/out/`

```text
debug_core_call.log                 5eaa665511a57aaa34f17cbc3ca0cd7682cb3d84f38f2af5f93bb8fc9d24c047
local_state_hash_code.bin            8d117690775a3f4973640acb02f07eb9629a535e32610b67c77d6b87b5d0a94e
local_state_payload.bin              e903ce0cf465b073077f5b0adf965b4047193ea516f8b25f7923ee87ab568b32
local_state_output.bin               c096ea2d01af2cb1574fb9539a7a9221632bf804ce260abd044991b2ac6de558
local_state_output_replay.bin        c096ea2d01af2cb1574fb9539a7a9221632bf804ce260abd044991b2ac6de558
local_transform_input.bin            7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e
local_transform_output.bin           6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3
local_transform_output_replay.bin    6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3
```

运行器：`<HOST_PATH>\vmctl\debug_core_call.ps1`；离线入口：`<HOST_PATH>\vmctl\local_transform_harness.py`、`<HOST_PATH>\vmctl\local_state_harness.py`。
