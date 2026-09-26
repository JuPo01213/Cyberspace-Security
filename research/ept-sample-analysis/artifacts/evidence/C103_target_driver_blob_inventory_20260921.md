# C103 — 历史运行材料中的目标驱动 blob 清点

日期：2026-09-21
状态：`TARGET_DRIVER_BYTES_ABSENT_FROM_PRESERVED_BLOBS`

## 范围

只读检查 `<HOST_PATH>\HexPatch\materials\ept\capture-20260912\real-run\recon\blobs`
中的 24 个保存文件，目标是排除“目标驱动已经在历史材料中、只是尚未命名”的可能。
没有启动样本、没有加载驱动、没有修改快照。

## 结果

- `HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS_DRIVER`、`HP_WKS`、
  `\\.\\HP_WKS` 和对应 UTF-16LE 字符串在全部 24 个 blob 中均为 0 命中；
- 四个 `driver_injected_*.bin` 文件均为 0 bytes；
- 12 个 `l1_*`/`vec_*`/`rdata_decrypted.bin` 相关文件均为同一 EPT runtime-driver
  L1 容器或其随机尾变体，PE 头为 `SizeOfImage=0xC8D000`，不是 genB 的
  `HP_WKS` 辅助驱动；
- `edrv_live_kva*.bin`、`edrv_kernel_raw.bin`、物理 carve 文件均属于此前已识别的
  `edrv` 参考镜像，不包含目标设备名；
- `system32\\Hardware` 的 900-byte 文件不是 8MB runtime-driver-image，不能替代
  目标 `.sys`；历史 `EPT_runtime_hash.csv` 记录的 runtime-driver-image 长度约
  8.12MB，与其不符。

对所有 blob 的 `MZ → PE\0\0` x64 候选检查只得到上述 EPT runtime-driver 族的
已知镜像和 carve 中的偶然候选，没有出现一个带 `HP_WKS` 关联证据的新 PE。

## 结论

当前保存材料中没有可直接分析的 `HP_WKS_SWTOOLS_DRIVER` 同身份驱动或辅助组件。
因此 C93/C94 之后的缺口是真实的字节缺口，不是“尚未搜索到正确文件”。已有
`edrv` 参考层仍只能用于取证方法复用，不能填充 genB 的有效设备响应。
