# C152：历史材料——伪造 response 在宿主 harness 中触发局部分支（不计目标完成）

日期：2026-09-22（2026-09-24 口径校正）
状态：`PARTIAL / HOST_HARNESS_LOCAL_BRANCH_OBSERVED / NOT_TARGET_COMPLETION`
证据范围：`host_mapped_code_runner`

## 0. 范围声明

H17 `core_h17.exe` 将 EPT 派生的 `.text/.rdata` 映射到宿主进程，并使用 forge response、受控 caller 和 synthetic 全局量运行。它没有运行外层 EPT 样本，没有自然启动真实目标进程，没有取得自然驱动 response，也没有观察 RC06 后的目标行为。

因此，本件中的 `native_return`、`c_struct_changed_bytes`、`target_reached` 等原始字段均应解释为 harness/runner 局部字段；为避免误读，本文统一使用 `harness_*` 前缀。它们不得映射为目标级 `target_native_return` 或 `target_caller_diff_bytes`。

## 1. 保留的局部观察

- out16 原始日志记录 `harness_native_return=0x1`、`harness_c_struct_diff_bytes=34`；这是受控映射代码和 forge fixture 的局部结构变化。
- out9 原始对照记录返回 `0x1` 但结构变化为 `0`，说明返回值本身不推出写回或成功行为。
- out13/out15 使用的是 284B 对照材料；其来源、有效设备会话和自然驱动语义没有在本轮闭合。
- out17 在不使用 validator 桩时于 `0x14078dce9` AV，说明宿主映射环境缺少真运行时依赖；不能把桩结果升级为目标结果。
- `0x14078ce60` 的局部 XOR 流和受控结构写回动作可作为静态/算法复核材料，但不是解码后行为证据。

## 2. 关键材料

| 运行 | response | harness_native_return | harness_c_struct_diff_bytes | 解释 |
|---|---|---:|---:|---|
| out9 | 密文回环对照 | 0x1 | 0 | 恒等回环/假成功对照 |
| out13 | 284B 对照 | 0x0 | 未测 | validator 拒绝；response 来源未闭合 |
| out15 | 284B 对照 | 0x0 | 10 | 受控结构变化，不等于目标行为 |
| out14 | forge v1 | 0x1 | 6 | fixture 分支被接受 |
| out16 | forge v2 | 0x1 | 34 | harness 局部回归，不是目标门槛闭合 |
| out17 | forge v2 | AV | — | 真 validator 在宿主映射环境缺依赖 |

out16 的 `+0x80` 内容为 harness 测试字符串 `EPT-LICENSE-GRANTED-20260922`，不是样本自然生成的 license，也不是授权成功证明。原始材料目录：`<HOST_PATH>\EPT\scratch\h17\`。

## 3. 不支持的主张

本件不能证明：真实目标进程自然到达 RC03/RC06、真实授权通过、真实驱动接受请求、自然响应存在、解码结果被目标消费者使用，或产生了文件/注册表/网络/注入/持久化/清理行为。

## 4. 当前状态

C152 仅保留为 `HOST_HARNESS_LOCAL_BRANCH_OBSERVED`。目标级实验必须在同一次真实 Guest 目标运行中取得目标 seam before/after，并继续越过 RC06 收割 post-decode 行为；C152 结果不得与其他运行拼接。

完整材料哈希及原始日志仍在本件历史运行目录；本件不改变原始材料，只纠正其证据范围和结论命名。
