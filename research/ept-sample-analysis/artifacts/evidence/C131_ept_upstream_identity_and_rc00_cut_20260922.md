# C131：EPT 上游样本身份核验与 RC00 内部切口候选（2026-09-22）

## 状态

`PARTIAL / EPT_CAPTURE_IDENTITY_CONFIRMED_SYNTHETIC_FIXTURE_EXTERNAL`

本件只记录样本上游边界、当前捕获区段身份和下一轮 RC00 动态观测条件，不证明 RC00 分离已经完成。

## 样本上游规则

- 唯一样本上游：`<HOST_PATH>\EPT\sample\`
- EPT 仓库身份清单：`<HOST_PATH>\EPT\artifacts\CHECKSUMS.sha256`
- EPT 清单记录的 genB 派生对象：`<HOST_PATH>/vmctl/out/Hardware.genB.exe`
- 清单记录的 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`
- `<HOST_PATH>\vmctl\out\Hardware.genB.exe` 当前未在宿主文件系统中发现，因此本件不声称重新读取了该源文件；以下只核对当前实验使用的捕获区段和外部 fixture 的身份与类别。

`<HOST_PATH>\HexPatch` 不是 EPT 样本上游。其 `probe\` 中的运行器、输入副本和输出目录都是派生/实验材料；名字相同不改变这个边界。

## 当前探针输入的身份核对

宿主只读核对结果如下。对 EPT 仓库内已有捕获区段，HexPatch 工作副本与 EPT 文件逐字节同哈希：

| EPT 权威捕获路径 | HexPatch 工作副本 | 结果 |
|---|---|---|
| `<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin` | `<HOST_PATH>\HexPatch\probe\stream_text.bin` | 同哈希 `5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757` |
| `<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_rdatafront.bin` | `<HOST_PATH>\HexPatch\probe\stream_rdatafront.bin` | 同哈希 `87BF94ECB38D5C0270E18AF6F031359EAD4A72E377C1068A8EF9705B182597BC` |
| `<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_rdata.bin` | `<HOST_PATH>\HexPatch\probe\stream_rdata.bin` | 同哈希 `FB63581CCC65D4DC7ADEBF5F041F7A51BC4151589C22D9494BE3437A933AC16F` |
| `<HOST_PATH>\EPT\artifacts\captures\RG2_region_0x140e00000.bin` | `<HOST_PATH>\HexPatch\probe\RG2_region_0x140e00000.bin` | 同哈希 `09D8D5DE6059679957D3B49F17B9AED6B85C48756FF8D36B41E4CE6E93044C7A` |

这四项证明的是：当前 harness 映射的代码/数据捕获物与 EPT 仓库中的对应捕获物一致；它们仍不是原始样本本身。

## 外部合成 fixture 的边界

以下两个输入不在 `<HOST_PATH>\EPT` 仓库内，也没有在 EPT 身份清单中登记为样本文件：

| 外部材料 | HexPatch 工作副本 | 类别与哈希 |
|---|---|---|
| `<HOST_PATH>\CTF\forge_caller_input_268.bin` | `<HOST_PATH>\HexPatch\probe\forge_caller_input_268.bin` | 外部历史合成 caller fixture；同哈希 `7C9293E800192A21F09FFFFD88C22DDEB9E83204FE221A128A8F4097CDCC5D6E` |
| `<HOST_PATH>\CTF\forge_license_response_284.bin` | `<HOST_PATH>\HexPatch\probe\response_284.bin` | 外部历史合成 response fixture；同哈希 `BFA525E78731BEAAA2EBF1C64E993FCD933AC43D60B7A6E3D1F61576C78B0CC8` |

它们曾被 C130 作为“伪造输入/伪造应答”使用；当前只能把它们当作**驱动 RC00 harness 的合成测试输入**。它们不能证明样本身份、真实设备响应、真实许可解码或自然样本分支。若后续需要把它们纳入 EPT 正式捕获材料，必须另建明确的 synthetic-fixture 归档并保留来源与类别，不能改名冒充样本。

## RC00 内部切口的当前证据等级

已有 EPT 证据 `C105` 记录：

- `0x14078ee9b` 调用 `0x14078db80`，并把 `RDX` 指向 RC00 栈帧中的 marker 槽 `&[rsp+0x44]`；
- marker 通过后，`0x14078ef42` 处准备 `RCX=[rsp+0x60]`；
- 原始 RC06 transform 调用位于 `0x14078ef47`；
- 随后结果被复制到 caller structure `+0x80`。

现有 `runner2.cpp` 只把 `0x14078db80` 替换为 `mov eax,1;ret`，没有同步写入 `RDX` 指向的 marker 槽。因而“validator 返回 1 后仍未进入 `0x14078ef42`”是一个有证据支持的候选解释，但目前仍不是动态确认的根因。

下一轮唯一有价值的区分动作是：在已核验的 EPT 捕获区段上，同时记录 marker 槽、`0x14078ef42` 命中和真实 `0x14078ef47` 后续输出；不再重复只改 validator 返回值的旧臂。若使用合成 fixture，结果只能标为 harness-level 证据。

## 调试器与 VM 条件

本轮已确认 <OTHER_VM_LABEL> 来宾机没有旧记录中的 `C:\ept\kdbin\cdb.exe`，也没有本地 CDB；可通过 `\\VBoxSvr\HexPatch\materials\ept\capture-20260912\real-run\recon\kdbin\cdb.exe` 读取并执行 Microsoft CDB `10.0.29617.1000 AMD64`。该工具来自 HexPatch 外部实验材料，不是样本，不改变 EPT 上游边界。当前观测脚本在启动样本前执行输入哈希门禁；门禁不通过时不得把结果记为样本阴性。

## 目标级 seam 必要条件（不是最终完成判据）

本件不改变校正后的目标方向。真实目标运行必须把字段按范围命名为：

```text
target_native_return == 0x1
target_caller_diff_bytes > 0
```

两者必须来自同一真实目标进程、同一运行的目标返回和 caller before/after；还要保留样本身份、VM/快照、运行编号、response 来源/注入点、caller `+0x80` 前后快照和清理状态。即使这些 seam 条件成立，仍必须继续越过 RC06 取得解码结果消费者和后续伪装/规避/持久化等行为证据，才能完成项目目标。使用合成 fixture 得到的 harness 命中不得升级为“真实样本已分离”。

## 限制与未决项

- 本件此前的 CDB 路径探测和哈希门禁失败均未启动样本，也没有产生新的 RC00 动态命中。
- 当前 HexPatch `probe\` 仍是未提交实验目录，不是 EPT 样本目录。
- `<HOST_PATH>\CTF\forge_*` 位于 EPT 仓库外层，属于历史合成工作材料；不得继续在文档中称为 EPT 权威输入。
- `<HOST_PATH>\EPT\artifacts\evidence\C130_decode_core_keyless_separation_final.md` 顶部撤回横幅仍是当前有效状态；旧的“已分离/真实解码”段落只能作为历史记录阅读。
