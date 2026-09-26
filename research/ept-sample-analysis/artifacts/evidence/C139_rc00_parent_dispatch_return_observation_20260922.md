# C139：真实 EPT 父级 dispatcher 返回点观测（2026-09-22）

## 状态

`PARTIAL / PARENT_DISPATCH_NO_CALLSITE_OR_RETURN_WITHIN_WINDOW`

H4 保持 C138 的样本、参数、快照、断网、response 注入和 RC00 两个候选补丁不变，只增加父入口调用点 `0x14235f6a8` 与返回点 `0x14235f6ad` 的一次性观察断点。运行中真实命中四段高地址 dispatcher 各两次，但两个新增 marker 都为 0；runner 在 35 秒截止时被收尾。该结果不是解码失败，也不是“dispatcher 永不返回”的证明，只说明当前有界窗口没有观察到调用点/返回点。

## 输入与运行身份

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- 原始样本：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe`
- 原始样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- 客体样本：`C:\ept_core\Hardware.exe`
- 客体样本前后 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` / `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- run id：`EPT_RC00_PARENT_RETURN_PROBE_20260922H4`
- 参数：`-n 2 -m 1`
- 卡密：长度 `380`，SHA-256 `D5B012B6B3D3495CCCC31B43B28C70ED26757667BF3367C018024CDFF626A535`；不在本件记录明文
- response 注入：`False`
- runner：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\ept_rc00_parent_return_probe_guest_20260922H4.ps1`
- runner SHA-256：`29C48355124A9B559B1CD28E2FF4A396417D3C9EFBC543181CFC28B81D60704B`
- CDB 日志：`<HOST_PATH>\HexPatch\probe\EPT_RC00_PARENT_RETURN_PROBE_20260922H4\cdb_stdout.txt`
- CDB 日志 SHA-256：`404783C007ED822A36BF61AC376AC6398F263E56D412AE89B03AD482578FC0B9`
- 运行元数据：`<HOST_PATH>\HexPatch\probe\EPT_RC00_PARENT_RETURN_PROBE_20260922H4\run_meta.json`
- 运行元数据 SHA-256：`9FC497C75D2244A30CF13A97D6932AABB5E7FF510B1AB10DA4C63DFB2DA10DCF`
- CDB 命令文件：`<HOST_PATH>\HexPatch\probe\EPT_RC00_PARENT_RETURN_PROBE_20260922H4\patch.cdb`
- CDB 命令文件 SHA-256：`87A50E086E5670828F3D43AE3AC8910DE7EF6C2F86D3A94F00B03E524B378187`
- EPT 内解析产物：`<HOST_PATH>\EPT\artifacts\captures\parent_dispatch_return_20260922H4\`
- `marker_summary.json` SHA-256：`3BF9B3AD1485F93F61DAB1E202463D745EECE682B97FB67F7B08F2ADE8367D33`
- `register_extract.json` SHA-256：`F5BFEDCD55CC922BD58617BAA54112CA7B95F612B87714CD73D8146398C68E39`
- VM 基线：`qoder-armed-20260919`
- H4 postmortem：`ept-real-decode-20260922H4-postmortem`，UUID=`98e6e5b1-d008-42f6-87d2-8c1d4f7f1824`
- 收尾：已关闭 H4 实验实例并恢复 `qoder-armed-20260919`，Guest 登录状态恢复；H4 postmortem 不是成功证据

## 观察器与新增变量

H4 的 CDB 命令文件中实际包含：

```text
bu 14235f6a8 ".echo DISPATCH_CALLSITE; r rip; r rsp; r rax; r rdx; r r8; r r9; g"
bu 14235f6ad ".echo DISPATCH_RETURN; r rip; r rsp; r rax; r rdx; r r8; r r9; g"
```

原始日志回显了这两条命令；没有出现 breakpoint 命令错误。这里的“无命中”来自 exact-line marker 解析，而不是把命令回显当作命中。

## 直接观察

由 `marker_summary.json` 对 H4 原始 CDB 日志做 exact-line 计数：

- `TARGET_ENTRY`：1 次。
- `DISPATCH_143C17FB0`、`DISPATCH_143C3DEAE`、`DISPATCH_143C30E27`、`DISPATCH_143DEAC60`：各 2 次。
- `DISPATCH_CALLSITE`：0 次。
- `DISPATCH_RETURN`：0 次。
- `MAIN_ENTRY`、`N_PARSE`、`F250`、`F060`、`CHILD_CREATE`、`DEVICE_SEAM`、RC00/RC06、caller 写回和成功返回 marker：均为 0 次。

两组 dispatcher 参数仍与 C138 相同：第一组前三段为 `RCX/R8=0x7e4`、`RDX=0x9dc70`、`R9=0x1521b0`，第二组为 `RCX/R8=0x87f`、`RDX=0x9d730`、`R9=0x1521b0`；`0x143deac60` 现场 `RCX=0x6daf15b8`。

运行元数据：`status=WAIT_TIMEOUT`、`timed_out=true`、`cdb_exit_code=null`。客体样本前后身份一致；`C:\Windows\System32\Hardware.exe` 前后仍为 genA，size=`32198144`，SHA-256=`0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8`。

## 证据解释

**直接观察**：真实 EPT 派生样本命中父入口及四段 dispatcher；调用点和返回点 marker 在 35 秒窗口内均未命中；CDB 最终由 runner 超时收尾。

**推导**：C138 所见的高地址链在本臂中仍是当前最早的可重复动态链；在现有窗口下，后续路径没有进入 `0x14235f6a8`/`0x14235f6ad` 可观测现场。

**未知**：不能区分“dispatcher 长时间/循环不返回”“返回点断点未在正确执行映射上生效”“返回前发生异常或其他控制流转移”。H4 没有异常 marker，也没有足够证据证明其中某一个是唯一原因。

**完成门槛**：本轮没有 `native_return == 0x1`、没有 `changed_bytes > 0`、没有 RC06 命中、没有 caller `+0x80` 前后缓冲，故核心分离仍未完成。

## 下一条破解式验证

在同一 EPT 派生样本和同一 VM 基线中，只改变一处：首段 dispatcher `0x143c17fb0` 第一次命中时，先撤销该断点并把首字节临时改为 `C3`，让真实 `call 0x143c17fb0` 直接返回到 `0x14235f6ad`；保留 `DISPATCH_CALLSITE`、`DISPATCH_RETURN`、main/F250/F060/RC00/RC06 观察点，不改样本文件、不改快照、不注入 response。

该实验的判别价值是：

- 若命中 `DISPATCH_RETURN` 并继续到已知业务点，说明首段保护 dispatcher 是当前控制流阻断，可继续向真实 RC00 追踪。
- 若立即异常/退出，只能说明“首段直接 `ret` 不满足当前调用契约”，不能说明真实样本解码失败。
- 若仍停在其他高地址链或无返回，则阻断点不在首段 `jmp`，需要停止继续盲补丁并重新找返回/状态边界。

本轮结论：**H4 没有把“未返回”升级为事实；它只排除了在当前 35 秒窗口内可观察到调用点/返回点的路径。下一步才进行一次可回滚的首段 `ret` 破解式区分实验。**