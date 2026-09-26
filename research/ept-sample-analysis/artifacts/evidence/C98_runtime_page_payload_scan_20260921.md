# C98：genB 运行时页面中的 payload 边界（2026-09-21）

## 状态

`PARTIAL / RUNTIME_PAGES_HAVE_NO_EMBEDDED_PE_OR_DRIVER_STRINGS`

本轮只读分析 C81 从 genB 客体取得的完整 `.Sq>` 运行时范围，不启动样本、不连接网络。输入范围为：

```text
file: <HOST_PATH>\EPT\artifacts\captures\stream_SQSCAN_20260921A\sq_runtime_range.bin
VA: 0x141174000..0x14205a000
size: 15,622,144 bytes
SHA-256: 1DAF7EC28A09B43EB456F2027BCBAEB047AAFAB6B1A290CE14EDC9CCE761D1D4
```

（上面的 SHA-256 连续值为 `1daf7ec28a09b43eb456f2027bcbaeb047aafab6b1a290ce14edc9cce761d1d4`。）

## 实际观察

在整个范围内搜索 ASCII 与 UTF-16LE：

```text
HP_WKS_SWTOOLS_DRIVER
HP_WKS_SWTOOLS_DRIVER.sys
SWTOOLS_DRIVER
Hardware.genB.exe
EPT_runtime_hash
runtime-driver-image
.sys
```

结果：所有目标字符串均为 0 命中；对 `MZ → PE\0\0`、x64 machine、合理 section count、合理 image size 进行组合检查后，有效 x64 PE 候选为 0。

## 解释边界

这排除了“完整 `.Sq>` 运行时页中直接存在一个可识别的 PE/明文目标驱动字符串”这一具体解释，但不能排除：

- 运行时页之外的其他内存区域；
- 无明文字符串、压缩、加密或分片 payload；
- 驱动已在内核地址空间或由其他辅助组件提供；
- 目标仅把 0x11c 请求交给外部设备，不在用户态生成最终结果。

因此 C98 进一步收窄了用户态运行时 payload 边界，但不改变 C94 的结论：有效设备会话下的返回 buffer、最终业务解码和本地副作用仍未闭合。
