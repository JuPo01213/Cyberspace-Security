# C100：`-n/-m` 到本地 caller 的参数路径边界（2026-09-21）

## 状态

`PARTIAL / CLI_STRINGS_FOUND_CALLER_SEAM_NOT_CONNECTED`

本轮只读分析 genB 静态 `.text`、rdata 和 C81 的完整 `.Sq>` 运行时页。目标是验证 `-n/-m` 是否已经通过真实交叉引用连接到 `0x14078f060`，而不是把 synthetic caller 参数当成自然命令行输入。

## 已确认的本地 caller 契约

静态 `.pdata` 分段和指令显示：

```text
0x14078f250:
  RCX = caller structure
  EDX = mode
  R8B = serial mode
  call 0x14078f060

0x14078f060:
  RCX = same structure
  EDX -> ESI
  R8B -> EBP
  copies 0x10c bytes from the structure source
  calls 0x14078ece0 logical communication block
```

`0x14078f250 -> 0x14078f060` 是已确认的静态 caller seam；它解释了 C90 synthetic 运行的参数形状，但不等于命令行已经走到这里。

## 命令行字符串证据

genB rdata 中确实存在：

```text
0x140f92bf7  " -n "
0x140f92c03  " -m "
0x140f92c0f  " -h "
0x140f92ce3  "-n 1"
0x140f92b50  "-now"
```

但在已恢复的静态 `.text` `.pdata` 函数中，以上字符串没有直接 RIP-relative xref；在 C81 的 870 个 `.Sq>` `.pdata` 运行时函数中也没有指向这些地址的直接 RIP-relative xref。`--nsp-runtime-child` 和 `MAIN startup` 的 xref 可以找到，但它们只证明另一个启动/子进程参数分支存在。

对 `0x14078f250` 的静态 direct-call xref 搜索也没有找到调用者；该 wrapper 更可能通过间接分发、运行时表或未恢复的控制流到达。当前证据不足以把 rdata 中的 `-n/-m` 字符串与该 caller seam 连成一条自然路径。

## 结论边界

- 已确认：自然 caller 所需的 mode、serial mode 和 0x10c-byte structure 形状。
- 已确认：C90 使用这些参数形状时，genB helper 链可独立复现。
- 未确认：`argv -n/-m` 的解析函数、解析后的数值来源、到 `0x14078f250` 的调用边，以及自然输入如何到达 `0x14078ce60`。

因此本轮不修改核心完成判定，不把 `-n/-m` 字符串命中写成自然解码路径已闭合。下一次若要闭合该项，必须取得命令行启动早期的真实参数/调用观测，或获得能解析间接分发目标的同身份运行时证据；继续重复 synthetic caller 不会提供该信息。
