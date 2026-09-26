# C201 · 稀疏 XOR mutator 原语解码：5925 调用点的通用保护原语

日期：2026-09-26 · 数据源：child_full_recv2.dmp（recv#2 时刻全进程快照）· 脚本：`extract_xor_chain.py`

## 1. 原语语义（0x1405d5f80 全解码，此前误标为"日志器"）

```
f(uint enable_cl, uint count_edx, ptr index_table_r8, ptr buffer_r9, uint xor_imm@[rsp+0x20])
  for i in 0..count_edx:
      idx = index_table[i]            // dword 索引表选择目标位置
      buffer[idx] ^= xor_imm          // 对选中 dword 异或立即数
```

**非日志器**——是保护壳的通用**稀疏 XOR 缓冲变异原语**：每个调用用索引表选中缓冲中的若干 dword，异或一个状态立即数。

## 2. 规模

- 全映像 **5925 个调用点**（0x140000000-0x144000000 内全扫描）——保护壳的全部状态转移/数据变换都构建在该原语上
- 每调用点三元组 (count_edx, index_table_ptr, xor_imm) 已提取 → `mutator_triples.json`（5925 条）
- idx=5 handler 的调用链：0xf3c/0x6f84 等此前误读的"事件 ID"实为 **XOR 立即数**；"0x3188 帧缓冲引用"实为缓冲指针参数

## 3. 对 103B 帧体解密的推论

1. 103B 请求体 = 发送侧经一串 sparse-XOR 步骤变换的产物；**XOR 可逆** → 接收侧（我们的响应构造）= 以相反顺序重放同链
2. 链的提取要素已全部就位：5925 个 (count, table_ptr, imm) 三元组 + 索引表内容（dmp 内存可读）
3. 剩余工作 = 链的**排序与条件**（哪些步骤作用于 103B 缓冲、执行顺序、分支条件）——需按调用点地址序 + 缓冲指针匹配过滤子链

## 4. 方法论反思

1. **原语语义必须解码一次**：此前把 mutator 误读为"日志器"（因为它出现在状态边界且带"事件号"形态的立即数）——直到全解码才见真容。教训：对反复出现的调用原语，先完整反编译其函数体，再大规模标注调用点。
2. **标注方法论转向**：从"锚点标注"转为"原语追踪"——254 个"日志锚点"重新解释为"254 个变换步骤"。
3. XOR 原语 = 可逆变换 ⇒ 只要链序可恢复，全部保护态变换可离线重放（无需 VM）。

## 5. 台账

`target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）。
新增：`mutator_triples.json`（5925 条）、`extract_xor_chain.py`。
