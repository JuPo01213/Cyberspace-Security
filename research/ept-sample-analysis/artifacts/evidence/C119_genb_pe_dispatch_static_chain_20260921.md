# C119：genB PE 入口到 runtime dispatcher 的静态 direct-jump 链（2026-09-21）

## 输入与 PE 映射

- 文件：`<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`
- 大小：`32,671,232` bytes
- SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- ImageBase：`0x140000000`
- SizeOfImage：`0x3f83000`
- AddressOfEntryPoint：RVA `0x235f67b`，VA `0x14235f67b`
- 相关 section：`.)Bu`，RVA `0x205b000`，raw pointer `0x1400`，raw size `0x1f09c00`

地址均由 PE section 表进行 VA→RVA→file offset 回算；不是从动态日志猜测。

## 直接字节链

| VA | 文件偏移 | 直接字节/边 |
|---|---:|---|
| `0x14235f67b` | `0x305a7b` | `call 0x143c17fb0`，原始首字节 `41 53 9c 49 ...` |
| `0x143c17fb0` | `0x1bbe3b0` | `E9 F9 5E 02 00` → `jmp 0x143c3deae` |
| `0x143c3deae` | `0x1be42ae` | `E9 74 2F FF FF` → `jmp 0x143c30e27` |
| `0x143c30e27` | `0x1bd7227` | 前置保存/寄存器操作后，`0x143c30e38: E9 23 9E 1B 00` → `jmp 0x143deac60` |

C109 的动态观测已在真实进程中命中 `0x14235f67b`、`0x143c17fb0` 和 `0x143c3deae`；C119 把这些动态地址与当前 genB 原始文件中的真实字节和文件偏移对应起来。

## 解释边界

这条链确认真实 PE 入口首先进入高地址打包/runtime dispatcher，而不是直接进入此前恢复的 `0x1407…` 用户态 helper。它只证明 direct call/jump 和地址来源；`0x143c30e27` 之后的 section 含有混淆/虚拟化风格字节，不能用普通线性反汇编解释为业务 CFG，也不能据此推导自然 `-n/-m`、`RUN apply`、RC00 或设备返回。

C119 因而强化了“自然核心路径位于保护 runtime/未捕获分发边界”的证据，但不替代有效 response、自然 RC03/RC06 或驱动字节。
