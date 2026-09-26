# C102 — C6 重建视图中的用户态设备对象边界

日期：2026-09-21
状态：`PARTIAL / USERMODE_DEVICE_SETUP_CONFIRMED`

## 目标

确认 `C6_multi.exe` 是否是驱动镜像、是否包含缺失的目标驱动，以及
`HP_WKS_SWTOOLS_DRIVER` 字符串所在函数的职责。分析只使用已有 C6 捕获物，未启动
样本、未加载驱动、未联网。

## C6 重建物身份

`<HOST_PATH>\EPT\artifacts\captures\stream_C6\C6_multi.exe` 的属性为：

- PE32+ x64，ImageBase=`0x140000000`；
- `SizeOfImage=0x3F83000`，与当前 genB 候选一致；
- 三个重建节：用户态 `.text`、`.rdata` 前段和 `.rdata` 后段；
- 文件大小 `9,564,672` bytes，SHA-256
  `8978171CE7FC33F31039EA9A5027ABDC9EDD09D52FB0F4065905967FC161C44F`；
- 对所有 `MZ` 候选做 `e_lfanew → PE\0\0`、x64 machine、PE32+ 和合理
  `SizeOfImage` 校验后，只有外层 PE 一个有效候选。

因此它是用于静态分析的用户态重建视图，不是内嵌的目标 `.sys` 或运行时内核镜像。

## 设备对象初始化函数

在 `0x1407890D0..0x1407891A5` 中可以逐条确认：

1. 对传入对象清理/初始化若干字段，并把固定函数地址写入对象偏移
   `0x00..0x40`；
2. 把 `\\.\HP_WKS_SWTOOLS_DRIVER` 的地址写入对象偏移 `0x40`；
3. 调用 `0x140788F00`；
4. 被调方成功时返回 `0`，失败时写入状态字段并返回 `2`，空对象返回 `1`。

同一函数还把 `HP_WKS_SWTOOLS_DRIVER.sys helper` 字符串作为对象字段保存。该证据把
当前用户态职责收窄为设备/服务通信对象初始化；它没有显示 `0x14078CE60` 的变换
算法，也没有显示最终响应产生。

## 与核心数据流的关系

当前最小、可脱离外层执行的链应标记为：

```text
caller-local 0x10c bytes
    → 0x14078CE60  本地原地变换
    → 0x14078D900  16-byte state 构造
    → 0x141757ACD  进入 DeviceIoControl 包装
    → 目标驱动/辅助组件（字节与有效会话未取得）
    → 0x14078DB80  本地响应/状态校验
```

这里的前两步是可复现的设备前请求构造，不应命名为“最终本地解码器”。
`C6_multi.exe` 只提供用户态设备路径和初始化对象的证据；它没有补上目标驱动字节、
有效 IOCTL、返回 buffer 或 `RC03 decode_failed` 的真实业务条件。

## 结论

当前可以交付的独立研究入口是 `method/harnesses/core_predevice_harness.py`，
其语义是“重现 genB 的设备前请求构造和设备后 validator”，不是完整最终 decoder。
最终本地结果仍位于有效设备请求返回及其缺失的辅助/驱动边界之后；在取得该边界的
同身份字节或稳定有效会话前，继续重复外层授权、网络或长时间启动实验不会增加核心
证据强度。
