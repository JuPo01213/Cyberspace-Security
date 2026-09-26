# C200 · 256 handler 全枚举完成 + 标注提取待修正

日期：2026-09-26 · 数据源：child_full_recv2.dmp · 脚本：`enumerate_handlers.py`、`annotate_handlers.py`

## 1. 完成

- **0x140FA18F0 表全部 256 个小索引 handler 解析成功**（handler_enum.json：idx → handler VA，idx=5→0x14014731C 与 C193 自洽）
- handler 地址分布覆盖 0x140100000-0x140180000 协议区（与 C193 锚点法互证）

## 2. 待修正（下一步第一步）

- 事件 ID 标注提取为空：logger 调用的栈立即数编码形式（`mov dword ptr [r10+0x20], 0x222f` 的实际机器码编码——C7 44 24 20 xx xx xx xx 或经寄存器中转）与我的 op_str 正则不匹配
- XOR 字节循环检测为空：handler 内无内联变换循环 ⇒ **解密在 handler 调用的子函数中**——需沿 call 目标一层
- 修正路径：①用 run 76 实证过的编码（`C7 44 24 20` 前缀）做字节级扫描而非 op_str 正则；②对每个 handler 的 call 目标递归一层，在子函数中找变换循环

## 3. 台账

`target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）。
新增：handler_enum.json（256 idx→VA）、handler_annotations.json（初版）。
