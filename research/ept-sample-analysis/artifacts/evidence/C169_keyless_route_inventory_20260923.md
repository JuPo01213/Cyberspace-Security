# C169：无密钥核心路线材料清点（2026-09-23）

## 状态

INVENTORY_ONLY / NOT_EXECUTED_ON_WIN10_CONTROL

本件只清点一条独立的无密钥核心复现路线，不把它定义为外层 EPT 正常运行，也没有在 <OTHER_VM_LABEL> 中投递或执行任何材料。

## 为什么不走外层 EPT GUI

项目没有可输入的明文卡密。C138/C139 只登记历史卡密长度 380 与 SHA-256，不记录明文；C165 的运行参数为 [REDACTED]。因此外层 EPT GUI 最多能启动到卡密输入界面，不能继续完成正常流程。

## 可复用材料

| 材料 | SHA-256 | 作用/边界 |
|---|---|---|
| <HOST_PATH>/CTF/forge_caller_input_268.bin | 7C9293E800192A21F09FFFFD88C22DDEB9E83204FE221A128A8F4097CDCC5D6E | 268-byte synthetic caller input |
| <HOST_PATH>/CTF/forge_license_response_284.bin | BFA525E78731BEAAA2EBF1C64E993FCD933AC43D60B7A6E3D1F61576C78B0CC8 | 284-byte synthetic response-shaped input |
| artifacts/captures/stream_C6/stream_text.bin | 5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757 | recovered genB .text, 8,257,536 B |
| artifacts/captures/stream_C6/stream_rdatafront.bin | 87BF94ECB38D5C0270E18AF6F031359EAD4A72E377C1068A8EF9705B182597BC | recovered data region, 1 MiB |
| artifacts/captures/stream_C6/stream_rdata.bin | FB63581CCC65D4DC7ADEBF5F041F7A51BC4151589C22D9494BE3437A933AC16F | recovered data region, 256 KiB |
| artifacts/captures/RG2_region_0x140e00000.bin | 09D8D5DE6059679957D3B49F17B9AED6B85C48756FF8D36B41E4CE6E93044C7A | recovered data region, 4 MiB |

## Code boundaries

- `core_predevice_harness.py` maps the captured regions at preferred addresses and calls local transform/state/validator stages. Its own docstring says it never starts Hardware.exe, loads authorization state, or performs I/O.
- `core_local_decode_harness.py` models the user-mode success/decode seam. Its `--input` mode constructs a synthetic response; its `--response` mode consumes a supplied response-shaped buffer. It does not open a device, start Hardware.exe, load authorization, or perform network I/O.
- `scratch/h17/runner_h17.cpp` is the C152 host harness. It uses mapped captures, controlled stubs, and optional response injection; its result is host-harness evidence, not Guest outer-EPT evidence.

## Prior-result boundary

C130 is a prior VM-side proof of a keyless decoder route. C152 is a prior host-harness proof for a forged response. Neither establishes that the outer EPT GUI ran normally, and neither is being combined with a future Guest run.

## Next gate

Do not launch `EPTSample` with `-Launch`. If the user explicitly selects the independent keyless-core route, first restore GuestControl and data collection on <OTHER_VM_LABEL>, then create a new run id and separately label the result as a core-harness experiment. Otherwise the normal EPT path remains blocked on the absent plaintext card key.
