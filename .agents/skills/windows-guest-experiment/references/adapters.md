# 低层适配器参考

**只有已经确认成熟 workflow 存在能力缺口时才读本文件。**

这些机制只是 transport / adapter，不是分析 runtime，也不应被扩展成第二套任务系统。

## Hyper-V：PowerShell Direct

适用：Host 为 Hyper-V，且需要在不依赖 Guest 网络的情况下执行少量命令或复制文件。

Microsoft 支持 Host 直接对 Windows Guest 使用 `Invoke-Command -VMName`、`New-PSSession -VMName` 和 `Copy-Item -ToSession/-FromSession`。

边界：

- PowerShell Direct 证明命令/数据通道可用，不证明交互式桌面可用。
- 不用它替代已经存在的 CAPEsolo job/runtime。
- 长任务不要默认与前台 PSSession 生命周期绑定。

官方文档：
https://learn.microsoft.com/windows-server/virtualization/hyper-v/powershell-direct

## VirtualBox Guest Control

适用：现有环境明确使用 VirtualBox，并且 Guest Additions Guest Control 已验证。

优先查当前本机 `VBoxManage guestcontrol --help`，不要凭记忆拼参数。

边界：

- `run` / `start` 的等待语义不同；
- Guest 路径存在不等于 Host 已取得文件；
- 不把 GuestControl 当通用 scheduler。

官方文档：
https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/vboxmanage.html

## SSH / SCP

只在 Guest 已明确配置 SSH 且网络通道本身属于设计时使用。

- 端口开放或 SSH banner 只证明服务响应；
- 必须实际执行命令才能证明 control；
- SCP 路径错误应立即修路径，不要伪装成“文件还没准备好”继续轮询；
- 凭据、私钥、私有地址不得写入仓库。

## SMB / UNC

主要作为数据通道。

- 优先使用明确的 UNC 路径；
- 映射盘符可能受用户、session、服务账户影响；
- 一个 session 能看到路径，不代表另一个 session 也能看到。

## CDB / WinDbg CLI

只有当 `references/debugger-stack.md` 已判断需要 Microsoft debugger，并且没有更稳定的语义接口时再使用 CLI。

优先顺序：

```text
runtime 自带 debugger API
→ DbgEng / DbgSrv 薄桥接
→ 最后才是 CDB/WinDbg 文本 CLI
```

不要把命令回显当 breakpoint event；不要为长期控制反复解析人类文本输出。

官方文档：
https://learn.microsoft.com/windows-hardware/drivers/debugger/cdb-command-line-options

## 最小验证原则

低层 adapter 只验证当前任务真正依赖的能力，例如：

- 一次真实命令执行；
- 一次文件往返；
- 一次 debugger attach/hit；
- 一次 GUI session 可见性。

不要因为选了低层 adapter 就自动展开 control/data/runner/state 全套自研框架。

