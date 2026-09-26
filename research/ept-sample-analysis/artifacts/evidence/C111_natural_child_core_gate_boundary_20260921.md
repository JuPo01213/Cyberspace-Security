# C111：自然子进程核心候选点与授权前置边界

## 目的

C110 已经证明自然启动会进入 `main` 和 `-n` 解析。本轮只继续到更深一层：在不重复 `main`/`-n` 断点的情况下，确认 CDB 是否能在临时 `EPT_*.exe` 子进程中安装 `F250/F060/RC00` 候选点，并观察当前输入是否进入这些候选点。

本轮仍不启动 `auto_decode.pyc`、不联网、不伪造设备响应；也没有在自然运行中替换授权闸门。因此它只能回答“当前未替换前置条件的自然分支是否进入候选核心点”，不能回答有效授权条件下的核心行为。

## 输入与环境

- 样本：`<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`
- SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- VM：`<OTHER_VM_LABEL>`
- 动态快照：`qoder-armed-20260919`
- NIC：`null`
- 命令行：`C:\ept_core\Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 0 -m 1`
- 调试器：Microsoft CDB `10.0.29617.1000 AMD64`
- 机制：`.childdbg 1`；父进程初始断点直接安装硬件断点；`cpr:EPT_*.exe` 过滤器在临时子进程创建时安装同组断点。
- 单次核心观测墙钟上限：`12 s`；到期停止 CDB，不延长同一臂。

## 直接观察

子进程创建事件过滤器实际命中，CDB 输出：

```text
ModLoad: 0000000140000000 0000000143f83000
  <HOST_PATH>\Users\<USER>\AppData\Local\Temp\EPT_1E4C1342_A983B4EF.exe
CHILD_BPS_ARMED
```

`CHILD_BPS_ARMED` 出现两次，说明临时子进程已经被 CDB 跟随，并且以下地址在子进程地址空间中完成了硬件断点安装：

```text
0x14078f250  caller seam candidate
0x14078f060  local caller
0x14078ee73  RC00 callsite candidate
0x141757acd  RC00 post-send target candidate
```

在 12 秒窗口内，没有出现上述任一断点命中、RC03/RC06 输出或有效设备响应。该轮也没有取得文件、注册表、设备或驱动副作用。

## 解释边界

本轮状态为：

`VALID_CHILD_BPS_ARMED / NO_CORE_CANDIDATE_OBSERVED`

它只支持以下有限结论：

1. CDB 的 child process 跟随和候选点安装已经成功；
2. 在当前命令行和未替换授权前置条件下，12 秒内没有进入这些候选点；
3. 这不是“核心不存在”或“解码失败”，因为自然分支可能在授权/设备前置条件处停止；
4. 需要继续核心路径时，下一项有信息价值的实验必须使用已经审查过的最小授权 bypass seam，并在同一 child 进程中保留这些断点；不能再重复当前无 bypass 的自然启动。

本轮不把“未命中”升级为 `F250/RC00` 的自然否定，也不把无效卡密下的早停解释成最终解码结果。

## 清理

实验结束后已执行：

- 关闭 `<OTHER_VM_LABEL>`；
- 恢复快照 `qoder-clean-20260920`；
- 恢复 `nic1=nat`；
- 当前 VM 状态：`saved`。

## 产物

- 完整 CDB 输出：`../captures/natural_dispatch_f250_20260921e/cdb_stdout.txt`
- 关键摘录：`../captures/natural_dispatch_f250_20260921e/cdb_child_cpr_probe_excerpt.txt`
- 前置自然路径：[`C110_natural_main_and_n_parse_dynamic_20260921.md`](C110_natural_main_and_n_parse_dynamic_20260921.md)
