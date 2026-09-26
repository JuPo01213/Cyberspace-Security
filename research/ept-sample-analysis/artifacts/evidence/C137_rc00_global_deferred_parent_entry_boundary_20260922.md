# C137：RC00 全局 deferred breakpoint 的父入口边界（2026-09-22）

## 状态

`PARTIAL / PARENT_ENTRY_OBSERVED_CHILD_EVENT_NOT_SEEN`

本轮不是 Guest Control 前置失败：CDB 真正启动并命中样本父进程入口 `0x14235f67b`。在 35 秒有界窗口内没有观察到子进程创建事件、RC00/RC06 切口或部署变化；该结果只约束本次真实输入和本次运行窗口，不把“父入口后未继续”升级成核心不存在或解码失败。

## 输入与运行身份

- 样本上游：`<HOST_PATH>\EPT\sample\`
- 客体样本：`C:\ept_core\Hardware.exe`
- 客体样本大小：`32,671,232 bytes`
- 客体样本 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_GLOBAL_CHILD_BPS_20260922H2`
- 参数：`-n 2 -m 1`；卡密只记录长度 `380` 和 SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`，不在本件重现明文
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_global_child_bps_guest_20260922H2.ps1`；bytes=`7847`；SHA-256=`7FA9171B7FE2289C9B5E5D08F9D4C217A0655DD1A7D009555B55290557BEA638`
- guest 执行路径：`\VBoxSvr\HexPatch\probe\EPT_RC00_GLOBAL_CHILD_BPS_20260922H2.ps1`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_GLOBAL_CHILD_BPS_20260922H2\cdb_stdout.txt`；SHA-256=`9C2D72621DCADADD8DABFC67896A559A6EADEBACE01589E38F5556717C625147`
- 运行元数据：`<HOST_PATH>\HexPatch\probe\EPT_RC00_GLOBAL_CHILD_BPS_20260922H2\run_meta.json`；SHA-256=`DF4973C0A7FDE306B047ACB4A06355969184DF1B9F3F4CFFDD61DE5654960183`
- CDB 命令文件：`<HOST_PATH>\HexPatch\probe\EPT_RC00_GLOBAL_CHILD_BPS_20260922H2\patch.cdb`；SHA-256=`F17516F575110E59649DAF7F12AA9ED2C08E5BA7A9E1592D82C49A329F96F686`
- VM 基线：`qoder-armed-20260919`
- postmortem：`ept-real-decode-20260922H2-postmortem`，UUID=`a70c77cb-3b11-4354-bb23-5d8f8049a75a`；该快照明确不是证据，只用于保留 H2 客体现场
- 收尾后：已恢复 `qoder-armed-20260919`，VM 为 `saved`
- 响应注入：`false`

## 直接观察

### CDB 观测器实际工作

CDB 原始日志包含独立 marker：

```text
TARGET_ENTRY
```

该 marker 由 `bu 14235f67b` 的命令产生，说明本轮 deferred breakpoint 已在真实样本父进程中解析并执行；这不是命令文件回显误判。

同一日志中没有以下独立 marker：

```text
CHILD_CREATE
F060_RETURN_AFTER_CALL
RC06_ENTRY
RC06_CALL
CALLER_OUTPUT_AFTER_COPY
SUCCESS_RETURN_EDGE
DEVICE_SEAM
RC00_VALIDATOR_BRANCH
INTERNAL_PATCH_1_APPLIED
RC00_MARKER_BRANCH
INTERNAL_PATCH_2_APPLIED
```

### 真实部署没有发生在本轮可见状态中

`PRE` 与 `POST` 中 `C:\Windows\System32\Hardware.exe` 均保持基线 genA：

- size=`32198144`
- SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`

runner 元数据中的样本 `C:\ept_core\Hardware.exe` 前后身份仍为 EPT genB SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`。本轮没有把 `System32` 目标升级为已部署。

运行状态为 `WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`；脚本保留了 CDB 日志和前后状态后结束。

## 证据解释

C137 把观测边界从“CDB 没有挂上”推进到：**CDB 已挂到父进程入口，但真实父进程在当前 35 秒窗口没有产生可见 child event 或进入已知核心切口。** 由于没有 child event，`cpr:` 过滤器已经不是本轮变量；由于没有 RC00 marker，不能把内部补丁未生效解释成 RC00 失败。

本轮没有获得：

- `native_return == 0x1`；
- `changed_bytes > 0`；
- caller `+0x80` 前后缓冲；
- 解码后的靶机副作用。

## 下一条最小区分变量

下一轮保持 EPT 样本、输入、快照、无 response 注入和 RC00 两个一次性补丁不变，只在 CDB 中增加父进程上已知 runtime dispatcher 与自然参数路径的观测点：`0x143c17fb0`、`0x143c3deae`、`0x143c30e27`、`0x143deac60`、`0x1407a4b90`、`0x1407a55ae`、`0x14078f250` 和 `0x14078f060`。目的不是先打高地址补丁，而是确认父进程停在入口、runtime dispatcher、参数解析还是 F250/F060 之前，从而选择下一处最小破解切口。

本轮结论：**全局 deferred breakpoint 路线已验证可观测父入口；当前核心阻断位于父入口之后、子进程/RC00 之前。**
