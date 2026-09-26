# C109：genB PE 真实入口与子进程调试边界

## 目的

验证此前对 `0x1407…` 候选函数的动态未命中是否只是调试器没有跟随样本产生的临时子进程，或者是样本的真实 PE 入口位于此前恢复 `.text` 范围之外。该轮只观察本地启动入口和调试器状态，不连接网络，不启动 `auto_decode.pyc`，不修改解码算法，也不把超时当作样本阴性。

## 输入与环境

- 当前样本：`<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`
- SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- 文件大小：`32,671,232` bytes
- VM：`<OTHER_VM_LABEL>`
- 动态快照：`qoder-armed-20260919`
- NIC：`null`
- 参数：`-k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 0 -m 1`
- 调试器：Microsoft CDB `10.0.29617.1000 AMD64`，客体内 `C:\ept\kdbin\cdb.exe`
- 单次 Guest Control 上限：`12 s`；无目标事件时停止，不延长同一臂。

## 直接观察

### PE 入口不在恢复的 `0x1407…` `.text` 范围

独立 PE 解析得到：

- ImageBase=`0x140000000`
- `AddressOfEntryPoint=0x235f67b`
- 入口 VA=`0x14235f67b`
- 该 RVA 落在 `.)Bu` 区段，而不在此前用于候选 helper 的 `0x1407…` `.text` 捕获范围。

在真实进程中对 `0x14235f67b` 下断点后命中：

```text
PE_ENTRY rip=000000014235f67b
rcx=00000000002ee000
rdx=000000014235f67b
r8 =00000000002ee000
```

入口前几条指令包含状态扰动，并调用 `0x143c17fb0`。该调用实际命中时的参数为：

```text
FIRST_CALL rip=0000000143c17fb0
rcx=00000000000007e4
rdx=000000000009dc70
r8 =00000000000007e4
```

`0x143c17fb0` 的第一条指令是跳转到 `0x143c3deae`；该高地址 dispatch 位置也实际命中。它不属于此前已闭合的 `0x14078ce60/0x14078db80` 用户态 helper 链。

### 临时子进程确实存在，且前缀字节与 genB 完全相同

在父进程启动后，CDB 的加载事件看到临时子进程，例如：

```text
<HOST_PATH>\Users\<USER>\AppData\Local\Temp\EPT_3266F6E0_85B8E896.exe
```

从客体取回该副本后重新计算：

- 子进程大小：`32,671,488` bytes
- 子进程 SHA-256：`3B506E9804B6BFAE8EF47C7BEC7B7C781CE83BB41A76B7999BD9EF3F159D52A4`
- 与原始 genB 的前 `32,671,232` bytes：逐字节相同
- 差异字节数（共同前缀）：`0`
- 追加尾部：`256` bytes

这说明临时副本不是一个可用来解释断点地址差异的不同代码版本；它是同一映像前缀加运行时追加块。

### CDB 子进程跟随与目标 seam 结果

使用 `.childdbg 1` 后，CDB 能附着到 `EPT_*.exe` 子进程。此前“没有命中”实验中，CDB 在子进程初始 `int 3` loader break 后执行了 `q`，属于仪器过早退出，已归档为无效动态结果。

修正事件名为 `ibp` 后，设置 `sxd ibp` 并保持 `0x1407a3080`、`0x14078f250`、`0x14078f060` 断点，仍在 `12 s` Guest Control 上限内没有得到目标命中或退出事件；Guest Control 随后无输出超时。该结果分类为：

`WAIT_TIMEOUT / INSTRUMENT_FAILURE`，不是 `VALID_NOT_REACHED`，更不是样本阴性。

## 解释边界

已验证：

1. 父进程和临时子进程确实被 CDB 观察到；
2. 真实 PE 入口位于 `0x14235f67b`，并实际进入高地址打包/dispatch 区；
3. 临时子进程的原始代码前缀与 genB 相同，仅追加 256 bytes；
4. 当前短窗口没有观察到 `0x1407a3080`、`0x14078f250` 或 `0x14078f060`。

尚未验证：

1. 高地址入口/dispatch 最终是否转入自然 `-n/-m` 参数路径；
2. `RUN apply soft_success` 与该 dispatch 的真实调用链；
3. 有效设备句柄、真实 `DeviceIoControl` response、`RC03` 或 `RC06`；
4. 目标驱动或辅助组件的真实字节。

因此 C109 只修正了入口和调试器边界，不提升 C108 的 `INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED` 状态。

## 清理

动态实验结束后已执行：

- 关闭运行中的 `<OTHER_VM_LABEL>`；
- 恢复快照 `qoder-clean-20260920`；
- 恢复 `nic1=nat`；
- 当前 VM 状态：`saved`。

## 产物

- 临时副本：`../captures/child_probe_20260921/EPT_3266F6E0_85B8E896.exe`
- 入口/dispatch 的 CDB 原始摘录：`../captures/child_probe_20260921/cdb_entry_probe.txt`；CDB 失败形态保留为 `WAIT_TIMEOUT / INSTRUMENT_FAILURE`，未用于样本阴性判断。
