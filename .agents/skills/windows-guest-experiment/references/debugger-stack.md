# Windows 远程调试栈

当成熟分析 runtime 的内置 debugger 足够回答问题时，优先使用它。只有明确缺少必要调试能力时，才补 Microsoft Debugging Tools for Windows。

## 优先级

```text
现有 runtime debugger 足够
→ 直接使用

现有 runtime 缺少必要能力
→ DbgEng / WinDbg / CDB

需要 Host 控制 Guest 用户态进程
→ 优先考虑 DbgSrv + Host smart client / DbgEng
```

不要因为熟悉 CDB 文本命令，就把成熟 remote-debug 重新包装成 PowerShell 启动 + 日志重定向 + marker parser。

## DbgEng

Microsoft 的 `DbgEng.dll` 是 WinDbg、CDB、NTSD、KD 的核心 debugger engine，可程序化：

- 获取 target；
- 设置断点；
- 监控事件；
- 查询符号；
- 读写内存；
- 控制线程和进程。

如果需要给 Agent 暴露稳定的语义 debugger API，应优先在 DbgEng 之上做薄桥接，而不是解析 WinDbg/CDB 的人类文本输出。

## DbgSrv

用户态跨机器调试可使用 `dbgsrv.exe` process server：

```text
Host
  debugger / DbgEng smart client
        ↓
Guest
  DbgSrv
        ↓
  target process
```

微软要求 client debugger binaries 与 Guest DbgSrv 来自同一版 Debugging Tools for Windows。

## 调试生命周期

一次需要后续自然行为的实验至少保证：

```text
attach/launch
→ 实际 breakpoint hit
→ 读取所需状态
→ 执行必要且已记录的 intervention
→ 删除临时 breakpoint
→ 确认 observer 状态有效
→ continue/detach
→ 再解释后续行为
```

configured breakpoint、命令回显或旧 debugger state 都不能当作真实 hit。

## 边界

- DbgEng/DbgSrv 是调试基础设施，不负责样本 job、artifact pipeline 或 VM 回滚。
- 如果已登记 runtime 已经可靠完成相同 debugger 动作，不重复建设第二套控制面。
- remote debugging 本身扩大攻击面，应只在隔离分析网络中启用。

## 上游

- Debugger Engine Overview: https://learn.microsoft.com/windows-hardware/drivers/debugger/debugger-engine-overview
- Process Servers: https://learn.microsoft.com/windows-hardware/drivers/debugger/process-servers--user-mode-
- Remote Debugging Using WinDbg: https://learn.microsoft.com/windows-hardware/drivers/debugger/remote-debugging-using-windbg


