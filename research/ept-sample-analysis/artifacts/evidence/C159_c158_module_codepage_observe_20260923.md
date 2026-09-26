# C159：C158 目标映像地址与代码页观察（2026-09-23）

## 结论

状态：**PARTIAL / IMAGE_MAPPING_CONFIRMED / CANDIDATE_ADDRESSES_ZERO_FILLED / FOUR_DISPATCHERS_OBSERVED / WAIT_TIMEOUT**。

C158 在 CDB 入口事件处确认当前调试映像为 Hardware.exe，映像基址 0x140000000，结束地址 0x143f83000，ImageSize 0x03F83000，路径 C:\ept_core\Hardware.exe。两处候选地址因此都位于 Hardware 映像范围内：

- 0x14078eea2 - 0x140000000 = RVA 0x78eea2；入口时 8 字节为全零，反汇编为 add byte ptr [rax],al。
- 0x14078ef10 - 0x140000000 = RVA 0x78ef10；入口时 8 字节为全零，反汇编为 add byte ptr [rax],al。

这与既知 sanctioned 指令字节 75 5E 和 74 30 不同；因此 C158 不做写入是正确决策。当前结果确认的是“两个目标地址落在实际 Hardware 映像内、但入口时内容为零填充”，**不是授权补丁成功、代码页业务执行或目标修改机制闭环**。

## 运行身份

| 项 | 值 |
|---|---|
| run id | EPT_RC00_CODEPAGE_OBSERVE_20260923C |
| VM | <OTHER_VM_LABEL>，UUID 8d0b85c0-ed29-47c7-9fe1-21bc706a057a |
| 快照 | qoder-armed-20260919，UUID ad2c4f36-3640-432e-8ac8-39a7ecb15b39 |
| Guest CDB 目标 | C:\ept_core\Hardware.exe |
| Guest 文件 SHA-256 PRE/POST | CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7 |
| CDB SHA-256 | 5F54ABAFCA3AE5638BBF807D402FABB350A64575C1DFA9FBFC7F5732DF5BEE67 |
| deadline / 结果 | 120 秒 / WAIT_TIMEOUT；CDB exit code 未取得 |
| 实验方式 | 已有 VM 内脚本投递与 GuestControl 启动；本轮没有对目标地址写入机器码 |

C158 开始前 E: 可用 274.02 GiB；结束后核对 273.15 GiB。之后的只读复核为 273.31 GiB；没有创建新快照。runner 启动时 GuestControl 一度发生服务暂未就绪；等待/短探针后恢复，脚本投递与后续 GuestControl 探针成功。实验后查询时 VM 仍为 running、快照未变；本证据写成后 VM 仍可能由用户管理，不在本件之外擅自关机或回滚。

## 原始 CDB 运行证据

原始日志：<HOST_PATH>\HexPatch\probe\EPT_RC00_CODEPAGE_OBSERVE_20260923C\cdb.log。

独立运行行（不是 0:000> 命令回显）：

| 行 | 观察 |
|---:|---|
| 71 | [C158_ENTRY]：入口断点动作运行 |
| 73、75 | Hardware 映像区间 0x140000000..0x143f83000；lm 与 lmv 均给出相同范围 |
| 76–81 | lmv 报告映像路径 C:\ept_core\Hardware.exe、ImageSize 03F83000 |
| 84–90 | RVA 0x78eea2 全零；连续解码为六条 add byte ptr [rax],al |
| 92–98 | RVA 0x78ef10 全零；连续解码为六条 add byte ptr [rax],al |
| 100–103 | 四个 dispatcher 独立命中：143C17FB0、143C3DEAE、143C30E27、143DEAC60 |

其他业务运行 marker（MAIN_ENTRY、N_PARSE、F060、RC06、caller 输出、SUCCESS_RETURN_EDGE）没有独立运行行。CDB 在命令文件里确实为这些地址设置了 breakpoint，但其命令回显不表示断点实际命中。

当前记录只证明入口动作在这些地址执行过读/反汇编；没有证明它们是可执行页、CPU 执行过这两段零字节，或 dispatcher 与 RC00/F060 之间的因果关系。C158 观测脚本没有写入补丁；也没有取得内存保护属性、模块装载时原始节映射、执行跟踪或调用栈。

## 通信与数据面结果

本轮使用已落地的三平面模式：GuestControl 为控制面；共享目录/Guest spool 保存 runner.log、cdb.log、run.cdb、run_meta.json、pre_state.json、post_state.json；完成状态来自 deadline 与完整收割的本地状态，而不是 GuestControl 命令本身。

- GuestControl 首次健康探针曾成功；服务随后有一次短暂 not-ready，后来二次探针通过。
- 脚本通过 lab.ps1 -Action copyto 投递；简单路径启动 runner。没有把复杂实验内容拼成多层内联命令。
- CDB 在 120 秒 deadline 到达，runner 记录 WAIT_TIMEOUT；共享数据面仍提供完整原始日志和 PRE/POST。
- CDB 输入卡材料未写进该证据件；cdb.log 里的命令行值已脱敏。
- runner 的 run_meta.markers 是对全文文本做子串匹配，所以 C158 中保存为空对象/无事件计数，不作为命中依据。独立事件由原始 cdb.log 逐行确认。

这正是历史通信优化要求的证据边界：控制面异常或超时只分为 CONTROL_NOT_READY/WAIT_TIMEOUT 等仪器状态，不能解释为授权失败；数据面已保留时应优先基于 spool/log 收割，不重跑以“再看一次”。

## 与既有结论的关系及下一步

- C152：宿主 mapped-code/harness 级记录了 `harness_native_return=0x1` 和 `harness_c_struct_diff_bytes=34`。这是受控 fixture 分支观察，不是已证实的真实授权通过，也不是 VM 目标进程证据。
- C156：入口之前对候选地址写后读回得到 00 00 → EB 5E、00 00 → EB 30；时序过早，不能认定为业务补丁。
- C157：入口后同样读到候选位置原值为 00 00，并执行写入/读回；这不等于目标指令补丁。其独立事件有四个 dispatcher；run_meta marker 列表污染已在 C157 证据中记录。
- C158：未写任何补丁，确认入口现场两个候选 RVA 仍是零填充；对这两个位置再次写入不会推进结论。

下一次代码分析应先静态映射 genB Hardware PE 的节表/RVA 内容和受保护代码重定位，再选择真正的授权相关可执行指令边界；动态侧只观测该位置的映像/内存来源、页保护与实际 RIP 命中。不要复用这两个零填充地址作为补丁位置，不要用“dispatcher 命中”代替 RC00/F060/caller 闭环。若继续部署/伪装行为分析，用受限 ETW/ProcMon 追踪文件写入者及进程树。

项目目标级 seam 仍未取得：同一次目标运行中的 `target_native_return == 0x1`、`target_caller_diff_bytes > 0` 和 caller `+0x80` 前后缓冲；即便取得，还必须继续收割 RC06 后自然行为。

## 可复核材料

- runner：<HOST_PATH>\HexPatch\probe\EPT_RC00_CODEPAGE_OBSERVE_20260923C.ps1
- 原始运行目录：<HOST_PATH>\HexPatch\probe\EPT_RC00_CODEPAGE_OBSERVE_20260923C\
- runner.log、cdb.log、run.cdb、run_meta.json、pre_state.json、post_state.json
- 通信操作规范：<HOST_PATH>\EPT\method\COMMUNICATION_PLAYBOOK.md
- C157 对照：artifacts/evidence/C157_entry_patch_readback_20260923B.md
