# C134：RC00 强制解码臂 E 的真实部署与子进程过滤边界（2026-09-22）

## 状态

`INSTRUMENT_FAILURE / DEPLOYMENT_OBSERVED_CHILD_FILTER_MISMATCH`

本轮没有命中 RC00 内部补丁或 RC06，因此不宣称解码成功；但它排除了“样本没有启动/没有部署核心”的解释，并给出了下一轮唯一应改变的观测条件。

## 输入与运行身份

- 样本上游：`<HOST_PATH>\EPT\sample\`
- 客体样本：`C:\ept_core\Hardware.exe`
- 客体样本 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- 客体样本大小：`32,671,232 bytes`
- run id：`EPT_RC00_FORCED_DECODE_20260922E`
- 参数：`-n 2 -m 1`；卡密只记录长度 `380` 和 SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`，不在本件重现明文
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_forced_decode_guest_20260922E.ps1`；bytes=`7479`；SHA-256=`94DD2D579F57434218AC13A1F45E265A8CF0293A6CBAF8AE316D42127E92B43D`
- CDB 日志外部路径：`<HOST_PATH>\HexPatch\probe\EPT_RC00_FORCED_DECODE_20260922E\cdb_stdout.txt`；SHA-256=`7ECE68A45B7416528F18933657F89E173601C98944462C122F8C4318297FC502`
- VM 基线：`qoder-armed-20260919`
- postmortem：`ept-real-decode-20260922E-postmortem`，UUID=`12b5c359-fd02-4b9c-ba22-502149e2d347`；该快照明确不是证据，只用于保留臂 E 的客体状态
- 网络：未使用网络输入；本轮只观察真实样本启动、部署和调试器事件

## 直接观察

### 真实部署发生

基线 `PRE` 中 `C:\Windows\System32\Hardware.exe` 为：

- size=`32198144`
- SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`

`POST` 中同一路径变为：

- size=`32671232`
- SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`

后者与 EPT 登记的 genB 身份一致。样本原路径 `C:\ept_core\Hardware.exe` 在前后仍保持 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`，因此这不是“原始样本被覆盖”，而是运行时向 `System32` 部署了 genB。

### 内部补丁没有实际命中

CDB 日志只显示了命令文件的输入回显和模块加载；对以下字符串做“整行独立 marker”匹配，结果全部为 `false`：

```text
INTERNAL_PATCHES_APPLIED
CHILD_PATCH_AND_BPS_ARMED
DEVICE_SEAM
RC06_ENTRY
RC06_CALL
CALLER_OUTPUT_AFTER_COPY
F060_RETURN_AFTER_CALL
SUCCESS_RETURN_EDGE
```

因此不能把命令文本中出现这些名字误读为断点命中。CDB 在 35 秒上限内未退出，脚本按 `WAIT_TIMEOUT` 收尾；收尾后客体内没有残留 `Hardware`/`cdb` 进程。

## 原因定位与下一步

本轮 CDB 只对 `cpr:EPT_*.exe` 安装了子进程补丁事件。真实卡密路径的部署目标是 `C:\Windows\System32\Hardware.exe`，不是本轮过滤器声明的 `EPT_*.exe`。因此本轮只能判为观测器未挂到真实部署子进程，不能判为 RC00 未到达、解码失败或补丁无效。

下一轮只改变一个变量：把子进程过滤改为实际部署名 `cpr:Hardware.exe`（或等价的精确 `Hardware.exe` 子进程过滤），保持以下内容不变：

- EPT 派生样本及 SHA-256；
- VM/快照基线；
- 真实卡密及 `-n 2 -m 1`；
- 两个 RC00 2-byte 补丁：`0x14078eea2: 75 5e -> EB 5E`、`0x14078ef10: 74 30 -> EB 30`；
- 不向设备接缝注入 response；
- 35 秒运行上限和共享镜像收割。

## 判定边界

本轮可升级的只有：**真实 EPT 路径完成了 genB 部署**。本轮仍没有：

- `0x14078ef42/0x14078ef47` 命中；
- `native_return == 0x1`；
- caller `+0x80` 前后缓冲；
- `changed_bytes > 0`；
- 解码后靶机副作用。

所以核心分离仍未完成。
