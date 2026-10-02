# 分支分离参考

用于回答“两个执行分支如何被当前输入区分”，不负责选择 VM 或发明通信实现。

## 必填问题

先写出 A/B 两个分支的共享前缀、判别状态、各自独有的 marker/action，以及“未到达”的判定。分支选择、分支专属动作和进程/文件/网络结果分别记录，不能用后果反推分支已经进入。

## 坐标与静态表

在使用自定义流、内存转储或 Ghidra 程序前，独立解析 `MZ/PE/e_lfanew/ImageBase/节表`，明确 `file_offset`、`rva`、`section_va` 和 `stream_offset` 的公式；至少用三个绝对地标做 round-trip 校验。统一页偏移、错误的 PE 头或线性反汇编错位先归类为仪器候选问题。

静态分支表至少包含：predicate、指令范围、直接/间接转移、分支独有调用/数据、覆盖范围和未覆盖区段。FLOSS、capa、YARA 只用于找锚点，不证明分支执行。

## 动态分类

每轮只改一个变量并选择一个主观察器。结果至少使用：

- `VALID_A` / `VALID_B`：判别器和分支专属证据都闭合；
- `VALID_NOT_REACHED`：运行有效但未到达判别点；
- `VALID_UNOBSERVABLE_ON_THIS_BASE`：已知当前底座/范围无法观察；
- `INVALID_INSTRUMENT`：通信、调试器、收割或身份链无效。

超时、断连、空输出和缺少 artifact 不得直接写成样本阴性。

