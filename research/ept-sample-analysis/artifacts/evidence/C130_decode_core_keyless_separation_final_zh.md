# C130：历史材料——“无密钥分离/真实解码”旧结论（已撤回）

日期：2026-09-22（2026-09-24 口径校正）
状态：`RETRACTED / HISTORICAL / NOT_TARGET_COMPLETION`
证据范围：`host_mapped_code_runner`、`offline_reference_synthetic_response`

## 0. 撤回声明

本文原先把“伪造 response 通过受控 validator”“映射代码段 runner 产生输出”写成“目标完成、真实解码和授权可分离”。该结论不成立，现仅作为历史材料保留，不再是当前结论或完成证据。

本文出现的 `RC06 success`、`native_return`、输出哈希、forge response 等字段，均不得替代真实 EPT 目标进程同一次 Guest 运行中的 `target_native_return`、`target_caller_diff_bytes` 及 RC06 后自然行为。

## 1. 仍可引用的有限事实

1. 离线参考实现可以从已知 268B 输入构造 284B 的 response-shaped fixture；validator/reference 模型可以接受该 fixture 并执行第二次 transform。这只证明参考模型和 fixture 内部自洽，不证明真实设备 response、真实授权或自然样本路径。
2. 宿主 mapped-code runner 曾把恢复的 `.text` 映射到固定地址并调用受控 caller；输入、全局量、外部边界和部分后续跳转均由 runner 控制，因此不是外层样本自然启动的目标进程。
3. 原始 C130 runner 日志同时出现 `target_reached=true` 和 `native_return=0x0`；设备/授权边界由 stub 控制。“命中 stub”不能解释为驱动接受请求或真实解码成功。
4. 输出与输入不同、或 transform 可以往返，最多说明受控变换代码/参考模型的性质，不说明解码后行为或伪装行为。

## 2. 原结论为何不能成立

- `make_request(input)` 产生的是 synthetic response-shaped fixture，不是自然驱动返回。
- `0x141757acd` 被 stub/短路时，没有有效设备句柄、IOCTL 语义或目标驱动响应证据。
- mapped-code runner 自行构造 caller、输入、全局量和控制流，不能证明外层 EPT/Hardware 目标自然走到同一业务路径。
- 原轮没有在真实目标进程中继续追踪 `caller+0x80` 的消费者，也没有取得 RC06 后的进程、文件、注册表、网络、注入、组件释放或清理行为。
- 因而“绕过授权后仍能真实解码”“伪造它即破解”“两类目标均已完成”等表述全部撤回。

## 3. 当前替代结论

当前只保留：用户态局部 transform/validator/RC06 写回 seam 已被静态和受控实验部分解释；真实样本目标仍为：

```text
INCOMPLETE / REAL_SAMPLE_POST_DECODE_BEHAVIOR_UNOBSERVED
```

目标级实验必须在真实样本 Guest 进程内进行。若为研究 post-decode 路径而在已确认的 DeviceIoControl 边界注入 response，必须标注：

```text
evidence_scope=real_sample_guest_run_injected_io
```

这表示真实目标进程自己的 RC00→RC03→RC06 代码执行，但 response 不是自然驱动产物；运行还必须继续越过 RC06，不能在解码点或首个后行为点截断。最终完成要求同一次运行取得解码结果消费者和后续伪装、规避、持久化等自然行为证据。

## 4. 原始材料

原 C130 材料、运行日志、forge 文件和代码段捕获物保留在原路径；使用时必须同时读取本撤回说明，不得单独引用旧标题或旧结论。相关边界证据：

- `C120_continuous_native_decode_execution_20260921.md`
- `C121_pure_python_local_decoder_closure_20260921.md`
- `C131_ept_upstream_identity_and_rc00_cut_20260922.md`
- `C152_forged_response_native_accept_20260922.md`
- `C175_coreharness_vm_closure_20260924.md`
