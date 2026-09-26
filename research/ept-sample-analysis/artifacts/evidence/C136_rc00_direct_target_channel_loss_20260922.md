# C136：RC00 直接目标路线的客体通道失活（2026-09-22）

## 状态

`INSTRUMENT_FAILURE / CHANNEL_LOST_AFTER_OUTER_LAUNCH`

本轮没有进入直接 CDB 阶段。客体只完成样本身份、CDB 身份和 `PRE` 收集，随后在外层真实样本启动后失去 Guest Control/心跳；因此本轮不能判定部署是否完成，不能判定直接目标是否可执行，也不能判定 RC00 分支阴性。

## 输入与运行身份

- 样本上游：`<HOST_PATH>\EPT\sample\`
- 客体样本：`C:\ept_core\Hardware.exe`
- 客体样本大小：`32,671,232 bytes`
- 客体样本 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_DIRECT_TARGET_20260922G`
- 参数：`-n 2 -m 1`；卡密只记录长度 `380` 和 SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`，不在本件重现明文
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_direct_target_guest_20260922G.ps1`；bytes=`10623`；SHA-256=`87B3889B100B299213AEC6C31B79E2C42A42A01E83E0078EED7E5B963908C97A`
- mirror runtime log：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DIRECT_TARGET_20260922G\mirror_runtime.log`；SHA-256=`139D77CBF9B0C012AA7E668CAD40E7C0682BDACB6445ECFD7F8B9DA922ED16CF`
- `PRE` 状态：`<HOST_PATH>\HexPatch\probe\EPT_RC00_DIRECT_TARGET_20260922G\pre_state.json`；SHA-256=`5AFB147DFEDEDD0C153BE936AF6D1D50DDDE8B7A5C91990DCD218E57BF493A1B`
- CDB：客体本地 SHA-256=`5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67`
- VM 基线：`qoder-armed-20260919`
- postmortem：`ept-real-decode-20260922G-postmortem`，UUID=`b479f453-5a9a-4bd5-80d1-07bfd6dc26f6`；该快照明确不是证据，只用于保留 G 轮失活现场
- 收尾后：已恢复 `qoder-armed-20260919`，VM 为 `saved`

## 直接观察

G 轮 guest log 依次记录：

```text
BOOT|run_id=EPT_RC00_DIRECT_TARGET_20260922G|deployment_deadline_sec=30|direct_cdb_deadline_sec=35|response_injection=false
IDENTITY|sample_size=32671232|sample_sha256=CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7|key_chars=380|key_sha256=D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535
STATE|PRE|targets=7|temp_matches=16
CDB|...|sha256=5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67
OUTER_LAUNCH|pid=8664|args=-k[redacted] -n 2 -m 1
```

其后没有产生：

- `DEPLOY_OBSERVED`；
- `CLEAN_BEFORE_DIRECT`；
- `DIRECT_LAUNCH`；
- `CDB_DONE`；
- `POST` 状态；
- 任何 CDB 输出或 RC00/RC06 marker。

独立的 Guest Control 进程查询也在相同时间窗内卡住。VirtualBox `VBox.log` 记录 `vmmDevHeartbeatFlatlinedTimer: Guest seems to be unresponsive`，随后宿主按边界强制断电。该记录证明的是客体/仪器通道失活，不证明样本业务结果。

## 证据解释

这轮没有验证到 EPT genB 已写入 `System32`，因为没有 `POST`；E/F 轮已经独立验证过该部署动作，但不能把 E/F 的部署结果冒充为 G 轮结果。G 轮也没有启动直接 `System32\Hardware.exe` 的 CDB，所以“直接目标路线是否命中 RC00”在本轮仍是未知。

本轮没有获得：

- `0x14078eea2` 或 `0x14078ef10` 的一次性补丁命中；
- `native_return == 0x1`；
- caller `+0x80` 前后缓冲；
- `changed_bytes > 0`；
- 解码后的靶机副作用。

## 路线调整

G 轮排除了“先让外层样本脱离调试器运行，再依靠 Guest Control 在部署后接管”的低可靠方案；不再沿这条路径等待。下一轮应让调试器从外层启动时就接管，并取消 `cpr:` 子进程过滤依赖：使用 `.childdbg`/模块加载事件和全局 deferred breakpoint，在真实子进程加载后直接于 `0x14078eea2`、`0x14078ef10` 的首次执行点做一次性补丁。这样不需要客体在未调试状态下先运行到通道失活，也能区分“子进程未创建”“代码未解包到切口”和“切口命中后 RC06 未写回”。

本轮可确认的只有：**直接目标路线尚未被测试；G 轮首先暴露的是外层未调试启动导致的客体通道失活。**
