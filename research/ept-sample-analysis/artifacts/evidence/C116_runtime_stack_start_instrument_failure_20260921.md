# C116：轻量栈现场臂的 VirtualBox 启动会话失败（2026-09-21）

## 状态

`INVALID_INSTRUMENT / VM_SESSION_CLOSED_BEFORE_START`

## 范围

本臂原计划复用 C114 的样本、快照、断网、命令行和 child 观察，只把 `kv` 替换成 `RSP + dq @rsp L8 + u` 的轻量现场。脚本经过 ASCII/PowerShell 语法检查，但没有进入客体执行阶段。

## 直接结果

VirtualBox 在 `startvm <OTHER_VM_LABEL> --type headless` 阶段返回：

```text
VBoxManage.exe: error: The VM session was closed before any attempt to power it on
VBoxManage.exe: error: Details: code E_FAIL (0x80004005), component SessionMachine, interface ISession
```

没有取得 `cdb_stdout.txt`、`run_meta.txt`、`probe.cdb`、样本退出码或断点事件；因此本臂不提供任何样本行为证据。

## 清理

finally 流程已恢复 `qoder-clean-20260920`，当前状态为 `saved`，`nic1=nat`。该结果只记录 VirtualBox 仪器启动失败，不是核心不存在、不是自然路径阴性，也不是解码失败。未重复同一启动会话。
