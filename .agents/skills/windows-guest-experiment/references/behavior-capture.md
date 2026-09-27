# Windows 行为采集

当任务需要文件、注册表、进程等系统行为证据时，优先使用成熟行为采集工具，不要先写自制轮询脚本。

## 推荐角色

### Procmon

Procmon 是 Windows 行为观测基础工具，适合详细记录文件系统、注册表、进程/线程等事件。

### Noriben

Noriben 在 Procmon 之上自动收集、过滤并生成较易读的 runtime 行为报告。

典型用途：

```text
启动行为采集
→ 运行/交互/调试目标
→ 停止采集
→ 保存原始 Procmon 数据
→ 生成 Noriben 报告/时间线
→ 与其他 runtime 结果交叉解释
```

如果 CAPEsolo 已经提供足够的行为结果，先用 CAPEsolo；只有需要更细 Procmon 级证据或独立交叉验证时，再启用 Noriben/Procmon。

## 证据原则

- 报告是原始行为数据的解释层，不替代原始捕获。
- “没有出现在过滤后的 Noriben 报告中”不自动等于行为不存在；必要时回看 Procmon 原始数据和过滤规则。
- 行为采集可以与 debugger 同时存在，但 debugger 的干预必须单独记录。
- 不为了一次行为查询自己写文件/注册表轮询器，除非成熟工具无法观察该对象。

## 上游

- Noriben: https://github.com/Rurik/Noriben
- Procmon 属于 Microsoft Sysinternals 工具集。
