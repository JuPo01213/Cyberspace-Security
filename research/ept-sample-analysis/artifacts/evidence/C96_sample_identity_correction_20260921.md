# C96：历史快照样本身份纠正（2026-09-21）

## 状态

`CORRECTION / GEN_A_NOT_GEN_B`

本报告纠正 C95 的证据归属。C95 使用的 `post-real-run` 快照提取物属于 genA/OUTER2，不是当前目标 `Hardware.genB.exe`。因此 C95 只能作为历史运行边界材料，不能作为 genB 本地解码核心的直接证据。

## 可复核身份

从 `post-real-run` 快照的 NTFS 文件记录提取出的活动文件：

```text
path: \Windows\System32\Hardware.exe
size: 32,198,144 bytes
SHA-256: 0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C
artifact: <HOST_PATH>\EPT\artifacts\captures\snapshot_post_real_run_20260921\out\Hardware.exe
```

该提取物与已记录的 OUTER2/genA 候选完全一致。当前 genB 候选为：

```text
path: <HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe
size: 32,671,232 bytes
SHA-256: CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7
```

二者不是同一文件。已记录的 PE 头差异也相互印证：genA 的映像大小为 `0x3F96000`、入口 RVA 为 `0x2A085A0`；genB 的映像大小为 `0x3F83000`、入口 RVA 为 `0x235F67B`，且 genB 具有不同的节布局（包括 `.Sq>`）。C95 dump 的主模块大小为 `0x3F96000`，与 genA 一致。

## 对既有结论的影响

- C95 提取的 `EPT_C573274B_2066D1C9.exe.3332.dmp`（SHA-256 `3CB8891F5A114C13A793B1B0C47889DF8EDC67DC1D265203A5BAE315647E19FC`）仍是有效的历史 minidump，但其主模块身份是 genA/OUTER2。
- C95 中关于 `EPT_runtime_hash`、`runtime-driver-image`、用户态模块归属和 dump 中未出现目标驱动名的观察保持有效，但只对该 genA 历史运行成立。
- C95 不削弱也不增强 C90–C94 对 genB 捕获 `.text`、本地 helper、0x11c 请求块和 `DeviceIoControl` 边界的证据；两组证据必须分开引用。
- 当前 genB 核心的最终业务输出、有效设备会话下的驱动返回和本地副作用仍未闭合。

## 处理决定

后续核心判断只接受 genB 身份证据：`CFA6998E...` 的样本、genB 对应的 `.text`/运行时页、以及能证明同一身份的动态捕获。C95 被保留为历史边界材料，不再用于证明 genB 已执行或未执行某个解码分支。
