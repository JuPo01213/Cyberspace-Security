# C97：genB baked 快照顶层驱动字符串边界（2026-09-21）

## 状态

`PARTIAL / GENB_BAKED_TOP_LAYER_NEGATIVE`

本轮只读扫描 `qoder-baked-20260921h` 的顶层差分 VDI，不启动客体、不连接网络、不运行外层工具。该快照对应的磁盘为：

```text
snapshot: qoder-baked-20260921h
disk: <HOST_PATH>\VMs\<OTHER_VM_LABEL>\Snapshots\{ea2036b7-5c22-4ff2-982f-47ba4aba8997}.vdi
disk uuid: ea2036b7-5c22-4ff2-982f-47ba4aba8997
parent uuid: 0804dc93-b582-4439-aa1a-acc1c1a85031
```

## 实际扫描

按 VDI block map 读取该层的 2,702 个已分配 1 MiB 数据块，分别搜索 ASCII 和 UTF-16LE：

```text
HP_WKS_SWTOOLS_DRIVER
HP_WKS_SWTOOLS_DRIVER.sys
SWTOOLS_DRIVER
Hardware.genB.exe
EPT_runtime_hash
runtime-driver-image
Hardware.exe
EPT_C573274B
```

扫描耗时 `131,317 ms`。目标驱动名、`.sys`、`SWTOOLS_DRIVER`、`Hardware.genB.exe` 和 `EPT_C573274B` 均为 0 命中；命中的是 `EPT_runtime_hash`、`runtime-driver-image` 和普通 `Hardware.exe` 字符串，共 41 个 ASCII/UTF-16LE 命中。

## 解释边界

这只能证明目标字符串没有出现在 `qoder-baked-20260921h` 的顶层差分数据块中。它不能证明：

- 祖先 VDI 层没有这些字符串；
- 驱动没有以无明文字符串、压缩、加密或内存映射形式存在；
- `0x141757acd` 后没有有效驱动或辅助组件。

因此该结果只作为 genB 快照的局部排除项，不能替代有效设备会话下的动态返回和副作用观察，也不能把 `runtime-driver-image` 字符串解释成已取得驱动字节。
