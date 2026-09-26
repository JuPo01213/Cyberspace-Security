# C95：历史运行 minidump 与驱动边界（2026-09-21）

## 状态

`PARTIAL / HISTORICAL_MINIDUMP_BOUNDARY_ONLY`

重要身份限定：本报告所用 `post-real-run` 快照和 dump 属于 genA/OUTER2，不是当前目标 `Hardware.genB.exe`。活动文件 `\\Windows\\System32\\Hardware.exe` 已提取为 `<HOST_PATH>\EPT\artifacts\captures\snapshot_post_real_run_20260921\out\Hardware.exe`，大小 `32,198,144` 字节，SHA-256 为 `0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C`；genB 候选的 SHA-256 为 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。身份纠正见 [`C96_sample_identity_correction_20260921.md`](C96_sample_identity_correction_20260921.md)。因此 C95 只能作为历史 genA 边界材料，不能直接证明 genB 的核心行为。

本轮只对 `<OTHER_VM_LABEL>` 的 `post-real-run` 快照链做只读 VDI/NTFS 解析和局部文件提取。不启动客体、不启动 `auto_decode.pyc`、不连接网络，也不把历史 dump 中的字符串当作当前核心解码输出。

## 输入与复现范围

- 快照：`post-real-run`，父链沿 `bf8372f0 → 5b979328 → d7f8ab72 → base` 读取。
- 来宾分区：MBR 分区起点 `0x100000`；其后为有效 NTFS 引导扇区，512 bytes/sector、8 sectors/cluster、1024-byte MFT record。
- `post-real-run` 与其直接父层的已分配 VDI 数据块使用流式扫描；未把整盘加载到内存。
- 目标字符串：`HP_WKS_SWTOOLS_DRIVER[.sys]`、`\\.\HP_WKS_SWTOOLS_DRIVER`、`Hardware.genB.exe`、`auto_decode.pyc`、`EPT_runtime_hash`、`runtime-driver-image`。

## 文件归属

唯一有效的 `EPT_runtime_hash` 命中位于 `post-real-run` 层的原始数据块。通过 NTFS `$MFT` 记录反查，它属于：

```text
\ept\dumps\EPT_C573274B_2066D1C9.exe.3332.dmp
MFT record: 29619
size: 114,157,625 bytes
```

该文件已按已验证的 33 条 NTFS data run 从快照链提取到：

`<HOST_PATH>\EPT\artifacts\captures\snapshot_post_real_run_20260921\out\EPT_C573274B_2066D1C9.exe.3332.dmp`

SHA-256：`3CB8891F5A114C13A793B1B0C47889DF8EDC67DC1D265203A5BAE315647E19FC`。

文件头为 `MDMP`，包含 16 个 stream，其中存在 `ModuleList` 和 `Memory64List`。这不是普通日志文件。

## dump 内的实际观察

- `ModuleList` 有 45 个模块；主模块为 `<HOST_PATH>\Users\<USER>\AppData\Local\Temp\EPT_C573274B_2066D1C9.exe`，基址 `0x140000000`、映像大小 `0x3F96000`。
- `EPT_runtime_hash` 位于 dump 文件偏移 `0x1714E73`，通过 `Memory64List` 映射到虚拟地址 `0x140FA763A`，落在主模块范围内。
- `runtime-driver-image` 位于同一主模块的相邻字符串表中。
- dump 中未找到 `HP_WKS_SWTOOLS_DRIVER`、`SWTOOLS_DRIVER`、`Hardware.genB` 或 `auto_decode.pyc` 的 ASCII/UTF-16 命中。
- 对 dump 中的 `MZ → PE\0\0` 做虚拟地址去重后，得到 45 个有效 x64 PE，全部落在已登记的 `ModuleList` 模块范围内；未知/隐藏用户态 PE 数量为 0。

## 解释边界

这条证据说明历史用户态进程的主模块包含 `EPT_runtime_hash.csv` / `runtime-driver-image` 记录逻辑，并且该运行产生过进程 dump；它不能证明驱动文件字节已落盘，也不能证明驱动映像被包含在用户态 minidump 中。

因此 C95 只加强以下边界判断：

```text
主模块中的运行时驱动记录/取证逻辑
        ≠
用户态 dump 中存在驱动 PE
        ≠
0x141757acd 已取得有效驱动返回
        ≠
本地解码核心已完成
```

内核驱动、内存映射驱动或未被用户态 minidump 收集的辅助组件仍是未决项。C95 不改变 C94 的最高核心状态：本地请求构造和 `DeviceIoControl` 参数传播已证实，但有效 session/IOCTL 下的最终业务解码输出和本地副作用仍未证实。

## 产物

- dump：`<HOST_PATH>\EPT\artifacts\captures\snapshot_post_real_run_20260921\out\EPT_C573274B_2066D1C9.exe.3332.dmp`
- 本报告：`<HOST_PATH>\EPT\artifacts\evidence\C95_historical_minidump_boundary_20260921.md`
