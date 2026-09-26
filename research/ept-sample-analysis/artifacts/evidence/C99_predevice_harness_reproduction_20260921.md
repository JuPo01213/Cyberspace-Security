# C99：genB 本地 pre-device harness 可复现性（2026-09-21）

## 状态

`PARTIAL / PREDEVICE_HARNESS_REPRODUCED`

旧报告引用的 `<HOST_PATH>\vmctl` 临时 harness 已不在当前工作区。为避免交付不可复现，本轮把同一研究入口固化到：

`<HOST_PATH>\EPT\method\harnesses\core_predevice_harness.py`

该脚本只映射已核验的 genB 恢复 `.text` 和最小数据捕获，在固定地址直接调用：

```text
0x14078ce60  268-byte in-place transform
0x14078d900  16-byte state builder
0x14078db80  response/state validator
```

它不启动 `Hardware.exe`、不启动 `auto_decode.pyc`、不加载授权、不打开设备、不连接网络。

## 正例复现

命令：

```powershell
py -3.13 <HOST_PATH>\EPT\method\harnesses\core_predevice_harness.py `
  --text <HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin `
  --input <HOST_PATH>\EPT\artifacts\captures\core_direct_local_caller_20260921F\out\local_transform_input.bin `
  --out-dir <HOST_PATH>\EPT\artifacts\captures\predevice_harness_20260921B
```

实际结果：

```text
text SHA-256:              5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757
input bytes:               268
input SHA-256:             7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e
transform output SHA-256:  6f6a7d1c1434b53ceb3e5152e303b43cedb641fcbb10119c75ba8314b62471c3
request buffer bytes:      284
request buffer SHA-256:    bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8
state output:              a47b1c4e030ca1e4bcdbae01f044cf60
validator RAX:             0x00000001
validator marker:          0x13579bdf
elapsed:                   22.902 ms
```

这与 C90/C92 的动态捕获逐字节一致：变换输出、16 字节状态和 0x11c 请求块均一致。

## 负对照

```powershell
py -3.13 <HOST_PATH>\EPT\method\harnesses\core_predevice_harness.py `
  --text <HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin --self-test
```

`--self-test` 直接把全零 0x11c 缓冲交给 validator，实际返回 `RAX=0`、marker 保持 `0`。因此正例的 `RAX=1` 不是固定返回值。

## 交付边界

该 harness 已经形成可脱离外层工具的本地研究入口，但它只覆盖“请求侧变换、状态构造、响应/状态校验”。它不包含 `0x141757acd` 之后的有效设备调用、最终业务输出或驱动副作用，因此不能被命名为完整最终解码器。
