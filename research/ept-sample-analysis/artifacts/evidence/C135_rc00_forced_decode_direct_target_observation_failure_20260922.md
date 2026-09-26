# C135：RC00 强制解码臂 F 的直接部署目标观测失败（2026-09-22）

## 状态

`INSTRUMENT_FAILURE / DIRECT_DEPLOYED_TARGET_NOT_OBSERVED`

本轮不是解码失败、不是核心不存在，也不是核心分离完成。它验证了 EPT 真实部署仍发生，但即使把 CDB 子进程过滤改为实际部署名 `Hardware.exe`，仍没有获得独立的内部补丁或 RC06 命中 marker；因此不能继续把问题归因于 E 轮的过滤器名称。下一轮应停止重复 `cpr:` 过滤器变体，改用直接启动或附加到已部署目标的观测平面。

## 输入与运行身份

- 样本上游：`<HOST_PATH>\EPT\sample\`
- 客体样本：`C:\ept_core\Hardware.exe`
- 客体样本 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- 客体样本大小：`32,671,232 bytes`
- run id：`EPT_RC00_FORCED_DECODE_20260922F`
- 参数：`-n 2 -m 1`；卡密只记录长度 `380` 和 SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`，不在本件重现明文
- 响应注入：`false`
- 运行时补丁：`0x14078eea2: 75 5e -> EB 5E`；`0x14078ef10: 74 30 -> EB 30`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_forced_decode_guest_20260922F.ps1`；bytes=`7484`；SHA-256=`407E2AE56DE59D0B3CF79D9E7DD682DBFF02627BB6AEEEABF1B65933D6C9DF65`
- CDB 日志外部路径：`<HOST_PATH>\HexPatch\probe\EPT_RC00_FORCED_DECODE_20260922F\cdb_stdout.txt`；SHA-256=`A4762D76F6FC2FBB12C927AD24FBFAEC7873FE69D9A27D36CB445EB81E83E35E`
- VM 基线：`qoder-armed-20260919`
- postmortem：`ept-real-decode-20260922F-postmortem`，UUID=`2d988d43-8850-4d56-89af-bfd1d5df7016`；该快照明确不是证据，只用于保留 F 轮客体状态
- 收尾后：已恢复 `qoder-armed-20260919`，VM 为 `saved`
- 网络：未使用网络输入；本轮只观察真实样本启动、部署和调试器事件

## 直接观察

### 真实部署仍然发生

`PRE` 中 `C:\Windows\System32\Hardware.exe` 为：

- size=`32198144`
- SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`

`POST` 中同一路径变为：

- size=`32671232`
- SHA-256=`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`

后者与 EPT 登记的 genB 身份一致；`C:\ept_core\Hardware.exe` 前后仍保持同一 SHA-256。因此 F 轮再次证明：真实 EPT 路径会把 genB 部署到 `System32`，但不会改写 EPT 原始样本。

### `cpr:Hardware.exe` 仍没有形成有效内部观测

CDB 命令已改为针对 `cpr:Hardware.exe`，但日志只提供命令回显、模块加载和异常/超时上下文；以下字符串按“整行独立 marker”匹配均为 `false`：

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

运行元数据为 `status=WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`。所以不能把命令文本中出现这些名字解释成断点命中，也不能从“没有 marker”推出 RC00 未到达。

## 证据解释

E 轮已证明错误过滤 `cpr:EPT_*.exe` 可以解释 E 轮没有 marker；F 轮使用部署目标名 `Hardware.exe` 后仍没有 marker，说明“只修正过滤器名字”不是充分修复。当前更稳妥的解释是：CDB 的子进程创建/过滤观测面没有可靠地绑定到实际执行的部署目标，具体是事件时序、目标进程拓扑还是 CDB 语义尚未区分。

本轮没有获得：

- `0x14078ef42` 或 `0x14078ef47` 的可靠命中；
- `native_return == 0x1`；
- caller `+0x80` 前后缓冲；
- `changed_bytes > 0`；
- 解码后的靶机副作用。

## 路线修正

不再进行第三轮仅改变 `cpr:` 过滤字符串的重试。下一次使用新的观测拓扑：

1. 先沿真实 EPT 路径完成部署，并以 `C:\Windows\System32\Hardware.exe` 的 genB SHA-256 作为部署确认。
2. 再直接对该已部署目标启动 CDB，或附加到该目标的精确 PID；不依赖 `cpr:` 子进程过滤。
3. 在目标进程自身的模块加载/入口停点安装 `0x14078eea2`、`0x14078ef10` 两个 RC00 内部补丁及 RC06、caller `+0x80` 观测点。
4. 保持同一 EPT 派生样本、同一 `-n 2 -m 1`、同一 VM 基线、不注入 response；只有真实样本同时给出 `native_return == 0x1` 与 `changed_bytes > 0`，才升级为核心分离完成。

本轮可确认的只有：**真实部署发生；CDB 子进程观测仍未形成可用命中证据。**