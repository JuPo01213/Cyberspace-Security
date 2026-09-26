# C101 — 参考运行时驱动与 genB 身份排除

日期：2026-09-21
状态：`REFERENCE_ONLY / TARGET_DRIVER_NOT_IDENTIFIED`

## 目的

本轮只核对 `<HOST_PATH>\HexPatch\reference\ept-runtime-driver` 是否可以作为当前
`Hardware.genB.exe` 的目标驱动字节和解码实现。没有加载驱动、没有启动样本、没有
修改 VM，也没有把参考驱动的行为接入 genB 核心结论。

## 身份证据

当前 genB 候选为：

- 路径：`<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`
- 大小：`32,671,232` bytes
- SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- PE 镜像大小：`0x3F83000`
- PE 入口 RVA：`0x235F67`
- 节布局包含 `.text`、`.rdata`、`.Sq>` 等用户态/运行时区域。

参考目录的 L1 容器和内核实况镜像分别为：

- `rdata_decrypted.bin`：`8,121,856` bytes，SHA-256
  `3FE6370C8C54C709C496F187F73184B367C2C81EEC550942AD3BC9DAEAFF347F`
- `edrv_live_kva_full.bin`：`13,160,448` bytes，SHA-256
  `1BA855AD1ADEC091181ECEB8291399EB84CCEF58FE083466926FA9DE0D62B4CF`
- 参考镜像 PE 入口 RVA：`0x4EDC23`
- 参考镜像 `SizeOfImage`：`0xC8D000`
- 参考镜像是 9 节 Native PE，主要功能位于自解包后的 `.text`/`. [B:`/`.i?^`，与
  genB 的 PE 结构和入口均不相同。

此外，从当前 genB 用户态边界得到的设备路径是
`\\.\HP_WKS_SWTOOLS_DRIVER`，并存在 `HP_WKS_SWTOOLS_DRIVER.sys helper` 字符串；
这两项已由 C94 的全量数据区扫描记录。参考实况镜像的 UTF-16 设备名则是：

```text
\Device\R2EHfEN7xzDfUR4GNTC676GOxk8v
\DosDevices\R2EHfEN7xzDfUR4GNTC676GOxk8v
```

参考镜像中没有 `HP_WKS_SWTOOLS_DRIVER` 或 `SWTOOLS` 字符串。参考目录的
`ept-core-diag.c` 另行定义了 `\\Device\\HexPatchCoreDiag`，用于读取
`\\Driver\\edrv` 的对象/内存信息；它是取证辅助代码，不是 genB 目标驱动接口。

## 交叉比对

从当前 genB `.text` 中抽取的三个已确认用户态代码窗口：

- `0x14078CE60`：268-byte 本地原地变换；
- `0x14078F060`：本地 caller seam；
- `0x14078ED39`：RC00 continuation；

在参考 L1 容器、参考解包镜像和参考镜像文件中均没有逐字节命中。该结果不能证明
两个项目完全没有共同算法，但足以否定“把参考镜像直接当作 genB 的缺失驱动字节”
这一身份假设。

## 结论与边界

`reference/ept-runtime-driver` 现在只能被标记为：

1. 可复用的内核取证方法和 VM 内 `kd -kl` 取证流程；
2. 独立参考/研究驱动及其私有诊断接口；
3. 不能作为当前 genB 的驱动响应、IOCTL 语义或最终解码算法证据。

C93/C94 仍然是当前 genB 的有效结论：`0x141757ACD` 已确认进入
`DeviceIoControl → NtDeviceIoControlFile`，但有效句柄、真实控制码、目标驱动字节、
返回缓冲区和 RC03 结果尚未取得。当前独立 harness 仍只覆盖设备前的请求构造和
设备后的本地校验，核心交付状态保持未完成。
