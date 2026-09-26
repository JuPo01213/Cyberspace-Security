# C175：C173 Guest 内 caller/injection harness 回归（不计目标完成）

日期：2026-09-24
RUN_ID：`EPT-C175-COREHARNESS-01`
状态：`PARTIAL / CALLER_INJECTION_HARNESS_ONLY / NOT_TARGET_COMPLETION`
证据范围：`caller_injection_harness`

## 0. 先读边界

本轮没有启动 EPT/Hardware 真实样本，没有打开目标设备，没有加载授权，没有取得自然驱动 response，也没有观察 RC06 后目标行为。C173 Guest 和 PowerShell Direct 通信闭环只证明测试脚手架能运行，不能证明目标样本已运行。

本轮结果只能说明：在 Guest 中将 genB 恢复 `.text` 映射后，使用 forge fixture 的 caller/injection harness 能复现局部 validator/transform/写回路径。它不满足 AGENTS.md 的目标级条件，也不构成真实授权成功、自然解码完成或恶意行为结论。

## 1. 投递与身份

Host 打包 `python313.tar.gz`（17.9 MB / 2123 条目）经 PowerShell Direct 送达 Guest，解包为 `C:\ept_obs\python\3.13.12\python.exe`（Python 3.13.14），`ctypes` 校验 `CTYPES_OK 8`。harness、捕获件和 forge 件的 Guest SHA-256 与 Host authority 一致，证据等级为 `HOST_VERIFIED`。

这些哈希只证明测试材料完整，不证明样本目标运行。

## 2. harness 结果（现行字段命名）

C175 的原始收割 JSON 保留为不可变历史材料，生成时仍含未加前缀字段；本轮不改写 raw。现行 `core_local_decode_harness.py` 已将新输出固定为 `evidence_scope=caller_injection_harness` 与 `harness_*` 字段，`derive.py` 对旧 raw 只做内存归一化，不把任何字段升级为 `target_*`。

| 模式 | harness_rc03_branch | harness_validator_rax | harness_decoded_output_bytes | harness_caller_output_written |
|---|---|---|---:|---|
| self-test | 正/负/mismatch 控制符合预期 | 0x1（正例） | 仅作控制向量 | 仅作控制向量 |
| `--input forge_caller_input_268.bin` | `RC06 success` | `0x00000001` | 268 | true |
| `--response forge_license_response_284.bin` | `RC06 success` | `0x00000001` | 268 | true |

两个 forge 件在该 harness 中形成内部 round-trip 一致性：response-shaped fixture 经局部 transform 后得到已知 268B 输入。这不是自然设备 response，也不是目标业务明文或授权状态。

Guest harness 子进程 PID：self-test=2788、input=7344、response=3084；共享 PPID=5412；`ppid_live=null`。这些 PID/PPID 只归因于 harness。

## 3. caller 快照的正确命名

收割的 396B caller 快照在 harness 自构造的 before/after 对照中有 14 个变化字节，均落入 `[0x80,0x80+0x10C)`，且 after 的输出区等于 harness decoded output。这里应记录为：

```text
harness_caller_diff_bytes=14
harness_decoded_output_bytes=268
harness_caller_output_written=true
```

不得把这些字段命名或映射为真实目标的 `target_caller_diff_bytes` / `changed_bytes`。

## 4. 审查结论

C175 的有效结论是：`caller_injection_harness` 在 C173 Guest 可复现局部用户态 transform/validator/写回路径。无以下目标级证据：

- 真实 EPT/Hardware 目标进程 PID/PPID；
- 真实目标进程的 `target_native_return` 和 caller before/after；
- 自然或明确注入的 I/O response 与目标调用的同一运行归因；
- RC06 之后的消费者、文件/注册表、网络、驱动/组件释放、注入、持久化、规避或清理行为。

当前目标状态仍为：

```text
INCOMPLETE / REAL_SAMPLE_POST_DECODE_BEHAVIOR_UNOBSERVED
```

## 5. 可复核材料

- 收割件：`artifacts/evidence/C175_coreharness/raw/`
- Host 状态：`runs/EPT-C175-COREHARNESS-01/`
- 相关方法：`method/harnesses/core_local_decode_harness.py`
- 历史局部边界：C120、C121、C152
